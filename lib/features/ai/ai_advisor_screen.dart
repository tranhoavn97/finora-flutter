import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/premium_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../state/ai_chat_provider.dart';
import '../../state/dashboard_provider.dart';
import '../../state/transaction_provider.dart';
import '../../state/wallet_provider.dart';
import '../transaction/add_transaction_page.dart';

class AiAdvisorScreen extends StatefulWidget {
  final String userId;
  final bool isTab;
  final VoidCallback? onBack;
  const AiAdvisorScreen({
    super.key,
    required this.userId,
    this.isTab = false,
    this.onBack,
  });

  @override
  State<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends State<AiAdvisorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _hasInputText = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText != _hasInputText) {
        setState(() => _hasInputText = hasText);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncContext();
    });
  }

  void _syncContext() {
    if (!mounted) return;
    final txProvider = context.read<TransactionProvider>();
    final aiProvider = context.read<AiChatProvider>();
    aiProvider.setContextData(
      userId: widget.userId,
      categories: txProvider.categories,
      wallets: txProvider.wallets,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool instant = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (instant) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
  }

  Map<String, dynamic> _buildFinanceContext() {
    try {
      final dashboard = context.read<DashboardProvider>();
      final data = dashboard.data;
      final netAssets = data.totalWalletBalance +
          data.totalAssetsValue +
          data.totalLent -
          data.totalCreditCardDebt -
          data.totalBorrowed;

      return {
        'balance': netAssets,
        'recentTransactions': data.recentTransactions
            .take(15)
            .map((t) => {
                  'title': t.note ?? t.categoryName ?? 'Giao dịch',
                  'amount': t.amount,
                  'type': t.type,
                  'category': t.categoryName ?? '',
                  'wallet': t.walletName ?? '',
                  'date': t.date,
                })
            .toList(),
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> _sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    _syncContext();
    _messageController.clear();
    _scrollToBottom();

    final aiProvider = context.read<AiChatProvider>();
    final financeContext = _buildFinanceContext();

    await aiProvider.sendMessage(
      text: clean,
      userId: widget.userId,
      financeContext: financeContext,
    );

    _scrollToBottom();
  }

  void _showAttachmentSheet() {
    final c = context.fc;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassBottomSheet(
        radius: 30,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.document_scanner_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Quét hóa đơn / Chuyển khoản',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Finora AI sẽ tự động đọc số tiền, danh mục và lưu ngay vào sổ chi tiêu của bạn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _AttachmentOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Chụp ảnh mới',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.pop(ctx);
                        _scanBill(ImageSource.camera);
                      },
                    ),
                    _AttachmentOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Chọn từ thư viện',
                      color: AppColors.success,
                      onTap: () {
                        Navigator.pop(ctx);
                        _scanBill(ImageSource.gallery);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _scanBill(ImageSource source) async {
    _syncContext();
    final aiProvider = context.read<AiChatProvider>();
    final financeContext = _buildFinanceContext();

    await aiProvider.pickAndScanBill(
      source: source,
      userId: widget.userId,
      financeContext: financeContext,
    );

    _scrollToBottom();
  }

  void _showClearConfirmDialog() async {
    final confirm = await showConfirmDeleteDialog(
      context: context,
      title: 'Làm mới cuộc trò chuyện?',
      content:
          'Nội dung chat sẽ được khởi tạo lại, các giao dịch đã ghi chép vào sổ vẫn được bảo lưu nguyên vẹn.',
      confirmLabel: 'Làm mới',
      isDanger: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aiProvider = context.watch<AiChatProvider>();
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;

    final bottomNavInset = mediaQuery.padding.bottom + 8.0;
    final bottomPadding =
        isKeyboardOpen ? (mediaQuery.viewInsets.bottom + 8.0) : bottomNavInset;

    final chatBody = Column(
      children: [
        // 1. Sleek Floating Chat Header
        _buildChatHeader(isDark),

        // 2. Chat Message List or Welcome State
        Expanded(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: aiProvider.messages.isEmpty
                ? _buildWelcomeView(isDark)
                : ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    itemCount: aiProvider.messages.length,
                    itemBuilder: (context, idx) {
                      final msg = aiProvider.messages[idx];
                      return _ChatMessageItem(
                        message: msg,
                        userId: widget.userId,
                        onUndo: (card) => aiProvider.undoTransaction(
                            card: card, userId: widget.userId),
                        onConfirm: (card) => aiProvider.confirmTransaction(
                            card: card, userId: widget.userId),
                        onDismiss: aiProvider.dismissDraft,
                        onQuickReply: (text) => _sendMessage(text),
                      );
                    },
                  ),
          ),
        ),

        // 3. AI Typing Indicator
        if (aiProvider.isLoading) _buildTypingIndicator(isDark),

        // 4. Voice Listening Waveform Banner
        if (aiProvider.isListening) _buildVoiceListeningBanner(),

        // 5. Floating Capsule Input Bar
        _buildInputBar(isDark, bottomPadding, aiProvider),
      ],
    );

    if (widget.isTab) {
      return SafeArea(
        bottom: false,
        child: chatBody,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: SafeArea(
          bottom: false,
          child: chatBody,
        ),
      ),
    );
  }

  Widget _buildChatHeader(bool isDark) {
    final c = context.fc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withOpacity(0.85)
            : Colors.white.withOpacity(0.90),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          if (widget.onBack != null || !widget.isTab) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            const SizedBox(width: 2),
          ],

          // AI Glowing Avatar with Pulse Halo
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1)
                              .withOpacity(0.45 * _pulseAnimation.value),
                          blurRadius: 12 * _pulseAnimation.value,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 22),
                    ),
                  );
                },
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      width: 2.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Title & Model Tag
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Finora AI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: c.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '3.0 ULTRA',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Cố vấn tài chính & Ghi chép tức thì',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Refresh Button
          GestureDetector(
            onTap: _showClearConfirmDialog,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Icon(
                Icons.restart_alt_rounded,
                color: c.textSecondary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView(bool isDark) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Ambient Orb
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF4F46E5),
                  Color(0xFF7C3AED),
                  Color(0xFFEC4899)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.4),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Xin chào! Tôi là Finora AI',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: primaryTextColor,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Ghi chép tự nhiên bằng văn bản, giọng nói hoặc quét ảnh hóa đơn chi tiêu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: secondaryTextColor,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 4 Suggestion Cards
          _buildPromptCard(
            icon: '🍜',
            title: 'Ghi chép nhanh',
            subtitle: 'Ăn phở bò 45k bằng ví MoMo',
            onTap: () => _sendMessage('Ăn phở bò 45k bằng ví MoMo'),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildPromptCard(
            icon: '📊',
            title: 'Phân tích dòng tiền',
            subtitle: 'Tháng này tôi đã chi tiêu hết bao nhiêu?',
            onTap: () =>
                _sendMessage('Tháng này tôi đã chi tiêu hết bao nhiêu?'),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildPromptCard(
            icon: '💡',
            title: 'Kế hoạch tài chính',
            subtitle: 'Làm sao để tiết kiệm 20% thu nhập mỗi tháng?',
            onTap: () =>
                _sendMessage('Làm sao để tiết kiệm 20% thu nhập mỗi tháng?'),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildPromptCard(
            icon: '🛡️',
            title: 'Đánh giá sức khỏe',
            subtitle: 'Đánh giá sức khỏe tài chính hiện tại của tôi',
            onTap: () =>
                _sendMessage('Đánh giá sức khỏe tài chính hiện tại của tôi'),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPromptCard({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131C35) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF223157) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141F3C) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF223157) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Transform.scale(
                    scale: _pulseAnimation.value,
                    child: const Icon(Icons.auto_awesome,
                        color: AppColors.primary, size: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Finora đang phân tích dữ liệu...',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceListeningBanner() {
    final aiProvider = context.watch<AiChatProvider>();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              aiProvider.lastWords.isNotEmpty
                  ? '"${aiProvider.lastWords}"'
                  : 'Đang lắng nghe giọng nói...',
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Material(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                final words = aiProvider.lastWords;
                aiProvider.stopVoiceListening();
                if (words.trim().isNotEmpty) {
                  _sendMessage(words);
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  'Gửi ngay',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(
      bool isDark, double bottomPadding, AiChatProvider aiProvider) {
    final c = context.fc;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPadding),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Camera / Bill Scan Button
          Container(
            margin: const EdgeInsets.only(bottom: 2),
            child: GestureDetector(
              onTap: _showAttachmentSheet,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Icon(Icons.camera_alt_rounded,
                    color: c.textPrimary, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Message Input Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _inputFocusNode,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                style: TextStyle(fontSize: 14, color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Nhắn Finora: Ăn phở 45k...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: InputBorder.none,
                ),
                onSubmitted: (val) => _sendMessage(val),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Voice Mic Button or Send Button
          Container(
            margin: const EdgeInsets.only(bottom: 2),
            child: _hasInputText
                ? GestureDetector(
                    onTap: () => _sendMessage(_messageController.text),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF075985), Color(0xFF0891B2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0891B2).withOpacity(0.32),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.arrow_upward_rounded,
                          color: Colors.white, size: 22),
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      aiProvider.toggleVoiceListening((text) {
                        _messageController.text = text;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: aiProvider.isListening
                            ? AppColors.error
                            : (isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: aiProvider.isListening
                              ? AppColors.error
                              : (isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        aiProvider.isListening
                            ? Icons.mic
                            : Icons.mic_none_rounded,
                        color: aiProvider.isListening
                            ? Colors.white
                            : c.textPrimary,
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

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessageItem extends StatelessWidget {
  final AiChatMessage message;
  final String userId;
  final Function(AiTransactionCardData) onUndo;
  final Function(AiTransactionCardData) onConfirm;
  final Function(AiTransactionCardData) onDismiss;
  final Function(String) onQuickReply;

  const _ChatMessageItem({
    required this.message,
    required this.userId,
    required this.onUndo,
    required this.onConfirm,
    required this.onDismiss,
    required this.onQuickReply,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alignment =
        message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final timeStr = DateFormat('HH:mm').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          // AI Header Badge
          if (!message.isUser) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      ),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 11),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Finora AI',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: c.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Bubble Container
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85),
            decoration: BoxDecoration(
              gradient: message.isUser
                  ? const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: message.isUser
                  ? null
                  : (isDark ? const Color(0xFF131C35) : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                bottomRight: Radius.circular(message.isUser ? 4 : 20),
              ),
              border: Border.all(
                color: message.isUser
                    ? Colors.transparent
                    : (isDark
                        ? const Color(0xFF223157)
                        : const Color(0xFFE2E8F0)),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image preview if user scanned a receipt
                if (message.imagePath != null) ...[
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(19)),
                    child: Image.file(
                      File(message.imagePath!),
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],

                // Message Text
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                  child: _FormattedChatText(
                    text: message.text,
                    isUser: message.isUser,
                    isDark: isDark,
                  ),
                ),

                // User message timestamp inside bubble
                if (message.isUser) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          timeStr,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white70),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all_rounded,
                            size: 13, color: Colors.white70),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Copy text action on AI messages
          if (!message.isUser) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã sao chép nội dung tin nhắn'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 12, color: c.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        'Sao chép',
                        style: TextStyle(
                          fontSize: 10,
                          color: c.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Transaction cards if AI extracted transactions
          if (message.cards.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...message.cards.map((card) => _AiTransactionCard(
                  card: card,
                  userId: userId,
                  onUndo: () => onUndo(card),
                  onConfirm: () => onConfirm(card),
                  onDismiss: () => onDismiss(card),
                )),
          ],

          // Contextual Quick Replies Chips
          if (message.quickReplies.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: message.quickReplies.map((qr) {
                return ActionChip(
                  label: Text(
                    qr,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  backgroundColor: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onQuickReply(qr.replaceFirst(RegExp(r'^[^\w\s]+\s*'), ''));
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _FormattedChatText extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isDark;

  const _FormattedChatText({
    required this.text,
    required this.isUser,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14.5,
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final spans = _parseMarkdown(text, textColor, isDark);

    return SelectableText.rich(
      TextSpan(children: spans),
      style: TextStyle(fontSize: 14.5, height: 1.5, color: textColor),
    );
  }

  List<InlineSpan> _parseMarkdown(String input, Color textColor, bool isDark) {
    final spans = <InlineSpan>[];
    final lines = input.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      final parts = line.split('**');
      for (int j = 0; j < parts.length; j++) {
        final p = parts[j];
        if (j % 2 == 1) {
          spans.add(
            TextSpan(
              text: p,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color:
                    isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
              ),
            ),
          );
        } else {
          spans.add(
            TextSpan(
              text: p,
              style: TextStyle(
                color: textColor,
              ),
            ),
          );
        }
      }

      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return spans;
  }
}

class _AiTransactionCard extends StatelessWidget {
  final AiTransactionCardData card;
  final String userId;
  final VoidCallback onUndo;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  const _AiTransactionCard({
    required this.card,
    required this.userId,
    required this.onUndo,
    required this.onConfirm,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tx = card.transaction;
    final isExpense = tx.type == 'expense';
    final isUndone = card.status == AiCardStatus.undone;
    final isPending = card.status == AiCardStatus.pending;
    final isError = card.status == AiCardStatus.error;

    final primaryColor = isUndone
        ? Colors.grey
        : (isExpense ? AppColors.error : AppColors.success);

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111C38) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUndone
              ? Colors.grey.withOpacity(0.3)
              : primaryColor.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(isDark ? 0.12 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isExpense
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.note ?? 'Giao dịch',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        decoration:
                            isUndone ? TextDecoration.lineThrough : null,
                        color: c.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (tx.categoryName != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tx.categoryName!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (tx.walletName != null) ...[
                          Flexible(
                            child: Text(
                              '• ${tx.walletName}',
                              style: TextStyle(
                                fontSize: 11,
                                color: c.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${isExpense ? '-' : '+'}${formatVND(tx.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  decoration: isUndone ? TextDecoration.lineThrough : null,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (card.errorMessage != null) ...[
            Text(card.errorMessage!,
                style: const TextStyle(fontSize: 11, color: AppColors.error)),
            const SizedBox(height: 8),
          ],
          if (isPending || isError)
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDismiss,
                  child: const Text('Bỏ qua'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: onConfirm,
                  icon: Icon(
                      isError ? Icons.refresh_rounded : Icons.check_rounded,
                      size: 17),
                  label: Text(isError ? 'Thử lưu lại' : 'Xác nhận lưu'),
                ),
              ),
            ])
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isUndone
                        ? Colors.grey.withOpacity(0.15)
                        : AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isUndone ? 'Đã bỏ qua / hoàn tác' : 'Đã lưu vào sổ',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isUndone ? Colors.grey : AppColors.success),
                  ),
                ),
                if (!isUndone)
                  TextButton(onPressed: onUndo, child: const Text('Hoàn tác')),
              ],
            ),
        ],
      ),
    );
  }
}
