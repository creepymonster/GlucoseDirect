//
//  AppleHealth.swift
//  GlucoseDirect
//

import Combine
import Foundation
import HealthKit

func appleHealthExportMiddleware() -> Middleware<AppState, AppAction> {
    return appleHealthExportMiddleware(service: LazyService<AppleHealthExportService>(initialization: {
        AppleHealthExportService()
    }))
}

private func appleHealthExportMiddleware(service: LazyService<AppleHealthExportService>) -> Middleware<AppState, AppAction> {
    return { state, action, _ in
        switch action {
        case .requestAppleHealthAccess(enabled: let enabled):
            if enabled {
                if !service.value.healthStoreAvailable {
                    break
                }

                return Future<AppAction, AppError> { promise in
                    service.value.requestAccess { granted in
                        if !granted {
                            promise(.failure(.withMessage("Calendar access declined")))

                        } else {
                            promise(.success(.setAppleHealthExport(enabled: true)))
                        }
                    }
                }.eraseToAnyPublisher()
            } else {
                return Just(AppAction.setAppleHealthExport(enabled: false))
                    .setFailureType(to: AppError.self)
                    .eraseToAnyPublisher()
            }

        case .addGlucose(glucose: let glucose):
            guard state.appleHealthExport else {
                DirectLog.info("Guard: state.appleHealth is false")
                break
            }

            guard service.value.healthStoreAvailable else {
                DirectLog.info("Guard: HKHealthStore.isHealthDataAvailable is false")
                break
            }

            guard glucose.type == .cgm || glucose.type == .bgm else {
                break
            }

            service.value.addGlucose(glucose: glucose)

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

    var requiredPermissions: Set<HKSampleType> {
        Set([glucoseType])
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

    func addGlucose(glucose: Glucose) {
        guard let healthStore = healthStore else {
            return
        }

        guard let glucoseValue = glucose.glucoseValue else {
            return
        }

        healthStore.requestAuthorization(toShare: requiredPermissions, read: nil) { granted, error in
            guard granted else {
                DirectLog.info("Guard: HKHealthStore.requestAuthorization failed, error: \(error?.localizedDescription)")
                return
            }

            let healthGlucoseValues = HKQuantitySample(
                type: self.glucoseType,
                quantity: HKQuantity(unit: .milligramsPerDeciliter, doubleValue: Double(glucoseValue)),
                start: glucose.timestamp,
                end: glucose.timestamp,
                metadata: [
                    HKMetadataKeyExternalUUID: glucose.id.uuidString,
                    HKMetadataKeySyncIdentifier: glucose.id.uuidString,
                    HKMetadataKeySyncVersion: 1
                ]
            )

            healthStore.save(healthGlucoseValues) { success, error in
                if !success {
                    DirectLog.info("Guard: Writing data to apple health store failed, error: \(error?.localizedDescription)")
                }
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

// TEST
