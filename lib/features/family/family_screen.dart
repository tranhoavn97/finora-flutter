import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/finora_mascot.dart';
import '../../core/widgets/finora_member_filter.dart';
import '../../core/widgets/finora_notice.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../data/models/family_models.dart';
import '../../state/auth_provider.dart';
import '../../state/dashboard_provider.dart';
import '../../state/family_provider.dart';
import '../../state/more_provider.dart';
import '../../state/theme_studio_controller.dart';
import '../../state/transaction_provider.dart';
import '../../state/wallet_provider.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  FamilyRole _selectedRole = FamilyRole.admin;
  String _selectedInviteTag = 'Vợ';
  String? _generatedCode;
  String? _exportedSyncPackage;
  bool _isCreatingInvite = false;
  bool _isJoining = false;
  bool _isExportingSync = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _reloadAllFinancialProviders(String uid) {
    try {
      context.read<WalletProvider>().load(uid, force: true);
    } catch (_) {}
    try {
      context.read<TransactionProvider>().load(uid, force: true);
    } catch (_) {}
    try {
      context.read<MoreProvider>().load(uid, force: true);
    } catch (_) {}
    try {
      context.read<DashboardProvider>().load(uid, force: true);
    } catch (_) {}
  }

  Future<void> _handleCreateInvite() async {
    final familyProv = context.read<FamilyProvider>();
    if (familyProv.members.length >= 6) {
      FinoraNotice.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nhóm gia đình đã đạt tối đa 6 thành viên.')),
      );
      return;
    }

    setState(() => _isCreatingInvite = true);
    final memberName = _nameController.text.trim();
    if (memberName.isNotEmpty) {
      await familyProv.addOrUpdateManualMember(
        displayName: memberName,
        email: _emailController.text.trim(),
        role: _selectedRole,
        memberTag: _selectedInviteTag,
      );
    }
    final invite = await familyProv.createInvitation(
      role: _selectedRole,
      targetEmail: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      memberTag: _selectedInviteTag,
    );
    if (!mounted) return;
    setState(() {
      _isCreatingInvite = false;
      if (invite != null) {
        _generatedCode = invite.code;
      }
    });

    if (invite != null && mounted) {
      _nameController.clear();
      _emailController.clear();
      FinoraNotice.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Đã tạo mã mời gia đình: ${invite.code} (${_selectedRole.displayName})'),
        ),
      );
    }
  }

  Future<void> _handleExportZeroLossPackage() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    setState(() => _isExportingSync = true);
    try {
      final pkg =
          await context.read<FamilyProvider>().exportFamilySharePackage(user.uid);
      if (!mounted) return;
      setState(() {
        _isExportingSync = false;
        _exportedSyncPackage = pkg;
      });
      await Clipboard.setData(ClipboardData(text: pkg));
      if (!mounted) return;
      FinoraNotice.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Đã sao chép Gói Đồng Bộ Gia Đình (An toàn 100% không mất dữ liệu)! Gửi cho Vợ/Chồng để dán vào máy.'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExportingSync = false);
      FinoraNotice.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể xuất gói đồng bộ: $e'),
          backgroundColor: const Color(0xFFE11D48),
        ),
      );
    }
  }

  Future<void> _handleJoinWithCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _isJoining = true);
    final res =
        await context.read<FamilyProvider>().acceptInvitation(code, user);
    if (!mounted) return;
    setState(() => _isJoining = false);

    if (mounted) {
      final success = res['success'] == true;
      if (success) {
        _reloadAllFinancialProviders(user.uid);
        _codeController.clear();
      }
      FinoraNotice.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? ''),
          backgroundColor:
              success ? const Color(0xFF059669) : const Color(0xFFE11D48),
        ),
      );
    }
  }

  Future<void> _handlePasteAndSyncFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      if (!mounted) return;
      FinoraNotice.of(context).showSnackBar(
        const SnackBar(content: Text('Bộ nhớ tạm đang trống.')),
      );
      return;
    }
    _codeController.text = text;
    await _handleJoinWithCode();
  }

  Future<void> _showRenameFamilyDialog(FamilyProvider familyProv) async {
    final ctrl = TextEditingController(text: familyProv.family?.name ?? '');
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Đổi tên Không gian Gia đình',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          inputFormatters: const [FinoraCapitalizeFirstFormatter()],
          decoration: InputDecoration(
            hintText: 'VD: Gia đình Minh & Lan',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              shape: const StadiumBorder(),
            ),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Lưu tên mới'),
          ),
        ],
      ),
    );
    if (saved != null && saved.isNotEmpty) {
      await familyProv.updateFamilyName(saved);
    }
  }

  Future<void> _handleLeaveFamily() async {
    final familyProv = context.read<FamilyProvider>();
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Làm mới nhóm gia đình?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Toàn bộ ví tiền, giao dịch và tài sản của bạn được giữ nguyên 100% không mất bất kỳ dữ liệu nào.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              shape: const StadiumBorder(),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await familyProv.leaveGroup(user);
      if (mounted) {
        FinoraNotice.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Đã đặt lại danh sách thành viên. Dữ liệu sổ thu chi được bảo toàn 100%.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final familyProv = context.watch<FamilyProvider>();
    final user = context.watch<AuthProvider>().currentUser;
    final family = familyProv.family;
    final members = familyProv.members;
    final isOwner = familyProv.isOwner;
    final perm = familyProv.permissionConfig;

    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryText =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = (isDark ? const Color(0xFF141E2B) : Colors.white)
        .withValues(alpha: (studio?.glassOpacity ?? 0.96).clamp(0.25, 1.0));
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0);
    final headerBlur = (studio?.appBarBlur ?? 18.0).clamp(0.0, 32.0);
    final headerAlpha =
        (studio?.appBarOpacity ?? (isDark ? 0.84 : 0.88)).clamp(0.15, 1.0);

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
              // Sticky Blur Header
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
                    child: Row(
                      children: [
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
                              color: primaryText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quản lý & Phân quyền Gia đình',
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w800,
                                  color: primaryText,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                'Chia sẻ sổ Vợ & Chồng • An toàn 100% không mất dữ liệu',
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 11.2,
                                  fontWeight: FontWeight.w600,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (user != null)
                          InkWell(
                            onTap: () => familyProv.init(user),
                            borderRadius: BorderRadius.circular(999),
                            child: Tooltip(
                              message: 'Làm mới',
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
                                  color: primaryText,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: familyProv.isLoading && family == null
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Luxury Hero Family Card with Mascot Watermark
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF047857),
                                          Color(0xFF0D9488),
                                          Color(0xFF0284C7),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.24),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            FinoraMemberAvatar(
                                              member: 'all',
                                              size: 54,
                                              isDark: isDark,
                                              showRing: true,
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 9,
                                                        vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.18),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              999),
                                                    ),
                                                    child: const Text(
                                                      'ZERO-LOSS FAMILY LEDGER • MOBILE & WEB',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color: Colors.white,
                                                        letterSpacing: 0.6,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          family?.name ??
                                                              'Gia đình của bạn',
                                                          style:
                                                              const TextStyle(
                                                            fontFamily:
                                                                'BeVietnamPro',
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w900,
                                                            fontSize: 19,
                                                            letterSpacing: -0.3,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      InkWell(
                                                        onTap: () =>
                                                            _showRenameFamilyDialog(
                                                                familyProv),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(999),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(4),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white
                                                                .withValues(
                                                                    alpha:
                                                                        0.18),
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: const Icon(
                                                            Icons.edit_rounded,
                                                            size: 13,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${members.length} thành viên • Quyền của bạn: ${familyProv.scope?.role.displayName ?? "Chủ hộ"}',
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.92),
                                                      fontSize: 12.2,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.18),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.16),
                                            ),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(
                                                Icons.verified_user_rounded,
                                                size: 15,
                                                color: Color(0xFF6EE7B7),
                                              ),
                                              SizedBox(width: 7),
                                              Expanded(
                                                child: Text(
                                                  'Bảo vệ kép: Gộp dữ liệu Vợ & Chồng 100% chính xác, chống trùng lặp & không bao giờ mất dữ liệu gốc.',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const FinoraAmbientMascotWatermark(
                                    pose: FinoraMascotPose.happy,
                                    size: 135,
                                    opacity: 0.12,
                                    right: -12,
                                    bottom: -16,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            // 1b. Tùy chỉnh 3 Avatar: Ảnh Chung (Vợ & Chồng), Chồng, Vợ
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF10B981)
                                              .withValues(alpha: 0.14),
                                        ),
                                        child: const Icon(
                                          Icons.add_a_photo_rounded,
                                          size: 17,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Avatar Chung (Tất cả) • Chồng • Vợ',
                                              style: TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w800,
                                                color: primaryText,
                                              ),
                                            ),
                                            Text(
                                              'Up ảnh cặp đôi hoặc chọn icon hiển thị trên nút lọc và danh sách giao dịch',
                                              style: TextStyle(
                                                fontSize: 11.2,
                                                color: secondaryText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildAvatarQuickTile(
                                          role: 'all',
                                          label: 'Ảnh Chung',
                                          accent: const Color(0xFF10B981),
                                          isDark: isDark,
                                          primaryText: primaryText,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildAvatarQuickTile(
                                          role: 'husband',
                                          label: 'Chồng',
                                          accent: const Color(0xFF0284C7),
                                          isDark: isDark,
                                          primaryText: primaryText,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildAvatarQuickTile(
                                          role: 'wife',
                                          label: 'Vợ',
                                          accent: const Color(0xFFE11D48),
                                          isDark: isDark,
                                          primaryText: primaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            // 1c. Trung tâm Đồng Bộ Sổ Chung Không Mất Dữ Liệu (Mobile & Web)
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.35),
                                  width: 1.2,
                                ),
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
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF10B981)
                                              .withValues(alpha: 0.14),
                                        ),
                                        child: const Icon(
                                          Icons.cloud_sync_rounded,
                                          color: Color(0xFF059669),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Chia sẻ & Gộp Dữ Liệu Gia Đình (Web & App)',
                                              style: TextStyle(
                                                fontSize: 14.8,
                                                fontWeight: FontWeight.w800,
                                                color: primaryText,
                                              ),
                                            ),
                                            Text(
                                              'Đồng bộ Ví, Giao dịch, Danh mục, Tài sản & Sổ nợ giữa các máy mà không mất bất kỳ dữ liệu nào',
                                              style: TextStyle(
                                                fontSize: 11.2,
                                                color: secondaryText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 44,
                                          child: FilledButton.icon(
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF059669),
                                              foregroundColor: Colors.white,
                                              shape: const StadiumBorder(),
                                            ),
                                            onPressed: _isExportingSync
                                                ? null
                                                : _handleExportZeroLossPackage,
                                            icon: _isExportingSync
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.ios_share_rounded,
                                                    size: 17),
                                            label: const Text(
                                              'Sao chép Gói Chia Sẻ',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: SizedBox(
                                          height: 44,
                                          child: OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  const Color(0xFF0284C7),
                                              side: const BorderSide(
                                                color: Color(0xFF0284C7),
                                                width: 1.2,
                                              ),
                                              shape: const StadiumBorder(),
                                            ),
                                            onPressed: _isJoining
                                                ? null
                                                : _handlePasteAndSyncFromClipboard,
                                            icon: const Icon(
                                                Icons.content_paste_go_rounded,
                                                size: 17),
                                            label: const Text(
                                              'Dán & Gộp Dữ Liệu',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_exportedSyncPackage != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981)
                                            .withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded,
                                              size: 16,
                                              color: Color(0xFF059669)),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Text(
                                              'Đã tạo gói đồng bộ vào bộ nhớ tạm! Gửi qua Zalo/Messenger cho người thân và bấm "Dán & Gộp Dữ Liệu".',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF047857),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 22),

                            // 2. Danh sách thành viên & Phân quyền trực tiếp
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'THÀNH VIÊN & PHÂN QUYỀN',
                                  style: TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: secondaryText,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${members.length} thành viên',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: members.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final m = members[index];
                                final isMe = m.uid == user?.uid;
                                return _buildMemberBentoCard(
                                  context: context,
                                  m: m,
                                  isMe: isMe,
                                  isOwner: isOwner,
                                  isDark: isDark,
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  primaryText: primaryText,
                                  secondaryText: secondaryText,
                                  familyProv: familyProv,
                                );
                              },
                            ),

                            const SizedBox(height: 18),

                            // 2b. Bảng Quy tắc Phân quyền Chi tiết
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.admin_panel_settings_rounded,
                                        size: 19,
                                        color: Color(0xFF8B5CF6),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Thiết lập Quyền hạn & Bảo vệ Dữ liệu',
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          color: primaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _buildPermissionSwitchRow(
                                    title: 'Cho phép thành viên thêm giao dịch',
                                    subtitle:
                                        'Ghi nhận khoản thu/chi mới vào sổ gia đình',
                                    value: perm.allowMemberCreateTx,
                                    onChanged: (v) =>
                                        familyProv.updatePermissionConfig(
                                      perm.copyWith(allowMemberCreateTx: v),
                                    ),
                                    primaryText: primaryText,
                                    secondaryText: secondaryText,
                                  ),
                                  _buildPermissionSwitchRow(
                                    title:
                                        'Cho phép Đồng quản lý (Vợ/Chồng) sửa ví & giao dịch',
                                    subtitle:
                                        'Cập nhật hạn mức, danh mục và ghi chú chung',
                                    value: perm.allowMemberEditTx,
                                    onChanged: (v) =>
                                        familyProv.updatePermissionConfig(
                                      perm.copyWith(allowMemberEditTx: v),
                                    ),
                                    primaryText: primaryText,
                                    secondaryText: secondaryText,
                                  ),
                                  _buildPermissionSwitchRow(
                                    title:
                                        'Khóa chống xóa nhầm dữ liệu gốc (100% Zero-Loss)',
                                    subtitle:
                                        'Luôn giữ toàn bộ giao dịch cũ khi gộp sổ trên Web & Mobile',
                                    value: perm.zeroLossMergeProtection,
                                    onChanged: (_) {},
                                    primaryText: primaryText,
                                    secondaryText: secondaryText,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 22),

                            // 3. Mời thành viên mới & Cấp quyền
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFFF59E0B)
                                              .withValues(alpha: 0.14),
                                        ),
                                        child: const Icon(
                                            Icons.person_add_alt_1_rounded,
                                            color: Color(0xFFD97706),
                                            size: 19),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Mời thành viên & Cấp quyền',
                                              style: TextStyle(
                                                fontFamily: 'BeVietnamPro',
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                                color: primaryText,
                                              ),
                                            ),
                                            Text(
                                              'Tạo mã mời 6 ký tự kèm phân quyền Vợ / Chồng / Thành viên',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: secondaryText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  TextField(
                                    controller: _nameController,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    inputFormatters: const [
                                      FinoraCapitalizeFirstFormatter()
                                    ],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: primaryText,
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.badge_rounded,
                                        size: 18,
                                        color: secondaryText,
                                      ),
                                      hintText:
                                          'Tên người thân (VD: Vợ yêu, Minh Anh...)',
                                      hintStyle: TextStyle(
                                          fontSize: 13, color: secondaryText),
                                      filled: true,
                                      fillColor: isDark
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFFF1F5F9),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        borderSide: BorderSide(
                                            color: borderColor, width: 1),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        borderSide: BorderSide(
                                            color: borderColor, width: 1),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _emailController,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: primaryText,
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.alternate_email_rounded,
                                        size: 18,
                                        color: secondaryText,
                                      ),
                                      hintText:
                                          'Email người nhận lời mời (Tùy chọn)',
                                      hintStyle: TextStyle(
                                          fontSize: 13, color: secondaryText),
                                      filled: true,
                                      fillColor: isDark
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFFF1F5F9),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        borderSide: BorderSide(
                                            color: borderColor, width: 1),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        borderSide: BorderSide(
                                            color: borderColor, width: 1),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Vai trò trong gia đình',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      for (final tag in const [
                                        ('Vợ', Color(0xFFE11D48)),
                                        ('Chồng', Color(0xFF0284C7)),
                                        ('Con', Color(0xFFD97706)),
                                        ('Thành viên', Color(0xFF059669)),
                                      ])
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 3),
                                            child: InkWell(
                                              onTap: () => setState(() =>
                                                  _selectedInviteTag = tag.$1),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 160),
                                                height: 36,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: _selectedInviteTag ==
                                                          tag.$1
                                                      ? tag.$2
                                                      : tag.$2.withValues(
                                                          alpha: 0.10),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999),
                                                ),
                                                child: Text(
                                                  tag.$1,
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: _selectedInviteTag ==
                                                            tag.$1
                                                        ? Colors.white
                                                        : tag.$2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Cấp độ phân quyền',
                                    style: TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildRoleOptionTile(
                                          role: FamilyRole.admin,
                                          title: 'Đồng quản lý',
                                          subtitle: 'Toàn quyền Vợ/Chồng',
                                          icon: Icons.favorite_rounded,
                                          accent: const Color(0xFFE11D48),
                                          isDark: isDark,
                                          primaryText: primaryText,
                                          secondaryText: secondaryText,
                                          borderColor: borderColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildRoleOptionTile(
                                          role: FamilyRole.member,
                                          title: 'Thành viên',
                                          subtitle: 'Xem & ghi thu chi',
                                          icon: Icons.verified_user_rounded,
                                          accent: const Color(0xFF059669),
                                          isDark: isDark,
                                          primaryText: primaryText,
                                          secondaryText: secondaryText,
                                          borderColor: borderColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildRoleOptionTile(
                                          role: FamilyRole.limited,
                                          title: 'Giới hạn',
                                          subtitle: 'Chỉ xem / Ghi nháp',
                                          icon: Icons.lock_person_rounded,
                                          accent: const Color(0xFFD97706),
                                          isDark: isDark,
                                          primaryText: primaryText,
                                          secondaryText: secondaryText,
                                          borderColor: borderColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 46,
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF059669),
                                        foregroundColor: Colors.white,
                                        shape: const StadiumBorder(),
                                      ),
                                      onPressed: _isCreatingInvite
                                          ? null
                                          : _handleCreateInvite,
                                      icon: _isCreatingInvite
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white),
                                            )
                                          : const Icon(Icons.qr_code_2_rounded,
                                              size: 19),
                                      label: const Text(
                                          'Thêm thành viên & Tạo mã mời',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14)),
                                    ),
                                  ),
                                  if (_generatedCode != null) ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: const Color(0xFF10B981)
                                              .withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Mã mời gia đình (Hiệu lực 7 ngày):',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF047857),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  _generatedCode!,
                                                  style: const TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 2.2,
                                                    color: Color(0xFF059669),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Sao chép mã mời',
                                            icon: const Icon(Icons.copy_rounded,
                                                color: Color(0xFF059669)),
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(
                                                  text: _generatedCode!));
                                              FinoraNotice.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Đã sao chép mã mời vào bộ nhớ tạm!')),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // 4. Gia nhập bằng mã mời hoặc Gói đồng bộ
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF0284C7)
                                              .withValues(alpha: 0.14),
                                        ),
                                        child: const Icon(Icons.vpn_key_rounded,
                                            color: Color(0xFF0284C7), size: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Tham gia bằng Mã mời / Gói đồng bộ',
                                              style: TextStyle(
                                                fontFamily: 'BeVietnamPro',
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                                color: primaryText,
                                              ),
                                            ),
                                            Text(
                                              'Nhập mã 6 ký tự hoặc dán gói FINORA-SYNC từ người thân',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: secondaryText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _codeController,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: primaryText,
                                          ),
                                          decoration: InputDecoration(
                                            hintText:
                                                'Mã 6 ký tự hoặc FINORA-SYNC:...',
                                            hintStyle: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w500,
                                                color: secondaryText),
                                            filled: true,
                                            fillColor: isDark
                                                ? const Color(0xFF0F172A)
                                                : const Color(0xFFF1F5F9),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              borderSide: BorderSide(
                                                  color: borderColor, width: 1),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              borderSide: BorderSide(
                                                  color: borderColor, width: 1),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        height: 46,
                                        child: FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF0284C7),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20),
                                            shape: const StadiumBorder(),
                                          ),
                                          onPressed: _isJoining
                                              ? null
                                              : _handleJoinWithCode,
                                          child: _isJoining
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white),
                                                )
                                              : const Text('Kết nối',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // 5. Đặt lại danh sách nhóm
                            Center(
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFE11D48),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 10),
                                  shape: const StadiumBorder(),
                                ),
                                onPressed: _handleLeaveFamily,
                                icon: const Icon(Icons.logout_rounded, size: 18),
                                label: const Text(
                                    'Rời nhóm gia đình (Giữ nguyên 100% dữ liệu)',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarQuickTile({
    required String role,
    required String label,
    required Color accent,
    required bool isDark,
    required Color primaryText,
  }) {
    return InkWell(
      onTap: () => showFinoraMemberAvatarPickerSheet(
        context,
        role: role,
        isDark: isDark,
      ),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.16 : 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accent.withValues(alpha: 0.32),
          ),
        ),
        child: Column(
          children: [
            FinoraMemberAvatar(
              member: role,
              size: 38,
              isDark: isDark,
              showRing: true,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: primaryText,
              ),
            ),
            Text(
              'Up ảnh',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: const Color(0xFF10B981),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOptionTile({
    required FamilyRole role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required bool isDark,
    required Color primaryText,
    required Color secondaryText,
    required Color borderColor,
  }) {
    final selected = _selectedRole == role;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedRole = role);
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(
                    accent.withValues(alpha: isDark ? 0.22 : 0.12),
                    isDark ? const Color(0xFF0F172A) : Colors.white,
                  )
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? accent : borderColor,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? accent
                      : accent.withValues(alpha: isDark ? 0.18 : 0.12),
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: selected ? Colors.white : accent,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected ? accent : primaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.8,
                  color: secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberBentoCard({
    required BuildContext context,
    required FamilyMemberModel m,
    required bool isMe,
    required bool isOwner,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color primaryText,
    required Color secondaryText,
    required FamilyProvider familyProv,
  }) {
    final currentTag = m.memberTag ??
        (m.role == FamilyRole.owner ? 'Chồng' : 'Thành viên');
    final Color tagColor = currentTag == 'Chồng'
        ? const Color(0xFF0284C7)
        : (currentTag == 'Vợ'
            ? const Color(0xFFE11D48)
            : const Color(0xFF059669));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              FinoraMemberAvatar(
                role: currentTag,
                size: 42,
                isDark: isDark,
                showRing: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            m.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: primaryText,
                            ),
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Bạn',
                              style: TextStyle(
                                color: Color(0xFF0284C7),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      m.role.permissionSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 11.2,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  // Cycle role permissions on tap
                  final nextRole = switch (m.role) {
                    FamilyRole.owner => FamilyRole.owner,
                    FamilyRole.admin => FamilyRole.member,
                    FamilyRole.member => FamilyRole.limited,
                    FamilyRole.limited => FamilyRole.admin,
                  };
                  if (m.role != FamilyRole.owner) {
                    familyProv.changeRole(m.uid, nextRole);
                  }
                },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: m.role == FamilyRole.owner
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                        : tagColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    m.role.displayName,
                    style: TextStyle(
                      color: m.role == FamilyRole.owner
                          ? const Color(0xFFD97706)
                          : tagColor,
                      fontSize: 11.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (!isMe && m.role != FamilyRole.owner) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Xóa thành viên',
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFE11D48), size: 20),
                  onPressed: () => familyProv.removeMember(m.uid),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                for (final roleTag in const [
                  ('Chồng', Icons.person_rounded, Color(0xFF0284C7)),
                  ('Vợ', Icons.favorite_rounded, Color(0xFFE11D48)),
                  ('Con', Icons.child_care_rounded, Color(0xFFD97706)),
                  ('Thành viên', Icons.groups_rounded, Color(0xFF059669)),
                ])
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        familyProv.changeMemberTag(m.uid, roleTag.$1);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: currentTag == roleTag.$1
                              ? roleTag.$3
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              roleTag.$2,
                              size: 12,
                              color: currentTag == roleTag.$1
                                  ? Colors.white
                                  : secondaryText,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                roleTag.$1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: currentTag == roleTag.$1
                                      ? Colors.white
                                      : secondaryText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
