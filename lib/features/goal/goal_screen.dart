import '../../core/widgets/finora_mascot.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_spacing.dart';
import '../../data/models/finance_models.dart';
import '../../state/more_provider.dart';
import '../../state/theme_studio_controller.dart';
import '../../core/widgets/finora_motion.dart';
import '../../core/widgets/finora_privacy_mask.dart';

/// Redesigned Savings Goals Page:
/// - Matching Finora's luxury Obsidian & Royal Indigo design language
/// - Compact Overview Card (total accumulated vs total target, sleek progress)
/// - Horizontal filter pills (All, In Progress, Near Target, Completed)
/// - Compact goal items with pastel category badges, dual progress stats, and quick deposit action
class GoalScreen extends StatefulWidget {
  final String userId;
  final bool isTab;
  const GoalScreen({
    super.key,
    required this.userId,
    this.isTab = true,
  });

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  StreamSubscription<String>? _eventsSub;
  String _goalFilter = 'all'; // 'all', 'active', 'near', 'completed'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MoreProvider>();
      provider.load(widget.userId);
      _eventsSub = provider.events.listen((msg) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
      });
    });
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    super.dispose();
  }

  void _openAdd() {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AddGoalPage(userId: widget.userId),
    ));
  }

  void _openEdit(Goal goal) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AddGoalPage(userId: widget.userId, existing: goal),
    ));
  }

  void _openDeposit(Goal goal) {
    showDialog(
      context: context,
      builder: (_) => _DepositDialog(userId: widget.userId, goal: goal),
    );
  }

  Future<void> _deleteGoal(Goal goal) async {
    final ok = await showConfirmDeleteDialog(
      context: context,
      title: 'Xóa mục tiêu?',
      content: 'Bạn có chắc chắn muốn xóa mục tiêu "${goal.name}" không?',
    );
    if (ok && mounted) {
      context.read<MoreProvider>().deleteGoal(widget.userId, goal.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final provider = context.watch<MoreProvider>();
    final allGoals = provider.goals;

    // Filter goals
    final activeGoals = allGoals.where((g) => g.status == 'active').toList();
    final completedGoals = allGoals.where((g) => g.status != 'active').toList();

    // Filtered display list
    final List<Goal> displayGoals;
    if (_goalFilter == 'completed') {
      displayGoals = completedGoals;
    } else if (_goalFilter == 'active') {
      displayGoals = activeGoals;
    } else if (_goalFilter == 'near') {
      displayGoals = activeGoals
          .where((g) =>
              g.targetAmount > 0 && (g.savedAmount / g.targetAmount) >= 0.8)
          .toList();
    } else {
      displayGoals = allGoals;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: _buildFilterPillsRow(isDark: isDark),
        ),
        Expanded(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Goals Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _goalFilter == 'completed'
                        ? 'Đã hoàn thành'
                        : (_goalFilter == 'near'
                            ? 'Sắp đạt mục tiêu'
                            : 'Danh sách mục tiêu'),
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${displayGoals.length} mục tiêu',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _openAdd,
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F6E56), Color(0xFF10B981)],
                            ),
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.30),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded,
                                  size: 14, color: Colors.white),
                              SizedBox(width: 3),
                              Text(
                                'Thêm',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Goal Cards List
              if (displayGoals.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 28, horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF1E293B) : Colors.white)
                        .withValues(
                            alpha: context
                                .watch<ThemeStudioController>()
                                .glassOpacity),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FinoraMascotImage(
                        pose: FinoraMascotPose.celebrate,
                        size: 76,
                        withGlow: true,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Chưa có mục tiêu nào trong mục này',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Đặt mục tiêu tiết kiệm mua nhà, xe, du lịch cùng Finora ngay!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: _openAdd,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F6E56), Color(0xFF10B981)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.30),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            '+ Tạo mục tiêu mới',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...displayGoals.asMap().entries.map((entry) {
                  return FinoraStaggeredItem(
                    index: entry.key,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildGoalCard(
                        goal: entry.value,
                        index: entry.key,
                        isDark: isDark,
                      ),
                    ),
                  );
                }),
            ]),
          ),
        ),
      ],
    ),
  ),
],
);
}

  Widget _buildFilterPillsRow({required bool isDark}) {
    const filters = ['all', 'active', 'near', 'completed'];
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final targetWidth = availableWidth > 420 ? availableWidth : 420.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: targetWidth,
            child: BouncyPillTabs(
              height: 38,
              labels: const [
                'Tất cả',
                'Đang thực hiện',
                'Sắp đạt',
                'Hoàn thành',
              ],
              selectedIndex: filters.indexOf(_goalFilter),
              colors: const [
                Color(0xFF005FEA), // Royal Blue for All
                Color(0xFF0284C7), // Sky Blue for Active
                Color(0xFFD97706), // Amber for Near
                Color(0xFF059669), // Emerald for Completed
              ],
              onChanged: (i) => setState(() => _goalFilter = filters[i]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoalCard({
    required Goal goal,
    required int index,
    required bool isDark,
  }) {
    final isCompleted = goal.status != 'active' ||
        (goal.targetAmount > 0 && goal.savedAmount >= goal.targetAmount);
    final progress = goal.targetAmount > 0
        ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final percent = (progress * 100).round();
    final remainingAmount =
        (goal.targetAmount - goal.savedAmount).clamp(0, 999999999999).toInt();

    // Days remaining
    final days = goal.targetDate == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(goal.targetDate!)
            .difference(DateTime.now())
            .inDays;

    final pastelColorsDark = [
      const Color(0xFF1E293B), // Slate
      const Color(0xFF451A03), // Amber
      const Color(0xFF022C22), // Emerald
      const Color(0xFF4C0519), // Rose
      const Color(0xFF082F49), // Sky
      const Color(0xFF042F2E), // Teal
    ];
    final pastelColorsLight = [
      const Color(0xFFF1F5F9), // Slate pastel
      const Color(0xFFFEF3C7), // Amber pastel
      const Color(0xFFDCFCE7), // Emerald pastel
      const Color(0xFFFCE7F3), // Rose pastel
      const Color(0xFFE0F2FE), // Sky pastel
      const Color(0xFFCCFBF1), // Teal pastel
    ];
    final accentColors = [
      const Color(0xFF2563EB), // Blue
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFFEC4899), // Rose
      const Color(0xFF0EA5E9), // Sky
      const Color(0xFF0D9488), // Teal
    ];

    final pastel = isDark
        ? pastelColorsDark[index % pastelColorsDark.length]
        : pastelColorsLight[index % pastelColorsLight.length];
    final accentColor = accentColors[index % accentColors.length];

    IconData resolveGoalIcon(String name, int idx) {
      final lower = name.toLowerCase();
      if (lower.contains('xe') ||
          lower.contains('ô tô') ||
          lower.contains('oto') ||
          lower.contains('honda')) {
        return Icons.directions_car_rounded;
      }
      if (lower.contains('nhà') ||
          lower.contains('đất') ||
          lower.contains('căn hộ') ||
          lower.contains('chung cư')) {
        return Icons.home_rounded;
      }
      if (lower.contains('du lịch') ||
          lower.contains('biển') ||
          lower.contains('nghỉ dưỡng') ||
          lower.contains('bay') ||
          lower.contains('vé')) {
        return Icons.flight_takeoff_rounded;
      }
      if (lower.contains('cưới') ||
          lower.contains('kết hôn') ||
          lower.contains('nhẫn') ||
          lower.contains('yêu')) {
        return Icons.favorite_rounded;
      }
      if (lower.contains('điện thoại') ||
          lower.contains('iphone') ||
          lower.contains('laptop') ||
          lower.contains('macbook') ||
          lower.contains('ipad')) {
        return Icons.phone_iphone_rounded;
      }
      if (lower.contains('học') ||
          lower.contains('du học') ||
          lower.contains('khóa học') ||
          lower.contains('sách')) {
        return Icons.school_rounded;
      }
      if (lower.contains('kinh doanh') ||
          lower.contains('đầu tư') ||
          lower.contains('chứng khoán') ||
          lower.contains('vàng')) {
        return Icons.trending_up_rounded;
      }
      if (lower.contains('mua') || lower.contains('sắm')) {
        return Icons.shopping_bag_rounded;
      }
      if (lower.contains('bảo hiểm') ||
          lower.contains('y tế') ||
          lower.contains('sức khỏe')) {
        return Icons.health_and_safety_rounded;
      }
      final defaultIcons = [
        Icons.savings_rounded,
        Icons.flag_rounded,
        Icons.stars_rounded,
        Icons.rocket_launch_rounded,
        Icons.account_balance_wallet_rounded,
      ];
      return defaultIcons[idx % defaultIcons.length];
    }

    final iconData = isCompleted
        ? Icons.check_circle_rounded
        : resolveGoalIcon(goal.name, index);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: isDark
              ? const Color(0xFF142033).withValues(alpha: 0.90)
              : Colors.white.withValues(alpha: 0.96),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: isDark ? 0.09 : 0.05),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dòng 1: Squircle Icon + Tiêu đề + Status Pill + Menu 3 chấm Apple
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: pastel,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isCompleted ? const Color(0xFF10B981) : accentColor)
                                .withValues(alpha: 0.20),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        iconData,
                        size: 22,
                        color: isCompleted ? const Color(0xFF10B981) : accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: (isCompleted ? const Color(0xFF10B981) : accentColor)
                                  .withValues(alpha: isDark ? 0.20 : 0.10),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: (isCompleted ? const Color(0xFF10B981) : accentColor)
                                    .withValues(alpha: 0.30),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              isCompleted
                                  ? '✓ Hoàn thành 100%'
                                  : '$percent% • ${days == null ? "Đang tích lũy" : (days <= 0 ? "Đã đến hạn" : "Còn $days ngày")}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isCompleted ? const Color(0xFF10B981) : accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Nút 3 chấm Apple Style (32x32 circle)
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: isDark ? 0.06 : 0.04),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.more_horiz_rounded,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (v) {
                        if (v == 'deposit') _openDeposit(goal);
                        if (v == 'edit') _openEdit(goal);
                        if (v == 'delete') _deleteGoal(goal);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'deposit',
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline_rounded,
                                  size: 16, color: Color(0xFF059669)),
                              SizedBox(width: 8),
                              Text('Góp tiền'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0070F3)),
                              SizedBox(width: 8),
                              Text('Chỉnh sửa'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  size: 16, color: Color(0xFFEF4444)),
                              SizedBox(width: 8),
                              Text('Xóa mục tiêu',
                                  style: TextStyle(color: Color(0xFFEF4444))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Đường hairline phân cách
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Divider(
                    height: 1,
                    thickness: 0.6,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                ),

                // Dòng 2: Số liệu ĐÃ TÍCH LŨY vs MỤC TIÊU — Tràn viền borderless chuẩn Zenvest
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ĐÃ TÍCH LŨY',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? const Color(0xFFA3B4D4)
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: FinoraPrivacyMask(
                              child: Text(
                                formatVND(goal.savedAmount),
                                style: TextStyle(
                                  color: isCompleted
                                      ? const Color(0xFF10B981)
                                      : accentColor,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'MỤC TIÊU',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? const Color(0xFFA3B4D4)
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: FinoraPrivacyMask(
                              child: Text(
                                formatVND(goal.targetAmount),
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFF1F5F9)
                                      : const Color(0xFF0F172A),
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Dòng 3: Vạch tiến độ gradient rực sáng chuẩn Zenvest
                Container(
                  height: 6.5,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: isDark ? 0.08 : 0.05),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth = constraints.maxWidth * progress;
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: barWidth,
                          height: 6.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isCompleted
                                  ? const [Color(0xFF34D399), Color(0xFF10B981)]
                                  : [accentColor.withValues(alpha: 0.85), accentColor],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: (isCompleted ? const Color(0xFF10B981) : accentColor)
                                    .withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Dòng 4: Chú thích tiến độ & Nút góp tiền nhanh
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isCompleted
                            ? '🎉 Đã hoàn thành mục tiêu!'
                            : 'Còn thiếu: ${formatVND(remainingAmount)}',
                        style: TextStyle(
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : (isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B)),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isCompleted)
                      InkWell(
                        onTap: () => _openDeposit(goal),
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: isDark ? 0.18 : 0.10),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.28),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_circle_outline_rounded, size: 13, color: accentColor),
                              const SizedBox(width: 4),
                              Text(
                                'Góp tiền',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Deposit Dialog — Quick, compact glass dialog
class _DepositDialog extends StatefulWidget {
  final String userId;
  final Goal goal;
  const _DepositDialog({required this.userId, required this.goal});

  @override
  State<_DepositDialog> createState() => _DepositDialogState();
}

class _DepositDialogState extends State<_DepositDialog> {
  final _amountController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final amount = int.tryParse(
            _amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;
    if (amount <= 0) return;

    setState(() => _isSaving = true);
    try {
      final updated = widget.goal.copyWith(
        savedAmount: widget.goal.savedAmount + amount,
      );
      await context.read<MoreProvider>().updateGoal(
            widget.userId,
            widget.goal.id,
            updated,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final diff = widget.goal.targetAmount - widget.goal.savedAmount;
    final remaining = diff < 0 ? 0 : diff;

    return GlassDialog(
      radius: 26,
      title: 'Ghi nhận tích lũy',
      subtitle: widget.goal.name,
      icon: Icons.savings_rounded,
      iconColor: const Color(0xFFD97706),
      onClose: () => Navigator.of(context).pop(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      actions: [
        Expanded(
          child: FinoraPillButton(
            label: 'Hủy',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FinoraPillButton(
            label: 'Xác nhận',
            primary: true,
            icon: Icons.check_rounded,
            onPressed: _isSaving ? null : _submit,
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Còn thiếu đến mục tiêu:',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  formatVND(remaining),
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Số tiền nạp thêm (VND)',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          GlassTextField(
            controller: _amountController,
            hint: '0 ₫',
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }
}

/// Full-screen form to create or edit a savings goal.
class AddGoalPage extends StatefulWidget {
  final String userId;
  final Goal? existing;
  const AddGoalPage({super.key, required this.userId, this.existing});

  @override
  State<AddGoalPage> createState() => _AddGoalPageState();
}

class _AddGoalPageState extends State<AddGoalPage> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _daysController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final goal = widget.existing;
    if (goal != null) {
      _nameController.text = goal.name;
      _targetController.text = '${goal.targetAmount}';
      if (goal.targetDate != null) {
        final days = DateTime.fromMillisecondsSinceEpoch(goal.targetDate!)
            .difference(DateTime.now())
            .inDays;
        if (days > 0) _daysController.text = '$days';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final name = _nameController.text.trim();
    final target = int.tryParse(
            _targetController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;
    if (name.isEmpty || target <= 0) return;

    setState(() => _isSaving = true);

    try {
      final daysStr = _daysController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final days = daysStr.isEmpty ? null : int.tryParse(daysStr);
      final now = DateTime.now().millisecondsSinceEpoch;
      final targetDate = days != null ? now + days * 24 * 60 * 60 * 1000 : null;
      final existing = widget.existing;
      final goal = Goal(
        id: existing?.id ?? '',
        userId: widget.userId,
        name: name,
        targetAmount: target,
        savedAmount: existing?.savedAmount ?? 0,
        targetDate: targetDate,
        status: existing?.status ?? 'active',
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
      if (existing == null) {
        await context.read<MoreProvider>().addGoal(widget.userId, goal);
      } else {
        await context
            .read<MoreProvider>()
            .updateGoal(widget.userId, existing.id, goal);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GlassScaffold(
      appBar: GlassTopBar(
        title: widget.existing == null
            ? 'Tạo mục tiêu tiết kiệm'
            : 'Chỉnh sửa mục tiêu',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  GlassScaffold.topInset(context, 8),
                  AppSpacing.md,
                  AppSpacing.lg),
              children: [
                Text(
                  'Tên mục tiêu',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                GlassTextField(
                  controller: _nameController,
                  hint: 'Ví dụ: Quỹ dự phòng, Mua xe, Du lịch...',
                ),
                const SizedBox(height: 16),
                Text(
                  'Số tiền mục tiêu (VND)',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                GlassTextField(
                  controller: _targetController,
                  hint: '0 ₫',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Text(
                  'Thời gian thực hiện (số ngày, tùy chọn)',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                GlassTextField(
                  controller: _daysController,
                  hint: 'Ví dụ: 30, 90, 365 ngày...',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
              child: PrimaryButton(
                expand: true,
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.existing == null
                            ? 'Tạo mục tiêu'
                            : 'Lưu thay đổi',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
