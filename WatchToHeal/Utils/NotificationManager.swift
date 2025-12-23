import Foundation
import UserNotifications
import Combine

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private override init() {
        super.init()
        checkAuthorization()
    }
    
    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }
    
    func scheduleWatchlistAlert(for movie: Movie) {
        // Only schedule if user authorized
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Watchlist Reminder"
        content.body = "Don't forget to watch \"\(movie.displayName)\" today! It's waiting for you to heal."
        content.sound = .default
        
        // Simple 24h reminder for now, or based on release date if available and in future
        // For a true "Watchlist Alert", we could check if release_date is today or upcoming
        
        // Trigger in 5 seconds for testing, or a specific date
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 86400, repeats: false) // 24 hours
        
        let request = UNNotificationRequest(identifier: "watchlist_\(movie.id)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleMovieReleaseAlert(for movie: Movie, releaseDate: Date) {
        guard isAuthorized else { return }
        
        // Release date alert
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: releaseDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let content = UNMutableNotificationContent()
        content.title = "New Release Alert! 🍿"
        content.body = "\"\(movie.displayName)\" is now available! Dive in and enjoy."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "release_\(movie.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelAlert(for movieId: Int) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["watchlist_\(movieId)", "release_\(movieId)"])
    }
}
