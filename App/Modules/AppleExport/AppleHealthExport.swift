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
                            promise(.success(.setAppleHealthExport(enabled: true)))
                        }
                    }
                }.eraseToAnyPublisher()
            } else {
                return Just(DirectAction.setAppleHealthExport(enabled: false))
                    .setFailureType(to: DirectError.self)
                    .eraseToAnyPublisher()
            }
            
        case .addBloodGlucose(glucoseValues: let glucoseValues):
            guard state.appleHealthExport else {
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
            guard state.appleHealthExport else {
                DirectLog.info("Guard: state.appleHealth is false")
                break
            }
            
            guard service.value.healthStoreAvailable else {
                DirectLog.info("Guard: HKHealthStore.isHealthDataAvailable is false")
                break
            }
            
            service.value.addGlucose(glucoseValues: glucoseValues)
            
        case .deleteSensorGlucose(glucose: let glucose):
            guard state.appleHealthExport else {
                DirectLog.info("Guard: state.appleHealth is false")
                break
            }
            
            guard service.value.healthStoreAvailable else {
                DirectLog.info("Guard: HKHealthStore.isHealthDataAvailable is false")
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
    
    var insulinType: HKQuantityType {
        HKObjectType.quantityType(forIdentifier: .insulinDelivery)!
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
        
        healthStore.requestAuthorization(toShare: requiredPermissions, read: nil) { granted, error in
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
        
        healthStore.requestAuthorization(toShare: requiredPermissions, read: nil) { granted, error in
            guard granted else {
                DirectLog.info("Guard: HKHealthStore.requestAuthorization failed, error: \(error?.localizedDescription)")
                return
            }
            
            let healthGlucoseValues = glucoseValues.map { glucose in
                HKQuantitySample(
                    type: self.glucoseType,
                    quantity: HKQuantity(unit: .milligramsPerDeciliter, doubleValue: Double(glucose.glucoseValue)),
                    start: glucose.timestamp,
                    end: glucose.timestamp,
                    metadata: [
                        HKMetadataKeyExternalUUID: glucose.id.uuidString,
                        HKMetadataKeySyncIdentifier: glucose.id.uuidString,
                        HKMetadataKeySyncVersion: 1
                    ]
                )
            }.compactMap { $0 }
            
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
