//
//  AppDelegate.swift
//  TaskDock
//
//  Created by Andrey Radchishin on 7/19/23.
//

import AXSwift
import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var dockWindows: [CGDirectDisplayID: (window: DockWindow, view: ContentView)] = [:]
    private var menuWindow: MenuWindow!

    private var stateHandler: StateHandler!
    private var changeHandler: ChangeHandler!
    private var trayHandler: TrayHandler!
    private var orderHandler: OrderHandler!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // Check for accessibility permissions and exit if we don't have it
        guard AXSwift.checkIsProcessTrusted(prompt: true) else {
            print("Not trusted as an AX process; please authorize and re-launch")
            NSApp.terminate(self)
            return
        }
                
        menuWindow = MenuWindow()
        menuWindow.contentView = NSHostingView(rootView: MenuView())
        
        stateHandler = StateHandler()
        changeHandler = ChangeHandler()
        trayHandler = TrayHandler()
        orderHandler = OrderHandler()
        
        changeHandler.onRecreate = recreate
        changeHandler.onRefresh = refresh
        
        changeHandler.register()
        
        recreate()
    }
    
    private func recreate() {
        let state = stateHandler.recreate()
        orderHandler.update(state: state)
        let tray = trayHandler.getApps()
        
        // Remove existing
        dockWindows.forEach { displayId, dock in
            dock.window.close()
        }
        
        // Create a dock for each display
        dockWindows = Dictionary(uniqueKeysWithValues: state.displays.map { displayId, display in
            
            // Create dock using display frame for positioning
            let dock = DockWindow(screenFrame: display.frame)
            
            // Create view
            let spaceId = CGSManagedDisplayGetCurrentSpace(CGSMainConnectionID(), display.uuid)
            let space = display.spaces[spaceId] ?? Space(id: spaceId)
            var view = ContentView(displayId: displayId, space: space, tray: tray)
            view.onShowMenu = { self.openMenu(on: display.frame) }
            view.onChangeOrder = { displayId, spaceId, updated in
                self.orderHandler.move(displayId: displayId, spaceId: spaceId, updated: updated)
                self.orderHandler.update(state: state)
                guard let space = state.displays[displayId]?.spaces[spaceId] else { return }
                view.spacePub.send(space)
            }
            dock.contentView = NSHostingView(rootView: view)
            
            // Bring to front
            dock.orderFront(nil)
            
            return (displayId, (window: dock, view: view))
        })
    }
    
    private func refresh() {
        let state = stateHandler.refresh()
        orderHandler.update(state: state)
        let tray = trayHandler.getApps()
        
        // Update each display's dock
        dockWindows.forEach { displayId, dock in
            let display = state.displays[displayId]!
            let spaceId = CGSManagedDisplayGetCurrentSpace(CGSMainConnectionID(), display.uuid)
            let space = display.spaces[spaceId] ?? Space(id: spaceId)
            
            // Trigger a resize on all windows if needed
            space.windows.forEach { window in
                window.fixOverlap(screenY: display.bounds.origin.y, screenHeight: display.frame.height, dockHeight: dock.window.frame.height)
            }
            
            dock.view.spacePub.send(space)
            dock.view.trayPub.send(tray)
        }
    }
    
    private func openMenu(on screenFrame: NSRect) {
        NSApp.activate(ignoringOtherApps: true)
        menuWindow.moveToScreen(withFrame: screenFrame)
        menuWindow.makeKeyAndOrderFront(nil)
    }
    
    @objc func onWorkspaceChanged(_ notification: Notification) {
        print("change")
        
//        windows.forEach { (id, window) in
//            
//
//            
//            window.1!.publisher.send(currentSpace)
//        }
        
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // Generate initial set of docks
    }
    
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

