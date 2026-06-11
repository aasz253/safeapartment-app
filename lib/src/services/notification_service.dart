import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../core/constants.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  late final FlutterLocalNotificationsPlugin _localNotifications;

  Future<void> initialize() async {
    OneSignal.initialize(AppConstants.oneSignalAppId);

    _localNotifications = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'threat_alerts',
      'Threat Alerts',
      channelDescription: 'Security threat notifications',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  Future<void> sendPushNotification({
    required String title,
    required String body,
    String? subtitle,
  }) async {
    await OneSignal.User.addTagWithKey('last_alert', DateTime.now().toIso8601String());
    await OneSignal.Notification.requestPermission(true);
  }

  Future<String?> getOneSignalPlayerId() async {
    final device = await OneSignal.User.pushSubscription.id;
    return device;
  }

  Future<void> setExternalUserId(String userId) async {
    await OneSignal.login(userId);
  }

  Future<void> removeExternalUserId() async {
    await OneSignal.logout();
  }
}
