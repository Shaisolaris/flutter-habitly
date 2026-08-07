/// Weekday and month labels indexed to match [DateTime.weekday] (Monday = 1
/// ... Sunday = 7) and [DateTime.month] (January = 1 ... December = 12), so
/// the rest of the app never has to hand-roll a switch statement.
class DateLabels {
  const DateLabels._();

  static const List<String> _shortWeekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _fullWeekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _shortMonths = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// e.g. "Mon" for [DateTime.monday].
  static String shortWeekday(int weekday) => _shortWeekdays[weekday - 1];

  /// e.g. "Monday" for [DateTime.monday].
  static String fullWeekday(int weekday) => _fullWeekdays[weekday - 1];

  /// e.g. "Friday, Aug 7" for August 7th.
  static String fullDate(DateTime date) {
    final weekday = _fullWeekdays[date.weekday - 1];
    final month = _shortMonths[date.month - 1];
    return '$weekday, $month ${date.day}';
  }
}
