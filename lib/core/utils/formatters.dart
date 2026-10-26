import 'package:intl/intl.dart';

final NumberFormat _vnd = NumberFormat('#,##0', 'vi_VN');

String formatVND(int amount) => '${_vnd.format(amount)} ₫';

class Formatters {
  static String formatCurrency(num amount) {
    return '${_vnd.format(amount.toInt())} đ';
  }
}

/// Mirrors CategoryIconHelper.resolveIcon — maps icon names to emoji.
class CategoryIconHelper {
  static const Map<String, String> _iconMap = {
    'wallet': '💳',
    'credit-card': '💳',
    'banknote': '💵',
    'piggy-bank': '🐷',
    'chart-pie': '📊',
    'target': '🎯',
    'briefcase': '💼',
    'landmark': '🏦',
    'trending-up': '📈',
    'trending-down': '📉',
    'receipt': '🧾',
    'shopping-bag': '🛍️',
    'badge-percent': '🏷️',
    'party-popper': '🎉',
    'construction': '🚧',
    'youtube': '▶️',
    'gift': '🎁',
    'shield': '🛡️',
    'repeat': '🔄',
    'more-horizontal': '💸',
    'utensils': '🍜',
    'car': '🚗',
    'home': '🏠',
    'gamepad': '🎮',
    'heart': '❤️',
    'graduation-cap': '🎓',
    'plane': '✈️',
    'coins': '🪙',
    'bitcoin': '🪙',
    'box': '📦',
    'users': '👥',
    'search': '🔍',
    'sparkles': '✨',
    'command': '⌨️',
    'arrowrightleft': '🔄',
    'layoutgrid': '🎛️',
    'piechart': '📊',
    'handcoins': '🫱🪙',
    'activity': '📈',
    'item-award': '🏆',
    'item-key': '🔑',
    'item-play': '▶️',
    'dollar-sign': '💵',
    'euro': '💶',
    'pound-sterling': '💷',
    'shopping-cart': '🛒',
    'store': '🏪',
    'shirt': '👕',
    'gem': '💎',
    'coffee': '☕',
    'cake': '🍰',
    'bus': '🚌',
    'train': '🚆',
    'bike': '🚲',
    'ship': '🚢',
    'fuel': '⛽',
    'building': '🏢',
    'zap': '⚡',
    'droplet': '💧',
    'flame': '🔥',
    'wrench': '🔧',
    'music': '🎵',
    'ticket': '🎫',
    'clapperboard': '🎬',
    'tv': '📺',
    'dumbbell': '🏋️',
    'stethoscope': '🩺',
    'pill': '💊',
    'book': '📖',
    'smartphone': '📱',
    'laptop': '💻',
    'monitor': '🖥️',
    'camera': '📷',
    'watch': '⌚',
    'headset': '🎧',
    'dog': '🐶',
    'cat': '🐱',
    'award': '🏆',
    'key': '🔑',
    'play': '▶️',
    'phone': '📞',
    'wifi': '📶',
    'scissors': '✂️',
    'brush': '🖌️',
    'glass-water': '🥤',
    'baby': '👶',
    'flower': '🌸',
    'leaf': '🍃',
    'heart-pulse': '❤️‍🩹',
    'first-aid': '🩹',
    'shield-alert': '🛡️',
    'alert-triangle': '⚠️',
    'clock': '⏰',
    'calendar': '📅',
    'apple': '🍎',
    'croissant': '🥐',
    'pizza': '🍕',
    'beer': '🍺',
    'wine': '🍷',
    'trophy': '🏆',
    'calculator': '🧮',
    'school': '🏫',
    'umbrella': '☂️',
    'cloud': '☁️',
    'sun': '☀️',
    'moon': '🌙',
    'wind': '💨',
    'snowflake': '❄️',
    'hammer': '🔨',
    'trash': '🗑️',
    'lock': '🔒',
    'unlock': '🔓',
    'eye': '👁️',
    'mail': '✉️',
    'map-pin': '📍',
    'film': '🎬',
    'video': '📹',
    'anchor': '⚓',
    'compass': '🧭',
    'crown': '👑',
    'fish': '🐟',
    'ghost': '👻',
    'glasses': '👓',
    'hard-hat': '⛑️',
    'palette': '🎨',
    'tent': '⛺',
    'smile': '😊',
    'syringe': '💉',
    // Brands matching web constants/brandIcons.ts
    'brand-shopee': '🛍️', 'shopee': '🛍️',
    'brand-tiktok': '📱', 'tiktok': '📱',
    'brand-lazada': '🛍️', 'lazada': '🛍️',
    'brand-winmart': '🏪', 'winmart': '🏪',
    'brand-grab': '🚗', 'grab': '🚗',
    'brand-netflix': '📺', 'netflix': '📺',
    'brand-spotify': '🎵', 'spotify': '🎵',
    'brand-tiki': '📦', 'tiki': '📦',
    // E-Wallets & Banks matching web constants/banks.ts
    'bank-momo': '👛', 'momo': '👛',
    'bank-zalo': '💬', 'zalo': '💬', 'zalopay': '💬',
    'bank-vnpay': '💳', 'vnpay': '💳',
    'bank-shopeepay': '🛍️', 'shopeepay': '🛍️',
    'bank-viettelmoney': '📱', 'viettelmoney': '📱',
    'bank-vnptmoney': '📱', 'vnptmoney': '📱', 'vnpt': '📱',
    'bank-vcb': '🏦', 'vcb': '🏦', 'vietcombank': '🏦',
    'bank-mbbank': '🏦', 'mbbank': '🏦', 'mb': '🏦',
    'bank-tcb': '🏦', 'tcb': '🏦', 'techcombank': '🏦',
    'bank-bidv': '🏦', 'bidv': '🏦',
    'bank-vtb': '🏦', 'vtb': '🏦', 'vietinbank': '🏦', 'ctg': '🏦',
    'bank-acb': '🏦', 'acb': '🏦',
    'bank-vpb': '🏦', 'vpb': '🏦', 'vpbank': '🏦',
    'bank-tpb': '🏦', 'tpb': '🏦', 'tpbank': '🏦',
    'bank-stb': '🏦', 'stb': '🏦', 'sacombank': '🏦',
    'bank-shb': '🏦', 'shb': '🏦',
    'bank-hdb': '🏦', 'hdb': '🏦', 'hdbank': '🏦',
    'bank-vib': '🏦', 'vib': '🏦',
    'bank-msb': '🏦', 'msb': '🏦',
    'bank-ocb': '🏦', 'ocb': '🏦',
    'bank-sea': '🏦', 'sea': '🏦', 'seabank': '🏦',
    'bank-eib': '🏦', 'eib': '🏦', 'eximbank': '🏦',
    'bank-agri': '🏦', 'agri': '🏦', 'agribank': '🏦',
    'bank-cake': '🧁',
    'bank-timo': '🏦', 'timo': '🏦',
    'bank-cash': '💵', 'cash': '💵', 'tienmat': '💵',
    // Aliases
    'wa': '💳', 'cr': '💳', 'ba': '💵', 'pi': '🐷', 'ch': '📊', 'ta': '🎯',
    'br': '💼', 'la': '🏦', 'tr': '📈', 're': '🧾', 'sh': '🛍️', 'gi': '🎁',
    'mo': '💬', 'ut': '🍲', 'ca': '🚗', 'ho': '🏠', 'ga': '🎮', 'he': '❤️',
    'gr': '🎓', 'pl': '✈️', 'co': '🪙', 'bi': '🪙', 'bo': '📦', 'us': '👥',
    'se': '🔍', 'sp': '✨', 'ar': '🔄', 'ha': '🫱🪙', 'ac': '📈', 'it': '🏆',
  };

