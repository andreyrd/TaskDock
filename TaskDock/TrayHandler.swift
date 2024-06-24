//
//  TrayHandler.swift
//  TaskDock
//
//  Created by Andrey Radchishin on 7/21/23.
//

import AXSwift
import Foundation

class TrayHandler {
    
    public func getApps() -> [App] {
        
        let apps = getAllAppASNs()
        let infos = apps.map { getAppInfo(asn: $0) }
        var dockInfo: [String: String] = [:]
        
        var configured = [
            ("Discord", "com.hnc.Discord"),
            //("Element", "im.riot.app"),
            //("Slack", "com.tinyspeck.slackmacgap"),
            ("Mattermost", "Mattermost.Desktop"),
            ("Messages", "com.apple.MobileSMS"),
        ]
        
        if let dock = Application.allForBundleID("com.apple.dock").first {
            if let children: [AXUIElement] = try? dock.attribute(kAXChildrenAttribute) {
                if let child = children.first {
                    let element = UIElement(child)
                    if let listChildren: [AXUIElement] = try? element.attribute(kAXChildrenAttribute) {
                        let elementChildren = listChildren.map { UIElement($0) }
                        elementChildren.forEach { element in
                            if let title: String = try? element.attribute(kAXTitleAttribute),
                               let status: String = try? element.attribute("AXStatusLabel") {
                                dockInfo[title] = status
                            }
                        }
                    }
                }
            }
        }
        
        return configured.map { (name, bundleId) in
            let path = StaticLookups.grabPath(bundleId: bundleId)
            let info = infos.first(where: {
                $0["CFBundleIdentifier"] as? String == bundleId
            })
            
            let statusLabel = info?["StatusLabel"] as? [String: String]
        
            let status = statusLabel?["label"] ?? dockInfo[name]
            
            return App(name: name, icon: StaticLookups.grabIcon(path: path), bundleId: bundleId, path: path,
                       status: status)
        }
    }
}
