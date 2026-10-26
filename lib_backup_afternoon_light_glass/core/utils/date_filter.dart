enum DateFilterOption {
  today('today', 'Hôm nay'),
  yesterday('yesterday', 'Hôm qua'),
  thisWeek('this_week', 'Tuần này'),
  lastWeek('last_week', 'Tuần trước'),
  thisMonth('this_month', 'Tháng này'),
  lastMonth('last_month', 'Tháng trước'),
  thisYear('this_year', 'Năm nay'),
  allTime('all_time', 'Tất cả');

  final String key;
  final String label;
  const DateFilterOption(this.key, this.label);
}

bool isDateInFilterOption(int timestampMs, DateFilterOption option) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final d = DateTime.fromMillisecondsSinceEpoch(timestampMs);
  final dayStart = DateTime(d.year, d.month, d.day);
  bool inRange(DateTime start, DateTime end) =>
      timestampMs >= start.millisecondsSinceEpoch &&
      timestampMs < end.millisecondsSinceEpoch;

  switch (option) {
    case DateFilterOption.today:
      return dayStart == todayStart;
    case DateFilterOption.yesterday:
      return dayStart == todayStart.subtract(const Duration(days: 1));
    case DateFilterOption.thisWeek:
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
      return inRange(weekStart, weekStart.add(const Duration(days: 7)));
    case DateFilterOption.lastWeek:
      final weekStart =
          todayStart.subtract(Duration(days: now.weekday - 1 + 7));
      return inRange(weekStart, weekStart.add(const Duration(days: 7)));
    case DateFilterOption.thisMonth:
      return inRange(DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 1));
    case DateFilterOption.lastMonth:
      return inRange(DateTime(now.year, now.month - 1, 1),
          DateTime(now.year, now.month, 1));
    case DateFilterOption.thisYear:
      return inRange(DateTime(now.year, 1, 1), DateTime(now.year + 1, 1, 1));
    case DateFilterOption.allTime:
      return true;
  }
}

String monthKeyOf(int timestampMs) {
  final d = DateTime.fromMillisecondsSinceEpoch(timestampMs);
  return '${d.year}-${d.month.toString().padLeft(2, '0')}';
}

String currentMonthKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}