  static String? getAssetPath(String? iconStr) {
    if (iconStr == null || iconStr.trim().isEmpty) return null;
    var raw = iconStr.trim().toLowerCase();
    if (raw.startsWith('http://') ||
        raw.startsWith('https://') ||
        raw.startsWith('//') ||
        raw.contains('/storage/')) {
      return null;
    }
    if (raw.startsWith('assets/')) {
      return iconStr.trim();
    }
    var clean = raw;
    if (clean.startsWith('bank-')) clean = clean.substring(5);
    if (clean.startsWith('brand-')) clean = clean.substring(6);
    clean = clean.replaceAll(RegExp(r'[^a-z0-9]'), '');

    const assetMap = {
      'vcb': 'assets/banks/vcb.jpg',
      'vietcombank': 'assets/banks/vcb.jpg',
      'tcb': 'assets/banks/tcb.jpg',
      'techcombank': 'assets/banks/tcb.jpg',
      'mb': 'assets/banks/mbbank.jpg',
      'mbbank': 'assets/banks/mbbank.jpg',
      'vpb': 'assets/banks/vpb.jpg',
      'vpbank': 'assets/banks/vpb.jpg',
      'acb': 'assets/banks/acb.jpg',
      'tpb': 'assets/banks/tpb.jpg',
      'tpbank': 'assets/banks/tpb.jpg',
      'bidv': 'assets/banks/bidv.jpg',
      'ctg': 'assets/banks/vtb.jpg',
      'vtb': 'assets/banks/vtb.jpg',
      'vietinbank': 'assets/banks/vtb.jpg',
      'vib': 'assets/banks/vib.jpg',
      'stb': 'assets/banks/stb.jpg',
      'sacombank': 'assets/banks/stb.jpg',
      'shb': 'assets/banks/shb.jpg',
      'hdb': 'assets/banks/hdb.jpg',
      'hdbank': 'assets/banks/hdb.jpg',
      'msb': 'assets/banks/msb.jpg',
      'ocb': 'assets/banks/ocb.jpg',
      'sea': 'assets/banks/sea.jpg',
      'seabank': 'assets/banks/sea.jpg',
      'eib': 'assets/banks/eib.jpg',
      'eximbank': 'assets/banks/eib.jpg',
      'agri': 'assets/banks/agri.jpg',
      'agribank': 'assets/banks/agri.jpg',
      'cake': 'assets/banks/cake.jpg',
      'timo': 'assets/banks/timo.jpg',
      'momo': 'assets/banks/momo.jpg',
      'zalo': 'assets/banks/zalo.jpg',
      'zalopay': 'assets/banks/zalo.jpg',
      'vnpay': 'assets/banks/vnpay.jpg',
      'shopeepay': 'assets/banks/shopeepay.jpg',
      'viettelmoney': 'assets/banks/viettelmoney.jpg',
      'vnptmoney': 'assets/banks/vnptmoney.jpg',
      'shopee': 'assets/banks/shopee.jpg',
      'shopeemall': 'assets/banks/shopee.jpg',
      'lazada': 'assets/banks/lazada.jpg',
      'lazadamall': 'assets/banks/lazada.jpg',
      'tiktok': 'assets/banks/tiktok.jpg',
      'tiktokshop': 'assets/banks/tiktok.jpg',
      'winmart': 'assets/banks/winmart.png',
      'winmartplus': 'assets/banks/winmart.png',
      'vinmart': 'assets/banks/winmart.png',
      'vinmartplus': 'assets/banks/winmart.png',
    };

    if (assetMap.containsKey(clean)) return assetMap[clean];
    if (clean.contains('shopee')) return 'assets/banks/shopee.jpg';
    if (clean.contains('tiktok')) return 'assets/banks/tiktok.jpg';
    if (clean.contains('lazada')) return 'assets/banks/lazada.jpg';
    if (clean.contains('winmart') || clean.contains('vinmart')) {
      return 'assets/banks/winmart.png';
    }

    return null;
  }

