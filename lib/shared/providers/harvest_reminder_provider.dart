import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/enums.dart';
import '../../data/models/harvest_reminder.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

final harvestReminderSyncProvider = Provider<HarvestReminderSync>((ref) {
  return HarvestReminderSync(ref);
});

class HarvestReminderSync {
  HarvestReminderSync(this._ref);

  final Ref _ref;

  Future<int> sync({bool showTestNotification = false}) async {
    // Scheduled local notifications are unsupported on Flutter web.
    if (kIsWeb) return 0;

    final session = _ref.read(authProvider).valueOrNull;
    final role = session?.user.role;
    if (session == null ||
        (role != UserRole.executive && role != UserRole.superAdmin)) {
      await NotificationService.instance.clearAll();
      return 0;
    }

    try {
      final reminders = await _fetchReminders();
      await NotificationService.instance.syncHarvestReminders(reminders);
      if (showTestNotification && reminders.isNotEmpty) {
        await NotificationService.instance.showTestHarvestNotification(
          reminder: reminders.first,
        );
      }
      return reminders.length;
    } catch (e) {
      // Non-fatal — permission or network failures shouldn't block the UI.
      // ignore: avoid_print
      print('Harvest reminder sync skipped: $e');
      return -1;
    }
  }

  Future<List<HarvestReminder>> _fetchReminders() async {
    final client = _ref.read(dioClientProvider);
    final response = await client.dio.get(
      ApiEndpoints.harvestsReminders,
      queryParameters: {
        'days_before': 5,
        'horizon_days': 90,
      },
    );
    return HarvestReminder.listFromResponse(response.data);
  }
}
