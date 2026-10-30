import 'dart:ui';

import '../../core/widgets/finora_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/finora_mascot.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../data/services/local_assistant_service.dart';
import 'assistant_response_body.dart';
import '../../data/services/finora_nlp_engine.dart';
import '../../data/models/category.dart';
import '../../data/models/finance_models.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../state/transaction_provider.dart';
import '../../state/budget_provider.dart';
import '../../state/theme_studio_controller.dart';
import '../../core/theme/finora_tokens.dart';

/// Free on-device assistant for ledger reports and confirmed income/expense drafts.
class AiAdvisorScreen extends StatefulWidget {
  final String userId;
  final String? familyId;
  final String? screenContext;
  const AiAdvisorScreen({
    super.key,
    required this.userId,
    this.familyId,
    this.screenContext,
  });

  @override
  State<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends State<AiAdvisorScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<({String text, bool user, String source})> _messages = [];
  List<SmartTransactionParsed> _pendingTransactions = [];
  String _conversationPrompt = '';
  bool _busy = false;
  bool _savingDrafts = false;
  final Map<SmartTransactionParsed, String> _draftIds = {};
  final Map<SmartTransactionParsed, String> _draftWalletIds = {};
  final Map<SmartTransactionParsed, String> _draftCategoryIds = {};

