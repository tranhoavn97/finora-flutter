import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../data/services/activity_log_repository.dart';

class ActivityLogsScreen extends StatefulWidget {
  final String userId;
  final String? familyId;

  const ActivityLogsScreen({
    super.key,
    required this.userId,
    this.familyId,
  });

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  final ActivityLogRepository _repo = ActivityLogRepository();
  List<ActivityLogModel> _logs = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    final list = await _repo.getActivityLogs(
      widget.userId,
      familyId: widget.familyId,
      limitCount: 100,
    );
    if (mounted) {
      setState(() {
        _logs = list;
        _isLoading = false;
      });
    }
  }

  List<ActivityLogModel> get _filteredLogs {
    if (_selectedFilter == 'all') return _logs;
    return _logs.where((l) => l.action.toLowerCase().contains(_selectedFilter) || l.collectionName.toLowerCase().contains(_selectedFilter)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    final displayLogs = _filteredLogs;

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Nhật ký hoạt động',
        onBack: () => Navigator.of(context).pop(),
        actions: [
          IconButton(
            onPressed: _fetchLogs,
            icon: Icon(Icons.refresh_rounded, color: primaryTextColor, size: 22),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withOpacity(0.7)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.history_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kiểm toán hoạt động minh bạch',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ghi lại toàn bộ lịch sử chỉnh sửa giao dịch, ví tiền và tài sản giữa các thành viên.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayLogs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 54,
                                color: secondaryTextColor.withOpacity(0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Chưa có nhật ký hoạt động nào',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                          itemCount: displayLogs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final log = displayLogs[index];
                            final timeStr = log.createdAt != null
                                ? DateFormat('dd/MM/yyyy HH:mm').format(log.createdAt!)
                                : 'Vừa xong';

                            final (badgeBg, badgeColor, icon) = _getActionVisual(log.action);

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(18),
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
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: badgeBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(icon, color: badgeColor, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                log.actorName ?? 'Người dùng',
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: primaryTextColor,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              timeStr,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: secondaryTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatActionText(log),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: primaryTextColor.withOpacity(0.9),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (log.details != null && log.details!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              log.details!,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: secondaryTextColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color, IconData) _getActionVisual(String action) {
    final a = action.toLowerCase();
    if (a.contains('delete') || a.contains('xóa')) {
      return (const Color(0xFFFFE4E6), AppColors.error, Icons.delete_outline_rounded);
    }
    if (a.contains('create') || a.contains('add') || a.contains('thêm')) {
      return (const Color(0xFFDCFCE7), AppColors.success, Icons.add_circle_outline_rounded);
    }
    if (a.contains('update') || a.contains('edit') || a.contains('sửa')) {
      return (const Color(0xFFDBEAFE), const Color(0xFF2563EB), Icons.edit_note_rounded);
    }
    return (const Color(0xFFFEF3C7), const Color(0xFFD97706), Icons.sync_rounded);
  }

  String _formatActionText(ActivityLogModel log) {
    final a = log.action.toLowerCase();
    String collectionLabel = log.collectionName;
    if (collectionLabel == 'transactions') collectionLabel = 'giao dịch';
    if (collectionLabel == 'wallets') collectionLabel = 'ví tiền';
    if (collectionLabel == 'assets') collectionLabel = 'tài sản';
    if (collectionLabel == 'loans') collectionLabel = 'khoản vay';

    if (a.contains('create')) return 'Đã tạo $collectionLabel mới';
    if (a.contains('update')) return 'Đã cập nhật $collectionLabel';
    if (a.contains('delete')) return 'Đã đưa $collectionLabel vào thùng rác';
    if (a.contains('restore')) return 'Đã khôi phục $collectionLabel';

    return log.action;
  }
}
