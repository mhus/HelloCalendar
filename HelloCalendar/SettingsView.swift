//
//  SettingsView.swift
//  HelloCalendar
//
//  Created by Mike Hummel on 14.08.25.
//

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("openMainWindowOnStart") private var openMainWindowOnStart = true
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        TabView {
            GeneralSettingsView(
                launchAtLogin: $launchAtLogin,
                openMainWindowOnStart: $openMainWindowOnStart,
                showingAlert: $showingAlert,
                alertMessage: $alertMessage
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }
            .tag("general")
        }
        .frame(width: 500, height: 350)
        .alert("Einstellungen", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}

struct GeneralSettingsView: View {
    @Binding var launchAtLogin: Bool
    @Binding var openMainWindowOnStart: Bool
    @Binding var showingAlert: Bool
    @Binding var alertMessage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Allgemeine Einstellungen")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Start-Verhalten")
                    .font(.headline)
                
                Toggle("App beim Login starten", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { oldValue, newValue in
                        updateLoginItem(enabled: newValue)
                    }
                
                Text("Wenn aktiviert, wird die App automatisch gestartet, wenn Sie sich bei macOS anmelden.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 20)
                
                Divider()
                
                Text("Fenster-Verhalten")
                    .font(.headline)
                
                Toggle("Hauptfenster beim Start öffnen", isOn: $openMainWindowOnStart)
                
                Text("Wenn deaktiviert, startet die App im Hintergrund ohne sichtbares Fenster.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 20)
            }
            
            Spacer()
        }
        .padding(20)
        .onAppear {
            checkLoginItemStatus()
        }
    }
    
    private func updateLoginItem(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                    alertMessage = "App wurde erfolgreich für den automatischen Start beim Login registriert."
                } else {
                    try SMAppService.mainApp.unregister()
                    alertMessage = "App wurde erfolgreich vom automatischen Start beim Login entfernt."
                }
                showingAlert = true
            } catch {
                launchAtLogin = !enabled // Rückgängig machen bei Fehler
                alertMessage = "Fehler beim Ändern der Login-Einstellung: \(error.localizedDescription)"
                showingAlert = true
            }
        } else {
            // Fallback für ältere macOS Versionen - nicht mehr verwendet
            alertMessage = "Diese Funktion erfordert macOS 13.0 oder neuer."
            launchAtLogin = !enabled
            showingAlert = true
        }
    }
    
    private func checkLoginItemStatus() {
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        } else {
            // Für ältere Versionen
            launchAtLogin = false
        }
    }
}

#Preview {
    SettingsView()
}
