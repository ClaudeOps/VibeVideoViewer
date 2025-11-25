//
//  CustomVideoPlayer.swift
//  VibeVideoViewer
//
//  Created by Claude Wilder on 2025-10-10.
//

import SwiftUI
import AVKit
import AppKit

// MARK: - Custom Video Player View

struct CustomVideoPlayerView: NSViewRepresentable {
    let player: AVPlayer
    var onTap: (() -> Void)?
    var onDoubleTap: (() -> Void)?
    
    func makeNSView(context: Context) -> PlayerContainerView {
        let containerView = PlayerContainerView()
        containerView.setupPlayer(player)
        containerView.onTap = onTap
        containerView.onDoubleTap = onDoubleTap
        return containerView
    }
    
    func updateNSView(_ nsView: PlayerContainerView, context: Context) {
        nsView.updatePlayer(player)
        nsView.onTap = onTap
        nsView.onDoubleTap = onDoubleTap
    }
}

// MARK: - Player Container View

class PlayerContainerView: NSView {
    private var playerLayer: AVPlayerLayer?
    var onTap: (() -> Void)?
    var onDoubleTap: (() -> Void)?
    private var clickCount = 0
    private var clickTimer: Timer?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupPlayer(_ player: AVPlayer) {
        // Remove old layer if exists
        playerLayer?.removeFromSuperlayer()
        
        // Create new player layer
        let newPlayerLayer = AVPlayerLayer(player: player)
        newPlayerLayer.videoGravity = .resizeAspect
        newPlayerLayer.frame = bounds
        
        layer?.addSublayer(newPlayerLayer)
        self.playerLayer = newPlayerLayer
        
        // Force initial layout
        needsLayout = true
        layoutSubtreeIfNeeded()
    }
    
    func updatePlayer(_ player: AVPlayer) {
        if playerLayer?.player !== player {
            setupPlayer(player)
        }
    }
    
    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer?.frame = bounds
        CATransaction.commit()
    }
    
    override func mouseDown(with event: NSEvent) {
        // Check if this is a double-click
        if event.clickCount == 2 {
            // Cancel any pending single-click timer
            clickTimer?.invalidate()
            clickTimer = nil
            clickCount = 0
            
            // Call the double-tap handler immediately
            onDoubleTap?()
        } else if event.clickCount == 1 {
            // Start a timer to delay single-click action
            // This allows us to detect if a double-click follows
            clickCount = 1
            clickTimer?.invalidate()
            clickTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                if self.clickCount == 1 {
                    // No double-click detected, process single click
                    self.onTap?()
                }
                self.clickCount = 0
            }
        }
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
}
