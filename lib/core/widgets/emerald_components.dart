import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../theme/emerald_tokens.dart';
import 'finora/financial_components.dart';

/// Top Appbar chuẩn Emerald (height: 58px, title: 17px w600, padding: 0 22px)
class EmeraldAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final String? actionTooltip;
  final bool dark;

  const EmeraldAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actionIcon,
    this.onAction,
    this.actionTooltip,
    this.dark = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(EmeraldTokens.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : EmeraldTokens.ink;
    return Container(
      height: EmeraldTokens.appBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: EmeraldTokens.pagePadding),
      color: dark ? Colors.transparent : EmeraldTokens.ivoryBg,
      child: Row(
        children: [
          if (onBack != null)
            GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 32,
                height: 36,
                alignment: Alignment.centerLeft,
                child: Icon(LucideIcons.arrow_left, size: 20, color: fg),
              ),
            ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.45,
                color: fg,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actionIcon != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.centerRight,
                child: Icon(actionIcon, size: 20, color: fg),
              ),
            ),
        ],
      ),
    );
  }
}

/// Thẻ số dư chính chuẩn Emerald (120deg gradient #007B60 -> #00503F, bo góc 17px, quầng sáng)
class EmeraldBalanceCard extends StatelessWidget {
  final String title;
  final int amountValue;
  final String amount;
  final bool isAmountVisible;
  final VoidCallback onToggleMask;
  final VoidCallback onAddTransaction;

