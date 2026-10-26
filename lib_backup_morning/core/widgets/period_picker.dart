import 'package:flutter/material.dart';
import '../utils/date_filter.dart';

/// A period, not a single representative day. Shared by every overview filter.
class PeriodSelection {
  final DateFilterOption option;
  final DateTime? date;
  const PeriodSelection(this.option, {this.date});
  String get label => option == DateFilterOption.customMonth && date != null
      ? 'Tháng ${date!.month}/${date!.year}'
      : option == DateFilterOption.customDate && date != null
          ? '${date!.day}/${date!.month}/${date!.year}'
          : option.label;
  bool matches(int timestamp) => isDateInFilterOption(
      timestamp > 100000000000 ? timestamp : timestamp * 1000, option,
      customDate: date, customYear: date?.year, customMonth: date?.month);
}

class PeriodPicker extends StatefulWidget {
  final PeriodSelection initial;
  const PeriodPicker({super.key, required this.initial});
  static Future<PeriodSelection?> show(BuildContext context,
          {required PeriodSelection initial}) =>
      showModalBottomSheet<PeriodSelection>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: (_) => PeriodPicker(initial: initial));
  @override
  State<PeriodPicker> createState() => _PeriodPickerState();
}

class _PeriodPickerState extends State<PeriodPicker> {
  late PeriodSelection selected;
  late DateTime month;
  @override
  void initState() {
    super.initState();
    selected = widget.initial;
    final d = selected.date ?? DateTime.now();
    month = DateTime(d.year, d.month);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calendar = selected.option == DateFilterOption.customDate;
    final monthMode = selected.option == DateFilterOption.customMonth;
    return ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .82),
        child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text('Khoảng thời gian',
                            style: theme.textTheme.titleLarge)),
                    IconButton(
                        tooltip: 'Đóng',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded))
                  ]),
                  Flexible(
                      child: SingleChildScrollView(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 6, children: [
                          for (final option in [
                            DateFilterOption.today,
                            DateFilterOption.yesterday,
                            DateFilterOption.thisWeek,
                            DateFilterOption.lastWeek,
                            DateFilterOption.thisMonth,
                            DateFilterOption.lastMonth,
                            DateFilterOption.thisYear,
                            DateFilterOption.allTime
                          ])
                            ChoiceChip(
                                label: Text(option.label),
                                selected: selected.option == option,
                                onSelected: (_) => setState(
                                    () => selected = PeriodSelection(option))),
                        ]),
                        const SizedBox(height: 16),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          ChoiceChip(
                              label: const Text('Chọn tháng'),
                              selected: monthMode,
                              onSelected: (_) => setState(() => selected =
                                  PeriodSelection(DateFilterOption.customMonth,
                                      date: month))),
                          ChoiceChip(
                              label: const Text('Chọn ngày'),
                              selected: calendar,
                              onSelected: (_) => setState(() => selected =
                                  PeriodSelection(DateFilterOption.customDate,
                                      date: selected.date ?? DateTime.now()))),
                        ]),
                        if (calendar || monthMode) ...[
                          const SizedBox(height: 12),
                          Row(children: [
                            IconButton(
                                tooltip: 'Trước',
                                icon: const Icon(Icons.chevron_left_rounded),
                                onPressed: () => setState(() {
                                      month = DateTime(
                                          month.year - (monthMode ? 1 : 0),
                                          month.month - (calendar ? 1 : 0));
                                    })),
                            Expanded(
                                child: Text(
                                    monthMode
                                        ? '${month.year}'
                                        : 'Tháng ${month.month}/${month.year}',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleMedium)),
                            IconButton(
                                tooltip: 'Sau',
                                icon: const Icon(Icons.chevron_right_rounded),
                                onPressed: () => setState(() {
                                      month = DateTime(
                                          month.year + (monthMode ? 1 : 0),
                                          month.month + (calendar ? 1 : 0));
                                    })),
                          ]),
                          if (monthMode)
                            GridView.count(
                                crossAxisCount: 3,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                childAspectRatio: 1.8,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                children: List.generate(
                                    12,
                                    (i) => TextButton(
                                        style: TextButton.styleFrom(
                                            backgroundColor:
                                                selected.date?.year == month.year && selected.date?.month == i + 1
                                                    ? theme.colorScheme
                                                        .primaryContainer
                                                    : theme.colorScheme
                                                        .surfaceContainerLow),
                                        onPressed: () => setState(() =>
                                            selected = PeriodSelection(
                                                DateFilterOption.customMonth,
                                                date: DateTime(month.year, i + 1))),
                                        child: Text('Tháng ${i + 1}')))),
                          if (calendar) ...[
                            Row(children: [
                              for (final label in [
                                'T2',
                                'T3',
                                'T4',
                                'T5',
                                'T6',
                                'T7',
                                'CN'
                              ])
                                Expanded(
                                    child: Center(
                                        child: Text(label,
                                            style: theme.textTheme.labelSmall)))
                            ]),
                            const SizedBox(height: 8),
                            GridView.count(
                                crossAxisCount: 7,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: List.generate(
                                    month.weekday -
                                        1 +
                                        DateTime(month.year, month.month + 1, 0)
                                            .day, (i) {
                                  final day = i - month.weekday + 2;
                                  if (day < 1) return const SizedBox.shrink();
                                  final date =
                                      DateTime(month.year, month.month, day);
                                  final active = selected.date != null &&
                                      DateUtils.isSameDay(selected.date, date);
                                  return Semantics(
                                      selected: active,
                                      child: TextButton(
                                          style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              backgroundColor: active
                                                  ? theme.colorScheme
                                                      .primaryContainer
                                                  : null),
                                          onPressed: () => setState(() =>
                                              selected = PeriodSelection(
                                                  DateFilterOption.customDate,
                                                  date: date)),
                                          child: Text('$day')));
                                })),
                          ],
                        ],
                        const SizedBox(height: 16),
                      ]))),
                  SafeArea(
                      top: false,
                      child: FilledButton(
                          onPressed: () => Navigator.pop(context, selected),
                          child: Text('Áp dụng · ${selected.label}'))),
                ])));
  }
}
