import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/glass_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../data/models/finance_models.dart';
import '../../state/more_provider.dart';
import '../../state/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;
  const SettingsScreen({super.key, required this.userId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  StreamSubscription? _sub;

  // Local mirror of MoreProvider.settings.
  String _currency = 'VND';
  bool _allowNegativeBalance = false;
  int _financeMonthStartDay = 1;
  String _dateFormat = 'DD/MM/YYYY';

  @override
  void initState() {
    super.initState();
    final more = context.read<MoreProvider>();
    more.load(widget.userId);
    _syncFrom(more.settings);
    _sub = more.events.listen((msg) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    });
  }

  void _syncFrom(AppSettings s) {
    _currency = s.currency;
    _allowNegativeBalance = s.allowNegativeBalance;
    _financeMonthStartDay = s.financeMonthStartDay;
    _dateFormat = s.dateFormat;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _save() {
    final more = context.read<MoreProvider>();
    more.updateSettings(
      widget.userId,
      more.settings.copyWith(
        currency: _currency,
        allowNegativeBalance: _allowNegativeBalance,
        financeMonthStartDay: _financeMonthStartDay,
        dateFormat: _dateFormat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final theme = context.watch<ThemeController>();

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Cài đặt ứng dụng',
        onBack: () => Navigator.of(context).pop(),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined, color: AppColors.accent),
            tooltip: 'Lưu',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 40),
        children: [
          Text(
            'CẤU HÌNH TIỀN TỆ & HIỂN THỊ',
            style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: AppSpacing.md),

          // Theme
          _SettingCard(
            title: 'Giao diện ứng dụng',
            child: SegmentedControl(
              options: const [
                ('system', 'Hệ thống'),
                ('light', 'Sáng'),
                ('dark', 'Tối'),
              ],
              selected: theme.mode,
              onChanged: (v) => context.read<ThemeController>().setMode(v),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Currency
          _SettingCard(
            title: 'Đơn vị tiền tệ chính',
            child: SegmentedControl(
              options: const [
                ('VND', 'VND'),
                ('USD', 'USD'),
              ],
              selected: _currency,
              onChanged: (v) => setState(() => _currency = v),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Allow negative balance
          GlassCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cho phép số dư âm',
                          style: AppTypography.body
                              .copyWith(color: primaryTextColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('Cho phép hiển thị ví khi có số dư nhỏ hơn 0',
                          style: AppTypography.caption2.copyWith(color: secondaryTextColor)),
                    ],
                  ),
                ),
                Switch(
                  value: _allowNegativeBalance,
                  activeTrackColor: AppColors.accent,
                  activeColor: Colors.white,
                  onChanged: (v) => setState(() => _allowNegativeBalance = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Date format
          _SettingCard(
            title: 'Định dạng ngày tháng',
            child: SegmentedControl(
              options: const [
                ('DD/MM/YYYY', 'DD/MM'),
                ('MM/DD/YYYY', 'MM/DD'),
                ('YYYY/MM/DD', 'YYYY/MM'),
              ],
              selected: _dateFormat,
              onChanged: (v) => setState(() => _dateFormat = v),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Finance month start day
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ngày bắt đầu chu kỳ tài chính',
                    style: AppTypography.body
                        .copyWith(color: primaryTextColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                    'Ngày chốt chu kỳ tính ngân sách hàng tháng: ngày $_financeMonthStartDay',
                    style: AppTypography.caption2.copyWith(color: secondaryTextColor)),
                const SizedBox(height: 10),
                Slider(
                  value: _financeMonthStartDay.toDouble(),
                  min: 1,
                  max: 31,
                  divisions: 30,
                  label: '$_financeMonthStartDay',
                  activeColor: AppColors.accent,
                  thumbColor: AppColors.accent,
                  inactiveColor: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12),
                  onChanged: (v) => setState(() => _financeMonthStartDay = v.round()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SettingCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTypography.body
                  .copyWith(color: primaryTextColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}
