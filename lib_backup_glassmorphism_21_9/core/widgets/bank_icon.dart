import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'premium_widgets.dart';
import '../utils/formatters.dart';

class BankBrand {
  final String code;
  final String name;
  final Color color;
  final String? assetPath;

  const BankBrand({
    required this.code,
    required this.name,
    required this.color,
    this.assetPath,
  });
}

/// Registry mapping bank short codes to their local asset paths.
class BankIconRegistry {
  static const List<BankBrand> brands = [
    BankBrand(
        code: 'vcb',
        name: 'Vietcombank',
        color: Color(0xFF61A928),
        assetPath: 'assets/banks/vcb.jpg'),
    BankBrand(
        code: 'mbbank',
        name: 'MB BANK',
        color: Color(0xFF141ED2),
        assetPath: 'assets/banks/mbbank.jpg'),
    BankBrand(
        code: 'tcb',
        name: 'Techcombank',
        color: Color(0xFFEA0029),
        assetPath: 'assets/banks/tcb.jpg'),
    BankBrand(
        code: 'bidv',
        name: 'BIDV',
        color: Color(0xFF0F6F74),
        assetPath: 'assets/banks/bidv.jpg'),
    BankBrand(
        code: 'vtb',
        name: 'VietinBank',
        color: Color(0xFF00558F),
        assetPath: 'assets/banks/vtb.jpg'),
    BankBrand(
        code: 'acb',
        name: 'ACB',
        color: Color(0xFF005EAF),
        assetPath: 'assets/banks/acb.jpg'),
    BankBrand(
        code: 'vpb',
        name: 'VPBank',
        color: Color(0xFF00AF5A),
        assetPath: 'assets/banks/vpb.jpg'),
    BankBrand(
        code: 'tpb',
        name: 'TPBank',
        color: Color(0xFF8E2B88),
        assetPath: 'assets/banks/tpb.jpg'),
    BankBrand(
        code: 'stb',
        name: 'Sacombank',
        color: Color(0xFF00539E),
        assetPath: 'assets/banks/stb.jpg'),
    BankBrand(
        code: 'shb',
        name: 'SHB',
        color: Color(0xFFF36F21),
        assetPath: 'assets/banks/shb.jpg'),
    BankBrand(
        code: 'hdb',
        name: 'HDBank',
        color: Color(0xFFED1B24),
        assetPath: 'assets/banks/hdb.jpg'),
    BankBrand(
        code: 'vib',
        name: 'VIB',
        color: Color(0xFF005A9C),
        assetPath: 'assets/banks/vib.jpg'),
    BankBrand(
        code: 'msb',
        name: 'MSB',
        color: Color(0xFFF47D22),
        assetPath: 'assets/banks/msb.jpg'),
    BankBrand(
        code: 'ocb',
        name: 'OCB',
        color: Color(0xFF007A3E),
        assetPath: 'assets/banks/ocb.jpg'),
    BankBrand(
        code: 'sea',
        name: 'SeABank',
        color: Color(0xFFE31837),
        assetPath: 'assets/banks/sea.jpg'),
    BankBrand(
        code: 'eib',
        name: 'Eximbank',
        color: Color(0xFF005C9C),
        assetPath: 'assets/banks/eib.jpg'),
    BankBrand(
        code: 'agri',
        name: 'Agribank',
        color: Color(0xFFB3292C),
        assetPath: 'assets/banks/agri.jpg'),
    BankBrand(
        code: 'cake',
        name: 'Cake',
        color: Color(0xFFF61F6E),
        assetPath: 'assets/banks/cake.jpg'),
    BankBrand(
        code: 'timo',
        name: 'Timo',
        color: Color(0xFF5F2C82),
        assetPath: 'assets/banks/timo.jpg'),
    BankBrand(
        code: 'momo',
        name: 'MoMo',
        color: Color(0xFFA50064),
        assetPath: 'assets/banks/momo.jpg'),
    BankBrand(
        code: 'zalo',
        name: 'ZaloPay',
        color: Color(0xFF0088FF),
        assetPath: 'assets/banks/zalo.jpg'),
    BankBrand(
        code: 'vnpay',
        name: 'VNPAY',
        color: Color(0xFFEC1C24),
        assetPath: 'assets/banks/vnpay.jpg'),
    BankBrand(
        code: 'shopeepay',
        name: 'ShopeePay',
        color: Color(0xFFEE4D2D),
        assetPath: 'assets/banks/shopeepay.jpg'),
    BankBrand(
        code: 'viettelmoney',
        name: 'Viettel Money',
        color: Color(0xFFEE0033),
        assetPath: 'assets/banks/viettelmoney.jpg'),
    BankBrand(
        code: 'vnptmoney',
        name: 'VNPT Money',
        color: Color(0xFF0066B3),
        assetPath: 'assets/banks/vnptmoney.jpg'),
    BankBrand(code: 'cash', name: 'Tiền mặt', color: Color(0xFF10B981)),
  ];

