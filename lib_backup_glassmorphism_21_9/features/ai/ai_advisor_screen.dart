import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/design_system/v8/finora_v8.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../domain/finance/finance_summary.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/finora_nlp_engine.dart';
import '../../data/models/category.dart';
import '../../data/models/finance_models.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../state/dashboard_provider.dart';
import '../../state/transaction_provider.dart';

/// Cố vấn tài chính AI thông minh Finora AI
/// Thiết kế chuẩn Liquid Glass, Ambient Background, bong bóng hội thoại cao cấp & Capsule Input
class AiAdvisorScreen extends StatefulWidget {
  final String userId;
  final String? familyId;
  const AiAdvisorScreen({super.key, required this.userId, this.familyId});

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
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientFloatingBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top Bar Liquid Glass
              _buildTopBar(isDark: isDark, primaryTextColor: primaryTextColor),

              // Chat Messages List
              Expanded(
                child: ListView(
                  controller: _scroll,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    if (_messages.isEmpty) ...[
                      const SizedBox(height: 14),
                      // Hero AI Avatar with radiant Liquid Glow
                      Center(
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF005FEA),
                                Color(0xFF0284C7),
                                Color(0xFF06B6D4),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.38),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : Colors.white,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                size: 42,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Finora AI Advisor',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Trợ lý tài chính thông minh của gia đình bạn. Sẵn sàng phân tích, tối ưu chi tiêu và định hướng ngân sách.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: secondaryTextColor,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 4 Action Prompt Cards Grid (2x2) Liquid Glass
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionCard(
                              icon: Icons.pie_chart_rounded,
                              iconGradient: const [
                                Color(0xFF2563EB),
                                Color(0xFF3B82F6)
                              ],
                              title: 'Phân tích chi tiêu',
                              subtitle: 'Xem cơ cấu thu chi tháng này',
                              isDark: isDark,
                              primaryTextColor: primaryTextColor,
                              secondaryTextColor: secondaryTextColor,
                              onTap: () => _sendPrompt(
                                  'Phân tích chi tiêu tháng này giúp tôi'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionCard(
                              icon: Icons.lightbulb_rounded,
                              iconGradient: const [
                                Color(0xFFEA580C),
                                Color(0xFFF59E0B)
                              ],
                              title: 'Gợi ý tiết kiệm',
                              subtitle: 'Mẹo cắt giảm chi phí thông minh',
                              isDark: isDark,
                              primaryTextColor: primaryTextColor,
                              secondaryTextColor: secondaryTextColor,
                              onTap: () => _sendPrompt(
                                  'Gợi ý cách tối ưu chi tiêu tiết kiệm'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionCard(
                              icon: Icons.trending_up_rounded,
                              iconGradient: const [
                                Color(0xFF059669),
                                Color(0xFF10B981)
                              ],
                              title: 'Dự báo tài chính',
                              subtitle: 'Xu hướng dòng tiền tháng tới',
                              isDark: isDark,
                              primaryTextColor: primaryTextColor,
                              secondaryTextColor: secondaryTextColor,
                              onTap: () => _sendPrompt(
                                  'Dự báo tài chính tháng tới cho tôi'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionCard(
                              icon: Icons.shield_rounded,
                              iconGradient: const [
                                Color(0xFF059669),
                                Color(0xFF0D9488)
                              ],
                              title: 'An toàn ngân sách',
                              subtitle: 'Cảnh báo các khoản vượt mức',
                              isDark: isDark,
                              primaryTextColor: primaryTextColor,
                              secondaryTextColor: secondaryTextColor,
                              onTap: () => _sendPrompt(
                                  'Kiểm tra ngân sách có khoản nào nguy hiểm không?'),
                            ),
                          ),
                        ],
                      ),
                    ] else
                      for (final m in _messages)
                        _buildChatBubble(m, isDark, primaryTextColor),
                    if (_pendingTransactions.isNotEmpty)
                      _buildTransactionDraftCard(
                        isDark: isDark,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                    if (_busy)
                      _buildTypingIndicator(isDark, secondaryTextColor),
                  ],
                ),
              ),

              // Bottom Input Bar Floating Capsule
              _buildFloatingInputBar(
                isDark: isDark,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar({required bool isDark, required Color primaryTextColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF0F172A) : Colors.white)
            .withValues(alpha: 0.75),
        border: Border(
          bottom: BorderSide(
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          FinoraBackButton(
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF005FEA), Color(0xFF0284C7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Finora AI',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: primaryTextColor,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Sẵn sàng tư vấn tài chính',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_messages.isNotEmpty)
            IconButton(
              tooltip: 'Làm mới cuộc trò chuyện',
              icon: const Icon(Icons.refresh_rounded, size: 20),
              color: const Color(0xFF64748B),
              onPressed: () {
                setState(() => _messages.clear());
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required List<Color> iconGradient,
    required String title,
    required String subtitle,
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
          color: (isDark ? const Color(0xFF1E293B) : Colors.white)
              .withValues(alpha: isDark ? 0.82 : 0.90),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: isDark ? 0.10 : 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: iconGradient),
                boxShadow: [
                  BoxShadow(
                    color: iconGradient.first.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 19),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11.5,
                color: secondaryTextColor,
                fontWeight: FontWeight.w500,
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

  Widget _buildChatBubble(
      ({String text, bool user}) message, bool isDark, Color primaryTextColor) {
    if (message.user) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(5),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              fontSize: 14.5,
              color: Colors.white,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 36),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(top: 2, right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF005FEA), Color(0xFF0284C7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF1E293B) : Colors.white)
                      .withValues(alpha: isDark ? 0.90 : 0.95),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: isDark ? 0.10 : 0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: primaryTextColor,
                    height: 1.48,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark, Color secondaryTextColor) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 42),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF1E293B) : Colors.white)
              .withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Finora AI đang suy nghĩ...',
              style: TextStyle(
                fontSize: 12.5,
                color: secondaryTextColor,
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
      padding: const EdgeInsets.all(FinoraV8Space.x4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(FinoraV8Radius.card),
        border: Border.all(
          color: FinoraV8Colors.brand.withValues(alpha: .22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 18, color: FinoraV8Colors.brand),
              const SizedBox(width: FinoraV8Space.x2),
              Expanded(
                child: Text(
                  'Bản nháp giao dịch AI',
                  style: FinoraV8Type.sectionTitle.copyWith(
                    color: primaryTextColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: FinoraV8Colors.brand.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(FinoraV8Radius.pill),
                ),
                child: Text(
                  '${_pendingTransactions.length} mục',
                  style: FinoraV8Type.micro.copyWith(
                    color: FinoraV8Colors.brand,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: FinoraV8Space.x3),
          ..._pendingTransactions.map((draft) {
            final category = _resolveCategory(draft, provider.categories);
            final wallet = _resolveWallet(draft, provider.wallets);
            final positive = draft.type == 'income';
            return Padding(
              padding: const EdgeInsets.only(bottom: FinoraV8Space.x3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (positive
                              ? FinoraV8Colors.income
                              : FinoraV8Colors.expense)
                          .withValues(alpha: .12),
                    ),
                    child: Icon(
                      positive
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      size: 17,
                      color: positive
                          ? FinoraV8Colors.income
                          : FinoraV8Colors.expense,
                    ),
                  ),
                  const SizedBox(width: FinoraV8Space.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          draft.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FinoraV8Type.itemTitle.copyWith(
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${category?.name ?? "Chưa có danh mục"} • ${wallet?.name ?? "Chưa có ví"}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FinoraV8Type.caption.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: FinoraV8Space.x2),
                  Text(
                    '${positive ? "+" : "-"}${_formatAmount(draft.amount)}',
                    style: FinoraV8Type.amount.copyWith(
                      color: positive
                          ? FinoraV8Colors.income
                          : FinoraV8Colors.expense,
                    ),
                  ),
                ],
              ),
            );
          }),
          Row(
            children: [
              Expanded(
                child: FinoraButton(
                  onPressed: _savingDrafts
                      ? null
                      : () => setState(() => _pendingTransactions = []),
                  variant: FinoraButtonVariant.secondary,
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: FinoraV8Space.x2),
              Expanded(
                child: FinoraButton(
                  onPressed: _savePendingTransactions,
                  loading: _savingDrafts,
                  child: const Text('Xác nhận lưu'),
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
    return '${buffer.toString()} đ';
  }

  Widget _buildFloatingInputBar({
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        8,
        14,
        MediaQuery.of(context).viewInsets.bottom > 0
            ? MediaQuery.of(context).viewInsets.bottom + 8
            : 24,
      ),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC))
            .withValues(alpha: 0.85),
        border: Border(
          top: BorderSide(
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1E293B) : Colors.white)
                    .withValues(alpha: isDark ? 0.90 : 0.96),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: (isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: primaryTextColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Hỏi Finora AI bất kỳ điều gì...',
                        hintStyle: TextStyle(
                          fontSize: 13.5,
                          color: secondaryTextColor,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (val) => _sendPrompt(val),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendPrompt(_input.text),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
