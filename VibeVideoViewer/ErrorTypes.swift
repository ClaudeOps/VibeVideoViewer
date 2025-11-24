//
//  ErrorTypes.swift
//  VibeVideoViewer
//
//  Created by Claude Wilder on 2025-11-09.
//

import Foundation

// MARK: - App Errors

enum VideoPlayerError: LocalizedError {
    case folderAccessDenied(String)
    case folderNotFound(String)
    case noVideosFound
    case fileMoveFailedDestinationNotFound(String)
    case fileMoveFailedPermission(String)
    case fileMoveFailedUnknown(String, Error)
    case fileDeleteFailed(String, Error)
    case invalidVideoFile(String)
    case scanCancelled
    case playerInitializationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .folderAccessDenied(let path):
            return "Access Denied: Unable to access folder at '\(path)'. Please check permissions."
        case .folderNotFound(let path):
            return "Folder Not Found: The folder at '\(path)' does not exist or has been moved."
        case .noVideosFound:
            return "No videos found in the selected folder."
        case .fileMoveFailedDestinationNotFound(let destination):
            return "Move Failed: Destination folder '\(destination)' does not exist."
        case .fileMoveFailedPermission(let filename):
            return "Move Failed: Permission denied when trying to move '\(filename)'."
        case .fileMoveFailedUnknown(let filename, let error):
            return "Move Failed: Unable to move '\(filename)'. \(error.localizedDescription)"
        case .fileDeleteFailed(let filename, let error):
            return "Delete Failed: Unable to delete '\(filename)'. \(error.localizedDescription)"
        case .invalidVideoFile(let filename):
            return "Invalid Video: '\(filename)' is not a valid video file."
        case .scanCancelled:
            return "Folder scan was cancelled."
        case .playerInitializationFailed(let filename):
            return "Playback Error: Unable to play '\(filename)'."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .folderAccessDenied:
            return "Try selecting a different folder or check system permissions in System Settings > Privacy & Security."
        case .folderNotFound:
            return "The folder may have been moved or deleted. Please select a different folder."
        case .noVideosFound:
            return "Make sure the folder contains supported video files (MP4, MOV, M4V, 3GP)."
        case .fileMoveFailedDestinationNotFound:
            return "Set a move location in Settings (⌘⇧S) or create the destination folder."
        case .fileMoveFailedPermission:
            return "Check that you have write permissions for the destination folder."
        case .fileMoveFailedUnknown, .fileDeleteFailed:
            return "Try closing other apps that might be using this file, or restart the app."
        case .invalidVideoFile:
            return "This file may be corrupted or in an unsupported format."
        case .scanCancelled:
            return nil
        case .playerInitializationFailed:
            return "Try skipping to the next video. The file may be corrupted."
        }
    }
}
