//
//  Models.swift
//  VibeVideoViewer
//
//  Created by Claude Wilder on 2025-10-10.
//


import Foundation

// MARK: - Enums

enum SortOption: String, CaseIterable {
    case fileName = "File Name"
    case filePath = "File Path"
    case sizeAscending = "Size (Smallest First)"
    case sizeDescending = "Size (Largest First)"
    case random = "Random"
}

enum PlaybackEndOption: String, CaseIterable {
    case stop = "Stop"
    case replay = "Replay"
    case playNext = "Play Next"
}

// MARK: - Video File Model

struct VideoFile: Identifiable {
    let id = UUID()
    let url: URL
    let size: Int64
    
    var name: String {
        url.lastPathComponent
    }
    
    var path: String {
        url.path
    }
}

// MARK: - Settings Model

struct AppSettings {
    var seekForwardSeconds: Double
    var seekBackwardSeconds: Double
    var pauseOnLoseFocus: Bool
    var autoResumeOnFocus: Bool
    var moveLocationPath: String?
    var includeSubfolders: Bool
    
    static let defaultSettings = AppSettings(
        seekForwardSeconds: 10,
        seekBackwardSeconds: 10,
        pauseOnLoseFocus: true,
        autoResumeOnFocus: false,
        moveLocationPath: nil,
        includeSubfolders: true
    )
}
