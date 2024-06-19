//
//  TrayHandler.swift
//  TaskDock
//
//  Created by Andrey Radchishin on 7/21/23.
//

import Foundation

class TrayHandler {
    
    public func getApps() -> [App] {
        
        let apps = getAllAppASNs()
        let infos = apps.map { getAppInfo(asn: $0) }
        
        var configured = [
            ("Discord", "com.hnc.Discord"),
            //("Element", "im.riot.app"),
            //("Slack", "com.tinyspeck.slackmacgap"),
            //("Mattermost", "Mattermost.Desktop"),
        ]
    
        
        return configured.map { (name, bundleId) in
            let path = "/Applications/\(name).app"
            let info = infos.first(where: {
                $0["CFBundleIdentifier"] as? String == bundleId
            })
            
            let statusLabel = info?["StatusLabel"] as? [String: String]
            
            let status = statusLabel?["label"]
            
            return App(name: name, icon: StaticLookups.grabIcon(path: path), bundleId: bundleId, path: path,
                       status: status)
        }
    }
}
