import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_radius.dart';
import '../design_system/app_shadows.dart';
import '../design_system/app_typography.dart';
import 'premium_widgets.dart';
export 'premium_widgets.dart'
    show
        GlassCard,
        GradientBackground,
        FloatingBubblesBackground,
        GradientButton,
        FinoraTextField,
        BankLogoView,
        BankIconAvatar,
        DotSeparatorTextInputFormatter;
export 'subject_filter_pill.dart';
export '../theme/app_theme.dart';

/// Page scaffold that paints the ambient pastel backdrop behind a transparent Scaffold.
class GlassScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const GlassScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
            ),
      child: GradientBackground(
        child: FloatingBubblesBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBody: true,
            appBar: appBar,
            body: Stack(
              children: [
                Positioned.fill(child: body),
                if (canPop)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 24,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragEnd: (details) {
                        if ((details.primaryVelocity ?? 0) > 300) {
                          Navigator.of(context).maybePop();
                        }
                      },
                      child: const SizedBox.expand(),
                    ),
                  ),
              ],
            ),
            bottomNavigationBar: bottomNavigationBar,
            floatingActionButton: floatingActionButton,
            floatingActionButtonLocation: floatingActionButtonLocation,
          ),
        ),
      ),
    );
  }
}

/// Editorial page header shared by all secondary screens and forms.
class GlassTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget? leading;
  const GlassTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions = const [],
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(58);

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null)
              leading!
            else if (onBack != null)
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF18223D)
                      : Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF202D4E)
                        : const Color(0xFFE8EEF8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF101828).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onBack!();
                  },
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: c.textPrimary,
                    size: 18,
                  ),
                ),
              )
            else
              const SizedBox(width: 8),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: AppTypography.title3.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

/// Frosted glass dialog for iOS-style premium dialogs.
class GlassDialog extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  const GlassDialog({
    super.key,
    required this.child,
    this.radius = 28.0,
    this.padding = const EdgeInsets.all(22.0),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark
        ? const Color(0xFF10172B).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.95);

    final borderColor =
        isDark ? const Color(0xFF202D4E) : const Color(0xFFE8EEF8);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: isDark
                  ? AppShadows.darkCardShadow
                  : AppShadows.floatingShadow,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Frosted glass bottom sheet with drag indicator and rounded top corners.
class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final double radius;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.radius = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF10172B) : Colors.white;

    final borderColor =
        isDark ? const Color(0xFF202D4E) : const Color(0xFFE8EEF8);

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(radius),
              topRight: Radius.circular(radius),
            ),
            border: Border(
              top: BorderSide(color: borderColor, width: 1.2),
              left: BorderSide(color: borderColor, width: 1.2),
              right: BorderSide(color: borderColor, width: 1.2),
            ),
            boxShadow:
                isDark ? AppShadows.darkCardShadow : AppShadows.floatingShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2E3D66)
                      : const Color(0xFFD4E1E4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Primary filled button with smooth gradient and glow.
class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final List<Color>? colors;
  final bool glow;
  final double height;
  final bool expand;
  final double radius;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.colors,
    this.glow = true,
    this.height = 54,
    this.expand = false,
    this.radius = 20,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final btnColors = colors ??
        (color != null
            ? [color!, color!.withValues(alpha: 0.85)]
            : [AppColors.primary, AppColors.primary]);

    return GradientButton(
      onPressed: onPressed,
      height: height,
      expand: expand,
      radius: radius,
      colors: btnColors,
      isLoading: isLoading,
      child: child,
    );
  }
}

/// iOS-style filled glass text field.
class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscure;
  final int maxLines;
  final Widget? suffix;
  final Widget? prefix;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.maxLines = 1,
    this.suffix,
    this.prefix,
    this.inputFormatters,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return FinoraTextField(
      controller: controller,
      hint: hint,
      obscure: obscure,
      keyboardType: keyboardType,
      prefix: prefix,
      suffix: suffix,
      radius: 20,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
    );
  }
}

