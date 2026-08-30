import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/glass_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
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
    HapticFeedback.selectionClick();
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu cấu hình cài đặt')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = context.watch<ThemeController>();

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Cài đặt hệ thống',
        onBack: () => Navigator.of(context).pop(),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded, color: AppColors.primary, size: 24),
            tooltip: 'Lưu cài đặt',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
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
            const SizedBox(height: 12),

            // Currency
            _SettingCard(
              title: 'Đơn vị tiền tệ chính',
              child: SegmentedControl(
                options: const [
                  ('VND', 'VND (₫)'),
                  ('USD', 'USD (\$)'),
                ],
                selected: _currency,
                onChanged: (v) => setState(() => _currency = v),
              ),
            ),
            const SizedBox(height: 12),

            // Allow negative balance
            GlassCard(
              radius: 22,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cho phép số dư âm',
                          style: TextStyle(
                            color: c.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Hiển thị ví khi số dư nhỏ hơn 0',
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _allowNegativeBalance,
                    activeTrackColor: AppColors.primary,
                    activeColor: Colors.white,
                    onChanged: (v) => setState(() => _allowNegativeBalance = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Date format
            _SettingCard(
              title: 'Định dạng ngày tháng',
              child: SegmentedControl(
                options: const [
                  ('DD/MM/YYYY', 'DD/MM/YYYY'),
                  ('MM/DD/YYYY', 'MM/DD/YYYY'),
                  ('YYYY/MM/DD', 'YYYY/MM/DD'),
                ],
                selected: _dateFormat,
                onChanged: (v) => setState(() => _dateFormat = v),
              ),
            ),
            const SizedBox(height: 12),

            // Finance month start day
            GlassCard(
              radius: 22,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ngày bắt đầu chu kỳ tài chính',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ngày chốt chu kỳ tính ngân sách hàng tháng: ngày $_financeMonthStartDay',
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: _financeMonthStartDay.toDouble(),
                    min: 1,
                    max: 31,
                    divisions: 30,
                    label: '$_financeMonthStartDay',
                    activeColor: AppColors.primary,
                    thumbColor: AppColors.primary,
                    inactiveColor: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08),
                    onChanged: (v) => setState(() => _financeMonthStartDay = v.round()),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    final c = context.fc;

    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: c.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
