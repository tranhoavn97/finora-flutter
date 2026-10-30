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
    var icon = toStringValue(d['icon']).trim();
    if (icon.isEmpty) icon = toStringValue(d['logo']).trim();
    if (icon.isEmpty) icon = toStringValue(d['imageUrl']).trim();
    if (icon.isEmpty) icon = toStringValue(d['iconUrl']).trim();
    if (icon.isEmpty) icon = toStringValue(d['avatar']).trim();
    if (icon.isEmpty) icon = toStringValue(d['emoji']).trim();
    final group = toStringValue(d['categoryGroup']).trim().toLowerCase();
    final type = toStringValue(d['type']).trim().toLowerCase();
    final String resolvedGroup;
    if (group == 'income' || type == 'income') {
      resolvedGroup = 'income';
    } else if (group == 'merchant' || type == 'merchant') {
      resolvedGroup = 'merchant';
    } else if (group == 'investment' ||
        type == 'investment' ||
        group == 'saving' ||
        type == 'saving') {
      resolvedGroup = 'investment';
    } else {
      resolvedGroup = 'expense';
    }
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

  static const List<Category> defaultMerchants = [
    Category(
      id: 'green_sm',
      name: 'Green SM',
      icon: 'car',
      color: '#059669',
      categoryGroup: 'merchant',
    ),
    Category(
      id: 'be',
      name: 'Be',
      icon: 'bike',
      color: '#EAB308',
      categoryGroup: 'merchant',
    ),
    Category(
      id: 'shopee',
      name: 'Shopee',
      icon: 'assets/banks/shopee.jpg',
      color: '#EE4D2D',
      categoryGroup: 'merchant',
    ),
    Category(
      id: 'winmart',
      name: 'WinMart',
      icon: 'assets/banks/winmart.png',
      color: '#E11D48',
      categoryGroup: 'merchant',
    ),
    Category(
      id: 'grab',
      name: 'Grab',
      icon: 'car',
      color: '#059669',
      categoryGroup: 'merchant',
    ),
    Category(
      id: 'tiktok_shop',
      name: 'TikTok Shop',
      icon: 'video',
      color: '#000000',
      categoryGroup: 'merchant',
    ),
  ];

  /// Single source of truth for resolving active merchants across CategoryScreen & AddTransactionPage.
  static List<Category> resolveMerchants(
    Iterable<Category> customCategories, {
    Set<String> deletedMerchantKeys = const {},
  }) {
    final result = <Category>[];
    final seenIds = <String>{};
    final seenNames = <String>{};

    for (final c in customCategories) {
      if (c.categoryGroup != 'merchant' || c.isArchived) continue;
      final idKey = c.id.trim().toLowerCase();
      final nameKey = c.name.trim().toLowerCase();
      if (deletedMerchantKeys.contains(idKey) ||
          deletedMerchantKeys.contains(nameKey)) {
        continue;
      }
      if ((idKey.isNotEmpty && seenIds.contains(idKey)) ||
          (nameKey.isNotEmpty && seenNames.contains(nameKey))) {
        continue;
      }
      if (idKey.isNotEmpty) seenIds.add(idKey);
      if (nameKey.isNotEmpty) {
        seenNames.add(nameKey);
        if (nameKey == 'xanh sm' || nameKey == 'green sm') {
          seenIds.add('green_sm');
          seenNames.add('green sm');
          seenNames.add('xanh sm');
        }
      }
      result.add(c);
    }

    for (final dm in defaultMerchants) {
      final idKey = dm.id.trim().toLowerCase();
      final nameKey = dm.name.trim().toLowerCase();
      if (deletedMerchantKeys.contains(idKey) ||
          deletedMerchantKeys.contains(nameKey)) {
        continue;
      }
      if (seenIds.contains(idKey) || seenNames.contains(nameKey)) {
        continue;
      }
      seenIds.add(idKey);
      seenNames.add(nameKey);
      result.add(dm);
    }
    return result;
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
