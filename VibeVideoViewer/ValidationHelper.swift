//
//  ValidationHelper.swift
//  VibeVideoViewer
//
//  Created by Claude Wilder on 2025-11-09.
//

import Foundation

// MARK: - Validation Helper

struct ValidationHelper {
    
    // MARK: - Folder Validation
    
    static func validateFolder(at url: URL) throws {
        let fileManager = FileManager.default
        
        // Check if folder exists
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            throw VideoPlayerError.folderNotFound(url.path)
        }
        
        // Check if it's actually a directory
        guard isDirectory.boolValue else {
            throw VideoPlayerError.folderNotFound(url.path)
        }
        
        // Check if readable
        guard fileManager.isReadableFile(atPath: url.path) else {
            throw VideoPlayerError.folderAccessDenied(url.path)
        }
    }
    
    // MARK: - Destination Validation
    
    static func validateDestination(path: String) throws {
        let fileManager = FileManager.default
        
        // Check if destination exists
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
            throw VideoPlayerError.fileMoveFailedDestinationNotFound(path)
        }
        
        // Check if it's a directory
        guard isDirectory.boolValue else {
            throw VideoPlayerError.fileMoveFailedDestinationNotFound(path)
        }
        
        // Check if writable
        guard fileManager.isWritableFile(atPath: path) else {
            throw VideoPlayerError.fileMoveFailedPermission(path)
        }
    }
    
    // MARK: - Settings Validation
    
    static func validateSeekTime(_ seconds: Double) -> Bool {
        return seconds >= 1 && seconds <= 60
    }
    
    static func sanitizeSeekTime(_ seconds: Double) -> Double {
        return max(1, min(60, seconds))
    }
    
    // MARK: - File Path Validation
    
    static func isValidVideoExtension(_ url: URL) -> Bool {
        let validExtensions = ["mp4", "mov", "m4v", "3gp"]
        return validExtensions.contains(url.pathExtension.lowercased())
    }
    
    static func sanitizeFileName(_ name: String) -> String {
        // Remove or replace invalid characters
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return name.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
    
    // MARK: - Disk Space Validation
    
    static func hasEnoughDiskSpace(for fileSize: Int64, at url: URL) -> Bool {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: url.path)
            if let freeSpace = attributes[.systemFreeSize] as? NSNumber {
                // Require at least 100MB more than file size as buffer
                let requiredSpace = fileSize + (100 * 1024 * 1024)
                return freeSpace.int64Value > requiredSpace
            }
        } catch {
            AppLogger.logError(error, category: AppLogger.fileOps)
        }
        return false
    }
    
    // MARK: - URL Validation
    
    static func isSecurePath(_ url: URL) -> Bool {
        // Prevent path traversal attacks
        let path = url.standardized.path
        let components = path.components(separatedBy: "/")
        
        // Check for suspicious patterns
        let suspiciousPatterns = ["..", "~", "//"]
        for pattern in suspiciousPatterns {
            if components.contains(pattern) || path.contains(pattern) {
                return false
            }
        }
        
        return true
    }
}
