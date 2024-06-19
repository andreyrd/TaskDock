//
//  MenuWindow.swift
//  TaskDock
//
//  Created by Andrey Radchishin on 7/21/23.
//

import Cocoa

class MenuWindow: NSWindow {
    
    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 0, height: 0), styleMask: [.unifiedTitleAndToolbar], backing: .buffered, defer: false)

        // self.isFloatingPanel = true
        self.level = .dock
        self.collectionBehavior = [.canJoinAllSpaces]
        self.hidesOnDeactivate = true
        self.isMovable = false
        
        self.backgroundColor = .clear
        
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
    }
    
    func moveToScreen(withFrame frame: NSRect) {
        let frame = NSRect(
            x: frame.minX,
            y: frame.origin.y + 48 + 2,
            width: 480,
            height: min(frame.height - 48 - NSStatusBar.system.thickness - 2, 640)
        )
        self.setFrame(frame, display: true)
    }

    // `canBecomeKey` and `canBecomeMain` are required so that text inputs inside the panel can receive focus
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
}
