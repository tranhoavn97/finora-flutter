import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_spacing.dart';
import '../../data/models/finance_models.dart';
import '../../state/more_provider.dart';

/// Redesigned Savings Goals Page:
/// - Matching Finora's luxury Obsidian & Royal Indigo design language
/// - Compact Overview Card (total accumulated vs total target, sleek progress)
/// - Horizontal filter pills (All, In Progress, Near Target, Completed)
/// - Compact goal items with pastel category badges, dual progress stats, and quick deposit action
class GoalScreen extends StatefulWidget {
  final String userId;
  const GoalScreen({super.key, required this.userId});

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

    final money = NumberFormat('#,##0', 'vi_VN');
    final priorityGoal = activeGoals.isNotEmpty ? activeGoals.first : null;
    final prioritySaved = priorityGoal?.savedAmount ?? 0;
    final priorityTarget = priorityGoal != null && priorityGoal.targetAmount > 0
        ? priorityGoal.targetAmount
        : 0;
    final priorityProgress = priorityTarget > 0
        ? (prioritySaved / priorityTarget).clamp(0.0, 1.0)
        : 0.0;
    final remainingTarget = (priorityTarget - prioritySaved).clamp(0, double.maxFinite.toInt());

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF14273A) : const Color(0xFFF1F6FA),
      body: AmbientFloatingBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              // 1. Header: head('Dành cho tương lai', 'Mỗi khoản nhỏ, một bước gần hơn', btn('plus', 'notice'))
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dành cho tương lai',
                          style: TextStyle(
                            color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mỗi khoản nhỏ, một bước gần hơn',
                          style: TextStyle(
                            color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (Navigator.of(context).canPop())
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 38,
                            height: 38,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1D354B) : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF2C4861) : const Color(0xFFDCE5EF),
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              size: 19,
                              color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: _openAdd,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1D354B) : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF2C4861) : const Color(0xFFDCE5EF),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF224E74).withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            LucideIcons.plus,
                            size: 19,
                            color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. Journey Card: .journey with landscape illustration
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF183036) : const Color(0xFFE4EFEA),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                    color: isDark ? const Color(0xFF28464E) : Colors.white,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF437B6B).withValues(alpha: 0.08),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Landscape SVG Artwork
                      SizedBox(
                        height: 160,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _LandscapePainter(),
                        ),
                      ),
                      // Caption
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MỤC TIÊU ƯU TIÊN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                                color: Color(0xFF527578),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              priorityGoal != null ? priorityGoal.name : 'Chưa có mục tiêu nào',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF203E42),
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${money.format(prioritySaved)} ₫',
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF203E42),
                                  ),
                                ),
                                Text(
                                  '/ ${money.format(priorityTarget)} ₫',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF6B8A8D),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Progress bar (.bar)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                height: 8,
                                color: isDark ? const Color(0xFF24444A) : const Color(0xFFCCE0DD),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: priorityProgress,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4A8588),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${(priorityProgress * 100).round()}% hành trình',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF6B8A8D),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Tháng 12, 2026',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF6B8A8D),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 3. Primary Button: Góp thêm 500.000 ₫
              GestureDetector(
                onTap: () {
                  if (priorityGoal != null) {
                    _openDeposit(priorityGoal);
                  } else {
                    _openAdd();
                  }
                },
                child: Container(
                  height: 49,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2885FF), Color(0xFF0864E9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF126BEA).withValues(alpha: 0.20),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Góp thêm 500.000 ₫',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 4. Milestones Timeline (.timeline)
              Container(
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.only(left: 22),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Color(0xFFDCE7F0),
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    _buildGoalTimelineEvent(
                      title: 'Khởi hành ước mơ',
                      detail: 'Tháng 6 · Đã bắt đầu tích lũy',
                      dotColor: const Color(0xFF4A8588),
                      isDark: isDark,
                    ),
                    _buildGoalTimelineEvent(
                      title: 'Đã đi được hơn nửa đường',
                      detail: 'Tháng 9 · Bạn đang giữ nhịp rất tốt',
                      dotColor: const Color(0xFF005FEA),
                      isDark: isDark,
                    ),
                    _buildGoalTimelineEvent(
                      title: 'Còn ${money.format(remainingTarget)} ₫ để chạm đích',
                      detail: 'Gợi ý: dành ${(remainingTarget / 3).round() > 0 ? money.format((remainingTarget / 3).round()) : "2.700.000"} ₫ mỗi tháng',
                      dotColor: const Color(0xFFB0C4D6),
                      isDark: isDark,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Section: Danh sách mục tiêu + Tabs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Danh sách mục tiêu (${displayGoals.length})',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                    ),
                  ),
                  GestureDetector(
                    onTap: _openAdd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C3146) : const Color(0xFFE8F1FC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.plus, size: 14, color: Color(0xFF005FEA)),
                          SizedBox(width: 4),
                          Text(
                            'Thêm',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF005FEA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildFilterPillsRow(isDark: isDark),
              const SizedBox(height: 16),
              if (displayGoals.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.target,
                          size: 44,
                          color: isDark ? const Color(0xFF3B5670) : const Color(0xFFB6C7D8),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Chưa có mục tiêu nào phù hợp',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF7D9DBE) : const Color(0xFF6B8299),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...displayGoals.asMap().entries.map(
                      (e) => _buildGoalCard(
                        goal: e.value,
                        index: e.key,
                        isDark: isDark,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalTimelineEvent({
    required String title,
    required String detail,
    required Color dotColor,
    required bool isDark,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -28,
            top: 2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF14273A) : const Color(0xFFF1F6FA),
                  width: 2,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                ),
              ),
            ],
          ),
        ],
      ),
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
          lower.contains('honda')) return Icons.directions_car_rounded;
      if (lower.contains('nhà') ||
          lower.contains('đất') ||
          lower.contains('căn hộ') ||
          lower.contains('chung cư')) return Icons.home_rounded;
      if (lower.contains('du lịch') ||
          lower.contains('biển') ||
          lower.contains('nghỉ dưỡng') ||
          lower.contains('bay') ||
          lower.contains('vé')) return Icons.flight_takeoff_rounded;
      if (lower.contains('cưới') ||
          lower.contains('kết hôn') ||
          lower.contains('nhẫn') ||
          lower.contains('yêu')) return Icons.favorite_rounded;
      if (lower.contains('điện thoại') ||
          lower.contains('iphone') ||
          lower.contains('laptop') ||
          lower.contains('macbook') ||
          lower.contains('ipad')) return Icons.phone_iphone_rounded;
      if (lower.contains('học') ||
          lower.contains('du học') ||
          lower.contains('khóa học') ||
          lower.contains('sách')) return Icons.school_rounded;
      if (lower.contains('kinh doanh') ||
          lower.contains('đầu tư') ||
          lower.contains('chứng khoán') ||
          lower.contains('vàng')) return Icons.trending_up_rounded;
      if (lower.contains('mua') || lower.contains('sắm'))
        return Icons.shopping_bag_rounded;
      if (lower.contains('bảo hiểm') ||
          lower.contains('y tế') ||
          lower.contains('sức khỏe')) return Icons.health_and_safety_rounded;
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF161B26).withValues(alpha: 0.75)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF1E293B).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Icon, Title (max 2 lines), percent & popup menu
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
                      color:
                          (isCompleted ? const Color(0xFF10B981) : accentColor)
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            days == null
                                ? 'Vô thời hạn'
                                : (days <= 0
                                    ? '⏱ Đã đến hạn'
                                    : '⏱ Còn $days ngày'),
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFF10B981).withOpacity(0.15)
                                : accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isCompleted ? '✓ Hoàn thành' : '🎯 Đang tích lũy',
                            style: TextStyle(
                              color: isCompleted
                                  ? const Color(0xFF10B981)
                                  : accentColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$percent%',
                    style: TextStyle(
                      color: isCompleted
                          ? const Color(0xFF10B981)
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert_rounded,
                        size: 18, color: Color(0xFF94A3B8)),
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
                            Icon(Icons.edit_outlined, size: 16),
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
                                size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa mục tiêu',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Stats Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withOpacity(0.6)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155).withOpacity(0.5)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đã tích lũy',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatVND(goal.savedAmount),
                          style: TextStyle(
                            color: isCompleted
                                ? const Color(0xFF10B981)
                                : accentColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Mục tiêu',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatVND(goal.targetAmount),
                          style: TextStyle(
                            color:
                                isDark ? Colors.white : const Color(0xFF1E293B),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? const Color(0xFF10B981) : accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isCompleted
                          ? '🎉 Đã hoàn thành 100% mục tiêu!'
                          : 'Còn thiếu: ${formatVND(remainingAmount)}',
                      style: TextStyle(
                        color: isCompleted
                            ? const Color(0xFF10B981)
                            : (isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B)),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        color:
                            isCompleted ? const Color(0xFF10B981) : accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Row 3: Action Buttons
          Row(
            children: [
              if (!isCompleted)
                Expanded(
                  child: InkWell(
                    onTap: () => _openDeposit(goal),
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: accentColor.withValues(alpha: 0.35),
                            width: 0.8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline_rounded,
                              size: 15, color: accentColor),
                          const SizedBox(width: 6),
                          Text(
                            'Góp tiền',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_rounded,
                            size: 15, color: Color(0xFF10B981)),
                        SizedBox(width: 6),
                        Text(
                          'Mục tiêu hoàn thành',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _openEdit(goal),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _deleteGoal(goal),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ],
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  color: Color(0xFF4F46E5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Ghi nhận tích lũy',
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.goal.name,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Còn thiếu: ${formatVND(remaining)}',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Hủy',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  expand: true,
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Xác nhận',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
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
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
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

class _LandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Sky background
    final skyPaint = Paint()..color = const Color(0xFFE4EFEA);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    final scaleX = size.width / 330.0;
    final scaleY = size.height / 174.0;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // Sun (#F5D999)
    final sunPaint = Paint()..color = const Color(0xFFF5D999);
    canvas.drawCircle(const Offset(255, 42), 25, sunPaint);

    // Mountain Layer 1 (#A5BEC0)
    final m1 = Path()
      ..moveTo(0, 130)
      ..lineTo(78, 32)
      ..lineTo(178, 158)
      ..lineTo(243, 71)
      ..lineTo(330, 146)
      ..lineTo(330, 174)
      ..lineTo(0, 174)
      ..close();
    canvas.drawPath(m1, Paint()..color = const Color(0xFFA5BEC0));

    // Snow caps (#F8FAF5)
    final snow = Path()
      ..moveTo(41, 78)
      ..lineTo(78, 32)
      ..lineTo(116, 80)
      ..lineTo(86, 68)
      ..lineTo(71, 75)
      ..lineTo(62, 64)
      ..close();
    canvas.drawPath(snow, Paint()..color = const Color(0xFFF8FAF5));

    // Mountain Layer 2 (#6C9694)
    final m2 = Path()
      ..moveTo(0, 154)
      ..lineTo(105, 109)
      ..lineTo(215, 169)
      ..lineTo(330, 103)
      ..lineTo(330, 174)
      ..lineTo(0, 174)
      ..close();
    canvas.drawPath(m2, Paint()..color = const Color(0xFF6C9694));

    // Mountain Layer 3 (#355D66)
    final m3 = Path()
      ..moveTo(0, 173)
      ..lineTo(90, 149)
      ..lineTo(167, 174)
      ..close();
    canvas.drawPath(m3, Paint()..color = const Color(0xFF355D66));

    // Foreground trail stroke (#EDF2D9)
    final trail = Path()
      ..moveTo(190, 174)
      ..lineTo(239, 142)
      ..lineTo(228, 130)
      ..lineTo(251, 119);
    canvas.drawPath(
      trail,
      Paint()
        ..color = const Color(0xFFEDF2D9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
