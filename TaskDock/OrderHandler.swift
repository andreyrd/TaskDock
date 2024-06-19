//
//  OrderHandler.swift
//  TaskDock
//
//  Created by Andrey Radchishin on 8/10/23.
//

class OrderHandler {
    
    private var _stored: [CGDirectDisplayID: [CGSSpaceID: ([CGWindowID], [CGWindowID: Int])]] = [:]
    
    public func update(state: StateModel) {
        state.displays.forEach { displayId, display in
            var storedDisplay = _stored[displayId, orInit: [:]]
            display.spaces.forEach { spaceId, space in
                var (arr, dict) = storedDisplay[spaceId, orInit: ([], [:])]
                
                // Add any windows that aren't accounted for
                space.windows.forEach { window in
                    if !dict.keys.contains(window.id) {
                        dict[window.id] = arr.count
                        arr.append(window.id)
                    }
                }
                
                storedDisplay[spaceId] = (arr, dict)
                _stored[displayId] = storedDisplay
                
                // Sort the StateModel windows based on our stored order
                space.windows.sort { lhs, rhs in
                    guard let lhsIndex = dict[lhs.id] else { return false }
                    guard let rhsIndex = dict[rhs.id] else { return true }
                    return lhsIndex < rhsIndex
                }
                
                
            }
        }
    }
    
    public func move(displayId: CGDirectDisplayID, spaceId: CGSSpaceID, updated arr: [CGWindowID]) {
        guard var display = _stored[displayId] else { return }
        
        var dict = [CGWindowID: Int]()
        arr.enumerated().forEach { (index, window) in
            dict[window]  = index
        }
        
        display[spaceId] = (arr, dict)
        _stored[displayId] = display
    }
}
