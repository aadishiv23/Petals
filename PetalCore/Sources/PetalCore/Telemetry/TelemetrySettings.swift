//
//  TelemetrySettings.swift
//  PetalCore
//
//  Created by AI Assistant on 4/3/25.
//

import Foundation

@MainActor
public final class TelemetrySettings: ObservableObject {
    public static let shared = TelemetrySettings()

    private enum Keys {
        static let telemetryEnabled = "telemetry.enabled"
        static let verboseLoggingEnabled = "telemetry.verboseLoggingEnabled"
    }

    @Published public var telemetryEnabled: Bool {
        didSet { UserDefaults.standard.set(telemetryEnabled, forKey: Keys.telemetryEnabled) }
    }

    @Published public var verboseLoggingEnabled: Bool {
        didSet { UserDefaults.standard.set(verboseLoggingEnabled, forKey: Keys.verboseLoggingEnabled) }
    }

    private init() {
        let defaults = UserDefaults.standard
        self.telemetryEnabled = defaults.object(forKey: Keys.telemetryEnabled) as? Bool ?? true
        self.verboseLoggingEnabled = defaults.object(forKey: Keys.verboseLoggingEnabled) as? Bool ?? true
    }
}