  static BankBrand resolve(String? code, {String? bankName}) {
    final source = (code?.trim().isNotEmpty == true ? code : bankName);
    if (source == null || source.trim().isEmpty) {
      return brands.firstWhere((b) => b.code == 'cash');
    }
    var clean =
        source.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (clean.startsWith('bank')) clean = clean.substring(4);
    if (clean.startsWith('brand')) clean = clean.substring(5);

    if (clean.contains('momo'))
      return brands.firstWhere((b) => b.code == 'momo');
    if (clean.contains('zalo'))
      return brands.firstWhere((b) => b.code == 'zalo');
    if (clean.contains('shopee'))
      return brands.firstWhere((b) => b.code == 'shopeepay');
    if (clean.contains('viettel'))
      return brands.firstWhere((b) => b.code == 'viettelmoney');
    if (clean.contains('vnpt'))
      return brands.firstWhere((b) => b.code == 'vnptmoney');
    if (clean.contains('vnpay'))
      return brands.firstWhere((b) => b.code == 'vnpay');
    if (clean.contains('tienmat') || clean.contains('cash'))
      return brands.firstWhere((b) => b.code == 'cash');

    if (clean == 'mb' || clean == 'mbbank' || clean.contains('mbbank'))
      return brands.firstWhere((b) => b.code == 'mbbank');
    if (clean == 'techcombank' ||
        clean == 'tcb' ||
        clean.contains('techcombank'))
      return brands.firstWhere((b) => b.code == 'tcb');
    if (clean == 'vietcombank' ||
        clean == 'vcb' ||
        clean.contains('vietcombank'))
      return brands.firstWhere((b) => b.code == 'vcb');
    if (clean == 'vietinbank' ||
        clean == 'ctg' ||
        clean == 'vtb' ||
        clean.contains('vietinbank'))
      return brands.firstWhere((b) => b.code == 'vtb');
    if (clean == 'vpbank' || clean == 'vpb' || clean.contains('vpbank'))
      return brands.firstWhere((b) => b.code == 'vpb');
    if (clean == 'tpbank' || clean == 'tpb' || clean.contains('tpbank'))
      return brands.firstWhere((b) => b.code == 'tpb');
    if (clean == 'sacombank' || clean == 'stb' || clean.contains('sacombank'))
      return brands.firstWhere((b) => b.code == 'stb');
    if (clean == 'bidv' || clean.contains('bidv'))
      return brands.firstWhere((b) => b.code == 'bidv');
    if (clean == 'acb' || clean.contains('acb'))
      return brands.firstWhere((b) => b.code == 'acb');
    if (clean == 'agribank' || clean.contains('agribank') || clean == 'agri')
      return brands.firstWhere((b) => b.code == 'agri');
    if (clean == 'shb' || clean.contains('shb'))
      return brands.firstWhere((b) => b.code == 'shb');
    if (clean == 'hdb' || clean == 'hdbank' || clean.contains('hdbank'))
      return brands.firstWhere((b) => b.code == 'hdb');
    if (clean == 'vib' || clean.contains('vib'))
      return brands.firstWhere((b) => b.code == 'vib');
    if (clean == 'msb' || clean.contains('msb'))
      return brands.firstWhere((b) => b.code == 'msb');
    if (clean == 'ocb' || clean.contains('ocb'))
      return brands.firstWhere((b) => b.code == 'ocb');
    if (clean == 'sea' || clean == 'seabank' || clean.contains('seabank'))
      return brands.firstWhere((b) => b.code == 'sea');
    if (clean == 'eib' || clean == 'eximbank' || clean.contains('eximbank'))
      return brands.firstWhere((b) => b.code == 'eib');
    if (clean == 'cake' || clean.contains('cake'))
      return brands.firstWhere((b) => b.code == 'cake');
    if (clean == 'timo' || clean.contains('timo'))
      return brands.firstWhere((b) => b.code == 'timo');

    return brands.firstWhere(
      (b) =>
          b.code.replaceAll(RegExp(r'[^a-z0-9]'), '') == clean ||
          b.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') == clean,
      orElse: () => brands.firstWhere((b) => b.code == 'cash'),
    );
  }

  static Color parseThemeColor(String? hex,
      {Color fallback = const Color(0xFF10B981)}) {
    if (hex == null) return fallback;
    var clean = hex.trim().replaceFirst('#', '');
    if (clean.length == 6) clean = 'FF$clean';
    if (clean.length != 8) return fallback;
    final value = int.tryParse(clean, radix: 16);
    if (value == null) return fallback;
    return Color(value);
  }

