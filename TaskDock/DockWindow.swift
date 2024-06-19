//
//  DockWindow.swift
//  TaskDock
//
//  Created by Andrey Radchishin on 7/19/23.
//

import Cocoa

class DockWindow: NSWindow {
    
    init(screenFrame: NSRect) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 0, height: 0), styleMask: [.borderless], backing: .buffered, defer: false)

        self.level = .dock
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenNone, .stationary]
        self.isMovable = false
        
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
        
        let frame = NSRect(x: screenFrame.minX, y: screenFrame.minY, width: screenFrame.width, height: 48)
            
        setFrame(frame, display: true)
    }
    
    override var isFloatingPanel: Bool {
        return true
    }
    
    // `canBecomeKey` and `canBecomeMain` are required so that text inputs inside the panel can receive focus
    override var canBecomeKey: Bool {
        return false
    }

    override var canBecomeMain: Bool {
        return false
    }
}
