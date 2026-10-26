import '../../data/models/vietqr_data.dart';

/// Bank Directory Item
class BankInfo {
  final String bin;
  final String name;
  final String shortName;
  final String logo;
  final String? androidPackage;
  final String? iosScheme;

  const BankInfo({
    required this.bin,
    required this.name,
    required this.shortName,
    required this.logo,
    this.androidPackage,
    this.iosScheme,
  });
}

/// Finora VietQR & Payment Parser
///
/// Fully decodes EMVCo Merchant-Presented QR codes (NAPAS 247 VietQR)
/// and extracts beneficiary account, bank name, amount, and transfer notes.
class VietQrParser {
  VietQrParser._();

  /// Directory of Vietnamese Banks and E-Wallets
  static const Map<String, BankInfo> supportedBanks = {
    '970436': BankInfo(
      bin: '970436',
      name: 'Vietcombank',
      shortName: 'VCB',
      logo: 'assets/banks/vcb.png',
      androidPackage: 'com.VCB',
      iosScheme: 'vcb://',
    ),
    '970422': BankInfo(
      bin: '970422',
      name: 'MB Bank',
      shortName: 'MB',
      logo: 'assets/banks/mb.png',
      androidPackage: 'com.mbmobile',
      iosScheme: 'mbmobile://',
    ),
    '970407': BankInfo(
      bin: '970407',
      name: 'Techcombank',
      shortName: 'TCB',
      logo: 'assets/banks/tcb.png',
      androidPackage: 'vn.com.techcombank.bb.app',
      iosScheme: 'techcombank://',
    ),
    '970418': BankInfo(
      bin: '970418',
      name: 'BIDV',
      shortName: 'BIDV',
      logo: 'assets/banks/bidv.png',
      androidPackage: 'com.vnpay.bidv',
      iosScheme: 'bidv://',
    ),
    '970415': BankInfo(
      bin: '970415',
      name: 'VietinBank',
      shortName: 'CTG',
      logo: 'assets/banks/ctg.png',
      androidPackage: 'com.vietinbank.ipay',
      iosScheme: 'vietinbankipay://',
    ),
    '970423': BankInfo(
      bin: '970423',
      name: 'TPBank',
      shortName: 'TPB',
      logo: 'assets/banks/tpb.png',
      androidPackage: 'com.tpb.mb.gprsandroid',
      iosScheme: 'tpbank://',
    ),
    '970432': BankInfo(
      bin: '970432',
      name: 'VPBank',
      shortName: 'VPB',
      logo: 'assets/banks/vpb.png',
      androidPackage: 'com.vnpay.vpbankonline',
      iosScheme: 'vpbank://',
    ),
    '970416': BankInfo(
      bin: '970416',
      name: 'ACB',
      shortName: 'ACB',
      logo: 'assets/banks/acb.png',
      androidPackage: 'mobile.acb.com.vn',
      iosScheme: 'acbone://',
    ),
    '970403': BankInfo(
      bin: '970403',
      name: 'Sacombank',
      shortName: 'STB',
      logo: 'assets/banks/stb.png',
      androidPackage: 'com.vnpay.sacombank',
      iosScheme: 'sacombank://',
    ),
    '970405': BankInfo(
      bin: '970405',
      name: 'Agribank',
      shortName: 'VBA',
      logo: 'assets/banks/agri.jpg',
      androidPackage: 'com.vnpay.agribank',
      iosScheme: 'agribank://',
    ),
    '970441': BankInfo(
      bin: '970441',
      name: 'VIB',
      shortName: 'VIB',
      logo: 'assets/banks/vib.png',
      androidPackage: 'com.vib.vibmobile',
      iosScheme: 'vib://',
    ),
    '970437': BankInfo(
      bin: '970437',
      name: 'HDBank',
      shortName: 'HDB',
      logo: 'assets/banks/hdb.png',
      androidPackage: 'com.vnpay.hdbank',
      iosScheme: 'hdbank://',
    ),
    '970426': BankInfo(
      bin: '970426',
      name: 'MSB',
      shortName: 'MSB',
      logo: 'assets/banks/msb.png',
      androidPackage: 'com.vnpay.msb',
      iosScheme: 'msb://',
    ),
    '970448': BankInfo(
      bin: '970448',
      name: 'OCB',
      shortName: 'OCB',
      logo: 'assets/banks/ocb.png',
      androidPackage: 'com.ocb.omni',
      iosScheme: 'ocb://',
    ),
    '970443': BankInfo(
      bin: '970443',
      name: 'SHB',
      shortName: 'SHB',
      logo: 'assets/banks/shb.jpg',
      androidPackage: 'vn.shb.mbanking',
      iosScheme: 'shb://',
    ),
    '970431': BankInfo(
      bin: '970431',
      name: 'Eximbank',
      shortName: 'EIB',
      logo: 'assets/banks/eib.jpg',
      androidPackage: 'com.vnpay.eximbank',
      iosScheme: 'eximbank://',
    ),
    '970440': BankInfo(
      bin: '970440',
      name: 'SeABank',
      shortName: 'SeABank',
      logo: 'assets/banks/sea.jpg',
      androidPackage: 'vn.com.seabank.mb1',
      iosScheme: 'seabank://',
    ),
    '963388': BankInfo(
      bin: '963388',
      name: 'Timo',
      shortName: 'Timo',
      logo: 'assets/banks/timo.webp',
      androidPackage: 'timo.vn.bank',
      iosScheme: 'timo://',
    ),
    '546034': BankInfo(
      bin: '546034',
      name: 'Cake by VPBank',
      shortName: 'Cake',
      logo: 'assets/banks/cake.jpg',
      androidPackage: 'xyz.be.cake',
      iosScheme: 'cake://',
    ),
  };