  /// Returns the asset path for a bank code, or null if not registered.
  static String? getAssetPath(String code) {
    final brand = resolve(code);
    return brand.code == 'cash' ? null : brand.assetPath;
  }

  /// Returns a list of all registered bank codes.
  static List<String> get registeredCodes =>
      brands.map((bank) => bank.code).toList();
}

/// A circular icon for Vietnamese banks, mapping to BankIconAvatar.
class BankIcon extends StatelessWidget {
  final String? bankCode;
  final String? bankName;
  final double size;

  const BankIcon({
    super.key,
    this.bankCode,
    this.bankName,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    final brand = BankIconRegistry.resolve(bankCode, bankName: bankName);
    return BankIconAvatar(
      bankCode: brand.code,
      size: size,
    );
  }
}

/// Renders a synchronized category icon:
/// - If the icon is a bank / brand logo with an asset, displays the image
/// - Otherwise displays the emoji cleanly
class CategoryIconWidget extends StatelessWidget {
  final String? icon;
  final String? categoryName;
  final double size;
  final Color? color;

  const CategoryIconWidget({
    super.key,
    required this.icon,
    this.categoryName,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final raw = icon?.trim() ?? '';
    if (raw.startsWith('https://') ||
        raw.startsWith('http://') ||
        raw.startsWith('//') ||
        raw.contains('/storage/')) {
      final url = raw.startsWith('//') ? 'https:$raw' : raw;
      return SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: Image.network(
            url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => Icon(
              Icons.image_not_supported_outlined,
              size: size * 0.56,
              color: color,
            ),
          ),
        ),
      );
    }
    final assetPath = CategoryIconHelper.getAssetPath(icon);
    if (assetPath != null) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: Image.asset(
            assetPath,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(
              child: Text(
                CategoryIconHelper.resolveIcon(icon, categoryName),
                style: TextStyle(fontSize: size * 0.6),
              ),
            ),
          ),
        ),
      );
    }

    final iconData = _categoryLucideIcons[raw.toLowerCase()];
    if (iconData != null) {
      return Icon(iconData, size: size * 0.62, color: color);
    }
    return Text(CategoryIconHelper.resolveIcon(icon, categoryName),
        style: TextStyle(fontSize: size * 0.6, color: color));
  }
}

/// Circular colored badge wrapping [CategoryIconWidget] with border, glow, and theme tint.
class CategoryIconBadge extends StatelessWidget {
  final String? icon;
  final String? categoryName;
  final String? colorHex;
  final Color? color;
  final double size;
  final bool isDark;

