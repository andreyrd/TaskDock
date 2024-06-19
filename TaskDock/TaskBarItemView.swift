//
//  TaskBarItemView.swift
//  TaskDock
//
//  Created by Andrey Radchishin on 8/11/23.
//

import AXSwift
import SwiftUI

struct TaskBarItemView: View {
    let window: Window
    
    var body: some View {
        HStack {
            if let icon = window.icon {
                Image(nsImage: icon)
            }
            Text("\(window.title ?? window.name)").frame(maxWidth: 180).padding(.leading, -3)
        }.padding(EdgeInsets(top: 4, leading: 5, bottom: 4, trailing: 8))
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlColor)))
        .onTapGesture {
            let nsapp = NSRunningApplication(processIdentifier: window.pid)
            
            
            let app = Application.init(forProcessID: window.pid)
            let windows = try! app?.windows()
            
            let axwindow = windows?.first(where: { w in
                var cgWindowId = CGWindowID()
                if (_AXUIElementGetWindow(w.element, &cgWindowId) != .success) {
                    print("cannot get CGWindow id (objc bridged call)")
                } else {
                    return cgWindowId == window.id
                }
                return false
            })
            
            if let axwindow = axwindow {
                nsapp?.activate()
                // try? app?.setAttribute(.frontmost, value: kCFBooleanTrue)
                // try! app?.setAttribute(.focusedWindow, value: kCFBooleanTrue)
                try? axwindow.performAction(.raise)
                try? axwindow.setAttribute(.focused, value: kCFBooleanTrue)
            } else {
                nsapp?.activate(options: .activateAllWindows)
            }
        }
    }
}
