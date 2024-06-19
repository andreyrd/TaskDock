//
//  ContentView.swift
//  TaskDock
//
//  Created by Andrey Radchishin on 7/19/23.
//

import AXSwift
import Combine
import SwiftUI
import UniformTypeIdentifiers

/*
 TODO:
 - add "pinned" apps that show on one side always
 - app launcher menu
 - figure out how to catch window move events, etc.
 - "system tray"
 - ability to drag an app into the settings to add it (kind of like privacy settings work on mac)
 - automatically show common apps that a user might want to add there (discord, slack, telegram, etc.)
 */


struct ContentView: View {
    
    let displayId: CGDirectDisplayID
    
    let spacePub = PassthroughSubject<Space, Never>()
    let trayPub = PassthroughSubject<[App], Never>()
    
    @State var space: Space
    @State var tray: [App]
    
    @State private var dragged: Window?
    @State var draggingWindows: [Window]?
    
    var onShowMenu: (() -> Void)?
    var onChangeOrder: ((_ displayId: CGDirectDisplayID, _ spaceId: CGSSpaceID, _ updated: [CGWindowID]) -> Void)?
    
    let sorter = SortHandler()
    
    var body: some View {
        
        HStack(spacing: 2) {
            
            
            Button(action: {
                onShowMenu?()
            }, label: {
                Image(systemName: "command").resizable().frame(width: 16, height: 16)
            }).buttonStyle(.borderless).padding(8)
            
            Button {
                let homeDir = FileManager.default.homeDirectoryForCurrentUser
                NSWorkspace.shared.open(homeDir)
            } label: {
                Image(systemName: "house").resizable().frame(width: 20, height: 20).symbolVariant(.fill)
            }.buttonStyle(.borderless).padding(8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(draggingWindows ?? space.windows, id: \.id) { window in
                        TaskBarItemView(window: window)
                            .onDrag({
                                dragged = window
                                draggingWindows = [Window](space.windows)
                                return NSItemProvider(object: String(window.id) as NSString)
                            }, preview: {
                                Rectangle().fill(Color.clear)
                            })
                            .onDrop(
                                of: [UTType.plainText],
                                delegate: ReorderDropDelegate(
                                    displayId: displayId,
                                    spaceId: space.id,
                                    item: window,
                                    onChangeOrder: onChangeOrder,
                                    data: $draggingWindows,
                                    dataa: $space.windows,
                                    dragged: $dragged)
                            )
                    }
                }.padding(8)
            }.fadeOutSides()
                .padding(-8)
            
            Spacer(minLength: 16)
            
            HStack(spacing: 2) {
                ForEach(tray, id: \.bundleId) { app in
                    Button(action: {
                        app.moveToSpace(space.id)
                        app.activate()
                    }, label: {
                        if let icon = app.icon {
                            Image(nsImage: icon).resizable().frame(width: 34, height: 34)
                        } else {
                            Text("\(app.name)")
                        }
                    }).buttonStyle(.borderless)
                        .overlay(HStack(alignment: .top) {
                            if let status = app.status, !status.isEmpty {
                                ZStack {
                                    Circle().fill(Color.red)
                                    Text(status).foregroundStyle(Color.white).font(.system(size: 12))
                                }.frame(width: 18, height: 18)
                                    .offset(x: 10, y: -10)
                                    .allowsHitTesting(false)
                            }
                        })
                }
            }.onDrop(of: [UTType.application], isTargeted: nil) { items in
                guard let item = items.first else { return false }
                
                item.loadFileRepresentation(for: UTType.application, completionHandler: { url, _, err in
                    print(url)
                })
                
                return true
            }
            
            Button(action: {
                CoreDockSendNotification("com.apple.expose.awake" as CFString)
            }, label: {
                Image(systemName: "macwindow.on.rectangle").resizable().frame(width: 18, height: 18)
            }).buttonStyle(.borderless).padding(8)

            Button(action: {
                CoreDockSendNotification("com.apple.showdesktop.awake" as CFString)
            }, label: {
                Image(systemName: "menubar.dock.rectangle").resizable().frame(width: 18, height: 18)
            }).buttonStyle(.borderless).padding(8)

        }.padding(8)
            .frame(maxWidth: .infinity, minHeight: 48)
            .onReceive(spacePub) { space in
                if dragged == nil {
                    self.space = space
                    draggingWindows = nil
                }
            }
            .onReceive(trayPub) { apps in
                self.tray = apps
            }
    }
}

struct DockMenuStyle: MenuStyle {
    func makeBody(configuration: Configuration) -> some View {
        Menu(configuration)
            .offset(y: -10)
    }
}

struct ReorderDropDelegate: DropDelegate {
    let displayId: CGDirectDisplayID
    let spaceId: CGSSpaceID
    let item: Window
    let onChangeOrder: ((_ displayId: CGDirectDisplayID, _ spaceId: CGSSpaceID, _ updated: [CGWindowID]) -> Void)?
    
    @Binding var data: [Window]?
    @Binding var dataa: [Window]
    @Binding var dragged: Window?
    
    func dropEntered(info: DropInfo) {
        guard item != dragged,
              let current = dragged,
              let from = data?.firstIndex(of: current),
              let to = data?.firstIndex(of: item)
        else {
            return
        }
        
        if data?[to] != current {
            withAnimation {
                // Just move local array initially
                data?.move(fromOffsets: IndexSet(integer: from), toOffset: from < to ? (to + 1) : to)
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        withAnimation {
            // Commit to the actual dataset
            onChangeOrder?(displayId, spaceId, data!.map { $0.id })
        }
        
        dragged = nil
        return true
    }
}
