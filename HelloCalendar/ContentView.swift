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
    @State private var selectedCalendars: Set<String> = []
    @State private var todaysEvents: [EKEvent] = []
    @State private var disabledEvents: Set<String> = []
    @State private var permissionStatus: String = "Nicht angefordert"
    @State private var isLoading = false
    
    private let eventStore = EKEventStore()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Zeige Berechtigungsbereich nur wenn noch nicht gewährt
                if permissionStatus != "Gewährt" {
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
                }
                
                if !calendars.isEmpty {
                    HStack(spacing: 20) {
                        // Linke Seite: Kalender-Liste
                        VStack(alignment: .leading) {
                            Text("Verfügbare Kalender (\(calendars.count))")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            List(calendars, id: \.calendarIdentifier) { calendar in
                                HStack {
                                    Button(action: {
                                        toggleCalendarSelection(calendar)
                                    }) {
                                        Image(systemName: selectedCalendars.contains(calendar.calendarIdentifier) ? "checkmark.square.fill" : "square")
                                            .foregroundColor(selectedCalendars.contains(calendar.calendarIdentifier) ? .blue : .gray)
                                    }
                                    .buttonStyle(.plain)
                                    
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
                        }
                        .frame(minWidth: 300)
                        
                        Divider()
                        
                        // Rechte Seite: Termine von heute
                        VStack(alignment: .leading) {
                            Text("Termine heute (\(todaysEvents.count))")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            if todaysEvents.isEmpty {
                                Text("Keine Termine heute")
                                    .foregroundColor(.secondary)
                                    .italic()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                List(todaysEvents, id: \.eventIdentifier) { event in
                                    HStack {
                                        Button(action: {
                                            toggleEventSelection(event)
                                        }) {
                                            Image(systemName: isEventEnabled(event) ? "checkmark.square.fill" : "square")
                                                .foregroundColor(isEventEnabled(event) ? .green : .gray)
                                        }
                                        .buttonStyle(.plain)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(event.title ?? "Unbenannter Termin")
                                                .font(.headline)
                                                .strikethrough(!isEventEnabled(event))
                                                .foregroundColor(isEventEnabled(event) ? .primary : .secondary)
                                            
                                            if let startDate = event.startDate, let endDate = event.endDate {
                                                Text("\(formatTime(startDate)) - \(formatTime(endDate))")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            if let location = event.location, !location.isEmpty {
                                                Text(location)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        // Kalender-Indikator
                                        Circle()
                                            .fill(Color(event.calendar.cgColor))
                                            .frame(width: 8, height: 8)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        .frame(minWidth: 350)
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
            loadDisabledEvents()
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
    
    private func toggleCalendarSelection(_ calendar: EKCalendar) {
        if selectedCalendars.contains(calendar.calendarIdentifier) {
            selectedCalendars.remove(calendar.calendarIdentifier)
        } else {
            selectedCalendars.insert(calendar.calendarIdentifier)
        }
        loadTodaysEvents()
    }
    
    private func toggleEventSelection(_ event: EKEvent) {
        let eventKey = getEventKey(event)
        if disabledEvents.contains(eventKey) {
            disabledEvents.remove(eventKey)
        } else {
            disabledEvents.insert(eventKey)
        }
        saveDisabledEvents()
    }
    
    private func isEventEnabled(_ event: EKEvent) -> Bool {
        let eventKey = getEventKey(event)
        return !disabledEvents.contains(eventKey)
    }
    
    private func getEventKey(_ event: EKEvent) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: event.startDate)
        return "\(dateString)_\(event.eventIdentifier ?? "")"
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func loadTodaysEvents() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        let selectedCalendarsArray = calendars.filter { selectedCalendars.contains($0.calendarIdentifier) }
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: selectedCalendarsArray)
        todaysEvents = eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
    }
    
    private func saveDisabledEvents() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        UserDefaults.standard.set(Array(disabledEvents), forKey: "disabledEvents_\(today)")
    }
    
    private func loadDisabledEvents() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        let savedDisabledEvents = UserDefaults.standard.stringArray(forKey: "disabledEvents_\(today)") ?? []
        disabledEvents = Set(savedDisabledEvents)
    }
    
    private func loadCalendars() {
        calendars = eventStore.calendars(for: .event)
        // Alle Kalender standardmäßig auswählen
        selectedCalendars = Set(calendars.map { $0.calendarIdentifier })
        loadTodaysEvents()
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