/// iOS-style segmented control. [options] are (value, label) pairs.
class SegmentedControl extends StatelessWidget {
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const SegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedIndex = options
        .indexWhere((o) => o.$1 == selected)
        .clamp(0, options.length - 1);
    return LayoutBuilder(builder: (context, constraints) {
      const inset = 4.0;
      final itemWidth = (constraints.maxWidth - inset * 2) / options.length;
      return Container(
        height: 46,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xB8141F3C)
              : Colors.white.withValues(alpha: .62),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isDark ? const Color(0xFF202D4E) : Colors.white,
              width: 1.2),
        ),
        child: Stack(children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 340),
            curve: Curves.easeOutBack,
            left: inset + selectedIndex * itemWidth,
            top: inset,
            width: itemWidth,
            height: 38,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF5AA9FF)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: .24),
                      blurRadius: 14,
                      offset: const Offset(0, 5))
                ],
              ),
            ),
          ),
          Row(
              children: options.map((o) {
            final isSel = o.$1 == selected;
            return Expanded(
                child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(o.$1);
              },
              child: Center(
                  child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                    color: isSel ? Colors.white : c.textSecondary,
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13),
                child: Text(o.$2),
              )),
            ));
          }).toList()),
        ]),
      );
    });
  }
}

/// iOS-style pill filter chip.
class FilterChipX extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const FilterChipX({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF5B6FD4), Color(0xFF4CAEFE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected
              ? null
              : (isDark
                  ? const Color(0xFF141F3C)
                  : Colors.white.withValues(alpha: 0.85)),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark ? const Color(0xFF202D4E) : const Color(0xFFE8EEF8)),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF5B6FD4).withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFF101828).withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : c.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : c.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section title with optional trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            style: AppTypography.title3.copyWith(
              color: c.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionText != null && onAction != null)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onAction!();
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                actionText!,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Uppercase group label.
class Overline extends StatelessWidget {
  final String text;
  const Overline(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.caption1.copyWith(
        color: context.fc.textTertiary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

/// Rounded squircle tinted icon badge (icon or emoji).
class IconBadge extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final Color tint;
  final double size;
  final double radius;

  const IconBadge({
    super.key,
    this.icon,
    this.emoji,
    required this.tint,
    this.size = 44,
    this.radius = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: tint.withValues(alpha: 0.24)),
      ),
      alignment: Alignment.center,
      child: emoji != null
          ? Text(emoji!, style: TextStyle(fontSize: size * 0.45))
          : Icon(icon, color: tint, size: size * 0.46),
    );
  }
}

