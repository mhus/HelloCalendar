//
//  ContentView.swift
//  HelloCalendar
//
//  Created by Mike Hummel on 14.08.25.
//

import SwiftUI
import EventKit

struct ContentView: View {
    @State private var calendars: [EKCalendar] = []
    @State private var permissionStatus: String = "Nicht angefordert"
    @State private var isLoading = false
    
    private let eventStore = EKEventStore()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Text("Kalender Berechtigungen")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Status: \(permissionStatus)")
                        .foregroundColor(getStatusColor())
                    
                    Button("Berechtigung anfordern") {
                        requestCalendarPermission()
                    }
                    .disabled(isLoading)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                if !calendars.isEmpty {
                    Text("Verfügbare Kalender (\(calendars.count))")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    List(calendars, id: \.calendarIdentifier) { calendar in
                        HStack {
                            Circle()
                                .fill(Color(calendar.cgColor))
                                .frame(width: 12, height: 12)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(calendar.title)
                                    .font(.headline)
                                
                                Text(calendar.source.title)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("Typ: \(calendarTypeString(for: calendar.type))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if calendar.allowsContentModifications {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } else if permissionStatus == "Gewährt" {
                    Text("Keine Kalender gefunden")
                        .foregroundColor(.secondary)
                        .italic()
                }
                
                if isLoading {
                    ProgressView("Lade Kalender...")
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Hello Calendar")
        }
        .onAppear {
            checkPermissionStatus()
        }
    }
    
    private func requestCalendarPermission() {
        isLoading = true
        
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if granted {
                        self.permissionStatus = "Gewährt"
                        self.loadCalendars()
                    } else {
                        self.permissionStatus = "Verweigert"
                        if let error = error {
                            print("Fehler bei Berechtigung: \(error.localizedDescription)")
                        }
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if granted {
                        self.permissionStatus = "Gewährt"
                        self.loadCalendars()
                    } else {
                        self.permissionStatus = "Verweigert"
                        if let error = error {
                            print("Fehler bei Berechtigung: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    private func checkPermissionStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .notDetermined:
            permissionStatus = "Nicht angefordert"
        case .restricted:
            permissionStatus = "Eingeschränkt"
        case .denied:
            permissionStatus = "Verweigert"
        case .authorized:
            permissionStatus = "Gewährt"
            loadCalendars()
        case .fullAccess:
            permissionStatus = "Gewährt"
            loadCalendars()
        case .writeOnly:
            permissionStatus = "Nur Schreibzugriff"
            loadCalendars()
        @unknown default:
            permissionStatus = "Unbekannt"
        }
    }
    
    private func loadCalendars() {
        calendars = eventStore.calendars(for: .event)
    }
    
    private func getStatusColor() -> Color {
        switch permissionStatus {
        case "Gewährt":
            return .green
        case "Verweigert", "Eingeschränkt":
            return .red
        case "Nur Schreibzugriff":
            return .orange
        default:
            return .secondary
        }
    }
    
    private func calendarTypeString(for type: EKCalendarType) -> String {
        switch type {
        case .local:
            return "Lokal"
        case .calDAV:
            return "CalDAV"
        case .exchange:
            return "Exchange"
        case .subscription:
            return "Abonnement"
        case .birthday:
            return "Geburtstag"
        @unknown default:
            return "Unbekannt"
        }
    }
}

#Preview {
    ContentView()
}
