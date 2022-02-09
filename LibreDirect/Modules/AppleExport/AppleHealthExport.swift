//
//  AppleHealth.swift
//  LibreDirect
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
        case .setAppleHealthExport(enabled: let enabled):
            if enabled {
                if !service.value.healthStoreAvailable {
                    return Just(AppAction.setAppleHealthExport(enabled: false))
                        .setFailureType(to: AppError.self)
                        .eraseToAnyPublisher()
                }

                return Future<AppAction, AppError> { promise in
                    service.value.requestAccess { granted in
                        if !granted {
                            promise(.success(.setAppleHealthExport(enabled: false)))

                        } else {
                            promise(.failure(.withMessage("Calendar access declined")))
                        }
                    }
                }.eraseToAnyPublisher()
            }

        case .addGlucoseValues(glucoseValues: let glucoseValues):
            guard state.appleHealthExport else {
                AppLog.info("Guard: state.appleHealth is false")
                break
            }

            guard service.value.healthStoreAvailable else {
                AppLog.info("Guard: HKHealthStore.isHealthDataAvailable is false")
                break
            }

            if glucoseValues.count > 1 {
                let filteredGlucoseValues = glucoseValues.filter { glucose in
                    glucose.type != .none
                }

                service.value.addGlucose(glucoseValues: filteredGlucoseValues)
            } else if let glucose = glucoseValues.first, (glucose.type == .cgm && glucose.is5Minutely || state.sensorInterval > 1) || glucose.type == .bgm {
                service.value.addGlucose(glucoseValues: [glucose])
            }

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
        AppLog.info("Create AppleHealthExportService")
    }

    // MARK: Internal

    static var glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose)!

    static var requiredPermissions: Set<HKSampleType> {
        Set([glucoseType].compactMap { $0 })
    }

    var healthStoreAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAccess(completionHandler: @escaping AppleHealthExportHandler) {
        healthStore?.requestAuthorization(toShare: AppleHealthExportService.requiredPermissions, read: nil) { granted, error in
            if granted, error == nil {
                completionHandler(true)
            } else {
                completionHandler(false)
            }
        }
    }

    func addGlucose(glucoseValues: [Glucose]) {
        healthStore?.requestAuthorization(toShare: AppleHealthExportService.requiredPermissions, read: nil) { granted, error in
            guard granted else {
                AppLog.info("Guard: HKHealthStore.requestAuthorization failed, error: \(error?.localizedDescription)")
                return
            }

            let healthGlucoseValues = glucoseValues.map {
                HKQuantitySample(
                    type: AppleHealthExportService.glucoseType,
                    quantity: HKQuantity(unit: .milligramsPerDeciliter, doubleValue: Double($0.glucoseValue!)),
                    start: $0.timestamp,
                    end: $0.timestamp,
                    metadata: [
                        HKMetadataKeyExternalUUID: $0.id.uuidString,
                        HKMetadataKeySyncIdentifier: $0.id.uuidString,
                        HKMetadataKeySyncVersion: 1
                    ]
                )
            }

            self.healthStore?.save(healthGlucoseValues) { success, error in
                if !success {
                    AppLog.info("Guard: Writing data to apple health store failed, error: \(error?.localizedDescription)")
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
    static let milligramsPerDeciliter: HKUnit = {
        HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
    }()
}
