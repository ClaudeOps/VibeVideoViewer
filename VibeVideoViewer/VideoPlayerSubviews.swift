//
//  VideoPlayerSubviews.swift
//  VibeVideoViewer
//
//  Created by Claude Wilder on 2025-10-06.
//

import SwiftUI

// MARK: - Header View

struct HeaderView: View {
    let selectedFolder: URL?
    let currentVideoFile: VideoFile?
    
    private var displayText: String {
        guard let folder = selectedFolder else {
            return "No folder selected"
        }
        
        guard let video = currentVideoFile else {
            return "\(folder.path) • (no video)"
        }
        
        // Calculate relative path from selected folder to current video
        let folderPath = folder.path
        let videoPath = video.url.path
        
        // Get the relative part
        if videoPath.hasPrefix(folderPath) {
            var relativePath = String(videoPath.dropFirst(folderPath.count))
            // Ensure it starts with /
            if !relativePath.hasPrefix("/") {
                relativePath = "/" + relativePath
            }
            return "\(folderPath) • \(relativePath)"
        } else {
            // Fallback if paths don't match (shouldn't happen)
            return "\(folderPath) • /\(video.name)"
        }
    }
    
    var body: some View {
        HStack {
            Text(displayText)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    var body: some View {
        Text("No video files found. Select a folder to begin.")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Video Content View

struct VideoContentView: View {
    @EnvironmentObject var viewModel: VideoPlayerViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if let player = viewModel.player {
                CustomVideoPlayerView(
                    player: player,
                    onTap: {
                        viewModel.togglePlayPause()
                    },
                    onDoubleTap: {
                        viewModel.toggleFullScreen()
                    }
                )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id(viewModel.currentIndex)
            }
            
            VideoControlsView()
        }
    }
}

// MARK: - Video Controls View

struct VideoControlsView: View {
    @EnvironmentObject var viewModel: VideoPlayerViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            VideoInfoView()
            ProgressBarView()
            NavigationButtonsView()
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Video Info View

struct VideoInfoView: View {
    @EnvironmentObject var viewModel: VideoPlayerViewModel
    
    var body: some View {
        VStack(spacing: 4) {
            if !viewModel.videoFiles.isEmpty && viewModel.currentIndex < viewModel.videoFiles.count {
                Text(viewModel.videoFiles[viewModel.currentIndex].name)
                    .font(.headline)
                    .lineLimit(1)
                Text("Video \(viewModel.currentIndex + 1) of \(viewModel.videoFiles.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 10)
    }
}

// MARK: - Progress Bar View

struct ProgressBarView: View {
    @EnvironmentObject var viewModel: VideoPlayerViewModel
    @State private var isDragging = false
    
    var progress: Double {
        guard viewModel.duration > 0 else { return 0 }
        return viewModel.currentTime / viewModel.duration
    }
    
    var timeString: String {
        let current = formatTime(viewModel.currentTime)
        let total = formatTime(viewModel.duration)
        return "\(current) / \(total)"
    }
    
    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    // Progress fill
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * progress, height: 6)
                        .cornerRadius(3)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let percentage = max(0, min(1, value.location.x / geometry.size.width))
                            viewModel.seek(to: percentage)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
            }
            .frame(height: 6)
            
            Text(timeString)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
    }
    
    private func formatTime(_ time: Double) -> String {
        guard time.isFinite && time >= 0 else { return "0:00" }
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Navigation Buttons View

struct NavigationButtonsView: View {
    @EnvironmentObject var viewModel: VideoPlayerViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            Spacer()
            // Left side - playback controls
            HStack(spacing: 20) {
                Button(action: viewModel.playPrevious) {
                    Label("Previous", systemImage: "backward.fill")
                }
                .buttonStyle(.bordered)
                
                Button(action: viewModel.togglePlayPause) {
                    Label(viewModel.isPlaying ? "Pause" : "Play", systemImage: viewModel.isPlaying ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.bordered)
                
                Button(action: viewModel.playRandom) {
                    Label("Random", systemImage: "shuffle")
                }
                .disabled(viewModel.videoFiles.count <= 1)
                .buttonStyle(.bordered)
                
                Button(action: viewModel.playNext) {
                    Label("Next", systemImage: "forward.fill")
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            // Right side - mute button
            Button(action: viewModel.toggleMute) {
                Label(viewModel.isMuted ? "Unmute" : "Mute", systemImage: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
}

// MARK: - Preview

#Preview {
    NavigationButtonsView()
        .environmentObject(VideoPlayerViewModel())
}
