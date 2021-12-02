//
//  VirtualLibre.swift
//  LibreDirect
//

import Foundation

func virtualLibreMiddelware() -> Middleware<AppState, AppAction> {
    return sensorMiddelware(service: VirtualLibreService())
}

// MARK: - VirtualLibreService

final class VirtualLibreService: SensorServiceProtocol {
    // MARK: Internal

    func pairSensor(updatesHandler: @escaping SensorUpdatesHandler) {
        let sensor = Sensor(
            uuid: Data(hexString: "e9ad9b6c79bd93aa")!,
            patchInfo: Data(hexString: "448cd1")!,
            factoryCalibration: FactoryCalibration(i1: 1, i2: 2, i3: 4, i4: 8, i5: 16, i6: 32),
            customCalibration: [],
            family: .unknown,
            type: .virtual,
            region: .european,
            serial: "OBIR2PO",
            state: .starting,
            age: initAge,
            lifetime: 24 * 60,
            warmupTime: warmupTime
        )

        updatesHandler(SensorUpdate(sensor: sensor))
    }

    func sendNextGlucose() {
        Log.info("direction: \(direction)")

        let currentGlucose = nextGlucose
        Log.info("currentGlucose: \(currentGlucose)")

        age = age + 1

        updatesHandler?(SensorStateUpdate(sensorAge: age, sensorState: age > warmupTime ? .ready : .starting))

        if age > warmupTime {
            updatesHandler?(SensorReadingUpdate(nextReading: SensorReading(id: UUID(), timestamp: Date(), glucoseValue: Double(currentGlucose))))
        }

        let nextAddition = direction == .up ? 1 : -1

        nextGlucose = currentGlucose + (nextAddition * Int.random(in: 0 ..< 12))
        lastGlucose = currentGlucose

        Log.info("nextGlucose: \(nextGlucose)")

        if direction == .up, currentGlucose > nextRotation {
            direction = .down
            nextRotation = Int.random(in: 50 ..< 80)

            Log.info("nextRotation: \(nextRotation)")
        } else if direction == .down, currentGlucose < nextRotation {
            direction = .up
            nextRotation = Int.random(in: 160 ..< 240)

            Log.info("nextRotation: \(nextRotation)")
        }
    }

    func connectSensor(sensor: Sensor, updatesHandler: @escaping SensorUpdatesHandler) {
        self.updatesHandler = updatesHandler
        self.sensor = sensor

        let fireDate = Date().rounded(on: 1, .minute).addingTimeInterval(60)
        let timer = Timer(fire: fireDate, interval: glucoseInterval, repeats: true) { _ in
            Log.info("fires at \(Date())")

            self.sendNextGlucose()
        }

        RunLoop.main.add(timer, forMode: .common)

        updatesHandler(SensorConnectionStateUpdate(connectionState: .connected))
    }

    func disconnectSensor() {
        timer?.invalidate()
        timer = nil

        updatesHandler?(SensorConnectionStateUpdate(connectionState: .disconnected))
    }

    // MARK: Private

    private var initAge = 0
    private var warmupTime = 5
    private var age = 0
    private let glucoseInterval = TimeInterval(60)

    private var updatesHandler: SensorUpdatesHandler?
    private var sensor: Sensor?
    private var timer: Timer?

    private var direction: VirtualLibreDirection = .up

    private var nextGlucose = 100
    private var nextRotation = 112
    private var lastGlucose = 100
}

// MARK: - VirtualLibreDirection

private enum VirtualLibreDirection: String {
    case up = "Up"
    case down = "Down"
}

private let savedSensor = "eyJuZmNTY2FuVGltZXN0YW1wIjo2NTg4NjAwNzIuMzA2NTUwMDMsInV1aWQiOiJLWENFQWdDa0IrQT0iLCJzdGF0ZSI6IlNlbnNvciBpcyByZWFkeSIsInBhdGNoSW5mbyI6Im5RZ3dBWGdRIiwiYWdlIjoxMjc4OCwiZmFtaWx5IjozLCJjdXN0b21DYWxpYnJhdGlvbiI6W10sInNlcmlhbCI6IjNNSDAwNTEzSDU0IiwidHlwZSI6IkxpYnJlIDIgRVUiLCJyZWdpb24iOiIxIC0gRXVyb3BlYW4iLCJmYWN0b3J5Q2FsaWJyYXRpb24iOnsiaTMiOjI2LCJpNiI6Njg2NCwiaTIiOjY5NiwiaTUiOjExNTMyLCJpMSI6MCwiaTQiOjY4MjB9LCJsaWZldGltZSI6MjA4MDksImZyYW0iOiJhd3JBRlFNQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQURkY0NFeTRHQUVnYWdDRUdBQkFhZ0o4R0FQd1pnSmNHQU93WmdKRUdBRHdhZ0ljR0FCZ2FnSHNHQVBnWmdIRUdBT1FaZ0djR0FPQVpnRjBHQVBRWmdGY0dBT2daZ0U0R0FPZ1pnRU1HQU9BWmdEd0dBQXdhZ0RrR0FCUWFnRE1HQUNnYWdMa0RBREFiZ0tzREFOd2FnSE1EQU5RYWdJMERBT2dhZ0pzREFJQWFnSUVEQUhRYWdGVURBSWdhZ0k4REFPd2FnSDBEQUlnYmdQOERBTXdhZ0NFRkFGd2FnSmtHQUV3YWdKUUhBR0FhZ093SEFDZ2FnTlVIQU5BYWdBNElBSVFhZ0lzSEFKUWFnTkVHQUFRYWdFVUdBT0FaZ0wwREFJeGNnT1FEQUpRYmdDZ0VBRHdiZ0pnRUFCd2JnSW9FQUF3YmdLTUVBTmdhZ0xrRUFQaGFnTDBFQU5SYWdBY0ZBT0FhZ1BrRUFBd2JnTFVFQUNnZGdDNEVBTHdiZ01nREFMUWRnSU1vQVFDdXN6QUJUQXRKVVJRRGxvQmFBTTJtR3FRYUFBQkRTMnM9In0=".fromBase64()!

private func createPreviewSensor() -> Sensor? {
    let decoder = JSONDecoder()

    if let sensor = try? decoder.decode(Sensor.self, from: savedSensor) {
        return sensor
    }

    return nil
}
