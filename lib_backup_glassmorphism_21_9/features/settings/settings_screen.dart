import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../state/theme_controller.dart';
import '../../state/theme_studio_controller.dart';

class SettingsScreen extends StatelessWidget {
  final String userId;
  const SettingsScreen({super.key, required this.userId});

  static const _modes = [
    ('system', 'Theo thiết bị', Icons.brightness_auto_rounded),
    ('light', 'Sáng', Icons.light_mode_outlined),
    ('dark', 'Tối', Icons.dark_mode_outlined),
    ('amoled', 'Đen AMOLED', Icons.nightlight_round),
  ];

  Future<void> _choose<T>(
    BuildContext context, {
    required String title,
    required T selected,
    required List<(T, String, Widget)> options,
    required Future<void> Function(T) save,
  }) async {
    final value = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * .75),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                child: Text(title,
                    style: Theme.of(sheetContext).textTheme.titleLarge),
              ),
              for (final option in options)
                ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  leading: option.$3,
                  title: Text(option.$2),
                  selected: option.$1 == selected,
                  trailing: option.$1 == selected
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, option.$1),
                ),
            ],
          ),
        ),
      ),
    );
    if (value == null || value == selected) return;
    try {
      await save(value);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Chưa lưu được lựa chọn trên thiết bị. Vui lòng thử lại.'),
        ));
      }
    }
  }

  Widget _swatch(List<Color> colors) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: .25)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final studio = context.watch<ThemeStudioController>();
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = _modes.firstWhere((m) => m.$1 == theme.mode,
        orElse: () => _modes.first);
    return GlassScaffold(
      appBar: GlassTopBar(
          title: 'Cài đặt', onBack: () => Navigator.of(context).pop()),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text('Giao diện',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Điều chỉnh cách Finora hiển thị trên thiết bị này.',
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.5)),
            const SizedBox(height: 20),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: .9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Column(children: [
                _row(
                  context,
                  icon: Icon(mode.$3, color: colors.primary),
                  title: 'Chế độ hiển thị',
                  value: mode.$2,
                  onTap: () => _choose<String>(
                    context,
                    title: 'Chế độ hiển thị',
                    selected: theme.mode,
                    options: [for (final m in _modes) (m.$1, m.$2, Icon(m.$3))],
                    save: theme.setMode,
                  ),
                ),
                const Divider(height: 1, indent: 68, endIndent: 16),
                _row(
                  context,
                  icon: _swatch([studio.primaryColor, studio.secondaryColor]),
                  title: 'Màu chủ đạo',
                  value: studio.currentPaletteMeta.title,
                  onTap: () => _choose<AppColorPalette>(
                    context,
                    title: 'Màu chủ đạo',
                    selected: studio.palette,
                    options: [
                      for (final p in ThemeStudioController.palettes)
                        (p.palette, p.title, _swatch([p.primary, p.secondary]))
                    ],
                    save: studio.setPalette,
                  ),
                ),
                const Divider(height: 1, indent: 68, endIndent: 16),
                _row(
                  context,
                  icon: _swatch(isDark
                      ? studio.currentAmbientBlurMeta.bgColorsDark
                      : studio.currentAmbientBlurMeta.bgColorsLight),
                  title: 'Màu nền',
                  value: studio.currentAmbientBlurMeta.title,
                  onTap: () => _choose<AmbientBlurPreset>(
                    context,
                    title: 'Màu nền',
                    selected: studio.ambientBlur,
                    options: [
                      for (final p in ThemeStudioController.ambientBlurPresets)
                        (
                          p.preset,
                          p.title,
                          _swatch(isDark ? p.bgColorsDark : p.bgColorsLight)
                        )
                    ],
                    save: studio.setAmbientBlur,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            Text('Thay đổi được áp dụng ngay và tự động lưu trên thiết bị.',
                style: TextStyle(
                    fontSize: 12, height: 1.5, color: colors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required Widget icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: SizedBox(width: 36, height: 36, child: Center(child: icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(value,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant))),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: onTap,
      );
}
