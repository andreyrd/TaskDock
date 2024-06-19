//
//  SortHandler.swift
//  TaskDock
//
//  Created by Andrey Radchishin on 7/20/23.
//

import Foundation

class SortHandler {
    
    // For now, just alphabetical. Later we want to allow user to drag and drop - and we should remember to the best of
    // our abilities
    func sort(_ windows: [Window]) -> [Window] {
        return windows.sorted { lhs, rhs in
            return (lhs.title ?? lhs.name) < (rhs.title ?? rhs.name)
        }
    }
}