  const EmeraldBalanceCard({
    super.key,
    this.title = 'Tổng số dư hiện tại',
    this.amountValue = 0,
    required this.amount,
    required this.isAmountVisible,
    required this.onToggleMask,
    required this.onAddTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 21),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(EmeraldTokens.balanceCardRadius),
        gradient: EmeraldTokens.balanceCardGrad,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -100,
            bottom: -60,
            child: Container(
              width: 250,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: const Color(0x1A40CC8B),
              ),
            ),
          ),
          Positioned(
            left: 120,
            bottom: -50,
            child: Container(
              width: 200,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: const Color(0x12B0FFCB),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFC6E8DC),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: MoneyText(
                        amountValue,
                        hidden: !isAmountVisible,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: onToggleMask,
                      child: Icon(
                        isAmountVisible ? LucideIcons.eye : LucideIcons.eye_off,
                        size: 16,
                        color: const Color(0xFFD7EDE5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                EmeraldWhitePill(
                  label: 'Ghi một giao dịch',
                  icon: LucideIcons.plus,
                  onTap: onAddTransaction,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút viên thuốc trắng nổi trên thẻ số dư
class EmeraldWhitePill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const EmeraldWhitePill({
    super.key,
    required this.label,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF4FFF9),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: const Color(0xFF005B43)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF005B43),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hàng 4 tác vụ nhanh (Chuyển ví, Thu nhập, Quét QR, Tiện ích)
class EmeraldQuickActions extends StatelessWidget {
  final List<EmeraldQuickActionItem> items;

  const EmeraldQuickActions({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 23),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items.map((it) {
          return Expanded(
            child: GestureDetector(
              onTap: it.onTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 47,
                    height: 43,
                    decoration: BoxDecoration(
                      color: it.bubbleBg ?? EmeraldTokens.mintSoft,
                      border: Border.all(color: const Color(0xFFE5EEE8), width: 1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(it.icon, size: 20, color: it.iconColor ?? const Color(0xFF008364)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    it.label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF243A34),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class EmeraldQuickActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? bubbleBg;
  final Color? iconColor;

  const EmeraldQuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.bubbleBg,
    this.iconColor,
  });
}

/// Thanh Tabs chuẩn Emerald (nền #F0F6F2, ô chọn #006B50, bo góc 23px)
class EmeraldTabs extends StatelessWidget {
  final List<String> labels;
  final int activeIndex;
  final ValueChanged<int> onTabSelected;
  final bool isNaked;
  final List<Color>? colors;

  const EmeraldTabs({
    super.key,
    required this.labels,
    required this.activeIndex,
    required this.onTabSelected,
    this.isNaked = false,
    this.colors,
  });

  Color _resolveTabColor(int idx, String label) {
    if (colors != null && idx < colors!.length) return colors![idx];
    final l = label.trim().toLowerCase();
    if (l.contains('chi ti') || l == 'chi') return const Color(0xFFE11D48);
    if (l.contains('thu nh') || l == 'thu') return const Color(0xFF059669);
    if (l.contains('chuy') || l.contains('transfer')) return const Color(0xFF0284C7);
    if (l.contains('thẻ') || l.contains('the')) return const Color(0xFFD97706);
    if (l.contains('đầu tư') || l.contains('dau tu')) return const Color(0xFF0D9488);
    return EmeraldTokens.emeraldActive;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 18),
      padding: isNaked ? EdgeInsets.zero : const EdgeInsets.all(4),
      decoration: isNaked
          ? null
          : BoxDecoration(
              color: EmeraldTokens.mintTabBg,
              borderRadius: BorderRadius.circular(EmeraldTokens.tabRadius),
            ),
      child: Row(
        children: List.generate(labels.length, (idx) {
          final isSelected = idx == activeIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(idx),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? _resolveTabColor(idx, labels[idx])
                      : (isNaked ? const Color(0xFFF1F7F3) : Colors.transparent),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected ? EmeraldTokens.activeTabShadow : null,
                ),
                child: Text(
                  labels[idx],
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF7D8F84),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Dòng giao dịch chuẩn Emerald (Icon tròn 35px, Tiêu đề 12px, Meta 10px, Số tiền 12px)
class EmeraldTransactionRow extends StatelessWidget {
  final String title;
  final String meta;
  final String? amount;
  final String? date;
  final IconData icon;
  final Color? iconBg;
  final Color? iconColor;
  final VoidCallback onTap;

  const EmeraldTransactionRow({
    super.key,
    required this.title,
    required this.meta,
    this.amount,
    this.date,
    required this.icon,
    this.iconBg,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPos = amount != null && amount!.startsWith('+');
    final isNeg = amount != null && amount!.startsWith('−');

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: EmeraldTokens.borderDivider, width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: iconBg ?? const Color(0xFFE6F3EB),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 17, color: iconColor ?? const Color(0xFF008463)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: EmeraldTokens.ink,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: EmeraldTokens.meta,
                      height: 1.35,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (amount != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isPos
                          ? EmeraldTokens.positive
                          : (isNeg ? EmeraldTokens.negative : EmeraldTokens.ink),
                      letterSpacing: -0.25,
                    ),
                  ),
                  if (date != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      date!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        color: EmeraldTokens.meta,
                      ),
                    ),
                  ],
                ],
              )
            else
              const Icon(LucideIcons.chevron_right, size: 14, color: Color(0xFFA8B5AE)),
          ],
        ),
      ),
    );
  }
}

/// Nút chính bo tròn chuẩn Emerald (cao 46px, bo góc 14px, gradient #00896B -> #00785E)
class EmeraldButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isSecondary;
  final bool isDanger;
  final bool isOutline;
  final bool isWhite;
  final bool isFullWidth;

  const EmeraldButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.isSecondary = false,
    this.isDanger = false,
    this.isOutline = false,
    this.isWhite = false,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    Color? bg;
    LinearGradient? grad;
    Color fg = Colors.white;
    Border? border;

    if (isSecondary) {
      bg = const Color(0xFFEEF6F1);
      fg = const Color(0xFF006B51);
    } else if (isDanger) {
      bg = const Color(0xFFFFF0EE);
      fg = const Color(0xFFCC5B55);
    } else if (isOutline) {
      bg = Colors.transparent;
      fg = const Color(0xFF00745B);
      border = Border.all(color: const Color(0xFFDEEBE3), width: 1);
    } else if (isWhite) {
      bg = const Color(0xFFF7FFFB);
      fg = const Color(0xFF005A43);
    } else {
      grad = EmeraldTokens.buttonGrad;
    }

    final content = Container(
      height: EmeraldTokens.buttonHeight,
      decoration: BoxDecoration(
        color: bg,
        gradient: grad,
        borderRadius: BorderRadius.circular(EmeraldTokens.buttonRadius),
        border: border,
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 17, color: fg),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: isFullWidth ? content : IntrinsicWidth(child: content),
    );
  }
}

/// Thẻ Panel trắng bo góc 15px chuẩn Emerald
class EmeraldPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool isSoft;
  final bool noBorder;

  const EmeraldPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(15),
    this.isSoft = false,
    this.noBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: padding,
      decoration: BoxDecoration(
        color: isSoft ? EmeraldTokens.mintSoft : EmeraldTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(EmeraldTokens.cardRadius),
        border: (noBorder || isSoft)
            ? null
            : Border.all(color: EmeraldTokens.border, width: 1),
      ),
      child: child,
    );
  }
}

