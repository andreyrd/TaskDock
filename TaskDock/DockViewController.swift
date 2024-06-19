//
//  DockViewController.swift
//  TaskDock
//
//  Created by Andrey Radchishin on 7/22/23.
//

import Cocoa

class DockViewController: NSViewController {
    public var space: Space {
        didSet {
            
        }
    }
    public var tray: [App] {
        didSet {
            
        }
    }
    
    init(space: Space, tray: [App]) {
        self.space = space
        self.tray = tray
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init with coder not implemented")
    }
    
    override func loadView() {
        
    }
}
