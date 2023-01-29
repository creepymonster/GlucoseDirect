//
//  AppleHealth.swift
//  GlucoseDirect
//

import Combine
import Foundation
import HealthKit
import GRDB
import UIKit

func appleHealthSyncMiddleware() -> Middleware<DirectState, DirectAction> {
    return appleHealthExportMiddleware(service: LazyService<AppleHealthSyncService>(initialization: {
        AppleHealthSyncService()
    }))
}

private func appleHealthExportMiddleware(service: LazyService<AppleHealthSyncService>) -> Middleware<DirectState, DirectAction> {
    return { state, action, _ in
        switch action {
        case .startup:
            if state.appleHealthSync && service.value.healthStoreAvailable {
                return Future<DirectAction, DirectError> { promise in
                    Task {
                        guard let _ = await service.value.requestAccess() else {
                            promise(.failure(.withMessage("Apple Health access declined")))
                            return
                        }
                        promise(.success(.setAppleHealthSync(enabled: true)))
                    }
                }.eraseToAnyPublisher()
            } else {
                return Just(DirectAction.setAppleHealthSync(enabled: false))
                    .setFailureType(to: DirectError.self)
                    .eraseToAnyPublisher()
            }
        case .setAppleHealthSync(enabled: let enabled):
            if enabled {
                Task {
                    //TODO: Should this be it's own action?
                    await service.value.migrateAppleHealthToV2Format()
                    await service.value.syncAllDataToAppleHealth()
                    await service.value.setUpGlucoseBackgroundDeliveries()
                    await service.value.setUpInsulinBackgroundDeliveries()
                }
            }
            
        case .requestAppleHealthAccess(enabled: let enabled):
            if enabled {
                if !service.value.healthStoreAvailable {
                    break
                }
                
                return Future<DirectAction, DirectError> { promise in
                    Task {
                        guard let _ = await service.value.requestAccess() else {
                            promise(.failure(.withMessage("Apple Health access declined")))
                            return
                        }
                        promise(.success(.setAppleHealthSync(enabled: true)))
                    }
                }.eraseToAnyPublisher()
            } else {
                return Just(DirectAction.setAppleHealthSync(enabled: false))
                    .setFailureType(to: DirectError.self)
                    .eraseToAnyPublisher()
            }
            
        case .addBloodGlucose(glucoseValues: let glucoseValues):
            guard state.appleHealthSync else {
                DirectLog.info("Guard: state.appleHealth is false")
                break
            }
            
            Task {
                await service.value.addGlucose(glucoseValues: glucoseValues)
            }
            
        case .deleteBloodGlucose(glucose: let glucose):
            guard state.appleHealthExport else {
                DirectLog.info("Guard: state.appleHealth is false")
                break
            }
            Task {
                await service.value.deleteGlucose(glucose: glucose)
            }
        case .addInsulinDelivery(insulinDeliveryValues: let insulinDeliveryValues):
            guard state.appleHealthExport else {
                DirectLog.info("Guard: state.appleHealth is false")
                break
            }
            
            Task {
                await service.value.addInsulinDelivery(insulinDeliveryValues: insulinDeliveryValues)
            }
        case .deleteInsulinDelivery(insulinDelivery: let insulinDelivery):
            guard state.appleHealthExport else {
                DirectLog.info("Guard: state.appleHealth is false")
                break
            }
            
            Task {
                await service.value.deleteInsulinDelivery(insulinDelivery: insulinDelivery)
            }
        case .addSensorGlucose(glucoseValues: let glucoseValues):
            guard state.appleHealthSync else {
                DirectLog.info("Guard: state.appleHealth is false")
                break
            }
            
            Task {
                await service.value.addGlucose(glucoseValues: glucoseValues)
            }
        case .deleteSensorGlucose(glucose: let glucose):
            guard state.appleHealthSync else {
                DirectLog.info("Guard: state.appleHealth is false")
                break
            }

            service.value.deleteGlucose(glucose: glucose)

        case .syncAppleHealth:
            guard state.appleHealthSync else {
                DirectLog.info("Guard: state.appleHealth is false")
                break
            }
            
            Task {
                await service.value.deleteGlucose(glucose: glucose)
            }
        default:
            break
        }
        
        return Empty().eraseToAnyPublisher()
    }
}


// MARK: - AppleHealthExportService

private class AppleHealthSyncService {
    // MARK: Lifecycle
    
