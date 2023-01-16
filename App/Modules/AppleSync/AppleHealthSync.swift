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
        case .requestAppleHealthAccess(enabled: let enabled):
            if enabled {
                if !service.value.healthStoreAvailable {
                    break
                }
                
                return Future<DirectAction, DirectError> { promise in
                    service.value.requestAccess { granted in
                        if !granted {
                            promise(.failure(.withMessage("Calendar access declined")))
                            
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
            
            guard service.value.healthStoreAvailable else {
                DirectLog.info("Guard: HKHealthStore.isHealthDataAvailable is false")
                break
            }
            
            service.value.addGlucose(glucoseValues: glucoseValues)
            
        case .deleteBloodGlucose(glucose: let glucose):
            guard state.appleHealthExport else {
                DirectLog.info("Guard: state.appleHealth is false")
                break
            }
            
            guard service.value.healthStoreAvailable else {
                DirectLog.info("Guard: HKHealthStore.isHealthDataAvailable is false")
                break
            }
            
            service.value.deleteGlucose(glucose: glucose)
            
        case .addInsulinDelivery(insulinDeliveryValues: let insulinDeliveryValues):
            guard state.appleHealthExport else {
                DirectLog.info("Guard: state.appleHealth is false")
                break
            }
            
            guard service.value.healthStoreAvailable else {
                DirectLog.info("Guard: HKHealthStore.isHealthDataAvailable is false")
                break
            }
            
            service.value.addInsulinDelivery(insulinDeliveryValues: insulinDeliveryValues)
            
        case .deleteInsulinDelivery(insulinDelivery: let insulinDelivery):
            guard state.appleHealthExport else {
                DirectLog.info("Guard: state.appleHealth is false")
                break
            }
            
            guard service.value.healthStoreAvailable else {
                DirectLog.info("Guard: HKHealthStore.isHealthDataAvailable is false")
                break
            }
            
            service.value.deleteInsulinDelivery(insulinDelivery: insulinDelivery)
            
        case .addSensorGlucose(glucoseValues: let glucoseValues):
            guard state.appleHealthSync else {
                DirectLog.info("Guard: state.appleHealth is false")
                break
            }
            
            guard service.value.healthStoreAvailable else {
                DirectLog.info("Guard: HKHealthStore.isHealthDataAvailable is false")
                break
            }
                    
            service.value.addGlucose(glucoseValues: glucoseValues)
             
        case .loadAppleHealth:
            guard state.appleHealthSync else {
                DirectLog.info("Guard: state.appleHealth is false")
                break
            }
            
            guard service.value.healthStoreAvailable else {
                DirectLog.info("Guard: HKHealthStore.isHealthDataAvailable is false")
                break
            }
            
            return Future<DirectAction, DirectError> { promise in
                service.value.syncDataFromAppleHealth { newExternalValues in
                    promise(.success(.addBloodGlucose(glucoseValues: newExternalValues)))
                }
            }.eraseToAnyPublisher()
            
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
            
            guard service.value.healthStoreAvailable else {
                DirectLog.info("Guard: HKHealthStore.isHealthDataAvailable is false")
                break
            }
            

            
            
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
    
    func requestAccess(completionHandler: @escaping AppleHealthExportHandler) {
        guard let healthStore = healthStore else {
            return
        }

        healthStore.requestAuthorization(toShare: requiredWritePermissions, read: requiredReadPermissions) { granted, error in
            if granted, error == nil {
                completionHandler(true)
            } else {
                completionHandler(false)
            }
        }
    }
    
    func addGlucose(glucoseValues: [any Glucose]) {
        guard let healthStore = healthStore else {
            return
        }
        
        healthStore.requestAuthorization(toShare: requiredWritePermissions, read: requiredReadPermissions) { [weak self] granted, error in
            guard granted else {
                DirectLog.info("Guard: HKHealthStore.requestAuthorization failed, error: \(error?.localizedDescription)")
                return
            }

            glucoseValues.forEach { [weak self] glucose in
                self?.getSample(for: glucose.id) {  [weak self] sample in
                    var metadata:[String : Any] = [
                        HKMetadataKeyExternalUUID: glucose.id.uuidString,
                        HKMetadataKeySyncIdentifier: glucose.id.uuidString,
                        HKMetadataKeySyncVersion: 2,
                        HKMetadataKeyWasUserEntered:  type(of: glucose) == BloodGlucose.self && (glucose as! BloodGlucose).isExternal(),
                    ]
                    
                    if (type(of: glucose) == SensorGlucose.self) {
                        // Add in the sensor data to HealthKit
                        metadata[HKMetadataKeyDeviceSerialNumber] = UserDefaults.shared.sensor?.serial
                        metadata[HKMetadataKeyDeviceManufacturerName] = UserDefaults.shared.sensor?.type.rawValue
                    }
                    
                    guard let retrievedSample = sample else {
                        let newSample = HKQuantitySample(
                            type: self!.glucoseType,
                            quantity: HKQuantity(unit: .milligramsPerDeciliter, doubleValue: Double(glucose.glucoseValue)),
                            start: glucose.timestamp,
                            end: glucose.timestamp,
                            metadata: metadata
                        )
                        healthStore.save(newSample) { success, error in
                            if !success {
                                DirectLog.info("Guard: Writing data to apple health store failed, error: \(error?.localizedDescription)")
                            }
                        }
                        return
                    }
                    
                    if (retrievedSample.sourceRevision.source.bundleIdentifier == DirectConfig.appBundle) {
                        //This sample is our own, so lets update the metadata.
                        //retrievedSample.metadata = metadata
                    }
                    healthStore.save(retrievedSample) { success, error in
                        if !success {
                            DirectLog.info("Guard: Writing data to apple health store failed, error: \(error?.localizedDescription)")
                        }
                    }
                }
            }

        }
    }
    
    func syncDataFromAppleHealth(completionHandler: @escaping AppleHealthLoadFromAppleHealthHandler) {
        guard let healthStore = healthStore else {
            completionHandler([])
            return
        }
        
        healthStore.requestAuthorization(toShare: requiredWritePermissions, read: requiredReadPermissions) {  granted, error in
            guard granted else {
                DirectLog.info("Guard: HKHealthStore.requestAuthorization failed, error: \(error?.localizedDescription)")
                completionHandler([])
                return
            }
        
            
            let query = HKSampleQuery(sampleType: self.glucoseType, predicate: nil, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil) {
                query, results, error in
                
                guard let samples = results as? [HKQuantitySample] else {
                    // Handle any errors here.
                    completionHandler([])
                    return 
                }
                
                
                var newExternalValues: [BloodGlucose] = []
                for sample in samples {
                    let sourceName = sample.sourceRevision.source.name
                    let sourceBundle = sample.sourceRevision.source.bundleIdentifier
//
//                    if (sourceBundle == DirectConfig.appBundle) {
//                        //The value came from our app, so we don't need to load it back in.
//                        continue
//                    }
                    
                    
                    // First try and use HKMetadataKeyExternalUUID
                    // If HKMetadataKeyExternalUUID does not exist, use ID.
                    let id = sample.metadata?[HKMetadataKeyExternalUUID] as? UUID ?? sample.uuid
                                        
                    let bloodGlucose = DataStore.shared.getBloodGlucose(for: id)
                    if (bloodGlucose != nil) {
                        continue
                    }
                    
                    let syncedGlucose = BloodGlucose(id: id, timestamp: sample.startDate, glucoseValue: Int(sample.quantity.doubleValue(for: .milligramsPerDeciliter)), originatingSourceName: sourceName, originatingSourceBundle: sourceBundle)
                    newExternalValues.append(syncedGlucose)
                }
                
                completionHandler(newExternalValues)
            }
            
            healthStore.execute(query)
            
            //TODO:
            // 1. Read all glucose & insulin from Apple Health, match against local database.
            // 2. If not in local database, add to local database
            // 3. Loop all local values and make sure in Apple Health
        }
    }
    
    func deleteGlucose(glucose: any Glucose) {
        guard let healthStore = healthStore else {
            return
        }
        
        healthStore.requestAuthorization(toShare: requiredPermissions, read: nil) { granted, error in
            guard granted else {
                DirectLog.info("Guard: HKHealthStore.requestAuthorization failed, error: \(error?.localizedDescription)")
                return
            }
            
            healthStore.deleteObjects(of: self.insulinType, predicate: HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeySyncIdentifier,
                                                                                                   allowedValues: [glucose.id.uuidString])) { success, numberDeleted, error in
                if !success {
                    DirectLog.info("Guard: Deleting glucose data in apple health store failed, error: \(error?.localizedDescription)")
                    return
                }
                
                DirectLog.info("Deleted \(numberDeleted) glucose delivery records from HealthKit")
            }
        }
    }
    
    func syncAppleHealth() {
        guard let healthStore = healthStore else {
            return
        }

        healthStore.requestAuthorization(toShare: requiredWritePermissions, read: requiredReadPermissions) { granted, error in
            guard granted else {
                DirectLog.info("Guard: HKHealthStore.requestAuthorization failed, error: \(error?.localizedDescription)")
                return
            }

            //TODO:
            // 1. Read all glucose from Apple Health, match against local database.
            // 2. If not in local database, add to local database
            // 3. Loop all local values and make sure in Apple Health
        }
    }
    
    func addInsulinDelivery(insulinDeliveryValues: [InsulinDelivery]) {
        guard let healthStore = healthStore else {
            return
        }
        
        healthStore.requestAuthorization(toShare: requiredPermissions, read: nil) { granted, error in
            guard granted else {
                DirectLog.info("Guard: HKHealthStore.requestAuthorization failed, error: \(error?.localizedDescription)")
                return
            }
            
            let healthInsulinDeliveryValues = insulinDeliveryValues.map { insulinDelivery in
                HKQuantitySample(
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
            }.compactMap { $0 }
            
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
            return
        }
        
        healthStore.requestAuthorization(toShare: requiredPermissions, read: nil) { granted, error in
            guard granted else {
                DirectLog.info("Guard: HKHealthStore.requestAuthorization failed, error: \(error?.localizedDescription)")
                return
            }
            
            healthStore.deleteObjects(of: self.insulinType, predicate: HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeySyncIdentifier,
                                                                                                   allowedValues: [insulinDelivery.id.uuidString])) { success, numberDeleted, error in
                if !success {
                    DirectLog.info("Guard: Deleting insulin data in apple health store failed, error: \(error?.localizedDescription)")
                    return
                }
                
                DirectLog.info("Deleted \(numberDeleted) insulin delivery records from HealthKit")
            }
        }
    }


    // MARK: Private
    
    private lazy var healthStore: HKHealthStore? = {
        if HKHealthStore.isHealthDataAvailable() {
            return HKHealthStore()
        }
        
        return nil
    }()
}

private extension AppleHealthExportService {
    func getSample(for id: UUID, completionHandler: @escaping AppleHealthLoadHealthKitSample) {
        guard let healthStore = healthStore else {
            return
        }
        
        healthStore.requestAuthorization(toShare: requiredWritePermissions, read: requiredReadPermissions) { granted, error in
            guard granted else {
                DirectLog.info("Guard: HKHealthStore.requestAuthorization failed, error: \(error?.localizedDescription)")
                return
            }
            
            
            let query = HKSampleQuery(sampleType: self.glucoseType, predicate: NSPredicate(format: "%K == %@", HKMetadataKeyExternalUUID, id.uuidString, HKPredicateKeyPathUUID, id.uuidString), limit: 1, sortDescriptors: nil) {
                query, results, error in
                guard let samples = results as? [HKQuantitySample] else {
                    completionHandler(nil)
                    return
                }
                
                DirectLog.debug("\(samples.first)")
                
                guard let sample = samples.first else {
                    completionHandler(nil)
                    return
                }
                completionHandler(sample)
            }
            
            healthStore.execute(query)
        }
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
