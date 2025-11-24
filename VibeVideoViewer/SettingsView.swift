//
//  SettingsView.swift
//  VibeVideoViewer
//
//  Created by Claude Wilder on 2025-10-06.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: VideoPlayerViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Settings Content
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Move Destination:")
                                .frame(width: 120, alignment: .leading)
                            
                            Button("Choose Folder...") {
                                viewModel.selectMoveLocation()
                            }
                        }
                        
                        if let path = viewModel.settings.moveLocationPath {
                            HStack {
                                Text(path)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                    .truncationMode(.middle)
                                
                                Spacer()
                                
                                Button(action: {
                                    viewModel.settings.moveLocationPath = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("Clear move location")
                            }
                        } else {
                            Text("No destination set - 'M' key will be disabled")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    Toggle("Include subfolders when scanning", isOn: $viewModel.settings.includeSubfolders)
                        .help("When enabled, video files in subfolders will also be found")
                } header: {
                    Text("File Management")
                        .font(.headline)
                }
                
                Section {
                    HStack {
                        Text("Seek Forward:")
                            .frame(width: 120, alignment: .leading)
                        
                        Slider(value: Binding(
                            get: { viewModel.settings.seekForwardSeconds },
                            set: { viewModel.settings.seekForwardSeconds = ValidationHelper.sanitizeSeekTime($0) }
                        ), in: 1...60, step: 1)
                        
                        Text("\(Int(viewModel.settings.seekForwardSeconds))s")
                            .frame(width: 40, alignment: .trailing)
                            .monospacedDigit()
                    }
                    
                    HStack {
                        Text("Seek Backward:")
                            .frame(width: 120, alignment: .leading)
                        
                        Slider(value: Binding(
                            get: { viewModel.settings.seekBackwardSeconds },
                            set: { viewModel.settings.seekBackwardSeconds = ValidationHelper.sanitizeSeekTime($0) }
                        ), in: 1...60, step: 1)
                        
                        Text("\(Int(viewModel.settings.seekBackwardSeconds))s")
                            .frame(width: 40, alignment: .trailing)
                            .monospacedDigit()
                    }
                } header: {
                    Text("Seek Times")
                        .font(.headline)
                }
                
                Section {
                    Toggle("Pause when app loses focus", isOn: $viewModel.settings.pauseOnLoseFocus)
                    
                    Toggle("Auto-resume when app gains focus", isOn: $viewModel.settings.autoResumeOnFocus)
                        .disabled(!viewModel.settings.pauseOnLoseFocus)
                } header: {
                    Text("Playback Behavior")
                        .font(.headline)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        KeyboardShortcutRow(key: ",", description: "Seek backward \(Int(viewModel.settings.seekBackwardSeconds))s")
                        KeyboardShortcutRow(key: ".", description: "Seek forward \(Int(viewModel.settings.seekForwardSeconds))s")
                        KeyboardShortcutRow(key: "←", description: "Seek backward \(Int(viewModel.settings.seekBackwardSeconds))s")
                        KeyboardShortcutRow(key: "→", description: "Seek forward \(Int(viewModel.settings.seekForwardSeconds))s")
                        KeyboardShortcutRow(key: "Space", description: "Play/Pause")
                        KeyboardShortcutRow(key: "↑", description: "Previous video")
                        KeyboardShortcutRow(key: "↓", description: "Next video")
                        KeyboardShortcutRow(key: "R", description: "Random video")
                        KeyboardShortcutRow(key: "M", description: "Mute/Unmute")
                        KeyboardShortcutRow(key: "B", description: "Boss Key (Mute, Pause, Minimize)")
                        HStack {
                            KeyboardShortcutRow(key: "1", description: "Move file to destination")
                            if viewModel.settings.moveLocationPath == nil {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .help("Set move location first")
                            }
                        }
                        KeyboardShortcutRow(key: "Delete", description: "Move to trash")
                    }
                } header: {
                    Text("Keyboard Shortcuts Reference")
                        .font(.headline)
                }
            }
            .formStyle(.grouped)
            .padding()
            
            Divider()
            
            // Footer
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 500, height: 550)
    }
}

struct KeyboardShortcutRow: View {
    let key: String
    let description: String
    
    var body: some View {
        HStack {
            Text(key)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
                .frame(width: 80, alignment: .leading)
            
            Text(description)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(VideoPlayerViewModel())
}
