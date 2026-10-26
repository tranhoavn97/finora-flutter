import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_radius.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../data/models/category.dart';
import '../../state/more_provider.dart';
import '../transaction/transaction_history_sheet.dart';

/// Parses a "#RRGGBB" / "#AARRGGBB" hex string into a [Color], or null.
Color? _parseHexColor(String? hex) {
  if (hex == null) return null;
  var clean = hex.trim().replaceFirst('#', '');
  if (clean.length == 6) clean = 'FF$clean';
  if (clean.length != 8) return null;
  final value = int.tryParse(clean, radix: 16);
  if (value == null) return null;
  return Color(value);
}

bool _matchesGroup(Category cat, String group) {
  if (group == 'investment') {
    return cat.categoryGroup == 'investment' ||
        cat.categoryGroup == 'saving';
  }
  return cat.categoryGroup == group;
}

/// Category management page — custom + default categories grouped by type.
class CategoryScreen extends StatefulWidget {
  final String userId;
  const CategoryScreen({super.key, required this.userId});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  StreamSubscription<String>? _eventsSub;
  String _group = 'expense'; // expense | income | investment

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MoreProvider>();
      provider.load(widget.userId);
      _eventsSub = provider.events.listen((msg) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
      });
    });
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    super.dispose();
  }

  void _openAdd() {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AddCategoryPage(
        userId: widget.userId,
        defaultGroup: _group == 'investment' ? 'investment' : _group,
      ),
    ));
  }

  void _confirmDelete(Category cat) async {
    final confirm = await showConfirmDeleteDialog(
      context: context,
      title: 'Xóa danh mục?',
      content: "Bạn có chắc chắn muốn xóa danh mục '${cat.name}' không?",
    );
    if (confirm && context.mounted) {
      context.read<MoreProvider>().deleteCategory(widget.userId, cat.id);
    }
  }

  void _showHistory(Category category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: TransactionHistorySheet(
          userId: widget.userId,
          categoryId: category.id,
          categoryName: category.name,
          categoryIcon: category.icon,
          categoryColor: category.color,
          categoryGroup: category.categoryGroup,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final provider = context.watch<MoreProvider>();

    final customFiltered = provider.categories
        .where((cat) => _matchesGroup(cat, _group))
        .toList();
    final defaultFiltered = Category.defaults
        .where((cat) => _matchesGroup(cat, _group))
        .toList();

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Quản lý danh mục',
        onBack: () => Navigator.of(context).pop(),
        actions: [
          IconButton(
            onPressed: _openAdd,
            icon: const Icon(Icons.add, color: AppColors.accent),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
            child: SegmentedControl(
              options: const [
                ('expense', 'Chi tiêu'),
                ('income', 'Thu nhập'),
                ('investment', 'Đầu tư & Tiết kiệm'),
              ],
              selected: _group,
              onChanged: (v) => setState(() => _group = v),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 80),
              children: [
                if (customFiltered.isEmpty)
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const IconBadge(
                            emoji: '✨', tint: AppColors.accent, size: 52),
                        const SizedBox(height: 12),
                        Text('Chưa có danh mục nào',
                            textAlign: TextAlign.center,
                            style: AppTypography.subhead.copyWith(
                                color: primaryTextColor,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(
                            'Hãy tạo danh mục mới để quản lý chi tiêu tốt hơn.',
                            textAlign: TextAlign.center,
                            style: AppTypography.caption2
                                .copyWith(color: secondaryTextColor)),
                        const SizedBox(height: AppSpacing.md),
                        PrimaryButton(
                          onPressed: _openAdd,
                          child: const Text('Tạo danh mục',
                              style:
                                  TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  )
                else
                  _CategoryGrid(
                    categories: customFiltered,
                    isDefault: false,
                    onTapItem: _showHistory,
                    onLongPressItem: _confirmDelete,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 2-column grid of category tiles using [Wrap].
class _CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final bool isDefault;
  final ValueChanged<Category> onTapItem;
  final ValueChanged<Category> onLongPressItem;
  const _CategoryGrid({
    required this.categories,
    required this.isDefault,
    required this.onTapItem,
    required this.onLongPressItem,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final tileWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final cat in categories)
              SizedBox(
                width: tileWidth,
                child: _CategoryTile(
                  category: cat,
                  isDefault: isDefault,
                  onTap: () => onTapItem(cat),
                  onLongPress: () => onLongPressItem(cat),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final bool isDefault;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _CategoryTile({
    required this.category,
    required this.isDefault,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final tint = _parseHexColor(category.color) ?? AppColors.accent;

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.card,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: AppRadius.card,
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconBadge(
                      emoji: CategoryIconHelper.resolveIcon(category.icon),
                      tint: tint,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTypography.caption2.copyWith(
                              color: primaryTextColor,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  isDefault ? Icons.lock : Icons.edit,
                  size: 12,
                  color: isDefault
                      ? secondaryTextColor.withOpacity(0.4)
                      : AppColors.accent.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen form to add a custom category (name, emoji, color, group).
class AddCategoryPage extends StatefulWidget {
  final String userId;
  final String defaultGroup;
  const AddCategoryPage({
    super.key,
    required this.userId,
    required this.defaultGroup,
  });

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final _nameController = TextEditingController();
  final _emojiController = TextEditingController(text: '🍔');
  late String _group;
  String _color = '#16C784';
  bool _isSaving = false;

  static const _colors = [
    '#16C784', '#2F7CF6', '#4DA3FF', '#EC4899', '#F5B942',
    '#FF5D73', '#8B5CF6', '#06B6D4', '#10B981', '#6B7280',
  ];

  @override
  void initState() {
    super.initState();
    _group = widget.defaultGroup;
    // Live-update the preview tile as the user edits name / emoji.
    _nameController.addListener(_onPreviewChanged);
    _emojiController.addListener(_onPreviewChanged);
  }

  void _onPreviewChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    
    try {
      final emoji = _emojiController.text.trim();
      final now = DateTime.now().millisecondsSinceEpoch;
      final category = Category(
        userId: widget.userId,
        name: name,
        icon: emoji.isEmpty ? '🍔' : emoji,
        color: _color,
        categoryGroup: _group,
        createdAt: now,
        updatedAt: now,
      );
      await context.read<MoreProvider>().addCategory(widget.userId, category);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final previewTint = _parseHexColor(_color) ?? const Color(0xFF34D399);
    final previewEmoji = _emojiController.text.trim().isEmpty
        ? '🍔'
        : _emojiController.text.trim();

    return GlassScaffold(
      appBar: GlassTopBar(
        title: 'Thêm danh mục mới',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
              children: [
                Text('Tên danh mục',
                    style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GlassTextField(
                  controller: _nameController,
                  hint: 'Ví dụ: Ăn uống',
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Nhóm danh mục',
                    style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedControl(
                  options: const [
                    ('expense', 'Chi tiêu'),
                    ('income', 'Thu nhập'),
                    ('investment', 'Đầu tư'),
                  ],
                  selected: _group,
                  onChanged: (v) => setState(() => _group = v),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Biểu tượng (Emoji)',
                    style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GlassTextField(
                  controller: _emojiController,
                  hint: '🍔',
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Xem trước biểu tượng',
                    style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: AppRadius.card,
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      IconBadge(emoji: previewEmoji, tint: previewTint, size: 50),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                            _nameController.text.trim().isEmpty
                                ? 'Tên danh mục'
                                : _nameController.text.trim(),
                            style: AppTypography.subhead.copyWith(
                                color: primaryTextColor,
                                fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Chọn màu đại diện',
                    style: AppTypography.caption1.copyWith(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final hex in _colors)
                      GestureDetector(
                        onTap: () => setState(() => _color = hex),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _parseHexColor(hex) ?? AppColors.accent,
                            border: Border.all(
                              color: _color == hex
                                  ? primaryTextColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
              child: PrimaryButton(
                expand: true,
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Lưu danh mục',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