/// Tiêu đề phân hệ chuẩn Emerald (13px w700, kèm link xem tất cả)
class EmeraldSectionTitle extends StatelessWidget {
  final String title;
  final String? linkText;
  final VoidCallback? onLinkTap;

  const EmeraldSectionTitle({
    super.key,
    required this.title,
    this.linkText,
    this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 21, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: EmeraldTokens.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (linkText != null && onLinkTap != null)
            GestureDetector(
              onTap: onLinkTap,
              child: Text(
                linkText!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF008164),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Thanh điều hướng Dock chuẩn Emerald (cao 62px, 5 nút, nút dấu + 29x29 bo góc 10)
class EmeraldDock extends StatelessWidget {
  final int activeIndex; // 0: Home, 1: Ledger, 2: Add, 3: Planning, 4: Profile
  final ValueChanged<int> onTap;
  final VoidCallback onAddTap;

  const EmeraldDock({
    super.key,
    required this.activeIndex,
    required this.onTap,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: EmeraldTokens.dockHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: EmeraldTokens.dockBorder, width: 1)),
      ),
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        children: [
          _buildItem(0, LucideIcons.house, 'Trang chủ'),
          _buildItem(1, LucideIcons.receipt_text, 'Giao dịch'),
          Expanded(
            child: GestureDetector(
              onTap: onAddTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -4),
                    child: Container(
                      width: 29,
                      height: 29,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007B5D),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(LucideIcons.plus, size: 17, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ghi chép',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFA0AEA7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildItem(3, LucideIcons.layout_grid, 'Kế hoạch'),
          _buildItem(4, LucideIcons.user, 'Cá nhân'),
        ],
      ),
    );
  }

  Widget _buildItem(int index, IconData icon, String label) {
    final isActive = activeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 19,
              color: isActive ? const Color(0xFF007859) : const Color(0xFFA0AEA7),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 8,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFF007859) : const Color(0xFFA0AEA7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thẻ Tag pill chuẩn Emerald (Coral, Mint, Gold, Blue)
class EmeraldTag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String tone; // 'mint' | 'coral' | 'gold' | 'blue'
  final VoidCallback? onTap;

  const EmeraldTag({
    super.key,
    required this.label,
    this.icon,
    this.tone = 'mint',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (tone) {
      case 'coral':
        bg = const Color(0xFFFBECE8);
        fg = const Color(0xFFC95F57);
        break;
      case 'gold':
        bg = const Color(0xFFFCF4E4);
        fg = const Color(0xFFB57D28);
        break;
      case 'blue':
        bg = const Color(0xFFE8F2FA);
        fg = const Color(0xFF2C749A);
        break;
      case 'mint':
      default:
        bg = const Color(0xFFE4F5EB);
        fg = const Color(0xFF007557);
        break;
    }

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}

/// Hàng Key-Value biên nhận chuẩn Emerald
class EmeraldKeyValue extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const EmeraldKeyValue({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Color(0xFF768780),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? EmeraldTokens.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Khung nhập số tiền lớn chuẩn Emerald (cao 69px, 28px text, ₫ suffix)
class EmeraldMoneyField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;

  const EmeraldMoneyField({
    super.key,
    required this.controller,
    this.label = 'Số tiền',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF586B63),
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          height: 69,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EmeraldTokens.border, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  onChanged: onChanged,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    color: EmeraldTokens.ink,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC0CEC7),
                    ),
                  ),
                ),
              ),
              const Text(
                '₫',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF768780),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Khung nhập liệu văn bản chuẩn Emerald (cao 46px, bo góc 14px)
class EmeraldField extends StatelessWidget {
  final String? label;
  final String placeholder;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final IconData? leadingIcon;
  final Widget? trailing;
  final bool obscureText;
  final TextInputType keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;

  const EmeraldField({
    super.key,
    this.label,
    required this.placeholder,
    this.controller,
    this.onChanged,
    this.leadingIcon,
    this.trailing,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF586B63),
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: EmeraldTokens.border, width: 1),
          ),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 18, color: const Color(0xFF86928C)),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  readOnly: readOnly,
                  onTap: onTap,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: EmeraldTokens.ink,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: placeholder,
                    hintStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFA5B2AC),
                    ),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ],
    );
  }
}

