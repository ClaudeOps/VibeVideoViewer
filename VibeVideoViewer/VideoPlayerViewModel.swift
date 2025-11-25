//
//  VideoPlayerApp.swift
//  VibeVideoViewer
//
//  Created by Claude Wilder on 2025-10-06.
//

import SwiftUI
import AVKit
import Combine
import Foundation

class VideoPlayerViewModel: ObservableObject {
    // Published state
    @Published var videoFiles: [VideoFile] = []
    @Published var selectedFolder: URL?
    @Published var isScanning = false
    @Published var currentIndex = 0
    @Published var player: AVPlayer?
    @Published var isPlaying = true
    
    // Computed property for current video file
    var currentVideoFile: VideoFile? {
        guard currentIndex >= 0 && currentIndex < videoFiles.count else {
            return nil
        }
        return videoFiles[currentIndex]
    }
    @Published var selectedSort: SortOption = .fileName {
        didSet {
            if !isLoadingPreferences {
                savePreferences()
            }
        }
    }
    @Published var playbackEndOption: PlaybackEndOption = .playNext {
        didSet {
            if !isLoadingPreferences { savePreferences() }
        }
    }
    @Published var shouldSelectFolder = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var showingSettings = false
    @Published var isMuted = false {
        didSet {
            player?.isMuted = isMuted
            if !isLoadingPreferences {
                savePreferences()
            }
        }
    }
    @Published var settings = AppSettings.defaultSettings {
        didSet {
            if !isLoadingPreferences {
                savePreferences()
            }
        }
    }
    @Published var errorMessage: String?
    @Published var showingError = false
    @Published var isFullScreen = false
    @Published var playbackSpeed: Float = 1.0 {
        didSet {
            player?.rate = isPlaying ? playbackSpeed : 0
            if !isLoadingPreferences {
                savePreferences()
            }
        }
    }
    
    private var isLoadingPreferences = false
    private var isTransitioningFullScreen = false
    private var wasPlayingBeforeFullScreen = false
    @Published var isSorting = false  // now published for testing scripts
    private let fileManager = FileManager.default
    private let videoExtensions = ["mp4", "mov", "m4v", "3gp"]
    private let availablePlaybackSpeeds: [Float] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    private var timeObserver: Any?
    private var endObserver: Any?
    private var currentScanID = UUID()
    
    // MARK: - Initialization
    
    init() {
        loadPreferences()
        // Always start muted for privacy
        isMuted = true
    }
    
