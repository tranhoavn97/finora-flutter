import 'package:flutter/material.dart';
import 'premium_widgets.dart';

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
    BankBrand(code: 'vcb', name: 'Vietcombank', color: Color(0xFF61A928), assetPath: 'assets/banks/vcb.webp'),
    BankBrand(code: 'mbbank', name: 'MB Bank', color: Color(0xFF1B4FA0), assetPath: 'assets/banks/mb.webp'),
    BankBrand(code: 'tcb', name: 'Techcombank', color: Color(0xFFE51A24), assetPath: 'assets/banks/tcb.webp'),
    BankBrand(code: 'bidv', name: 'BIDV', color: Color(0xFF00685E), assetPath: 'assets/banks/bidv.png'),
    BankBrand(code: 'vtb', name: 'VietinBank', color: Color(0xFF005696), assetPath: 'assets/banks/ctg.png'),
    BankBrand(code: 'acb', name: 'ACB', color: Color(0xFF0F56B3), assetPath: 'assets/banks/acb.webp'),
    BankBrand(code: 'vpb', name: 'VPBank', color: Color(0xFF00904B), assetPath: 'assets/banks/vpb.png'),
    BankBrand(code: 'tpb', name: 'TPBank', color: Color(0xFF7A2082), assetPath: 'assets/banks/tpb.webp'),
    BankBrand(code: 'stb', name: 'Sacombank', color: Color(0xFF0058A8), assetPath: 'assets/banks/stb.webp'),
    BankBrand(code: 'shb', name: 'SHB', color: Color(0xFFF37023)),
    BankBrand(code: 'hdb', name: 'HDBank', color: Color(0xFFED1C24), assetPath: 'assets/banks/hdb.png'),
    BankBrand(code: 'vib', name: 'VIB', color: Color(0xFF005EA6), assetPath: 'assets/banks/vib.webp'),
    BankBrand(code: 'msb', name: 'MSB', color: Color(0xFFF37021), assetPath: 'assets/banks/msb.png'),
    BankBrand(code: 'ocb', name: 'OCB', color: Color(0xFF008D43), assetPath: 'assets/banks/ocb.png'),
    BankBrand(code: 'sea', name: 'SeABank', color: Color(0xFFE21836)),
    BankBrand(code: 'eib', name: 'Eximbank', color: Color(0xFF0067AC)),
    BankBrand(code: 'agri', name: 'Agribank', color: Color(0xFF8B1B20)),
    BankBrand(code: 'cake', name: 'CAKE by VPBank', color: Color(0xFFFF424E)),
    BankBrand(code: 'timo', name: 'Timo Digital Bank', color: Color(0xFF5B36F2), assetPath: 'assets/banks/timo.webp'),
    BankBrand(code: 'momo', name: 'MoMo', color: Color(0xFFA50064), assetPath: 'assets/banks/momo.png'),
    BankBrand(code: 'zalo', name: 'ZaloPay', color: Color(0xFF0088FF), assetPath: 'assets/banks/zalopay.png'),
    BankBrand(code: 'vnpay', name: 'VNPAY', color: Color(0xFF005BAA)),
    BankBrand(code: 'cash', name: 'Tiền mặt', color: Color(0xFF10B981)),
  ];

  static BankBrand resolve(String? code, {String? bankName}) {
    final source = (code?.trim().isNotEmpty == true ? code : bankName);
    if (source == null || source.trim().isEmpty) {
      return brands.firstWhere((b) => b.code == 'cash');
    }
    final clean = source.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (clean == 'mb' || clean == 'mbbank') return brands.firstWhere((b) => b.code == 'mbbank');
    if (clean == 'techcombank' || clean == 'tcb') return brands.firstWhere((b) => b.code == 'tcb');
    if (clean == 'zalopay' || clean == 'zalo') return brands.firstWhere((b) => b.code == 'zalo');
    if (clean == 'vietcombank' || clean == 'vcb') return brands.firstWhere((b) => b.code == 'vcb');
    if (clean == 'vietinbank' || clean == 'ctg' || clean == 'vtb') return brands.firstWhere((b) => b.code == 'vtb');
    if (clean == 'vpbank' || clean == 'vpb') return brands.firstWhere((b) => b.code == 'vpb');
    if (clean == 'tpbank' || clean == 'tpb') return brands.firstWhere((b) => b.code == 'tpb');
    if (clean == 'sacombank' || clean == 'stb') return brands.firstWhere((b) => b.code == 'stb');
    return brands.firstWhere(
      (b) =>
          b.code.replaceAll(RegExp(r'[^a-z0-9]'), '') == clean ||
          b.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') == clean,
      orElse: () => brands.firstWhere((b) => b.code == 'cash'),
    );
  }

  static Color parseThemeColor(String? hex, {Color fallback = const Color(0xFF10B981)}) {
    if (hex == null) return fallback;
    var clean = hex.trim().replaceFirst('#', '');
    if (clean.length == 6) clean = 'FF$clean';
    if (clean.length != 8) return fallback;
    final value = int.tryParse(clean, radix: 16);
    if (value == null) return fallback;
    return Color(value);
  }

  static const Map<String, String> _registry = {
    'VCB': 'assets/banks/vcb.webp',
    'VIETCOMBANK': 'assets/banks/vcb.webp',
    'TCB': 'assets/banks/tcb.webp',
    'TECHCOMBANK': 'assets/banks/tcb.webp',
    'MB': 'assets/banks/mb.webp',
    'MBBANK': 'assets/banks/mb.webp',
    'VPB': 'assets/banks/vpb.png',
    'VPBANK': 'assets/banks/vpb.png',
    'ACB': 'assets/banks/acb.webp',
    'TPB': 'assets/banks/tpb.webp',
    'TPBANK': 'assets/banks/tpb.webp',
    'BIDV': 'assets/banks/bidv.png',
    'CTG': 'assets/banks/ctg.png',
    'VIETINBANK': 'assets/banks/ctg.png',
    'VTB': 'assets/banks/ctg.png',
    'VIB': 'assets/banks/vib.webp',
    'STB': 'assets/banks/stb.webp',
    'SACOMBANK': 'assets/banks/stb.webp',
    'HDB': 'assets/banks/hdb.png',
    'MSB': 'assets/banks/msb.png',
    'OCB': 'assets/banks/ocb.png',
    'TIMO': 'assets/banks/timo.webp',
    'MOMO': 'assets/banks/momo.png',
    'ZALOPAY': 'assets/banks/zalopay.png',
  };

  /// Returns the asset path for a bank code, or null if not registered.
  static String? getAssetPath(String code) {
    final cleanCode = code.trim().toUpperCase();
    return _registry[cleanCode];
  }

  /// Returns a list of all registered bank codes.
  static List<String> get registeredCodes => _registry.keys.toList();
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
