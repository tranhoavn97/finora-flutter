import 'package:flutter/material.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../data/models/finance_models.dart';
import '../../domain/finance/transaction_member.dart';
import 'finora_member_filter.dart';

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
    return resolveTransactionMember(tx, walletMap: walletMap).value == value;
  }

  bool matchWallet(Wallet wallet) {
    if (this == OwnerFilter.all) return true;
    return resolveWalletMember(wallet).value == value;
  }

  bool matchAsset(Asset asset, {Map<String, Wallet>? walletMap}) {
    if (this == OwnerFilter.all) return true;
    final targetWalletId = asset.walletId ?? asset.sourceWalletId;
    final w = (walletMap != null &&
            targetWalletId != null &&
            walletMap.containsKey(targetWalletId))
        ? walletMap[targetWalletId]
        : null;
    final raw = (w?.owner ?? '').toLowerCase().trim();
    final name = (w?.ownerName ?? '').toLowerCase().trim();
    final isWife = raw == 'wife' ||
        name == 'vợ' ||
        asset.name.toLowerCase().contains('vợ');
    if (this == OwnerFilter.wife) return isWife;
    if (this == OwnerFilter.husband) return !isWife;
    return true;
  }

  bool matchLoan(Loan loan, {Map<String, Wallet>? walletMap}) {
    if (this == OwnerFilter.all) return true;
    final w = (walletMap != null &&
            loan.walletId.isNotEmpty &&
            walletMap.containsKey(loan.walletId))
        ? walletMap[loan.walletId]
        : null;
    final raw = (w?.owner ?? '').toLowerCase().trim();
    final name = (w?.ownerName ?? '').toLowerCase().trim();
    final isWife = raw == 'wife' ||
        name == 'vợ' ||
        loan.personName.toLowerCase().contains('vợ');
    if (this == OwnerFilter.wife) return isWife;
    if (this == OwnerFilter.husband) return !isWife;
    return true;
  }
}

/// Nút lọc thành viên chỉ hiển thị Avatar / Icon tròn của người đó (không hiện chữ trên nút)
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

  @override
  Widget build(BuildContext context) {
    final currentMember = switch (selected) {
      OwnerFilter.husband => 'husband',
      OwnerFilter.wife => 'wife',
      _ => null,
    };

    return FinoraUnifiedMemberPill(
      currentMember: currentMember,
      isDark: isDark,
      height: 36,
      onSelected: (val) {
        if (val == 'husband') {
          onSelected(OwnerFilter.husband);
        } else if (val == 'wife') {
          onSelected(OwnerFilter.wife);
        } else {
          onSelected(OwnerFilter.all);
        }
      },
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
