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

    // Local scheduled notifications are not supported on Flutter web.
    if (kIsWeb) {
      _initialized = true;
      return;
    }

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
    if (kIsWeb) return false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      var granted = (await Permission.notification.status).isGranted;
      if (!granted) {
        granted = (await Permission.notification.request()).isGranted;
        await androidPlugin?.requestNotificationsPermission();
      }
      // Do not open the system "Alarms & reminders" settings on every launch —
      // that hijacks the UI. Exact alarms are requested only when scheduling.
      return granted;
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
    if (kIsWeb) return;

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

      final daysLeft = reminder.daysUntilHarvest >= 0
          ? reminder.daysUntilHarvest
          : reminder.daysBefore;
      final title = daysLeft == 0
          ? 'Harvest today'
          : daysLeft == 1
              ? 'Harvest tomorrow'
              : 'Harvest in $daysLeft days';

      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
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
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: reminder.toPayload(),
        );
      } catch (e) {
        // Exact alarms may be denied — fall back to inexact scheduling.
        try {
          await _plugin.zonedSchedule(
            id: id,
            title: title,
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
        } catch (fallbackError) {
          debugPrint('Failed to schedule harvest reminder: $fallbackError');
        }
      }
    }
  }

  Future<void> clearAll() async {
    await initialize();
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  /// Shows an immediate notification to verify permissions and channel setup.
  Future<void> showTestHarvestNotification({HarvestReminder? reminder}) async {
    await initialize();
    if (kIsWeb) {
      debugPrint('Test harvest notification skipped on web');
      return;
    }

    final sample = reminder ??
        HarvestReminder(
          farmId: 'test-farm',
          farmName: 'Test Farm',
          crop: 'Paddy',
          harvestType: 'Manual',
          harvestDate: DateTime.now().add(const Duration(days: 5)),
          remindOn: DateTime.now(),
          daysUntilHarvest: 5,
        );

    final cropLabel =
        sample.crop.trim().isEmpty ? 'crop' : sample.crop.trim();

    final daysLeft = sample.daysUntilHarvest >= 0
        ? sample.daysUntilHarvest
        : sample.daysBefore;
    final title = daysLeft == 0
        ? 'Test: Harvest today'
        : daysLeft == 1
            ? 'Test: Harvest tomorrow'
            : 'Test: Harvest in $daysLeft days';

    await _plugin.show(
      id: 0x7ffffffe,
      title: title,
      body:
          '${sample.farmName} ($cropLabel) harvest is on '
          '${_formatDate(sample.harvestDate)}',
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
      payload: sample.toPayload(),
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}