    deinit {
        // Clean up observers
        if let player = player, let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - User Defaults Keys
    
    private enum PreferenceKeys {
        static let selectedSort = "selectedSort"
        static let playbackEndOption = "playbackEndOption"
        static let lastFolder = "lastFolder"
        static let seekForwardSeconds = "seekForwardSeconds"
        static let seekBackwardSeconds = "seekBackwardSeconds"
        static let isMuted = "isMuted"
        static let pauseOnLoseFocus = "pauseOnLoseFocus"
        static let autoResumeOnFocus = "autoResumeOnFocus"
        static let moveLocationPath = "moveLocationPath"
        static let includeSubfolders = "includeSubfolders"
        static let playbackSpeed = "playbackSpeed"
    }
    
    // MARK: - Preferences
    
    private func savePreferences() {
        UserDefaults.standard.set(selectedSort.rawValue, forKey: PreferenceKeys.selectedSort)
        UserDefaults.standard.set(playbackEndOption.rawValue, forKey: PreferenceKeys.playbackEndOption)
        if let folderPath = selectedFolder?.path {
            UserDefaults.standard.set(folderPath, forKey: PreferenceKeys.lastFolder)
        }
        UserDefaults.standard.set(settings.seekForwardSeconds, forKey: PreferenceKeys.seekForwardSeconds)
        UserDefaults.standard.set(settings.seekBackwardSeconds, forKey: PreferenceKeys.seekBackwardSeconds)
        UserDefaults.standard.set(isMuted, forKey: PreferenceKeys.isMuted)
        UserDefaults.standard.set(settings.pauseOnLoseFocus, forKey: PreferenceKeys.pauseOnLoseFocus)
        UserDefaults.standard.set(settings.autoResumeOnFocus, forKey: PreferenceKeys.autoResumeOnFocus)
        UserDefaults.standard.set(settings.includeSubfolders, forKey: PreferenceKeys.includeSubfolders)
        UserDefaults.standard.set(playbackSpeed, forKey: PreferenceKeys.playbackSpeed)
        if let moveLocationPath = settings.moveLocationPath {
            UserDefaults.standard.set(moveLocationPath, forKey: PreferenceKeys.moveLocationPath)
        } else {
            UserDefaults.standard.removeObject(forKey: PreferenceKeys.moveLocationPath)
        }
    }
    
    private func loadPreferences() {
        // Don't try to save preferences while loading them.
        isLoadingPreferences = true
        defer { isLoadingPreferences = false }
        
        // Load sort option
        if let sortValue = UserDefaults.standard.string(forKey: PreferenceKeys.selectedSort),
           let sort = SortOption(rawValue: sortValue) {
            selectedSort = sort
        }
        
        // Load playback end option
        if let playbackValue = UserDefaults.standard.string(forKey: PreferenceKeys.playbackEndOption),
           let playback = PlaybackEndOption(rawValue: playbackValue) {
            playbackEndOption = playback
        }
        
        // Load last folder (but don't automatically open it)
        if let folderPath = UserDefaults.standard.string(forKey: PreferenceKeys.lastFolder) {
            let folderURL = URL(fileURLWithPath: folderPath)
            // Only restore if the folder still exists
            if fileManager.fileExists(atPath: folderPath) {
                selectedFolder = folderURL
                // Optionally auto-scan on launch
                // scanForVideoFiles(in: folderURL)
            }
        }
        
        // Load seek times
        let seekForward = UserDefaults.standard.double(forKey: PreferenceKeys.seekForwardSeconds)
        let seekBackward = UserDefaults.standard.double(forKey: PreferenceKeys.seekBackwardSeconds)
        
        if seekForward > 0 {
            settings.seekForwardSeconds = seekForward
        }
        if seekBackward > 0 {
            settings.seekBackwardSeconds = seekBackward
        }
        
        // Load pause/resume settings
        if UserDefaults.standard.object(forKey: PreferenceKeys.pauseOnLoseFocus) != nil {
            settings.pauseOnLoseFocus = UserDefaults.standard.bool(forKey: PreferenceKeys.pauseOnLoseFocus)
        }
        if UserDefaults.standard.object(forKey: PreferenceKeys.autoResumeOnFocus) != nil {
            settings.autoResumeOnFocus = UserDefaults.standard.bool(forKey: PreferenceKeys.autoResumeOnFocus)
        }
        
        // Load move location path
        if let moveLocationPath = UserDefaults.standard.string(forKey: PreferenceKeys.moveLocationPath) {
            settings.moveLocationPath = moveLocationPath
        }
        
        // Load include subfolders setting
        if UserDefaults.standard.object(forKey: PreferenceKeys.includeSubfolders) != nil {
            settings.includeSubfolders = UserDefaults.standard.bool(forKey: PreferenceKeys.includeSubfolders)
        }
        
        // Load playback speed
        let savedSpeed = UserDefaults.standard.float(forKey: PreferenceKeys.playbackSpeed)
        if savedSpeed > 0 && availablePlaybackSpeeds.contains(savedSpeed) {
            playbackSpeed = savedSpeed
        }
        
        // Load mute state
        isMuted = UserDefaults.standard.bool(forKey: PreferenceKeys.isMuted)
    }
    
    // MARK: - Public Methods
    
    func triggerFolderSelection() {
        shouldSelectFolder = true
    }
    
    func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder to scan for video files"
        
        // Create checkbox for subfolder option
        let checkbox = NSButton(checkboxWithTitle: "Include subfolders", target: nil, action: nil)
        checkbox.state = settings.includeSubfolders ? .on : .off
        
        // Create accessory view
        let accessoryView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 25))
        checkbox.frame = NSRect(x: 0, y: 0, width: 200, height: 25)
        accessoryView.addSubview(checkbox)
        
        panel.accessoryView = accessoryView
        
        panel.begin { [weak self] response in
            guard let self = self, response == .OK, let url = panel.url else { return }
            
            // Update the includeSubfolders setting from checkbox state
            self.settings.includeSubfolders = checkbox.state == .on
            
            AppLogger.logInfo("User selected folder: \(url.path), includeSubfolders: \(self.settings.includeSubfolders)", category: AppLogger.scan)
            
            // Validate folder before scanning
            do {
                try ValidationHelper.validateFolder(at: url)
                self.selectedFolder = url
                self.savePreferences()
                self.scanForVideoFiles(in: url)
            } catch {
                AppLogger.logError(error, category: AppLogger.scan)
                self.showError(error)
            }
        }
    }
    
    func setSortOption(_ option: SortOption) {
        selectedSort = option
        applySorting()
    }
    
    func setPlaybackEndOption(_ option: PlaybackEndOption) {
        playbackEndOption = option
    }
    
    func playVideo(at index: Int) {
        guard index >= 0 && index < videoFiles.count else { return }
        
        currentIndex = index
        let videoURL = videoFiles[index].url
        
        // Remove previous observers
        if let player = player, let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        pausePlayback()
        player = AVPlayer(url: videoURL)
        
        // Add observer for when video ends using block-based API
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.handleVideoEnd()
        }
        
        // Add time observer for progress updates
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
            if let duration = self?.player?.currentItem?.duration.seconds, duration.isFinite {
                self?.duration = duration
            }
        }
        
        resumePlayback()
        player?.isMuted = isMuted
    }
    
    func playPrevious() {
        guard !videoFiles.isEmpty else { return }
        
        if currentIndex > 0 {
            playVideo(at: currentIndex - 1)
        } else {
            playVideo(at: videoFiles.count - 1)
        }
    }
    
    func playNext() {
        guard !videoFiles.isEmpty else { return }
        
        if currentIndex < videoFiles.count - 1 {
            playVideo(at: currentIndex + 1)
        } else {
            playVideo(at: 0)
        }
    }
    
    func playRandom() {
        guard videoFiles.count > 1 else { return }
        
        var randomIndex: Int
        repeat {
            randomIndex = Int.random(in: 0..<videoFiles.count)
        } while randomIndex == currentIndex
        
        playVideo(at: randomIndex)
    }
    
    func togglePlayPause() {
        guard player != nil else { return }
        
        if isPlaying {
            pausePlayback()
        } else {
            resumePlayback()
        }
    }
    
    func pausePlayback() {
        // Don't pause if we're transitioning full screen
        if isTransitioningFullScreen {
            AppLogger.logInfo("Ignoring pause request during full screen transition", category: AppLogger.playback)
            return
        }
        
        player?.pause()
        isPlaying = false
    }
    
    func resumePlayback() {
        player?.rate = playbackSpeed
        isPlaying = true
    }
    
    func handleFullScreenTransitionComplete() {
        // Reset the transition flag
        isTransitioningFullScreen = false
        
        // Restore the playing state from before the transition
        if wasPlayingBeforeFullScreen && !isPlaying {
            resumePlayback()
            AppLogger.logInfo("Restored playback after full screen transition", category: AppLogger.playback)
        }
    }
    
    func seek(to percentage: Double) {
        guard let player = player, duration > 0 else { return }
        let targetTime = duration * percentage
        let cmTime = CMTime(seconds: targetTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: cmTime)
    }
    
    func seekForward(seconds: Double) {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: settings.seekForwardSeconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        player.seek(to: newTime)
    }
    
    func seekBackward(seconds: Double) {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: settings.seekBackwardSeconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        let zeroTime = CMTime.zero
        player.seek(to: newTime > zeroTime ? newTime : zeroTime)
    }
    
    func toggleMute() {
        isMuted.toggle()
    }
    
    // MARK: - Boss Key
    
    func activateBossKey() {
        // Mute audio
        if !isMuted {
            isMuted = true
        }
        
        // Pause playback
        pausePlayback()
        
        // Minimize window
        if let window = NSApplication.shared.windows.first {
            window.miniaturize(nil)
        }
        
        AppLogger.logInfo("Boss key activated", category: AppLogger.general)
    }
    
    // MARK: - Full Screen Methods
    
    func toggleFullScreen() {
        if let window = NSApplication.shared.windows.first {
            // Track playing state before transition
            wasPlayingBeforeFullScreen = isPlaying
            isTransitioningFullScreen = true
            
            window.toggleFullScreen(nil)
            isFullScreen = !(window.styleMask.contains(.fullScreen))
            AppLogger.logInfo("Full screen toggled: \(isFullScreen)", category: AppLogger.ui)
        }
    }
    
    func enterFullScreen() {
        if let window = NSApplication.shared.windows.first {
            if !window.styleMask.contains(.fullScreen) {
                // Track playing state before transition
                wasPlayingBeforeFullScreen = isPlaying
                isTransitioningFullScreen = true
                
                window.toggleFullScreen(nil)
                isFullScreen = true
                AppLogger.logInfo("Entering full screen", category: AppLogger.ui)
            }
        }
    }
    
    func exitFullScreen() {
        if let window = NSApplication.shared.windows.first {
            if window.styleMask.contains(.fullScreen) {
                // Track playing state before transition
                wasPlayingBeforeFullScreen = isPlaying
                isTransitioningFullScreen = true
                
                window.toggleFullScreen(nil)
                isFullScreen = false
                AppLogger.logInfo("Exiting full screen", category: AppLogger.ui)
            }
        }
    }
    
    // MARK: - Playback Speed Methods
    
    func increasePlaybackSpeed() {
        guard let currentIndex = availablePlaybackSpeeds.firstIndex(of: playbackSpeed),
              currentIndex < availablePlaybackSpeeds.count - 1 else {
            AppLogger.logInfo("Already at maximum playback speed: \(playbackSpeed)x", category: AppLogger.playback)
            return
        }
        
        playbackSpeed = availablePlaybackSpeeds[currentIndex + 1]
        AppLogger.logInfo("Increased playback speed to \(playbackSpeed)x", category: AppLogger.playback)
    }
    
    func decreasePlaybackSpeed() {
        guard let currentIndex = availablePlaybackSpeeds.firstIndex(of: playbackSpeed),
              currentIndex > 0 else {
            AppLogger.logInfo("Already at minimum playback speed: \(playbackSpeed)x", category: AppLogger.playback)
            return
        }
        
        playbackSpeed = availablePlaybackSpeeds[currentIndex - 1]
        AppLogger.logInfo("Decreased playback speed to \(playbackSpeed)x", category: AppLogger.playback)
    }
    
    func resetPlaybackSpeed() {
        playbackSpeed = 1.0
        AppLogger.logInfo("Reset playback speed to 1.0x", category: AppLogger.playback)
    }
    
    var playbackSpeedText: String {
        if playbackSpeed == 1.0 {
            return "1x"
        } else {
            return String(format: "%.2fx", playbackSpeed)
        }
    }
    
    func selectMoveLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select destination folder for moving files"
        panel.prompt = "Select"
        
        panel.begin { [weak self] response in
            guard let self = self, response == .OK, let url = panel.url else { return }
            
            AppLogger.logInfo("User selected move location: \(url.path)", category: AppLogger.settings)
            
            // Validate the destination
            do {
                try ValidationHelper.validateDestination(path: url.path)
                self.settings.moveLocationPath = url.path
            } catch {
                AppLogger.logError(error, category: AppLogger.settings)
                self.showError(error)
            }
        }
    }
    
    func moveCurrentFile() {
        guard let destinationPath = settings.moveLocationPath else {
            let error = VideoPlayerError.fileMoveFailedDestinationNotFound("No destination set")
            AppLogger.logError( error, category: AppLogger.fileOps)
            showError(error)
            return
        }
        
        moveCurrentFile(to: destinationPath)
    }
    
    func moveCurrentFile(to destinationPath: String) {
        guard currentIndex < videoFiles.count else { return }
        
        let fileURL = videoFiles[currentIndex].url
        let fileName = fileURL.lastPathComponent
        let destinationURL = URL(fileURLWithPath: destinationPath).appendingPathComponent(fileName)
        
        AppLogger.logInfo("Attempting to move file: \(fileName) to \(destinationPath)", category: AppLogger.fileOps)
        
        do {
            // Validate destination
            try ValidationHelper.validateDestination(path: destinationPath)
            
            // Validate path security
            guard ValidationHelper.isSecurePath(destinationURL) else {
                throw VideoPlayerError.fileMoveFailedPermission(fileName)
            }
            
            pausePlayback()
            try fileManager.moveItem(at: fileURL, to: destinationURL)
            videoFiles.remove(at: currentIndex)
            
            AppLogger.logInfo("Successfully moved file: \(fileName)", category: AppLogger.fileOps)
            
            if videoFiles.isEmpty {
                player = nil
                currentIndex = 0
            } else if currentIndex >= videoFiles.count {
                currentIndex = videoFiles.count - 1
                playVideo(at: currentIndex)
            } else {
                playVideo(at: currentIndex)
            }
        } catch let error as VideoPlayerError {
            AppLogger.logError(error, category: AppLogger.fileOps)
            showError(error)
        } catch {
            let wrappedError = VideoPlayerError.fileMoveFailedUnknown(fileName, error)
            AppLogger.logError(wrappedError, category: AppLogger.fileOps)
            showError(wrappedError)
        }
    }
    
    func moveCurrentFileToTrash() {
        guard currentIndex < videoFiles.count else { return }
        
        let fileURL = videoFiles[currentIndex].url
        let fileName = fileURL.lastPathComponent
        
        AppLogger.logInfo("Attempting to trash file: \(fileName)", category: AppLogger.fileOps)
        
        do {
            pausePlayback()
            try fileManager.trashItem(at: fileURL, resultingItemURL: nil)
            videoFiles.remove(at: currentIndex)
            
            AppLogger.logInfo("Successfully trashed file: \(fileName)", category: AppLogger.fileOps)
            
            if videoFiles.isEmpty {
                player = nil
                currentIndex = 0
            } else if currentIndex >= videoFiles.count {
                currentIndex = currentIndex - 1
                playVideo(at: currentIndex)
            } else {
                playVideo(at: currentIndex)
            }
        } catch {
            let wrappedError = VideoPlayerError.fileDeleteFailed(fileName, error)
            AppLogger.logError(wrappedError, category: AppLogger.fileOps)
            showError(wrappedError)
        }
    }
    
    // MARK: - Private Methods
    
    private func scanForVideoFiles(in directory: URL) {
        // Generate a new scan ID to invalidate previous scans
        let scanID = UUID()
        currentScanID = scanID
        
        AppLogger.logInfo("Starting scan of directory: \(directory.path), includeSubfolders: \(settings.includeSubfolders)", category: AppLogger.scan)
        
        isScanning = true
        videoFiles.removeAll()
        pausePlayback()
        player = nil
        currentIndex = 0
        currentTime = 0
        duration = 0
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Check if this scan is still valid
            guard scanID == self.currentScanID else {
                AppLogger.logInfo("Scan cancelled (superseded)", category: AppLogger.scan)
                return
            }
            
            // Set up enumerator options based on subfolder setting
            var enumeratorOptions: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]
            if !self.settings.includeSubfolders {
                enumeratorOptions.insert(.skipsSubdirectoryDescendants)
            }
            
            guard let enumerator = self.fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
                options: enumeratorOptions
            ) else {
                DispatchQueue.main.async {
                    if scanID == self.currentScanID {
                        self.isScanning = false
                        let error = VideoPlayerError.folderAccessDenied(directory.path)
                        AppLogger.logError(error, category: AppLogger.scan)
                        self.showError(error)
                    }
                }
                return
            }
            
            var foundFiles: [VideoFile] = []
            
            for case let fileURL as URL in enumerator {
                // Check if this scan has been superseded
                guard scanID == self.currentScanID else { return }
                
                // Validate file extension
                guard ValidationHelper.isValidVideoExtension(fileURL) else {
                    continue
                }
                
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                    
                    if resourceValues.isRegularFile == true {
                        let size = resourceValues.fileSize.map { Int64($0) } ?? 0
                        foundFiles.append(VideoFile(url: fileURL, size: size))
                    }
                } catch {
                    AppLogger.logWarning("Skipping file \(fileURL.lastPathComponent): \(error.localizedDescription)", category: AppLogger.scan)
                }
            }
            
            // Check again before sorting
            guard scanID == self.currentScanID else { return }
            
            foundFiles.sort { $0.path < $1.path }
            
            AppLogger.logInfo("Scan complete. Found \(foundFiles.count) video files", category: AppLogger.scan)
            
            DispatchQueue.main.async {
                // Final check before updating UI
                guard scanID == self.currentScanID else { return }
                
                self.videoFiles = foundFiles
                self.isScanning = false
                
                if foundFiles.isEmpty {
                    let error = VideoPlayerError.noVideosFound
                    AppLogger.logWarning("No videos found in directory", category: AppLogger.scan)
                    self.showError(error)
                } else {
                    // Apply the user's preferred sort
                    self.applySorting()
                    self.playVideo(at: 0)
                }
            }
        }
    }
    
    private func showError(_ error: Error) {
        if let videoError = error as? VideoPlayerError {
            errorMessage = videoError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
        showingError = true
    }
    
    private func handleVideoEnd() {
        switch playbackEndOption {
        case .stop:
            // Do nothing, video stays at the end
            isPlaying = false
            break
            
        case .replay:
            // Seek back to beginning and play again
            player?.seek(to: .zero)
            resumePlayback()
            
        case .playNext:
            // Play next video, wrapping to beginning if at end
            if currentIndex < videoFiles.count - 1 {
                playVideo(at: currentIndex + 1)
            } else if !videoFiles.isEmpty {
                playVideo(at: 0)
            }
        }
    }
    
    private func applySorting() {
        guard !videoFiles.isEmpty else { return }
        guard !isSorting else { return }
        
        let currentVideoURL = videoFiles[currentIndex].url
        
        if selectedSort == .fileName || selectedSort == .filePath || selectedSort == .random {
            switch selectedSort {
            case .fileName:
                videoFiles.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
                
            case .filePath:
                videoFiles.sort { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
                
            case .random:
                videoFiles.shuffle()
                
            default:
                break
            }
            
            if let newIndex = videoFiles.firstIndex(where: { $0.url == currentVideoURL }) {
                currentIndex = newIndex
            }
        } else {
            isSorting = true
            let filesToSort = videoFiles
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                var sortedFiles = filesToSort
                
                switch self.selectedSort {
                case .sizeAscending:
                    sortedFiles.sort { $0.size < $1.size }
                    
                case .sizeDescending:
                    sortedFiles.sort { $0.size > $1.size }
                    
                default:
                    break
                }
                
                DispatchQueue.main.async {
                    self.videoFiles = sortedFiles
                    self.isSorting = false
                    
                    if let newIndex = self.videoFiles.firstIndex(where: { $0.url == currentVideoURL }) {
                        self.currentIndex = newIndex
                    }
                }
            }
        }
    }
}
