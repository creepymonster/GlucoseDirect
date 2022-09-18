//
//  TunnelSettingsView.swift
//  GlucoseDirectApp
//

import Combine
import Foundation
import NetworkExtension
import SwiftUI

// MARK: - TunnelSettingsView

struct TunnelSettingsView: View {
    @ObservedObject var service: TunnelService = .shared

    var body: some View {
        Button("SETUP", action: {
            service.setup()
        })

        Button("START", action: {
            service.start()
        })
    }
}

// MARK: - TunnelService

class TunnelService: ObservableObject {
    // MARK: Lifecycle

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(TunnelService.statusDidChange(_:)), name: NSNotification.Name.NEVPNStatusDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TunnelService.configurationDidChange(_:)), name: NSNotification.Name.NEVPNConfigurationChange, object: nil)
    }

    // MARK: Internal

    static let shared = TunnelService()

    @Published var status: TunnelStatus = .disconnected
    @Published var isEnabled = false

    func setup() {
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            guard let managers = managers else {
                return
            }

            if !managers.isEmpty {
                self.tunnelManager = managers[0]
            } else {
                self.tunnelManager = NETunnelProviderManager()
            }

            let tunnelProtocol = NETunnelProviderProtocol()
            tunnelProtocol.serverAddress = "Your Device"

            self.tunnelManager.localizedDescription = "Proxy"
            self.tunnelManager.protocolConfiguration = tunnelProtocol
            self.tunnelManager.isEnabled = true

            self.tunnelManager.saveToPreferences { error in
                if error == nil {
                    self.tunnelManager.loadFromPreferences { error in
                        if error == nil {
                            self.statusDidChange(nil)
                        }
                    }
                }
            }
        }
    }

    func start() {
        if tunnelManager.connection.status == .disconnected || tunnelManager.connection.status == .disconnecting {
            do {
                try tunnelManager.connection.startVPNTunnel()
            } catch {
                NSLog("Error enabling")
            }
        }
    }

    func stop() {
        if tunnelManager.connection.status == .connected || tunnelManager.connection.status == .connecting {
            tunnelManager.connection.stopVPNTunnel()
        }
    }

    @objc
    func statusDidChange(_ notification: Notification?) {
        DirectLog.info("statusDidChange")

        status = TunnelStatus(rawValue: tunnelManager.connection.status.rawValue) ?? .invalid
    }

    @objc
    func configurationDidChange(_ notification: Notification?) {
        DirectLog.info("configurationDidChange")

        isEnabled = tunnelManager.isEnabled
    }

    // MARK: Private

    private var tunnelManager: NETunnelProviderManager = .init()
}

// MARK: - TunnelStatus

enum TunnelStatus: Int {
    case invalid
    case disconnected
    case connecting
    case connected
    case reasserting
    case disconnecting
}
