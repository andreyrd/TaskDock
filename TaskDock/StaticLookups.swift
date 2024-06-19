//
//  Helpers.swift
//  TaskDock
//
//  Created by Andrey Radchishin on 7/21/23.
//

import AXSwift

struct StaticLookups {
    
    // TODO: We probably don't need or want to hold onto these forever (potential memory leak?)
    private static var _axWindowsById: [CGWindowID: UIElement] = [:]
    private static var _iconsByPath: [String: NSImage] = [:]
    private static var _pathsByBundleId: [String: String] = [:]
    
    public static func grabAXWindow(pid: pid_t, _ id: CGWindowID) -> UIElement? {
        if let cached = _axWindowsById[id] {
            return cached
        }
        
        guard let app = Application.init(forProcessID: pid) else { return nil }
        return grabAXWindow(app: app, id)
    }
    
    public static func grabAXWindow(app: Application, _ id: CGWindowID) -> UIElement? {
        if let cached = _axWindowsById[id] {
            return cached
        }
        
        let windows = try? app.windows()
        
        let window = windows?.first(where: { axWindow in
            var axWindowId = CGWindowID()
            if (_AXUIElementGetWindow(axWindow.element, &axWindowId) != .success) {
                print("Could not get CGWindowId for one of the AXUIElement windows!")
                return false
            } else {
                return axWindowId == id
            }
        })
        
        StaticLookups._axWindowsById[id] = window
        
        return window
    }
    
    public static func grabPath(bundleId: String) -> String? {
        if let cached = StaticLookups._pathsByBundleId[bundleId] {
            return cached
        }
        
        guard let path = NSWorkspace.shared.absolutePathForApplication(withBundleIdentifier: bundleId) else {
            print("Could not get absolute path for \(bundleId)")
            return nil
        }
        
        guard FileManager.default.fileExists(atPath: path) else {
            print("Path does not exist: \(path)")
            return nil
        }
        
        StaticLookups._pathsByBundleId[bundleId] = path
        
        return path
    }
    
    public static func grabIcon(path: String?) -> NSImage? {
        guard let path = path else { return nil }
        
        if let cached = StaticLookups._iconsByPath[path] {
            return cached
        }
        
        let icon = NSWorkspace.shared.icon(forFile: path)
        
        StaticLookups._iconsByPath[path] = icon
        
        return icon
    }
}
