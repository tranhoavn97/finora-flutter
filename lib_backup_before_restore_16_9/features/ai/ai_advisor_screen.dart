import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

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

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF14273A) : const Color(0xFFF1F6FA),
      body: AmbientFloatingBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. Top Bar: head('Finora Assistant', 'Người bạn cùng bạn quản lý tiền', btn('sparkles', 'home'))
              _buildTopBar(isDark: isDark),

              // 2. Chat & Content List
              Expanded(
                child: ListView(
                  controller: _scroll,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    if (_messages.isEmpty) ...[
                      // Hero Greeting Section
                      _buildGreetingHero(isDark: isDark),

                      // Demo Chat Interaction matching app.js
                      _buildChatBubble(
                        (text: 'Sáng nay cà phê 45 nghìn, tiền mặt.', user: true),
                        isDark,
                      ),
                      _buildDemoAssistantDraft(isDark),
                      const SizedBox(height: 12),

                      // Suggestion Pills matching app.js
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildPill(
                            icon: LucideIcons.chart_pie,
                            label: 'Phân tích chi tiêu tháng này',
                            onTap: () => _sendPrompt('Phân tích chi tiêu tháng này giúp tôi'),
                            isDark: isDark,
                          ),
                          _buildPill(
                            icon: LucideIcons.lightbulb,
                            label: 'Gợi ý tiết kiệm',
                            onTap: () => _sendPrompt('Gợi ý cách tối ưu chi tiêu tiết kiệm'),
                            isDark: isDark,
                          ),
                          _buildPill(
                            icon: LucideIcons.trending_up,
                            label: 'Dự báo tài chính',
                            onTap: () => _sendPrompt('Dự báo tài chính tháng tới cho tôi'),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ] else ...[
                      for (final m in _messages)
                        _buildChatBubble(m, isDark),
                    ],

                    // Real pending drafts if NLP detected transactions
                    if (_pendingTransactions.isNotEmpty)
                      _buildRealDraftCard(isDark: isDark),

                    // Typing / thinking indicator
                    if (_busy)
                      _buildTypingIndicator(isDark),
                  ],
                ),
              ),

              // 3. Bottom Input Bar: .search input + arrow-up icon button
              _buildFloatingInputBar(isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar({required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E3146) : Colors.white,
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2E455C) : const Color(0xFFDCE7F0),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.chevron_left,
                    size: 20,
                    color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Finora Assistant',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Người bạn cùng bạn quản lý tiền',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              if (_messages.isNotEmpty) {
                setState(() => _messages.clear());
              }
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E3146) : Colors.white,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: isDark ? const Color(0xFF2E455C) : const Color(0xFFDCE7F0),
                ),
              ),
              child: const Icon(
                LucideIcons.sparkles,
                size: 18,
                color: Color(0xFF005FEA),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingHero({required bool isDark}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3A5A) : const Color(0xFFE0EDFF),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.sparkles,
                size: 26,
                color: Color(0xFF005FEA),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Hôm nay, mình\ngiúp gì cho bạn?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.18,
              letterSpacing: -0.6,
              color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Từ một khoản chi nhỏ đến một kế hoạch lớn.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(
    ({String text, bool user}) message,
    bool isDark,
  ) {
    if (message.user) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A3B60) : const Color(0xFFE0EDFF),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCCE4FF) : const Color(0xFF32608C),
              height: 1.4,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 36),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2C3E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(22),
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(22),
          ),
          border: Border.all(
            color: isDark ? const Color(0xFF2B3F55) : const Color(0xFFE4EDF4),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
            height: 1.45,
          ),
        ),
      ),
    );
  }

  Widget _buildDemoAssistantDraft(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2C3E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(22),
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(22),
          ),
          border: Border.all(
            color: isDark ? const Color(0xFF2B3F55) : const Color(0xFFE4EDF4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mình đã chuẩn bị khoản chi này. Bạn kiểm tra trước khi lưu nhé.',
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF142434) : const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF243B52) : const Color(0xFFE6EEF5),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4E5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Icon(
                            LucideIcons.coffee,
                            size: 20,
                            color: Color(0xFFE67E22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cà phê sáng',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ăn uống · Tiền mặt',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        '45.000 ₫',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFC86359),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () {
                        _sendPrompt('Ghi nhận cà phê sáng 45 nghìn tiền mặt');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005FEA),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Xác nhận khoản chi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E3146) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2E455C) : const Color(0xFFDCE7F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: const Color(0xFF005FEA)),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealDraftCard({required bool isDark}) {
    final provider = context.read<TransactionProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 14, right: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2C3E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF2B3F55) : const Color(0xFFE4EDF4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, size: 16, color: Color(0xFF005FEA)),
              const SizedBox(width: 8),
              Text(
                'Bản nháp giao dịch (${_pendingTransactions.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._pendingTransactions.map((draft) {
            final category = _resolveCategory(draft, provider.categories);
            final wallet = _resolveWallet(draft, provider.wallets);
            final positive = draft.type == 'income';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: positive
                          ? const Color(0xFFE4EFEA)
                          : const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Center(
                      child: Icon(
                        positive ? LucideIcons.arrow_down_left : LucideIcons.arrow_up_right,
                        size: 18,
                        color: positive
                            ? const Color(0xFF138875)
                            : const Color(0xFFE67E22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          draft.note.isEmpty ? (category?.name ?? 'Giao dịch') : draft.note,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${category?.name ?? "Chung"} · ${wallet?.name ?? "Ví chính"}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${positive ? "+" : "-"}${_formatAmount(draft.amount)}',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: positive
                          ? const Color(0xFF138875)
                          : const Color(0xFFC86359),
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
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: _savingDrafts ? null : () => setState(() => _pendingTransactions = []),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF2B3F55) : const Color(0xFFDCE7F0),
                      ),
                    ),
                    child: Text(
                      'Hủy',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _savingDrafts ? null : _savePendingTransactions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005FEA),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _savingDrafts
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Xác nhận lưu',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
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

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2C3E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2B3F55) : const Color(0xFFE4EDF4),
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
                color: Color(0xFF005FEA),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Finora AI đang suy nghĩ...',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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

  Widget _buildFloatingInputBar({required bool isDark}) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).viewInsets.bottom > 0
            ? MediaQuery.of(context).viewInsets.bottom + 10
            : 24,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B2C3E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF2B3F55) : const Color(0xFFDCE7F0),
                ),
              ),
              child: TextField(
                controller: _input,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                ),
                decoration: InputDecoration(
                  hintText: 'Nhắn cho Finora…',
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (val) => _sendPrompt(val),
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
                color: const Color(0xFF005FEA),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.arrow_up,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
