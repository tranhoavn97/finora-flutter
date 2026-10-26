enum DateFilterOption {
  today('today', 'Hôm nay'),
  yesterday('yesterday', 'Hôm qua'),
  thisWeek('this_week', 'Tuần này'),
  lastWeek('last_week', 'Tuần trước'),
  thisMonth('this_month', 'Tháng này'),
  lastMonth('last_month', 'Tháng trước'),
  thisYear('this_year', 'Năm nay'),
  customMonth('custom_month', 'Chọn tháng'),
  customDate('custom_date', 'Chọn ngày'),
  customRange('custom_range', 'Khoảng ngày'),
  allTime('all_time', 'Tất cả');

  final String key;
  final String label;
  const DateFilterOption(this.key, this.label);
}

bool isDateInFilterOption(
  int timestampMs,
  DateFilterOption option, {
  DateTime? customDate,
  DateTime? customStartDate,
  DateTime? customEndDate,
  int? customYear,
  int? customMonth,
}) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final d = DateTime.fromMillisecondsSinceEpoch(
      timestampMs > 100000000000 ? timestampMs : timestampMs * 1000);
  final dayStart = DateTime(d.year, d.month, d.day);
  bool inRange(DateTime start, DateTime end) =>
      d.millisecondsSinceEpoch >= start.millisecondsSinceEpoch &&
      d.millisecondsSinceEpoch < end.millisecondsSinceEpoch;

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
    case DateFilterOption.customMonth:
      final y = customYear ?? now.year;
      final m = customMonth ?? now.month;
      return d.year == y && d.month == m;
    case DateFilterOption.customDate:
      if (customDate == null) return true;
      return d.year == customDate.year &&
          d.month == customDate.month &&
          d.day == customDate.day;
    case DateFilterOption.customRange:
      if (customStartDate == null && customEndDate == null) return true;
      final start = customStartDate != null
          ? DateTime(customStartDate.year, customStartDate.month, customStartDate.day)
          : DateTime(2000);
      final end = customEndDate != null
          ? DateTime(customEndDate.year, customEndDate.month, customEndDate.day, 23, 59, 59, 999)
          : DateTime(2100);
      return d.millisecondsSinceEpoch >= start.millisecondsSinceEpoch &&
          d.millisecondsSinceEpoch <= end.millisecondsSinceEpoch;
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