/// Centered premium empty-state.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.20),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: AppColors.primary, size: 38),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.title3.copyWith(
              color: c.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.subhead.copyWith(
              color: c.textSecondary,
              height: 1.4,
            ),
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 24),
            PrimaryButton(
              onPressed: onAction,
              height: 48,
              child: Text(
                actionText!,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Polished error state widget with retry action.
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Không thể tải dữ liệu',
              style: AppTypography.title3.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.subhead.copyWith(color: c.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              PrimaryButton(
                onPressed: onRetry,
                height: 46,
                color: AppColors.primary,
                child: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<bool> showConfirmDeleteDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmLabel = 'Xóa',
  bool isDanger = true,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primaryTextColor =
      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  final secondaryTextColor =
      isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  final actionColor = isDanger ? AppColors.error : AppColors.primary;

  final result = await showDialog<bool>(
    context: context,
    builder: (_) => GlassDialog(
      radius: 28,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDanger
                      ? Icons.delete_outline_rounded
                      : Icons.refresh_rounded,
                  color: actionColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Hủy',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: actionColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  confirmLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

class GlassCalendarPicker extends StatefulWidget {
  final DateTime initialDate;
  const GlassCalendarPicker({super.key, required this.initialDate});

  @override
  State<GlassCalendarPicker> createState() => _GlassCalendarPickerState();
}

class _GlassCalendarPickerState extends State<GlassCalendarPicker> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth =
        DateTime(widget.initialDate.year, widget.initialDate.month, 1);
    _selectedDate = DateTime(widget.initialDate.year, widget.initialDate.month,
        widget.initialDate.day);
  }

  int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _firstWeekdayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday;
  }

  void _prevMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _selectPreset(DateTime date) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
      _currentMonth = DateTime(date.year, date.month, 1);
    });
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Thứ Hai';
      case 2:
        return 'Thứ Ba';
      case 3:
        return 'Thứ Tư';
      case 4:
        return 'Thứ Năm';
      case 5:
        return 'Thứ Sáu';
      case 6:
        return 'Thứ Bảy';
      case 7:
      default:
        return 'Chủ Nhật';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    final isSelectedToday = _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;
    final isSelectedYesterday = _selectedDate.year == yesterday.year &&
        _selectedDate.month == yesterday.month &&
        _selectedDate.day == yesterday.day;

    final monthStr = 'Tháng ${_currentMonth.month}, ${_currentMonth.year}';
    final weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    final totalDays = _daysInMonth(_currentMonth);
    final firstDayWeekday = _firstWeekdayOfMonth(_currentMonth);
    final emptyPrefixCells = firstDayWeekday - 1;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10172B) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.45 : 0.15),
            blurRadius: 36,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag pill
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFD4E1E4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Selected Date Highlight Banner
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
                        : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _selectedDate.day.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_weekdayName(_selectedDate.weekday)}, ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E1B4B),
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isSelectedToday
                                ? 'Hôm nay'
                                : (isSelectedYesterday
                                    ? 'Hôm qua'
                                    : '${_selectedDate.difference(today).inDays.abs()} ngày ${_selectedDate.isBefore(today) ? "trước" : "tới"}'),
                            style: TextStyle(
                              color: const Color(0xFF6366F1),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Quick Preset Chips (Hôm nay / Hôm qua / Đầu tháng)
              Row(
                children: [
                  _buildPresetChip(
                    label: 'Hôm nay',
                    selected: isSelectedToday,
                    onTap: () => _selectPreset(today),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildPresetChip(
                    label: 'Hôm qua',
                    selected: isSelectedYesterday,
                    onTap: () => _selectPreset(yesterday),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildPresetChip(
                    label: 'Đầu tháng',
                    selected: _selectedDate.day == 1 &&
                        _selectedDate.month == now.month &&
                        _selectedDate.year == now.year,
                    onTap: () => _selectPreset(firstDayOfMonth),
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Month Navigator Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF16213D)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _prevMonth,
                      icon: Icon(
                        Icons.chevron_left_rounded,
                        color: primaryTextColor,
                        size: 26,
                      ),
                      splashRadius: 20,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 16,
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          monthStr,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _nextMonth,
                      icon: Icon(
                        Icons.chevron_right_rounded,
                        color: primaryTextColor,
                        size: 26,
                      ),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Weekdays Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: weekdays.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final day = entry.value;
                  final isSunday = idx == 6;
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          color: isSunday
                              ? const Color(0xFFEF4444)
                              : secondaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              // Days Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: emptyPrefixCells + totalDays,
                itemBuilder: (context, index) {
                  if (index < emptyPrefixCells) {
                    return const SizedBox.shrink();
                  }
                  final dayNumber = index - emptyPrefixCells + 1;
                  final date = DateTime(
                      _currentMonth.year, _currentMonth.month, dayNumber);
                  final isSelected = _selectedDate.year == date.year &&
                      _selectedDate.month == date.month &&
                      _selectedDate.day == date.day;
                  final isToday = date.year == today.year &&
                      date.month == today.month &&
                      date.day == today.day;
                  final isSunday = date.weekday == 7;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected
                            ? null
                            : (isToday
                                ? (isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFEEF2FF))
                                : Colors.transparent),
                        border: isToday && !isSelected
                            ? Border.all(
                                color: const Color(0xFF6366F1),
                                width: 1.5,
                              )
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color:
                                      const Color(0xFF4F46E5).withOpacity(0.40),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayNumber.toString(),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isSunday
                                      ? const Color(0xFFEF4444)
                                      : (isToday
                                          ? const Color(0xFF6366F1)
                                          : primaryTextColor)),
                              fontSize: 14,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                            ),
                          ),
                          if (isToday && !isSelected)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF223157)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Text(
                        'Hủy',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(_selectedDate),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Xác nhận ngày',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF4F46E5)
                : (isDark ? const Color(0xFF16213D) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF6366F1)
                  : (isDark
                      ? const Color(0xFF223157)
                      : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
