import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/search.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../core/theme/finora_tokens.dart';
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
  String? _merchantId;
  String? _merchantName;
  String? _creatorTag;
  String? _creatorUid;
  String? _creatorName;
  bool _isSaving = false;
  String? _pendingTransactionId;
  Set<String> _deletedMerchantKeys = {};

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

  Future<void> _loadDeletedMerchants() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list =
          prefs.getStringList('finora_deleted_merchants_${widget.userId}') ?? [];
      if (mounted) {
        setState(() {
          _deletedMerchantKeys = list.map((e) => e.toLowerCase()).toSet();
        });
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? widget.initialType ?? 'expense';
    _date = e?.date ?? DateTime.now().millisecondsSinceEpoch;
    _merchantId = e?.merchantId;
    _merchantName = e?.merchantName;
    _amountController = TextEditingController(
        text:
            (e != null && e.amount > 0) ? _formatInitialAmount(e.amount) : '');
    _noteController = TextEditingController(text: e?.note ?? '');

    _loadDeletedMerchants();
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
          _findWalletByName(wallets, e?.walletName) ??
          _findLastUsedWallet(provider) ??
          (wallets.isNotEmpty ? wallets.first : null);
      _fromWallet = _findWallet(wallets, e?.fromWalletId ?? initWId) ??
          _findWalletByName(wallets, e?.fromWalletName) ??
          (wallets.isNotEmpty ? wallets.first : null);
      _toWallet = _findWallet(
              wallets, e?.toWalletId ?? widget.initialToWalletId ?? initWId) ??
          _findWalletByName(wallets, e?.toWalletName) ??
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

  Wallet? _findWalletByName(List<Wallet> wallets, String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final target = name.trim().toLowerCase();
    for (final w in wallets) {
      if (w.name.trim().toLowerCase() == target) return w;
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

  Color get _activeTypeAccentColor {
    switch (_type) {
      case 'expense':
        return const Color(0xFFE11D48);
      case 'income':
        return const Color(0xFF10B981);
      case 'transfer':
        return const Color(0xFF0284C7);
      case 'credit_card_payment':
      case 'debt':
      case 'loan':
        return const Color(0xFFD97706);
      case 'investment':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF0F6E56);
    }
  }


  String _inferBankCodeForWallet(Wallet w) {
    final raw = w.bankCode?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    final combined = '${w.bankName ?? ''} ${w.name}'.toLowerCase();
    if (combined.contains('mb') ||
        combined.contains('tiết kiệm') ||
        combined.contains('tiet kiem')) {
      return 'mbbank';
    }
    if (combined.contains('techcom') || combined.contains('tcb')) {
      return 'tcb';
    }
    if (combined.contains('vietcom') || combined.contains('vcb')) {
      return 'vcb';
    }
    if (combined.contains('tiền mặt') || combined.contains('tien mat')) {
      return 'cash';
    }
    return w.type;
  }

  Future<void> _pickDate() async {
    final current = DateTime.fromMillisecondsSinceEpoch(_date);
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DateAndTimePickerSheet(
        initialDateTime: current,
        accentColor: _activeTypeAccentColor,
      ),
    );
    if (picked != null) {
      setState(() {
        _date = picked.millisecondsSinceEpoch;
      });
    }
  }

  void _pickCategory() => _showCategorySearchModal();

  void _showCategorySearchModal() {
    final provider = context.read<TransactionProvider>();
    final rawCats = _categoriesFor(provider, _type);
    final cats = _sortCategoriesByRecency(rawCats, provider.transactions);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = _activeTypeAccentColor;

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
                      maxHeight: MediaQuery.of(sheetContext).size.height * 0.78,
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Chọn danh mục',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: primaryTextColor,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Phân loại khoản ${_type == 'income' ? 'thu nhập' : 'chi tiêu'} chính xác',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.of(sheetContext).pop(),
                              borderRadius: BorderRadius.circular(100),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFF1F5F9),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
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
                        const SizedBox(height: 12),
                        Flexible(
                          child: filtered.isEmpty
                              ? Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 28),
                                  child: Center(
                                    child: Text(
                                      'Không tìm thấy danh mục nào',
                                      style: AppTypography.caption2.copyWith(
                                        color: secondaryTextColor,
                                      ),
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
                                      icon: item.icon,
                                      categoryName: item.name,
                                      color: BankIconRegistry.parseThemeColor(
                                          item.color),
                                      label: item.name,
                                      selected: selected,
                                      accentColor: accent,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _category = item);
                                        Navigator.of(sheetContext).pop();
                                      },
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 10),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(sheetContext).pop(),
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const Text(
                                'Xong',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
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

  void _selectWallet(
    void Function(Wallet) onSelected, {
    Wallet? current,
    String title = 'Chọn ví',
    bool Function(Wallet)? filter,
  }) =>
      _pickWallet(
        onSelected,
        current: current,
        title: title,
        filter: filter,
      );

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
    final accent = _activeTypeAccentColor;

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
                      maxHeight: MediaQuery.of(sheetContext).size.height * 0.78,
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: primaryTextColor,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Chọn nguồn tiền thanh toán hoặc nhận tiền',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.of(sheetContext).pop(),
                              borderRadius: BorderRadius.circular(100),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFF1F5F9),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
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
                        const SizedBox(height: 12),
                        Flexible(
                          child: displayedWallets.isEmpty
                              ? Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 28),
                                  child: Center(
                                    child: Text(
                                      'Không tìm thấy ví nào',
                                      style: AppTypography.caption2.copyWith(
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: displayedWallets.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 6),
                                  itemBuilder: (_, i) {
                                    final w = displayedWallets[i];
                                    final selected = w.id == current?.id;
                                    final bankCode = _inferBankCodeForWallet(w);
                                    final ownerIsWife =
                                        w.owner.toLowerCase() == 'wife' ||
                                            w.ownerName
                                                .toLowerCase()
                                                .contains('vợ');

                                    return Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(18),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          onSelected(w);
                                          Navigator.of(sheetContext).pop();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? accent.withValues(
                                                    alpha: isDark ? 0.18 : 0.10)
                                                : (isDark
                                                    ? Colors.white.withValues(
                                                        alpha: 0.03)
                                                    : const Color(0xFFF8FAFC)),
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            border: Border.all(
                                              color: selected
                                                  ? accent
                                                  : (isDark
                                                      ? Colors.white10
                                                      : const Color(
                                                          0xFFE2E8F0)),
                                              width: selected ? 1.4 : 1.0,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              BankIcon(
                                                bankCode: bankCode,
                                                bankName: w.bankName ?? w.name,
                                                size: 38,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      w.name,
                                                      style: TextStyle(
                                                        fontSize: 14.5,
                                                        color: primaryTextColor,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Row(
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            w.isCreditCard
                                                                ? 'Thẻ tín dụng'
                                                                : (w.type ==
                                                                        'bank'
                                                                    ? 'Ngân hàng'
                                                                    : 'Tiền mặt'),
                                                            style: TextStyle(
                                                              fontSize: 11.5,
                                                              color:
                                                                  secondaryTextColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 6,
                                                            vertical: 1.5,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: ownerIsWife
                                                                ? (isDark
                                                                    ? const Color(
                                                                        0xFF500724)
                                                                    : const Color(
                                                                        0xFFFCE7F3))
                                                                : (isDark
                                                                    ? const Color(
                                                                        0xFF082F49)
                                                                    : const Color(
                                                                        0xFFE0F2FE)),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        100),
                                                          ),
                                                          child: Text(
                                                            ownerIsWife
                                                                ? 'Vợ'
                                                                : 'Chồng',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              color: ownerIsWife
                                                                  ? const Color(
                                                                      0xFFDB2777)
                                                                  : const Color(
                                                                      0xFF0284C7),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                        maxWidth: 112),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      alignment:
                                                          Alignment.centerRight,
                                                      child: Text(
                                                        w.isCreditCard
                                                            ? Formatters
                                                                .formatCurrency(w
                                                                        .creditLimit -
                                                                    w.currentDebt)
                                                            : Formatters
                                                                .formatCurrency(
                                                                    w.balance),
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: w.isCreditCard
                                                              ? const Color(
                                                                  0xFFE11D48)
                                                              : const Color(
                                                                  0xFF0F6E56),
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      w.isCreditCard
                                                          ? 'Khả dụng'
                                                          : 'Số dư',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            secondaryTextColor,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (selected) ...[
                                                const SizedBox(width: 8),
                                                Icon(
                                                  Icons.check_circle_rounded,
                                                  size: 20,
                                                  color: accent,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 10),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(sheetContext).pop(),
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const Text(
                                'Đóng',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
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

    final provider = context.read<TransactionProvider>();
    final wallets = provider.wallets;

    if (_type == 'transfer') {
      final fromW = _fromWallet ?? (wallets.isNotEmpty ? wallets.first : null);
      final toW = _toWallet ??
          (wallets.length > 1
              ? wallets[1]
              : (wallets.isNotEmpty ? wallets.first : null));
      tx = TransactionModel(
        amount: amount,
        type: 'transfer',
        date: _date,
        note: note.isEmpty ? null : note,
        walletId: fromW?.id,
        walletName: fromW?.name,
        fromWalletId: fromW?.id,
        fromWalletName: fromW?.name,
        toWalletId: toW?.id,
        toWalletName: toW?.name,
        fromOwner: fromW?.owner,
        toOwner: toW?.owner,
        categoryName: 'Chuyển tiền',
        categoryIcon: '🔄',
        categoryColor: '#6B7280',
        tags: txTags,
        creatorTag: activeTag,
        createdBy: activeUid,
        creatorName: activeName,
      );
    } else if (_type == 'credit_card_payment') {
      final fromW = _fromWallet ?? (wallets.isNotEmpty ? wallets.first : null);
      final toW = _toWallet ??
          (wallets.length > 1
              ? wallets[1]
              : (wallets.isNotEmpty ? wallets.first : null));
      tx = TransactionModel(
        amount: amount,
        type: 'credit_card_payment',
        date: _date,
        note: note.isEmpty ? null : note,
        walletId: fromW?.id,
        walletName: fromW?.name,
        fromWalletId: fromW?.id,
        fromWalletName: fromW?.name,
        toWalletId: toW?.id,
        toWalletName: toW?.name,
        creditCardId: toW?.id,
        fromOwner: fromW?.owner,
        toOwner: toW?.owner,
        categoryName: 'Thanh toán thẻ',
        categoryIcon: '💳',
        categoryColor: '#F59E0B',
        tags: txTags,
        creatorTag: activeTag,
        createdBy: activeUid,
        creatorName: activeName,
      );
    } else {
      final effectiveWallet =
          _wallet ?? (wallets.isNotEmpty ? wallets.first : null);
      tx = TransactionModel(
        amount: amount,
        type: _type,
        date: _date,
        note: note.isEmpty ? null : note,
        walletId: effectiveWallet?.id,
        walletName: effectiveWallet?.name,
        owner: effectiveWallet?.owner,
        ownerName: effectiveWallet?.ownerName,
        categoryId: _category?.id,
        categoryName: _category?.name,
        categoryIcon: _category?.icon,
        categoryColor: _category?.color,
        categoryGroup: _category?.categoryGroup ?? _type,
        merchantId: _merchantId,
        merchantName: _merchantName,
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
    _category ??= _resolveCategory(provider, _type, widget.existing);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientFloatingBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // Scrollable content underneath floating header and footer
              ListView(
                padding: const EdgeInsets.fromLTRB(12, 62, 12, 140),
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

              // Floating Frosted Glass Header with subtle blur
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildFloatingHeader(isDark),
              ),

              // Floating Frosted Glass Save Button with blur
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildSaveButton(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Minimalist Header matching Warm Paper & Ink
  Widget _buildFloatingHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: FinoraTokens.bg(isDark),
        border: Border(
          bottom: BorderSide(
            color: FinoraTokens.line(isDark),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const FinoraBackButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.existing == null ? 'Thêm giao dịch' : 'Chỉnh sửa giao dịch',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: FinoraTokens.ink(isDark),
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Segmented tabs in Warm Paper & Ink aesthetic
  Widget _buildTypeTabs(bool isDark) => _buildTypeSelector(isDark);

  Widget _buildTypeSelector(bool isDark) {
    const types = [
      'expense',
      'income',
      'transfer',
      'credit_card_payment',
      'investment',
    ];
    const labels = [
      'Chi tiêu',
      'Thu nhập',
      'Chuyển khoản',
      'Trả thẻ',
      'Đầu tư',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(types.length, (i) {
          final isSelected = _type == types[i];
          return Padding(
            padding: EdgeInsets.only(right: i < types.length - 1 ? 8 : 0),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                _onTypeChanged(types[i]);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? FinoraTokens.ink(isDark)
                      : FinoraTokens.surface(isDark),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? FinoraTokens.ink(isDark)
                        : FinoraTokens.line(isDark),
                    width: 1,
                  ),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? const Color(0xFF141518) : Colors.white)
                        : FinoraTokens.inkSecondary(isDark),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Card 1: SỐ TIỀN - Hero input centered with tabular figures
  Widget _buildAmountCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: FinoraTokens.surface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FinoraTokens.line(isDark),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'SỐ TIỀN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: FinoraTokens.inkSecondary(isDark),
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicWidth(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 100, maxWidth: 280),
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: const [DotSeparatorTextInputFormatter()],
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: FinoraTokens.ink(isDark),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: FinoraTokens.inkSecondary(isDark).withValues(alpha: 0.4),
                          fontFeatures: const [FontFeature.tabularFigures()],
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
                ),
                const SizedBox(width: 6),
                Text(
                  '₫',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: FinoraTokens.inkSecondary(isDark),
                  ),
                ),
              ],
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
    final accent = _activeTypeAccentColor;
    final currentDt = DateTime.fromMillisecondsSinceEpoch(_date);
    final nowDt = DateTime.now();
    final isToday = currentDt.year == nowDt.year &&
        currentDt.month == nowDt.month &&
        currentDt.day == nowDt.day;
    final yesterdayDt = nowDt.subtract(const Duration(days: 1));
    final isYesterday = currentDt.year == yesterdayDt.year &&
        currentDt.month == yesterdayDt.month &&
        currentDt.day == yesterdayDt.day;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FinoraTokens.surface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FinoraTokens.line(isDark),
          width: 1,
        ),
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
            leading: activeWallet != null
                ? BankIcon(
                    bankCode: _inferBankCodeForWallet(activeWallet),
                    bankName: activeWallet.bankName ?? activeWallet.name,
                    size: 32,
                  )
                : const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 24,
                    color: Color(0xFF0F6E56),
                  ),
            title: activeWallet?.name ?? 'Chưa chọn ví',
            subtitle: activeWallet != null
                ? '${activeWallet.bankName ?? (activeWallet.isCreditCard ? "Thẻ tín dụng" : "Ngân hàng")} • ${activeWallet.ownerName.isNotEmpty ? activeWallet.ownerName : "Chồng"}'
                : 'Chạm để chọn nguồn thanh toán',
            trailingText: activeWallet != null
                ? (activeWallet.isCreditCard
                    ? Formatters.formatCurrency(
                        activeWallet.creditLimit - activeWallet.currentDebt)
                    : Formatters.formatCurrency(activeWallet.balance))
                : null,
            trailingSubtitle: activeWallet != null
                ? (activeWallet.isCreditCard ? 'Hạn mức khả dụng' : 'Số dư hiện tại')
                : null,
            trailingColor: const Color(0xFF0F6E56),
            onTap: () => _selectWallet(
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
              leading: _toWallet != null
                  ? BankIcon(
                      bankCode: _inferBankCodeForWallet(_toWallet!),
                      bankName: _toWallet!.bankName ?? _toWallet!.name,
                      size: 32,
                    )
                  : const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 24,
                      color: Color(0xFF0284C7),
                    ),
              title: _toWallet?.name ?? 'Chưa chọn ví nhận',
              subtitle: _toWallet != null
                  ? '${_toWallet!.bankName ?? (_toWallet!.isCreditCard ? "Thẻ tín dụng" : "Ngân hàng")} • ${_toWallet!.ownerName.isNotEmpty ? _toWallet!.ownerName : "Chồng"}'
                  : 'Chạm để chọn tài khoản đích',
              trailingText: _toWallet != null
                  ? (_toWallet!.isCreditCard
                      ? Formatters.formatCurrency(
                          _toWallet!.creditLimit - _toWallet!.currentDebt)
                      : Formatters.formatCurrency(_toWallet!.balance))
                  : null,
              trailingSubtitle: _toWallet != null
                  ? (_toWallet!.isCreditCard ? 'Hạn mức khả dụng' : 'Số dư hiện tại')
                  : null,
              trailingColor: const Color(0xFF0F6E56),
              onTap: () => _selectWallet(
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

          // NGÀY & GIỜ GIAO DỊCH
          Row(
            children: [
              Expanded(
                child: Text(
                  'NGÀY & GIỜ GIAO DỊCH',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildQuickDateMiniPill(
                        label: 'Hôm nay',
                        selected: isToday,
                        accent: accent,
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          final now = DateTime.now();
                          setState(() {
                            _date = DateTime(
                              now.year,
                              now.month,
                              now.day,
                              currentDt.hour,
                              currentDt.minute,
                            ).millisecondsSinceEpoch;
                          });
                        },
                      ),
                      const SizedBox(width: 6),
                      _buildQuickDateMiniPill(
                        label: 'Hôm qua',
                        selected: isYesterday,
                        accent: accent,
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          final y =
                              DateTime.now().subtract(const Duration(days: 1));
                          setState(() {
                            _date = DateTime(
                              y.year,
                              y.month,
                              y.day,
                              currentDt.hour,
                              currentDt.minute,
                            ).millisecondsSinceEpoch;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInteractiveTile(
            isDark: isDark,
            leading: Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: accent,
            ),
            title: _formatDate(_date),
            trailingText: isToday
                ? 'Hôm nay'
                : (isYesterday ? 'Hôm qua' : null),
            trailingColor: accent,
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
            height: 48,
            decoration: BoxDecoration(
              color: FinoraTokens.bg(isDark),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: FinoraTokens.line(isDark),
                width: 1,
              ),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: const [FirstLetterUpperCaseFormatter()],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: FinoraTokens.ink(isDark),
              ),
              decoration: InputDecoration(
                hintText: 'Mô tả chi tiết giao dịch...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: FinoraTokens.inkSecondary(isDark),
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
                        color: const Color(0xFF0F6E56).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              const Color(0xFF0F6E56).withValues(alpha: 0.28),
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
                                    size: 14, color: Color(0xFF10B981)),
                                const SizedBox(width: 5),
                                Text(
                                  'Gợi ý danh mục: $suggestedName',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F6E56),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F6E56),
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
          if (_type == 'expense') ...[
            const SizedBox(height: 18),
            _buildMerchantSelector(isDark),
          ],
        ],
      ),
    );
  }

  void _autoSelectWalletForMerchant(String merchantId, String merchantName) {
    if (merchantId.isEmpty && merchantName.isEmpty) return;
    final txProv = context.read<TransactionProvider>();
    final wallets = txProv.wallets;
    if (wallets.isEmpty) return;

    // 1. Check historical transactions for this merchant
    final mKey = (merchantId.isNotEmpty ? merchantId : merchantName).toLowerCase();
    final counts = <String, int>{};
    for (final tx in txProv.transactions) {
      final tMid = (tx.merchantId ?? '').toLowerCase();
      final tMname = (tx.merchantName ?? '').toLowerCase();
      if ((tMid.isNotEmpty && tMid == mKey) || (tMname.isNotEmpty && tMname == mKey)) {
        if (tx.walletId != null && tx.walletId!.isNotEmpty) {
          counts[tx.walletId!] = (counts[tx.walletId!] ?? 0) + 1;
        }
      }
    }
    if (counts.isNotEmpty) {
      String? bestWId;
      int maxCount = -1;
      counts.forEach((wId, c) {
        if (c > maxCount) {
          maxCount = c;
          bestWId = wId;
        }
      });
      if (bestWId != null) {
        final found = wallets.where((w) => w.id == bestWId).firstOrNull;
        if (found != null && found.id != _wallet?.id) {
          setState(() {
            _wallet = found;
            _autoDetectSpenderFromWallet(found);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã chọn ví "${found.name}" theo thói quen mua tại $merchantName'),
              duration: const Duration(milliseconds: 1500),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }
    }

    // 2. Keyword heuristic fallback
    final nameLower = merchantName.toLowerCase();
    final idLower = merchantId.toLowerCase();
    Wallet? matched;
    if (nameLower.contains('shopee') || idLower.contains('shopee')) {
      matched = wallets.where((w) {
        final wn = w.name.toLowerCase();
        return wn.contains('shopee') || wn.contains('shopeepay');
      }).firstOrNull;
    } else if (nameLower.contains('momo') || idLower.contains('momo')) {
      matched = wallets.where((w) => w.name.toLowerCase().contains('momo')).firstOrNull;
    } else if (nameLower.contains('zalo') || idLower.contains('zalo')) {
      matched = wallets.where((w) {
        final wn = w.name.toLowerCase();
        return wn.contains('zalo') || wn.contains('zalopay');
      }).firstOrNull;
    } else if (nameLower.contains('grab') || idLower.contains('grab')) {
      matched = wallets.where((w) {
        final wn = w.name.toLowerCase();
        return wn.contains('grab') || wn.contains('moca');
      }).firstOrNull;
    } else if (nameLower.contains('winmart') || idLower.contains('winmart')) {
      matched = wallets.where((w) {
        final wn = w.name.toLowerCase();
        final wb = (w.bankName ?? '').toLowerCase();
        return wn.contains('techcombank') || wb.contains('techcombank') || wn.contains('tcb');
      }).firstOrNull;
    }

    if (matched != null && matched.id != _wallet?.id) {
      setState(() {
        _wallet = matched;
        _autoDetectSpenderFromWallet(matched);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã gợi ý ví "${matched.name}" cho $merchantName'),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildQuickDateMiniPill({
    required String label,
    required bool selected,
    required Color accent,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? FinoraTokens.ink(isDark)
                : FinoraTokens.surface(isDark),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected
                  ? FinoraTokens.ink(isDark)
                  : FinoraTokens.line(isDark),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected
                  ? (isDark ? const Color(0xFF141518) : Colors.white)
                  : FinoraTokens.inkSecondary(isDark),
            ),
          ),
        ),
      ),
    );
  }

  List<({String id, String name, String? asset, String icon})>
      _getAllMerchants(TransactionProvider provider) {
    final customMerchants = provider.categories
        .where((c) => c.categoryGroup == 'merchant' && !c.isArchived)
        .toList();

    final rawDefaults = <({String id, String name, String? asset, String icon})>[];

    final existingKeys = <String>{};
    for (final cm in customMerchants) {
      existingKeys.add(cm.id.toLowerCase());
      existingKeys.add(cm.name.trim().toLowerCase());
    }

    final activeDefaults = rawDefaults.where((dm) {
      final idKey = dm.id.toLowerCase();
      final nameKey = dm.name.trim().toLowerCase();
      if (_deletedMerchantKeys.contains(idKey) ||
          _deletedMerchantKeys.contains(nameKey)) {
        return false;
      }
      return !existingKeys.contains(idKey) && !existingKeys.contains(nameKey);
    }).toList();

    return [
      (
        id: '',
        name: 'Không chọn',
        asset: null as String?,
        icon: 'shopping-bag'
      ),
      for (final dm in activeDefaults) dm,
      for (final cm in customMerchants)
        (
          id: cm.id,
          name: cm.name,
          asset: CategoryIconHelper.getAssetPath(cm.icon) ??
              CategoryIconHelper.getAssetPath(cm.name),
          icon: cm.icon,
        ),
    ];
  }

  void _showMerchantPickerModal() {
    final provider = context.read<TransactionProvider>();
    final allMerchants = _getAllMerchants(provider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = _activeTypeAccentColor;
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
                ? allMerchants
                : allMerchants
                    .where((m) => normalizeSearch(m.name).contains(query))
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
                      maxHeight: MediaQuery.of(sheetContext).size.height * 0.78,
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Chọn nơi mua',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: primaryTextColor,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Nhận diện thương hiệu, sàn TMĐT & gợi ý ví thông minh',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.of(sheetContext).pop(),
                              borderRadius: BorderRadius.circular(100),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFF1F5F9),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        FinoraTextField(
                          controller: searchController,
                          hint: 'Tìm sàn TMĐT hoặc cửa hàng...',
                          radius: 24,
                          onChanged: (val) {
                            setStateSheet(() {
                              searchQuery = val;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Flexible(
                          child: filtered.isEmpty
                              ? Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 28),
                                  child: Center(
                                    child: Text(
                                      'Không tìm thấy nơi mua phù hợp',
                                      style: AppTypography.caption2.copyWith(
                                        color: secondaryTextColor,
                                      ),
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
                                    final m = filtered[i];
                                    final isSelected =
                                        (_merchantId == null && m.id.isEmpty) ||
                                            (_merchantId == m.id);
                                    return Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(18),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          final newId =
                                              m.id.isEmpty ? null : m.id;
                                          final newName =
                                              m.id.isEmpty ? null : m.name;
                                          setState(() {
                                            _merchantId = newId;
                                            _merchantName = newName;
                                          });
                                          Navigator.of(sheetContext).pop();
                                          if (newId != null ||
                                              newName != null) {
                                            _autoSelectWalletForMerchant(
                                                newId ?? '', newName ?? '');
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 11),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? accent.withValues(
                                                    alpha: isDark ? 0.18 : 0.10)
                                                : (isDark
                                                    ? Colors.white.withValues(
                                                        alpha: 0.03)
                                                    : const Color(0xFFF8FAFC)),
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            border: Border.all(
                                              color: isSelected
                                                  ? accent
                                                  : (isDark
                                                      ? Colors.white10
                                                      : const Color(
                                                          0xFFE2E8F0)),
                                              width: isSelected ? 1.4 : 1.0,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 38,
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.08)
                                                      : Colors.white,
                                                  border: Border.all(
                                                    color: isDark
                                                        ? Colors.white12
                                                        : const Color(
                                                            0xFFE2E8F0),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: ClipOval(
                                                  child: m.id.isEmpty
                                                      ? Icon(
                                                          Icons
                                                              .storefront_outlined,
                                                          size: 19,
                                                          color:
                                                              secondaryTextColor,
                                                        )
                                                      : CategoryIconBadge(
                                                          icon: m.asset ??
                                                              m.icon,
                                                          categoryName: m.name,
                                                          size: 38,
                                                          isDark: isDark,
                                                        ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  m.name,
                                                  style: TextStyle(
                                                    fontSize: 14.5,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w800
                                                        : FontWeight.w600,
                                                    color: primaryTextColor,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isSelected)
                                                Icon(
                                                  Icons.check_circle_rounded,
                                                  size: 20,
                                                  color: accent,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 10),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(sheetContext).pop(),
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const Text(
                                'Xong',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
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

  /// Horizontal pill selector for purchase sources / merchants (Nơi mua)
  Widget _buildMerchantSelector(bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final provider = context.watch<TransactionProvider>();
    final allMerchants = _getAllMerchants(provider);
    final accent = _activeTypeAccentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'NƠI MUA (TÙY CHỌN)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color:
                      isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
            ),
            if (_merchantId != null && _merchantId!.isNotEmpty) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() {
                  _merchantId = null;
                  _merchantName = null;
                }),
                child: Text(
                  'Bỏ chọn',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showMerchantPickerModal,
              child: Text(
                'Tất cả',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: allMerchants.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final m = allMerchants[i];
              final isSelected = (_merchantId == null && m.id.isEmpty) ||
                  (_merchantId == m.id);

              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  final newId = m.id.isEmpty ? null : m.id;
                  final newName = m.id.isEmpty ? null : m.name;
                  setState(() {
                    _merchantId = newId;
                    _merchantName = newName;
                  });
                  if (newId != null || newName != null) {
                    _autoSelectWalletForMerchant(newId ?? '', newName ?? '');
                  }
                },
                borderRadius: BorderRadius.circular(100),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accent.withValues(alpha: isDark ? 0.22 : 0.12)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF6FAF8)),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected
                          ? accent
                          : (isDark
                              ? Colors.white10
                              : const Color(0xFFE3EBE7)),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (m.id.isEmpty)
                        Icon(Icons.storefront_outlined,
                            size: 18, color: secondaryTextColor)
                      else
                        ClipOval(
                          child: CategoryIconWidget(
                            icon: m.asset ?? m.icon,
                            categoryName: m.name,
                            size: 22,
                            color: isSelected
                                ? (isDark ? Colors.white : accent)
                                : textColor,
                          ),
                        ),
                      const SizedBox(width: 7),
                      Text(
                        m.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? Colors.white : accent)
                              : textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Danh mục cho biết bạn chi vào việc gì; nơi mua giúp nhận diện cửa hàng / sàn TMĐT.',
          style: TextStyle(
            fontSize: 11.5,
            color: secondaryTextColor,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  /// Interactive rounded tile inside card (Danh mục, Ví, Ngày)
  Widget _buildInteractiveTile({
    required bool isDark,
    required Widget leading,
    required String title,
    String? subtitle,
    String? trailingText,
    String? trailingSubtitle,
    Color? trailingColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: FinoraTokens.bg(isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: FinoraTokens.line(isDark),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FinoraTokens.ink(isDark),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: FinoraTokens.inkSecondary(isDark),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingText != null) ...[
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trailingText,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: trailingColor ?? FinoraTokens.ink(isDark),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (trailingSubtitle != null && trailingSubtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        trailingSubtitle,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          color: FinoraTokens.inkSecondary(isDark),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(width: 6),
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: FinoraTokens.inkSecondary(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Floating Solid Ink Save Button matching Warm Paper & Ink
  Widget _buildSaveButton(bool isDark) {
    final valid = _isValid();
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.paddingOf(context).bottom > 0
            ? MediaQuery.paddingOf(context).bottom + 8
            : 16,
      ),
      decoration: BoxDecoration(
        color: FinoraTokens.bg(isDark).withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: FinoraTokens.line(isDark),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: valid && !_isSaving ? _save : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: FinoraTokens.ink(isDark),
            disabledBackgroundColor: FinoraTokens.ink(isDark).withValues(alpha: 0.35),
            foregroundColor: isDark ? const Color(0xFF141518) : Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSaving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: isDark ? const Color(0xFF141518) : Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  widget.existing == null ? 'Lưu giao dịch' : 'Cập nhật giao dịch',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF141518) : Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  String _formatDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$hh:$min • $dd/$mm/${d.year}';
  }
}

class _DateAndTimePickerSheet extends StatefulWidget {
  final DateTime initialDateTime;
  final Color accentColor;

  const _DateAndTimePickerSheet({
    required this.initialDateTime,
    required this.accentColor,
  });

  @override
  State<_DateAndTimePickerSheet> createState() =>
      _DateAndTimePickerSheetState();
}

class _DateAndTimePickerSheetState extends State<_DateAndTimePickerSheet> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    final init = widget.initialDateTime;
    _displayedMonth = DateTime(init.year, init.month, 1);
    _selectedDate = DateTime(init.year, init.month, init.day);
    _hour = init.hour;
    _minute = init.minute;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _selectQuickDate(DateTime date) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
      _displayedMonth = DateTime(date.year, date.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = widget.accentColor;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dayBefore = today.subtract(const Duration(days: 2));

    final daysInMonth =
        DateUtils.getDaysInMonth(_displayedMonth.year, _displayedMonth.month);
    final firstWeekday =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday;
    final leadingEmpty = firstWeekday - 1; // Monday = 1 -> 0 empty cells

    final hhStr = _hour.toString().padLeft(2, '0');
    final mmStr = _minute.toString().padLeft(2, '0');
    final ddStr = _selectedDate.day.toString().padLeft(2, '0');
    final moStr = _selectedDate.month.toString().padLeft(2, '0');

    return GlassBottomSheet(
      radius: 32,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chọn ngày & giờ giao dịch',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: primaryText,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Đang chọn: $hhStr:$mmStr • $ddStr/$moStr/${_selectedDate.year}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFF1F5F9),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 1. Quick Date Pills (Hôm nay, Hôm qua, Hôm kia)
              Row(
                children: [
                  for (final preset in [
                    (label: 'Hôm nay', date: today),
                    (label: 'Hôm qua', date: yesterday),
                    (label: 'Hôm kia', date: dayBefore),
                  ]) ...[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                          child: InkWell(
                            onTap: () => _selectQuickDate(preset.date),
                            borderRadius: BorderRadius.circular(100),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _isSameDay(_selectedDate, preset.date)
                                    ? accent
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: _isSameDay(_selectedDate, preset.date)
                                      ? accent
                                      : (isDark
                                          ? Colors.white12
                                          : const Color(0xFFE2E8F0)),
                                  width: 1,
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    preset.label,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color:
                                          _isSameDay(_selectedDate, preset.date)
                                              ? Colors.white
                                              : primaryText,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              // 2. Clean Apple Month Calendar Grid
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Month navigation bar
                    Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _displayedMonth = DateTime(
                                _displayedMonth.year,
                                _displayedMonth.month - 1,
                                1,
                              );
                            });
                          },
                          icon: Icon(
                            Icons.chevron_left_rounded,
                            color: primaryText,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Tháng ${_displayedMonth.month} / ${_displayedMonth.year}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: primaryText,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _displayedMonth = DateTime(
                                _displayedMonth.year,
                                _displayedMonth.month + 1,
                                1,
                              );
                            });
                          },
                          icon: Icon(
                            Icons.chevron_right_rounded,
                            color: primaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Weekday headers
                    Row(
                      children: [
                        for (final wd in [
                          'T2',
                          'T3',
                          'T4',
                          'T5',
                          'T6',
                          'T7',
                          'CN'
                        ])
                          Expanded(
                            child: Center(
                              child: Text(
                                wd,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: wd == 'CN'
                                      ? const Color(0xFFE11D48)
                                      : secondaryText,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Days grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: leadingEmpty + daysInMonth,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                        childAspectRatio: 1.15,
                      ),
                      itemBuilder: (context, index) {
                        if (index < leadingEmpty) {
                          return const SizedBox.shrink();
                        }
                        final day = index - leadingEmpty + 1;
                        final cellDate = DateTime(
                          _displayedMonth.year,
                          _displayedMonth.month,
                          day,
                        );
                        final isSelected = _isSameDay(cellDate, _selectedDate);
                        final isTodayCell = _isSameDay(cellDate, today);

                        return InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedDate = cellDate;
                            });
                          },
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? accent : Colors.transparent,
                              border: isTodayCell && !isSelected
                                  ? Border.all(color: accent, width: 1.3)
                                  : null,
                            ),
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected || isTodayCell
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isTodayCell ? accent : primaryText),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 3. Time Selector (Chọn giờ giao dịch — HH:mm)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_filled_rounded,
                          size: 16,
                          color: accent,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Chọn giờ giao dịch — $hhStr:$mmStr',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: primaryText,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            final n = DateTime.now();
                            setState(() {
                              _hour = n.hour;
                              _minute = n.minute;
                            });
                          },
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: accent.withValues(
                                  alpha: isDark ? 0.22 : 0.12),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              'Giờ hiện tại',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: accent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Hour stepper pill
                        Expanded(
                          child: _buildTimeStepperControl(
                            label: 'Giờ',
                            valueText: hhStr,
                            isDark: isDark,
                            accent: accent,
                            primaryText: primaryText,
                            secondaryText: secondaryText,
                            onDecrement: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _hour = (_hour - 1 + 24) % 24;
                              });
                            },
                            onIncrement: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _hour = (_hour + 1) % 24;
                              });
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            ':',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: primaryText,
                            ),
                          ),
                        ),
                        // Minute stepper pill
                        Expanded(
                          child: _buildTimeStepperControl(
                            label: 'Phút',
                            valueText: mmStr,
                            isDark: isDark,
                            accent: accent,
                            primaryText: primaryText,
                            secondaryText: secondaryText,
                            onDecrement: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _minute = (_minute - 5 + 60) % 60;
                              });
                            },
                            onIncrement: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _minute = (_minute + 5) % 60;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Quick time chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          for (final t in const [
                            (h: 8, m: 0, label: '08:00'),
                            (h: 12, m: 0, label: '12:00'),
                            (h: 15, m: 0, label: '15:00'),
                            (h: 18, m: 30, label: '18:30'),
                            (h: 21, m: 0, label: '21:00'),
                          ]) ...[
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _hour = t.h;
                                    _minute = t.m;
                                  });
                                },
                                borderRadius: BorderRadius.circular(100),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: (_hour == t.h && _minute == t.m)
                                        ? accent
                                        : (isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.06)
                                            : Colors.white),
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: (_hour == t.h && _minute == t.m)
                                          ? accent
                                          : (isDark
                                              ? Colors.white12
                                              : const Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                  child: Text(
                                    t.label,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: (_hour == t.h && _minute == t.m)
                                          ? Colors.white
                                          : primaryText,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. Solid Stadium Pill Confirm Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop(
                      DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        _hour,
                        _minute,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: isDark ? 0.38 : 0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 19,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Xác nhận ngày & giờ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
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
        ),
      ),
    );
  }

  Widget _buildTimeStepperControl({
    required String label,
    required String valueText,
    required bool isDark,
    required Color accent,
    required Color primaryText,
    required Color secondaryText,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: onDecrement,
            borderRadius: BorderRadius.circular(100),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFF1F5F9),
              ),
              child: Icon(Icons.remove_rounded, size: 16, color: primaryText),
            ),
          ),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valueText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: accent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onIncrement,
            borderRadius: BorderRadius.circular(100),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFF1F5F9),
              ),
              child: Icon(Icons.add_rounded, size: 16, color: primaryText),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionRow extends StatelessWidget {
  final String icon;
  final String categoryName;
  final Color color;
  final String label;
  final bool selected;
  final Color? accentColor;
  final VoidCallback onTap;

  const _SelectionRow({
    required this.icon,
    required this.categoryName,
    required this.color,
    required this.label,
    required this.selected,
    this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final effectiveAccent = accentColor ?? AppColors.accent;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? effectiveAccent.withValues(alpha: isDark ? 0.18 : 0.10)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? effectiveAccent
                  : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              width: selected ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            children: [
              CategoryIconBadge(
                icon: icon,
                categoryName: categoryName,
                color: color,
                size: 40,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: primaryTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: effectiveAccent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
