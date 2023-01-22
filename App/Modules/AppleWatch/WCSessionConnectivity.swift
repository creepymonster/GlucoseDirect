//
//  WCSessionConnectivity.swift
//  GlucoseDirect
//
//
import Foundation
import WatchConnectivity
import WidgetKit
import Combine


final class WCSessionConnectivityService: NSObject, ObservableObject {
    static let shared = WCSessionConnectivityService()
    
    // Publish the latest sensor glucose so we can access it in Swift UI
    @Published var latestSensorGlucose: SensorGlucose? = nil
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
            #if os(iOS)
            guard let latestSensorGlucose = UserDefaults.shared.latestSensorGlucose else {
                return
            }
            self.send(latestSensorGlucose)
            #endif
        }
    }
    
    func send(_ sensorGlucose: SensorGlucose) {
        guard WCSession.default.activationState == .activated else {
          return
        }
        #if os(iOS)
        guard WCSession.default.isWatchAppInstalled else {
            return
        }
        #else
        guard WCSession.default.isCompanionAppInstalled else {
            return
        }
        #endif
                
        do {
            WCSession.default.sendMessageData(try JSONEncoder().encode(sensorGlucose), replyHandler: nil) { error in
                DirectLog.error("Cannot send message to watch", error: error)
            }
        } catch {
            DirectLog.error("Cannot encode message for watch", error: error)
        }
    }
}

extension WCSessionConnectivityService: WCSessionDelegate {
    
#if os(watchOS)
    /**
     On Apple Watch receive the messageData, as of now its always Sensor Glucose
     */
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        do {
            let sensorGlucose = try JSONDecoder().decode(SensorGlucose.self, from: messageData)
            self.latestSensorGlucose = sensorGlucose
            UserDefaults.shared.latestSensorGlucose = sensorGlucose
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            DirectLog.error("Cannot encode message from iOS", error: error)
        }
        
    }
#endif

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}
