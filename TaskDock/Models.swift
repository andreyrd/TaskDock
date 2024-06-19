//
//  StateModel.swift
//  TaskDock
//
//  Created by Andrey Radchishin on 7/20/23.
//

import AXSwift

struct MenuModel: Identifiable {
    let id: String
    let name: String?
    let action: (() -> Void)?
    let children: [MenuModel]?
    let app: App?
    
    
    init(id: String, name: String? = nil, children: [MenuModel]? = nil, app: App? = nil, action: (() -> Void)? = nil) {
        self.id = id
        self.name = name
        self.children = children
        self.app = app
        self.action = action
    }
}

class App {
    init(name: String, icon: NSImage? = nil, bundleId: String, path: String? = nil, status: String? = nil) {
        self.name = name;
        self.icon = icon;
        self.bundleId = bundleId;
        self.path = path;
        self.status = status;
    }
    
    var name: String
    var icon: NSImage?
    var bundleId: String
    var path: String?
    var status: String?
    
    func activate() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else { return }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: config)
    }
    
    func moveToSpace(_ spaceId: CGSSpaceID) {
        guard let app = Application.allForBundleID(bundleId).first else { return }
        guard let window = (try? app.windows())?.first else { return }
        
        var cgWindowId = CGWindowID()
        if (_AXUIElementGetWindow(window.element, &cgWindowId) != .success) {
            print("Could not get CGWindowId for \(name)")
        } else {
            CGSMoveWindowsToManagedSpace(CGSMainConnectionID(), [cgWindowId] as CFArray, spaceId)
        }
    }
}

class Window: Equatable {
    static func == (lhs: Window, rhs: Window) -> Bool {
        return lhs.id == rhs.id
    }
    
    
    init(id: CGWindowID, name: String, title: String? = nil, icon: NSImage? = nil, bounds: CGRect,
         displayId: CGDirectDisplayID, spaceId: CGSSpaceID, pid: pid_t, bundleId: String, path: String? = nil) {
        self.id = id
        self.name = name
        self.title = title
        self.icon = icon
        self.bounds = bounds
        self.displayId = displayId
        self.spaceId = spaceId
        self.pid = pid
        self.bundleId = bundleId
        self.path = path
    }
    
    var id: CGWindowID
    var name: String
    var title: String?
    var icon: NSImage?
    
    var bounds: CGRect
    
    var displayId: CGDirectDisplayID
    var spaceId: CGSSpaceID
    
    var pid: pid_t
    var bundleId: String
    var path: String?
    
    func fixOverlap (screenY: CGFloat, screenHeight: CGFloat, dockHeight: CGFloat) {
        let dockTop = screenY + screenHeight - dockHeight
        let windowBottom = bounds.origin.y + bounds.height
        
        let overlap = windowBottom - dockTop + 1 // 1 pixel accounts for overlapping borders
        
        if overlap > 0 {
            let bounds = CGRect(
                origin: bounds.origin,
                size: CGSize(width: bounds.width, height: bounds.height - overlap)
            )
            
            guard let axWindow = StaticLookups.grabAXWindow(pid: pid, id) else {
                print("Could not grab AXWindow for resize!")
                return
            }
            
            if let position: CGPoint = try? axWindow.attribute(.position) {
                if position != bounds.origin {
                    // Window is actively moving, we shouldn't resize until user stops moving it
                    return
                }
            }
            
            try? axWindow.setAttribute(.size, value: bounds.size)
        }
    }
}

class Space {
    init(id: CGSSpaceID) {
        self.id = id
        self.windows = []
    }
    
    var id: CGSSpaceID
    var windows: [Window]
}

class Display {
    init(uuid: CFString, frame: NSRect, bounds: CGRect) {
        self.uuid = uuid
        self.frame = frame
        self.bounds = bounds
        self.spaces = [:]
    }
    
    var uuid: CFString
    var frame: NSRect
    var bounds: CGRect
    var spaces: [CGSSpaceID: Space]
}

class StateModel {
    init() {
        self.displays = [:]
    }
    
    var displays: [CGDirectDisplayID : Display]
}
