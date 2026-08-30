import 'package:flutter/material.dart';
import 'premium_widgets.dart';

@immutable
class BankBrand {
  final String code;
  final String name;
  final String shortName;
  final String? assetPath;
  final Color color;

  const BankBrand(
      {required this.code,
      required this.name,
      required this.shortName,
      required this.color,
      this.assetPath});

  List<Color> get cardGradient => [
        Color.lerp(color, Colors.black, .34)!,
        color,
        Color.lerp(color, Colors.white, .18)!,
      ];
}

/// Registry mapping bank short codes to their local asset paths.
class BankIconRegistry {
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

  /// Mirrors `src/constants/banks.ts`: web and Flutter use one bank identity.
  static const List<BankBrand> brands = [
    BankBrand(
        code: 'vcb',
        name: 'Ngân hàng Ngoại thương Việt Nam',
        shortName: 'Vietcombank',
        assetPath: 'assets/banks/vcb.webp',
        color: Color(0xFF61A928)),
    BankBrand(
        code: 'mbbank',
        name: 'Ngân hàng Quân đội',
        shortName: 'MB BANK',
        assetPath: 'assets/banks/mb.webp',
        color: Color(0xFF141ED2)),
    BankBrand(
        code: 'tcb',
        name: 'Ngân hàng Kỹ Thương',
        shortName: 'Techcombank',
        assetPath: 'assets/banks/tcb.webp',
        color: Color(0xFFEA0029)),
    BankBrand(
        code: 'bidv',
        name: 'Ngân hàng Đầu tư và Phát triển VN',
        shortName: 'BIDV',
        assetPath: 'assets/banks/bidv.png',
        color: Color(0xFF0F6F74)),
    BankBrand(
        code: 'vtb',
        name: 'Ngân hàng Công Thương Việt Nam',
        shortName: 'VietinBank',
        assetPath: 'assets/banks/ctg.png',
        color: Color(0xFF00558F)),
    BankBrand(
        code: 'acb',
        name: 'Ngân hàng Á Châu',
        shortName: 'ACB',
        assetPath: 'assets/banks/acb.webp',
        color: Color(0xFF005EAF)),
    BankBrand(
        code: 'vpb',
        name: 'Ngân hàng Việt Nam Thịnh Vượng',
        shortName: 'VPBank',
        assetPath: 'assets/banks/vpb.png',
        color: Color(0xFF00AF5A)),
    BankBrand(
        code: 'tpb',
        name: 'Ngân hàng Tiên Phong',
        shortName: 'TPBank',
        assetPath: 'assets/banks/tpb.webp',
        color: Color(0xFF8E2B88)),
    BankBrand(
        code: 'stb',
        name: 'Ngân hàng Sài Gòn Thương Tín',
        shortName: 'Sacombank',
        assetPath: 'assets/banks/stb.webp',
        color: Color(0xFF00539E)),
    BankBrand(
        code: 'shb',
        name: 'Ngân hàng Sài Gòn - Hà Nội',
        shortName: 'SHB',
        color: Color(0xFFF36F21)),
    BankBrand(
        code: 'hdb',
        name: 'Ngân hàng Phát triển TP.HCM',
        shortName: 'HDBank',
        assetPath: 'assets/banks/hdb.png',
        color: Color(0xFFED1B24)),
    BankBrand(
        code: 'vib',
        name: 'Ngân hàng Quốc Tế',
        shortName: 'VIB',
        assetPath: 'assets/banks/vib.webp',
        color: Color(0xFF005A9C)),
    BankBrand(
        code: 'msb',
        name: 'Ngân hàng Hàng Hải',
        shortName: 'MSB',
        assetPath: 'assets/banks/msb.png',
        color: Color(0xFFF47D22)),
    BankBrand(
        code: 'ocb',
        name: 'Ngân hàng Phương Đông',
        shortName: 'OCB',
        assetPath: 'assets/banks/ocb.png',
        color: Color(0xFF007A3E)),
    BankBrand(
        code: 'sea',
        name: 'Ngân hàng Đông Nam Á',
        shortName: 'SeABank',
        color: Color(0xFFE31837)),
    BankBrand(
        code: 'eib',
        name: 'Ngân hàng Xuất Nhập Khẩu',
        shortName: 'Eximbank',
        color: Color(0xFF005C9C)),
    BankBrand(
        code: 'agri',
        name: 'Ngân hàng Nông nghiệp',
        shortName: 'Agribank',
        color: Color(0xFFB3292C)),
    BankBrand(
        code: 'cake',
        name: 'Cake by VPBank',
        shortName: 'Cake',
        color: Color(0xFFF61F6E)),
    BankBrand(
        code: 'timo',
        name: 'Timo Digital Bank',
        shortName: 'Timo',
        assetPath: 'assets/banks/timo.webp',
        color: Color(0xFF5F2C82)),
    BankBrand(
        code: 'momo',
        name: 'Ví MoMo',
        shortName: 'MoMo',
        assetPath: 'assets/banks/momo.png',
        color: Color(0xFFA50064)),
    BankBrand(
        code: 'zalo',
        name: 'ZaloPay',
        shortName: 'ZaloPay',
        assetPath: 'assets/banks/zalopay.png',
        color: Color(0xFF0088FF)),
    BankBrand(
        code: 'vnpay',
        name: 'Ví VNPay',
        shortName: 'VNPay',
        color: Color(0xFFEC1C24)),
    BankBrand(
        code: 'cash',
        name: 'Tiền mặt',
        shortName: 'Cash',
        color: Color(0xFF10B981)),
  ];

  static const Map<String, String> _aliases = {
    'mb': 'mbbank',
    'techcombank': 'tcb',
    'vietcombank': 'vcb',
    'vietinbank': 'vtb',
    'ctg': 'vtb',
    'vpbank': 'vpb',
    'tpbank': 'tpb',
    'sacombank': 'stb',
    'zalopay': 'zalo',
  };

  static BankBrand resolve(String? codeOrName) {
    final raw = (codeOrName ?? '').trim().toLowerCase();
    final code = _aliases[raw] ?? raw;
    for (final bank in brands) {
      if (bank.code == code ||
          bank.name.toLowerCase().contains(raw) ||
          bank.shortName.toLowerCase() == raw) return bank;
    }
    return const BankBrand(
        code: 'bank',
        name: 'Ngân hàng',
        shortName: 'Ngân hàng',
        color: Color(0xFF3157D5));
  }

  static Color parseThemeColor(String? value, {Color? fallback}) {
    final hex = (value ?? '').replaceAll('#', '').trim();
    if (hex.length == 6 || hex.length == 8) {
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed != null)
        return Color(hex.length == 6 ? 0xFF000000 | parsed : parsed);
    }
    return fallback ?? const Color(0xFF3157D5);
  }

  /// Returns the asset path for a bank code, or null if not registered.
  static String? getAssetPath(String code) {
    final cleanCode = code.trim().toUpperCase();
    return _registry[cleanCode] ?? resolve(code).assetPath;
  }

  /// Returns a list of all registered bank codes.
  static List<String> get registeredCodes => _registry.keys.toList();
}

/// A circular icon for Vietnamese banks, mapping to BankIconAvatar.
class BankIcon extends StatelessWidget {
  final String? bankCode;
  final double size;

  const BankIcon({
    super.key,
    required this.bankCode,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return BankIconAvatar(
      bankCode: bankCode,
      size: size,
    );
  }
}
