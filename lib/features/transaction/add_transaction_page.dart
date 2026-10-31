import '../../core/widgets/adaptive_glass_surface.dart';
import '../../core/widgets/finora_notice.dart';
import '../../core/widgets/finora_member_filter.dart';
import '../../core/widgets/finora_transaction_success_modal.dart';
import '../../state/theme_studio_controller.dart';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:uuid/uuid.dart';

import 'package:intl/intl.dart';

import '../../core/widgets/glass_widgets.dart';

import '../../core/widgets/premium_widgets.dart';

import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/transaction_calculator_sheet.dart';

import '../../core/design_system/app_colors.dart';

import '../../core/design_system/app_typography.dart';

import '../../core/utils/formatters.dart';

import '../../core/utils/search.dart';

import '../../data/models/category.dart';

import '../../data/models/transaction.dart';

import '../../data/models/wallet.dart';

import '../../state/transaction_provider.dart';

import '../../state/more_provider.dart';

import '../../state/family_provider.dart';

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

  final ScrollController _scrollController = ScrollController();

  final FocusNode _noteFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();
  final GlobalKey _noteCardKey = GlobalKey();
  Timer? _amountScrollTimer;
  Timer? _noteScrollTimer;

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
          prefs.getStringList('finora_deleted_merchants_${widget.userId}') ??
              [];

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

    _amountController.addListener(_onAmountChanged);

    _noteController.addListener(_onAmountChanged);

    _amountFocusNode.addListener(() {
      if (_amountFocusNode.hasFocus) {
        _amountScrollTimer?.cancel();
        _amountScrollTimer = Timer(const Duration(milliseconds: 150), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    });

    _noteFocusNode.addListener(() {
      if (_noteFocusNode.hasFocus) {
        _noteScrollTimer?.cancel();
        _noteScrollTimer = Timer(const Duration(milliseconds: 280), () {
          if (mounted && _noteFocusNode.hasFocus && _noteCardKey.currentContext != null) {
            Scrollable.ensureVisible(
              _noteCardKey.currentContext!,
              alignment: 0.35,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TransactionProvider>().load(widget.userId);
        try {
          context.read<MoreProvider>().load(widget.userId);
        } catch (_) {}

        _initSelections();
      }
    });
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

    _amountScrollTimer?.cancel();
    _noteScrollTimer?.cancel();
    _noteFocusNode.dispose();
    _amountFocusNode.dispose();

    _scrollController.dispose();

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
        return const Color(0xFF00866A);

      case 'transfer':
        return const Color(0xFF0284C7);

      case 'credit_card_payment':
      case 'debt':
      case 'loan':
        return const Color(0xFFD97706);

      case 'investment':
        return const Color(0xFF0D9488);

      default:
        return const Color(0xFF00866A);
    }
  }

  void _handleHorizontalSwipe(DragEndDetails details) {
    final v = details.primaryVelocity;

    if (v == null || v.abs() < 220) return;

    const types = [
      'expense',
      'income',
      'transfer',
      'credit_card_payment',
      'investment'
    ];

    final currentIndex = types.indexOf(_type);

    if (currentIndex == -1) return;

    if (v < -220 && currentIndex < types.length - 1) {
      HapticFeedback.selectionClick();

      _onTypeChanged(types[currentIndex + 1]);
    } else if (v > 220 && currentIndex > 0) {
      HapticFeedback.selectionClick();

      _onTypeChanged(types[currentIndex - 1]);
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

  Future<void> _pickCategory() async {
    final chosen = await _showCategorySearchModal();
    if (chosen != null && mounted) {
      setState(() => _category = chosen);
    }
  }

  Future<Category?> _showCategorySearchModal() {
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

    return showModalBottomSheet<Category?>(
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
                                padding: const EdgeInsets.all(6),
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
                              : GridView.builder(
                                  shrinkWrap: true,
                                  physics: const BouncingScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: 0.85,
                                  ),
                                  itemCount: filtered.length,
                                  itemBuilder: (_, i) {
                                    final item = filtered[i];

                                    final selected = item.id == _category?.id ||
                                        item.name == _category?.name;

                                    return _CategoryGridTile(
                                      category: item,
                                      selected: selected,
                                      accentColor: accent,
                                      onTap: () {
                                        HapticFeedback.selectionClick();

                                        Navigator.of(sheetContext).pop(item);
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
                                padding: const EdgeInsets.all(6),
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
                                                    ? Colors.white
                                                        .withValues(alpha: 0.03)
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
                                                        const SizedBox(
                                                            width: 6),
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
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                mainAxisSize: MainAxisSize.min,
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
                                                      color: secondaryTextColor,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
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
    if (!_isValid()) return;

    FocusManager.instance.primaryFocus?.unfocus();

    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');

    final amount = int.tryParse(digits) ?? 0;

    if (amount <= 0) return;

    setState(() => _isSaving = true);

    final rawNote = _noteController.text.trim();
    final note = rawNote.isEmpty ? '' : capitalizeFirstLetter(rawNote);
    final bankCodeRef = widget.existing?.bankTransactionCode?.trim() ?? '';

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
        .where((t) =>
            t != 'Chồng' &&
            t != 'Vợ' &&
            t != 'Con' &&
            t != 'Thành viên' &&
            t != 'Chung' &&
            !(bankCodeRef.isNotEmpty && t.startsWith('bank_code:')))
        .toList();

    final String ownerName;

    if (_type == 'transfer' || _type == 'credit_card_payment') {
      ownerName = _fromWallet?.ownerName ?? activeTag;
    } else {
      ownerName = _wallet?.ownerName ?? activeTag;
    }

    final txTags = {
      ...cleanTags,
      ownerName,
      activeTag,
      if (bankCodeRef.isNotEmpty) 'bank_code:$bankCodeRef',
    }.toList();

    final provider = context.read<TransactionProvider>();

    final wallets = provider.wallets;

    final resolvedOwnerRole = switch (activeTag.toLowerCase()) {
      'vợ' || 'vo' || 'wife' => 'wife',
      'chung' || 'joint' || 'all' => 'joint',
      _ => 'husband',
    };

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
        bankTransactionCode: bankCodeRef.isEmpty ? null : bankCodeRef,
        rawBankNotification: widget.existing?.rawBankNotification,
        walletId: fromW?.id,
        walletName: fromW?.name,
        fromWalletId: fromW?.id,
        fromWalletName: fromW?.name,
        toWalletId: toW?.id,
        toWalletName: toW?.name,
        owner: fromW?.owner ?? resolvedOwnerRole,
        ownerName: ownerName,
        fromOwner: fromW?.owner ?? resolvedOwnerRole,
        toOwner: toW?.owner ?? resolvedOwnerRole,
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
        bankTransactionCode: bankCodeRef.isEmpty ? null : bankCodeRef,
        rawBankNotification: widget.existing?.rawBankNotification,
        walletId: fromW?.id,
        walletName: fromW?.name,
        fromWalletId: fromW?.id,
        fromWalletName: fromW?.name,
        toWalletId: toW?.id,
        toWalletName: toW?.name,
        creditCardId: toW?.id,
        owner: fromW?.owner ?? resolvedOwnerRole,
        ownerName: ownerName,
        fromOwner: fromW?.owner ?? resolvedOwnerRole,
        toOwner: toW?.owner ?? resolvedOwnerRole,
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
        bankTransactionCode: bankCodeRef.isEmpty ? null : bankCodeRef,
        rawBankNotification: widget.existing?.rawBankNotification,
        walletId: effectiveWallet?.id,
        walletName: effectiveWallet?.name,
        owner: activeTag == 'Vợ'
            ? 'wife'
            : (activeTag == 'Chung'
                ? 'joint'
                : (effectiveWallet?.owner ?? 'husband')),
        ownerName: activeTag,
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
      final savedTx = existing != null
          ? tx.copyWith(id: existing.id, userId: widget.userId)
          : tx.copyWith(
              id: _pendingTransactionId ??= const Uuid().v4(),
              userId: widget.userId,
            );
      if (existing != null) {
        await provider.updateTransaction(widget.userId, existing.id, savedTx);
      } else {
        await provider.createTransaction(widget.userId, savedTx);
      }

      if (mounted) {
        final recordAnother = await FinoraTransactionSuccessModal.show(
          context,
          transaction: savedTx,
          isEdit: existing != null,
          walletName: _wallet?.name ?? _fromWallet?.name,
          destinationWalletName: _toWallet?.name,
          spenderTag: activeTag,
        );

        if (!mounted) return;
        if (recordAnother == true && existing == null) {
          setState(() {
            _amountController.clear();
            _noteController.clear();
            _pendingTransactionId = null;
          });
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        FinoraNotice.of(context).showSnackBar(
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

  Widget _buildSaveSuccessSheet(
      BuildContext sheetContext, int amount, String type) {
    final currencyFmt = NumberFormat('#,###', 'vi_VN');

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF003D35),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          Image.asset(
            'assets/mascot/sticker-07-transaction-success.png',
            height: 110,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 14),
          const Text(
            'Đã ghi nhận giao dịch!',
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${currencyFmt.format(amount)} ₫',
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF34D399),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mỗi khoản ghi chép là một bước tiến đến tự do tài chính.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 12,
              color: Color(0xCCFFFFFF),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00866A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: const Text(
                'Hoàn tất',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
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

    return GlassScaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassTopBar(
        title: '',
        titleWidget: _buildTypeSelector(isDark),
        showBack: true,
        onBack: () => Navigator.of(context).maybePop(),
        height: 48,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: _handleHorizontalSwipe,
        child: Stack(
          children: [
            Positioned.fill(
              child: ListView(
                key: const ValueKey('transaction-form-scroll'),
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                    16,
                    GlassScaffold.topInset(context, 6, 48),
                    16,
                    MediaQuery.of(context).viewInsets.bottom > 0
                        ? MediaQuery.of(context).viewInsets.bottom + 120
                        : 120),
                children: [
                  _buildAmountSection(isDark),

                  const SizedBox(height: 16),

                  // Card 1: Row of 2 Bento Cards (Danh mục & Ví thanh toán / 2 Ví cho Chuyển & Trả thẻ)

                  _buildBentoRowCards(isDark),

                  // Card 2: Nơi mua sắm Bento Card

                  if (_type == 'expense') ...[
                    const SizedBox(height: 12),
                    _buildMerchantBentoCard(isDark),
                  ],

                  const SizedBox(height: 12),

                  // Card 3: Thời gian giao dịch Bento Card

                  _buildDateTimeBentoCard(isDark),

                  const SizedBox(height: 12),

                  // Card 4: Ghi chú Bento Card (kèm Gợi ý thông minh)

                  _buildNoteBentoCard(isDark),

                  // Card 5: Người chi tiêu Bento Card

                  if (_hasFamilyMembers) ...[
                    const SizedBox(height: 12),
                    _buildSpenderBentoCard(isDark),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildSaveButton(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddTxHeaderContent(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.existing != null ? 'Sửa giao dịch' : 'Thêm giao dịch',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 18.0,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        _buildTypeSelector(isDark),
      ],
    );
  }

  /// Floating Header with Back Button (Row 1) + Type Selector Tabs (Row 2) - Matching Image Reference

  bool get _hasFamilyMembers => true;

  void _showCalculatorSheet(bool isDark) async {
    final currentDigits =
        _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final currentAmount = int.tryParse(currentDigits) ?? 0;

    final result = await TransactionCalculatorSheet.show(
      context,
      initialAmount: currentAmount,
      accentColor: _activeTypeAccentColor,
    );

    if (result != null && mounted) {
      setState(() {
        _amountController.text = _formatInitialAmount(result);
      });
      _onAmountChanged();
    }
  }

  Widget _buildTypeSelector(bool isDark) {
    const types = [
      'expense',
      'income',
      'transfer',
      'credit_card_payment',
      'investment'
    ];

    return FinoraSegmentedTabs(
      key: const ValueKey('transaction-type-tabs'),
      labels: const ['Chi tiêu', 'Thu nhập', 'Chuyển', 'Trả thẻ', 'Đầu tư'],
      selectedIndex: types.indexOf(_type).clamp(0, types.length - 1),
      height: 42,
      fontSize: 11.5,
      transparentBackground: true,
      colors: const [
        Color(0xFFE11D48),
        Color(0xFF059669),
        Color(0xFF0284C7),
        Color(0xFFD97706),
        Color(0xFF0D9488)
      ],
      onChanged: (index) => _onTypeChanged(types[index]),
    );
  }

  Widget _buildAmountSection(bool isDark) {
    String captionText = 'SỐ TIỀN CHI';

    if (_type == 'income') {
      captionText = 'SỐ TIỀN THU';
    } else if (_type == 'transfer') {
      captionText = 'SỐ TIỀN CHUYỂN';
    } else if (_type == 'credit_card_payment') {
      captionText = 'SỐ TIỀN TRẢ THẺ';
    } else if (_type == 'investment') {
      captionText = 'SỐ TIỀN ĐẦU TƯ';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Top row: Solid Pill Badge on Left <----> Redesigned Calculator Button on Right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: _activeTypeAccentColor,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: _activeTypeAccentColor.withValues(
                        alpha: isDark ? 0.35 : 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    captionText,
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _showCalculatorSheet(isDark);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? _activeTypeAccentColor.withValues(alpha: 0.22)
                        : _activeTypeAccentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _activeTypeAccentColor.withValues(
                          alpha: isDark ? 0.45 : 0.30),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _activeTypeAccentColor.withValues(
                            alpha: isDark ? 0.25 : 0.14),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.calculate_rounded,
                      size: 20,
                      color: _activeTypeAccentColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Centered Amount display + Currency symbol
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: IntrinsicWidth(
                child: TextField(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: const [DotSeparatorTextInputFormatter()],
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: (isDark ? Colors.white : const Color(0xFF0F172A))
                          .withValues(alpha: 0.25),
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
            const SizedBox(width: 4),
            Text(
              '₫',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: _activeTypeAccentColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Bento Card 1: Row of 2 Bento Cards (Danh mục & Ví thanh toán / 2 Ví cho Chuyển & Trả thẻ)

  Widget _buildBentoRowCards(bool isDark) {
    final provider = context.watch<TransactionProvider>();

    final wallets = provider.wallets;

    final isTransferOrCredit =
        _type == 'transfer' || _type == 'credit_card_payment';

    if (isTransferOrCredit) {
      return _buildTwoWalletDropdownRow(isDark, wallets);
    }

    final activeWallet = _wallet;

    final catColorHex = _category?.color ?? '#E11D48';

    final bankCode =
        activeWallet != null ? _inferBankCodeForWallet(activeWallet) : 'cash';

    final hasBankAsset = BankIconRegistry.getAssetPath(bankCode) != null;

    return Row(
      children: [
        // Left Bento: Danh mục

        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _pickCategory,
              borderRadius: BorderRadius.circular(20),
              child: AdaptiveGlassSurface(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Danh mục',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        CategoryIconBadge(
                          icon: _category?.icon,
                          categoryName: _category?.name,
                          colorHex: catColorHex,
                          size: 34,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _category?.name ?? 'Chọn danh mục',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Bấm để đổi ·',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Right Bento: Ví thanh toán

        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectWallet(
                (w) => setState(() {
                  _wallet = w;

                  _autoDetectSpenderFromWallet(w);
                }),
                current: activeWallet,
                title: 'Chọn ví thanh toán',
              ),
              borderRadius: BorderRadius.circular(20),
              child: AdaptiveGlassSurface(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Ví thanh toán',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF064E3B)
                                    .withValues(alpha: 0.40)
                                : const Color(0xFFD1FAE5),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF00866A)
                                  .withValues(alpha: isDark ? 0.40 : 0.25),
                              width: 1.2,
                            ),
                          ),
                          child: ClipOval(
                            child: Center(
                              child: hasBankAsset
                                  ? BankIcon(
                                      bankCode: bankCode,
                                      bankName: activeWallet?.bankName ??
                                          activeWallet?.name,
                                      size: 34,
                                    )
                                  : const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      size: 19,
                                      color: Color(0xFF00866A),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            activeWallet?.name ?? 'Chọn ví',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      activeWallet != null
                          ? (activeWallet.isCreditCard
                              ? 'Dư nợ ${Formatters.formatCurrency(activeWallet.currentDebt)}'
                              : 'Số dư ${Formatters.formatCurrency(activeWallet.balance)}')
                          : 'Chưa có ví',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF00866A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Bento Card 2: Nơi mua sắm Bento Card

  Widget _buildMerchantBentoCard(bool isDark) {
    final provider = context.watch<TransactionProvider>();
    try {
      context.watch<MoreProvider>();
    } catch (_) {}

    final allMerchants = _getAllMerchants(provider);

    return AdaptiveGlassSurface(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Nơi mua sắm',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: _showMerchantPickerModal,
                    borderRadius: BorderRadius.circular(100),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Xem danh sách',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF00866A),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: isDark
                                ? const Color(0xFF34D399)
                                : const Color(0xFF00866A),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: allMerchants.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final m = allMerchants[i];

                final isSelected = (_merchantId == null && m.id.isEmpty) ||
                    (_merchantId == m.id);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      HapticFeedback.selectionClick();

                      setState(() {
                        if (m.id.isEmpty) {
                          _merchantId = null;

                          _merchantName = null;
                        } else {
                          _merchantId = m.id;

                          _merchantName = m.name;

                          _autoSelectWalletForMerchant(m.id, m.name);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? const Color(0xFF064E3B)
                                    .withValues(alpha: 0.35)
                                : const Color(0xFFD1FAE5))
                            : (isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00866A)
                              : (isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0)),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMerchantChipIcon(m, isSelected, isDark),
                          const SizedBox(width: 8),
                          Text(
                            m.name,
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? (isDark
                                      ? const Color(0xFF6EE7B7)
                                      : const Color(0xFF065F46))
                                  : (isDark
                                      ? const Color(0xFFE2E8F0)
                                      : const Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Bento Card 3: Thời gian giao dịch Bento Card

  Widget _buildDateTimeBentoCard(bool isDark) {
    final currentDt = DateTime.fromMillisecondsSinceEpoch(_date);

    final nowDt = DateTime.now();

    final isToday = currentDt.year == nowDt.year &&
        currentDt.month == nowDt.month &&
        currentDt.day == nowDt.day;

    final yesterdayDt = nowDt.subtract(const Duration(days: 1));

    final isYesterday = currentDt.year == yesterdayDt.year &&
        currentDt.month == yesterdayDt.month &&
        currentDt.day == yesterdayDt.day;

    final dayStr = currentDt.day.toString().padLeft(2, '0');
    final monthStr = currentDt.month.toString().padLeft(2, '0');
    final yearStr = currentDt.year.toString();

    final dateLabel = isToday
        ? 'Hôm nay $dayStr/$monthStr/$yearStr'
        : (isYesterday
            ? 'Hôm qua $dayStr/$monthStr/$yearStr'
            : '$dayStr/$monthStr/$yearStr');

    final timeStr =
        '${currentDt.hour.toString().padLeft(2, '0')}:${currentDt.minute.toString().padLeft(2, '0')}';

    return AdaptiveGlassSurface(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Icon + Title
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF064E3B).withValues(alpha: 0.40)
                      : const Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00866A)
                        .withValues(alpha: isDark ? 0.40 : 0.25),
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: isDark
                        ? const Color(0xFF6EE7B7)
                        : const Color(0xFF00866A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Thời gian giao dịch',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Centered Date Time Inset Box
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: isDark
                            ? const Color(0xFF6EE7B7)
                            : const Color(0xFF00866A),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$timeStr    -    $dateLabel',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 2 Quick Pills: Hôm nay & Hôm qua
          Row(
            children: [
              Expanded(
                child: _buildBentoDatePill(
                  label: 'Hôm nay',
                  selected: isToday,
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
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBentoDatePill(
                  label: 'Hôm qua',
                  selected: isYesterday,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();

                    final yest =
                        DateTime.now().subtract(const Duration(days: 1));

                    setState(() {
                      _date = DateTime(
                        yest.year,
                        yest.month,
                        yest.day,
                        currentDt.hour,
                        currentDt.minute,
                      ).millisecondsSinceEpoch;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoDatePill({
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: selected
                ? (isDark
                    ? const Color(0xFF064E3B).withValues(alpha: 0.40)
                    : const Color(0xFFD1FAE5))
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected
                  ? const Color(0xFF00866A)
                  : (isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0)),
              width: selected ? 1.2 : 0.8,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 13,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected
                  ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF00866A))
                  : (isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }

  /// Bento Card 4: Ghi chú Ngân hàng Bento Card

  Widget _buildNoteBentoCard(bool isDark) {
    final accent = _activeTypeAccentColor;
    return Container(
      key: _noteCardKey,
      child: AdaptiveGlassSurface(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                size: 18,
                color: accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Ghi chú',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _noteController,
              focusNode: _noteFocusNode,
              scrollPadding: const EdgeInsets.only(bottom: 140),
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: const [
                FinoraCapitalizeFirstFormatter(),
              ],
              maxLines: null,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'BeVietnamPro',
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Thêm ghi chú riêng (Tự viết hoa chữ đầu)...',
                hintStyle: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'BeVietnamPro',
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
        ],
      ),
    ),
    );
  }

  /// Bento Card 5: Người chi tiêu Bento Card

  Widget _buildSpenderBentoCard(bool isDark) {
    return AdaptiveGlassSurface(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildBentoSpenderTile(isDark),
    );
  }

  Widget _buildQuickAmountChip(String label, int delta, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _addQuickAmount(delta),
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                : const Color(0xFFE6F4EA),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF059669).withValues(alpha: 0.4)
                  : const Color(0xFFA7F3D0),
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF00866A),
            ),
          ),
        ),
      ),
    );
  }

  void _addQuickAmount(int delta) {
    HapticFeedback.selectionClick();

    final currentStr = _amountController.text.replaceAll('.', '').trim();

    final currentVal = int.tryParse(currentStr) ?? 0;

    final newVal = currentVal + delta;

    _amountController.text = _formatInitialAmount(newVal);
  }

  /// Primary Unified Card (matching Image 8 with circular icon badges and clean 1px dividers)

  Widget _buildPrimaryDetailsCard(bool isDark) {
    final provider = context.watch<TransactionProvider>();

    final wallets = provider.wallets;

    final isTransferOrCredit =
        _type == 'transfer' || _type == 'credit_card_payment';

    final activeWallet = isTransferOrCredit ? _fromWallet : _wallet;

    final currentDt = DateTime.fromMillisecondsSinceEpoch(_date);

    final nowDt = DateTime.now();

    final isToday = currentDt.year == nowDt.year &&
        currentDt.month == nowDt.month &&
        currentDt.day == nowDt.day;

    final yesterdayDt = nowDt.subtract(const Duration(days: 1));

    final isYesterday = currentDt.year == yesterdayDt.year &&
        currentDt.month == yesterdayDt.month &&
        currentDt.day == yesterdayDt.day;

    final divider = Divider(
      height: 24,
      thickness: 1,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
    );

    return AdaptiveGlassSurface(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isTransferOrCredit) ...[
            // 1. Danh mục

            _buildCategoryRowInCard(isDark),

            divider,

            // 2. Ví thanh toán

            _buildWalletRowInCard(
              title: 'Ví thanh toán',
              wallet: activeWallet,
              isDark: isDark,
              onTap: () => _selectWallet(
                (w) => setState(() {
                  _wallet = w;

                  _autoDetectSpenderFromWallet(w);
                }),
                current: activeWallet,
                title: 'Chọn ví thanh toán',
              ),
            ),
          ] else ...[
            // 1 & 2: 2 Dropdown ví tiền / 1 hàng (Ví nguồn -> Ví nhận/Thẻ nhận)

            _buildTwoWalletDropdownRow(isDark, wallets),
          ],

          divider,

          // 3. Ngày & giờ

          _buildDateRowInCard(
            isDark: isDark,
            currentDt: currentDt,
            isToday: isToday,
            isYesterday: isYesterday,
          ),

          divider,

          // 4. Ghi chú (Sentence capitalization, no smart suggestions chip)

          _buildNoteRowInCard(isDark),

          if (_hasFamilyMembers) ...[
            divider,
            _buildBentoSpenderTile(isDark),
          ],
        ],
      ),
    );
  }

  /// 2 dropdown ví tiền trên 1 hàng cho Chuyển khoản và Trả thẻ (Ví nguồn -> Ví nhận/Thẻ nhận)

  Widget _buildTwoWalletDropdownRow(bool isDark, List<Wallet> wallets) {
    final isCard = _type == 'credit_card_payment';

    return Row(
      children: [
        // Left Bento: Ví nguồn (Kích thước & phong cách Bento chuẩn như Danh mục/Ví ở Chi tiêu)
        Expanded(
          child: _buildWalletBentoCard(
            label: 'Ví nguồn',
            wallet: _fromWallet,
            isDark: isDark,
            onTap: () => _selectWallet(
              (w) => setState(() {
                _fromWallet = w;

                if (_toWallet?.id == w.id) {
                  final others = wallets.where((ow) => ow.id != w.id).toList();

                  if (others.isNotEmpty) {
                    _toWallet = others.first;
                  }
                }

                _autoDetectSpenderFromWallet(w);
              }),
              current: _fromWallet,
              title: 'Chọn ví nguồn',
            ),
          ),
        ),

        // Arrow circular bridge between the two Bento cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 13,
              color: isCard ? const Color(0xFFD97706) : const Color(0xFF0284C7),
            ),
          ),
        ),

        // Right Bento: Ví nhận / Thẻ nhận (Kích thước & phong cách Bento chuẩn như Danh mục/Ví ở Chi tiêu)
        Expanded(
          child: _buildWalletBentoCard(
            label: isCard ? 'Thẻ nhận' : 'Ví nhận',
            wallet: _toWallet,
            isDark: isDark,
            isCreditCard: isCard,
            onTap: () => _selectWallet(
              (w) => setState(() {
                _toWallet = w;

                if (_fromWallet?.id == w.id) {
                  final others = wallets.where((ow) => ow.id != w.id).toList();

                  if (others.isNotEmpty) {
                    _fromWallet = others.first;
                  }
                }
              }),
              current: _toWallet,
              title: isCard ? 'Chọn thẻ nhận' : 'Chọn ví nhận',
              filter: isCard ? (w) => w.isCreditCard : null,
            ),
          ),
        ),
      ],
    );
  }

  /// Big Bento Card cho Ví nguồn, Ví nhận, Thẻ nhận đồng bộ 100% kích thước & layout với Bento Chi tiêu
  Widget _buildWalletBentoCard({
    required String label,
    required Wallet? wallet,
    required bool isDark,
    required VoidCallback onTap,
    bool isCreditCard = false,
  }) {
    final bankCode = wallet != null ? _inferBankCodeForWallet(wallet) : 'cash';
    final hasAsset = BankIconRegistry.getAssetPath(bankCode) != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AdaptiveGlassSurface(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AdaptiveGlassSurface(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hasAsset
                            ? const Color(0xFFE2E8F0)
                            : (isCreditCard
                                ? const Color(0xFFD97706)
                                    .withValues(alpha: 0.40)
                                : const Color(0xFF10B981)
                                    .withValues(alpha: 0.35)),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: isCreditCard
                          ? Container(
                              color: isDark
                                  ? const Color(0xFFD97706)
                                      .withValues(alpha: 0.20)
                                  : const Color(0xFFFEF3C7),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.credit_card_rounded,
                                size: 17,
                                color: Color(0xFFD97706),
                              ),
                            )
                          : (hasAsset
                              ? BankIcon(
                                  bankCode: bankCode,
                                  bankName: wallet?.bankName ?? wallet?.name,
                                  size: 34,
                                )
                              : Container(
                                  color: isDark
                                      ? const Color(0xFF064E3B)
                                          .withValues(alpha: 0.35)
                                      : const Color(0xFFE6F4EA),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: 17,
                                    color: Color(0xFF00866A),
                                  ),
                                )),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      wallet?.name ?? (isCreditCard ? 'Chọn thẻ' : 'Chọn ví'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                wallet != null
                    ? (wallet.isCreditCard
                        ? 'Nợ ${Formatters.formatCurrency(wallet.currentDebt)}'
                        : 'Số dư ${Formatters.formatCurrency(wallet.balance)}')
                    : 'Bấm để đổi ·',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF34D399)
                      : (isCreditCard
                          ? const Color(0xFFD97706)
                          : const Color(0xFF059669)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRowInCard(bool isDark) {
    final catColorHex = _category?.color ?? '#E11D48';

    final catColor = BankIconRegistry.parseThemeColor(catColorHex,
        fallback: const Color(0xFFE11D48));

    final hasAsset = CategoryIconHelper.getAssetPath(_category?.icon) != null ||
        CategoryIconHelper.getAssetPath(_category?.name) != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh mục',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickCategory,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasAsset
                      ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                      : (isDark
                          ? catColor.withValues(alpha: 0.22)
                          : catColor.withValues(alpha: 0.12)),
                  border: Border.all(
                    color: catColor.withValues(alpha: isDark ? 0.45 : 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: catColor.withValues(alpha: isDark ? 0.20 : 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Center(
                    child: CategoryIconWidget(
                      icon: _category?.icon,
                      categoryName: _category?.name,
                      size: hasAsset ? 44 : 24,
                      color: catColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _category?.name ?? 'Chọn danh mục',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color:
                    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWalletRowInCard({
    required String title,
    required Wallet? wallet,
    required bool isDark,
    required VoidCallback onTap,
    bool isCreditCard = false,
  }) {
    final bankCode = wallet != null ? _inferBankCodeForWallet(wallet) : 'cash';

    final hasAsset = BankIconRegistry.getAssetPath(bankCode) != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              AdaptiveGlassSurface(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.22)
                        : (isCreditCard
                            ? const Color(0xFFD97706).withValues(alpha: 0.40)
                            : (hasAsset
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF00866A)
                                    .withValues(alpha: 0.35))),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.20 : 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: isCreditCard
                      ? Container(
                          color: isDark
                              ? const Color(0xFFD97706).withValues(alpha: 0.20)
                              : const Color(0xFFFEF3C7),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.credit_card_rounded,
                            size: 24,
                            color: Color(0xFFD97706),
                          ),
                        )
                      : (hasAsset
                          ? BankIcon(
                              bankCode: bankCode,
                              bankName: wallet?.bankName ?? wallet?.name,
                              size: 44,
                            )
                          : Container(
                              color: isDark
                                  ? const Color(0xFF064E3B)
                                      .withValues(alpha: 0.40)
                                  : const Color(0xFFE6F4EA),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 24,
                                color: Color(0xFF00866A),
                              ),
                            )),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet?.name ??
                          (isCreditCard ? 'Chọn thẻ nhận' : 'Chọn ví'),
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      wallet != null
                          ? (wallet.isCreditCard
                              ? 'Dư nợ ${Formatters.formatCurrency(wallet.currentDebt)}'
                              : 'Số dư ${Formatters.formatCurrency(wallet.balance)}')
                          : 'Chưa có ví',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color:
                    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateRowInCard({
    required bool isDark,
    required DateTime currentDt,
    required bool isToday,
    required bool isYesterday,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Ngày & giờ',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDatePill(
                      label: 'Hôm nay',
                      selected: isToday,
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
                    const SizedBox(width: 8),
                    _buildDatePill(
                      label: 'Hôm qua',
                      selected: isYesterday,
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
        const SizedBox(height: 10),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: Color(0xFF00866A),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${DateFormat('HH:mm').format(currentDt)} · ${DateFormat('dd/MM/yyyy').format(currentDt)}',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteRowInCard(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ghi chú',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _noteController,
            focusNode: _noteFocusNode,
            textCapitalization: TextCapitalization.sentences,
            maxLines: null,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'BeVietnamPro',
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'Thêm mô tả giao dịch...',
              hintStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                fontFamily: 'BeVietnamPro',
                color:
                    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
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
    );
  }

  Widget _buildMerchantSelector(bool isDark) {
    final provider = context.watch<TransactionProvider>();

    final allMerchants = _getAllMerchants(provider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Nơi mua (Tùy chọn) on left, Xem tất cả > on far right

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Nơi mua',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tùy chọn',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _showMerchantPickerModal,
              borderRadius: BorderRadius.circular(100),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xem tất cả',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF00866A),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: isDark
                          ? const Color(0xFF34D399)
                          : const Color(0xFF00866A),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Row 2: Horizontal chips

        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: allMerchants.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final m = allMerchants[i];

              final isSelected = (_merchantId == null && m.id.isEmpty) ||
                  (_merchantId == m.id);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    HapticFeedback.selectionClick();

                    setState(() {
                      if (m.id.isEmpty) {
                        _merchantId = null;

                        _merchantName = null;
                      } else {
                        _merchantId = m.id;

                        _merchantName = m.name;

                        _autoSelectWalletForMerchant(m.id, m.name);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(6, 5, 14, 5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? const Color(0xFF064E3B).withValues(alpha: 0.45)
                              : const Color(0xFFD1FAE5))
                          : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00866A)
                            : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0)),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMerchantChipIcon(m, isSelected, isDark),
                        const SizedBox(width: 8),
                        Text(
                          m.name,
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (isDark
                                    ? const Color(0xFF6EE7B7)
                                    : const Color(0xFF065F46))
                                : (isDark
                                    ? const Color(0xFFE2E8F0)
                                    : const Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMerchantChipIcon(
    ({String id, String name, String? asset, String icon, String? colorHex}) m,
    bool isSelected,
    bool isDark,
  ) {
    if (m.id.isEmpty) {
      // 'Không chọn'
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5))
              : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.storefront_rounded,
          size: 16,
          color: isSelected
              ? const Color(0xFF00866A)
              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
      );
    }

    return CategoryIconBadge(
      icon: m.icon,
      categoryName: m.name,
      colorHex: m.colorHex,
      size: 34,
      isDark: isDark,
    );
  }

  Widget _buildBentoSpenderTile(bool isDark) {
    final options = const [
      (tag: 'Chồng', role: 'husband'),
      (tag: 'Vợ', role: 'wife'),
      (tag: 'Chung', role: 'joint'),
    ];
    final currentTag = (_creatorTag ?? 'Chồng').trim();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 16,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              'Người chi',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.end,
            children: options.map((opt) {
              final isSelected =
                  currentTag.toLowerCase() == opt.tag.toLowerCase();
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _creatorTag = opt.tag;
                      _creatorName = opt.tag;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _activeTypeAccentColor.withValues(
                              alpha: isDark ? 0.22 : 0.12)
                          : (isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? _activeTypeAccentColor
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFE2E8F0)),
                        width: isSelected ? 1.3 : 0.9,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FinoraMemberAvatar(
                          member: opt.role,
                          size: 16,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            opt.tag,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 11.2,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? _activeTypeAccentColor
                                  : (isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF475569)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePill({
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? (isDark
                    ? const Color(0xFF064E3B).withValues(alpha: 0.5)
                    : const Color(0xFFD1FAE5))
                : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected
                  ? (isDark
                      ? const Color(0xFF059669).withValues(alpha: 0.4)
                      : const Color(0xFFA7F3D0))
                  : Colors.transparent,
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46))
                  : (isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }

  void _autoSelectWalletForMerchant(String merchantId, String merchantName) {
    if (merchantId.isEmpty && merchantName.isEmpty) return;

    final txProv = context.read<TransactionProvider>();

    final wallets = txProv.wallets;

    if (wallets.isEmpty) return;

    // 1. Check historical transactions for this merchant

    final mKey =
        (merchantId.isNotEmpty ? merchantId : merchantName).toLowerCase();

    final counts = <String, int>{};

    for (final tx in txProv.transactions) {
      final tMid = (tx.merchantId ?? '').toLowerCase();

      final tMname = (tx.merchantName ?? '').toLowerCase();

      if ((tMid.isNotEmpty && tMid == mKey) ||
          (tMname.isNotEmpty && tMname == mKey)) {
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

          FinoraNotice.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Đã chọn ví "${found.name}" theo thói quen mua tại $merchantName'),
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
      matched = wallets
          .where((w) => w.name.toLowerCase().contains('momo'))
          .firstOrNull;
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

        return wn.contains('techcombank') ||
            wb.contains('techcombank') ||
            wn.contains('tcb');
      }).firstOrNull;
    }

    if (matched != null && matched.id != _wallet?.id) {
      setState(() {
        _wallet = matched;

        _autoDetectSpenderFromWallet(matched);
      });

      FinoraNotice.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã gợi ý ví "${matched.name}" cho $merchantName'),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<({String id, String name, String? asset, String icon, String? colorHex})>
      _getAllMerchants(TransactionProvider provider) {
    List<Category> moreCategories = const [];
    try {
      moreCategories = context.read<MoreProvider>().categories;
    } catch (_) {}

    final mergedCustom = <Category>[
      ...moreCategories,
      ...provider.categories,
    ];
    final resolvedMerchants = Category.resolveMerchants(
      mergedCustom,
      deletedMerchantKeys: _deletedMerchantKeys,
    );

    return [
      (
        id: '',
        name: 'Không chọn',
        asset: null as String?,
        icon: 'shopping-bag',
        colorHex: null as String?,
      ),
      for (final m in resolvedMerchants)
        (
          id: m.id,
          name: m.name,
          asset: CategoryIconHelper.getAssetPath(m.icon),
          icon: m.icon,
          colorHex: m.color,
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
                                                    ? Colors.white
                                                        .withValues(alpha: 0.03)
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
                                              m.id.isEmpty
                                                  ? Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: isDark
                                                            ? Colors.white
                                                                .withValues(
                                                                    alpha: 0.08)
                                                            : const Color(
                                                                0xFFF1F5F9),
                                                        border: Border.all(
                                                          color: isDark
                                                              ? Colors.white12
                                                              : const Color(
                                                                  0xFFE2E8F0),
                                                        ),
                                                      ),
                                                      alignment:
                                                          Alignment.center,
                                                      child: Icon(
                                                        Icons
                                                            .storefront_outlined,
                                                        size: 20,
                                                        color:
                                                            secondaryTextColor,
                                                      ),
                                                    )
                                                  : CategoryIconBadge(
                                                      icon: m.icon,
                                                      categoryName: m.name,
                                                      colorHex: m.colorHex,
                                                      size: 44,
                                                      isDark: isDark,
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

  Widget _buildSaveButton(bool isDark) {
    final valid = _isValid();
    final studio = context.watch<ThemeStudioController?>();
    final blurSigma = (studio?.appBarBlur ?? 22.0).clamp(12.0, 30.0);

    final label = widget.existing != null
        ? 'Cập nhật giao dịch'
        : switch (_type) {
            'expense' => 'Lưu chi tiêu',
            'income' => 'Lưu thu nhập',
            'transfer' => 'Lưu chuyển khoản',
            'credit_card_payment' => 'Lưu thanh toán thẻ',
            'investment' => 'Lưu đầu tư',
            _ => 'Lưu giao dịch',
          };

    final accent = _activeTypeAccentColor;
    final secondaryAccent = accent == const Color(0xFFE11D48)
        ? const Color(0xFFF43F5E)
        : accent == const Color(0xFF00866A)
            ? const Color(0xFF10B981)
            : accent == const Color(0xFF0284C7)
                ? const Color(0xFF38BDF8)
                : accent == const Color(0xFFD97706)
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF0D9488);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: valid
                  ? accent.withValues(alpha: isDark ? 0.36 : 0.26)
                  : Colors.black.withValues(alpha: isDark ? 0.24 : 0.06),
              blurRadius: 20,
              spreadRadius: -2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: valid
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: isDark ? 0.80 : 0.86),
                          secondaryAccent.withValues(
                              alpha: isDark ? 0.74 : 0.82),
                        ],
                      )
                    : null,
                color: valid
                    ? null
                    : (isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.68)
                        : Colors.white.withValues(alpha: 0.72)),
                border: Border.all(
                  color: valid
                      ? Colors.white.withValues(alpha: 0.32)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : const Color(0xFFCBD5E1).withValues(alpha: 0.75)),
                  width: 1.1,
                ),
              ),
              child: TextButton(
                key: const ValueKey('transaction-save'),
                onPressed: valid ? _save : null,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  disabledForegroundColor: isDark
                      ? const Color(0xFFA2B9AE)
                      : const Color(0xFF475569),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.check_circle_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(label,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w800)),
                        ])),
              ),
            ),
          ),
        ),
      ),
    );
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

              // 4. Action Buttons (Twin Stadium Pills matching FinoraDatePickerSheet)

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          'Hủy',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: secondaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Material(
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
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF003D35),
                                Color(0xFF00866A),
                                Color(0xFF10B981)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00866A)
                                    .withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
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
                                  'Áp dụng',
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
                  ),
                ],
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
    return AdaptiveGlassSurface(
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

class _CategoryGridTile extends StatelessWidget {
  final Category category;

  final bool selected;

  final Color accentColor;

  final VoidCallback onTap;

  const _CategoryGridTile({
    required this.category,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final catColor = BankIconRegistry.parseThemeColor(category.color);

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? accentColor.withValues(alpha: isDark ? 0.26 : 0.16)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? accentColor
                    : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                width: selected ? 1.8 : 1.0,
              ),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: accentColor.withValues(alpha: isDark ? 0.40 : 0.28),
                    blurRadius: 12,
                    spreadRadius: -1,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    CategoryIconBadge(
                      icon: category.icon,
                      categoryName: category.name,
                      color: catColor,
                      size: 38,
                      isDark: isDark,
                    ),
                    if (selected)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: AdaptiveGlassSurface(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isDark ? const Color(0xFF1E293B) : Colors.white,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(Icons.check,
                              size: 9, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    category.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