  static bool isPhoto(String? iconStr, [String? categoryName, String? merchantName]) {
    if (iconStr == null || iconStr.trim().isEmpty) {
      if (categoryName != null && isPhoto(categoryName)) return true;
      if (merchantName != null && isPhoto(merchantName)) return true;
      return false;
    }
    final raw = iconStr.trim().toLowerCase();
    if (raw.startsWith('http://') ||
        raw.startsWith('https://') ||
        raw.startsWith('//') ||
        raw.startsWith('data:image') ||
        raw.startsWith('blob:') ||
        raw.contains('/storage/')) {
      return true;
    }
    if (raw.contains('.png') ||
        raw.contains('.jpg') ||
        raw.contains('.jpeg') ||
        raw.contains('.webp') ||
        raw.contains('.svg') ||
        raw.contains('.gif') ||
        raw.contains('.bmp')) {
      return true;
    }
    if (raw.contains('assets/')) {
      return true;
    }
    if (getAssetPath(iconStr) != null) return true;
    if (categoryName != null && getAssetPath(categoryName) != null) return true;
    if (merchantName != null && getAssetPath(merchantName) != null) return true;
    return false;
  }

  static String resolveIcon(String? iconStr, [String? categoryName]) {
    if (iconStr != null && iconStr.trim().isNotEmpty) {
      final clean = iconStr.trim();
      final lower = clean.toLowerCase();

      // If iconStr is an image URL or storage path, NEVER return the URL string as an emoji!
      if (lower.startsWith('http://') ||
          lower.startsWith('https://') ||
          lower.startsWith('//') ||
          lower.contains('/storage/') ||
          lower.startsWith('data:image')) {
        // Fall through to keyword fallback below
      } else {
        var mapped = _iconMap[lower];
        if (mapped != null) return mapped;

        if (lower.startsWith('bank-')) {
          mapped = _iconMap[lower.substring(5)];
          if (mapped != null) return mapped;
        }
        if (lower.startsWith('brand-')) {
          mapped = _iconMap[lower.substring(6)];
          if (mapped != null) return mapped;
        }

        final lucideIdRegex = RegExp(r'^[a-z0-9_-]+$');
        if (!lucideIdRegex.hasMatch(lower)) {
          return clean;
        }
      }
    }

    // Fallback resolving by category or note name keywords
    if (categoryName != null && categoryName.trim().isNotEmpty) {
      final lowerName = categoryName.trim().toLowerCase();
      if (lowerName.contains('shopee')) return '🛍️';
      if (lowerName.contains('momo')) return '👛';
      if (lowerName.contains('zalo')) return '💬';
      if (lowerName.contains('cà phê') ||
          lowerName.contains('cafe') ||
          lowerName.contains('trà')) return '☕';
      if (lowerName.contains('ăn') ||
          lowerName.contains('cơm') ||
          lowerName.contains('phở') ||
          lowerName.contains('bún')) return '🍜';
      if (lowerName.contains('chợ') ||
          lowerName.contains('rau') ||
          lowerName.contains('siêu thị')) return '🥦';
      if (lowerName.contains('mua sắm') ||
          lowerName.contains('shopping') ||
          lowerName.contains('lazada') ||
          lowerName.contains('tiki')) return '🛍️';
      if (lowerName.contains('nhà ở') ||
          lowerName.contains('tiền nhà') ||
          lowerName.contains('phòng')) return '🏠';
      if (lowerName.contains('xăng') || lowerName.contains('đổ xăng'))
        return '⛽';
      if (lowerName.contains('đi lại') ||
          lowerName.contains('di chuyển') ||
          lowerName.contains('xe') ||
          lowerName.contains('grab')) return '🛵';
      if (lowerName.contains('điện') ||
          lowerName.contains('nước') ||
          lowerName.contains('hóa đơn')) return '⚡';
      if (lowerName.contains('thuốc') ||
          lowerName.contains('sức khỏe') ||
          lowerName.contains('khám')) return '💊';
      if (lowerName.contains('học') ||
          lowerName.contains('giáo dục') ||
          lowerName.contains('sách')) return '🎓';
      if (lowerName.contains('game') ||
          lowerName.contains('chơi') ||
          lowerName.contains('giải trí')) return '🎮';
      if (lowerName.contains('lương') ||
          lowerName.contains('thưởng') ||
          lowerName.contains('thu nhập')) return '💰';
      if (lowerName.contains('cho vay') || lowerName.contains('vay'))
        return '🪙';
      if (lowerName.contains('trả nợ') || lowerName.contains('nợ')) return '🧾';
      if (lowerName.contains('khác')) return '💳';
    }

    return '💸';
  }

  static String resolveTransactionIcon({
    required String transactionType,
    String? categoryIcon,
    String? categoryName,
    String? note,
  }) {
    switch (transactionType) {
      case 'transfer':
        return '⇄';
      case 'credit_card_payment':
        return '💳';
      case 'loan_repayment_received':
        return '🪙';
      case 'debt_repayment_paid':
        return '🧾';
      default:
        return resolveIcon(categoryIcon, categoryName ?? note);
    }
  }
}