  /// Popular E-Wallets
  static const List<BankInfo> popularWallets = [
    BankInfo(
      bin: 'MOMO',
      name: 'Ví MoMo',
      shortName: 'MoMo',
      logo: 'assets/banks/momo.png',
      androidPackage: 'com.mservice.momotransfer',
      iosScheme: 'momo://',
    ),
    BankInfo(
      bin: 'ZALOPAY',
      name: 'ZaloPay',
      shortName: 'ZaloPay',
      logo: 'assets/banks/zalopay.png',
      androidPackage: 'vn.com.vng.zalopay',
      iosScheme: 'zalopay://',
    ),
    BankInfo(
      bin: 'VIETTELMONEY',
      name: 'Viettel Money',
      shortName: 'ViettelMoney',
      logo: 'assets/banks/viettelmoney.jpg',
      androidPackage: 'com.b2c.bankplus',
      iosScheme: 'viettelmoney://',
    ),
    BankInfo(
      bin: 'SHOPEEPAY',
      name: 'ShopeePay',
      shortName: 'ShopeePay',
      logo: 'assets/banks/shopeepay.jpg',
      androidPackage: 'com.airpay.merchants',
      iosScheme: 'airpay://',
    ),
  ];

  /// Find bank by BIN or Short Name
  static BankInfo? findBank(String? identifier) {
    if (identifier == null || identifier.isEmpty) return null;
    final clean = identifier.trim().toUpperCase();

    // 1. Direct match by BIN
    if (supportedBanks.containsKey(clean)) {
      return supportedBanks[clean];
    }

    // 2. Exact match by shortName across all banks and wallets
    for (final bank in supportedBanks.values) {
      if (bank.shortName.toUpperCase() == clean) {
        return bank;
      }
    }
    for (final wallet in popularWallets) {
      if (wallet.shortName.toUpperCase() == clean || wallet.bin.toUpperCase() == clean) {
        return wallet;
      }
    }

    // 3. Exact match by full name
    for (final bank in supportedBanks.values) {
      if (bank.name.toUpperCase() == clean) {
        return bank;
      }
    }
    for (final wallet in popularWallets) {
      if (wallet.name.toUpperCase() == clean) {
        return wallet;
      }
    }

    // 4. Substring match by name only if clean identifier has at least 3 chars
    if (clean.length >= 3) {
      for (final bank in supportedBanks.values) {
        if (bank.name.toUpperCase().contains(clean)) {
          return bank;
        }
      }
      for (final wallet in popularWallets) {
        if (wallet.name.toUpperCase().contains(clean)) {
          return wallet;
        }
      }
    }

    return null;
  }

  /// Parses a raw scanned string (EMVCo VietQR, URL, pipe-delimited, or text)
  static VietQrData? parse(String rawCode) {
    final trimmed = rawCode.trim();
    if (trimmed.isEmpty) return null;

    // 1. Check for EMVCo standard VietQR (starts with or contains 000201 or A000000727)
    final emvIdx = trimmed.indexOf('000201');
    if (emvIdx >= 0) {
      final emvData = _parseEmvCo(trimmed.substring(emvIdx));
      if (emvData != null) return emvData;
    } else if (trimmed.contains('A000000727')) {
      final emvData = _parseEmvCo(trimmed);
      if (emvData != null) return emvData;
    }

    // 2. Check for VietQR or payment URL
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final urlData = _parseUrl(trimmed);
      if (urlData != null) return urlData;
    }

