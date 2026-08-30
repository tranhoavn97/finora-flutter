import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/glass_widgets.dart';
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

/// Full-screen form to create or edit a transaction with modern soft UI.
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

  late String
      _type; // 'expense' | 'income' | 'transfer' | 'credit_card_payment' | 'investment'
  late int _date;

  Wallet? _wallet;
  Wallet? _fromWallet;
  Wallet? _toWallet;
  Category? _category;
  bool _isSaving = false;

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

    WidgetsBinding.instance.addPostFrameCallback((_) => _initSelections());
  }

  void _onAmountChanged() {
    setState(() {});
  }

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

      if (_type == 'credit_card_payment') {
        final card =
            _findWallet(wallets, e?.creditCardId ?? e?.toWalletId ?? initWId);
        _toWallet = (card != null && card.isCreditCard)
            ? card
            : (wallets.where((w) => w.isCreditCard).isNotEmpty
                ? wallets.firstWhere((w) => w.isCreditCard)
                : null);
        _fromWallet = _findWallet(wallets, e?.fromWalletId) ??
            (wallets.where((w) => !w.isCreditCard).isNotEmpty
                ? wallets.firstWhere((w) => !w.isCreditCard)
                : null);
      } else {
        _fromWallet = _findWallet(wallets, e?.fromWalletId ?? initWId) ??
            (wallets.isNotEmpty ? wallets.first : null);
        _toWallet = _findWallet(wallets, e?.toWalletId) ??
            (wallets.length > 1
                ? wallets[1]
                : (wallets.isNotEmpty ? wallets.first : null));
      }
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
    HapticFeedback.selectionClick();
    final provider = context.read<TransactionProvider>();
    final wallets = provider.wallets;
    setState(() {
      _type = type;
      if (type == 'credit_card_payment') {
        if (_fromWallet == null || _fromWallet!.isCreditCard) {
          _fromWallet = wallets.where((w) => !w.isCreditCard).isNotEmpty
              ? wallets.firstWhere((w) => !w.isCreditCard)
              : null;
        }
        if (_toWallet == null || !_toWallet!.isCreditCard) {
          _toWallet = wallets.where((w) => w.isCreditCard).isNotEmpty
              ? wallets.firstWhere((w) => w.isCreditCard)
              : null;
        }
      } else if (type != 'transfer') {
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

    final c = context.fc;
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
                .where((item) =>
                    item.name.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return GlassBottomSheet(
              radius: 30,
              child: SafeArea(
                top: false,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(sheetContext).size.height * 0.72,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chọn danh mục',
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FinoraTextField(
                        controller: searchController,
                        hint: 'Tìm danh mục...',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.primary, size: 20),
                        radius: 20,
                        onChanged: (val) {
                          setStateSheet(() {
                            searchQuery = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: filtered.isEmpty
                            ? Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 24),
                                  child: Text(
                                    'Không tìm thấy danh mục nào',
                                    style: TextStyle(color: c.textSecondary),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (_, i) {
                                  final item = filtered[i];
                                  final selected = item.id == _category?.id ||
                                      item.name == _category?.name;
                                  return _SelectionRow(
                                    icon: CategoryIconHelper.resolveIcon(
                                        item.icon),
                                    label: item.name,
                                    selected: selected,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
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

  void _pickWallet(void Function(Wallet) onSelected,
      {Wallet? current,
      String title = 'Chọn ví',
      bool Function(Wallet)? filter}) {
    final provider = context.read<TransactionProvider>();
    final rawWallets = provider.wallets;
    final filtered =
        filter != null ? rawWallets.where(filter).toList() : rawWallets;
    final wallets = _sortWalletsByRecency(filtered, provider.transactions);
    final c = context.fc;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return GlassBottomSheet(
          radius: 30,
          child: SafeArea(
            top: false,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: wallets.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'Chưa có ví tài khoản nào',
                                style: TextStyle(color: c.textSecondary),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: wallets.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                            itemBuilder: (_, i) {
                              final w = wallets[i];
                              final selected = w.id == current?.id;

                              return GlassCard(
                                radius: 18,
                                highlighted: selected,
                                padding: const EdgeInsets.all(12),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  onSelected(w);
                                  Navigator.of(sheetContext).pop();
                                },
                                child: Row(
                                  children: [
                                    BankLogoView(
                                        bankCode: w.bankCode ?? w.type,
                                        size: 36),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            w.name,
                                            style: TextStyle(
                                              color: c.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${w.isCreditCard ? "Thẻ tín dụng" : (w.type == "bank" ? "Tài khoản" : "Tiền mặt")} • ${w.ownerName}',
                                            style: TextStyle(
                                              color: c.textSecondary,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          w.isCreditCard
                                              ? formatVND(
                                                  w.creditLimit - w.currentDebt)
                                              : formatVND(w.balance),
                                          style: TextStyle(
                                            color: w.isCreditCard
                                                ? AppColors.error
                                                : AppColors.success,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        Text(
                                          w.isCreditCard ? 'Khả dụng' : 'Số dư',
                                          style: TextStyle(
                                            color: c.textTertiary,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (selected) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.check_circle_rounded,
                                          size: 20, color: AppColors.primary),
                                    ],
                                  ],
                                ),
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
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(digits) ?? 0;
    if (amount <= 0) return;

    setState(() => _isSaving = true);

    final note = _noteController.text.trim();
    final TransactionModel tx;

    final oldTags = widget.existing?.tags ?? <String>[];
    final cleanTags = oldTags
        .where((t) => t != 'Chồng' && t != 'Vợ' && t != 'Chung')
        .toList();
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
        owner: _fromWallet?.owner,
        ownerName: _fromWallet?.ownerName,
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
        creditCardName: _toWallet?.name,
        paidByOwner: _fromWallet?.owner,
        cardOwner: _toWallet?.owner,
        fromOwner: _fromWallet?.owner,
        toOwner: _toWallet?.owner,
        owner: _fromWallet?.owner,
        ownerName: _fromWallet?.ownerName,
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
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
    final dateLabel = _formatDate(_date);

    final wallets = provider.wallets;
    if (_wallet == null && wallets.isNotEmpty) {
      _wallet =
          _findWallet(wallets, widget.existing?.walletId) ?? wallets.first;
    }
    if (_fromWallet == null && wallets.isNotEmpty) {
      if (_type == 'credit_card_payment') {
        _fromWallet = _findWallet(wallets, widget.existing?.fromWalletId) ??
            (wallets.where((w) => !w.isCreditCard).isNotEmpty
                ? wallets.firstWhere((w) => !w.isCreditCard)
                : wallets.first);
      } else {
        _fromWallet = _findWallet(wallets, widget.existing?.fromWalletId) ??
            wallets.first;
      }
    }
    if (_toWallet == null && wallets.isNotEmpty) {
      if (_type == 'credit_card_payment') {
        _toWallet = _findWallet(wallets,
                widget.existing?.creditCardId ?? widget.existing?.toWalletId) ??
            (wallets.where((w) => w.isCreditCard).isNotEmpty
                ? wallets.firstWhere((w) => w.isCreditCard)
                : (wallets.length > 1 ? wallets[1] : wallets.first));
      } else {
        _toWallet = _findWallet(wallets, widget.existing?.toWalletId) ??
            (wallets.length > 1 ? wallets[1] : wallets.first);
      }
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
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
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
                  const SizedBox(height: 24),

                  // Amount Card
                  GlassCard(
                    radius: 24,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Overline('SỐ TIỀN GIAO DỊCH'),
                        const SizedBox(height: 10),
                        FinoraTextField(
                          controller: _amountController,
                          hint: '0 ₫',
                          keyboardType: TextInputType.number,
                          inputFormatters: [DotSeparatorTextInputFormatter()],
                          autofocus: widget.existing == null,
                          radius: 16,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Details Card
                  GlassCard(
                    radius: 24,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_type != 'transfer' &&
                            _type != 'credit_card_payment') ...[
                          const Overline('DANH MỤC'),
                          const SizedBox(height: 6),
                          _InteractiveRow(
                            emoji:
                                CategoryIconHelper.resolveIcon(_category?.icon),
                            value: _category?.name ?? 'Chưa chọn',
                            onTap: _pickCategory,
                          ),
                          const SizedBox(height: 14),
                          const Overline('VÍ THANH TOÁN'),
                          const SizedBox(height: 6),
                          _InteractiveRow(
                            bankCode: _wallet?.bankCode ?? _wallet?.type,
                            value: _wallet?.name ?? 'Chưa chọn',
                            trailingText: _wallet != null
                                ? (_wallet!.isCreditCard
                                    ? formatVND(_wallet!.creditLimit -
                                        _wallet!.currentDebt)
                                    : formatVND(_wallet!.balance))
                                : null,
                            onTap: () => _pickWallet(
                              (w) => setState(() => _wallet = w),
                              current: _wallet,
                              title: 'Chọn ví thanh toán',
                            ),
                          ),
                        ] else ...[
                          const Overline('VÍ NGUỒN (CHUYỂN ĐI)'),
                          const SizedBox(height: 6),
                          _InteractiveRow(
                            bankCode:
                                _fromWallet?.bankCode ?? _fromWallet?.type,
                            value: _fromWallet?.name ?? 'Chưa chọn',
                            trailingText: _fromWallet != null
                                ? (_fromWallet!.isCreditCard
                                    ? formatVND(_fromWallet!.creditLimit -
                                        _fromWallet!.currentDebt)
                                    : formatVND(_fromWallet!.balance))
                                : null,
                            onTap: () => _pickWallet(
                              (w) => setState(() => _fromWallet = w),
                              current: _fromWallet,
                              title: 'Chọn ví nguồn',
                              filter: _type == 'credit_card_payment'
                                  ? (w) => !w.isCreditCard
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Overline(_type == 'credit_card_payment'
                              ? 'THẺ NHẬN (THANH TOÁN)'
                              : 'VÍ NHẬN (CHUYỂN ĐẾN)'),
                          const SizedBox(height: 6),
                          _InteractiveRow(
                            bankCode: _toWallet?.bankCode ?? _toWallet?.type,
                            value: _toWallet?.name ?? 'Chưa chọn',
                            trailingText: _toWallet != null
                                ? (_toWallet!.isCreditCard
                                    ? formatVND(_toWallet!.creditLimit -
                                        _toWallet!.currentDebt)
                                    : formatVND(_toWallet!.balance))
                                : null,
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
                        const SizedBox(height: 14),
                        const Overline('NGÀY GIAO DỊCH'),
                        const SizedBox(height: 6),
                        _InteractiveRow(
                          icon: Icons.calendar_today_rounded,
                          value: dateLabel,
                          onTap: _pickDate,
                        ),
                        const SizedBox(height: 14),
                        const Overline('GHI CHÚ'),
                        const SizedBox(height: 6),
                        FinoraTextField(
                          controller: _noteController,
                          hint: 'Mô tả chi tiết giao dịch...',
                          radius: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              child: PrimaryButton(
                expand: true,
                onPressed: _isValid() ? _save : null,
                isLoading: _isSaving,
                child: const Text(
                  'Lưu giao dịch',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
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

class _InteractiveRow extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final String? bankCode;
  final String value;
  final VoidCallback onTap;
  final String? trailingText;

  const _InteractiveRow({
    this.icon,
    this.emoji,
    this.bankCode,
    required this.value,
    required this.onTap,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark
          ? AppColors.darkSurfaceElevated
          : AppColors.lightSurfaceElevated,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              if (bankCode != null) ...[
                BankLogoView(bankCode: bankCode, size: 28),
              ] else if (emoji != null) ...[
                Text(emoji!, style: const TextStyle(fontSize: 20)),
              ] else if (icon != null) ...[
                Icon(icon, color: AppColors.primary, size: 20),
              ],
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailingText != null) ...[
                Text(
                  trailingText!,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: c.textTertiary,
              ),
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
    final c = context.fc;

    return GlassCard(
      radius: 18,
      highlighted: selected,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle_rounded,
                size: 20, color: AppColors.primary),
        ],
      ),
    );
  }
}