/// Khung nhập ghi chú nhiều dòng chuẩn Emerald
class EmeraldNoteField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final ValueChanged<String>? onChanged;

  const EmeraldNoteField({
    super.key,
    required this.controller,
    this.label = 'Ghi chú (không bắt buộc)',
    this.placeholder = 'Thêm một lời nhắn…',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF586B63),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 72,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: EmeraldTokens.border, width: 1),
          ),
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            onChanged: onChanged,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: EmeraldTokens.ink,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: placeholder,
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Color(0xFFA5B2AC),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Hàng chọn lựa chuẩn Emerald (Picker Row: icon/logo + label/meta + chev)
class EmeraldPickerRow extends StatelessWidget {
  final String label;
  final String meta;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback onTap;
  final Widget? trailing;

  const EmeraldPickerRow({
    super.key,
    required this.label,
    required this.meta,
    this.icon,
    this.leading,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EmeraldTokens.border, width: 1),
        ),
        child: Row(
          children: [
            leading ??
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4EC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon ?? LucideIcons.circle, size: 16, color: const Color(0xFF00866A)),
                ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: EmeraldTokens.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: EmeraldTokens.meta,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            trailing ?? const Icon(LucideIcons.chevron_right, size: 16, color: Color(0xFFA5B2AC)),
          ],
        ),
      ),
    );
  }
}

/// Huy hiệu logo ngân hàng (MB, TCB, VCB, ACB, TPB, BIDV, VPB)
class EmeraldBankBadge extends StatelessWidget {
  final String code;
  final double size;

  const EmeraldBankBadge({
    super.key,
    required this.code,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg = Colors.white;
    switch (code.toUpperCase()) {
      case 'MB':
        bg = const Color(0xFF003399);
        break;
      case 'TCB':
        bg = const Color(0xFFEE2E24);
        break;
      case 'VCB':
        bg = const Color(0xFF006838);
        break;
      case 'ACB':
        bg = const Color(0xFF0073BA);
        break;
      case 'TPB':
        bg = const Color(0xFF7C2283);
        break;
      case 'BIDV':
        bg = const Color(0xFF0A6E3B);
        break;
      case 'VPB':
        bg = const Color(0xFF00A859);
        break;
      default:
        bg = const Color(0xFF007558);
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      alignment: Alignment.center,
      child: Text(
        code,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: size * 0.35,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

/// Thẻ tín dụng/ngân hàng chuẩn Emerald (MB BANK, number, balance, EMV chip)
class EmeraldCreditCardWidget extends StatelessWidget {
  final String bankName;
  final String cardNumber;
  final String balance;
  final double height;
  final VoidCallback? onTap;

  const EmeraldCreditCardWidget({
    super.key,
    required this.bankName,
    required this.cardNumber,
    required this.balance,
    this.height = 175,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF064739), Color(0xFF022B22)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF04342A).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 38,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  bankName.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: Color(0xFFBBE5D5),
                  ),
                ),
                Text(
                  cardNumber,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2.2,
                    color: Color(0xFFDFEFE8),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SỐ DƯ HIỆN TẠI',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: Color(0xFF90C8B3),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      balance,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Thanh tiến trình phẳng chuẩn Emerald
class EmeraldProgress extends StatelessWidget {
  final double value;
  final double height;
  final Color? color;
  final Color? trackColor;

  const EmeraldProgress({
    super.key,
    required this.value,
    this.height = 6,
    this.color,
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = (value > 1.0 ? value / 100.0 : value).clamp(0.0, 1.0);
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: trackColor ?? const Color(0xFFE4EDE7),
        borderRadius: BorderRadius.circular(height),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: clamped,
        child: Container(
          decoration: BoxDecoration(
            color: color ?? EmeraldTokens.emeraldPrimary,
            borderRadius: BorderRadius.circular(height),
          ),
        ),
      ),
    );
  }
}

/// Vòng tròn tiến trình chuẩn Emerald (Ring Progress: ví dụ 73% đã dùng)
class EmeraldRingProgress extends StatelessWidget {
  final int percentage;
  final String label;
  final double size;

  const EmeraldRingProgress({
    super.key,
    required this.percentage,
    this.label = 'đã dùng',
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EmeraldRingPainter(percentage: percentage),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percentage%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w700,
                  color: EmeraldTokens.ink,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: size * 0.12,
                  color: EmeraldTokens.meta,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmeraldRingPainter extends CustomPainter {
  final int percentage;

  _EmeraldRingPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.12;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = const Color(0xFFE4EDE7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = EmeraldTokens.emeraldPrimary
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final sweepAngle = 2 * math.pi * (percentage.clamp(0, 100) / 100.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _EmeraldRingPainter oldDelegate) =>
      oldDelegate.percentage != percentage;
}

/// Khung thông báo nhỏ chuẩn Emerald (Notice)
class EmeraldNotice extends StatelessWidget {
  final String text;
  final IconData icon;

  const EmeraldNotice({
    super.key,
    required this.text,
    this.icon = LucideIcons.sparkles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF8F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6ECE0), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF007557)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF00563F),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hàng Cài đặt Switch chuẩn Emerald
class EmeraldSwitchRow extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const EmeraldSwitchRow({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: EmeraldTokens.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: EmeraldTokens.meta,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: EmeraldTokens.emeraldPrimary,
          ),
        ],
      ),
    );
  }
}

/// Hàng Menu danh sách chuẩn Emerald (Icon, Title, Subtitle, Chevron)
class EmeraldMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? detail;
  final VoidCallback onTap;

  const EmeraldMenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.detail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: EmeraldTokens.borderDivider, width: 1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF007A5C)),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: EmeraldTokens.ink,
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      detail!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: EmeraldTokens.meta,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(LucideIcons.chevron_right, size: 15, color: Color(0xFFA5B2AC)),
          ],
        ),
      ),
    );
  }
}

