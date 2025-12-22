import Foundation
import EventKit
import Combine

class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    private let eventStore = EKEventStore()
    
    @Published var isAuthorized = false
    
    private init() {
        checkStatus()
    }
    
    func checkStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, *) {
            isAuthorized = (status == .fullAccess)
        } else {
            isAuthorized = (status == .authorized)
        }
    }
    
    func requestAccess() async -> Bool {
        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                granted = try await eventStore.requestAccess(to: .event)
            }
            
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Calendar access error: \(error)")
            return false
        }
    }
    
    func addMovieReminder(movie: Movie) async -> (success: Bool, error: String?) {
        if !isAuthorized {
            let granted = await requestAccess()
            if !granted { return (false, "Calendar access denied") }
        }
        
        // Parse release date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let releaseDate = dateFormatter.date(from: movie.displayDate) else {
            return (false, "Invalid release date")
        }
        
        // Check if event already exists (optional but good for UX)
        // For simplicity, we create a new one here
        
        let event = EKEvent(eventStore: eventStore)
        event.title = "Movie Release: \(movie.displayName)"
        event.startDate = releaseDate
        event.endDate = releaseDate.addingTimeInterval(3600) // 1 hour duration
        event.calendar = eventStore.defaultCalendarForNewEvents
        event.notes = movie.overview + "\n\nSet via WatchToHeal"
        
        // Add alarm (1 day before)
        let alarm = EKAlarm(relativeOffset: -86400)
        event.addAlarm(alarm)
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return (true, nil)
        } catch {
            return (false, error.localizedDescription)
        }
    }
}
