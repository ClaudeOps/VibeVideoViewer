//
//  Logger.swift
//  VibeVideoViewer
//
//  Created by Claude Wilder on 2025-11-09.
//

import Foundation
import os.log

// MARK: - App Logger

struct AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.app.videoplayer"
    
    // Category loggers
    static let general = OSLog(subsystem: subsystem, category: "General")
    static let playback = OSLog(subsystem: subsystem, category: "Playback")
    static let fileOps = OSLog(subsystem: subsystem, category: "FileOperations")
    static let scan = OSLog(subsystem: subsystem, category: "Scan")
    static let settings = OSLog(subsystem: subsystem, category: "Settings")
    static let ui = OSLog(subsystem: subsystem, category: "UI")
    
    // Helper methods
    static func logError(_ error: Error, category: OSLog = general) {
        os_log(.error, log: category, "❌ Error: %{public}@", error.localizedDescription)
    }
    
    static func logInfo(_ message: String, category: OSLog = general) {
        os_log(.info, log: category, "ℹ️ %{public}@", message)
    }
    
    static func logDebug(_ message: String, category: OSLog = general) {
        os_log(.debug, log: category, "🔍 %{public}@", message)
    }
    
    static func logWarning(_ message: String, category: OSLog = general) {
        os_log(.default, log: category, "⚠️ %{public}@", message)
    }
}
