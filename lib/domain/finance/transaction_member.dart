import '../../core/utils/search.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';

enum TransactionMember {
  husband('husband', 'Chồng'),
  wife('wife', 'Vợ'),
  joint('joint', 'Chung'),
  unknown('unknown', 'Chưa phân loại');

  final String value;
  final String label;
  const TransactionMember(this.value, this.label);
}

TransactionMember? parseTransactionMember(String? value) =>
    switch (normalizeSearch(value ?? '')) {
      'husband' || 'chong' => TransactionMember.husband,
      'wife' || 'vo' => TransactionMember.wife,
      'joint' ||
      'shared' ||
      'family' ||
      'chung' ||
      'gia dinh' =>
        TransactionMember.joint,
      _ => null,
    };

TransactionMember resolveMemberFields(Iterable<String?> values) {
  final members =
      values.map(parseTransactionMember).whereType<TransactionMember>().toSet();
  return members.length == 1 ? members.single : TransactionMember.unknown;
}

TransactionMember resolveWalletMember(Wallet? wallet) => resolveMemberFields([
      if (wallet?.hasExplicitOwner == true) wallet!.owner,
      if (wallet?.hasExplicitOwnerName == true) wallet!.ownerName,
    ]);

/// Prefer explicit transaction attribution. Destination ownership does not
/// identify the spender; AI marks the source, rather than a family member.
TransactionMember resolveTransactionMember(TransactionModel tx,
    {Map<String, Wallet>? walletMap}) {
  for (final fields in [
    [tx.creatorTag],
    [tx.owner, tx.ownerName],
    [tx.paidByOwner, tx.fromOwner],
    tx.tags,
  ]) {
    if (fields.any((value) => parseTransactionMember(value) != null)) {
      return resolveMemberFields(fields);
    }
  }
  final walletId = [tx.walletId, tx.fromWalletId]
      .whereType<String>()
      .where((id) => id.trim().isNotEmpty)
      .firstOrNull;
  final wallet = walletMap?[walletId];
  return resolveWalletMember(wallet);
}
