import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../domain/finance/finance_summary.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/finora_nlp_engine.dart';
import '../../data/models/category.dart';
import '../../data/models/finance_models.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../state/dashboard_provider.dart';
import '../../state/transaction_provider.dart';
import '../../state/theme_studio_controller.dart';
import '../../core/theme/finora_tokens.dart';

/// Cố vấn tài chính AI thông minh Finora AI
/// Thiết kế chuẩn Liquid Glass, Ambient Floating Background, Bento Grid & Capsule Chat Experience
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
  final List<({String text, bool user})> _messages = [];
  List<SmartTransactionParsed> _pendingTransactions = [];
  bool _busy = false;
  bool _savingDrafts = false;

  final List<String> _quickSuggestions = const [
    '🍽️ Ăn uống tháng này đã chi bao nhiêu?',
    '💰 Mẹo tiết kiệm thêm 2 triệu tháng này',
    '💳 Kiểm tra hạn mức thẻ tín dụng',
    '⚡ Ghi nhanh: Đổ xăng 80k Momo',
    '📈 Dự báo dòng tiền 30 ngày tới',
    '📊 Cơ cấu thu chi tháng này thế nào?',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context
            .read<DashboardProvider>()
            .load(widget.userId, familyId: widget.familyId);
        context
            .read<TransactionProvider>()
            .load(widget.userId, familyId: widget.familyId);
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
    if (cleanPrompt.isEmpty || _busy) return;

    HapticFeedback.lightImpact();
    setState(() {
      _messages.add((text: cleanPrompt, user: true));
      _busy = true;
      _input.clear();
    });

    _scrollToBottom();

    Map<String, dynamic>? financeContext;

    try {
      final d = context.read<DashboardProvider>();
      final txProvider = context.read<TransactionProvider>();
      final now = DateTime.now();
      final summary = FinanceSummary.from(
        d.data.allTransactions.where(FinanceScope.month(now).contains),
      );

      final history = _messages
          .skip(_messages.length > 6 ? _messages.length - 6 : 0)
          .map((m) => {
                'role': m.user ? 'user' : 'model',
                'parts': [
                  {'text': m.text}
                ],
              })
          .toList();

      final parsed = FinoraNlpEngine.extractTransactions(
        message: cleanPrompt,
        categories: txProvider.categories,
        wallets: txProvider.wallets,
      )
          .where((draft) => draft.type == 'income' || draft.type == 'expense')
          .toList();
      if (parsed.isNotEmpty && !FinoraNlpEngine.isFinancialQuery(cleanPrompt)) {
        if (mounted) {
          setState(() {
            _pendingTransactions = parsed;
            _messages.add((
              text:
                  'Mình đã hiểu ${parsed.length} giao dịch. Hãy kiểm tra bản nháp bên dưới trước khi lưu.',
              user: false,
            ));
          });
        }
        return;
      }

      final recent = txProvider.transactions
          .take(40)
          .map((tx) => {
                'date': tx.date,
                'amount': tx.amount,
                'type': tx.type,
                'title': tx.note ?? tx.categoryName ?? 'Giao dịch',
                'category': tx.categoryName,
                'wallet': tx.walletName,
                'owner': tx.owner,
              })
          .toList();
      financeContext = <String, dynamic>{
        'period': '${now.year}-${now.month}',
        'currency': 'VND',
        'income': summary.income,
        'expense': summary.expense,
        'balance': txProvider.wallets
            .where((wallet) => !wallet.isCreditCard)
            .fold<int>(0, (sum, wallet) => sum + wallet.balance),
        'wallets': txProvider.wallets
            .map((wallet) => {
                  'name': wallet.name,
                  'type': wallet.type,
                  'owner': wallet.owner,
                  'balance': wallet.balance,
                  'currentDebt': wallet.currentDebt,
                })
            .toList(),
        'categoryTotals': _categoryTotals(txProvider.transactions, now),
        'recentTransactions': recent,
      };

      var answer = await AiService.getFinancialAdvice(
        prompt: cleanPrompt,
        chatHistory: history,
        throwOnError: false,
        userFinanceContext: financeContext,
      );
      if (answer.startsWith('Finora AI chưa được cấu hình') ||
          answer.startsWith('Không thể kết nối Finora AI') ||
          answer.startsWith('Máy chủ Finora AI đang bận')) {
        answer = FinoraNlpEngine.generateFinancialAdvice(
              query: cleanPrompt,
              financeContext: financeContext,
              categories: txProvider.categories,
              wallets: txProvider.wallets,
            ).replyText ??
            'Mình chưa đủ dữ liệu để đưa ra phân tích phù hợp.';
      }

      if (mounted) {
        setState(() {
          _messages.add((text: answer, user: false));
        });
      }
    } catch (_) {
      if (mounted) {
        final fallback = FinoraNlpEngine.generateFinancialAdvice(
              query: cleanPrompt,
              financeContext: financeContext,
              categories: context.read<TransactionProvider>().categories,
              wallets: context.read<TransactionProvider>().wallets,
            ).replyText ??
            'Finora AI luôn sẵn sàng đồng hành cùng bạn quản lý chi tiêu hiệu quả.';
        setState(() {
          _messages.add((
            text: fallback,
            user: false,
          ));
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _scrollToBottom();
      }
    }
  }

  Map<String, int> _categoryTotals(
      List<TransactionModel> transactions, DateTime now) {
    final totals = <String, int>{};
    for (final tx in transactions) {
      final date = DateTime.fromMillisecondsSinceEpoch(
        tx.date < 100000000000 ? tx.date * 1000 : tx.date,
      );
      if (date.year != now.year || date.month != now.month) continue;
      if (tx.type != 'expense') continue;
      final name = tx.categoryName ?? 'Khác';
      totals[name] = (totals[name] ?? 0) + tx.amount;
    }
    return totals;
  }

  Category? _resolveCategory(
      SmartTransactionParsed draft, List<Category> categories) {
    final compatible = categories.where((category) {
      final expected = draft.type == 'income' ? 'income' : 'expense';
      return category.categoryGroup == expected;
    });
    final wanted = FinoraNlpEngine.normalize(draft.categoryName ?? '');
    for (final category in compatible) {
      if (FinoraNlpEngine.normalize(category.name) == wanted) return category;
    }
    return compatible.isEmpty ? null : compatible.first;
  }

  Wallet? _resolveWallet(SmartTransactionParsed draft, List<Wallet> wallets) {
    final wanted = FinoraNlpEngine.normalize(draft.walletName ?? '');
    for (final wallet in wallets) {
      if (FinoraNlpEngine.normalize(wallet.name) == wanted) return wallet;
    }
    final ownerMatches = wallets.where((wallet) =>
        draft.owner == null || wallet.owner.toLowerCase() == draft.owner);
    return ownerMatches.isNotEmpty
        ? ownerMatches.first
        : (wallets.isEmpty ? null : wallets.first);
  }

  Future<void> _savePendingTransactions() async {
    if (_pendingTransactions.isEmpty || _savingDrafts) return;
    final provider = context.read<TransactionProvider>();
    setState(() => _savingDrafts = true);
    try {
      for (final draft in _pendingTransactions) {
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
            tags: [ownerTag, 'Finora AI'],
          ),
        );
      }
      if (!mounted) return;
      final count = _pendingTransactions.length;
      setState(() {
        _pendingTransactions = [];
        _messages.add((
          text:
              'Đã lưu $count giao dịch và cập nhật số dư, báo cáo, ngân sách.',
          user: false,
        ));
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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

    return GlassScaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassTopBar(
        title: 'Trợ lý Finora AI',
        titleWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Trợ lý',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: FinoraTokens.ink(isDark),
              ),
            ),
            Text(
              'Dựa trên dữ liệu của bạn',
              style: TextStyle(
                fontSize: 11,
                color: FinoraTokens.inkSecondary(isDark),
              ),
            ),
          ],
        ),
        showBottomDivider: true,
        onBack: () => Navigator.of(context).maybePop(),
        actions: _messages.isEmpty
            ? const []
            : [
                IconButton(
                  tooltip: 'Làm mới cuộc trò chuyện',
                  icon: Icon(Icons.refresh_rounded,
                      color: FinoraTokens.ink(isDark)),
                  onPressed: () => setState(() {
                    _messages.clear();
                    _pendingTransactions = [];
                  }),
                ),
              ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Column(
            children: [
              // CHAT & BENTO CONTENT
              Expanded(
                child: ListView(
                  controller: _scroll,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    GlassScaffold.topInset(context, 10),
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
    return Column(
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: FinoraTokens.ink(isDark)
                  .withValues(alpha: isDark ? 0.12 : 0.06),
              border: Border.all(
                color: FinoraTokens.line(isDark),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 28,
                color: FinoraTokens.ink(isDark),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Trợ lý Finora AI',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: FinoraTokens.ink(isDark),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Cố vấn tài chính thông minh của gia đình bạn. Sẵn sàng bóc tách cơ cấu chi tiêu, đề xuất tiết kiệm và phân tích dòng tiền.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: FinoraTokens.inkSecondary(isDark),
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTelemetryBadge(
              icon: Icons.bolt_rounded,
              label: 'Gemini Brain',
              color: FinoraTokens.ink(isDark),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildTelemetryBadge(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Dữ liệu thực tế',
              color: FinoraTokens.pos(isDark),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildTelemetryBadge(
              icon: Icons.shield_outlined,
              label: 'Bảo mật gia đình',
              color: FinoraTokens.inkSecondary(isDark),
              isDark: isDark,
            ),
          ],
        ),
      ],
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
                subtitle: 'Bóc tách cơ cấu chi & so sánh với tháng trước',
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
                subtitle: 'Mẹo cắt giảm chi phí & phát hiện khoản bất thường',
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
                title: 'Dự báo tài chính',
                subtitle: 'Mô phỏng dòng tiền & điểm an toàn 30 ngày tới',
                tag: 'Dự báo ➔',
                isDark: isDark,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                onTap: () => _sendPrompt(
                    'Dự báo xu hướng tài chính và số dư 30 ngày tới cho tôi'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoCard(
                icon: Icons.shield_rounded,
                gradient: const [Color(0xFFE11D48), Color(0xFFFB7185)],
                title: 'An toàn ngân sách',
                subtitle: 'Quét cảnh báo hạn mức thẻ tín dụng & vượt chi',
                tag: 'Quét rủi ro ➔',
                isDark: isDark,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                onTap: () => _sendPrompt(
                    'Kiểm tra ngân sách và hạn mức thẻ tín dụng có khoản nào vượt ngưỡng không?'),
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
                Text(
                  tag,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: FinoraTokens.inkSecondary(isDark),
                  ),
                ),
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
    ({String text, bool user}) message,
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
        margin: const EdgeInsets.only(bottom: 16, right: 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(top: 2, right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: FinoraTokens.surface(isDark),
                border: Border.all(
                  color: FinoraTokens.line(isDark),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: FinoraTokens.ink(isDark),
                size: 16,
              ),
            ),
            Expanded(
              child: Container(
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
                        Text(
                          'Finora',
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã sao chép phản hồi'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: FinoraTokens.inkSecondary(isDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: FinoraTokens.ink(isDark),
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
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
            final statusColor = positive
                ? FinoraTokens.pos(isDark)
                : FinoraTokens.neg(isDark);
            return Padding(
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
            );
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
                      style: TextStyle(
                        fontSize: 14,
                        color: FinoraTokens.ink(isDark),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Hỏi Finora bất kỳ điều gì...',
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
