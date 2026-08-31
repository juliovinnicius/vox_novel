/// Whether the app may post the media notification.
///
/// Behind a contract so the permission rules stay testable off a device, and
/// so the platform package stays in the data layer (AD-013).
abstract interface class NotificationPermission {
  /// Requests the permission if it has not been decided yet, and reports
  /// whether the app may post notifications.
  Future<bool> ensureGranted();
}
