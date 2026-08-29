import 'package:permission_handler/permission_handler.dart';
import 'package:vox_novel/features/narration/domain/services/notification_permission.dart';

/// Asks Android for the notification permission introduced in API 33.
///
/// Below that the permission does not exist and the platform reports it as
/// granted, so no version check is needed here.
final class PermissionHandlerNotifications implements NotificationPermission {
  const PermissionHandlerNotifications();

  @override
  Future<bool> ensureGranted() async {
    if (await Permission.notification.isGranted) return true;
    final status = await Permission.notification.request();
    return status.isGranted;
  }
}
