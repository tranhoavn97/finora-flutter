import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../state/theme_studio_controller.dart';
import 'premium_widgets.dart';
import '../utils/formatters.dart';
import '../../domain/finance/transaction_member.dart';
import '../../state/transaction_provider.dart';

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
    final rawLower = source.trim().toLowerCase();
    if (rawLower.contains('tiền mặt') ||
        rawLower.contains('tien mat') ||
        rawLower.contains('tiền') ||
        rawLower.contains('cash')) {
      return brands.firstWhere((b) => b.code == 'cash');
    }
    if (rawLower.contains('kỹ thương') || rawLower.contains('ky thuong')) {
      return brands.firstWhere((b) => b.code == 'tcb');
    }
    if (rawLower.contains('ngoại thương') || rawLower.contains('ngoai thuong')) {
      return brands.firstWhere((b) => b.code == 'vcb');
    }
    if (rawLower.contains('công thương') || rawLower.contains('cong thuong')) {
      return brands.firstWhere((b) => b.code == 'vtb');
    }
    if (rawLower.contains('quân đội') || rawLower.contains('quan doi')) {
      return brands.firstWhere((b) => b.code == 'mbbank');
    }
    if (rawLower.contains('thịnh vượng') || rawLower.contains('thinh vuong')) {
      return brands.firstWhere((b) => b.code == 'vpb');
    }
    if (rawLower.contains('tiên phong') || rawLower.contains('tien phong')) {
      return brands.firstWhere((b) => b.code == 'tpb');
    }

    var clean =
        source.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (clean.startsWith('bank')) clean = clean.substring(4);
    if (clean.startsWith('brand')) clean = clean.substring(5);

    if (clean.contains('momo')) {
      return brands.firstWhere((b) => b.code == 'momo');
    }
    if (clean.contains('zalo')) {
      return brands.firstWhere((b) => b.code == 'zalo');
    }
    if (clean.contains('shopee')) {
      return brands.firstWhere((b) => b.code == 'shopeepay');
    }
    if (clean.contains('viettel')) {
      return brands.firstWhere((b) => b.code == 'viettelmoney');
    }
    if (clean.contains('vnpt')) {
      return brands.firstWhere((b) => b.code == 'vnptmoney');
    }
    if (clean.contains('vnpay')) {
      return brands.firstWhere((b) => b.code == 'vnpay');
    }
    if (clean.contains('tienmat') || clean.contains('cash')) {
      return brands.firstWhere((b) => b.code == 'cash');
    }

    if (clean == 'mb' || clean == 'mbbank' || clean.contains('mbbank')) {
      return brands.firstWhere((b) => b.code == 'mbbank');
    }
    if (clean == 'techcombank' ||
        clean == 'tcb' ||
        clean.contains('techcombank')) {
      return brands.firstWhere((b) => b.code == 'tcb');
    }
    if (clean == 'vietcombank' ||
        clean == 'vcb' ||
        clean.contains('vietcombank')) {
      return brands.firstWhere((b) => b.code == 'vcb');
    }
    if (clean == 'vietinbank' ||
        clean == 'ctg' ||
        clean == 'vtb' ||
        clean.contains('vietinbank')) {
      return brands.firstWhere((b) => b.code == 'vtb');
    }
    if (clean == 'vpbank' || clean == 'vpb' || clean.contains('vpbank')) {
      return brands.firstWhere((b) => b.code == 'vpb');
    }
    if (clean == 'tpbank' || clean == 'tpb' || clean.contains('tpbank')) {
      return brands.firstWhere((b) => b.code == 'tpb');
    }
    if (clean == 'sacombank' || clean == 'stb' || clean.contains('sacombank')) {
      return brands.firstWhere((b) => b.code == 'stb');
    }
    if (clean == 'bidv' || clean.contains('bidv')) {
      return brands.firstWhere((b) => b.code == 'bidv');
    }
    if (clean == 'acb' || clean.contains('acb')) {
      return brands.firstWhere((b) => b.code == 'acb');
    }
    if (clean == 'agribank' || clean.contains('agribank') || clean == 'agri') {
      return brands.firstWhere((b) => b.code == 'agri');
    }
    if (clean == 'shb' || clean.contains('shb')) {
      return brands.firstWhere((b) => b.code == 'shb');
    }
    if (clean == 'hdb' || clean == 'hdbank' || clean.contains('hdbank')) {
      return brands.firstWhere((b) => b.code == 'hdb');
    }
    if (clean == 'vib' || clean.contains('vib')) {
      return brands.firstWhere((b) => b.code == 'vib');
    }
    if (clean == 'msb' || clean.contains('msb')) {
      return brands.firstWhere((b) => b.code == 'msb');
    }
    if (clean == 'ocb' || clean.contains('ocb')) {
      return brands.firstWhere((b) => b.code == 'ocb');
    }
    if (clean == 'sea' || clean == 'seabank' || clean.contains('seabank')) {
      return brands.firstWhere((b) => b.code == 'sea');
    }
    if (clean == 'eib' || clean == 'eximbank' || clean.contains('eximbank')) {
      return brands.firstWhere((b) => b.code == 'eib');
    }
    if (clean == 'cake' || clean.contains('cake')) {
      return brands.firstWhere((b) => b.code == 'cake');
    }
    if (clean == 'timo' || clean.contains('timo')) {
      return brands.firstWhere((b) => b.code == 'timo');
    }

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
    if (raw.startsWith('data:image')) {
      try {
        final commaIdx = raw.indexOf(',');
        final base64Str = commaIdx != -1 ? raw.substring(commaIdx + 1) : raw;
        final bytes = base64Decode(base64Str);
        return SizedBox(
          width: size,
          height: size,
          child: ClipOval(
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.image_not_supported_outlined,
                size: size * 0.56,
                color: color,
              ),
            ),
          ),
        );
      } catch (_) {}
    }
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
    final assetPath = raw.contains('assets/')
        ? raw.substring(raw.indexOf('assets/'))
        : (CategoryIconHelper.getAssetPath(icon) ??
            (categoryName != null
                ? CategoryIconHelper.getAssetPath(categoryName)
                : (BankIconRegistry.resolve(icon, bankName: categoryName).code != 'cash'
                    ? BankIconRegistry.resolve(icon, bankName: categoryName).assetPath
                    : null)));
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

    final cleanKey =
        raw.toLowerCase().replaceAll('_', '-').replaceAll(' ', '-').trim();
    final iconData =
        _categoryLucideIcons[cleanKey] ?? _categoryLucideIcons[raw.toLowerCase()];
    if (iconData != null) {
      return Icon(iconData, size: size * 0.62, color: color);
    }

    // Direct emoji fallback mapping to modern Lucide vectors
    const emojiLucideMap = <String, IconData>{
      '🤝': LucideIcons.handshake,
      '🪙': LucideIcons.coins,
      '🫱🪙': LucideIcons.hand_coins,
      '📈': LucideIcons.trending_up,
      '📉': LucideIcons.trending_down,
      '🧾': LucideIcons.receipt,
      '💳': LucideIcons.credit_card,
      '💵': LucideIcons.banknote,
      '🐷': LucideIcons.piggy_bank,
      '🔄': LucideIcons.repeat,
      '⇄': LucideIcons.arrow_left_right,
      '🛍️': LucideIcons.shopping_bag,
      '🛒': LucideIcons.shopping_cart,
      '🏪': LucideIcons.store,
      '☕': LucideIcons.coffee,
      '🍜': LucideIcons.utensils,
      '🚗': LucideIcons.car,
      '🏠': LucideIcons.house,
      '🎮': LucideIcons.gamepad_2,
      '❤️': LucideIcons.heart,
      '🎓': LucideIcons.graduation_cap,
      '✈️': LucideIcons.plane,
      '⚡': LucideIcons.zap,
      '💊': LucideIcons.pill,
      '🎁': LucideIcons.gift,
      '🛡️': LucideIcons.shield,
      '🏦': LucideIcons.landmark,
      '💼': LucideIcons.briefcase,
      '📊': LucideIcons.chart_pie,
      '🎯': LucideIcons.target,
    };
    final directVector = emojiLucideMap[raw];
    if (directVector != null) {
      return Icon(directVector, size: size * 0.62, color: color);
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
    final isPhoto = CategoryIconHelper.isPhoto(icon, categoryName) ||
        (icon != null &&
            BankIconRegistry.resolve(icon, bankName: categoryName).code != 'cash' &&
            BankIconRegistry.resolve(icon, bankName: categoryName).assetPath != null) ||
        (categoryName != null &&
            BankIconRegistry.resolve(categoryName).code != 'cash' &&
            BankIconRegistry.resolve(categoryName).assetPath != null);

    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final decoration = isPhoto
        ? BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.08),
                blurRadius: 6,
                offset: const Offset(0, 1.5),
              ),
            ],
          )
        : (studio?.getCategoryIconDecoration(
                isDark: isDark, categoryColor: tint, size: size) ??
            BoxDecoration(
              shape: BoxShape.circle,
              color: tint.withValues(alpha: isDark ? 0.22 : 0.14),
              border: Border.all(
                color: tint.withValues(alpha: isDark ? 0.38 : 0.28),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: tint.withValues(alpha: isDark ? 0.25 : 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ));
    final iconColor = studio != null
        ? studio.resolveIconGlyphColor(tint, isDark)
        : (isDark ? tint : Color.lerp(tint, Colors.black, 0.15)!);

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: decoration,
      child: Center(
        child: CategoryIconWidget(
          icon: icon,
          categoryName: categoryName,
          size: isPhoto ? size : size * 0.65,
          color: iconColor,
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
  'cross': LucideIcons.cross,
  'tag': LucideIcons.tag,
  'hospital': LucideIcons.hospital,
  'heart-pulse': LucideIcons.heart_pulse,
  'badge-percent': LucideIcons.badge_percent,
  'bank': LucideIcons.landmark,
  'brand-grab': LucideIcons.car,
  'grab': LucideIcons.car,
  'brand-tiki': LucideIcons.shopping_bag,
  'tiki': LucideIcons.shopping_bag,
  'brand-shopee': LucideIcons.shopping_bag,
  'brand-lazada': LucideIcons.shopping_bag,
  'brand-tiktok': LucideIcons.smartphone,
  'bank-winmart': LucideIcons.store,
  'handshake': LucideIcons.handshake,
  'hand-coins': LucideIcons.hand_coins,
  'hand_coins': LucideIcons.hand_coins,
  'handcoins': LucideIcons.hand_coins,
  'coins': LucideIcons.coins,
  'line-chart': LucideIcons.trending_up,
  'line_chart': LucideIcons.trending_up,
  'linechart': LucideIcons.trending_up,
  'arrow-left-right': LucideIcons.arrow_left_right,
  'trending_up': LucideIcons.trending_up,
  'trendingup': LucideIcons.trending_up,
  'trending_down': LucideIcons.trending_down,
  'trendingdown': LucideIcons.trending_down,
  'credit_card': LucideIcons.credit_card,
  'creditcard': LucideIcons.credit_card,
  'piggy_bank': LucideIcons.piggy_bank,
  'piggybank': LucideIcons.piggy_bank,
  'chart_pie': LucideIcons.chart_pie,
  'chartpie': LucideIcons.chart_pie,
  'dollar_sign': LucideIcons.dollar_sign,
  'dollarsign': LucideIcons.dollar_sign,
  'shopping_bag': LucideIcons.shopping_bag,
  'shoppingbag': LucideIcons.shopping_bag,
  'shopping_cart': LucideIcons.shopping_cart,
  'shoppingcart': LucideIcons.shopping_cart,
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
        'borrow',
        'debt',
        'loan_repayment_received',
        'interest_income',
        'debt_collection',
      }.contains(type.toLowerCase());

  static bool isOutflow(String type) => const {
        'expense',
        'debt_repayment',
        'repayment',
        'debt_repayment_paid',
        'lending',
        'loan',
        'lent',
        'saving',
        'savings',
        'investment',
        'invest',
        'credit_card_payment',
        'interest_expense',
      }.contains(type.toLowerCase());

  static bool isTransfer(String type) => const {
        'transfer',
        'credit_card_payment',
      }.contains(type.toLowerCase());

  static Color colorFor(String type, {String? categoryColor}) {
    final normalized = type.toLowerCase();
    if (normalized == 'lending' || normalized == 'loan' || normalized == 'lent') {
      return const Color(0xFFE11D48); // Cho vay
    }
    if (normalized == 'borrowing' || normalized == 'borrow' || normalized == 'debt') {
      return const Color(0xFF0284C7); // Vay nợ
    }
    if (normalized == 'debt_repayment' || normalized == 'repayment' || normalized == 'debt_repayment_paid') {
      return const Color(0xFFD97706); // Trả nợ
    }
    if (normalized == 'loan_repayment_received' || normalized == 'debt_collection') {
      return const Color(0xFF10B981); // Thu nợ
    }
    if (isTransfer(normalized)) return transfer;
    if (normalized == 'investment' || normalized == 'invest') return investment;
    if (normalized == 'saving' || normalized == 'savings') return saving;
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
    final tLower = type.toLowerCase();
    if (tLower == 'lending' || tLower == 'loan' || tLower == 'lent') return const Color(0xFFE11D48);
    if (tLower == 'borrowing' || tLower == 'borrow' || tLower == 'debt') return const Color(0xFF0284C7);
    if (tLower == 'debt_repayment' || tLower == 'repayment' || tLower == 'debt_repayment_paid') return const Color(0xFFD97706);
    if (tLower == 'loan_repayment_received' || tLower == 'debt_collection') return const Color(0xFF10B981);
    if (tLower == 'investment' || tLower == 'invest') return const Color(0xFF7C3AED);
    if (tLower == 'saving' || tLower == 'savings') return const Color(0xFF4F46E5);
    if (tLower == 'credit_card_payment') return const Color(0xFFD97706);
    if (isTransfer(tLower)) return const Color(0xFF0284C7);

    if (categoryColor?.trim().isNotEmpty == true) {
      return BankIconRegistry.parseThemeColor(categoryColor,
          fallback: colorFor(type));
    }
    return colorFor(type);
  }

  static String iconFor(String type, String? categoryIcon,
      {String? merchantId,
      String? categoryName,
      String? merchantIcon,
      String? merchantName}) {
    final tLower = type.trim().toLowerCase();
    if (isTransfer(tLower)) return 'repeat';
    if (tLower == 'investment' || tLower == 'invest') return 'trending-up';
    if (tLower == 'credit_card_payment') return 'credit-card';
    if (tLower == 'lending' || tLower == 'loan' || tLower == 'lent') return 'handshake';
    if (tLower == 'borrowing' || tLower == 'borrow' || tLower == 'debt') return 'hand-coins';
    if (tLower == 'debt_repayment' || tLower == 'repayment' || tLower == 'debt_repayment_paid') return 'receipt';
    if (tLower == 'loan_repayment_received' || tLower == 'debt_collection') return 'coins';
    if (tLower == 'saving' || tLower == 'savings') return 'piggy-bank';

    // 1. Direct merchant icon (URL, base64, asset path or icon code)
    if (merchantIcon?.trim().isNotEmpty == true) {
      return merchantIcon!.trim();
    }

    // 2. Tra cứu avatar nơi mua theo merchantId hoặc merchantName (LUÔN ƯU TIÊN NƠI MUA KHI CÓ)
    final mId = merchantId?.trim() ?? '';
    final mName = merchantName?.trim() ?? '';
    if (mId.isNotEmpty || mName.isNotEmpty) {
      // 2.1 Direct network image avatar or base64
      if (mId.startsWith('http://') ||
          mId.startsWith('https://') ||
          mId.startsWith('data:image') ||
          mId.startsWith('//') ||
          mId.contains('/storage/')) {
        return mId;
      }
      // 2.2 Direct asset path
      if (mId.startsWith('assets/')) {
        return mId;
      }

      // 2.3 Asset mapping từ CategoryIconHelper
      final assetFromId = CategoryIconHelper.getAssetPath(mId);
      if (assetFromId != null) return assetFromId;
      final assetFromName = CategoryIconHelper.getAssetPath(mName);
      if (assetFromName != null) return assetFromName;

      // 2.4 Khớp nhận diện thương hiệu phổ biến
      final searchTarget = '$mName $mId'.toLowerCase();
      if (searchTarget.contains('shopee')) return 'assets/banks/shopee.jpg';
      if (searchTarget.contains('tiktok')) return 'assets/banks/tiktok.jpg';
      if (searchTarget.contains('lazada')) return 'assets/banks/lazada.jpg';
      if (searchTarget.contains('winmart') || searchTarget.contains('vinmart')) {
        return 'assets/banks/winmart.png';
      }
      if (searchTarget.contains('tiki')) return 'shopping-bag';
      if (searchTarget.contains('grab')) return 'car';
      if (searchTarget.contains('highlands') ||
          searchTarget.contains('phuclong') ||
          searchTarget.contains('starbucks') ||
          searchTarget.contains('coffee') ||
          searchTarget.contains('cafe')) {
        return 'coffee';
      }
      if (searchTarget.contains('circle k') ||
          searchTarget.contains('familymart') ||
          searchTarget.contains('7-eleven') ||
          searchTarget.contains('gs25') ||
          searchTarget.contains('mart')) {
        return 'store';
      }
      if (searchTarget.contains('bach hoa xanh') ||
          searchTarget.contains('coopmart') ||
          searchTarget.contains('big c') ||
          searchTarget.contains('go!')) {
        return 'shopping-cart';
      }
      if (searchTarget.contains('momo')) return 'assets/banks/momo.jpg';
      if (searchTarget.contains('zalo')) return 'assets/banks/zalo.jpg';
      if (searchTarget.contains('viettel')) return 'assets/banks/viettelmoney.jpg';
      if (searchTarget.contains('vnpay')) return 'assets/banks/vnpay.jpg';

      if (mId.isNotEmpty && _categoryLucideIcons.containsKey(mId.toLowerCase())) {
        return mId;
      }

      // Có nơi mua nhưng chưa có icon đặc thù -> biểu tượng Store
      return 'store';
    }

    // 3. Nếu không có nơi mua: Dùng categoryIcon của danh mục nếu có
    if (categoryIcon?.trim().isNotEmpty == true) {
      return categoryIcon!.trim();
    }

    // 5. Keyword heuristic fallback by category name or note
    final catLower = (categoryName ?? '').toLowerCase();
    if (catLower.contains('cho vay') || catLower.contains('lending')) return 'handshake';
    if (catLower.contains('vay') || catLower.contains('mượn') || catLower.contains('borrow')) return 'hand-coins';
    if (catLower.contains('trả nợ')) return 'receipt';
    if (catLower.contains('thu nợ')) return 'coins';
    if (catLower.contains('đầu tư') || catLower.contains('cổ phiếu') || catLower.contains('chứng khoán') || catLower.contains('crypto')) return 'trending-up';
    if (catLower.contains('tiết kiệm') || catLower.contains('sổ tiết kiệm')) return 'piggy-bank';
    if (catLower.contains('chuyển khoản')) return 'repeat';
    if (catLower.contains('trả thẻ') || catLower.contains('thẻ tín dụng')) return 'credit-card';
    if (catLower.contains('lương') || catLower.contains('thu nhập')) return 'banknote';
    if (catLower.contains('thưởng')) return 'gift';

    if (isInflow(tLower)) return 'banknote';
    return 'receipt';
  }
}

class TransactionIconWidget extends StatelessWidget {
  final String type;
  final String? categoryIcon;
  final String? categoryName;
  final String? categoryColor;
  final String? merchantId;
  final String? merchantName;
  final String? merchantIcon;
  final double size;
  final BankBrand? bankBrand;
  final String? bankCode;
  final String? bankName;
  final bool showBankBadge;
  final bool showBorder;

  const TransactionIconWidget({
    super.key,
    required this.type,
    this.categoryIcon,
    this.categoryName,
    this.categoryColor,
    this.merchantId,
    this.merchantName,
    this.merchantIcon,
    this.size = 42,
    this.bankBrand,
    this.bankCode,
    this.bankName,
    this.showBankBadge = false,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Tự động tìm kiếm avatar & màu sắc của Nơi Mua trong TransactionProvider
    final txProvider = Provider.of<TransactionProvider?>(context, listen: false);
    String? resolvedMerchantIcon = merchantIcon;
    Color? resolvedMerchantColor;

    if (txProvider != null &&
        ((merchantId?.trim().isNotEmpty == true) ||
            (merchantName?.trim().isNotEmpty == true))) {
      final mIdLower = merchantId?.trim().toLowerCase();
      final mNameLower = merchantName?.trim().toLowerCase();
      for (final c in txProvider.categories) {
        if (c.categoryGroup == 'merchant') {
          final idMatch = mIdLower != null && c.id.toLowerCase() == mIdLower;
          final nameMatch = mNameLower != null && c.name.trim().toLowerCase() == mNameLower;
          if (idMatch || nameMatch) {
            if (resolvedMerchantIcon == null || resolvedMerchantIcon.isEmpty) {
              resolvedMerchantIcon = c.icon;
            }
            if (c.color != null && c.color!.trim().isNotEmpty) {
              resolvedMerchantColor = BankIconRegistry.parseThemeColor(c.color);
            }
            break;
          }
        }
      }
    }

    final effectiveColor = resolvedMerchantColor ??
        TransactionVisuals.iconColorFor(type, categoryColor: categoryColor);

    final resolvedIconStr = TransactionVisuals.iconFor(
      type,
      categoryIcon,
      merchantId: merchantId,
      categoryName: categoryName,
      merchantIcon: resolvedMerchantIcon,
      merchantName: merchantName,
    );

    final isPhoto = CategoryIconHelper.isPhoto(resolvedIconStr, categoryName, merchantName) ||
        (BankIconRegistry.resolve(resolvedIconStr, bankName: categoryName ?? merchantName).code != 'cash' &&
            BankIconRegistry.resolve(resolvedIconStr, bankName: categoryName ?? merchantName).assetPath != null);

    final scale = (studio?.iconScale ?? 1.0).clamp(0.75, 1.25);
    final effectiveSize = size * scale;

    final dec = isPhoto
        ? const BoxDecoration(shape: BoxShape.circle)
        : (!showBorder
            ? BoxDecoration(
                shape: BoxShape.circle,
                color: effectiveColor.withValues(alpha: isDark ? 0.22 : 0.14),
              )
            : (studio != null
                ? studio.getIconContainerDecoration(
                    color: effectiveColor,
                    isDark: isDark,
                    size: effectiveSize,
                  )
                : BoxDecoration(
                    shape: BoxShape.circle,
                    color: TransactionVisuals.backgroundFor(type,
                        categoryColor: categoryColor, isDark: isDark),
                  )));

    final effectiveIconColor = studio != null
        ? studio.resolveIconGlyphColor(effectiveColor, isDark)
        : (isDark ? effectiveColor : Color.lerp(effectiveColor, Colors.black, 0.15)!);

    final baseIcon = Container(
      width: effectiveSize,
      height: effectiveSize,
      clipBehavior: Clip.antiAlias,
      decoration: dec,
      child: Center(
        child: CategoryIconWidget(
          icon: resolvedIconStr,
          categoryName: categoryName ?? merchantName,
          size: isPhoto ? effectiveSize : effectiveSize * 0.58,
          color: effectiveIconColor,
        ),
      ),
    );

    final hasBankInfo = showBankBadge ||
        bankBrand != null ||
        (bankCode != null && bankCode!.isNotEmpty) ||
        (bankName != null && bankName!.isNotEmpty);

    if (!hasBankInfo) {
      return baseIcon;
    }

    final brand =
        bankBrand ?? BankIconRegistry.resolve(bankCode, bankName: bankName);
    final badgeSize = (size * 0.44).clamp(16.0, 22.0);
    final iconSize = (badgeSize * 0.52).clamp(8.0, 11.5);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        baseIcon,
        Positioned(
          bottom: -1.5,
          right: -1.5,
          child: Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border.all(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
                  blurRadius: 3.5,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: brand.assetPath != null
                  ? Image.asset(brand.assetPath!, fit: BoxFit.cover)
                  : (brand.code == 'cash'
                      ? Container(
                          color: const Color(0xFF10B981),
                          child: Icon(Icons.payments_rounded,
                              size: iconSize, color: Colors.white),
                        )
                      : Container(
                          color: brand.color,
                          child: Icon(Icons.account_balance_rounded,
                              size: iconSize, color: Colors.white),
                        )),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tag người chi tiêu (Vợ / Chồng / Gia đình / AI) độ tương phản cao, siêu sắc nét, dễ nhìn
class SpenderBadgeWidget extends StatelessWidget {
  final TransactionMember? member;
  final String? tag;
  final String? ownerName;
  final bool isDark;
  final double fontScale;
  final String? fontFamily;
  final bool compact;

  const SpenderBadgeWidget({
    super.key,
    this.member,
    this.tag,
    this.ownerName,
    required this.isDark,
    this.fontScale = 1.0,
    this.fontFamily,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final tLower = (tag ?? '').trim().toLowerCase();
    final oLower = (ownerName ?? '').trim().toLowerCase();

    final resolved = member ?? resolveMemberFields([tag, ownerName]);
    final isWife = resolved == TransactionMember.wife;
    final isAi = member == null &&
        resolved == TransactionMember.unknown &&
        (tLower == 'ai' || tLower == 'finora ai' || oLower == 'ai');
    final isShared = resolved == TransactionMember.joint;

    final String label;
    final IconData icon;
    final Color badgeBg;
    final Color badgeBorder;
    final Color textColor;
    final Color iconColor;

    if (isWife) {
      label = 'Vợ';
      icon = Icons.favorite_rounded;
      badgeBg = const Color(0xFFFF2D55).withValues(alpha: isDark ? 0.25 : 0.14);
      badgeBorder =
          const Color(0xFFFF2D55).withValues(alpha: isDark ? 0.65 : 0.45);
      textColor = isDark ? const Color(0xFFF472B6) : const Color(0xFFE11D48);
      iconColor = textColor;
    } else if (isAi) {
      label = 'AI';
      icon = Icons.auto_awesome_rounded;
      badgeBg = const Color(0xFF6366F1).withValues(alpha: isDark ? 0.25 : 0.14);
      badgeBorder =
          const Color(0xFF6366F1).withValues(alpha: isDark ? 0.65 : 0.45);
      textColor = isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5);
      iconColor = textColor;
    } else if (isShared) {
      label = 'Chung';
      icon = Icons.groups_rounded;
      badgeBg = const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.14);
      badgeBorder =
          const Color(0xFF10B981).withValues(alpha: isDark ? 0.65 : 0.45);
      textColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
      iconColor = textColor;
    } else if (resolved == TransactionMember.husband) {
      label = 'Chồng';
      icon = Icons.person_rounded;
      badgeBg = const Color(0xFF007AFF).withValues(alpha: isDark ? 0.25 : 0.14);
      badgeBorder =
          const Color(0xFF007AFF).withValues(alpha: isDark ? 0.65 : 0.45);
      textColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF005FEA);
      iconColor = textColor;
    } else {
      label = TransactionMember.unknown.label;
      icon = Icons.person_outline_rounded;
      badgeBg = const Color(0xFF64748B).withValues(alpha: isDark ? 0.25 : 0.12);
      badgeBorder = const Color(0xFF64748B).withValues(alpha: 0.4);
      textColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
      iconColor = textColor;
    }

    final double padH = compact ? 6.5 : 8.5;
    final double padV = compact ? 2.5 : 4.0;
    final double fs = (compact ? 10.5 : 11.5) * fontScale;
    final double iconSz = compact ? 11.0 : 12.5;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: badgeBorder, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: iconSz, color: iconColor),
          const SizedBox(width: 4.0),
          Flexible(
              child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fs,
              fontWeight: FontWeight.w800,
              fontFamily: fontFamily,
              color: textColor,
              letterSpacing: -0.1,
              height: 1.1,
            ),
          )),
        ],
      ),
    );
  }
}