/// Hàng Chip ngang chuẩn Emerald (ChipRow: Tất cả, Tuần này, Tháng này...)
class EmeraldChipRow extends StatelessWidget {
  final List<String> labels;
  final int activeIndex;
  final ValueChanged<int> onSelect;

  const EmeraldChipRow({
    super.key,
    required this.labels,
    required this.activeIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(labels.length, (idx) {
          final isSelected = idx == activeIndex;
          return GestureDetector(
            onTap: () => onSelect(idx),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE2F4EB) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFF00866A) : EmeraldTokens.border,
                  width: 1,
                ),
              ),
              child: Text(
                labels[idx],
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? const Color(0xFF006F53) : EmeraldTokens.ink,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Biểu đồ cột Thu & Chi qua các tháng (T5 - T10) chuẩn Emerald
class EmeraldBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyData;

  const EmeraldBarChart({super.key, required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: monthlyData.map((d) {
                final double incFactor = (d['income'] as num).toDouble() / 100.0;
                final double expFactor = (d['expense'] as num).toDouble() / 100.0;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 10,
                          height: (85 * incFactor).clamp(10.0, 85.0),
                          decoration: BoxDecoration(
                            color: EmeraldTokens.emeraldPrimary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Container(
                          width: 10,
                          height: (85 * expFactor).clamp(10.0, 85.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF74CCAA),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      d['month'] as String,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        color: EmeraldTokens.meta,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(EmeraldTokens.emeraldPrimary, 'Thu nhập'),
              const SizedBox(width: 18),
              _legendDot(const Color(0xFF74CCAA), 'Chi tiêu'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xFF586B63)),
        ),
      ],
    );
  }
}

/// Biểu đồ Donut chi tiêu danh mục chuẩn Emerald
class EmeraldDonutChart extends StatelessWidget {
  final List<Map<String, dynamic>> slices;

  const EmeraldDonutChart({super.key, required this.slices});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          height: 90,
          child: CustomPaint(
            painter: _DonutPainter(slices: slices),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: slices.map((s) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: s['color'] as Color? ?? EmeraldTokens.emeraldPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '${s['label']} ',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: EmeraldTokens.ink,
                        ),
                      ),
                    ),
                    Text(
                      '${s['percent']}%',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: EmeraldTokens.ink,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<Map<String, dynamic>> slices;

  _DonutPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.22;
    final radius = (size.width - strokeWidth) / 2;

    double startAngle = -math.pi / 2;
    for (final s in slices) {
      final percent = (s['percent'] as num).toDouble() / 100.0;
      final sweepAngle = 2 * math.pi * percent;
      final paint = Paint()
        ..color = (s['color'] as Color? ?? EmeraldTokens.emeraldPrimary)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.04,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}

/// Đáy hành động ghim cố định (Sticky Bottom Action Footer) chuẩn Emerald
class EmeraldBottomAction extends StatelessWidget {
  final Widget child;

  const EmeraldBottomAction({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: EmeraldTokens.borderDivider, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(
        EmeraldTokens.pagePadding,
        12,
        EmeraldTokens.pagePadding,
        math.max(12.0, bottomInset),
      ),
      child: child,
    );
  }
}
