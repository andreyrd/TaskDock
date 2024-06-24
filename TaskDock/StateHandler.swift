//
//  WindowsState.swift
//  TaskDock
//
//  Created by Andrey Radchishin on 7/20/23.
//

import AXSwift
import Foundation

class StateHandler {
    
    private static let HIDDEN_WINDOWS = ["Control Center", "SystemUIServer", "WindowManager", "WindowServer",
                                         "Spotlight", "Wallpaper"]
    
    private var _displayUuids: [CGDirectDisplayID: CFString] = [:]
    private var _displayBounds: [CGDirectDisplayID: CGRect] = [:]
    private var _displayFrames: [CGDirectDisplayID: NSRect] = [:]
        
    private var _bundleIdByPid: [pid_t: String] = [:]
    
    private func reset(resetWindowOrder: Bool = true) {
        _displayUuids = [:]
        _displayBounds = [:]
        _displayFrames = [:]
        
        _bundleIdByPid = [:]
        
        NSScreen.screens.forEach { screen in
            guard let displayId = screen.deviceDescription[NSDeviceDescriptionKey(rawValue: "NSScreenNumber")]
                    as? CGDirectDisplayID else {
                print("Could not get Display ID from NSScreen!")
                return
            }
            
            let uuid = CGDisplayCreateUUIDFromDisplayID(displayId).takeRetainedValue()
            guard let uuidString = CFUUIDCreateString(nil, uuid) else {
                print("Could not create UUID String from Display UUID!")
                return
            }
            
            _displayUuids[displayId] = uuidString
            
            let bounds = CGDisplayBounds(displayId)
            _displayBounds[displayId] = bounds
            
            _displayFrames[displayId] = screen.frame
        }
    }
    
    public func recreate() -> StateModel {
        reset() // I'm not actually sure if this is necessary but we do it just in case
        return refresh()
    }
    
    public func refresh() -> StateModel {
        let windowData = CGWindowListCopyWindowInfo(
            CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly),
            CGWindowID(0)
        ) as! [[String: Any]]
        
        let windows = windowData.compactMap(extractWindow)
        
        let state = StateModel()
        
        // Prefill displays because there might not actually be any windows on the display
        _displayUuids.forEach { displayId, uuid in
            state.displays[displayId] = Display(uuid: uuid, frame: _displayFrames[displayId]!, bounds: _displayBounds[displayId]!)
        }
        
        windows.forEach { window in
            state.displays[window.displayId]!
                .spaces[
                    window.spaceId,
                    orInit: Space(id: window.spaceId)
                ].windows.append(window)
        }
        
        return state
    }
    
    public func extractWindow(fromData data: [String: Any]) -> Window? {
        
        // Anything that is not layer 0 is not actually a visible window
        let layer = data["kCGWindowLayer"] as! NSNumber
        if layer != 0 { return nil }
        
        // Filter out known system windows
        let name = data["kCGWindowOwnerName"] as! String
        if StateHandler.HIDDEN_WINDOWS.contains(name) {
            return nil
        }
        
        // Figure out which display the window is on using bounds
        let boundsData = data["kCGWindowBounds"] as! NSDictionary
        
        let x = boundsData["X"] as! Double
        let y = boundsData["Y"] as! Double
        let width = boundsData["Width"] as! Double
        let height = boundsData["Height"] as! Double
        let bounds = CGRect(x: x, y: y, width: width, height: height)
        
        guard let displayId = _displayBounds.first(where: { displayId, displayBounds in
            return displayBounds.intersects(bounds)
        })?.key else {
            print("Could not figure out which display the window for \(name) is on!")
            return nil
        }
        
        // Grab window id and use it to find the space it's on
        let windowId = (data["kCGWindowNumber"] as! NSNumber).uint32Value

    
        guard let space = (CGSCopySpacesForWindows(
            CGSMainConnectionID(),
            kCGSAllSpacesMask,
            [windowId] as CFArray
        ).takeRetainedValue() as NSArray as? [NSNumber])?.first?.intValue else {
            print("Could not figure out which space the window for \(name) is on!")
            return nil
        }
        
        let ownerPid = (data["kCGWindowOwnerPID"] as! NSNumber).int32Value
        guard let title = grabTitle(pid: ownerPid, id: windowId) else { return nil}
        
        guard let bundleId = grabBundleId(pid: ownerPid) else {
            print("Could not figure out bundle id for \(name)")
            return nil
        }
        
        let path = StaticLookups.grabPath(bundleId: bundleId)
        let icon = StaticLookups.grabIcon(path: path)
        
        return Window(
            id: windowId, name: name, title: title, icon: icon,
            bounds: bounds,
            displayId: displayId, displayUUID: _displayUuids[displayId], spaceId: space,
            pid: ownerPid, bundleId: bundleId, path: path
        )
    }
    
    private func grabTitle(pid: pid_t, id: CGWindowID) -> String? {
        let axWindow = StaticLookups.grabAXWindow(pid: pid, id)
        return try? axWindow?.attribute(.title)
    }
    
    
    
    private func grabBundleId(pid: pid_t) -> String? {
        if let cached = _bundleIdByPid[pid] {
            return cached
        }
        
        let app = NSRunningApplication(processIdentifier: pid)
        let bundleId = app?.bundleIdentifier
        
        _bundleIdByPid[pid] = bundleId
        
        return bundleId
    }
}
