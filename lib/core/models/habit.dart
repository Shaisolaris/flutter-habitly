/// A single trackable habit.
///
/// A habit's [frequency] is the set of weekdays it is scheduled on, using
/// the same convention as [DateTime.weekday] (Monday = 1 ... Sunday = 7). A
/// "daily" habit is simply one whose frequency contains all seven days.
class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.frequency,
    required this.createdAt,
  });

  /// Locally-generated unique identifier.
  final String id;

  /// Short display name, e.g. "Morning run".
  final String name;

  /// Single emoji glyph used as the habit's icon.
  final String emoji;

  /// Weekdays this habit is scheduled on ([DateTime.monday]..[DateTime.sunday]).
  final Set<int> frequency;

  /// When the habit was created. Days before this are never counted as
  /// scheduled, regardless of [frequency].
  final DateTime createdAt;

  /// All seven [DateTime.weekday] values, Monday through Sunday.
  static const List<int> allWeekdays = <int>[1, 2, 3, 4, 5, 6, 7];

  /// Whether this habit is scheduled on every day of the week.
  bool get isDaily => frequency.length >= 7;

  /// Whether this habit is scheduled to happen on [date].
  bool isScheduledOn(DateTime date) => frequency.contains(date.weekday);

  Habit copyWith({
    String? id,
    String? name,
    String? emoji,
    Set<int>? frequency,
    DateTime? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      frequency: frequency ?? this.frequency,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'emoji': emoji,
      'frequency': frequency.toList()..sort(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    final rawFrequency = json['frequency'] as List<dynamic>;
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      frequency: rawFrequency.map((dynamic e) => e as int).toSet(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  String toString() => 'Habit($id, $name, $emoji, freq: $frequency)';
}
