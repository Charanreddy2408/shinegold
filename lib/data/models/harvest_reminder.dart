import 'dart:convert';

/// A farm harvest reminder used for local/push notification scheduling.
class HarvestReminder {
  const HarvestReminder({
    required this.farmId,
    required this.farmName,
    required this.crop,
    required this.harvestType,
    required this.harvestDate,
    required this.remindOn,
    required this.daysUntilHarvest,
    this.daysBefore = 5,
  });

  final String farmId;
  final String farmName;
  final String crop;
  final String harvestType;
  final DateTime harvestDate;
  final DateTime remindOn;
  final int daysUntilHarvest;
  final int daysBefore;

  factory HarvestReminder.fromJson(
    Map<String, dynamic> json, {
    int daysBefore = 5,
  }) {
    return HarvestReminder(
      farmId: json['farm_id']?.toString() ?? '',
      farmName: json['farm_name'] as String? ?? '',
      crop: json['crop'] as String? ?? '',
      harvestType: json['harvest_type'] as String? ?? '',
      harvestDate: DateTime.parse(json['harvest_date'] as String),
      remindOn: DateTime.parse(json['remind_on'] as String),
      daysUntilHarvest: json['days_until_harvest'] as int? ?? 0,
      daysBefore: daysBefore,
    );
  }

  static List<HarvestReminder> listFromResponse(dynamic data) {
    if (data is! Map<String, dynamic>) return [];
    final daysBefore = data['days_before'] as int? ?? 5;
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map((e) => HarvestReminder.fromJson(e, daysBefore: daysBefore))
        .toList();
  }

  String toPayload() => jsonEncode({'farm_id': farmId});
}
