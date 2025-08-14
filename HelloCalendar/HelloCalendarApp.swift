//
//  HelloCalendarApp.swift
//  HelloCalendar
//
//  Created by Mike Hummel on 14.08.25.
//

import SwiftUI

@main
struct HelloCalendarApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.appSettings) {
                Button("Einstellungen...") {
                    openSettings()
                }
                .keyboardShortcut(",")
            }
        }
        
        Settings {
            SettingsView()
        }
    }
    
    private func openSettings() {
        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
}
