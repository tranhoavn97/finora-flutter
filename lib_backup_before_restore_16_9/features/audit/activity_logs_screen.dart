import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/premium_widgets.dart';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final todayStr = 'Hôm nay · ${DateFormat('dd/MM/yyyy').format(now)}';

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF14273A) : const Color(0xFFF1F6FA),
      body: AmbientFloatingBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Soft Header: head('Dấu chân tài chính', 'Lịch sử thay đổi của bạn')
              Padding(
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
                              'Dấu chân tài chính',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Lịch sử thay đổi của bạn',
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
                      onTap: _fetchLogs,
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
                          LucideIcons.rotate_cw,
                          size: 18,
                          color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Timeline Body
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                        children: [
                          // Date Pill matching app.js
                          Row(
                            children: [
                              Container(
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
                                    const Icon(LucideIcons.calendar, size: 15, color: Color(0xFF005FEA)),
                                    const SizedBox(width: 7),
                                    Text(
                                      todayStr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Timeline container with left border
                          Container(
                            margin: const EdgeInsets.only(left: 12),
                            padding: const EdgeInsets.only(left: 22),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: isDark ? const Color(0xFF2A4259) : const Color(0xFFDCE7F0),
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_logs.isNotEmpty) ...[
                                  ..._logs.map((log) => _buildRealLogEvent(log, isDark)),
                                ] else ...[
                                  // Representative Events matching app.js
                                  _buildAuditTimelineEvent(
                                    time: '10:42',
                                    title: 'Điều chỉnh ngân sách',
                                    desc: 'Danh mục Ăn uống',
                                    isDark: isDark,
                                    extra: Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E3146) : Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF2E455C) : const Color(0xFFE5EDF4),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '4.000.000 ₫',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              decoration: TextDecoration.lineThrough,
                                              color: isDark ? const Color(0xFF8BA5BF) : const Color(0xFF9CA7B2),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Text('→ ', style: TextStyle(fontSize: 12.5)),
                                          Text(
                                            '5.000.000 ₫',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  _buildAuditTimelineEvent(
                                    time: '08:31',
                                    title: 'Thêm khoản chi',
                                    desc: 'Cà phê sáng · Tiền mặt',
                                    isDark: isDark,
                                    extra: Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF4E5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        '−45.000 ₫',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFE67E22),
                                        ),
                                      ),
                                    ),
                                  ),
                                  _buildAuditTimelineEvent(
                                    time: '08:15',
                                    title: 'Cập nhật mục tiêu',
                                    desc: 'Một chuyến đi Đà Lạt\nĐã góp thêm 500.000 ₫',
                                    isDark: isDark,
                                  ),
                                  _buildAuditTimelineEvent(
                                    time: 'HÔM QUA · 21:10',
                                    title: 'Chuyển vào thùng rác',
                                    desc: 'Giao dịch trùng · Mua sắm',
                                    isDark: isDark,
                                    isLast: true,
                                    extra: Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: GestureDetector(
                                        onTap: () => Navigator.maybePop(context),
                                        child: const Text(
                                          'Xem trong thùng rác →',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF005FEA),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuditTimelineEvent({
    required String time,
    required String title,
    required String desc,
    required bool isDark,
    Widget? extra,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 26),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -28,
            top: 4,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF005FEA),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF14273A) : const Color(0xFFF1F6FA),
                  width: 2,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFE2EDF7) : const Color(0xFF233D58),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFFABC0D3) : const Color(0xFF7A90A5),
                  height: 1.35,
                ),
              ),
              if (extra != null) extra,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRealLogEvent(ActivityLogModel log, bool isDark) {
    final timeStr = log.createdAt != null
        ? DateFormat('HH:mm · dd/MM').format(log.createdAt!)
        : 'Vừa xong';

    return _buildAuditTimelineEvent(
      time: timeStr,
      title: log.action.isEmpty ? 'Hoạt động hệ thống' : log.action,
      desc: '${log.details ?? ""}\nNgười thực hiện: ${log.actorName ?? "Tôi"}',
      isDark: isDark,
    );
  }
}
