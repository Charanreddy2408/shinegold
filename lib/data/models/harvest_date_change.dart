class HarvestDateChange {
  const HarvestDateChange({
    required this.id,
    required this.farmId,
    required this.oldDate,
    required this.newDate,
    required this.changedById,
    required this.changedByName,
    required this.changedAt,
    this.reason,
  });

  final String id;
  final String farmId;
  final DateTime oldDate;
  final DateTime newDate;
  final String changedById;
  final String changedByName;
  final DateTime changedAt;
  final String? reason;

  factory HarvestDateChange.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      final raw = value?.toString() ?? '';
      // API returns date-only (YYYY-MM-DD) for old/new.
      if (raw.length == 10) {
        return DateTime.parse('${raw}T00:00:00');
      }
      return DateTime.parse(raw);
    }

    return HarvestDateChange(
      id: json['id']?.toString() ?? '',
      farmId: json['farm_id']?.toString() ?? '',
      oldDate: parseDate(json['old_date']),
      newDate: parseDate(json['new_date']),
      changedById: json['changed_by_id']?.toString() ?? '',
      changedByName: json['changed_by_name'] as String? ?? 'Unknown',
      changedAt: DateTime.parse(json['changed_at'] as String),
      reason: json['reason'] as String?,
    );
  }
}
