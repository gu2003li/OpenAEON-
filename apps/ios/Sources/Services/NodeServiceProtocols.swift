import CoreLocation
import Foundation
import OpenAEONKit
import UIKit

typealias OpenAEONCameraSnapResult = (format: String, base64: String, width: Int, height: Int)
typealias OpenAEONCameraClipResult = (format: String, base64: String, durationMs: Int, hasAudio: Bool)

protocol CameraServicing: Sendable {
    func listDevices() async -> [CameraController.CameraDeviceInfo]
    func snap(params: OpenAEONCameraSnapParams) async throws -> OpenAEONCameraSnapResult
    func clip(params: OpenAEONCameraClipParams) async throws -> OpenAEONCameraClipResult
}

protocol ScreenRecordingServicing: Sendable {
    func record(
        screenIndex: Int?,
        durationMs: Int?,
        fps: Double?,
        includeAudio: Bool?,
        outPath: String?) async throws -> String
}

@MainActor
protocol LocationServicing: Sendable {
    func authorizationStatus() -> CLAuthorizationStatus
    func accuracyAuthorization() -> CLAccuracyAuthorization
    func ensureAuthorization(mode: OpenAEONLocationMode) async -> CLAuthorizationStatus
    func currentLocation(
        params: OpenAEONLocationGetParams,
        desiredAccuracy: OpenAEONLocationAccuracy,
        maxAgeMs: Int?,
        timeoutMs: Int?) async throws -> CLLocation
    func startLocationUpdates(
        desiredAccuracy: OpenAEONLocationAccuracy,
        significantChangesOnly: Bool) -> AsyncStream<CLLocation>
    func stopLocationUpdates()
    func startMonitoringSignificantLocationChanges(onUpdate: @escaping @Sendable (CLLocation) -> Void)
    func stopMonitoringSignificantLocationChanges()
}

protocol DeviceStatusServicing: Sendable {
    func status() async throws -> OpenAEONDeviceStatusPayload
    func info() -> OpenAEONDeviceInfoPayload
}

protocol PhotosServicing: Sendable {
    func latest(params: OpenAEONPhotosLatestParams) async throws -> OpenAEONPhotosLatestPayload
}

protocol ContactsServicing: Sendable {
    func search(params: OpenAEONContactsSearchParams) async throws -> OpenAEONContactsSearchPayload
    func add(params: OpenAEONContactsAddParams) async throws -> OpenAEONContactsAddPayload
}

protocol CalendarServicing: Sendable {
    func events(params: OpenAEONCalendarEventsParams) async throws -> OpenAEONCalendarEventsPayload
    func add(params: OpenAEONCalendarAddParams) async throws -> OpenAEONCalendarAddPayload
}

protocol RemindersServicing: Sendable {
    func list(params: OpenAEONRemindersListParams) async throws -> OpenAEONRemindersListPayload
    func add(params: OpenAEONRemindersAddParams) async throws -> OpenAEONRemindersAddPayload
}

protocol MotionServicing: Sendable {
    func activities(params: OpenAEONMotionActivityParams) async throws -> OpenAEONMotionActivityPayload
    func pedometer(params: OpenAEONPedometerParams) async throws -> OpenAEONPedometerPayload
}

struct WatchMessagingStatus: Sendable, Equatable {
    var supported: Bool
    var paired: Bool
    var appInstalled: Bool
    var reachable: Bool
    var activationState: String
}

struct WatchQuickReplyEvent: Sendable, Equatable {
    var replyId: String
    var promptId: String
    var actionId: String
    var actionLabel: String?
    var sessionKey: String?
    var note: String?
    var sentAtMs: Int?
    var transport: String
}

struct WatchNotificationSendResult: Sendable, Equatable {
    var deliveredImmediately: Bool
    var queuedForDelivery: Bool
    var transport: String
}

protocol WatchMessagingServicing: AnyObject, Sendable {
    func status() async -> WatchMessagingStatus
    func setReplyHandler(_ handler: (@Sendable (WatchQuickReplyEvent) -> Void)?)
    func sendNotification(
        id: String,
        params: OpenAEONWatchNotifyParams) async throws -> WatchNotificationSendResult
}

extension CameraController: CameraServicing {}
extension ScreenRecordService: ScreenRecordingServicing {}
extension LocationService: LocationServicing {}