  const CategoryIconBadge({
    super.key,
    required this.icon,
    this.categoryName,
    this.colorHex,
    this.color,
    this.size = 40.0,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? BankIconRegistry.parseThemeColor(colorHex);
    final raw = icon?.trim() ?? '';
    final isPhoto = raw.startsWith('https://') ||
        raw.startsWith('http://') ||
        raw.startsWith('//') ||
        raw.contains('/storage/');
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPhoto
            ? Colors.transparent
            : tint.withValues(alpha: isDark ? 0.22 : 0.14),
        border: isPhoto
            ? null
            : Border.all(
                color: tint.withValues(alpha: isDark ? 0.38 : 0.28),
                width: 1.2,
              ),
        boxShadow: isPhoto
            ? null
            : [
                BoxShadow(
                  color: tint.withValues(alpha: isDark ? 0.25 : 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Center(
        child: CategoryIconWidget(
          icon: icon,
          categoryName: categoryName,
          size: isPhoto ? size : size * 0.65,
          color: tint,
        ),
      ),
    );
  }
}

/// Same category icon identifiers as `web/src/constants/lucideIcons.ts`.
final Map<String, IconData> categoryLucideIcons = {
  'wallet': LucideIcons.wallet,
  'credit-card': LucideIcons.credit_card,
  'banknote': LucideIcons.banknote,
  'piggy-bank': LucideIcons.piggy_bank,
  'chart-pie': LucideIcons.chart_pie,
  'target': LucideIcons.target,
  'briefcase': LucideIcons.briefcase,
  'landmark': LucideIcons.landmark,
  'trending-up': LucideIcons.trending_up,
  'trending-down': LucideIcons.trending_down,
  'receipt': LucideIcons.receipt,
  'dollar-sign': LucideIcons.dollar_sign,
  'euro': LucideIcons.euro,
  'pound-sterling': LucideIcons.pound_sterling,
  'bitcoin': LucideIcons.bitcoin,
  'shopping-bag': LucideIcons.shopping_bag,
  'shopping-cart': LucideIcons.shopping_cart,
  'store': LucideIcons.store,
  'shirt': LucideIcons.shirt,
  'gift': LucideIcons.gift,
  'gem': LucideIcons.gem,
  'utensils': LucideIcons.utensils,
  'coffee': LucideIcons.coffee,
  'cake': LucideIcons.cake,
  'car': LucideIcons.car,
  'bus': LucideIcons.bus,
  'train': LucideIcons.train_front,
  'plane': LucideIcons.plane,
  'bike': LucideIcons.bike,
  'ship': LucideIcons.ship,
  'fuel': LucideIcons.fuel,
  'home': LucideIcons.house,
  'building': LucideIcons.building,
  'zap': LucideIcons.zap,
  'droplet': LucideIcons.droplet,
  'flame': LucideIcons.flame,
  'wrench': LucideIcons.wrench,
  'gamepad': LucideIcons.gamepad_2,
  'play': LucideIcons.play,
  'music': LucideIcons.music,
  'ticket': LucideIcons.ticket,
  'clapperboard': LucideIcons.clapperboard,
  'tv': LucideIcons.tv,
  'heart': LucideIcons.heart,
  'activity': LucideIcons.activity,
  'dumbbell': LucideIcons.dumbbell,
  'stethoscope': LucideIcons.stethoscope,
  'pill': LucideIcons.pill,
  'graduation-cap': LucideIcons.graduation_cap,
  'book': LucideIcons.book,
  'smartphone': LucideIcons.smartphone,
  'laptop': LucideIcons.laptop,
  'monitor': LucideIcons.monitor,
  'camera': LucideIcons.camera,
  'watch': LucideIcons.watch,
  'headset': LucideIcons.headphones,
  'dog': LucideIcons.dog,
  'cat': LucideIcons.cat,
  'award': LucideIcons.award,
  'key': LucideIcons.key,
  'shield': LucideIcons.shield,
  'repeat': LucideIcons.repeat,
  'more-horizontal': LucideIcons.ellipsis,
};

final Map<String, IconData> _categoryLucideIcons = categoryLucideIcons;
final List<String> categoryLucideIconKeys = categoryLucideIcons.keys.toList();

/// Shared transaction palette and icon rules mirrored from the web history UI.
abstract final class TransactionVisuals {
  static const Color income = Color(0xFF059669);
  static const Color expense = Color(0xFFDC2626);
  static const Color transfer = Color(0xFF2563EB);
  static const Color investment = Color(0xFF9333EA);
  static const Color saving = Color(0xFF4F46E5);
  static const Color neutral = Color(0xFF64748B);

  static bool isInflow(String type) => const {
        'income',
        'borrowing',
        'loan_repayment_received',
        'interest_income',
        'debt_collection',
      }.contains(type.toLowerCase());

  static bool isOutflow(String type) => const {
        'expense',
        'debt_repayment',
        'lending',
        'saving',
        'investment',
        'credit_card_payment',
        'interest_expense',
        'repayment',
      }.contains(type.toLowerCase());

  static bool isTransfer(String type) => const {
        'transfer',
        'credit_card_payment',
      }.contains(type.toLowerCase());

  static Color colorFor(String type, {String? categoryColor}) {
    final normalized = type.toLowerCase();
    if (isTransfer(normalized)) return transfer;
    if (normalized == 'investment') return investment;
    if (normalized == 'saving') return saving;
    if (isInflow(normalized)) return income;
    if (normalized == 'expense') return expense;
    if (isOutflow(normalized)) return expense;
    return neutral;
  }

  static Color backgroundFor(String type,
      {String? categoryColor, bool isDark = false}) {
    final base = iconColorFor(type, categoryColor: categoryColor);
    return base.withValues(alpha: isDark ? 0.20 : 0.12);
  }

  static Color iconColorFor(String type, {String? categoryColor}) {
    if (!isTransfer(type) && categoryColor?.trim().isNotEmpty == true) {
      return BankIconRegistry.parseThemeColor(categoryColor,
          fallback: colorFor(type));
    }
    return colorFor(type);
  }

  static String iconFor(String type, String? categoryIcon,
      {String? merchantId}) {
    if (isTransfer(type)) return 'repeat';
    return merchantId?.trim().isNotEmpty == true
        ? merchantId!
        : categoryIcon ?? '';
  }
}

class TransactionIconWidget extends StatelessWidget {
  final String type;
  final String? categoryIcon;
  final String? categoryName;
  final String? categoryColor;
  final String? merchantId;
  final double size;

  const TransactionIconWidget({
    super.key,
    required this.type,
    this.categoryIcon,
    this.categoryName,
    this.categoryColor,
    this.merchantId,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        TransactionVisuals.iconColorFor(type, categoryColor: categoryColor);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: TransactionVisuals.backgroundFor(type,
            categoryColor: categoryColor, isDark: isDark),
      ),
      child: Center(
        child: CategoryIconWidget(
          icon: TransactionVisuals.iconFor(type, categoryIcon,
              merchantId: merchantId),
          categoryName: categoryName,
          size: size,
          color: color,
        ),
      ),
    );
  }
}
