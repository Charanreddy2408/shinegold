import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/harvest_reminder.dart';

/// Local notifications for harvest reminders (5 days before harvest by default).
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  static const _channelId = 'harvest_reminders';
  static const _channelName = 'Harvest reminders';
  static const _notificationHour = 9;

  Future<void> initialize() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (_) {
      // Keep default UTC if location data missing.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Alerts 5 days before farm harvest dates',
        importance: Importance.high,
      ),
    );

    _initialized = true;
  }

  /// Requests notification permission at app start (Android 13+ / iOS).
  Future<bool> requestPermissionAtStartup() async {
    await initialize();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      if (status.isGranted) return true;
      final result = await Permission.notification.request();
      if (!result.isGranted) return false;

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      // Best-effort: exact alarms help fire at the planned time.
      await androidPlugin?.requestExactAlarmsPermission();
      return true;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      return granted;
    }

    return true;
  }

  Future<void> syncHarvestReminders(List<HarvestReminder> reminders) async {
    await initialize();
    await _plugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);

    for (final reminder in reminders) {
      if (reminder.farmId.isEmpty) continue;

      var when = tz.TZDateTime(
        tz.local,
        reminder.remindOn.year,
        reminder.remindOn.month,
        reminder.remindOn.day,
        _notificationHour,
      );

      // If remind day already passed but harvest is still upcoming, notify soon.
      if (when.isBefore(now) && reminder.daysUntilHarvest >= 0) {
        when = now.add(const Duration(minutes: 1));
      }
      if (when.isBefore(now)) continue;

      final id = reminder.farmId.hashCode & 0x7fffffff;
      final cropLabel =
          reminder.crop.trim().isEmpty ? 'crop' : reminder.crop.trim();

      try {
        await _plugin.zonedSchedule(
          id: id,
          title: 'Harvest in ${reminder.daysBefore} days',
          body:
              '${reminder.farmName} ($cropLabel) harvest is on '
              '${_formatDate(reminder.harvestDate)}',
          scheduledDate: when,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: 'Alerts 5 days before farm harvest dates',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: reminder.toPayload(),
        );
      } catch (e) {
        debugPrint('Failed to schedule harvest reminder: $e');
      }
    }
  }

  Future<void> clearAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}
