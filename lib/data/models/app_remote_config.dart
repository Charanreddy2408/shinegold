class AppRemoteConfig {
  const AppRemoteConfig({
    required this.farmVisitCooldownDays,
    required this.executiveAssignmentRadiusKm,
    required this.maxVoiceNoteSeconds,
  });

  static const defaults = AppRemoteConfig(
    farmVisitCooldownDays: 30,
    executiveAssignmentRadiusKm: 70,
    maxVoiceNoteSeconds: 150,
  );

  final int farmVisitCooldownDays;
  final double executiveAssignmentRadiusKm;
  final int maxVoiceNoteSeconds;

  factory AppRemoteConfig.fromJson(Map<String, dynamic> json) => AppRemoteConfig(
        farmVisitCooldownDays:
            json['farm_visit_cooldown_days'] as int? ?? defaults.farmVisitCooldownDays,
        executiveAssignmentRadiusKm:
            (json['executive_assignment_radius_km'] as num?)?.toDouble() ??
                defaults.executiveAssignmentRadiusKm,
        maxVoiceNoteSeconds:
            json['max_voice_note_seconds'] as int? ?? defaults.maxVoiceNoteSeconds,
      );
}
