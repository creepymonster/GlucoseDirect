//
//  VirtualConnection.swift
//  GlucoseDirect
//

import Combine
import Foundation

// MARK: - VirtualLibreConnection

final class VirtualLibreConnection: SensorBLEConnection, IsSensor {
    // MARK: Lifecycle

    init(subject: PassthroughSubject<AppAction, AppError>) {
        DirectLog.info("init")
        self.subject = subject
    }

    // MARK: Internal

    weak var subject: PassthroughSubject<AppAction, AppError>?

    func pairConnection() {
        let sensor = Sensor(
            uuid: Data(hexString: "e9ad9b6c79bd93aa")!,
            patchInfo: Data(hexString: "448cd1")!,
            factoryCalibration: FactoryCalibration(i1: 1, i2: 2, i3: 4, i4: 8, i5: 16, i6: 32),
            family: .unknown,
            type: .virtual,
            region: .european,
            serial: "OBIR2PO",
            state: .ready,
            age: initAge,
            lifetime: 24 * 60,
            warmupTime: warmupTime
        )

        sendUpdate(sensor: sensor)
        sendUpdate(isPaired: true)
    }

    func connectConnection(sensor: Sensor, sensorInterval: Int) {
        glucoseInterval = TimeInterval(sensorInterval * 60)

        let fireDate = Date().toRounded(on: 1, .minute).addingTimeInterval(60)
        let timer = Timer(fire: fireDate, interval: glucoseInterval, repeats: true) { _ in
            DirectLog.info("fires at \(Date())")

            self.sendNextGlucose()
        }

        RunLoop.main.add(timer, forMode: .common)

        sendUpdate(connectionState: .connected)
    }

    func disconnectConnection() {
        timer?.invalidate()
        timer = nil

        sendUpdate(connectionState: .disconnected)
    }

    // MARK: Private

    private var initAge = 120
    private var warmupTime = 60
    private var age = 120
    private var glucoseInterval = TimeInterval(60)
    private var sensor: Sensor?
    private var timer: Timer?
    private var direction: VirtualGlucoseDirection = .up
    private var nextGlucose = 100
    private var nextRotation = 112
    private var lastGlucose = 100

    private func sendNextGlucose() {
        DirectLog.info("direction: \(direction)")

        let currentGlucose = nextGlucose
        DirectLog.info("currentGlucose: \(currentGlucose)")

        age = age + 1

        sendUpdate(age: age, state: age > warmupTime ? .ready : .starting)

        if age > warmupTime {
            let sensorReading = Int.random(in: 0 ..< 100) < 2
                ? SensorReading.createFaultyReading(timestamp: Date(), quality: .AVG_DELTA_EXCEEDED)
                : SensorReading.createGlucoseReading(timestamp: Date(), glucoseValue: Double(currentGlucose))

            sendUpdate(sensorSerial: sensor?.serial ?? "", reading: sensorReading)
        }

        let nextAddition = direction == .up ? 1 : -1

        nextGlucose = currentGlucose + (nextAddition * Int.random(in: 0 ..< 12))
        lastGlucose = currentGlucose

        DirectLog.info("nextGlucose: \(nextGlucose)")

        if direction == .up, currentGlucose > nextRotation {
            direction = .down
            nextRotation = Int.random(in: 50 ..< 80)

            DirectLog.info("nextRotation: \(nextRotation)")
        } else if direction == .down, currentGlucose < nextRotation {
            direction = .up
            nextRotation = Int.random(in: 160 ..< 240)

            DirectLog.info("nextRotation: \(nextRotation)")
        }
    }
}

// MARK: - VirtualGlucoseDirection

private enum VirtualGlucoseDirection: String {
    case up = "Up"
    case down = "Down"
}

// TEST
