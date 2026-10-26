import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/design_system/v8/finora_v8.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../widgets/catalog_glass_card.dart';

/// Screen 10: AI Advisor (Trợ lý tài chính thông minh Finora AI) in Glassmorphism 2.0
class DemoAiScreen extends StatefulWidget {
  final bool isLiveMode;
  final VoidCallback? onBack;

  const DemoAiScreen({
    super.key,
    this.isLiveMode = false,
    this.onBack,
  });

  @override
  State<DemoAiScreen> createState() => _DemoAiScreenState();
}

class _DemoAiScreenState extends State<DemoAiScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': 'Chào Louis! Mình là Finora AI Copilot. Hôm nay bạn cần trợ giúp phân tích ngân sách hay ghi chép giao dịch bằng giọng nói/văn bản?',
      'time': '14:20',
    },
    {
      'isUser': true,
      'text': 'Ăn tối Highlands với đối tác hết 185k bằng thẻ Vietcombank',
      'time': '14:22',
    },
    {
      'isUser': false,
      'isDraft': true,
      'amount': 185000,
      'category': 'Ăn uống & Cà phê',
      'wallet': 'Vietcombank Visa',
      'note': 'Ăn tối Highlands với đối tác',
      'time': '14:22',
    },
    {
      'isUser': false,
      'text': 'Mình đã phân tích và trích xuất thành công phiếu giao dịch. Bạn kiểm tra thông tin và bấm xác nhận để ghi vào sổ chi tiêu nhé!',
      'time': '14:23',
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _messages.add({
        'isUser': true,
        'text': text.trim(),
        'time': 'Bây giờ',
      });
      _controller.clear();
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'isUser': false,
          'text': 'Finora AI đã ghi nhận yêu cầu của bạn! Đang tổng hợp dữ liệu chi tiêu...',
          'time': 'Vừa xong',
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: FinoraPageHeader(
                title: 'Finora AI Copilot',
                onBack: widget.onBack ?? () => Navigator.maybePop(context),
                actions: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: GlassmorphismTokens.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GlassmorphismTokens.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.sparkles, size: 14, color: GlassmorphismTokens.primary),
                        SizedBox(width: 4),
                        Text(
                          'Online',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GlassmorphismTokens.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                physics: const BouncingScrollPhysics(),
                itemCount: _messages.length,
                itemBuilder: (context, idx) {
                  final msg = _messages[idx];
                  if (msg['isDraft'] == true) {
                    return _buildDraftTransactionCard(msg, isDark);
                  }
                  return _buildMessageBubble(msg, isDark);
                },
              ),
            ),
            _buildInputToolbar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isDark) {
    final isUser = msg['isUser'] as bool;
    final text = msg['text'] as String;
    final time = msg['time'] as String;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? GlassmorphismTokens.primary
              : (isDark
                  ? GlassmorphismTokens.surfaceBaseDark.withValues(alpha: 0.75)
                  : GlassmorphismTokens.surfaceBaseLight.withValues(alpha: 0.85)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: Border.all(
            color: isUser
                ? Colors.transparent
                : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08)),
          ),
          boxShadow: isUser
              ? [
                  BoxShadow(
                    color: GlassmorphismTokens.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: isUser ? Colors.white70 : (isDark ? Colors.white38 : Colors.black38),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftTransactionCard(Map<String, dynamic> msg, bool isDark) {
    return CatalogGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: GlassmorphismTokens.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.sparkles, color: GlassmorphismTokens.primary, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Phiếu giao dịch AI đề xuất',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: GlassmorphismTokens.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '-185,000 đ',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: GlassmorphismTokens.expense),
          ),
          const SizedBox(height: 8),
          Text('Danh mục: ${msg['category']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text('Nguồn tiền: ${msg['wallet']}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
          const SizedBox(height: 2),
          Text('Ghi chú: ${msg['note']}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlassmorphismTokens.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã ghi nhận giao dịch vào ví Vietcombank!')),
                    );
                  },
                  child: const Text('Lưu giao dịch'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputToolbar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                'Phân tích chi tiêu tuần này',
                'Gợi ý tối ưu ngân sách',
                'So sánh chi tiêu 2 vợ chồng',
              ].map((chip) {
                return GestureDetector(
                  onTap: () => _sendMessage(chip),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8, bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    child: Text(
                      chip,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    onSubmitted: _sendMessage,
                    decoration: const InputDecoration(
                      hintText: 'Nhập chi tiêu hoặc câu hỏi tài chính...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: GlassmorphismTokens.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(LucideIcons.send, size: 18),
                onPressed: () => _sendMessage(_controller.text),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
