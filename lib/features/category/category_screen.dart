import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/vikram_widgets.dart';
import '../../core/design_system/app_colors.dart';
import '../../data/models/category.dart';
import '../../state/more_provider.dart';
import '../../state/transaction_provider.dart';
import '../transaction/transaction_history_sheet.dart';

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
    return cat.categoryGroup == 'investment' || cat.categoryGroup == 'saving';
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
  String _group = 'expense';
  bool _isListView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MoreProvider>();
      provider.load(widget.userId);
      context.read<TransactionProvider>().load(widget.userId);
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
    HapticFeedback.selectionClick();
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
      content: 'Bạn có chắc chắn muốn xóa danh mục "${cat.name}" không?',
    );
    if (confirm && context.mounted) {
      context.read<MoreProvider>().deleteCategory(widget.userId, cat.id);
    }
  }

  void _openEdit(Category cat) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AddCategoryPage(
        userId: widget.userId,
        defaultGroup: cat.categoryGroup,
        category: cat,
      ),
    ));
  }

  void _showActions(Category cat) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Sửa danh mục'),
            onTap: () {
              Navigator.pop(sheetContext);
              _openEdit(cat);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text('Xóa danh mục'),
            onTap: () {
              Navigator.pop(sheetContext);
              _confirmDelete(cat);
            },
          ),
        ]),
      ),
    );
  }

  void _showHistory(Category category) {
    HapticFeedback.selectionClick();
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
    final c = context.fc;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MoreProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final allTxs = txProvider.transactions;

    final customFiltered =
        provider.categories.where((cat) => _matchesGroup(cat, _group)).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PearlMeshBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Danh mục',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: c.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _openAdd,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF075985), Color(0xFF22B8CF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0891B2).withOpacity(0.30),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add_rounded,
                            size: 24, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              // Segmented Tabs: Thu | Chi | Đầu tư
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: SegmentedControl(
                  options: const [
                    ('expense', 'Chi'),
                    ('income', 'Thu'),
                    ('investment', 'Đầu tư'),
                  ],
                  selected: _group,
                  onChanged: (v) => setState(() => _group = v),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xB8141F3C)
                          : Colors.white.withOpacity(.7),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withOpacity(.8)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      _viewButton(Icons.view_list_rounded, _isListView,
                          () => setState(() => _isListView = true)),
                      _viewButton(Icons.grid_view_rounded, !_isListView,
                          () => setState(() => _isListView = false)),
                    ]),
                  ),
                ),
              ),

              // Category List / Grid
              Expanded(
                child: customFiltered.isEmpty
                    ? Center(
                        child: EmptyState(
                          icon: Icons.category_outlined,
                          title: 'Chưa có danh mục nào',
                          subtitle:
                              'Hãy tạo danh mục mới để phân loại các khoản thu chi.',
                          actionText: 'Tạo danh mục mới',
                          onAction: _openAdd,
                        ),
                      )
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        child: _isListView
                            ? ListView.builder(
                                key: const ValueKey('category-list'),
                                physics: const BouncingScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 110),
                                itemCount: customFiltered.length,
                                itemBuilder: (context, i) {
                                  final cat = customFiltered[i];
                                  final matchingTxs = allTxs
                                      .where((t) =>
                                          t.categoryId == cat.id ||
                                          t.categoryName == cat.name)
                                      .toList();
                                  final txCount = matchingTxs.length;
                                  final totalAmount = matchingTxs.fold<int>(
                                      0, (s, t) => s + t.amount);

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _CategoryListTile(
                                      category: cat,
                                      txCount: txCount,
                                      totalAmount: totalAmount,
                                      onTap: () => _showHistory(cat),
                                      onLongPress: () => _showActions(cat),
                                    ),
                                  );
                                },
                              )
                            : GridView.builder(
                                key: const ValueKey('category-grid'),
                                physics: const BouncingScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 110),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 1.22,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10),
                                itemCount: customFiltered.length,
                                itemBuilder: (context, i) {
                                  final cat = customFiltered[i];
                                  final matching = allTxs
                                      .where((t) =>
                                          t.categoryId == cat.id ||
                                          t.categoryName == cat.name)
                                      .toList();
                                  return _CategoryGridTile(
                                      category: cat,
                                      txCount: matching.length,
                                      totalAmount: matching.fold<int>(
                                          0, (s, t) => s + t.amount),
                                      onTap: () => _showHistory(cat),
                                      onLongPress: () => _showActions(cat));
                                },
                              )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewButton(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          shape: active ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: active ? null : BorderRadius.circular(18),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? Colors.white : Colors.grey,
        ),
      ),
    );
  }
}

