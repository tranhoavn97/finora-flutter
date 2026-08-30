import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../data/models/finance_models.dart';
import '../design_system/app_colors.dart';

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

/// Universal 1-Touch Subject Filter Pill component.
class SubjectFilterPill extends StatelessWidget {
  final OwnerFilter selected;
  final ValueChanged<OwnerFilter> onSelected;
  final bool compact;

  const SubjectFilterPill({
    super.key,
    required this.selected,
    required this.onSelected,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const visibleFilters = [
      OwnerFilter.all,
      OwnerFilter.husband,
      OwnerFilter.wife,
    ];

    final selectedIndex = visibleFilters.indexOf(selected).clamp(0, 2);
    final height = compact ? 40.0 : 46.0;
    return LayoutBuilder(builder: (context, constraints) {
      const inset = 4.0;
      final itemWidth =
          (constraints.maxWidth - inset * 2) / visibleFilters.length;
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xB8141F3C)
              : Colors.white.withValues(alpha: .70),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isDark ? const Color(0xFF202D4E) : Colors.white,
            width: 1.2,
          ),
        ),
        child: Stack(children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutBack,
            left: inset + selectedIndex * itemWidth,
            top: inset,
            width: itemWidth,
            height: height - inset * 2,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              decoration: BoxDecoration(
                gradient: _gradientForFilter(visibleFilters[selectedIndex]),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: _glowColor(visibleFilters[selectedIndex]),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: visibleFilters.map((filter) {
              final isSelected = selected == filter;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelected(filter);
                  },
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      style: TextStyle(
                        fontSize: compact ? 12.0 : 13.0,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                      child: Text(filter.label),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ]),
      );
    });
  }

  LinearGradient _gradientForFilter(OwnerFilter filter) {
    switch (filter) {
      case OwnerFilter.husband:
        return const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF5AA9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case OwnerFilter.wife:
        return const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case OwnerFilter.joint:
        return const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF93C5FD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case OwnerFilter.all:
        return const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _glowColor(OwnerFilter filter) {
    switch (filter) {
      case OwnerFilter.husband:
        return const Color(0xFF3563E9).withValues(alpha: 0.30);
      case OwnerFilter.wife:
        return const Color(0xFFEC4899).withValues(alpha: 0.35);
      case OwnerFilter.joint:
        return const Color(0xFF0E7490).withValues(alpha: 0.30);
      case OwnerFilter.all:
        return const Color(0xFF1E293B).withValues(alpha: 0.25);
    }
  }
}
