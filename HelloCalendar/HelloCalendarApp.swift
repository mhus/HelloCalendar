//
//  HelloCalendarApp.swift
//  HelloCalendar
//
//  Created by Mike Hummel on 14.08.25.
//

import SwiftUI

@main
struct HelloCalendarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Window("Hello Calendar", id: "main") {
            ContentView()
        }
        .windowResizability(.contentSize)
        .windowToolbarStyle(.unifiedCompact)
        .defaultPosition(.center)
        .commands {
            CommandGroup(after: .windowArrangement) {
                Button("Hauptfenster anzeigen") {
                    showMainWindow()
                }
                .keyboardShortcut("m", modifiers: [.command])
            }
        }
        
        Settings {
            SettingsView()
        }
    }
    
    private func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