    // 3. Check for Delimited format (e.g. VCB|0123456789|50000|noidung)
    if (trimmed.contains('|')) {
      final delimData = _parseDelimited(trimmed);
      if (delimData != null) return delimData;
    }

    // 4. Fallback: Parse space-delimited text (e.g. "VCB 1012345678 50000 Cafe" or "1012345678 VCB")
    final textData = _parseText(trimmed);
    if (textData != null) return textData;

    return null;
  }

  /// Internal: Parses EMVCo Tag-Length-Value hierarchy
  static VietQrData? _parseEmvCo(String raw) {
    try {
      final rootMap = parseTlv(raw);

      // Search for Merchant Account Information (Tag 38 NAPAS, Tag 26 VNPAY, or 27-51)
      String? tagMerchant = rootMap['38'];
      if (tagMerchant == null) {
        for (final tag in ['26', '39', '40', '41', '50']) {
          if (rootMap.containsKey(tag)) {
            tagMerchant = rootMap[tag];
            break;
          }
        }
      }
      if (tagMerchant == null) return null;

      final tagMap = parseTlv(tagMerchant);

      // Subtag 01: Beneficiary Bank & Account (Standard NAPAS)
      String? bankBin;
      String? accountNo;

      if (tagMap.containsKey('01')) {
        final beneficiaryMap = parseTlv(tagMap['01']!);
        bankBin = beneficiaryMap['00']; // 6-digit BIN
        accountNo = beneficiaryMap['01']; // Account Number
      }

      // Fallback: If not in subtag 01, search across all subtags
      if (accountNo == null || accountNo.isEmpty) {
        for (final val in tagMap.values) {
          final nested = parseTlv(val);
          if (nested.containsKey('00') && nested.containsKey('01')) {
            bankBin = nested['00'];
            accountNo = nested['01'];
            break;
          }
        }
      }

      if (accountNo == null || accountNo.isEmpty) return null;

      // Tag 54: Amount
      double? amount;
      final amountRaw = rootMap['54'];
      if (amountRaw != null && amountRaw.isNotEmpty) {
        amount = double.tryParse(amountRaw);
      }

      // Tag 62: Additional Data Field (Memo / Purpose)
      String? memo;
      final tag62Raw = rootMap['62'];
      if (tag62Raw != null && tag62Raw.isNotEmpty) {
        final tag62Map = parseTlv(tag62Raw);
        memo = tag62Map['08']; // Purpose of transaction
      }

      final bank = findBank(bankBin);

      return VietQrData(
        bankBin: bankBin,
        bankName: bank?.name ?? 'Ngân hàng ${bankBin ?? ""}',
        bankShortName: bank?.shortName ?? (bankBin ?? 'Bank'),
        bankLogo: bank?.logo,
        accountNumber: accountNo,
        amount: amount,
        memo: memo,
        rawPayload: raw,
        androidPackage: bank?.androidPackage,
        iosScheme: bank?.iosScheme,
      );
    } catch (_) {
      return null;
    }
  }

  /// Parses URL schemes (e.g. api.vietqr.io, qr.sepay.vn, me.momo.vn)
  static VietQrData? _parseUrl(String url) {
    try {
      final uri = Uri.parse(url);

      // Case A: SePay QR (https://qr.sepay.vn/img?acc=123&bank=VCB&amount=50000&des=...)
      if (uri.queryParameters.containsKey('acc') && uri.queryParameters.containsKey('bank')) {
        final acc = uri.queryParameters['acc']!;
        final b = uri.queryParameters['bank']!;
        final amt = double.tryParse(uri.queryParameters['amount'] ?? '');
        final des = uri.queryParameters['des'];
        final bank = findBank(b);
        return VietQrData(
          bankBin: bank?.bin ?? b,
          bankName: bank?.name ?? b,
          bankShortName: bank?.shortName ?? b,
          bankLogo: bank?.logo,
          accountNumber: acc,
          amount: amt,
          memo: des,
          rawPayload: url,
          androidPackage: bank?.androidPackage,
          iosScheme: bank?.iosScheme,
        );
      }

      // Case B: VietQR Pattern: /image/<BIN>-<ACCOUNT>-<TEMPLATE>.jpg
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        for (final segment in pathSegments) {
          final parts = segment.replaceAll('.jpg', '').replaceAll('.png', '').split('-');
          if (parts.length >= 2) {
            final potentialBin = parts[0];
            final potentialAccount = parts[1];
            final bank = findBank(potentialBin);
            if (bank != null || potentialAccount.length >= 6) {
              final amountStr = uri.queryParameters['amount'];
              final memo = uri.queryParameters['addInfo'] ?? uri.queryParameters['memo'];
              return VietQrData(
                bankBin: bank?.bin ?? potentialBin,
                bankName: bank?.name ?? 'Ngân hàng $potentialBin',
                bankShortName: bank?.shortName ?? potentialBin,
                bankLogo: bank?.logo,
                accountNumber: potentialAccount,
                amount: amountStr != null ? double.tryParse(amountStr) : null,
                memo: memo,
                rawPayload: url,
                androidPackage: bank?.androidPackage,
                iosScheme: bank?.iosScheme,
              );
            }
          }
        }
      }

      // Case C: MoMo Transfer URL (https://me.momo.vn/<PHONE> or https://nhantien.momo.vn/...)
      if (url.contains('momo.vn')) {
        final last = pathSegments.isNotEmpty ? pathSegments.last : '';
        if (RegExp(r'^\d{9,11}$').hasMatch(last)) {
          final momo = findBank('MOMO');
          return VietQrData(
            bankBin: 'MOMO',
            bankName: 'Ví MoMo',
            bankShortName: 'MoMo',
            bankLogo: momo?.logo,
            accountNumber: last,
            rawPayload: url,
            androidPackage: momo?.androidPackage,
            iosScheme: momo?.iosScheme,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// Parses pipe-delimited format (e.g. "VCB|1012345678|50000|An trua")
  static VietQrData? _parseDelimited(String raw) {
    try {
      final parts = raw.split('|');
      if (parts.length >= 2) {
        final bankIdent = parts[0].trim();
        final accountNo = parts[1].trim();
        final bank = findBank(bankIdent);

        double? amount;
        if (parts.length >= 3) {
          amount = double.tryParse(parts[2].trim());
        }

        String? memo;
        if (parts.length >= 4) {
          memo = parts[3].trim();
        }

        return VietQrData(
          bankBin: bank?.bin,
          bankName: bank?.name ?? bankIdent,
          bankShortName: bank?.shortName ?? bankIdent,
          bankLogo: bank?.logo,
          accountNumber: accountNo,
          amount: amount,
          memo: memo,
          rawPayload: raw,
          androidPackage: bank?.androidPackage,
          iosScheme: bank?.iosScheme,
        );
      }
    } catch (_) {}
    return null;
  }

  /// Parses space-separated manual text input
  static VietQrData? _parseText(String raw) {
    try {
      final tokens = raw.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
      if (tokens.length < 2) return null;

      // Try tokens[0] as bank, tokens[1] as account
      var bank = findBank(tokens[0]);
      String? account;
      int nextIdx = 2;

      if (bank != null) {
        account = tokens[1];
      } else {
        // Try tokens[1] as bank, tokens[0] as account
        bank = findBank(tokens[1]);
        if (bank != null) {
          account = tokens[0];
        }
      }

      if (bank != null && account != null && account.length >= 4) {
        double? amount;
        if (tokens.length > nextIdx) {
          amount = double.tryParse(tokens[nextIdx].replaceAll(RegExp(r'[^0-9]'), ''));
          nextIdx++;
        }
        String? memo;
        if (tokens.length > nextIdx) {
          memo = tokens.sublist(nextIdx).join(' ');
        }

        return VietQrData(
          bankBin: bank.bin,
          bankName: bank.name,
          bankShortName: bank.shortName,
          bankLogo: bank.logo,
          accountNumber: account,
          amount: amount,
          memo: memo,
          rawPayload: raw,
          androidPackage: bank.androidPackage,
          iosScheme: bank.iosScheme,
        );
      }
    } catch (_) {}
    return null;
  }

  /// Pure Dart TLV (Tag - Length - Value) Parser
  static Map<String, String> parseTlv(String raw) {
    final result = <String, String>{};
    int i = 0;
    while (i + 4 <= raw.length) {
      final tag = raw.substring(i, i + 2);
      final lenStr = raw.substring(i + 2, i + 4);
      final len = int.tryParse(lenStr);
      if (len == null || i + 4 + len > raw.length) break;
      final val = raw.substring(i + 4, i + 4 + len);
      result[tag] = val;
      i += 4 + len;
    }
    return result;
  }
}