  final List<String> _quickSuggestions = const [
    '🍽️ Ăn uống tháng này đã chi bao nhiêu?',
    '💰 Gợi ý tiết kiệm từ chi tiêu thực tế',
    '💳 Kiểm tra hạn mức thẻ tín dụng',
    'Hướng dẫn ghi giao dịch bằng trò chuyện',
    '📈 So sánh chi tiêu với tháng trước',
    '📊 Cơ cấu thu chi tháng này thế nào?',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context
            .read<TransactionProvider>()
            .load(widget.userId, familyId: widget.familyId);
        context
            .read<BudgetProvider?>()
            ?.load(widget.userId, familyId: widget.familyId);
      }
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _sendPrompt(String prompt) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty || _busy || _savingDrafts) return;
    if (_pendingTransactions.isNotEmpty) {
      FinoraNotice.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Hãy lưu hoặc hủy bản nháp hiện tại trước khi gửi yêu cầu mới.')));
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _messages.add((text: cleanPrompt, user: true, source: 'user'));
      _busy = true;
      _input.clear();
    });

    _scrollToBottom();

    try {
      final txProvider = context.read<TransactionProvider>();
      final budgetProvider = context.read<BudgetProvider?>();
      final answer = LocalAssistantService.reply(
        prompt: cleanPrompt,
        transactions: txProvider.transactions,
        wallets: txProvider.wallets,
        categories: txProvider.categories,
        dataReady: !txProvider.isRefreshing && txProvider.error == null,
        now: DateTime.now(),
        previousPrompt: _conversationPrompt,
        budgets:
            budgetProvider?.budgetsWithSpent.map((b) => b.budget).toList() ??
                const [],
        budgetsReady: budgetProvider != null &&
            !budgetProvider.isRefreshing &&
            budgetProvider.error == null,
      );
      if (mounted) {
        setState(() {
          _messages.add((text: answer.text, user: false, source: 'local'));
          _conversationPrompt = answer.contextPrompt ?? cleanPrompt;
          _pendingTransactions = answer.transactions;
          _draftIds.clear();
          _draftWalletIds.clear();
          _draftCategoryIds.clear();
          for (var i = 0; i < answer.transactions.length; i++) {
            _draftIds[answer.transactions[i]] =
                'ai_${DateTime.now().microsecondsSinceEpoch}_$i';
          }
        });
      }
    } catch (error) {
      if (mounted)
        setState(() {
          _messages.add((
            text: 'Chưa thể xử lý yêu cầu. Hãy thử lại.',
            user: false,
            source: 'status'
          ));
        });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _scrollToBottom();
      }
    }
  }

  Category? _resolveCategory(
      SmartTransactionParsed draft, List<Category> categories) {
    final compatible = categories.where((category) {
      final expected = draft.type == 'income' ? 'income' : 'expense';
      return !category.isArchived && category.categoryGroup == expected;
    });
    final selectedId = _draftCategoryIds[draft];
    final matches = compatible
        .where((c) => selectedId != null
            ? c.id == selectedId
            : draft.categoryName != null &&
                FinoraNlpEngine.normalize(c.name) ==
                    FinoraNlpEngine.normalize(draft.categoryName!))
        .toList();
    return matches.length == 1 ? matches.single : null;
  }

  Wallet? _resolveWallet(SmartTransactionParsed draft, List<Wallet> wallets) {
    final selectedId = _draftWalletIds[draft];
    final matches = wallets
        .where((w) => selectedId != null
            ? w.id == selectedId
            : draft.walletName != null &&
                FinoraNlpEngine.normalize(w.name) ==
                    FinoraNlpEngine.normalize(draft.walletName!))
        .toList();
    return matches.length == 1 ? matches.single : null;
  }

  void _updateDraft(SmartTransactionParsed draft,
      {String? walletName,
      String? categoryName,
      String? walletId,
      String? categoryId}) {
    final replacement = SmartTransactionParsed(
        type: draft.type,
        amount: draft.amount,
        note: draft.note,
        date: draft.date,
        walletName: walletName ?? draft.walletName,
        categoryName: categoryName ?? draft.categoryName);
    setState(() {
      final index = _pendingTransactions.indexOf(draft);
      if (index < 0) return;
      _pendingTransactions[index] = replacement;
      _draftIds[replacement] = _draftIds.remove(draft) ??
          'ai_${DateTime.now().microsecondsSinceEpoch}';
      final oldWallet = _draftWalletIds.remove(draft);
      final oldCategory = _draftCategoryIds.remove(draft);
      if (walletId ?? oldWallet case final String id)
        _draftWalletIds[replacement] = id;
      if (categoryId ?? oldCategory case final String id)
        _draftCategoryIds[replacement] = id;
    });
  }

  Future<void> _savePendingTransactions() async {
    if (_pendingTransactions.isEmpty || _savingDrafts) return;
    final provider = context.read<TransactionProvider>();
    setState(() => _savingDrafts = true);
    try {
      for (final draft
          in List<SmartTransactionParsed>.of(_pendingTransactions)) {
        final category = _resolveCategory(draft, provider.categories);
        final wallet = _resolveWallet(draft, provider.wallets);
        if (category == null || wallet == null) {
          throw StateError('Thiếu ví hoặc danh mục phù hợp');
        }
        final owner = draft.owner ?? wallet.owner;
        final ownerName = draft.ownerName ?? wallet.ownerName;
        final ownerTag = owner == 'wife'
            ? 'Vợ'
            : owner == 'joint'
                ? 'Chung'
                : 'Chồng';
        await provider.createTransaction(
          widget.userId,
          TransactionModel(
            id: _draftIds[draft] ??=
                'ai_${DateTime.now().microsecondsSinceEpoch}',
            userId: widget.userId,
            amount: draft.amount,
            type: draft.type == 'income' ? 'income' : 'expense',
            date: draft.date,
            note: draft.note,
            categoryId: category.id,
            categoryName: category.name,
            categoryIcon: category.icon,
            categoryColor: category.color,
            categoryGroup: category.categoryGroup,
            walletId: wallet.id,
            walletName: wallet.name,
            owner: owner,
            ownerName: ownerName,
            creatorTag: ownerTag,
            tags: [ownerTag, 'Trợ lí FINORA'],
          ),
        );
        _pendingTransactions.remove(draft);
        _draftIds.remove(draft);
        _draftWalletIds.remove(draft);
        _draftCategoryIds.remove(draft);
      }
      if (!mounted) return;
      setState(() {
        _pendingTransactions = [];
        _messages.add((
          text: 'Đã lưu các giao dịch đã xác nhận vào sổ.',
          user: false,
          source: 'status',
        ));
      });
    } catch (_) {
      if (mounted) {
        FinoraNotice.of(context).showSnackBar(const SnackBar(
          content:
              Text('Chưa thể lưu. Hãy kiểm tra ví và danh mục rồi thử lại.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _savingDrafts = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final primaryAccent = studio?.primaryColor ?? const Color(0xFF2563EB);

    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    final headerBlur = (studio?.appBarBlur ?? 18.0).clamp(0.0, 32.0);
    final headerAlpha =
        (studio?.appBarOpacity ?? (isDark ? 0.84 : 0.88)).clamp(0.15, 1.0);
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: AmbientFloatingBackground(child: SizedBox.expand()),
            ),
          ),
          Column(
            children: [
              // Sticky Blur Header aligned with all main screens
              ClipRect(
                child: BackdropFilter(
                  filter:
                      ImageFilter.blur(sigmaX: headerBlur, sigmaY: headerBlur),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      MediaQuery.of(context).padding.top + 8,
                      16,
                      12,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF0B131E) : Colors.white)
                          .withValues(alpha: headerAlpha),
                      border: Border(
                        bottom: BorderSide(color: borderColor, width: 0.8),
                      ),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 780),
                        child: Row(
                          children: [
                            if (canPop) ...[
                              InkWell(
                                onTap: () => Navigator.of(context).maybePop(),
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : const Color(0xFFF1F5F9),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 16,
                                    color: primaryTextColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ] else ...[
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF10B981),
                                      Color(0xFF059669),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981)
                                          .withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Trợ lý AI FINORA',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: primaryTextColor,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  Text(
                                    'Miễn phí • Xử lý trên máy',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_messages.isNotEmpty)
                              InkWell(
                                onTap: _busy || _savingDrafts
                                    ? null
                                    : () => setState(() {
                                          _messages.clear();
                                          _conversationPrompt = '';
                                          _pendingTransactions = [];
                                        }),
                                borderRadius: BorderRadius.circular(999),
                                child: Tooltip(
                                  message: 'Làm mới cuộc trò chuyện',
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : const Color(0xFFF1F5F9),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Icon(
                                      Icons.refresh_rounded,
                                      size: 18,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 780),
                    child: Column(
                      children: [
                        // CHAT & BENTO CONTENT
                        Expanded(
                          child: ListView(
                            controller: _scroll,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              12,
                              16,
                              16,
                            ),
                            children: [
                    if (_messages.isEmpty) ...[
                      const SizedBox(height: 10),

                      // 2.1 HERO AI INTELLIGENCE CORE (Cosmic Radiant Orb)
                      _buildHeroAiCore(
                        isDark: isDark,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                        primaryAccent: primaryAccent,
                      ),
                      const SizedBox(height: 24),

                      // 2.2 4 CAPABILITY BENTO CARDS (2x2 Grid)
                      _buildBentoCapabilityGrid(
                        isDark: isDark,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                      const SizedBox(height: 22),

                      // 2.3 QUICK SUGGESTIONS CAROUSEL
                      _buildQuickSuggestionsSection(
                        isDark: isDark,
                        primaryTextColor: primaryTextColor,
                        primaryAccent: primaryAccent,
                      ),
                      const SizedBox(height: 12),
                    ] else
                      for (final m in _messages)
                        _buildChatBubble(
                          m,
                          isDark,
                          primaryTextColor,
                          primaryAccent,
                          studio,
                        ),
                    if (_pendingTransactions.isNotEmpty)
                      _buildTransactionDraftCard(
                        isDark: isDark,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                    if (_messages.isNotEmpty &&
                        _pendingTransactions.isEmpty &&
                        !_busy)
                      Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: Wrap(spacing: 8, runSpacing: 6, children: [
                            for (final suggestion in [
                              'Liệt kê từng khoản',
                              'So sánh với tháng trước',
                              'Gợi ý cắt giảm'
                            ])
                              ActionChip(
                                  label: Text(suggestion,
                                      style: const TextStyle(fontSize: 11)),
                                  onPressed: () => _sendPrompt(suggestion)),
                          ])),
                    if (_busy)
                      _buildTypingIndicator(
                        isDark,
                        secondaryTextColor,
                        primaryAccent,
                      ),
                  ],
                ),
              ),

              // 3. BOTTOM FLOATING LIQUID GLASS INPUT BAR
              _buildFloatingInputBar(
                isDark: isDark,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                primaryAccent: primaryAccent,
              ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TOP BAR
  // ==========================================
  Widget _buildHeroAiCore({
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color primaryAccent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: FinoraTokens.surface(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: FinoraTokens.line(isDark),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          FinoraAmbientMascotWatermark(
            pose: FinoraMascotPose.thinking,
            size: 132,
            opacity: isDark ? 0.10 : 0.08,
            right: -18,
            bottom: -18,
          ),
          Column(
            children: [
              Center(
                child: Container(
                  width: 82,
                  height: 82,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark
                            ? const Color(0xFF0F6E56)
                            : const Color(0xFFE8F5F0))
                        .withValues(alpha: isDark ? 0.35 : 0.65),
                    border: Border.all(
                      color: const Color(0xFF10B981)
                          .withValues(alpha: isDark ? 0.40 : 0.30),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981)
                            .withValues(alpha: isDark ? 0.25 : 0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/mascot/animation-keypose-01-idle.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/mascot/expression-01-happy.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Trợ lí FINORA',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: FinoraTokens.ink(isDark),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Trả lời ngắn gọn, đúng trọng tâm số liệu thực tế & soạn giao dịch tức thì.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: FinoraTokens.inkSecondary(isDark),
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTelemetryBadge(
                    icon: Icons.bolt_rounded,
                    label: 'Ngắn gọn · Đúng trọng tâm',
                    color: FinoraTokens.ink(isDark),
                    isDark: isDark,
                  ),
                  _buildTelemetryBadge(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Số liệu thực tế',
                    color: FinoraTokens.pos(isDark),
                    isDark: isDark,
                  ),
                  _buildTelemetryBadge(
                    icon: Icons.shield_outlined,
                    label: 'Bảo mật gia đình',
                    color: FinoraTokens.inkSecondary(isDark),
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryBadge({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: FinoraTokens.surface(isDark),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: FinoraTokens.line(isDark),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: FinoraTokens.ink(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4 CAPABILITY BENTO CARDS
  // ==========================================
  Widget _buildBentoCapabilityGrid({
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                icon: Icons.pie_chart_rounded,
                gradient: const [Color(0xFF2563EB), Color(0xFF38BDF8)],
                title: 'Phân tích chi tiêu',
                subtitle: 'Tổng thu chi và chi theo danh mục tháng này',
                tag: 'Báo cáo ➔',
                isDark: isDark,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                onTap: () => _sendPrompt(
                    'Phân tích chi tiết cơ cấu chi tiêu tháng này giúp tôi'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoCard(
                icon: Icons.lightbulb_rounded,
                gradient: const [Color(0xFFEA580C), Color(0xFFFBBF24)],
                title: 'Gợi ý tiết kiệm',
                subtitle: 'Rà soát danh mục chi nhiều nhất trong sổ',
                tag: 'Tối ưu ➔',
                isDark: isDark,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                onTap: () => _sendPrompt(
                    'Gợi ý cách tối ưu chi tiêu và cắt giảm chi phí tháng này'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                icon: Icons.trending_up_rounded,
                gradient: const [Color(0xFF059669), Color(0xFF34D399)],
                title: 'So sánh chi tiêu',
                subtitle: 'Đối chiếu chi tháng này với tháng trước',
                tag: 'So sánh ➔',
                isDark: isDark,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                onTap: () => _sendPrompt('So sánh chi tiêu với tháng trước'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoCard(
                icon: Icons.shield_rounded,
                gradient: const [Color(0xFFE11D48), Color(0xFFFB7185)],
                title: 'Nợ thẻ tín dụng',
                subtitle: 'Dư nợ, hạn mức và ngày thanh toán đã cài',
                tag: 'Xem thẻ ➔',
                isDark: isDark,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                onTap: () => _sendPrompt(
                    'Số dư và nợ thẻ và hạn mức thẻ tín dụng có khoản nào vượt ngưỡng không?'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoCard({
    required IconData icon,
    required List<Color> gradient,
    required String title,
    required String subtitle,
    required String tag,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: FinoraTokens.surface(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: FinoraTokens.line(isDark),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
              blurRadius: 6,
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
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: FinoraTokens.ink(isDark)
                        .withValues(alpha: isDark ? 0.12 : 0.06),
                  ),
                  child: Icon(icon, color: FinoraTokens.ink(isDark), size: 17),
                ),
                const SizedBox(width: 6),
                Flexible(
                    child: Text(
                  tag,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: FinoraTokens.inkSecondary(isDark),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: FinoraTokens.ink(isDark),
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: FinoraTokens.inkSecondary(isDark),
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // QUICK SUGGESTIONS CAROUSEL
  // ==========================================
  Widget _buildQuickSuggestionsSection({
    required bool isDark,
    required Color primaryTextColor,
    required Color primaryAccent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'GỢI Ý HỎI NHANH',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: FinoraTokens.inkSecondary(isDark),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _quickSuggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final prompt = _quickSuggestions[i];
              return InkWell(
                onTap: () => _sendPrompt(prompt),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: FinoraTokens.surface(isDark),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: FinoraTokens.line(isDark),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    prompt,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: FinoraTokens.ink(isDark),
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

  // ==========================================
  // CHAT BUBBLES
  // ==========================================
  Widget _buildChatBubble(
    ({String text, bool user, String source}) message,
    bool isDark,
    Color primaryTextColor,
    Color primaryAccent,
    ThemeStudioController? studio,
  ) {
    if (message.user) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: FinoraTokens.ink(isDark),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF141518) : Colors.white,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(top: 2, right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF0F6E56).withValues(alpha: 0.30)
                    : const Color(0xFFE8F5F0),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/mascot/expression-03-focused.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.auto_awesome_rounded,
                    color: FinoraTokens.ink(isDark),
                    size: 16,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
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
                    Row(
                      children: [
                        Text(
                          message.source == 'local'
                              ? 'FINORA · Trên máy'
                              : 'Finora · Thông báo',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: FinoraTokens.ink(isDark),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: message.text));
                            FinoraNotice.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã sao chép phản hồi'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(Icons.copy_rounded,
                                  size: 18,
                                  color: FinoraTokens.inkSecondary(isDark))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AssistantResponseBody(text: message.text),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(
    bool isDark,
    Color secondaryTextColor,
    Color primaryAccent,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, left: 42),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: FinoraTokens.surface(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: FinoraTokens.line(isDark),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: FinoraTokens.ink(isDark),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Finora đang phân tích dữ liệu...',
              style: TextStyle(
                fontSize: 12,
                color: FinoraTokens.inkSecondary(isDark),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDraftCard({
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final provider = context.read<TransactionProvider>();
    return Container(
      margin: const EdgeInsets.only(left: 42, bottom: 14),
      padding: const EdgeInsets.all(14),
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
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 16, color: FinoraTokens.ink(isDark)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bản nháp giao dịch Finora',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: FinoraTokens.ink(isDark),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: FinoraTokens.ink(isDark)
                      .withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${_pendingTransactions.length} mục',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: FinoraTokens.ink(isDark),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._pendingTransactions.map((draft) {
            final category = _resolveCategory(draft, provider.categories);
            final wallet = _resolveWallet(draft, provider.wallets);
            final positive = draft.type == 'income';
            final statusColor =
                positive ? FinoraTokens.pos(isDark) : FinoraTokens.neg(isDark);
            return Column(children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        positive
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                        size: 15,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            draft.note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: FinoraTokens.ink(isDark),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ngày ${DateTime.fromMillisecondsSinceEpoch(draft.date).day}/${DateTime.fromMillisecondsSinceEpoch(draft.date).month}/${DateTime.fromMillisecondsSinceEpoch(draft.date).year}',
                            style: TextStyle(
                                fontSize: 11,
                                color: FinoraTokens.inkSecondary(isDark)),
                          ),
                          Text(
                            '${category?.name ?? "Chưa có danh mục"} • ${wallet?.name ?? "Chưa có ví"}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: FinoraTokens.inkSecondary(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${positive ? "+" : "-"}${_formatAmount(draft.amount)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: wallet?.id,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Chọn ví'),
                items: provider.wallets
                    .map((w) =>
                        DropdownMenuItem(value: w.id, child: Text(w.name)))
                    .toList(),
                onChanged: _savingDrafts
                    ? null
                    : (id) {
                        final w = provider.wallets
                            .where((w) => w.id == id)
                            .firstOrNull;
                        if (w != null)
                          _updateDraft(draft,
                              walletName: w.name, walletId: w.id);
                      },
              ),
              DropdownButtonFormField<String>(
                initialValue: category?.id,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Chọn danh mục'),
                items: provider.categories
                    .where(
                        (c) => !c.isArchived && c.categoryGroup == draft.type)
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: _savingDrafts
                    ? null
                    : (id) {
                        final c = provider.categories
                            .where((c) => c.id == id)
                            .firstOrNull;
                        if (c != null)
                          _updateDraft(draft,
                              categoryName: c.name, categoryId: c.id);
                      },
              ),
              const SizedBox(height: 16),
            ]);
          }),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _savingDrafts
                      ? null
                      : () => setState(() => _pendingTransactions = []),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FinoraTokens.ink(isDark),
                    side: BorderSide(color: FinoraTokens.line(isDark)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _savePendingTransactions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FinoraTokens.ink(isDark),
                    foregroundColor:
                        isDark ? const Color(0xFF141518) : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _savingDrafts
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                isDark ? const Color(0xFF141518) : Colors.white,
                          ),
                        )
                      : const Text('Xác nhận lưu',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    final value = amount.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < value.length; index++) {
      if (index > 0 && (value.length - index) % 3 == 0) buffer.write('.');
      buffer.write(value[index]);
    }
    return '${buffer.toString()} ₫';
  }

  // ==========================================
  // BOTTOM MINIMALIST FLOATING INPUT BAR
  // ==========================================
  Widget _buildFloatingInputBar({
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color primaryAccent,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).viewInsets.bottom > 0
            ? 8
            : MediaQuery.paddingOf(context).bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: FinoraTokens.surface(isDark),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: FinoraTokens.line(isDark),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: FinoraTokens.inkSecondary(isDark),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textCapitalization: TextCapitalization.sentences,
                      inputFormatters: const [FinoraCapitalizeFirstFormatter()],
                      textInputAction: TextInputAction.send,
                      style: TextStyle(
                        fontSize: 14,
                        color: FinoraTokens.ink(isDark),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nhập thu chi hoặc hỏi số dư…',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: FinoraTokens.inkSecondary(isDark),
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                        fillColor: Colors.transparent,
                        isCollapsed: true,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (val) => _sendPrompt(val),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Minimalist Ink Circular Send Button
          InkWell(
            onTap: () => _sendPrompt(_input.text),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FinoraTokens.ink(isDark),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                color: isDark ? const Color(0xFF141518) : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
