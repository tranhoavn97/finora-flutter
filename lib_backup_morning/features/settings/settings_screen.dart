import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../state/more_provider.dart';
import '../../state/theme_controller.dart';
import '../../state/widget_style_controller.dart';
import '../dashboard/dashboard_theme_painters.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;
  const SettingsScreen({super.key, required this.userId});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _synced = false, _dirty = false, _saving = false, _negative = false;
  String _date = 'DD/MM/YYYY';
  late MoreProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<MoreProvider>();
    _provider.addListener(_sync);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _provider.load(widget.userId);
      _sync();
    });
  }

  void _sync() {
    if (!mounted || _synced || !_provider.settingsLoaded) return;
    setState(() {
      _negative = _provider.settings.allowNegativeBalance;
      _date = _provider.settings.dateFormat;
      _synced = true;
    });
  }

  @override
  void dispose() {
    _provider.removeListener(_sync);
    super.dispose();
  }

  Future<void> _save() async {
    if (!_synced || _saving) return;
    setState(() => _saving = true);
    final ok = await _provider.updateSettings(
        widget.userId,
        _provider.settings
            .copyWith(allowNegativeBalance: _negative, dateFormat: _date));
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) _dirty = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Đã lưu cài đặt'
            : 'Chưa lưu được. Thay đổi của bạn vẫn được giữ.')));
  }

  Future<void> _close() async {
    if (_saving) return;
    if (_dirty) {
      final discard = await showDialog<bool>(
          context: context,
          builder: (c) =>
              AlertDialog(title: const Text('Bỏ thay đổi chưa lưu?'), actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Tiếp tục sửa')),
                TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Bỏ thay đổi'))
              ]));
      if (discard != true) return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MoreProvider>();
    final theme = context.watch<ThemeController>();
    final widgetStyle = context.watch<WidgetStyleController>();

    return PopScope(
      canPop: !_dirty && !_saving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _close();
      },
      child: GlassScaffold(
        appBar: GlassTopBar(
          title: _dirty ? 'Cài đặt · Chưa lưu' : 'Cài đặt',
          onBack: _close,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            _settingsSectionHeader(
                Icons.palette_rounded, 'Giao diện',
                'Chế độ hiển thị và phong cách trang tổng quan'),
            const SizedBox(height: 10),
            // Theme Mode Selector (System / Light / Dark)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chế độ giao diện chung',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tự động áp dụng cho toàn bộ ứng dụng',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  SegmentedControl(
                    options: const [
                      ('system', 'Hệ thống'),
                      ('light', 'Sáng'),
                      ('dark', 'Tối')
                    ],
                    selected: theme.mode,
                    onChanged: (v) =>
                        context.read<ThemeController>().setMode(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.palette_rounded,
                      size: 18, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Text(
                    'TÙY BIẾN GIAO DIỆN TRANG TỔNG QUAN',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 1. Card Tổng tài sản (07 themes)
            _buildThemePickerCard(
              title: 'Card Tổng tài sản',
              subtitle: '07 giao diện chuẩn thiết kế Finora',
              selected: widgetStyle.assetStyle,
              presets: WidgetStyleController.assetPresets,
              onChanged: widgetStyle.setAssetStyle,
              previewBuilder: (meta, isSelected) =>
                  _buildAssetPreviewThumbnail(meta),
            ),
            const SizedBox(height: 14),

            // 2. Ngân sách tháng (04 themes)
            _buildThemePickerCard(
              title: 'Ngân sách tháng',
              subtitle: '04 giao diện Glass, Purple, Nature, Orange',
              selected: widgetStyle.budgetStyle,
              presets: WidgetStyleController.budgetPresets,
              onChanged: widgetStyle.setBudgetStyle,
              previewBuilder: (meta, isSelected) =>
                  _buildBudgetPreviewThumbnail(meta),
            ),
            const SizedBox(height: 14),

            // 3. Trợ lí Finora (04 themes)
            _buildThemePickerCard(
              title: 'Trợ lí Finora',
              subtitle: '04 giao diện chỉ số sức khỏe tài chính',
              selected: widgetStyle.assistantStyle,
              presets: WidgetStyleController.assistantPresets,
              onChanged: widgetStyle.setAssistantStyle,
              previewBuilder: (meta, isSelected) =>
                  _buildAssistantPreviewThumbnail(meta),
            ),
            const SizedBox(height: 14),

            // 4. Lịch sử giao dịch / Widget (09 themes)
            _buildThemePickerCard(
              title: 'Widget & Lịch sử giao dịch',
              subtitle: '09 mẫu danh sách & timeline độc đáo',
              selected: widgetStyle.historyStyle,
              presets: WidgetStyleController.historyPresets,
              onChanged: widgetStyle.setHistoryStyle,
              previewBuilder: (meta, isSelected) =>
                  _buildHistoryPreviewThumbnail(meta),
            ),
            const SizedBox(height: 24),

            _settingsSectionHeader(
                Icons.account_balance_wallet_rounded, 'Tài chính & dữ liệu',
                'Đơn vị tiền, chu kỳ và quy tắc ghi sổ'),
            const SizedBox(height: 10),

            // General App Settings
            if (!_synced)
              Padding(
                padding: const EdgeInsets.all(24),
                child: p.settingsError == null
                    ? const Center(child: CircularProgressIndicator())
                    : Text(p.settingsError!),
              )
            else ...[
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tiền tệ',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(p.settings.currency,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2563EB))),
                    const SizedBox(height: 6),
                    const Text(
                      'Chưa hỗ trợ tự động quy đổi tiền tệ. Giữ nguyên đơn vị của dữ liệu đã ghi.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const Divider(height: 28),
                    const Text('Chu kỳ tài chính',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Ngày ${p.settings.financeMonthStartDay} hàng tháng',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    const Text(
                      'Báo cáo hiện dùng tháng dương lịch.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GlassCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Cho phép số dư âm',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                      subtitle: const Text(
                        'Tùy chọn ghi sổ; không thay đổi giao dịch đã có.',
                        style:
                            TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      value: _negative,
                      onChanged: _saving
                          ? null
                          : (v) => setState(() {
                                _negative = v;
                                _dirty = true;
                              }),
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Định dạng ngày',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                    const SizedBox(height: 8),
                    SegmentedControl(
                      options: const [
                        ('DD/MM/YYYY', 'DD/MM'),
                        ('MM/DD/YYYY', 'MM/DD'),
                        ('YYYY/MM/DD', 'YYYY/MM')
                      ],
                      selected: _date,
                      onChanged: (v) => setState(() {
                        _date = v;
                        _dirty = true;
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _dirty && !_saving ? _save : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(_saving ? 'Đang lưu…' : 'Lưu cài đặt'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _settingsSectionHeader(
      IconData icon, String title, String subtitle) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 19, color: const Color(0xFF2563EB))),
          const SizedBox(width: 10),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ])),
        ]),
      );

  // -------------------------------------------------------------
  // REUSABLE THEME PICKER CONTAINER
  // -------------------------------------------------------------
  Widget _buildThemePickerCard({
    required String title,
    required String subtitle,
    required int selected,
    required List<ThemePresetMeta> presets,
    required ValueChanged<int> onChanged,
    required Widget Function(ThemePresetMeta meta, bool isSelected)
        previewBuilder,
  }) {
    final activeMeta = presets[selected.clamp(0, presets.length - 1)];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${selected + 1}/${presets.length} · ${activeMeta.title}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Horizontal scroll of preview cards
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, index) {
                final item = presets[index];
                final isSelected = selected == index;

                return GestureDetector(
                  onTap: () => onChanged(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 138,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: item.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : (item.isDark
                                ? Colors.white24
                                : const Color(0xFFE2E8F0)),
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Positioned.fill(
                              child: previewBuilder(item, isSelected)),

                          // Header indicator
                          Positioned(
                            top: 6,
                            left: 8,
                            right: 8,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: (item.isDark
                                            ? Colors.black
                                            : Colors.white)
                                        .withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#${index + 1}',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: item.isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2563EB),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Bottom label
                          Positioned(
                            bottom: 6,
                            left: 8,
                            right: 8,
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: item.isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // THUMBNAILS FOR THEMES
  // -------------------------------------------------------------
  Widget _buildAssetPreviewThumbnail(ThemePresetMeta meta) {
    return Stack(
      children: [
        if (meta.id == 1)
          Positioned.fill(
            child: CustomPaint(
                painter: NeonWavePainter(primaryColor: meta.accentColor)),
          )
        else if (meta.id == 2)
          Positioned.fill(
            child: CustomPaint(
                painter: EqualizerBarsPainter(primaryColor: meta.accentColor)),
          )
        else if (meta.id == 3)
          Positioned.fill(
            child: CustomPaint(
                painter: EmeraldWavePainter(primaryColor: meta.accentColor)),
          )
        else if (meta.id == 4)
          Positioned.fill(
            child: CustomPaint(
                painter: GoldenMeteorsPainter(primaryColor: meta.accentColor)),
          )
        else if (meta.id == 5)
          const Positioned.fill(
            child: CustomPaint(painter: PastelHorizonPainter()),
          )
        else if (meta.id == 6)
          Positioned.fill(
            child: CustomPaint(
                painter: HoloRadarPainter(primaryColor: meta.accentColor)),
          )
        else
          Center(
            child: Icon(
              Icons.blur_on_rounded,
              size: 28,
              color: meta.accentColor.withValues(alpha: 0.4),
            ),
          ),
        Positioned(
          top: 30,
          left: 8,
          child: Text(
            '203.940.692 đ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: meta.isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetPreviewThumbnail(ThemePresetMeta meta) {
    return Stack(
      children: [
        if (meta.id == 2)
          Positioned.fill(
            child: CustomPaint(
                painter: BotanicalLeavesPainter(leafColor: meta.accentColor)),
          ),
        Positioned(
          top: 28,
          left: 8,
          right: 8,
          child: Row(
            children: [
              Icon(Icons.pie_chart_rounded, size: 16, color: meta.accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: meta.accentColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssistantPreviewThumbnail(ThemePresetMeta meta) {
    return Center(
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: meta.accentColor, width: 3),
        ),
        child: Center(
          child: Text(
            '38',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: meta.accentColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryPreviewThumbnail(ThemePresetMeta meta) {
    return Stack(
      children: [
        if (meta.id == 2)
          Positioned.fill(
            child: CustomPaint(
                painter: BotanicalLeavesPainter(leafColor: meta.accentColor)),
          ),
        Positioned(
          left: 8,
          top: 28,
          bottom: 24,
          child: Container(
            width: 1.5,
            color: meta.accentColor.withValues(alpha: 0.4),
          ),
        ),
        Positioned(
          left: 18,
          top: 30,
          right: 8,
          child: Container(
            height: 14,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: (meta.isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ăn sáng',
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: meta.isDark ? Colors.white : Colors.black)),
                Text('-73.000 đ',
                    style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFEF4444))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
