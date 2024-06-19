//
//  main.swift
//  TaskDock
//
//  Created by Andrey Radchishin on 7/19/23.
//

import Cocoa

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// 2
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
