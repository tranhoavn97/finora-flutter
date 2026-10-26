import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/search.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../state/transaction_provider.dart';
import '../../state/family_provider.dart';
import '../../data/services/finora_nlp_engine.dart';

/// Full-screen form to create or edit a transaction.
/// Matches the modern clean card design with automatic wife/husband spender detection.
class AddTransactionPage extends StatefulWidget {
  final String userId;
  final TransactionModel? existing;
  final String? initialType;
  final String? initialWalletId;
  final String? initialToWalletId;
  final String? initialCategoryId;

  const AddTransactionPage({
    super.key,
    required this.userId,
    this.existing,
    this.initialType,
    this.initialWalletId,
    this.initialToWalletId,
    this.initialCategoryId,
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late String
      _type; // 'expense' | 'income' | 'transfer' | 'credit_card_payment' | 'investment'
  late int _date;

  Wallet? _wallet;
  Wallet? _fromWallet;
  Wallet? _toWallet;
  Category? _category;
  String? _creatorTag;
  String? _creatorUid;
  String? _creatorName;
  bool _isSaving = false;
  String? _pendingTransactionId;

  String _formatInitialAmount(int amount) {
    if (amount <= 0) return '';
    final cleanText = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < cleanText.length; i++) {
      if (i > 0 && (cleanText.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(cleanText[i]);
    }
    return buffer.toString();
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? widget.initialType ?? 'expense';
    _date = e?.date ?? DateTime.now().millisecondsSinceEpoch;
    _amountController = TextEditingController(
        text:
            (e != null && e.amount > 0) ? _formatInitialAmount(e.amount) : '');
    _noteController = TextEditingController(text: e?.note ?? '');

    context.read<TransactionProvider>().load(widget.userId);
    _amountController.addListener(_onAmountChanged);
    _noteController.addListener(_onAmountChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) => _initSelections());
  }

  void _onAmountChanged() {
    setState(() {});
  }

  /// Automatically identify spender (Vợ / Chồng) based on wallet ownership
  void _autoDetectSpenderFromWallet(Wallet? w) {
    if (w == null) return;
    FamilyProvider? familyProv;
    try {
      familyProv = context.read<FamilyProvider>();
    } catch (_) {}

    final ownerLower = w.owner.toLowerCase();
    final ownerNameLower = w.ownerName.toLowerCase();
    final nameLower = w.name.toLowerCase();

    String detectedTag = 'Chồng';
    if (ownerLower == 'wife' ||
        ownerNameLower.contains('vợ') ||
        nameLower.contains('vợ')) {
      detectedTag = 'Vợ';
    } else if (ownerLower == 'husband' ||
        ownerNameLower.contains('chồng') ||
        nameLower.contains('chồng')) {
      detectedTag = 'Chồng';
    } else if (w.ownerName.isNotEmpty && w.ownerName != 'default') {
      detectedTag = w.ownerName;
    } else if (familyProv?.defaultMemberTag != null) {
      detectedTag = familyProv!.defaultMemberTag;
    }

    _creatorTag = detectedTag;
    _creatorName = detectedTag;

    if (familyProv != null && familyProv.members.isNotEmpty) {
      for (final m in familyProv.members) {
        final tag =
            m.memberTag ?? (m.role.displayName == 'Chủ nhóm' ? 'Chồng' : 'Vợ');
        if (tag.toLowerCase() == detectedTag.toLowerCase() ||
            (m.displayName.toLowerCase().contains(detectedTag.toLowerCase()))) {
          _creatorUid = m.uid;
          _creatorName = m.displayName;
          break;
        }
      }
    }
  }

  /// Resolve initial wallet/category selections once provider data is ready.
  void _initSelections() {
    if (!mounted) return;
    final provider = context.read<TransactionProvider>();
    final wallets = provider.wallets;
    final e = widget.existing;
    final initWId = widget.initialWalletId;

    setState(() {
      _wallet = _findWallet(wallets, e?.walletId ?? initWId) ??
          _findLastUsedWallet(provider) ??
          (wallets.isNotEmpty ? wallets.first : null);
      _fromWallet = _findWallet(wallets, e?.fromWalletId ?? initWId) ??
          (wallets.isNotEmpty ? wallets.first : null);
      _toWallet = _findWallet(
              wallets, e?.toWalletId ?? widget.initialToWalletId ?? initWId) ??
          (wallets.length > 1
              ? wallets[1]
              : (wallets.isNotEmpty ? wallets.first : null));

      _category = _resolveCategory(provider, _type, e);

      // Auto detect spender from selected wallet
      if (e != null && e.creatorTag != null && e.creatorTag!.isNotEmpty) {
        _creatorTag = e.creatorTag;
        _creatorUid = e.createdBy;
        _creatorName = e.creatorName;
      } else {
        final activeW = (_type == 'transfer' || _type == 'credit_card_payment')
            ? _fromWallet
            : _wallet;
        _autoDetectSpenderFromWallet(activeW);
      }
    });
  }

  Wallet? _findWallet(List<Wallet> wallets, String? id) {
    if (id == null) return null;
    for (final w in wallets) {
      if (w.id == id) return w;
    }
    return null;
  }

  List<Category> _categoriesFor(TransactionProvider provider, String type) {
    return provider.categories
        .where((c) => c.categoryGroup == type && !c.isArchived)
        .toList();
  }

  List<Category> _sortCategoriesByRecency(
      List<Category> cats, List<TransactionModel> txs) {
    final recency = <String, int>{};
    for (int i = 0; i < txs.length; i++) {
      final tx = txs[i];
      if (tx.categoryId != null && !recency.containsKey(tx.categoryId!)) {
        recency[tx.categoryId!] = i;
      }
    }
    final sorted = List<Category>.from(cats);
    sorted.sort((a, b) {
      final aRec = recency[a.id] ?? 999999;
      final bRec = recency[b.id] ?? 999999;
      return aRec.compareTo(bRec);
    });
    return sorted;
  }

  List<Wallet> _sortWalletsByRecency(
      List<Wallet> wallets, List<TransactionModel> txs) {
    final recency = <String, int>{};
    for (int i = 0; i < txs.length; i++) {
      final tx = txs[i];
      if (tx.walletId != null &&
          tx.walletId!.isNotEmpty &&
          !recency.containsKey(tx.walletId!)) {
        recency[tx.walletId!] = i;
      }
    }
    final sorted = List<Wallet>.from(wallets);
    sorted.sort((a, b) {
      final aRec = recency[a.id] ?? 999999;
      final bRec = recency[b.id] ?? 999999;
      return aRec.compareTo(bRec);
    });
    return sorted;
  }

  Category? _findLastUsedCategory(TransactionProvider provider, String type) {
    final txs = provider.transactions;
    for (final tx in txs) {
      if (tx.type == type &&
          tx.categoryId != null &&
          tx.categoryId!.isNotEmpty) {
        final cats = _categoriesFor(provider, type);
        for (final c in cats) {
          if (c.id == tx.categoryId) {
            return c;
          }
        }
      }
    }
    return null;
  }

  Wallet? _findLastUsedWallet(TransactionProvider provider) {
    final txs = provider.transactions;
    final wallets = provider.wallets;
    for (final tx in txs) {
      if (tx.walletId != null && tx.walletId!.isNotEmpty) {
        final w = _findWallet(wallets, tx.walletId);
        if (w != null) return w;
      }
    }
    return null;
  }

  Category? _resolveCategory(
      TransactionProvider provider, String type, TransactionModel? existing) {
    final cats = _categoriesFor(provider, type);
    if (cats.isEmpty) return null;
    if (existing != null) {
      for (final c in cats) {
        if (c.name == existing.categoryName || c.id == existing.categoryId) {
          return c;
        }
      }
    }
    if (widget.initialCategoryId != null) {
      for (final c in cats) {
        if (c.id == widget.initialCategoryId ||
            c.name == widget.initialCategoryId) {
          return c;
        }
      }
    }
    final lastUsed = _findLastUsedCategory(provider, type);
    if (lastUsed != null) return lastUsed;
    return cats.first;
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _noteController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String type) {
    final provider = context.read<TransactionProvider>();
    setState(() {
      _type = type;
      if (type != 'transfer' && type != 'credit_card_payment') {
        _category = _resolveCategory(provider, type, widget.existing);
      }
    });
  }

  Future<void> _pickDate() async {
    final current = DateTime.fromMillisecondsSinceEpoch(_date);
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => GlassCalendarPicker(initialDate: current),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(picked.year, picked.month, picked.day, current.hour,
                current.minute)
            .millisecondsSinceEpoch;
      });
    }
  }

  void _pickCategory() {
    final provider = context.read<TransactionProvider>();
    final rawCats = _categoriesFor(provider, _type);
    final cats = _sortCategoriesByRecency(rawCats, provider.transactions);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final query = normalizeSearch(searchQuery);
            final filtered = query.isEmpty
                ? cats
                : cats
                    .where((c) => normalizeSearch(c.name).contains(query))
                    .toList();

            return AnimatedPadding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutQuad,
              child: GlassBottomSheet(
                radius: 32,
                child: SafeArea(
                  top: false,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.15)
                                  : Colors.black.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Text('Chọn danh mục',
                            style: AppTypography.subhead.copyWith(
                                color: primaryTextColor,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.md),
                        FinoraTextField(
                          controller: searchController,
                          hint: 'Tìm danh mục...',
                          radius: 24,
                          onChanged: (val) {
                            setStateSheet(() {
                              searchQuery = val;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Flexible(
                          child: filtered.isEmpty
                              ? Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text('Không tìm thấy danh mục nào',
                                        style: AppTypography.caption2.copyWith(
                                            color: secondaryTextColor)),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: AppSpacing.xs),
                                  itemBuilder: (_, i) {
                                    final item = filtered[i];
                                    final selected = item.id == _category?.id ||
                                        item.name == _category?.name;
                                    return _SelectionRow(
                                      icon: item.icon,
                                      categoryName: item.name,
                                      color: BankIconRegistry.parseThemeColor(
                                          item.color),
                                      label: item.name,
                                      selected: selected,
                                      onTap: () {
                                        setState(() => _category = item);
                                        Navigator.of(sheetContext).pop();
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _pickWallet(void Function(Wallet) onSelected,
      {Wallet? current,
      String title = 'Chọn ví',
      bool Function(Wallet)? filter}) {
    final provider = context.read<TransactionProvider>();
    final rawWallets = provider.wallets;
    final filtered =
        filter != null ? rawWallets.where(filter).toList() : rawWallets;
    final wallets = _sortWalletsByRecency(filtered, provider.transactions);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        String searchQuery = '';
        final searchWalletController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final query = normalizeSearch(searchQuery);
            final displayedWallets = query.isEmpty
                ? wallets
                : wallets.where((w) {
                    final n = normalizeSearch(w.name);
                    final b = normalizeSearch(w.bankName ?? '');
                    return n.contains(query) || b.contains(query);
                  }).toList();

            return AnimatedPadding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutQuad,
              child: GlassBottomSheet(
                radius: 32,
                child: SafeArea(
                  top: false,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.15)
                                  : Colors.black.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Text(title,
                            style: AppTypography.subhead.copyWith(
                                color: primaryTextColor,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.md),
                        FinoraTextField(
                          controller: searchWalletController,
                          hint: 'Tìm ví hoặc ngân hàng...',
                          radius: 24,
                          onChanged: (val) {
                            setStateSheet(() {
                              searchQuery = val;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Flexible(
                          child: displayedWallets.isEmpty
                              ? Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text('Không tìm thấy ví nào',
                                        style: AppTypography.caption2.copyWith(
                                            color: secondaryTextColor)),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: displayedWallets.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: AppSpacing.xs),
                                  itemBuilder: (_, i) {
                                    final w = displayedWallets[i];
                                    final selected = w.id == current?.id;
                                    final hasBank = w.bankCode != null;

                                    return Material(
                                      color: Colors.transparent,
                                      borderRadius: AppRadius.input,
                                      child: InkWell(
                                        borderRadius: AppRadius.input,
                                        onTap: () {
                                          onSelected(w);
                                          Navigator.of(sheetContext).pop();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.md,
                                              vertical: 12),
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? AppColors.accent
                                                    .withOpacity(0.12)
                                                : Colors.transparent,
                                            borderRadius: AppRadius.input,
                                          ),
                                          child: Row(
                                            children: [
                                              if (hasBank ||
                                                  w.type == 'ewallet')
                                                BankIcon(
                                                  bankCode:
                                                      w.bankCode ?? w.type,
                                                  bankName:
                                                      w.bankName ?? w.name,
                                                  size: 32,
                                                )
                                              else
                                                Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration:
                                                      const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Color(0xFFE0F2FE),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    w.isCreditCard
                                                        ? '💳'
                                                        : '💵',
                                                    style: const TextStyle(
                                                        fontSize: 16),
                                                  ),
                                                ),
                                              const SizedBox(
                                                  width: AppSpacing.sm),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      w.name,
                                                      style: AppTypography.body
                                                          .copyWith(
                                                        color: primaryTextColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${w.isCreditCard ? "Thẻ tín dụng" : (w.type == "bank" ? "Tài khoản" : "Tiền mặt")} • ${w.ownerName}',
                                                      style: AppTypography
                                                          .caption2
                                                          .copyWith(
                                                        color:
                                                            secondaryTextColor,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(
                                                  width: AppSpacing.sm),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    w.isCreditCard
                                                        ? Formatters
                                                            .formatCurrency(w
                                                                    .creditLimit -
                                                                w.currentDebt)
                                                        : Formatters
                                                            .formatCurrency(
                                                                w.balance),
                                                    style: AppTypography.body
                                                        .copyWith(
                                                      color: w.isCreditCard
                                                          ? const Color(
                                                              0xFFF87171)
                                                          : const Color(
                                                              0xFF2563EB),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    w.isCreditCard
                                                        ? 'Khả dụng'
                                                        : 'Số dư',
                                                    style: AppTypography
                                                        .caption2
                                                        .copyWith(
                                                      color: secondaryTextColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (selected) ...[
                                                const SizedBox(width: 8),
                                                const Icon(Icons.check,
                                                    size: 20,
                                                    color: AppColors.accent),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(digits) ?? 0;
    if (amount <= 0) return;

    setState(() => _isSaving = true);

    final note = _noteController.text.trim();
    final TransactionModel tx;

    FamilyProvider? familyProv;
    try {
      familyProv = context.read<FamilyProvider>();
    } catch (_) {}
    final defaultTag = familyProv?.defaultMemberTag ?? 'Chồng';
    final activeTag = _creatorTag ?? defaultTag;
    final activeUid = _creatorUid ?? familyProv?.currentUid ?? widget.userId;
    final activeName =
        _creatorName ?? familyProv?.currentMember?.displayName ?? 'Thành viên';

    final oldTags = widget.existing?.tags ?? <String>[];
    final cleanTags = oldTags
        .where(
            (t) => t != 'Chồng' && t != 'Vợ' && t != 'Con' && t != 'Thành viên')
        .toList();
    final String ownerName;
    if (_type == 'transfer' || _type == 'credit_card_payment') {
      ownerName = _fromWallet?.ownerName ?? activeTag;
    } else {
      ownerName = _wallet?.ownerName ?? activeTag;
    }
    final txTags = {...cleanTags, ownerName, activeTag}.toList();

    if (_type == 'transfer') {
      tx = TransactionModel(
        amount: amount,
        type: 'transfer',
        date: _date,
        note: note.isEmpty ? null : note,
        fromWalletId: _fromWallet?.id,
        fromWalletName: _fromWallet?.name,
        toWalletId: _toWallet?.id,
        toWalletName: _toWallet?.name,
        fromOwner: _fromWallet?.owner,
        toOwner: _toWallet?.owner,
        categoryName: 'Chuyển tiền',
        categoryIcon: '🔄',
        categoryColor: '#6B7280',
        tags: txTags,
        creatorTag: activeTag,
        createdBy: activeUid,
        creatorName: activeName,
      );
    } else if (_type == 'credit_card_payment') {
      tx = TransactionModel(
        amount: amount,
        type: 'credit_card_payment',
        date: _date,
        note: note.isEmpty ? null : note,
        fromWalletId: _fromWallet?.id,
        fromWalletName: _fromWallet?.name,
        toWalletId: _toWallet?.id,
        toWalletName: _toWallet?.name,
        creditCardId: _toWallet?.id,
        fromOwner: _fromWallet?.owner,
        toOwner: _toWallet?.owner,
        categoryName: 'Thanh toán thẻ',
        categoryIcon: '💳',
        categoryColor: '#F59E0B',
        tags: txTags,
        creatorTag: activeTag,
        createdBy: activeUid,
        creatorName: activeName,
      );
    } else {
      tx = TransactionModel(
        amount: amount,
        type: _type,
        date: _date,
        note: note.isEmpty ? null : note,
        walletId: _wallet?.id,
        walletName: _wallet?.name,
        owner: _wallet?.owner,
        ownerName: _wallet?.ownerName,
        categoryId: _category?.id,
        categoryName: _category?.name,
        categoryIcon: _category?.icon,
        categoryColor: _category?.color,
        categoryGroup: _category?.categoryGroup ?? _type,
        merchantId: widget.existing?.merchantId,
        investmentSubtype: _type == 'investment' ? 'simple_asset' : null,
        investmentAction: _type == 'investment' ? 'buy' : null,
        assetName: _type == 'investment'
            ? (note.isEmpty ? (_category?.name ?? 'Tài sản đầu tư') : note)
            : null,
        tags: txTags,
        creatorTag: activeTag,
        createdBy: activeUid,
        creatorName: activeName,
      );
    }

    final provider = context.read<TransactionProvider>();
    final existing = widget.existing;
    try {
      final dynamic res = existing != null
          ? await (provider as dynamic).updateTransaction(widget.userId,
              existing.id, tx.copyWith(id: existing.id, userId: widget.userId))
          : await (provider as dynamic).createTransaction(
              widget.userId,
              tx.copyWith(
                id: _pendingTransactionId ??= const Uuid().v4(),
                userId: widget.userId,
              ));
      if (res == false) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chưa lưu được giao dịch')),
          );
        }
        return;
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chưa lưu được giao dịch: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _isValid() {
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(digits) ?? 0;
    if (amount <= 0 || _isSaving) return false;
    if (_type == 'transfer' || _type == 'credit_card_payment') {
      return _fromWallet != null &&
          _toWallet != null &&
          _fromWallet?.id != _toWallet?.id;
    } else {
      return _wallet != null && _category != null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-select defaults when provider loads data
    final wallets = provider.wallets;
    if (_wallet == null && wallets.isNotEmpty) {
      _wallet =
          _findWallet(wallets, widget.existing?.walletId) ?? wallets.first;
      if (_creatorTag == null) {
        _autoDetectSpenderFromWallet(_wallet);
      }
    }
    if (_fromWallet == null && wallets.isNotEmpty) {
      _fromWallet =
          _findWallet(wallets, widget.existing?.fromWalletId) ?? wallets.first;
      if (_creatorTag == null &&
          (_type == 'transfer' || _type == 'credit_card_payment')) {
        _autoDetectSpenderFromWallet(_fromWallet);
      }
    }
    if (_toWallet == null && wallets.isNotEmpty) {
      _toWallet = _findWallet(wallets, widget.existing?.toWalletId) ??
          (wallets.length > 1 ? wallets[1] : wallets.first);
    }
    if (_category == null) {
      _category = _resolveCategory(provider, _type, widget.existing);
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF090E1A) : const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Column(
          children: [
            // Header: squircle back button + title
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          CupertinoIcons.chevron_left,
                          size: 20,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.existing == null
                            ? 'Thêm giao dịch'
                            : 'Chỉnh sửa giao dịch',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                children: [
                  // Horizontal segmented capsule tabs
                  _buildTypeTabs(isDark),
                  const SizedBox(height: 16),

                  // Card 1: SỐ TIỀN
                  _buildAmountCard(isDark),
                  const SizedBox(height: 16),

                  // Card 2: DANH MỤC, VÍ THANH TOÁN, NGÀY, GHI CHÚ
                  _buildDetailsCard(isDark),
                ],
              ),
            ),

            // Bottom full-width Save Button
            _buildSaveButton(isDark),
          ],
        ),
      ),
    );
  }

  /// Segmented tabs matching screenshot (Chi tiêu, Thu nhập, Chuyển, Trả thẻ, Đầu tư)
  Widget _buildTypeTabs(bool isDark) {
    const types = [
      'expense',
      'income',
      'transfer',
      'credit_card_payment',
      'investment'
    ];
    return BouncyPillTabs(
      height: 44,
      labels: const ['Chi tiêu', 'Thu nhập', 'Chuyển', 'Trả thẻ', 'Đầu tư'],
      selectedIndex: types.indexOf(_type),
      colors: const [
        Color(0xFF2563EB),
        Color(0xFF059669),
        Color(0xFF0891B2),
        Color(0xFFE87922),
        Color(0xFF8B5CF6)
      ],
      onChanged: (i) => _onTypeChanged(types[i]),
    );
  }

  /// Card 1: SỐ TIỀN with custom blue outline box
  Widget _buildAmountCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFEEF2F6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SỐ TIỀN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF3B82F6),
                width: 1.6,
              ),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [DotSeparatorTextInputFormatter()],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: '0 đ',
                hintStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
                suffixText: _amountController.text.isNotEmpty ? ' đ' : null,
                suffixStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card 2: Details (Danh mục, Ví thanh toán, Ngày, Ghi chú)
  Widget _buildDetailsCard(bool isDark) {
    final activeWallet = (_type == 'transfer' || _type == 'credit_card_payment')
        ? _fromWallet
        : _wallet;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFEEF2F6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DANH MỤC
          if (_type != 'transfer' && _type != 'credit_card_payment') ...[
            Text(
              'DANH MỤC',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color:
                    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 8),
            _buildInteractiveTile(
              isDark: isDark,
              leading: CategoryIconBadge(
                icon: _category?.icon,
                categoryName: _category?.name,
                colorHex: _category?.color,
                size: 38,
                isDark: isDark,
              ),
              title: _category?.name ?? 'Chưa chọn',
              onTap: _pickCategory,
            ),
            const SizedBox(height: 18),
          ],

          // VÍ THANH TOÁN (or VÍ NGUỒN)
          Text(
            (_type == 'transfer' || _type == 'credit_card_payment')
                ? 'VÍ NGUỒN'
                : 'VÍ THANH TOÁN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          _buildInteractiveTile(
            isDark: isDark,
            leading: (activeWallet != null &&
                    (activeWallet.bankCode != null ||
                        activeWallet.type == 'ewallet'))
                ? BankIcon(
                    bankCode: activeWallet.bankCode ?? activeWallet.type,
                    bankName: activeWallet.bankName ?? activeWallet.name,
                    size: 24)
                : Text(
                    activeWallet != null
                        ? (activeWallet.isCreditCard
                            ? '💳'
                            : (activeWallet.type == 'bank' ? '🏦' : '💵'))
                        : '💵',
                    style: const TextStyle(fontSize: 22),
                  ),
            title: activeWallet?.name ?? 'Chưa chọn',
            trailingText: activeWallet != null
                ? (activeWallet.isCreditCard
                    ? Formatters.formatCurrency(
                        activeWallet.creditLimit - activeWallet.currentDebt)
                    : Formatters.formatCurrency(activeWallet.balance))
                : null,
            trailingColor: const Color(0xFF2563EB),
            onTap: () => _pickWallet(
              (w) {
                setState(() {
                  if (_type == 'transfer' || _type == 'credit_card_payment') {
                    _fromWallet = w;
                  } else {
                    _wallet = w;
                  }
                  _autoDetectSpenderFromWallet(w);
                });
              },
              current: activeWallet,
              title: (_type == 'transfer' || _type == 'credit_card_payment')
                  ? 'Chọn ví nguồn'
                  : 'Chọn ví thanh toán',
              filter: _type == 'credit_card_payment'
                  ? (w) => !w.isCreditCard
                  : null,
            ),
          ),

          // If transfer or credit_card_payment: VÍ NHẬN / THẺ NHẬN
          if (_type == 'transfer' || _type == 'credit_card_payment') ...[
            const SizedBox(height: 18),
            Text(
              _type == 'credit_card_payment' ? 'THẺ NHẬN' : 'VÍ NHẬN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color:
                    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 8),
            _buildInteractiveTile(
              isDark: isDark,
              leading: (_toWallet != null &&
                      (_toWallet!.bankCode != null ||
                          _toWallet!.type == 'ewallet'))
                  ? BankIcon(
                      bankCode: _toWallet!.bankCode ?? _toWallet!.type,
                      bankName: _toWallet!.bankName ?? _toWallet!.name,
                      size: 24)
                  : Text(
                      _toWallet != null
                          ? (_toWallet!.isCreditCard
                              ? '💳'
                              : (_toWallet!.type == 'bank' ? '🏦' : '💵'))
                          : '💵',
                      style: const TextStyle(fontSize: 22),
                    ),
              title: _toWallet?.name ?? 'Chưa chọn',
              trailingText: _toWallet != null
                  ? (_toWallet!.isCreditCard
                      ? Formatters.formatCurrency(
                          _toWallet!.creditLimit - _toWallet!.currentDebt)
                      : Formatters.formatCurrency(_toWallet!.balance))
                  : null,
              trailingColor: const Color(0xFF2563EB),
              onTap: () => _pickWallet(
                (w) => setState(() => _toWallet = w),
                current: _toWallet,
                title: _type == 'credit_card_payment'
                    ? 'Chọn thẻ nhận'
                    : 'Chọn ví nhận',
                filter: _type == 'credit_card_payment'
                    ? (w) => w.isCreditCard
                    : null,
              ),
            ),
          ],

          const SizedBox(height: 18),

          // NGÀY GIAO DỊCH
          Text(
            'NGÀY GIAO DỊCH',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          _buildInteractiveTile(
            isDark: isDark,
            leading: const Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: Color(0xFF2563EB),
            ),
            title: _formatDate(_date),
            onTap: _pickDate,
          ),

          const SizedBox(height: 18),

          // GHI CHÚ
          Text(
            'GHI CHÚ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withOpacity(0.5)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFEEF2F6),
                width: 1,
              ),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _noteController,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Mô tả chi tiết giao dịch...',
                hintStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Builder(
            builder: (context) {
              final noteText = _noteController.text.trim();
              if (noteText.isEmpty ||
                  _type == 'transfer' ||
                  _type == 'credit_card_payment') {
                return const SizedBox.shrink();
              }
              final txProv = context.watch<TransactionProvider>();
              final suggestedName = FinoraNlpEngine.matchCategoryName(
                noteText,
                _type,
                txProv.categories,
              );
              if (suggestedName.isEmpty ||
                  suggestedName == 'Chi tiêu' ||
                  suggestedName == 'Khác' ||
                  suggestedName == _category?.name) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF005FEA).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              const Color(0xFF005FEA).withValues(alpha: 0.28),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            Category? matched;
                            try {
                              matched = txProv.categories.firstWhere(
                                (c) =>
                                    c.name.toLowerCase() ==
                                    suggestedName.toLowerCase(),
                              );
                            } catch (_) {
                              matched = Category(
                                id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
                                name: suggestedName,
                                icon: '🏷️',
                                categoryGroup: _type,
                              );
                            }
                            setState(() {
                              _category = matched;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome_rounded,
                                    size: 14, color: Color(0xFF0284C7)),
                                const SizedBox(width: 5),
                                Text(
                                  'Gợi ý danh mục: $suggestedName',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF005FEA),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF005FEA),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Chọn',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Interactive rounded tile inside card (Danh mục, Ví, Ngày)
  Widget _buildInteractiveTile({
    required bool isDark,
    required Widget leading,
    required String title,
    String? trailingText,
    Color? trailingColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withOpacity(0.5)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFEEF2F6),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailingText != null) ...[
                Text(
                  trailingText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: trailingColor ?? const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color:
                    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Full-width vibrant blue pill Save Button matching screenshot
  Widget _buildSaveButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _isValid() ? _save : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            disabledBackgroundColor: const Color(0xFF2563EB).withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            elevation: 0,
            shadowColor: const Color(0xFF2563EB).withOpacity(0.35),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.2,
                  ),
                )
              : const Text(
                  'Lưu giao dịch',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  String _formatDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }
}

class _SelectionRow extends StatelessWidget {
  final String icon;
  final String categoryName;
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectionRow({
    required this.icon,
    required this.categoryName,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.input,
      child: InkWell(
        borderRadius: AppRadius.input,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: AppRadius.input,
          ),
          child: Row(
            children: [
              CategoryIconBadge(
                icon: icon,
                categoryName: categoryName,
                color: color,
                size: 42,
                isDark: isDark,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(label,
                    style: AppTypography.body.copyWith(color: primaryTextColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (selected)
                const Icon(Icons.check, size: 20, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
