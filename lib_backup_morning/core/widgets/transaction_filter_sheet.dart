import 'package:flutter/material.dart';
import '../utils/date_filter.dart';
import 'period_picker.dart';

class FilterResult {
  final String owner; // 'all', 'husband', 'wife'
  final String type; // 'all', 'income', 'expense', 'investment'
  final String query;
  final String category;
  final String
      timeRange; // 'all', 'today', 'yesterday', 'this_week', 'this_month', 'this_year', 'custom'
  final int? selectedMonth;
  final int? selectedYear;
  final DateTime? customDate;

  const FilterResult({
    this.owner = 'all',
    this.type = 'all',
    this.query = '',
    this.category = 'all',
    this.timeRange = 'all',
    this.selectedMonth,
    this.selectedYear,
    this.customDate,
  });
  PeriodSelection get period {
    if (customDate != null)
      return PeriodSelection(DateFilterOption.customDate, date: customDate);
    if (selectedMonth != null && selectedYear != null)
      return PeriodSelection(DateFilterOption.customMonth,
          date: DateTime(selectedYear!, selectedMonth!));
    return PeriodSelection(DateFilterOption.values.firstWhere(
        (o) => o.key == timeRange,
        orElse: () => DateFilterOption.allTime));
  }

  FilterResult withPeriod(PeriodSelection value) => FilterResult(
      owner: owner,
      type: type,
      query: query,
      category: category,
      timeRange: value.option.key,
      customDate:
          value.option == DateFilterOption.customDate ? value.date : null,
      selectedMonth: value.option == DateFilterOption.customMonth
          ? value.date?.month
          : null,
      selectedYear: value.option == DateFilterOption.customMonth
          ? value.date?.year
          : null);
}

class TransactionFilterSheet extends StatefulWidget {
  final FilterResult initialFilter;
  final ValueChanged<FilterResult> onApply;
  final List<String> categories;
  const TransactionFilterSheet(
      {super.key,
      required this.initialFilter,
      required this.onApply,
      this.categories = const []});
  static Future<FilterResult?> show(BuildContext context,
          {required FilterResult initialFilter,
          List<String> categories = const []}) =>
      showModalBottomSheet<FilterResult>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: (ctx) => TransactionFilterSheet(
              initialFilter: initialFilter,
              categories: categories,
              onApply: (v) => Navigator.pop(ctx, v)));
  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  late String owner, type, category;
  late PeriodSelection period;
  @override
  void initState() {
    super.initState();
    owner = widget.initialFilter.owner;
    type = widget.initialFilter.type;
    category = widget.initialFilter.category;
    period = widget.initialFilter.period;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .8),
        child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text('Bộ lọc giao dịch',
                            style: theme.textTheme.titleLarge)),
                    TextButton(
                        onPressed: () => setState(() {
                              owner = 'all';
                              type = 'all';
                              category = 'all';
                              period = const PeriodSelection(
                                  DateFilterOption.allTime);
                            }),
                        child: const Text('Đặt lại'))
                  ]),
                  Flexible(
                      child: SingleChildScrollView(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                        const SizedBox(height: 12),
                        Text('Thành viên', style: theme.textTheme.titleSmall),
                        _options([
                          ('all', 'Tất cả'),
                          ('husband', 'Chồng'),
                          ('wife', 'Vợ')
                        ], owner, (v) => setState(() => owner = v)),
                        const SizedBox(height: 16),
                        Text('Loại giao dịch',
                            style: theme.textTheme.titleSmall),
                        _options([
                          ('all', 'Tất cả'),
                          ('expense', 'Chi tiêu'),
                          ('income', 'Thu nhập'),
                          ('investment', 'Đầu tư')
                        ], type, (v) => setState(() => type = v)),
                        const SizedBox(height: 16),
                        Text('Thời gian', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        ListTile(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            tileColor: theme.colorScheme.surfaceContainerLow,
                            leading: const Icon(Icons.date_range_outlined),
                            title: Text(period.label),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () async {
                              final picked = await PeriodPicker.show(context,
                                  initial: period);
                              if (picked != null && mounted)
                                setState(() => period = picked);
                            }),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                            initialValue: widget.categories.contains(category)
                                ? category
                                : 'all',
                            isExpanded: true,
                            decoration:
                                const InputDecoration(labelText: 'Danh mục'),
                            items: [
                              const DropdownMenuItem(
                                  value: 'all', child: Text('Tất cả danh mục')),
                              for (final name in widget.categories.toSet())
                                DropdownMenuItem(
                                    value: name,
                                    child: Text(name,
                                        overflow: TextOverflow.ellipsis))
                            ],
                            onChanged: (value) =>
                                setState(() => category = value ?? 'all'),
                            key: ValueKey(category)),
                        const SizedBox(height: 20),
                      ]))),
                  SafeArea(
                      top: false,
                      child: FilledButton(
                          onPressed: () => widget.onApply(FilterResult(
                                  owner: owner,
                                  type: type,
                                  category: category,
                                  query: widget.initialFilter.query)
                              .withPeriod(period)),
                          child: const Text('Áp dụng bộ lọc'))),
                ])));
  }

  Widget _options(List<(String, String)> options, String selected,
          ValueChanged<String> onChanged) =>
      Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(spacing: 8, runSpacing: 4, children: [
            for (final item in options)
              ChoiceChip(
                  label: Text(item.$2),
                  selected: selected == item.$1,
                  onSelected: (_) => onChanged(item.$1)),
          ]));
}
