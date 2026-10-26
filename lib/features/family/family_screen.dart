import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../data/models/family_models.dart';
import '../../state/auth_provider.dart';
import '../../state/family_provider.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  FamilyRole _selectedRole = FamilyRole.member;
  String? _generatedCode;
  bool _isCreatingInvite = false;
  bool _isJoining = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateInvite() async {
    final familyProv = context.read<FamilyProvider>();
    if (familyProv.members.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nhóm gia đình đã đủ tối đa 3 thành viên.')),
      );
      return;
    }

    setState(() => _isCreatingInvite = true);
    final invite = await familyProv.createInvitation(
      role: _selectedRole,
      targetEmail: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
    );
    if (!mounted) return;
    setState(() {
      _isCreatingInvite = false;
      if (invite != null) {
        _generatedCode = invite.code;
      }
    });

    if (invite != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã tạo mã mời: ${invite.code}')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Không thể tạo mã mời. Kiểm tra email và kết nối rồi thử lại.'),
      ));
    }
  }

  Future<void> _handleJoinWithCode() async {
    final code = _codeController.text.trim().toUpperCase();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? ''),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) {
        _codeController.clear();
      }
    }
  }

  Future<void> _handleLeaveFamily() async {
    final familyProv = context.read<FamilyProvider>();
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    if (familyProv.isOwner && familyProv.members.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chủ nhóm cần chuyển quyền sở hữu trước khi rời nhóm.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rời khỏi gia đình?'),
        content: const Text(
          'Dữ liệu tài chính bạn từng tạo vẫn sẽ được lưu trữ tại nhóm gia đình này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rời nhóm'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await familyProv.leaveGroup(user);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã rời nhóm gia đình.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final familyProv = context.watch<FamilyProvider>();
    final user = context.watch<AuthProvider>().currentUser;
    final family = familyProv.family;
    final members = familyProv.members;
    final isOwner = familyProv.isOwner;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Quản lý Gia đình',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: familyProv.isLoading && family == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Thẻ tổng quan
                  if (familyProv.error != null)
                    Card(
                        child: ListTile(
                      leading: const Icon(Icons.sync_problem_rounded),
                      title: const Text('Chưa thể đồng bộ gia đình'),
                      subtitle: const Text('Kiểm tra kết nối và thử lại.'),
                      trailing: IconButton(
                        tooltip: 'Thử lại',
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed:
                            user == null ? null : () => familyProv.init(user),
                      ),
                    )),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4263EB), Color(0xFF274690)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.people_alt,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                family?.name ?? 'Gia đình của bạn',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${members.length}/3 thành viên • Vai trò: ${familyProv.scope?.role.displayName ?? "Thành viên"}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Danh sách thành viên
                  const Text(
                    'Thành viên nhóm',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final m = members[index];
                      final isMe = m.uid == user?.uid;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.15),
                              backgroundImage:
                                  (m.photoURL != null && m.photoURL!.isNotEmpty)
                                      ? NetworkImage(m.photoURL!)
                                      : null,
                              child: (m.photoURL == null || m.photoURL!.isEmpty)
                                  ? Text(
                                      m.displayName.isNotEmpty
                                          ? m.displayName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFF59E0B)),
                                    )
                                  : null,
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
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      )),
                                      if (m.memberTag != null &&
                                          m.memberTag!.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: (m.memberTag == 'Chồng'
                                                    ? Colors.blue
                                                    : (m.memberTag == 'Vợ'
                                                        ? Colors.pink
                                                        : Colors.amber))
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            m.memberTag == 'Chồng'
                                                ? '👨 Chồng'
                                                : (m.memberTag == 'Vợ'
                                                    ? '👩 Vợ'
                                                    : (m.memberTag == 'Con'
                                                        ? '👶 Con'
                                                        : m.memberTag!)),
                                            style: TextStyle(
                                              color: m.memberTag == 'Chồng'
                                                  ? Colors.blue
                                                  : (m.memberTag == 'Vợ'
                                                      ? Colors.pink
                                                      : Colors.amber),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (isMe) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.blue
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text('Bạn',
                                              style: TextStyle(
                                                  color: Colors.blue,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    m.email.isNotEmpty ? m.email : 'Thành viên',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: m.role == FamilyRole.owner
                                    ? const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.15)
                                    : (m.role == FamilyRole.limited
                                        ? Colors.grey.withValues(alpha: 0.15)
                                        : Colors.green.withValues(alpha: 0.15)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                m.role.displayName,
                                style: TextStyle(
                                  color: m.role == FamilyRole.owner
                                      ? const Color(0xFFF59E0B)
                                      : (m.role == FamilyRole.limited
                                          ? Colors.grey
                                          : Colors.green),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isOwner || isMe)
                              PopupMenuButton<String>(
                                tooltip: 'Phân loại thành viên',
                                icon: const Icon(Icons.more_horiz_rounded,
                                    size: 20),
                                position: PopupMenuPosition.under,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18)),
                                itemBuilder: (_) => [
                                  for (final tag in const [
                                    'Chồng',
                                    'Vợ',
                                    'Con',
                                    'Thành viên'
                                  ])
                                    CheckedPopupMenuItem(
                                        value: tag,
                                        checked: m.memberTag == tag,
                                        child: Text(tag)),
                                ],
                                onSelected: (tag) async {
                                  try {
                                    await familyProv.changeMemberTag(
                                        m.uid, tag);
                                  } catch (_) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Chưa thể cập nhật. Vui lòng thử lại.'),
                                    ));
                                  }
                                },
                              ),
                            if (isOwner && !isMe && m.role != FamilyRole.owner)
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red, size: 20),
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Xóa thành viên?'),
                                      content: Text(
                                          'Bạn có chắc muốn xóa ${m.displayName} khỏi nhóm?'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Hủy')),
                                        FilledButton(
                                            style: FilledButton.styleFrom(
                                                backgroundColor: Colors.red),
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('Xóa')),
                                      ],
                                    ),
                                  );
                                  if (ok == true) {
                                    await familyProv.removeMember(m.uid);
                                  }
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // 3. Mời thành viên mới (Chỉ dành cho Owner khi < 3 người)
                  if (isOwner && members.length < 3) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.person_add_alt_1,
                                  color: Color(0xFFF59E0B), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Mời thành viên mới (Hết hạn sau 7 ngày)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'Email người nhận lời mời',
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<FamilyRole>(
                            value: _selectedRole,
                            decoration: InputDecoration(
                              labelText: 'Quyền hạn',
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: FamilyRole.member,
                                child: Text('Thành viên (Đầy đủ)'),
                              ),
                              DropdownMenuItem(
                                value: FamilyRole.limited,
                                child: Text('Giới hạn (Chỉ nhập)'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedRole = v);
                            },
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
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
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.send, size: 18),
                              label: const Text('Tạo mã mời 7 ngày',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          if (_generatedCode != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Mã mời của bạn:',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFFD97706))),
                                        const SizedBox(height: 2),
                                        Text(
                                          _generatedCode!,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2,
                                            color: Color(0xFFD97706),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy,
                                        color: Color(0xFFD97706)),
                                    onPressed: () {
                                      Clipboard.setData(
                                          ClipboardData(text: _generatedCode!));
                                      ScaffoldMessenger.of(context)
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
                  ],

                  // 4. Gia nhập bằng mã
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.vpn_key, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Nhập mã mời gia nhập nhóm',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _codeController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: 'Ví dụ: AB12CD',
                                  filled: true,
                                  fillColor: isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFF1F5F9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 12),
                                shape: const StadiumBorder(),
                              ),
                              onPressed:
                                  _isJoining ? null : _handleJoinWithCode,
                              child: _isJoining
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Tham gia'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 5. Rời nhóm
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: _handleLeaveFamily,
                      icon: const Icon(Icons.exit_to_app, size: 18),
                      label: const Text('Rời khỏi gia đình này',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
