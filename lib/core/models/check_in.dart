/// A single completed check-in for a habit on a given calendar day.
///
/// [date] should always be normalized to midnight (no time component) so
/// equality and lookups behave predictably; see the helpers in
/// `core/logic/streaks.dart` for how comparisons are done safely regardless.
class CheckIn {
  const CheckIn({
    required this.habitId,
    required this.date,
  });

  final String habitId;
  final DateTime date;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'habitId': habitId,
      'date': date.toIso8601String(),
    };
  }

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      habitId: json['habitId'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }

  @override
  String toString() => 'CheckIn($habitId, $date)';
}
