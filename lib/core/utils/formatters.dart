import 'package:intl/intl.dart';

final NumberFormat _vnd = NumberFormat('#,##0', 'vi_VN');

String formatVND(int amount) => '${_vnd.format(amount)} ₫';

class Formatters {
  static String currency(num amount) => _vnd.format(amount);
  static String formatCurrency(num amount) => '${_vnd.format(amount)} đ';
  static String date(DateTime date) => DateFormat('dd/MM/yyyy').format(date);
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
    // Remaining IDs from the web `CATEGORY_LUCIDE_ICONS` registry. Keeping
    // these keys exhaustive prevents valid web icons falling back to “Khác”.
    'smile': '😊',
    'syringe': '💉',
    'anchor': '⚓',
    'badge-percent': '🏷️',
    'compass': '🧭',
    'crown': '👑',
    'fish': '🐟',
    'ghost': '👻',
    'glasses': '👓',
    'hard-hat': '⛑️',
    'image': '🖼️',
    'palette': '🎨',
    'party-popper': '🎉',
    'tent': '⛺',
    'video': '🎥',
    'youtube': '▶️',
    'construction': '🚧',
    'wa': '💳', 'cr': '💳', 'ba': '💵', 'pi': '🐷', 'ch': '📊', 'ta': '🎯',
    'br': '💼', 'la': '🏦', 'tr': '📈', 're': '🧾', 'sh': '🛍️', 'gi': '🎁',
    'mo': '💬', 'ut': '🍲', 'ca': '🚗', 'ho': '🏠', 'ga': '🎮', 'he': '❤️',
    'gr': '🎓', 'pl': '✈️', 'co': '🪙', 'bi': '🪙', 'bo': '📦', 'us': '👥',
    'se': '🔍', 'sp': '✨', 'ar': '🔄', 'ha': '🫱🪙', 'ac': '📈', 'it': '🏆',
  };

  static String resolveIcon(String? iconStr) {
    if (iconStr == null || iconStr.trim().isEmpty) return '💸';
    final clean = iconStr.trim();
    final lower = clean.toLowerCase();
    final mapped = _iconMap[lower];
    if (mapped != null) return mapped;

    // Firestore may contain a category name instead of the web icon key.
    // Resolve names rather than rendering the raw text inside an icon badge.
    const nameFallbacks = <String, String>{
      'ăn': '🍜',
      'food': '🍜',
      'cafe': '☕',
      'cà phê': '☕',
      'mua': '🛍️',
      'shop': '🛍️',
      'nhà': '🏠',
      'điện': '⚡',
      'nước': '💧',
      'xăng': '⛽',
      'xe': '🚗',
      'di chuyển': '🚗',
      'giải trí': '🎮',
      'sức khỏe': '❤️',
      'y tế': '🩺',
      'giáo dục': '🎓',
      'lương': '💵',
      'thưởng': '🎁',
      'đầu tư': '📈',
      'bảo hiểm': '🛡️',
      'tiết kiệm': '🐷',
      'hóa đơn': '🧾',
      'chuyển tiền': '🔄',
    };
    for (final entry in nameFallbacks.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }

    // Preserve a real emoji, but reject object strings, URLs and ordinary text.
    final hasEmojiLikeRune = clean.runes.any((rune) => rune > 0x2000);
    if (hasEmojiLikeRune &&
        !clean.startsWith('{') &&
        !lower.startsWith('http')) {
      return clean;
    }
    return '💸';
  }

  /// Resolves system transactions before falling back to the category icon.
  /// Web records often store a generic category for transfers, loans and card
  /// repayments, so category-only rendering produces the wrong icon.
  static String resolveTransactionIcon({
    String? transactionType,
    String? categoryIcon,
    String? categoryName,
    String? note,
  }) {
    final haystack = [transactionType, categoryName, note]
        .whereType<String>()
        .join(' ')
        .toLowerCase();
    if (haystack.contains('credit_card_payment') ||
        haystack.contains('thanh toán thẻ')) return '💳';
    if (haystack.contains('loan_repayment_received') ||
        haystack.contains('thu nợ')) return '🪙';
    if (haystack.contains('debt_repayment') ||
        haystack.contains('loan_repayment_sent') ||
        haystack.contains('trả nợ')) return '🧾';
    if (haystack.contains('borrowing') || haystack.contains('vay nợ')) {
      return '🤝';
    }
    if (haystack.contains('lending') ||
        haystack.contains('cho vay') ||
        transactionType == 'loan') return '🪙';
    if (haystack.contains('transfer') || haystack.contains('chuyển tiền')) {
      return '⇄';
    }
    if (haystack.contains('investment') || haystack.contains('đầu tư')) {
      return '📈';
    }
    if (haystack.contains('saving') || haystack.contains('tiết kiệm')) {
      return '🐷';
    }
    return resolveIcon(categoryIcon ?? categoryName);
  }
}
