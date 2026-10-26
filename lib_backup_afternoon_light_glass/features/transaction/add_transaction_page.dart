import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../state/transaction_provider.dart';

/// Full-screen form to create or edit a transaction.
/// Mirrors the Kotlin AddTransactionDialog: expense / income / transfer modes.
class AddTransactionPage extends StatefulWidget {
  final String userId;
  final TransactionModel? existing;
  final String? initialType;
  final String? initialWalletId;
  const AddTransactionPage({
    super.key,
    required this.userId,
    this.existing,
    this.initialType,
    this.initialWalletId,
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late String _type; // 'expense' | 'income' | 'transfer'
  late int _date;

  Wallet? _wallet;
  Wallet? _fromWallet;
  Wallet? _toWallet;
  Category? _category;
  bool _isSaving = false;
  bool _saveDelayed = false;

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
        text: (e != null && e.amount > 0) ? _formatInitialAmount(e.amount) : '');
    _noteController = TextEditingController(text: e?.note ?? '');

    // Load the provider so wallets and categories are fetched from Firestore
    context.read<TransactionProvider>().load(widget.userId);
    _amountController.addListener(_onAmountChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) => _initSelections());
  }

  void _onAmountChanged() {
    setState(() {});
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
      _toWallet = _findWallet(wallets, e?.toWalletId ?? initWId) ??
          (wallets.length > 1 ? wallets[1] : (wallets.isNotEmpty ? wallets.first : null));
      _category = _resolveCategory(provider, _type, e);
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
      if (tx.walletId != null && tx.walletId!.isNotEmpty && !recency.containsKey(tx.walletId!)) {
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
      if (tx.type == type && tx.categoryId != null && tx.categoryId!.isNotEmpty) {
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
    final lastUsed = _findLastUsedCategory(provider, type);
    if (lastUsed != null) return lastUsed;
    return cats.first;
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
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
        _date = DateTime(picked.year, picked.month, picked.day,
                current.hour, current.minute)
            .millisecondsSinceEpoch;
      });
    }
  }

  void _pickCategory() {
    final provider = context.read<TransactionProvider>();
    final rawCats = _categoriesFor(provider, _type);
    final cats = _sortCategoriesByRecency(rawCats, provider.transactions);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final filtered = cats
                .where((c) => c.name.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return GlassBottomSheet(
              radius: 32,
              child: SafeArea(
                top: false,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
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
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text('Chọn danh mục',
                          style: AppTypography.subhead.copyWith(color: primaryTextColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSpacing.md),
                      FinoraTextField(
                        controller: searchController,
                        hint: 'Tìm kiếm danh mục...',
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
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Text('Không tìm thấy danh mục nào',
                                    style: AppTypography.caption2
                                        .copyWith(color: secondaryTextColor)),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: AppSpacing.xs),
                                itemBuilder: (_, i) {
                                  final item = filtered[i];
                                  final selected = item.id == _category?.id || item.name == _category?.name;
                                  return _SelectionRow(
                                    icon: CategoryIconHelper.resolveIcon(item.icon),
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
            );
          },
        );
      },
    ).then((_) {
      searchController.dispose();
    });
  }

  void _pickWallet(void Function(Wallet) onSelected, {Wallet? current, String title = 'Chọn ví', bool Function(Wallet)? filter}) {
    final provider = context.read<TransactionProvider>();
    final rawWallets = provider.wallets;
    final filtered = filter != null ? rawWallets.where(filter).toList() : rawWallets;
    final wallets = _sortWalletsByRecency(filtered, provider.transactions);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return GlassBottomSheet(
          radius: 32,
          child: SafeArea(
            top: false,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
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
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(title,
                      style: AppTypography.subhead.copyWith(color: primaryTextColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.md),
                  Flexible(
                    child: wallets.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text('Chưa có ví tài khoản nào',
                                style: AppTypography.caption2
                                    .copyWith(color: secondaryTextColor)),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: wallets.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.xs),
                            itemBuilder: (_, i) {
                              final w = wallets[i];
                              final selected = w.id == current?.id;
                              final hasBank = w.bankCode != null;
                              final balanceText = w.isCreditCard
                                  ? 'Khả dụng: ${formatVND(w.creditLimit - w.currentDebt)}'
                                  : formatVND(w.balance);

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
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.accent.withOpacity(0.12)
                                          : Colors.transparent,
                                      borderRadius: AppRadius.input,
                                    ),
                                    child: Row(
                                      children: [
                                        if (hasBank || w.type == 'ewallet')
                                          BankIcon(bankCode: w.bankCode ?? w.type, size: 32)
                                        else
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFFE0F2FE),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              w.isCreditCard ? '💳' : '💵',
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                          ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                w.name,
                                                style: AppTypography.body.copyWith(
                                                  color: primaryTextColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${w.isCreditCard ? "Thẻ tín dụng" : (w.type == "bank" ? "Tài khoản" : "Tiền mặt")} • ${w.ownerName}',
                                                style: AppTypography.caption2.copyWith(
                                                  color: secondaryTextColor,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              w.isCreditCard
                                                  ? formatVND(w.creditLimit - w.currentDebt)
                                                  : formatVND(w.balance),
                                              style: AppTypography.body.copyWith(
                                                color: w.isCreditCard ? const Color(0xFFF87171) : const Color(0xFF34D399),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              w.isCreditCard ? 'Khả dụng' : 'Số dư',
                                              style: AppTypography.caption2.copyWith(
                                                color: secondaryTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (selected) ...[
                                          const SizedBox(width: 8),
                                          const Icon(Icons.check, size: 20, color: AppColors.accent),
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
        );
      },
    );
  }

  void _showSelectionSheet<T>({
    required String title,
    required List<T> items,
    required bool Function(T) isSelected,
    required String Function(T) iconOf,
    required String Function(T) labelOf,
    required void Function(T) onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return GlassBottomSheet(
          radius: 32,
          child: SafeArea(
            top: false,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
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
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(title,
                      style: AppTypography.subhead.copyWith(color: primaryTextColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.md),
                  Flexible(
                    child: items.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text('Chưa có lựa chọn',
                                style: AppTypography.caption2
                                    .copyWith(color: secondaryTextColor)),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.xs),
                            itemBuilder: (_, i) {
                              final item = items[i];
                              return _SelectionRow(
                                icon: iconOf(item),
                                label: labelOf(item),
                                selected: isSelected(item),
                                onTap: () {
                                  onSelected(item);
                                  Navigator.of(sheetContext).pop();
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(digits) ?? 0;
    if (amount <= 0) return;

    setState(() {
      _isSaving = true;
      _saveDelayed = false;
    });
    final saveTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && _isSaving) setState(() => _saveDelayed = true);
    });

    final note = _noteController.text.trim();
    final TransactionModel tx;

    final oldTags = widget.existing?.tags ?? <String>[];
    final cleanTags = oldTags.where((t) => t != 'Chồng' && t != 'Vợ').toList();
    final String ownerName;
    if (_type == 'transfer' || _type == 'credit_card_payment') {
      ownerName = _fromWallet?.ownerName ?? 'Chồng';
    } else {
      ownerName = _wallet?.ownerName ?? 'Chồng';
    }
    final txTags = {...cleanTags, ownerName}.toList();

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
        categoryGroup: _type,
        investmentSubtype: _type == 'investment' ? 'simple_asset' : null,
        investmentAction: _type == 'investment' ? 'buy' : null,
        assetName: _type == 'investment'
            ? (note.isEmpty ? (_category?.name ?? 'Tài sản đầu tư') : note)
            : null,
        tags: txTags,
      );
    }

    final provider = context.read<TransactionProvider>();
    final existing = widget.existing;
    try {
      if (existing != null) {
        await provider.updateTransaction(widget.userId, existing.id,
            tx.copyWith(id: existing.id, userId: widget.userId));
      } else {
        await provider.createTransaction(
            widget.userId, tx.copyWith(userId: widget.userId));
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        final message = e is TimeoutException
            ? 'Không kết nối được máy chủ. Chưa gửi giao dịch; kiểm tra mạng rồi thử lại.'
            : e is FirebaseException && e.code == 'permission-denied'
                ? 'Bạn không có quyền lưu giao dịch này. Vui lòng kiểm tra tài khoản.'
                : 'Không lưu được giao dịch. Nội dung đã nhập vẫn được giữ lại.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      saveTimer.cancel();
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _isValid() {
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(digits) ?? 0;
    if (amount <= 0 || _isSaving) return false;
    if (_type == 'transfer' || _type == 'credit_card_payment') {
      return _fromWallet != null && _toWallet != null && _fromWallet?.id != _toWallet?.id;
    } else {
      return _wallet != null && _category != null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch so wallet/category selections rebuild as provider data streams in.
    final provider = context.watch<TransactionProvider>();
    final dateLabel = _formatDate(_date);

    // Auto-select defaults when provider loads data
    final wallets = provider.wallets;
    if (_wallet == null && wallets.isNotEmpty) {
      _wallet = _findWallet(wallets, widget.existing?.walletId) ?? wallets.first;
    }
    if (_fromWallet == null && wallets.isNotEmpty) {
      _fromWallet = _findWallet(wallets, widget.existing?.fromWalletId) ?? wallets.first;
    }
    if (_toWallet == null && wallets.isNotEmpty) {
      _toWallet = _findWallet(wallets, widget.existing?.toWalletId) ??
          (wallets.length > 1 ? wallets[1] : wallets.first);
    }
    if (_category == null) {
      _category = _resolveCategory(provider, _type, widget.existing);
    }

    return GlassScaffold(
      appBar: GlassTopBar(
        title:
            widget.existing == null ? 'Thêm giao dịch' : 'Chỉnh sửa giao dịch',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
                children: [
                  // Type segmented control
                  SegmentedControl(
                    options: const [
                      ('expense', 'Chi tiêu'),
                      ('income', 'Thu nhập'),
                      ('transfer', 'Chuyển'),
                      ('credit_card_payment', 'Trả thẻ'),
                      ('investment', 'Đầu tư'),
                    ],
                    selected: _type,
                    onChanged: _onTypeChanged,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Amount
                  const _FieldLabel('Số tiền'),
                  const SizedBox(height: AppSpacing.xs),
                  GlassTextField(
                    controller: _amountController,
                    hint: '0 ₫',
                    keyboardType: TextInputType.number,
                    inputFormatters: [DotSeparatorTextInputFormatter()],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (_type != 'transfer' && _type != 'credit_card_payment') ...[
                    const _FieldLabel('Danh mục'),
                    const SizedBox(height: AppSpacing.xs),
                    _InteractiveRow(
                      icon: CategoryIconHelper.resolveIcon(_category?.icon),
                      value: _category?.name ?? 'Chưa chọn',
                      onTap: _pickCategory,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _FieldLabel('Ví tiền'),
                    const SizedBox(height: AppSpacing.xs),
                    _InteractiveRow(
                      leadingIconWidget: _wallet != null && (_wallet!.bankCode != null || _wallet!.type == 'ewallet')
                          ? BankIcon(bankCode: _wallet!.bankCode ?? _wallet!.type, size: 24)
                          : null,
                      icon: _wallet != null ? (_wallet!.isCreditCard ? '💳' : (_wallet!.type == 'bank' ? '🏦' : '💵')) : '💵',
                      value: _wallet?.name ?? 'Chưa chọn',
                      trailingText: _wallet != null
                          ? (_wallet!.isCreditCard ? formatVND(_wallet!.creditLimit - _wallet!.currentDebt) : formatVND(_wallet!.balance))
                          : null,
                      onTap: () => _pickWallet(
                        (w) => setState(() => _wallet = w),
                        current: _wallet,
                        title: 'Chọn ví',
                      ),
                    ),
                  ] else ...[
                    const _FieldLabel('Ví nguồn'),
                    const SizedBox(height: AppSpacing.xs),
                    _InteractiveRow(
                      leadingIconWidget: _fromWallet != null && (_fromWallet!.bankCode != null || _fromWallet!.type == 'ewallet')
                          ? BankIcon(bankCode: _fromWallet!.bankCode ?? _fromWallet!.type, size: 24)
                          : null,
                      icon: _fromWallet != null ? (_fromWallet!.isCreditCard ? '💳' : (_fromWallet!.type == 'bank' ? '🏦' : '💵')) : '💵',
                      value: _fromWallet?.name ?? 'Chưa chọn',
                      trailingText: _fromWallet != null
                          ? (_fromWallet!.isCreditCard ? formatVND(_fromWallet!.creditLimit - _fromWallet!.currentDebt) : formatVND(_fromWallet!.balance))
                          : null,
                      onTap: () => _pickWallet(
                        (w) => setState(() => _fromWallet = w),
                        current: _fromWallet,
                        title: 'Chọn ví nguồn',
                        filter: _type == 'credit_card_payment' ? (w) => !w.isCreditCard : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FieldLabel(_type == 'credit_card_payment' ? 'Thẻ nhận' : 'Ví nhận'),
                    const SizedBox(height: AppSpacing.xs),
                    _InteractiveRow(
                      leadingIconWidget: _toWallet != null && (_toWallet!.bankCode != null || _toWallet!.type == 'ewallet')
                          ? BankIcon(bankCode: _toWallet!.bankCode ?? _toWallet!.type, size: 24)
                          : null,
                      icon: _toWallet != null ? (_toWallet!.isCreditCard ? '💳' : (_toWallet!.type == 'bank' ? '🏦' : '💵')) : '💵',
                      value: _toWallet?.name ?? 'Chưa chọn',
                      trailingText: _toWallet != null
                          ? (_toWallet!.isCreditCard ? formatVND(_toWallet!.creditLimit - _toWallet!.currentDebt) : formatVND(_toWallet!.balance))
                          : null,
                      onTap: () => _pickWallet(
                        (w) => setState(() => _toWallet = w),
                        current: _toWallet,
                        title: _type == 'credit_card_payment' ? 'Chọn thẻ nhận' : 'Chọn ví nhận',
                        filter: _type == 'credit_card_payment' ? (w) => w.isCreditCard : null,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),

                  const _FieldLabel('Ngày'),
                  const SizedBox(height: AppSpacing.xs),
                  _InteractiveRow(
                    icon: '📅',
                    value: dateLabel,
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  const _FieldLabel('Ghi chú'),
                  const SizedBox(height: AppSpacing.xs),
                  GlassTextField(
                    controller: _noteController,
                    hint: 'Mô tả giao dịch...',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
              child: PrimaryButton(
                expand: true,
                onPressed: _isValid() ? _save : null,
                child: _saveDelayed && _isSaving
                    ? const Text(
                        'Đang chờ máy chủ xác nhận. Không gửi lại giao dịch.',
                        textAlign: TextAlign.center,
                      )
                    : _isSaving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Lưu giao dịch',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Text(text,
        style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold));
  }
}

/// Tappable row showing an emoji + value, used to open a selection sheet.
class _InteractiveRow extends StatelessWidget {
  final String icon;
  final String value;
  final VoidCallback onTap;
  final Widget? leadingIconWidget;
  final String? trailingText;
  const _InteractiveRow({
    required this.icon,
    required this.value,
    required this.onTap,
    this.leadingIconWidget,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.input,
      child: InkWell(
        borderRadius: AppRadius.input,
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: AppRadius.input,
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1),
          ),
          child: Row(
            children: [
              if (leadingIconWidget != null) ...[
                leadingIconWidget!,
              ] else ...[
                Text(icon, style: const TextStyle(fontSize: 20)),
              ],
              const SizedBox(width: 12),
              Expanded(
                child: Text(value,
                    style: AppTypography.body.copyWith(color: primaryTextColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (trailingText != null) ...[
                Text(
                  trailingText!,
                  style: TextStyle(
                    color: trailingText!.contains('-') ? const Color(0xFFF87171) : const Color(0xFF34D399),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: secondaryTextColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionRow extends StatelessWidget {
  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SelectionRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.input,
      child: InkWell(
        borderRadius: AppRadius.input,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: AppRadius.input,
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
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
