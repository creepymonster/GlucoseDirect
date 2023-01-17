//
//  AppleHealth.swift
//  GlucoseDirect
//

import Combine
import Foundation
import HealthKit

func appleHealthExportMiddleware() -> Middleware<DirectState, DirectAction> {
    return appleHealthExportMiddleware(service: LazyService<AppleHealthExportService>(initialization: {
        AppleHealthExportService()
    }))
}

private func appleHealthExportMiddleware(service: LazyService<AppleHealthExportService>) -> Middleware<DirectState, DirectAction> {
    return { state, action, _ in
        switch action {
        case .startup:
            if state.appleHealthSync && service.value.healthStoreAvailable {
                return Future<DirectAction, DirectError> { promise in
                    service.value.requestAccess { granted in
                        if !granted {
                            promise(.failure(.withMessage("Apple Health access declined")))
                            
                        } else {
                            promise(.success(.setAppleHealthSync(enabled: true)))
                        }
                    }
                }.eraseToAnyPublisher()
            } else {
                return Just(DirectAction.setAppleHealthSync(enabled: false))
                    .setFailureType(to: DirectError.self)
                    .eraseToAnyPublisher()
            }
        case .requestAppleHealthAccess(enabled: let enabled):
            if enabled {
                if !service.value.healthStoreAvailable {
                    break
                }
                
                return Future<DirectAction, DirectError> { promise in
                    service.value.requestAccess { granted in
                        if !granted {
                            promise(.failure(.withMessage("Apple Health access declined")))
                            
                        } else {
                            promise(.success(.setAppleHealthSync(enabled: true)))
                        }
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
            
            service.value.addGlucose(glucoseValues: glucoseValues)
            
        case .deleteBloodGlucose(glucose: let glucose):
            guard state.appleHealthExport else {
                DirectLog.info("Guard: state.appleHealth is false")
                break
            }
        
            service.value.deleteGlucose(glucose: glucose)
            
        case .addInsulinDelivery(insulinDeliveryValues: let insulinDeliveryValues):
            guard state.appleHealthExport else {
                DirectLog.info("Guard: state.appleHealth is false")
                break
            }
            
            service.value.addInsulinDelivery(insulinDeliveryValues: insulinDeliveryValues)
            
        case .deleteInsulinDelivery(insulinDelivery: let insulinDelivery):
            guard state.appleHealthExport else {
                DirectLog.info("Guard: state.appleHealth is false")
                break
            }
            
            service.value.deleteInsulinDelivery(insulinDelivery: insulinDelivery)
            
        case .addSensorGlucose(glucoseValues: let glucoseValues):
            guard state.appleHealthSync else {
                DirectLog.info("Guard: state.appleHealth is false")
                break
            }
            
            service.value.addGlucose(glucoseValues: glucoseValues)
            
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
            
            service.value.deleteGlucose(glucose: glucose)
            
        default:
            break
        }
        
        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - AppleHealthService

typealias AppleHealthExportHandler = (_ granted: Bool) -> Void
typealias AppleHealthLoadFromAppleHealthHandler = (_ newExternalValues: [BloodGlucose]) -> Void
typealias AppleHealthLoadHealthKitSample = (_ sample: HKQuantitySample?) -> Void

// MARK: - AppleHealthExportService

private class AppleHealthExportService {
    // MARK: Lifecycle
    
    init() {
        DirectLog.info("Create AppleHealthExportService")
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
    
    private lazy var healthStore: HKHealthStore? = {
        if HKHealthStore.isHealthDataAvailable() {
            return HKHealthStore()
        }
        
        return nil
    }()
    
    func requestAccess(completionHandler: @escaping AppleHealthExportHandler) {
        guard let healthStore = healthStore else {
            completionHandler(false)
            return
        }
        
        healthStore.requestAuthorization(toShare: requiredWritePermissions, read: requiredReadPermissions) { granted, error in
            if granted, error == nil {
                self.setUpBackgroundDeliveries()
                completionHandler(true)
            } else {
                completionHandler(false)
            }
        }
    }
    
    // MARK: Sync Data from Apple Health To Glucose Direct
    
    /**
     In our long running HealthKit query we use the same handler for both new and updated HealthKit data points.
     */
    let syncFromHealthKitHandler: ((HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void) = { (query, newSamples, deletedSamples, newAnchor, error) in
        
        // 2 Guard our data to ensure it all exists and is the right type.
        guard let samples = newSamples as? [HKQuantitySample], let deleted = deletedSamples else {
            DirectLog.error("Error with samples recieved from our HealthKit Query", error: error)
            return
        }
        
        // 3 Save our new anchor to user defaults so we can use it later.
        UserDefaults.shared.anchor = newAnchor
        
        // 4 Loop through each new sample delievered to us.
        for newSample in samples {
            //self.queryForUpdates(newSample: newSample)
        }
        
        // 5 Delete any samples from our database that was deleted in Apple Health
        for deletedSample in deleted {
            //self.queryForDeletions(deletedSample: deletedSample, type: type)
        }
    }
    
    /**
     Set up Background deliveries of all the health kit data we want.
     */
    func setUpBackgroundDeliveries() {
        guard let healthStore = healthStore else {
            DirectLog.info("Guard: HealthStore unavailable, not setting up HealthKit background deliveries")
            return
        }
        
        for type in self.requiredReadPermissions {
            
            guard let sampleType = type as? HKSampleType else { print("ERROR: \(type) is not an HKSampleType"); continue }
            
            // Create a long running query that will grab initial results
            let query = HKAnchoredObjectQuery(type: sampleType, predicate: nil, anchor: UserDefaults.shared.anchor, limit: Int(HKObjectQueryNoLimit), resultsHandler: syncFromHealthKitHandler)
            
            // Install an update handler that will retrieve any updates from HealthKit in the background
            query.updateHandler = syncFromHealthKitHandler
            
            healthStore.execute(query)
            
            // Enable background delievery for health data.
            healthStore.enableBackgroundDelivery(for: type, frequency: .immediate, withCompletion: { (success, error) in
                
                if let error = error {
                    DirectLog.error("Failed enabling background delievery of HealthKit data for type \(type)", error: error)
                } else {
                    DirectLog.info("Successfully enabled background delivery of HealthKit data for type \(type)")
                }
                
            })
            
        }
    }
    
    //MARK:  -- Sync Data To Apple Health
    
    //MARK: Glucose Handling
    
    func addGlucose(glucoseValues: [any Glucose]) {
        guard let healthStore = healthStore else {
            DirectLog.info("Guard: HealthStore unavailable, not adding new glucuse values")
            return
        }
        
        self.requestAccess { [weak self] granted in
            guard granted else {
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
                    // Add in the sensor data to HealthKit
                    //TODO: Move these values to be saved on the Glucose Object in the database, and set based on that.
                    metadata[HKMetadataKeyDeviceSerialNumber] = UserDefaults.shared.sensor?.serial
                    metadata[HKMetadataKeyDeviceManufacturerName] = UserDefaults.shared.sensor?.type.rawValue
                }
                
                let appleSample = HKQuantitySample(
                    type: self!.glucoseType,
                    quantity: HKQuantity(unit: .milligramsPerDeciliter, doubleValue: Double(glucose.glucoseValue)),
                    start: glucose.timestamp,
                    end: glucose.timestamp,
                    metadata: metadata
                )
                
                let appleHealthId = appleSample.uuid
                //TODO: Somehow query database and update with apple health id.
                
                /// glucose.appleHealthId = appleHealthId
                //TODO: save glucose value back to store?
                healthGlucoseValues.append(appleSample)
            }
            
            guard !healthGlucoseValues.isEmpty else {
                return
            }
            
            healthStore.save(healthGlucoseValues) { success, error in
                if !success {
                    DirectLog.info("Guard: Writing data to apple health store failed, error: \(error?.localizedDescription)")
                }
            }
        }
    }
    
    func deleteGlucose(glucose: any Glucose) {
        guard let healthStore = healthStore else {
            DirectLog.info("Guard: HealthStore unavailable, not deleting glucose values")
            return
        }
        
        guard let appleHealthId = glucose.appleHealthId else {
            return
        }
        
        self.requestAccess { [weak self] granted in
            guard granted else {
                return
            }
            
            healthStore.deleteObjects(of: self!.glucoseType, predicate: HKQuery.predicateForObject(with: appleHealthId)) { success, numberDeleted, error in
                if !success {
                    DirectLog.info("Guard: Deleting glucose data in apple health store failed, error: \(error?.localizedDescription)")
                    return
                }
                
                DirectLog.info("Deleted \(numberDeleted) glucose delivery records from HealthKit")
            }
        }
    }
    
    //MARK: Insulin Handling
    
    func addInsulinDelivery(insulinDeliveryValues: [InsulinDelivery]) {
        guard let healthStore = healthStore else {
            DirectLog.info("Guard: HealthStore unavailable, not deleting glucose values")
            return
        }
        
        self.requestAccess { [weak self] granted in
            guard granted else {
                return
            }
            
            
            var healthInsulinDeliveryValues: [HKQuantitySample] = []
            
            for insulinDelivery in insulinDeliveryValues {
                if (insulinDelivery.isSyncedToAppleHealth()) {
                    // We don't save health values Back to Health Kit that are not from us.
                    continue
                }
                
                
                
                let appleSample = HKQuantitySample(
                    type: self!.insulinType,
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
                //TODO: Somehow query database and update with apple health id.
                
                /// glucose.appleHealthId = appleHealthId
                //TODO: save glucose value back to store?
                healthInsulinDeliveryValues.append(appleSample)
            }
            
            guard !healthInsulinDeliveryValues.isEmpty else {
                return
            }
            
            healthStore.save(healthInsulinDeliveryValues) { success, error in
                if !success {
                    DirectLog.info("Guard: Writing insulin data to apple health store failed, error: \(error?.localizedDescription)")
                }
            }
        }
    }
    
    func deleteInsulinDelivery(insulinDelivery: InsulinDelivery) {
        guard let healthStore = healthStore else {
            DirectLog.info("Guard: HealthStore unavailable, not deleting glucose values")
            return
        }
        
        guard let appleHealthId = insulinDelivery.appleHealthId else {
            return
        }
        
        self.requestAccess { [weak self] granted in
            guard granted else {
                return
            }
            
            healthStore.deleteObjects(of: self!.insulinType, predicate: HKQuery.predicateForObject(with: appleHealthId)) { success, numberDeleted, error in
                if !success {
                    DirectLog.info("Guard: Deleting insulin data in apple health store failed, error: \(error?.localizedDescription)")
                    return
                }
                
                DirectLog.info("Deleted \(numberDeleted) insulin delivery records from HealthKit")
            }
        }
    }    
    
    //MARK -- Migration
    
    /**
     Deletes all data Glucose Direct has saved in AppleHealth and resaves it so that we can input new values and save the Apple Health Identifier.
     */
    func migrateAppleHealthToV2Format() {
        //TODO: Determine when to run this in app lifecycle. (prob need to move apple health middleware down in the state machine after all rest of stuff, so it has all other needed migrations in db)
        // 1. Check if migrated already, if so, skip all.
        // 2. Delete all data from AppleHealth originating from this app.
        // 3. Loop through all data in this app and send it to AppleHealth (can this be a reused function we use on first turn on of AppleSync too?)
        // 4. Mark that we have migrated.
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
}


private extension DataStore {
    func getBloodGlucose(for id: UUID) -> BloodGlucose? {
        if let dbQueue = dbQueue {
            do {
                return try dbQueue.read { db in
                    try BloodGlucose
                        .filter(Column(BloodGlucose.Columns.id.name) == id.uuidString)
                        .fetchOne(db)
                }
            } catch {
                DirectLog.error("\(error)")
            }
        }
        
        return nil
    }
}


private extension UserDefaults {
    enum Keys: String {
        case anchor = "libre-direct.healthkit.anchor"
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
    
    var anchor: HKQueryAnchor? {
        get {
            var anchor = HKQueryAnchor.init(fromValue: 0)
            
            if UserDefaults.shared.object(forKey: UserDefaults.Keys.anchor.rawValue) != nil {
                let data = UserDefaults.shared.object(forKey: UserDefaults.Keys.anchor.rawValue) as! Data
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
                UserDefaults.shared.removeObject(forKey: UserDefaults.Keys.anchor.rawValue)
                return
            }
            
            do {
                let data : Data = try NSKeyedArchiver.archivedData(withRootObject: newValue as Any, requiringSecureCoding: false)
                UserDefaults.shared.set(data, forKey: UserDefaults.Keys.anchor.rawValue)
            } catch {
                DirectLog.error("Could not encode healthkit anchor, so clearing out existing one", error: error)
                UserDefaults.shared.removeObject(forKey: UserDefaults.Keys.anchor.rawValue)
            }
        }
    }
}
