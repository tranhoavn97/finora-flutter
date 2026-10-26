import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../domain/finance/finance_summary.dart';
import '../../data/services/ai_service.dart';
import '../../state/dashboard_provider.dart';

class AiAdvisorScreen extends StatefulWidget {
  final String userId;
  const AiAdvisorScreen({super.key, required this.userId});
  @override
  State<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends State<AiAdvisorScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<({String text, bool user})> _messages = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DashboardProvider>().load(widget.userId);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _sendPrompt(String prompt) async {
    if (prompt.isEmpty || _busy) return;
    setState(() {
      _messages.add((text: prompt, user: true));
      _busy = true;
      _input.clear();
    });

    try {
      final d = context.read<DashboardProvider>();
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

      final answer = await AiService.getFinancialAdvice(
        prompt: prompt,
        chatHistory: history,
        throwOnError: false,
        userFinanceContext: {
          'period': '${now.year}-${now.month}',
          'currency': 'VND',
          'income': summary.income,
          'expense': summary.expense,
        },
      );

      if (mounted) {
        setState(() {
          _messages.add((text: answer, user: false));
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add((
            text:
                'Không thể kết nối Finora AI lúc này. Vui lòng kiểm tra mạng và thử lại.',
            user: false,
          ));
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            _scroll.animateTo(
              _scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: primaryTextColor,
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              'Finora AI',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: primaryTextColor,
              ),
            ),
          ],
        ),
        actions: const [
          Icon(Icons.more_horiz_rounded, color: Color(0xFF64748B), size: 24),
          SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                children: [
                  if (_messages.isEmpty) ...[
                    const SizedBox(height: 12),
                    // Robot Hero Avatar
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.smart_toy_rounded,
                              size: 40, color: Color(0xFF2563EB)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        'Xin chào! 👋',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: primaryTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'Tôi có thể giúp gì cho bạn hôm nay?',
                        style: TextStyle(
                          fontSize: 14,
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 4 Action Prompt Cards Grid (2x2)
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.bar_chart_rounded,
                            iconColor: const Color(0xFF2563EB),
                            title: 'Phân tích chi tiêu',
                            subtitle: 'Xem chi tiêu tháng này',
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
                            icon: Icons.lightbulb_outline_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            title: 'Gợi ý tiết kiệm',
                            subtitle: 'Cách giảm chi phí',
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
                            iconColor: const Color(0xFF10B981),
                            title: 'Dự báo tài chính',
                            subtitle: 'Dự báo tháng tới',
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
                            icon: Icons.help_outline_rounded,
                            iconColor: const Color(0xFF8B5CF6),
                            title: 'Trả lời thắc mắc',
                            subtitle: 'Hỏi bất kỳ điều gì',
                            isDark: isDark,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                            onTap: () =>
                                _sendPrompt('Tôi nên đầu tư gì với 10 triệu?'),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    for (final m in _messages)
                      Align(
                        alignment: m.user
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: m.user
                                ? const Color(0xFF2563EB)
                                : (isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            border: m.user
                                ? null
                                : Border.all(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0),
                                  ),
                          ),
                          child: Text(
                            m.text,
                            style: TextStyle(
                              fontSize: 14.5,
                              color: m.user ? Colors.white : primaryTextColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Input Bar: "Hỏi Finora AI..." + Send Circle Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: InputDecoration(
                        hintText: 'Hỏi Finora AI...',
                        hintStyle:
                            TextStyle(fontSize: 14, color: secondaryTextColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (val) => _sendPrompt(val),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _sendPrompt(_input.text),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
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

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11.5,
                color: secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
