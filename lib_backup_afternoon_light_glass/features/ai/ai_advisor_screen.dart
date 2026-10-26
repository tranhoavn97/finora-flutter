import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../data/services/ai_service.dart';
import '../../state/dashboard_provider.dart';

class AiAdvisorScreen extends StatefulWidget {
  final String userId;
  const AiAdvisorScreen({super.key, required this.userId});

  @override
  State<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends State<AiAdvisorScreen> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  static const List<String> _suggestedPrompts = [
    'Phân tích thói quen chi tiêu tháng này',
    'Làm sao để tiết kiệm 15% thu nhập?',
    'Gợi ý hạn mức ngân sách hợp lý',
    'Tôi nên tối ưu hóa khoản vay như thế nào?'
  ];

  @override
  void initState() {
    super.initState();
    // Add default initial greeting from Gemini
    _messages.add(
      const _ChatMessage(
        text: 'Xin chào! Tôi là cố vấn tài chính AI của Finora. Tôi có thể giúp gì cho bạn trong việc quản lý chi tiêu và lập ngân sách hôm nay?',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    // Prepare financial context from DashboardProvider if available
    Map<String, dynamic> financeContext = {};
    try {
      final dashboard = context.read<DashboardProvider>();
      final data = dashboard.data;
      final netAssets = data.totalWalletBalance + data.totalAssetsValue + data.totalLent - data.totalCreditCardDebt - data.totalBorrowed;
      
      financeContext = {
        'balance': netAssets,
        'recentTransactions': data.recentTransactions.take(8).map((t) => {
          'title': t.note ?? t.categoryName ?? 'Giao dịch',
          'amount': t.amount,
          'type': t.type,
          'category': t.categoryName ?? '',
          'date': t.date,
        }).toList(),
      };
    } catch (_) {}

    // Prepare chat history for context
    final history = _messages
        .where((m) => m.text.isNotEmpty)
        .take(6) // send last 6 messages
        .map((m) => {
              'role': m.isUser ? 'user' : 'model',
              'parts': [
                {'text': m.text}
              ]
            })
        .toList();

    final response = await AiService.getFinancialAdvice(
      prompt: text,
      chatHistory: history,
      userFinanceContext: financeContext,
    );

    if (!mounted) return;

    setState(() {
      _messages.add(_ChatMessage(text: response, isUser: false));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Cố vấn tài chính AI',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          // Chat messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 20),
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final msg = _messages[idx];
                return _ChatBubble(message: msg);
              },
            ),
          ),

          // Suggested Prompts (if chat has only the greeting)
          if (_messages.length == 1 && !_isLoading) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Gợi ý câu hỏi:',
                    style: AppTypography.caption2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestedPrompts.map((prompt) {
                      return InkWell(
                        onTap: () => _sendMessage(prompt),
                        borderRadius: AppRadius.input,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                            borderRadius: AppRadius.input,
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
                            ),
                          ),
                          child: Text(
                            prompt,
                            style: AppTypography.caption2.copyWith(
                              color: secondaryTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Loading typing indicator
          if (_isLoading) ...[
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Cố vấn đang suy nghĩ...',
                          style: AppTypography.caption2.copyWith(
                            color: secondaryTextColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Message input bar
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: FinoraTextField(
                    controller: _messageController,
                    hint: 'Hỏi cố vấn tài chính Finora...',
                    radius: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Send button
                GestureDetector(
                  onTap: () => _sendMessage(_messageController.text),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.accent, Color(0xFF60A5FA)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x221877F2),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  const _ChatMessage({required this.text, required this.isUser});
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final alignment = message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = message.isUser
        ? (isDark ? AppColors.accent.withOpacity(0.15) : AppColors.accent.withOpacity(0.12))
        : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04));
        
    final bubbleBorder = isDark 
        ? Colors.white.withOpacity(0.08) 
        : Colors.black.withOpacity(0.06);

    final textColors = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(message.isUser ? 20 : 0),
      bottomRight: Radius.circular(message.isUser ? 0 : 20),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: radius,
              border: Border.all(color: bubbleBorder, width: 1),
            ),
            child: Text(
              message.text,
              style: AppTypography.body.copyWith(
                color: textColors,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
