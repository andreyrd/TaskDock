//
//  NotificationHandler.swift
//  TaskDock
//
//  Created by Andrey Radchishin on 7/20/23.
//

import Foundation

class ChangeHandler: NSObject {
    
    public var onRecreate: (() -> Void)?
    public var onRefresh: (() -> Void)?
    public var onResize: (() -> Void)?
    
    // For debouncing (leading AND trailing)
    private static let DEBOUNCE_INTERVAL = 0.1
    private var recreateDebounceTimer: Timer?
    private var recreateRetriggered: Bool = false
    private var refreshDebounceTimer: Timer?
    private var refreshRetriggered: Bool = false
    
    public func register() {
        
        // All of these handlers for NSWorkspace will trigger a refresh
        [
            NSWorkspace.activeSpaceDidChangeNotification,
            NSWorkspace.didHideApplicationNotification,
            NSWorkspace.didUnhideApplicationNotification,
            NSWorkspace.didDeactivateApplicationNotification,
            NSWorkspace.didTerminateApplicationNotification,
            NSWorkspace.didLaunchApplicationNotification
        ].forEach { notificationName in
            NSWorkspace.shared.notificationCenter.addObserver(
                self,
                selector: #selector(triggerRefresh),
                name: notificationName,
                object: nil
            )
        }
        
        // Screen changes should trigger recreating docks (since a screen may have been added or removed)
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(triggerRecreate),
//            name: NSApplication.didChangeScreenParametersNotification,
//            object: nil
//        )
        // TODO: This constantly crashes, we should just store the display geometry and do a quick check on refresh to see if it changed
        
        // Start an infinite timer too to catch anything else
        _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(triggerRefresh), userInfo: nil, repeats: true)
    }
    
    @objc func triggerRecreate() {
        if recreateDebounceTimer != nil {
            // This will let the timer know that it should indeed call the closure again when it expires
            recreateRetriggered = true
        } else {
            // Trigger the closure and start a timer
            onRecreate?()
            recreateDebounceTimer = Timer.scheduledTimer(withTimeInterval: ChangeHandler.DEBOUNCE_INTERVAL, repeats: false) { _ in
                self.recreateDebounceTimer = nil
                if (self.recreateRetriggered) {
                    // Notification was triggered again, so we should call closure again on exit of timer
                    self.onRefresh?()
                }
                self.recreateRetriggered = false
            }
        }
    }
    
    @objc func triggerRefresh(notification: Notification) {
        if refreshDebounceTimer != nil {
            // This will let the timer know that it should indeed call the closure again when it expires
            refreshRetriggered = true
        } else {
            // Trigger the closure and start a timer
            onRefresh?()
            refreshDebounceTimer = Timer.scheduledTimer(withTimeInterval: ChangeHandler.DEBOUNCE_INTERVAL, repeats: false) { _ in
                self.refreshDebounceTimer = nil
                if (self.refreshRetriggered) {
                    // Notification was triggered again, so we should call closure again on exit of timer
                    self.onRefresh?()
                }
                self.refreshRetriggered = false
            }
        }
    }
}
