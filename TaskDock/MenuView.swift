//
//  MenuView.swift
//  TaskDock
//
//  Created by Andrey Radchishin on 7/21/23.
//

import SwiftUI

struct MenuView: View {
    
    private static var rootMenu = MenuModel(id: "_root", children: [
        MenuModel(id: "_applications", name: "Applications"),
        
        MenuModel(id: "_finder", name: "Finder",
                  app: App(name: "Finder", icon: NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/Finder.app"), bundleId: "finder"),
                  action: { NSWorkspace.shared.launchApplication("Finder") }),
    ])
    
    @State private var menu = rootMenu
    
    var body: some View {
        VStack() {
            Spacer()
            
            VStack {
                if let name = menu.name {
                    Text(name)
                }
                List {
                    Section(header: Text("")) {
                        ForEach(menu.children ?? []) { child in
                            
                            //if there is a specific action tied to the app, we make it a button
                            if let action = child.action {
                                StartMenuAppButton(action: action, app: child.app!)
                                
                            //otherwise you ca tap on the text to navigate further into the gui
                            } else {
                                Text(child.name ?? "").onTapGesture {
                                    menu = child
                                }
                            }
                        }
                    }
                }
            }.background(Color.gray)
        }
    }
}

struct StartMenuAppButton: View {
    
    var action: () -> Void
    var app: App?
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack {
                if let icon = app?.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 50, height: 50)
                        .aspectRatio(contentMode: .fit)
                }
                
                if let appName = app?.name {
                    Text(appName)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .buttonStyle(HighlightButtonStyle())
        }
    }
}

struct HighlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .background()
            .cornerRadius(8)
    }
}
