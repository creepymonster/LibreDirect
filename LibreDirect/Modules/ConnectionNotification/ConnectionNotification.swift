//
//  SensorConnectionLostAlert.swift
//  LibreDirect
//

import Combine
import Foundation
import UserNotifications

func connectionNotificationMiddelware() -> Middleware<AppState, AppAction> {
    return connectionNotificationMiddelware(service: ConnectionNotificationService())
}

private func connectionNotificationMiddelware(service: ConnectionNotificationService) -> Middleware<AppState, AppAction> {
    return { state, action, lastState in
        switch action {
        case .setConnectionAlarm(enabled: let enabled):
            if !enabled {
                service.clearNotifications()
            }

        case .setConnectionError(errorMessage: let errorMessage, errorTimestamp: _, errorIsCritical: let errorIsCritical):
            guard state.connectionAlarm else {
                break
            }

            AppLog.info("Sensor connection lost alert check: \(errorMessage), \(errorIsCritical)")

            service.sendSensorConnectionLostNotification(errorIsCritical: errorIsCritical)

        case .setConnectionState(connectionState: let connectionState):
            guard state.connectionAlarm else {
                break
            }

            AppLog.info("Sensor connection lost alert check: \(connectionState)")

            if lastState.connectionState == .connected, connectionState == .disconnected {
                service.sendSensorConnectionLostNotification()

            } else if lastState.connectionState != .connected, connectionState == .connected {
                service.clearNotifications()
            }

        case .addMissedReading:
            guard state.connectionAlarm else {
                break
            }

            AppLog.info("Sensor connection available, but missed readings")

            if state.missedReadings % 5 == 0 {
                service.sendSensorMissedReadingsNotification(missedReadings: state.missedReadings)
            }

        default:
            break
        }

        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - ConnectionNotificationService

private class ConnectionNotificationService {
    enum Identifier: String {
        case sensorConnectionAlert = "libre-direct.notifications.sensor-connection-alert"
    }

    func clearNotifications() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [Identifier.sensorConnectionAlert.rawValue])
    }

    func sendSensorConnectionLostNotification(errorIsCritical: Bool = false) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        NotificationService.shared.ensureCanSendNotification { ensured in
            AppLog.info("Sensor connection lLost alert, ensured: \(ensured)")

            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.title = LocalizedString("Alert, sensor connection lost", comment: "")

            if errorIsCritical {
                notification.sound = NotificationService.AlarmSound

                if #available(iOS 15.0, *) {
                    notification.interruptionLevel = .critical
                }

                notification.body = LocalizedString("The sensor cannot be connected and rejects all connection attempts. This problem makes it necessary to re-pair the sensor.", comment: "")
            } else {
                notification.sound = .none

                if #available(iOS 15.0, *) {
                    notification.interruptionLevel = .passive
                }

                notification.body = LocalizedString("The connection with the sensor has been interrupted. Normally this happens when the sensor is out of range or its transmission power is impaired.", comment: "")
            }

            NotificationService.shared.add(identifier: Identifier.sensorConnectionAlert.rawValue, content: notification)
        }
    }

    func sendSensorConnectionRestoredNotification() {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        NotificationService.shared.ensureCanSendNotification { ensured in
            AppLog.info("Sensor connection lLost alert, ensured: \(ensured)")

            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.sound = .none

            if #available(iOS 15.0, *) {
                notification.interruptionLevel = .passive
            }

            notification.title = LocalizedString("OK, sensor connection established", comment: "")
            notification.body = LocalizedString("The connection to the sensor has been successfully established and glucose data is received.", comment: "")

            NotificationService.shared.add(identifier: Identifier.sensorConnectionAlert.rawValue, content: notification)
        }
    }

    func sendSensorMissedReadingsNotification(missedReadings: Int) {
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        NotificationService.shared.ensureCanSendNotification { ensured in
            AppLog.info("Sensor missed readings, ensured: \(ensured)")

            guard ensured else {
                return
            }

            let notification = UNMutableNotificationContent()
            notification.sound = NotificationService.NegativeSound

            if #available(iOS 15.0, *) {
                notification.interruptionLevel = .timeSensitive
            }

            notification.title = String(format: LocalizedString("Warning, sensor missed %1$@ readings", comment: ""), missedReadings.description)
            notification.body = LocalizedString("The connection to the sensor seems to exist, but no values are received. Faulty sensor data may be the cause.", comment: "")

            NotificationService.shared.add(identifier: Identifier.sensorConnectionAlert.rawValue, content: notification)
        }
    }
}
