import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private let categoryID = "SPRAY_REMINDER"

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        registerCategories()
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error { print("Notification error: \(error)") }
        }
    }

    private func registerCategories() {
        let spray  = UNNotificationAction(identifier: "SPRAY_ACTION",  title: "Spray",  options: [.foreground])
        let cancel = UNNotificationAction(identifier: "CANCEL_ACTION", title: "Cancel", options: [.destructive])
        let category = UNNotificationCategory(identifier: categoryID, actions: [cancel, spray],
                                              intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    func scheduleSprayReminder(after seconds: TimeInterval = 5) {
        let content = UNMutableNotificationContent()
        content.title = "CowGirls"
        content.body  = "Time to spray!"
        content.sound = .default
        content.categoryIdentifier = categoryID
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        )
    }

    func scheduleAmmoniaAlert(level: Int) {
        let content = UNMutableNotificationContent()
        content.title = "CowGirls ⚠️"
        content.sound = .default
        content.body  = level >= 25
            ? "NH₃ danger level (≥ 25 ppm) — Heavy spray + alert issued"
            : "NH₃ caution level (10–25 ppm) — Spray recommended"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        )
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