class _CategoryListTile extends StatelessWidget {
  final Category category;
  final int txCount;
  final int totalAmount;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _CategoryListTile({
    required this.category,
    required this.txCount,
    required this.totalAmount,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = _parseHexColor(category.color) ?? AppColors.primary;

    return FrostedCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: InkWell(
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            // Circular Category Icon
            IconBadge(
              emoji: CategoryIconHelper.resolveIcon(category.icon),
              tint: tint,
              size: 44,
              radius: 22,
            ),
            const SizedBox(width: 12),
            // Name + Transactions count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E2B4D)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$txCount giao dịch',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Total Spent/Received
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatVND(totalAmount),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category.categoryGroup == 'income' ? 'Thu vào' : 'Đã chi',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGridTile extends StatelessWidget {
  final Category category;
  final int txCount;
  final int totalAmount;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _CategoryGridTile(
      {required this.category,
      required this.txCount,
      required this.totalAmount,
      required this.onTap,
      required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final tint = _parseHexColor(category.color) ?? AppColors.primary;
    return FrostedCard(
      radius: 24,
      padding: const EdgeInsets.all(13),
      onTap: onTap,
      child: InkWell(
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconBadge(
                emoji: CategoryIconHelper.resolveIcon(category.icon),
                tint: tint,
                size: 42,
                radius: 21),
            const Spacer(),
            Text('$txCount',
                style: TextStyle(
                    color: c.textTertiary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11)),
          ]),
          const Spacer(),
          Text(category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(formatVND(totalAmount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: tint, fontSize: 12, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

class AddCategoryPage extends StatefulWidget {
  final String userId;
  final String defaultGroup;
  final Category? category;
  const AddCategoryPage({
    super.key,
    required this.userId,
    required this.defaultGroup,
    this.category,
  });

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final _nameController = TextEditingController();
  final _emojiController = TextEditingController(text: '🍔');
  late String _group;
  String _color = '#0891B2';
  bool _isSaving = false;

  static const _colors = [
    '#0891B2',
    '#4CAEFE',
    '#31C981',
    '#FF8A35',
    '#FFAA22',
    '#F04452',
    '#0EA5E9',
    '#06B6D4',
    '#64748B',
    '#10B981',
  ];

  @override
  void initState() {
    super.initState();
    _group = widget.defaultGroup;
    final category = widget.category;
    if (category != null) {
      _nameController.text = category.name;
      _emojiController.text = category.icon;
      _color = category.color ?? _color;
    }
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
      if (widget.category == null) {
        await context.read<MoreProvider>().addCategory(widget.userId, category);
      } else {
        await context
            .read<MoreProvider>()
            .updateCategory(widget.userId, widget.category!.id, category);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final previewTint = _parseHexColor(_color) ?? AppColors.primary;
    final previewEmoji = _emojiController.text.trim().isEmpty
        ? '🍔'
        : _emojiController.text.trim();

    return GlassScaffold(
      appBar: GlassTopBar(
        title: widget.category == null ? 'Thêm danh mục mới' : 'Sửa danh mục',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  GlassCard(
                    radius: 22,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Overline('TÊN DANH MỤC'),
                        const SizedBox(height: 6),
                        FinoraTextField(
                          controller: _nameController,
                          hint: 'Ví dụ: Ăn uống, Tiền điện...',
                          radius: 18,
                        ),
                        const SizedBox(height: 14),
                        const Overline('NHÓM DANH MỤC'),
                        const SizedBox(height: 6),
                        SegmentedControl(
                          options: const [
                            ('expense', 'Chi tiêu'),
                            ('income', 'Thu nhập'),
                            ('investment', 'Đầu tư'),
                          ],
                          selected: _group,
                          onChanged: (v) => setState(() => _group = v),
                        ),
                        const SizedBox(height: 14),
                        const Overline('BIỂU TƯỢNG (EMOJI)'),
                        const SizedBox(height: 6),
                        FinoraTextField(
                          controller: _emojiController,
                          hint: '🍔',
                          radius: 18,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  GlassCard(
                    radius: 22,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Overline('XEM TRƯỚC HIỂN THỊ'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            IconBadge(
                                emoji: previewEmoji,
                                tint: previewTint,
                                size: 48,
                                radius: 16),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _nameController.text.trim().isEmpty
                                    ? 'Tên danh mục'
                                    : _nameController.text.trim(),
                                style: TextStyle(
                                  color: c.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Overline('MÀU SẮC ĐẠI DIỆN'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final hex in _colors)
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _color = hex);
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _parseHexColor(hex) ??
                                        AppColors.primary,
                                    border: Border.all(
                                      color: _color == hex
                                          ? c.textPrimary
                                          : Colors.transparent,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      if (_color == hex)
                                        BoxShadow(
                                          color: (_parseHexColor(hex) ??
                                                  AppColors.primary)
                                              .withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: PrimaryButton(
                expand: true,
                onPressed: _isSaving ? null : _submit,
                isLoading: _isSaving,
                child: Text(
                    widget.category == null ? 'Lưu danh mục' : 'Lưu thay đổi',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
