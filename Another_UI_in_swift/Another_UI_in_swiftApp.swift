//
//  Another_UI_in_swiftApp.swift
//  Another_UI_in_swift
//
//  Created by Maksim Tochilkin on 9/30/21.
//

import SwiftUI

@main
struct Another_UI_in_swiftApp: App {
    let contentView: AnyView
    let updater = Updater()
    
    init() {
        let contentView = ContentView(updater: self.updater)
        let children = Mirror(reflecting: contentView).children
        
        for child in children {
            if let injectable = child.value as? ViewGraphInjectable_ {
                injectable.setViewGraph(updater)
            }
        }
        
        self.contentView = AnyView(contentView)
    }
    var body: some Scene {
        WindowGroup {
            contentView
        }
    }
}
