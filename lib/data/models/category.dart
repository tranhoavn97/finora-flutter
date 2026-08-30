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
    return Category(
      id: id,
      userId: toStringValue(d['userId']),
      name: toStringValue(d['name']),
      icon: icon.isEmpty ? 'wallet' : icon,
      color: toStringOrNull(d['color']),
      categoryGroup: group.isEmpty ? 'expense' : group,
      isArchived: toBoolValue(d['isArchived']),
      createdAt: toLongValue(d['createdAt']),
      updatedAt: toLongValue(d['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'icon': icon,
        'color': color,
        'categoryGroup': categoryGroup,
        'isArchived': isArchived,
      };

  Category copyWith({
    String? id,
    String? userId,
    String? name,
    String? icon,
    String? color,
    String? categoryGroup,
    bool? isArchived,
    int? createdAt,
    int? updatedAt,
  }) =>
      Category(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        categoryGroup: categoryGroup ?? this.categoryGroup,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  static const List<Category> defaults = [
    Category(id: 'cat_food', name: 'Ăn uống', icon: 'utensils', color: '#EF4444', categoryGroup: 'expense'),
    Category(id: 'cat_transport', name: 'Di chuyển', icon: 'car', color: '#F59E0B', categoryGroup: 'expense'),
    Category(id: 'cat_shopping', name: 'Mua sắm', icon: 'shopping-bag', color: '#EC4899', categoryGroup: 'expense'),
    Category(id: 'cat_entertainment', name: 'Giải trí', icon: 'gamepad', color: '#10B981', categoryGroup: 'expense'),
    Category(id: 'cat_house', name: 'Nhà cửa', icon: 'home', color: '#3B82F6', categoryGroup: 'expense'),
    Category(id: 'cat_bills', name: 'Hóa đơn', icon: 'receipt', color: '#8B5CF6', categoryGroup: 'expense'),
    Category(id: 'cat_salary', name: 'Lương', icon: 'banknote', color: '#10B981', categoryGroup: 'income'),
    Category(id: 'cat_bonus', name: 'Thưởng', icon: 'gift', color: '#F59E0B', categoryGroup: 'income'),
    Category(id: 'cat_invest_income', name: 'Đầu tư', icon: 'trending-up', color: '#3B82F6', categoryGroup: 'income'),
    Category(id: 'cat_other_income', name: 'Thu nhập khác', icon: 'coins', color: '#6B7280', categoryGroup: 'income'),
    Category(id: 'cat_other_expense', name: 'Chi tiêu khác', icon: 'more-horizontal', color: '#6B7280', categoryGroup: 'expense'),
  ];
}
