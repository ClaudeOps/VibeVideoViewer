//
//  VideoPlayerView.swift
//  VibeVideoViewer
//
//  Created by Claude Wilder on 2025-10-06.
//

import SwiftUI
import AVFoundation

struct VideoPlayerView: View {
    @EnvironmentObject var viewModel: VideoPlayerViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderView(selectedFolder: viewModel.selectedFolder, currentVideoFile: viewModel.currentVideoFile)
            
            Divider()
            
            if viewModel.isScanning {
                ProgressView("Scanning for video files...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.videoFiles.isEmpty {
                EmptyStateView()
            } else {
                VideoContentView()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onChange(of: viewModel.shouldSelectFolder) { _, newValue in
            if newValue {
                viewModel.selectFolder()
                viewModel.shouldSelectFolder = false
            }
        }
        .onAppear {
            setupKeyboardHandling()
            setupWindowObservers()
        }
        .onDisappear {
            viewModel.player?.pause()
        }
        .alert("Error", isPresented: $viewModel.showingError, presenting: viewModel.errorMessage) { _ in
            Button("OK", role: .cancel) { }
        } message: { message in
            Text(message)
        }
    }
    
    private func setupWindowObservers() {
        // Observe window minimize
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMiniaturizeNotification,
            object: nil,
            queue: .main
        ) { [weak viewModel] _ in
            viewModel?.pausePlayback()
        }
        
        // Observe window close
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { [weak viewModel] _ in
            viewModel?.pausePlayback()
        }
        
        // Observe app becoming inactive (losing focus)
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak viewModel] notification in
            guard let vm = viewModel else { return }
            if vm.settings.pauseOnLoseFocus {
                vm.pausePlayback()
            }
        }
        
        // Observe app becoming active (gaining focus)
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak viewModel] _ in
            guard let vm = viewModel else { return }
            if vm.settings.autoResumeOnFocus && !vm.isPlaying {
                vm.resumePlayback()
            }
        }
    }
    
    private func setupKeyboardHandling() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak viewModel] event in
            guard let viewModel = viewModel else { return event }
            return handleKeyPress(event: event, viewModel: viewModel)
        }
    }
    
    private func handleKeyPress(event: NSEvent, viewModel: VideoPlayerViewModel) -> NSEvent? {
        guard let characters = event.characters?.lowercased() else {
            return event
        }
        
        switch event.keyCode {
        case 123: // Left arrow
            viewModel.seekBackward(seconds: viewModel.settings.seekBackwardSeconds)
            return nil
        case 124: // Right arrow
            viewModel.seekForward(seconds: viewModel.settings.seekForwardSeconds)
            return nil
        case 126: // Up arrow
            viewModel.playPrevious()
            return nil
        case 125: // Down arrow
            viewModel.playNext()
            return nil
        case 51: // Delete key
            viewModel.moveCurrentFileToTrash()
            return nil
        case 49: // Spacebar
            viewModel.togglePlayPause()
            return nil
        default:
            if characters == "r" {
                viewModel.playRandom()
                return nil
            } else if characters == "m" {
                viewModel.toggleMute()
                return nil
            } else if characters == "b" {
                viewModel.activateBossKey()
                return nil
            } else if characters == "1" {
                viewModel.moveCurrentFile()
                return nil
            } else if characters == "," {
                viewModel.seekBackward(seconds: viewModel.settings.seekBackwardSeconds)
                return nil
            } else if characters == "." {
                viewModel.seekForward(seconds: viewModel.settings.seekForwardSeconds)
                return nil
            }
        }
        return event
    }
}
