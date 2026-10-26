import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'premium_widgets.dart';
export 'premium_widgets.dart' show GlassCard;

/// Frosted-glass card with a faint top sheen + bright hairline edge.

/// Page scaffold that paints the glass backdrop behind a transparent Scaffold.
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
    return Scaffold(
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation);
  }
}

/// Compact, left-aligned top bar that blends with the backdrop.
class GlassTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget> actions;
  const GlassTopBar(
      {super.key, required this.title, this.onBack, this.actions = const []});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            if (onBack != null)
              IconButton(
                onPressed: onBack,
                icon: Icon(Icons.arrow_back, color: c.textPrimary),
              )
            else
              const SizedBox(width: 16),
            Expanded(
              child: Text(title,
                  style: AppText.pageTitle.copyWith(color: c.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            ...actions,
            const SizedBox(width: 8),
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
    this.padding = const EdgeInsets.all(20.0),
  });

  @override
  Widget build(BuildContext context) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
          child: Padding(padding: padding, child: child)));
}

/// Frosted glass bottom sheet with drag indicator and rounded top corners.
class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final double radius;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.radius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Material(
          color: (dark ? const Color(0xFF111827) : Colors.white)
              .withValues(alpha: dark ? 0.82 : 0.84),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: dark ? 0.12 : 0.82),
                ),
              ),
            ),
            child: SafeArea(top: false, child: child),
          ),
        ),
      ),
    );
  }
}

/// Primary filled button with a soft coloured glow.
class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final bool glow;
  final double height;
  final bool expand;
  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = Brand.primaryBlue,
    this.glow = true,
    this.height = 52,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    return GradientButton(
      onPressed: onPressed,
      height: height,
      expand: expand,
      radius: 999,
      colors: [color, color.withOpacity(0.85)],
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
  final List<TextInputFormatter>? inputFormatters;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.maxLines = 1,
    this.suffix,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return FinoraTextField(
      controller: controller,
      hint: hint,
      obscure: obscure,
      keyboardType: keyboardType,
      suffix: suffix,
      radius: 22,
      inputFormatters: inputFormatters,
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
  Widget build(BuildContext context) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map((o) => ChoiceChip(
              label: Text(o.$2),
              selected: o.$1 == selected,
              onSelected: (_) => onChanged(o.$1),
              materialTapTargetSize: MaterialTapTargetSize.padded))
          .toList());
}

/// iOS-style pill filter chip.
class FilterChipX extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const FilterChipX(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? Brand.primaryBlue.withOpacity(0.14)
              : c.surfaceElevated,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected
                ? Brand.primaryBlue.withOpacity(0.5)
                : Colors.transparent,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? Brand.primaryBlue : c.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            )),
      ),
    );
  }
}

/// Section title with optional trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  const SectionHeader(
      {super.key, required this.title, this.actionText, this.onAction});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(title,
              style: AppText.sectionTitle.copyWith(color: c.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        if (actionText != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(actionText!,
                  style: const TextStyle(
                      color: Brand.primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
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
    return Text(text.toUpperCase(),
        style: AppText.overline.copyWith(color: context.fc.textTertiary));
  }
}

/// Rounded tinted icon badge (icon or emoji).
class IconBadge extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final Color tint;
  final double size;
  const IconBadge(
      {super.key, this.icon, this.emoji, required this.tint, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withOpacity(0.16),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: tint.withOpacity(0.22)),
      ),
      alignment: Alignment.center,
      child: emoji != null
          ? Text(emoji!, style: TextStyle(fontSize: size * 0.44))
          : Icon(icon, color: tint, size: size * 0.46),
    );
  }
}

/// Centred premium empty-state.
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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Brand.primaryBlue.withOpacity(0.14),
              border: Border.all(color: Brand.primaryBlue.withOpacity(0.28)),
            ),
            child: Icon(icon, color: Brand.accentBlue, size: 36),
          ),
          const SizedBox(height: 18),
          Text(title,
              textAlign: TextAlign.center,
              style: AppText.sectionTitle.copyWith(color: c.textPrimary)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(color: c.textSecondary)),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 22),
            PrimaryButton(
              onPressed: onAction,
              child: Text(actionText!,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
}

Future<bool> showConfirmDeleteDialog({
  required BuildContext context,
  required String title,
  required String content,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primaryTextColor =
      isDark ? const Color(0xFFF2F2F7) : const Color(0xFF0F172A);
  final secondaryTextColor =
      isDark ? const Color(0xFFAEAEB2) : const Color(0xFF475569);

  final result = await showDialog<bool>(
    context: context,
    builder: (_) => GlassDialog(
      radius: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(content,
              style: TextStyle(color: secondaryTextColor, fontSize: 14)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Hủy',
                    style: TextStyle(
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Xóa',
                    style: TextStyle(
                        color: Color(0xFFFF3B30), fontWeight: FontWeight.bold)),
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
  DateTime? _selectedDate;

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
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryColor = isDark ? Colors.white60 : Colors.black54;

    final monthStr = 'Tháng ${_currentMonth.month}, ${_currentMonth.year}';
    final weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    final totalDays = _daysInMonth(_currentMonth);
    final firstDayWeekday = _firstWeekdayOfMonth(_currentMonth);
    final emptyPrefixCells = firstDayWeekday - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: Icon(Icons.chevron_left, color: primaryColor),
              ),
              Text(
                monthStr,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: Icon(Icons.chevron_right, color: primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
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
              final date =
                  DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
              final isSelected = _selectedDate != null &&
                  _selectedDate!.year == date.year &&
                  _selectedDate!.month == date.month &&
                  _selectedDate!.day == date.day;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFF1877F2)
                        : Colors.transparent,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    dayNumber.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : primaryColor,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Hủy',
                    style: TextStyle(
                      color: secondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  onPressed: () => Navigator.of(context).pop(_selectedDate),
                  child: const Text(
                    'Chọn',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
