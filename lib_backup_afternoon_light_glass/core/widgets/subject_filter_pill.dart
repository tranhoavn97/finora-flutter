import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../data/models/finance_models.dart';

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

/// Universal Subject Filter Dropdown Pill component.
class SubjectFilterPill extends StatelessWidget {
  final OwnerFilter selected;
  final ValueChanged<OwnerFilter> onSelected;
  final bool compact;
  final bool showJoint;

  const SubjectFilterPill({
    super.key,
    required this.selected,
    required this.onSelected,
    this.compact = false,
    this.showJoint = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = compact ? 40.0 : 46.0;

    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<OwnerFilter>(
        initialValue: selected,
        tooltip: 'Chọn chủ sở hữu',
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
        offset: const Offset(0, 44),
        itemBuilder: (ctx) => [
          CheckedPopupMenuItem<OwnerFilter>(
            value: OwnerFilter.all,
            checked: selected == OwnerFilter.all,
            child: const Text('Tất cả'),
          ),
          CheckedPopupMenuItem<OwnerFilter>(
            value: OwnerFilter.husband,
            checked: selected == OwnerFilter.husband,
            child: const Text('Chồng'),
          ),
          CheckedPopupMenuItem<OwnerFilter>(
            value: OwnerFilter.wife,
            checked: selected == OwnerFilter.wife,
            child: const Text('Vợ'),
          ),
          CheckedPopupMenuItem<OwnerFilter>(
            value: OwnerFilter.joint,
            checked: selected == OwnerFilter.joint,
            child: const Text('Chung'),
          ),
        ],
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xB8141F3C)
                : Colors.white.withValues(alpha: .90),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: isDark ? const Color(0xFF202D4E) : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected == OwnerFilter.husband
                        ? Icons.person_rounded
                        : (selected == OwnerFilter.wife
                            ? Icons.person_outline_rounded
                            : Icons.people_alt_outlined),
                    size: 16,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Chủ sở hữu: ${selected.label}',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

}

/// Exact replica of user requested Member Dropdown Pill: [● Tất cả ⌵]
class MemberDropdownPill extends StatelessWidget {
  final OwnerFilter selected;
  final ValueChanged<OwnerFilter> onSelected;
  final bool isDark;

  const MemberDropdownPill({
    super.key,
    required this.selected,
    required this.onSelected,
    this.isDark = false,
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
        return const Color(0xFF10B981); // Emerald Green
    }
  }

  @override
  Widget build(BuildContext context) {

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
        offset: const Offset(0, 36),
        itemBuilder: (ctx) => [
          _buildMenuItem(OwnerFilter.all, isDark),
          _buildMenuItem(OwnerFilter.husband, isDark),
          _buildMenuItem(OwnerFilter.wife, isDark),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_alt_outlined,
                size: 16,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
              const SizedBox(width: 6),
              Text(
                selected.label,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<OwnerFilter> _buildMenuItem(OwnerFilter filter, bool dark) {
    final color = _getColor(filter);
    final isSelected = filter == selected;

    return PopupMenuItem<OwnerFilter>(
      value: filter,
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            filter.label,
            style: TextStyle(
              color: isSelected ? color : (dark ? Colors.white : const Color(0xFF0F172A)),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check_rounded, color: color, size: 16),
          ],
        ],
      ),
    );
  }
}
