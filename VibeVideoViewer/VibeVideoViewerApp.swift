//
//  VideoFinderApp.swift
//  VibeVideoViewer
//
//  Created by Claude Wilder on 2025-10-06.
//

import SwiftUI

@main
struct VibeVideoViewerApp: App {
    @StateObject private var viewModel = VideoPlayerViewModel()
    
    var body: some Scene {
        WindowGroup {
            VideoPlayerView()
                .environmentObject(viewModel)
                .sheet(isPresented: $viewModel.showingSettings) {
                    SettingsView()
                        .environmentObject(viewModel)
                }
        }
        .commands {  // <-- Menu bar code starts here
            CommandGroup(replacing: .newItem) {
                Button("Open Folder...") {
                    viewModel.triggerFolderSelection()
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
            
            CommandGroup(after: .appSettings) {
                Button("Settings...") {
                    viewModel.showingSettings = true
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
            
            CommandMenu("Sort") {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(action: {
                        viewModel.setSortOption(option)
                    }) {
                        HStack {
                            Text(option.rawValue)
                            if viewModel.selectedSort == option {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .keyboardShortcut(option == .fileName ? "1" :
                                        option == .filePath ? "2" :
                                        option == .sizeAscending ? "3" :
                                        option == .sizeDescending ? "4" : "5")
                }
            }
            
            CommandMenu("Playback") {
                ForEach(PlaybackEndOption.allCases, id: \.self) { option in
                    Button(action: {
                        viewModel.setPlaybackEndOption(option)
                    }) {
                        HStack {
                            Text(option.rawValue)
                            if viewModel.playbackEndOption == option {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .keyboardShortcut(option == .stop ? "s" :
                                        option == .replay ? "l" : "n",
                                      modifiers: [.command])
                }
            }
        }  // <-- Menu bar code ends here
    }
}
