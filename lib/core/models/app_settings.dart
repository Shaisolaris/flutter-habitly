/// User-configurable app preferences.
///
/// Kept as plain data (no `TimeOfDay` dependency) so it stays trivially
/// JSON-serializable; screens convert [reminderHour]/[reminderMinute] to a
/// `TimeOfDay` where needed.
class AppSettings {
  const AppSettings({
    required this.reminderHour,
    required this.reminderMinute,
    required this.weekStartDay,
  });

  /// Hour of the daily reminder, in 24-hour time (0-23).
  final int reminderHour;

  /// Minute of the daily reminder (0-59).
  final int reminderMinute;

  /// The first day of the week, using [DateTime.weekday] convention
  /// (Monday = 1 ... Sunday = 7). Used to align the stats heatmap.
  final int weekStartDay;

  factory AppSettings.defaults() {
    return const AppSettings(
      reminderHour: 8,
      reminderMinute: 0,
      weekStartDay: DateTime.monday,
    );
  }

  AppSettings copyWith({
    int? reminderHour,
    int? reminderMinute,
    int? weekStartDay,
  }) {
    return AppSettings(
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      weekStartDay: weekStartDay ?? this.weekStartDay,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'weekStartDay': weekStartDay,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      reminderHour: json['reminderHour'] as int,
      reminderMinute: json['reminderMinute'] as int,
      weekStartDay: json['weekStartDay'] as int,
    );
  }
}
