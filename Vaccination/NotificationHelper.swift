//
//  NotificationHelper.swift
//  Vaccination
//
//  Created by user66 on 12/12/25.
//

//import Foundation
import Foundation
import UserNotifications

struct NotificationHelper {
    static func scheduleLocalNotification(identifier: String = UUID().uuidString,
                                          title: String,
                                          body: String,
                                          date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let e = error { print("Notification schedule error:", e) }
            else { print("Notification scheduled for", date) }
        }
    }
}