    init() {
        DirectLog.info("Create AppleHealthSyncService")
    }
    
    // MARK: Internal
    
    var glucoseType: HKQuantityType {
        HKObjectType.quantityType(forIdentifier: .bloodGlucose)!
    }

    var requiredWritePermissions: Set<HKSampleType> {
        Set([glucoseType, insulinType])
    }
    
    var requiredReadPermissions: Set<HKObjectType> {
        Set([glucoseType, insulinType])
    }
    
    var requiredPermissions: Set<HKSampleType> {
        Set([glucoseType, insulinType])
    }
    
    var healthStoreAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    // MARK: Private
    
    /**
     Holder for the Apple health store, use requestAccess though instead to get the healthstore
     */
    private lazy var healthStore: HKHealthStore? = {
        if HKHealthStore.isHealthDataAvailable() {
            return HKHealthStore()
        }
        
        return nil
    }()
    
    /**
     Request access to the apple health store
     */
    func requestAccess() async -> HKHealthStore? {
        guard let healthStore = healthStore else {
            return nil
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: requiredWritePermissions, read: requiredReadPermissions)
            return healthStore
        } catch {
            return nil
        }
    }
    
    // MARK: Sync Data from Apple Health To Glucose Direct
    
    /**
     In our long running HealthKit query we use the same handler for both new and updated HealthKit data points.
     */
    let syncFromHealthKitGlucoseHandler: ((HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void) = { (query, newSamples, deletedSamples, newAnchor, error) in
        
        // 1. Guard our data to ensure it all exists and is the right type.
        guard let samples = newSamples as? [HKQuantitySample], let deleted = deletedSamples else {
            DirectLog.error("Error with samples recieved from our HealthKit Query", error: error)
            return
        }
        
        // 2. Save our new anchor to user defaults so we can use it later.
        UserDefaults.shared.glucoseAnchor = newAnchor
        
        // 3. Remove any samples we already have in our database (these can come from us)
        var samplesNotInDatabase = samples.filter {  DataStore.shared.getBloodGlucose(for: $0.uuid) == nil && DataStore.shared.getSensorGlucose(for: $0.uuid) == nil      }
        
        // 4. Loop through each new sample delievered to us.
        let bloodGlucoseValues = samplesNotInDatabase.map { sample in
            return BloodGlucose(id: UUID(), timestamp: sample.startDate, glucoseValue: Int(sample.quantity.doubleValue(for: .milligramsPerDeciliter)), originatingSourceName: sample.sourceRevision.source.name, originatingSourceBundle: sample.sourceRevision.source.bundleIdentifier, appleHealthId: sample.uuid)
        }
        
        // 5. Need to dispatch adds on the main thread.
        DispatchQueue.main.sync {
            GlucoseDirectApp.store.dispatch(.addBloodGlucose(glucoseValues: bloodGlucoseValues))
        }
        
        // 6. Grab any samples from our database that was deleted in Apple Health
        var deletedGlucoseValues: [(any Glucose)?] = deleted.map { sample in
            return DataStore.shared.getBloodGlucose(for: sample.uuid) ?? DataStore.shared.getSensorGlucose(for: sample.uuid)
        }
        
        let nonNilDeletedGlucoseValues: [any Glucose] = deletedGlucoseValues.filter { $0 != nil } as! [any Glucose]
        
        // 7. Filter to sensor glucose values to delete
        let deletedSensorGlucose: [SensorGlucose] = nonNilDeletedGlucoseValues.filter { type(of:$0) == SensorGlucose.self } as! [SensorGlucose]
        
        // 7. Filter to blood glucose values to delete
        let deletedBloodGlucose: [BloodGlucose] = nonNilDeletedGlucoseValues.filter { type(of:$0) == BloodGlucose.self} as! [BloodGlucose]
        
        
        // 8. Delete all the glucose values
        deletedSensorGlucose.forEach { glucose in
            DispatchQueue.main.sync {
                GlucoseDirectApp.store.dispatch(.deleteSensorGlucose(glucose: glucose))
            }
        }
        
        deletedBloodGlucose.forEach { glucose in
            DispatchQueue.main.sync {
                GlucoseDirectApp.store.dispatch(.deleteBloodGlucose(glucose: glucose))
            }
        }
    }
    
    /**
     In our long running HealthKit query we use the same handler for both new and updated HealthKit data points.
     */
    let syncFromHealthKitInsulinHandler: ((HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void) = { (query, newSamples, deletedSamples, newAnchor, error) in
        
        // 1. Guard our data to ensure it all exists and is the right type.
        guard let samples = newSamples as? [HKQuantitySample], let deleted = deletedSamples else {
            DirectLog.error("Error with samples recieved from our HealthKit Query", error: error)
            return
        }
        
        // 2. Save our new anchor to user defaults so we can use it later.
        UserDefaults.shared.insulinAnchor = newAnchor
        
        // 3. Remove any samples we already have in our database (these can come from us)
        var samplesNotInDatabase = samples.filter {  DataStore.shared.getInsulinDelivery(for: $0.uuid) == nil }
        
        // 4. Loop through each new sample delievered to us.
        let insulinValues = samplesNotInDatabase.map { sample in
            return InsulinDelivery(id: UUID(), starts: sample.startDate, ends: sample.endDate, units: sample.quantity.doubleValue(for: .internationalUnit()), type: InsulinType.insulinDeliveryReason(from:  HKInsulinDeliveryReason(rawValue: sample.metadata?[HKMetadataKeyInsulinDeliveryReason] as! Int)!) , originatingSourceName: sample.sourceRevision.source.name, originatingSourceBundle: sample.sourceRevision.source.bundleIdentifier, appleHealthId: sample.uuid)
        }
        
        // 5. Need to dispatch adds on the main thread.
        DispatchQueue.main.sync {
            GlucoseDirectApp.store.dispatch(.addInsulinDelivery(insulinDeliveryValues: insulinValues))
        }
        
        // 6. Grab any samples from our database that was deleted in Apple Health
        var deletedInsulinValues: [InsulinDelivery?] = deleted.map { sample in
            return DataStore.shared.getInsulinDelivery(for: sample.uuid)
        }
        
        let nonNilDeletedInsulinValues: [InsulinDelivery] = deletedInsulinValues.filter { $0 != nil } as! [InsulinDelivery]
        
        // 7. Need to dispatch adds on the main thread.
        DispatchQueue.main.sync {
            nonNilDeletedInsulinValues.forEach { insulinDelivery in
                GlucoseDirectApp.store.dispatch(.deleteInsulinDelivery(insulinDelivery: insulinDelivery))
            }
        }
    }
    
    /**
     Set up Background deliveries of all the glucose health kit data we want.
     */
    func setUpGlucoseBackgroundDeliveries() async {
        guard let healthStore = await requestAccess() else {
            DirectLog.info("Guard: HealthStore unavailable, not setting up HealthKit glucose background deliveries")
            return
        }
        
        // Create a long running query that will grab initial results
        let query = HKAnchoredObjectQuery(type: self.glucoseType, predicate: nil, anchor: UserDefaults.shared.glucoseAnchor, limit: Int(HKObjectQueryNoLimit), resultsHandler: syncFromHealthKitGlucoseHandler)
        
        // Install an update handler that will retrieve any updates from HealthKit in the background
        query.updateHandler = syncFromHealthKitGlucoseHandler
        
        healthStore.execute(query)
        
        // Enable background delievery for health data.
        do {
            try await healthStore.enableBackgroundDelivery(for: self.glucoseType, frequency: .immediate)
            DirectLog.info("Successfully enabled background delivery of HealthKit data for type \(self.glucoseType)")
        } catch {
            DirectLog.error("Failed enabling background delievery of HealthKit data for type \(self.glucoseType)", error: error)
        }
    }
    
    /**
     Set up Background deliveries of all the health kit data we want.
     */
    func setUpInsulinBackgroundDeliveries() async {
        guard let healthStore = await requestAccess() else {
            DirectLog.info("Guard: HealthStore unavailable, not setting up HealthKit insulin background deliveries")
            return
        }
        
        // Create a long running query that will grab initial results
        let query = HKAnchoredObjectQuery(type: self.insulinType, predicate: nil, anchor: UserDefaults.shared.insulinAnchor, limit: Int(HKObjectQueryNoLimit), resultsHandler: syncFromHealthKitInsulinHandler)
        
        // Install an update handler that will retrieve any updates from HealthKit in the background
        query.updateHandler = syncFromHealthKitInsulinHandler
        
        healthStore.execute(query)
        
        // Enable background delievery for health data.
        do {
            try await healthStore.enableBackgroundDelivery(for: self.insulinType, frequency: .immediate)
            DirectLog.info("Successfully enabled background delivery of HealthKit data for type \(self.insulinType)")
        } catch {
            DirectLog.error("Failed enabling background delievery of HealthKit data for type \(self.insulinType)", error: error)
        }
    }
    
    //MARK:  -- Sync Data To Apple Health
    
    //MARK: Glucose Handling
    
    func addGlucose(glucoseValues: [any Glucose]) async {
        guard let healthStore = await requestAccess() else {
            DirectLog.info("Guard: HealthStore unavailable, not adding new glucuse values")
            return
        }
        
        var healthGlucoseValues: [HKQuantitySample] = []
        
        for glucose in glucoseValues {
            if (glucose.isSyncedToAppleHealth()) {
                // We don't save health values Back to Health Kit that are already in HealthKit
                continue
            }
            
            var metadata:[String : Any] = [
                HKMetadataKeyExternalUUID: glucose.id.uuidString,
                HKMetadataKeySyncIdentifier: glucose.id.uuidString,
                HKMetadataKeySyncVersion: 2,
                HKMetadataKeyWasUserEntered:  type(of: glucose) == BloodGlucose.self,
            ]
            
            if (type(of: glucose) == SensorGlucose.self) {
                let sensorGlucose = glucose as! SensorGlucose
                // Add in the sensor data to HealthKit
                metadata[HKMetadataKeyDeviceSerialNumber] = sensorGlucose.serial
                metadata[HKMetadataKeyDeviceManufacturerName] = sensorGlucose.manufacturer
            }
            
            let appleSample = HKQuantitySample(
                type: self.glucoseType,
                quantity: HKQuantity(unit: .milligramsPerDeciliter, doubleValue: Double(glucose.glucoseValue)),
                start: glucose.timestamp,
                end: glucose.timestamp,
                metadata: metadata
            )
            
            let appleHealthId = appleSample.uuid
            
            if (type(of: glucose) == SensorGlucose.self) {
                DataStore.shared.updateSensorGlucose(for: glucose.id, with: appleHealthId)
            } else {
                DataStore.shared.updateBloodGlucose(for: glucose.id, with: appleHealthId)
            }
            
            healthGlucoseValues.append(appleSample)
        }
        
        guard !healthGlucoseValues.isEmpty else {
            return
        }
        
        do {
            try await healthStore.save(healthGlucoseValues)
        } catch {
            DirectLog.error("Writing data to apple health store failed", error: error)
        }
    }
    
    func deleteGlucose(glucose: any Glucose) async {
        guard let healthStore = await requestAccess() else {
            DirectLog.info("Guard: HealthStore unavailable, not deleting glucose values")
            return
        }
        
        guard let appleHealthId = glucose.appleHealthId else {
            return
        }
        
        do {
            let numberDeleted = try await healthStore.deleteObjects(of: self.glucoseType, predicate: HKQuery.predicateForObject(with: appleHealthId))
            DirectLog.info("Deleted \(numberDeleted) glucose delivery records from HealthKit")
        } catch {
            DirectLog.error("Deleting glucose data in apple health store failed", error: error)
        }
    }
    
    //MARK: Insulin Handling
    
    func addInsulinDelivery(insulinDeliveryValues: [InsulinDelivery]) async {
        guard let healthStore = await requestAccess() else {
            DirectLog.info("Guard: HealthStore unavailable, not deleting glucose values")
            return
        }
        
        var healthInsulinDeliveryValues: [HKQuantitySample] = []
        
        for insulinDelivery in insulinDeliveryValues {
            if (insulinDelivery.isSyncedToAppleHealth()) {
                // We don't save health values Back to Health Kit that are not from us.
                continue
            }
            
            let appleSample = HKQuantitySample(
                type: self.insulinType,
                quantity: HKQuantity(unit: .internationalUnit(), doubleValue: Double(insulinDelivery.units)),
                start: insulinDelivery.starts,
                end: insulinDelivery.ends,
                metadata: [
                    HKMetadataKeyExternalUUID: insulinDelivery.id.uuidString,
                    HKMetadataKeySyncIdentifier: insulinDelivery.id.uuidString,
                    HKMetadataKeySyncVersion: 1,
                    HKMetadataKeyInsulinDeliveryReason: insulinDelivery.type.hkInsulinDeliveryReason().rawValue,
                    HKMetadataKeyWasUserEntered: true
                ]
            )
            
            let appleHealthId = appleSample.uuid
            DataStore.shared.updateInsulinDelivery(for: insulinDelivery.id, with: appleHealthId)
            healthInsulinDeliveryValues.append(appleSample)
        }
        
        guard !healthInsulinDeliveryValues.isEmpty else {
            return
        }
        
        do {
            try await healthStore.save(healthInsulinDeliveryValues)
        } catch {
            DirectLog.error("Guard: Writing insulin data to apple health store failed", error: error)
        }
    }
    
    func deleteInsulinDelivery(insulinDelivery: InsulinDelivery) async {
        guard let healthStore = await requestAccess() else {
            DirectLog.info("Guard: HealthStore unavailable, not deleting glucose values")
            return
        }
        
        guard let appleHealthId = insulinDelivery.appleHealthId else {
            return
        }
        
        do {
            let numberDeleted = try await healthStore.deleteObjects(of: self.insulinType, predicate: HKQuery.predicateForObject(with: appleHealthId))
            DirectLog.info("Deleted \(numberDeleted) insulin delivery records from HealthKit")
        } catch {
            DirectLog.error("Guard: Deleting insulin data in apple health store failed", error: error)
        }
    }
    
    //MARK: -- Migration
    
    /**
     Deletes all data Glucose Direct has saved in AppleHealth and resaves it so that we can input new values and save the Apple Health Identifier.
     */
    func migrateAppleHealthToV2Format() async {
        // 1. Check if migrated already, if so, skip all.
        if UserDefaults.shared.appleHealthIdMigrated {
            return
        }
        // 2. Reset all the apple health data from this app
        await resetAppleHealthData()
        
        // 3. Mark that we have migrated.
        UserDefaults.shared.appleHealthIdMigrated = true
    }
    
    /**
     Resets all the apple health data as needed.
     */
    func resetAppleHealthData() async {
        // 1. Delete all data from AppleHealth originating from this app.
        await deleteAllAppleHealthGlucoseValues()
        
        // 2. Loop through all data in this app and re-send it to AppleHealth
        await self.syncAllDataToAppleHealth()
    }
    
    /**
     Delete all the apple health glucose values
     */
    func deleteAllAppleHealthGlucoseValues() async {
        guard let healthStore = await requestAccess() else {
            DirectLog.info("Guard: HealthStore unavailable, not deleting apple health glucose values")
            return
        }
        
        do {
            let numberGlucoseDeleted = try await healthStore.deleteObjects(of: self.glucoseType, predicate: HKQuery.predicateForObjects(from: .default()))
            DirectLog.info("Deleted \(numberGlucoseDeleted) apple health glucose values")
        } catch {
            DirectLog.error("Could not delete glucose froma Apple Health", error: error)
        }
    }
    
    /**
     Delete all the apple health insulin values
     */
    func deleteAllAppleHealthInsulinValues() async {
        guard let healthStore = await requestAccess() else {
            DirectLog.info("Guard: HealthStore unavailable, not deleting apple health glucose values")
            return
        }
        
        do {
            let numberInsulinDeleted = try await healthStore.deleteObjects(of: self.insulinType, predicate: HKQuery.predicateForObjects(from: .default()))
            DirectLog.info("Deleted \(numberInsulinDeleted) insulin while migrating to v2 Apple Health")
        } catch {
            DirectLog.error("Could not delete insulin migrating to v2 Apple Health", error: error)
        }
    }
    
    /**
     Sync all the data we have to apple health.
     */
    func syncAllDataToAppleHealth() async {
        await self.syncAllBloodGlucoseToAppleHealth()
        await self.syncAllSensorGlucoseToAppleHealth()
        await self.syncAllInsulinDeliveryToAppleHealth()
    }
    
    
    func syncAllSensorGlucoseToAppleHealth() async {
        let sensorGlucoseValues = DataStore.shared.getAllSensorGlucoseWithoutAppleHealthId()
        await self.addGlucose(glucoseValues: sensorGlucoseValues)
    }
    
    func syncAllBloodGlucoseToAppleHealth() async {
        let bloodGlucoseValues = DataStore.shared.getAllBloodGlucoseWithoutAppleHealthId()
        await self.addGlucose(glucoseValues: bloodGlucoseValues)
    }
    
    func syncAllInsulinDeliveryToAppleHealth() async {
        let insulinDeliveryValues = DataStore.shared.getAllInsulinDeliveryWithoutAppleHealthId()
        await self.addInsulinDelivery(insulinDeliveryValues: insulinDeliveryValues)
    }
    
}


private extension HKUnit {
    static let milligramsPerDeciliter: HKUnit = HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
}


private extension InsulinType {
    
    func hkInsulinDeliveryReason() -> HKInsulinDeliveryReason {
        switch self {
        case .basal:
            return .basal
        case .mealBolus:
            return .bolus
        case .correctionBolus:
            return .bolus
        case .snackBolus:
            return .bolus
        }
    }
    
    static func insulinDeliveryReason(from: HKInsulinDeliveryReason) -> InsulinType {
        switch from {
        case .basal:
            return .basal
        case .bolus:
            return .mealBolus
        @unknown default:
            return .mealBolus
        }
    }
}


private extension DataStore {
    func getBloodGlucose(for appleHealthId: UUID) -> BloodGlucose? {
        if let dbQueue = dbQueue {
            do {
                return try dbQueue.read { db in
                    try BloodGlucose
                        .filter(Column(BloodGlucose.Columns.appleHealthId.name) == appleHealthId.uuidString)
                        .fetchOne(db)
                }
            } catch {
                DirectLog.error("Could not get blood glucose", error: error)
            }
        }
        
        return nil
    }
    
    func getSensorGlucose(for appleHealthId: UUID) -> SensorGlucose? {
        if let dbQueue = dbQueue {
            do {
                return try dbQueue.read { db in
                    try SensorGlucose
                        .filter(Column(SensorGlucose.Columns.appleHealthId.name) == appleHealthId.uuidString)
                        .fetchOne(db)
                }
            } catch {
                DirectLog.error("Could not get sensor glucose", error: error)
            }
        }
        
        return nil
    }
    
    func getInsulinDelivery(for appleHealthId: UUID) -> InsulinDelivery? {
        if let dbQueue = dbQueue {
            do {
                return try dbQueue.read { db in
                    try InsulinDelivery
                        .filter(Column(InsulinDelivery.Columns.appleHealthId.name) == appleHealthId.uuidString)
                        .fetchOne(db)
                }
            } catch {
                DirectLog.error("Could not get insulin delivery", error: error)
            }
        }
        
        return nil
    }
    
    func getAllBloodGlucoseWithoutAppleHealthId() -> [BloodGlucose] {
        if let dbQueue = dbQueue {
            do {
                return try dbQueue.read { db in
                    try BloodGlucose
                        .filter(Column(BloodGlucose.Columns.appleHealthId.name) == nil)
                        .fetchAll(db)
                }
            } catch {
                DirectLog.error("Could not get all blood glucose without apple health id", error: error)
            }
        }
        
        return []
    }
    
    func getAllSensorGlucoseWithoutAppleHealthId() -> [SensorGlucose] {
        if let dbQueue = dbQueue {
            do {
                return try dbQueue.read { db in
                    try SensorGlucose
                        .filter(Column(SensorGlucose.Columns.appleHealthId.name) == nil)
                        .fetchAll(db)
                }
            } catch {
                DirectLog.error("Could not get all sensor glucose without apple health id", error: error)
            }
        }
        
        return []
    }
    
    func getAllInsulinDeliveryWithoutAppleHealthId() -> [InsulinDelivery] {
        if let dbQueue = dbQueue {
            do {
                return try dbQueue.read { db in
                    try InsulinDelivery
                        .filter(Column(InsulinDelivery.Columns.appleHealthId.name) == nil)
                        .fetchAll(db)
                }
            } catch {
                DirectLog.error("Could not get all inuslin delivery without apple health id", error: error)
            }
        }
        
        return []
    }
    
    func updateBloodGlucose(for id: UUID, with appleHealthId: UUID) {
        if let dbQueue = dbQueue {
            do {
                return try dbQueue.write({ db in
                    try BloodGlucose
                        .filter(Column(BloodGlucose.Columns.id.name) == id.uuidString)
                        .updateAll(db, Column(BloodGlucose.Columns.appleHealthId.name).set(to: appleHealthId.uuidString))
                })
            } catch {
                DirectLog.error("Could not write blood glucose apple health id", error: error)
            }
        }
    }
    
    /**
     Update the insulin delivery in our database with the generated apple health id
     */
    func updateSensorGlucose(for id: UUID, with appleHealthId: UUID) {
        if let dbQueue = dbQueue {
            do {
                return try dbQueue.write({ db in
                    try SensorGlucose
                        .filter(Column(SensorGlucose.Columns.id.name) == id.uuidString)
                        .updateAll(db, Column(SensorGlucose.Columns.appleHealthId.name).set(to: appleHealthId.uuidString))
                })
            } catch {
                DirectLog.error("Could not write sensor glucose apple health id", error: error)
            }
        }
    }
    
    /**
     Update the insulin delivery in our database with the generated apple health id
     */
    func updateInsulinDelivery(for id: UUID, with appleHealthId: UUID) {
        if let dbQueue = dbQueue {
            do {
                return try dbQueue.write({ db in
                    try InsulinDelivery
                        .filter(Column(InsulinDelivery.Columns.id.name) == id.uuidString)
                        .updateAll(db, Column(InsulinDelivery.Columns.appleHealthId.name).set(to: appleHealthId.uuidString))
                })
            } catch {
                DirectLog.error("Could not write insulin delivery apple health id", error: error)
            }
        }
    }
}


private extension UserDefaults {
    enum Keys: String {
        case glucoseAnchor = "libre-direct.healthkit.glucose-anchor"
        case insulinAnchor = "libre-direct.healthkit.insulin-anchor"
        
        // Used to determine if we have done a migration of all GlucoseDirects apple health data,
        // so that we have the HealthKit identifiers from Apple saved.
        case appleHealthIdMigrated = "libre-direct.healthkit.appleHealthIdMigrated"
    }
    
    var appleHealthIdMigrated: Bool {
        get {
            return UserDefaults.shared.bool(forKey: UserDefaults.Keys.appleHealthIdMigrated.rawValue)
        }
        set {
            if !newValue {
                UserDefaults.shared.removeObject(forKey: UserDefaults.Keys.appleHealthIdMigrated.rawValue)
                return
            }
            UserDefaults.shared.set(newValue, forKey: UserDefaults.Keys.appleHealthIdMigrated.rawValue)
        }
    }
    
    var glucoseAnchor: HKQueryAnchor? {
        get {
            var anchor = HKQueryAnchor.init(fromValue: 0)
            
            if UserDefaults.shared.object(forKey: UserDefaults.Keys.glucoseAnchor.rawValue) != nil {
                let data = UserDefaults.shared.object(forKey: UserDefaults.Keys.glucoseAnchor.rawValue) as! Data
                do {
                    anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)!
                } catch {
                    DirectLog.error("Could not decode saved healthkit anchor, using a new one", error: error)
                }
            }
            return anchor
        }
        set {
            guard let newValue = newValue else {
                UserDefaults.shared.removeObject(forKey: UserDefaults.Keys.glucoseAnchor.rawValue)
                return
            }
            
            do {
                let data : Data = try NSKeyedArchiver.archivedData(withRootObject: newValue as Any, requiringSecureCoding: false)
                UserDefaults.shared.set(data, forKey: UserDefaults.Keys.glucoseAnchor.rawValue)
            } catch {
                DirectLog.error("Could not encode healthkit anchor, so clearing out existing one", error: error)
                UserDefaults.shared.removeObject(forKey: UserDefaults.Keys.glucoseAnchor.rawValue)
            }
        }
    }
    
    var insulinAnchor: HKQueryAnchor? {
        get {
            var anchor = HKQueryAnchor.init(fromValue: 0)
            
            if UserDefaults.shared.object(forKey: UserDefaults.Keys.insulinAnchor.rawValue) != nil {
                let data = UserDefaults.shared.object(forKey: UserDefaults.Keys.insulinAnchor.rawValue) as! Data
                do {
                    anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)!
                } catch {
                    DirectLog.error("Could not decode saved healthkit anchor, using a new one", error: error)
                }
            }
            return anchor
        }
        set {
            guard let newValue = newValue else {
                UserDefaults.shared.removeObject(forKey: UserDefaults.Keys.insulinAnchor.rawValue)
                return
            }
            
            do {
                let data : Data = try NSKeyedArchiver.archivedData(withRootObject: newValue as Any, requiringSecureCoding: false)
                UserDefaults.shared.set(data, forKey: UserDefaults.Keys.insulinAnchor.rawValue)
            } catch {
                DirectLog.error("Could not encode healthkit anchor, so clearing out existing one", error: error)
                UserDefaults.shared.removeObject(forKey: UserDefaults.Keys.insulinAnchor.rawValue)
            }
        }
    }
}
