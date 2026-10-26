import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../data/models/finance_models.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_radius.dart';
import '../design_system/app_spacing.dart';

enum OwnerFilter {
  all('all', 'Tất cả'),
  husband('husband', 'Chồng'),
  wife('wife', 'Vợ'),
  joint('joint', 'Chung');

  final String value;
  final String label;
  const OwnerFilter(this.value, this.label);

  static OwnerFilter fromString(String? val) {
    if (val == null) return OwnerFilter.all;
    final clean = val.trim().toLowerCase();
    switch (clean) {
      case 'husband':
      case 'chồng':
      case 'chong':
        return OwnerFilter.husband;
      case 'wife':
      case 'vợ':
      case 'vo':
        return OwnerFilter.wife;
      case 'joint':
      case 'shared':
      case 'family':
      case 'chung':
      case 'gia đình':
      case 'gia dinh':
        return OwnerFilter.joint;
      case 'all':
      default:
        return OwnerFilter.all;
    }
  }

  bool matchTransaction(TransactionModel tx, {Map<String, Wallet>? walletMap}) {
    if (this == OwnerFilter.all) return true;
    final w = (walletMap != null && tx.walletId != null)
        ? walletMap[tx.walletId]
        : null;
    final rawOwner = (tx.owner ?? tx.fromOwner ?? tx.paidByOwner ?? w?.owner)
        ?.toLowerCase()
        .trim();
    final rawOwnerName = (tx.ownerName ?? w?.ownerName)?.toLowerCase().trim();

    if (this == OwnerFilter.husband) {
      return rawOwner == 'husband' ||
          rawOwnerName == 'chồng' ||
          tx.tags.any((tag) => tag.toLowerCase().contains('chồng'));
    } else if (this == OwnerFilter.wife) {
      return rawOwner == 'wife' ||
          rawOwnerName == 'vợ' ||
          tx.tags.any((tag) => tag.toLowerCase().contains('vợ'));
    } else if (this == OwnerFilter.joint) {
      const jointOwners = {'joint', 'shared', 'family', 'common'};
      return jointOwners.contains(rawOwner) ||
          rawOwnerName == 'chung' ||
          rawOwnerName == 'gia đình' ||
          tx.tags.any((tag) {
            final normalized = tag.toLowerCase();
            return normalized.contains('chung') ||
                normalized.contains('gia đình');
          });
    }
    return true;
  }

  bool matchWallet(Wallet wallet) {
    if (this == OwnerFilter.all) return true;
    final owner = wallet.owner.toLowerCase().trim();
    final name = wallet.ownerName.toLowerCase().trim();
    if (owner.isNotEmpty) {
      if (this == OwnerFilter.husband) return owner == 'husband';
      if (this == OwnerFilter.wife) return owner == 'wife';
      if (this == OwnerFilter.joint) {
        return const {'joint', 'shared', 'family', 'common'}.contains(owner);
      }
    }
    if (this == OwnerFilter.husband) {
      return name == 'chồng';
    } else if (this == OwnerFilter.wife) {
      return name == 'vợ';
    } else if (this == OwnerFilter.joint) {
      return name == 'chung' || name == 'gia đình';
    }
    return true;
  }

  bool matchAsset(Asset asset, {Map<String, Wallet>? walletMap}) {
    if (this == OwnerFilter.all) return true;
    final w = (walletMap != null &&
            (asset.walletId != null || asset.sourceWalletId != null))
        ? (walletMap[asset.walletId] ?? walletMap[asset.sourceWalletId])
        : null;
    if (w != null) {
      return matchWallet(w);
    }
    return true;
  }

  bool matchLoan(Loan loan, {Map<String, Wallet>? walletMap}) {
    if (this == OwnerFilter.all) return true;
    final w = (walletMap != null && loan.walletId.isNotEmpty)
        ? walletMap[loan.walletId]
        : null;
    if (w != null) {
      return matchWallet(w);
    }
    return true;
  }
}

/// Exact replica of user requested Member Dropdown Pill: [● Tất cả ⌵]
class MemberDropdownPill extends StatelessWidget {
  final OwnerFilter selected;
  final ValueChanged<OwnerFilter> onSelected;
  final bool isDark;
  final bool onColoredSurface;

  const MemberDropdownPill({
    super.key,
    required this.selected,
    required this.onSelected,
    this.isDark = false,
    this.onColoredSurface = false,
  });

  Color _getColor(OwnerFilter filter) {
    switch (filter) {
      case OwnerFilter.husband:
        return const Color(0xFF0284C7); // Sky Blue
      case OwnerFilter.wife:
        return const Color(0xFFEC4899); // Pink
      case OwnerFilter.joint:
        return const Color(0xFF8B5CF6); // Purple
      case OwnerFilter.all:
      default:
        return const Color(0xFF10B981); // Emerald Green
    }
  }

  Color _getBgColor(OwnerFilter filter, bool dark) {
    final baseColor = _getColor(filter);
    return dark
        ? baseColor.withValues(alpha: 0.18)
        : baseColor.withValues(alpha: 0.10);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = onColoredSurface ? Colors.white : _getColor(selected);
    final bgColor = onColoredSurface ? Colors.white.withValues(alpha: .16) : _getBgColor(selected, isDark);

    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<OwnerFilter>(
        initialValue: selected,
        tooltip: 'Chọn thành viên',
        onSelected: (val) {
          HapticFeedback.selectionClick();
          onSelected(val);
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 10,
        position: PopupMenuPosition.under,
        offset: const Offset(0, 6),
        constraints: const BoxConstraints(minWidth: 180),
        itemBuilder: (ctx) => [
          _buildMenuItem(OwnerFilter.all, isDark),
          _buildMenuItem(OwnerFilter.husband, isDark),
          _buildMenuItem(OwnerFilter.wife, isDark),
          _buildMenuItem(OwnerFilter.joint, isDark),
        ],
        child: Container(
          constraints: const BoxConstraints(minHeight: 34),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: effectiveColor.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: effectiveColor,
                  boxShadow: [
                    BoxShadow(
                      color: effectiveColor.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                selected.label,
                style: TextStyle(
                  color: effectiveColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: effectiveColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<OwnerFilter> _buildMenuItem(OwnerFilter filter, bool dark) {
    return CheckedPopupMenuItem<OwnerFilter>(
      value: filter,
      checked: filter == selected,
      child: Text(
        filter.label,
        style: TextStyle(
          color: dark ? Colors.white : const Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// Compact owner selector shared by every financial overview.
class SubjectFilterPill extends StatelessWidget {
  final OwnerFilter selected;
  final ValueChanged<OwnerFilter> onSelected;
  final bool compact;
  final bool onColoredSurface;

  const SubjectFilterPill({
    super.key,
    required this.selected,
    required this.onSelected,
    this.compact = false,
    this.onColoredSurface = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MemberDropdownPill(
      selected: selected,
      onSelected: onSelected,
      isDark: isDark,
      onColoredSurface: onColoredSurface,
    );
  }
}

