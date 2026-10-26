import 'package:flutter/material.dart';
import 'premium_widgets.dart';

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
