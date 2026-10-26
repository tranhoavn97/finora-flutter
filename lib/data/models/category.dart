import 'coerce.dart';

class Category {
  final String id;
  final String userId;
  final String name;
  final String icon;
  final String? color;
  final String categoryGroup;
  final bool isArchived;
  final int createdAt;
  final int updatedAt;

  const Category({
    this.id = '',
    this.userId = '',
    this.name = '',
    this.icon = 'wallet',
    this.color,
    this.categoryGroup = 'expense',
    this.isArchived = false,
    this.createdAt = 0,
    this.updatedAt = 0,
  });

  factory Category.fromMap(String id, Map<String, dynamic>? data) {
    final d = data ?? const {};
    final icon = toStringValue(d['icon']);
    final group = toStringValue(d['categoryGroup']);
    final type = toStringValue(d['type']);
    final resolvedGroup = group.isNotEmpty
        ? group
        : (type == 'merchant' ? 'merchant' : 'expense');
    return Category(
      id: id,
      userId: toStringValue(d['userId']),
      name: toStringValue(d['name']),
      icon: icon.isEmpty ? (resolvedGroup == 'merchant' ? 'store' : 'wallet') : icon,
      color: toStringOrNull(d['color']),
      categoryGroup: resolvedGroup,
      isArchived: toBoolValue(d['isArchived']),
      createdAt: toLongValue(d['createdAt']),
      updatedAt: toLongValue(d['updatedAt']),
    );
  }

  static const List<Category> defaults = [
    Category(id: 'food', name: 'Ăn uống', icon: 'utensils', categoryGroup: 'expense'),
    Category(id: 'transport', name: 'Đi lại', icon: 'car', categoryGroup: 'expense'),
    Category(id: 'shopping', name: 'Mua sắm', icon: 'shopping-bag', categoryGroup: 'expense'),
    Category(id: 'bills', name: 'Hóa đơn', icon: 'receipt', categoryGroup: 'expense'),
    Category(id: 'entertainment', name: 'Giải trí', icon: 'film', categoryGroup: 'expense'),
    Category(id: 'health', name: 'Sức khỏe', icon: 'heart', categoryGroup: 'expense'),
    Category(id: 'education', name: 'Giáo dục', icon: 'book', categoryGroup: 'expense'),
    Category(id: 'salary', name: 'Lương', icon: 'briefcase', categoryGroup: 'income'),
    Category(id: 'bonus', name: 'Thưởng', icon: 'award', categoryGroup: 'income'),
    Category(id: 'investment_in', name: 'Đầu tư', icon: 'trending-up', categoryGroup: 'income'),
    Category(id: 'other', name: 'Khác', icon: 'more-horizontal', categoryGroup: 'expense'),
  ];
}
