//
//  AppDelegate.swift
//  HelloCalendar
//
//  Created by Mike Hummel on 14.08.25.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool {
        // Verhindere, dass die App beendet wird, wenn das letzte Fenster geschlossen wird
        return false
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setze den Delegate für alle Fenster
        for window in NSApp.windows {
            if window.identifier?.rawValue == "main" {
                window.delegate = self
            }
        }
        
        // Überwache neue Fenster
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeMain),
            name: NSWindow.didBecomeMainNotification,
            object: nil
        )
    }
    
    @objc func windowDidBecomeMain(_ notification: Notification) {
        if let window = notification.object as? NSWindow,
           window.identifier?.rawValue == "main" {
            window.delegate = self
        }
    }
    
    // NSWindowDelegate Methode - wird aufgerufen, wenn Benutzer versucht, das Fenster zu schließen
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if sender.identifier?.rawValue == "main" {
            // Verstecke das Fenster anstatt es zu schließen
            sender.orderOut(nil)
            return false
        }
        return true
    }
}
