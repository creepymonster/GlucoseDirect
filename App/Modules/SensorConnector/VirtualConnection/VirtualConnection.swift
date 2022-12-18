//
//  VirtualConnection.swift
//  GlucoseDirect
//

import Combine
import Foundation

// MARK: - VirtualLibreConnection

class VirtualLibreConnection: SensorConnectionProtocol, IsSensor {
    // MARK: Lifecycle

    init(subject: PassthroughSubject<DirectAction, DirectError>) {
        self.subject = subject
    }

    // MARK: Internal

    weak var subject: PassthroughSubject<DirectAction, DirectError>?

    func getConfiguration(sensor: Sensor) -> [SensorConnectionConfigurationOption] {
        return []
    }

    func pairConnection() {
        let sensor = Sensor(
            family: .unknown,
            type: .virtual,
            region: .european,
            serial: "OBIR2PO",
            state: .ready,
            age: initAge,
            lifetime: 14 * 24 * 60,
            warmupTime: warmupTime
        )

        sendUpdate(sensor: sensor)
        sendUpdate(isPaired: true)

        if sensor.age >= sensor.lifetime {
            sendUpdate(age: sensor.age, state: .expired)

        } else if sensor.age > sensor.warmupTime {
            sendUpdate(age: sensor.age, state: sensor.state)
            sendUpdate(readings: [
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(30), glucoseValue: 77),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(29), glucoseValue: 83),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(28), glucoseValue: 85),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(27), glucoseValue: 84),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(26), glucoseValue: 84),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(25), glucoseValue: 83),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(24), glucoseValue: 83),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(23), glucoseValue: 81),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(22), glucoseValue: 82),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(21), glucoseValue: 83),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(20), glucoseValue: 83),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(19), glucoseValue: 82),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(18), glucoseValue: 81),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(17), glucoseValue: 80),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(16), glucoseValue: 79),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(15), glucoseValue: 79),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(14), glucoseValue: 79),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(13), glucoseValue: 81),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(12), glucoseValue: 83),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(11), glucoseValue: 85),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(10), glucoseValue: 86),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(9), glucoseValue: 84),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(8), glucoseValue: 80),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(7), glucoseValue: 79),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(6), glucoseValue: 79),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(5), glucoseValue: 81),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(4), glucoseValue: 84),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(3), glucoseValue: 88),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(2), glucoseValue: 90),
                SensorReading.createGlucoseReading(timestamp: generateHistoryTimestamp(1), glucoseValue: 96)
            ])

        } else if sensor.age <= sensor.warmupTime {
            sendUpdate(age: sensor.age, state: .starting)
        }
    }

    func connectConnection(sensor: Sensor, sensorInterval: Int) {
        self.sensor = sensor
        self.sensorInterval = TimeInterval(sensorInterval * 60)

        let fireDate = Date()
        let timer = Timer(fire: fireDate, interval: self.sensorInterval, repeats: true) { _ in
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
    private var sensorInterval = TimeInterval(60)
    private var sensor: Sensor?
    private var timer: Timer?
    private var direction: VirtualGlucoseDirection = .up
    private var nextGlucose = 100
    private var nextRotation = 112
    private var lastGlucose = 100

    private func generateHistoryTimestamp(_ factor: Double) -> Date {
        Date() - factor * 60
    }

    private func sendNextGlucose() {
        DirectLog.info("direction: \(direction)")

        let currentGlucose = nextGlucose
        DirectLog.info("currentGlucose: \(currentGlucose)")

        age = age + 1

        sendUpdate(age: age, state: age > warmupTime ? .ready : .starting)

        if age > warmupTime {
            let sensorReading = Int.random(in: 0 ..< 100) <= 5
                ? SensorReading.createFaultyReading(timestamp: Date(), quality: .AVG_DELTA_EXCEEDED)
                : SensorReading.createGlucoseReading(timestamp: Date(), glucoseValue: Double(currentGlucose))

            sendUpdate(reading: sensorReading)
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
