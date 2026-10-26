import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/design_system/glassmorphism_tokens.dart';

/// Structured data models and rich, realistic datasets for Glassmorphism 2.0 Catalog.
class CatalogMockData {
  // ---------------------------------------------------------------------------
  // Summary & Metrics
  // ---------------------------------------------------------------------------
  static const int totalNetWorth = 1485000000; // 1,485,000,000 VND
  static const int periodIncome = 45000000;    // 45,000,000 VND
  static const int periodExpense = 18500000;   // 18,500,000 VND
  static const int periodNet = 26500000;       // 26,500,000 VND
  static const int healthScore = 86;           // 86/100 (Tốt & Cân bằng)
  static const double emergencyFundMonths = 6.8;
  static const double savingRatio = 0.42;      // 42%
  static const double debtRatio = 0.14;        // 14%

  // ---------------------------------------------------------------------------
  // Wallets & Accounts
  // ---------------------------------------------------------------------------
  static final List<CatalogWalletItem> wallets = [
    CatalogWalletItem(
      id: 'w1',
      name: 'Vietcombank Priority',
      type: WalletType.bank,
      bankCode: 'vcb',
      bankName: 'Vietcombank',
      accountNumber: '**** 8829',
      balance: 125000000,
      color: const Color(0xFF1B5E20),
      isDefault: true,
      owner: '👨 Chồng',
    ),
    CatalogWalletItem(
      id: 'w2',
      name: 'MB Bank Titanium',
      type: WalletType.bank,
      bankCode: 'mbbank',
      bankName: 'MB BANK',
      accountNumber: '**** 6688',
      balance: 350000000,
      color: const Color(0xFF141ED2),
      owner: '👩 Vợ',
    ),
    CatalogWalletItem(
      id: 'w3',
      name: 'Techcombank Signature',
      type: WalletType.credit,
      bankCode: 'tcb',
      bankName: 'Techcombank',
      accountNumber: '**** 4591',
      balance: -15400000,
      creditLimit: 100000000,
      availableLimit: 84600000,
      statementDay: 20,
      color: const Color(0xFFEA0029),
      owner: '👨 Chồng',
    ),
    CatalogWalletItem(
      id: 'w4',
      name: 'MoMo Premium',
      type: WalletType.eWallet,
      bankCode: 'momo',
      bankName: 'Ví MoMo',
      accountNumber: '090****888',
      balance: 8500000,
      color: const Color(0xFFA50064),
      owner: '👨👩👧 Chung',
    ),
    CatalogWalletItem(
      id: 'w5',
      name: 'Tiền mặt gia đình',
      type: WalletType.cash,
      bankCode: 'cash',
      bankName: 'Két sắt gia đình',
      accountNumber: 'Tiền mặt',
      balance: 22000000,
      color: const Color(0xFFF59E0B),
      owner: '👨👩👧 Chung',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Transactions
  // ---------------------------------------------------------------------------
  static final List<CatalogTransactionItem> transactions = [
    CatalogTransactionItem(
      id: 'tx1',
      title: 'Highlands Coffee & Điểm tâm sáng',
      category: 'Ăn uống',
      amount: 145000,
      isExpense: true,
      walletName: 'Vietcombank',
      memberTag: '👨 Chồng',
      date: '21/09/2026',
      time: '08:30',
      icon: LucideIcons.utensils,
      categoryColor: const Color(0xFFFF9500),
      note: 'Gặp đối tác tại Vincom',
    ),
    CatalogTransactionItem(
      id: 'tx2',
      title: 'Lương Tech Lead tháng 9',
      category: 'Tiền lương',
      amount: 45000000,
      isExpense: false,
      walletName: 'MB BANK',
      memberTag: '👨 Chồng',
      date: '20/09/2026',
      time: '17:00',
      icon: LucideIcons.banknote,
      categoryColor: GlassmorphismTokens.income,
      note: 'Công ty Finora Global',
    ),
    CatalogTransactionItem(
      id: 'tx3',
      title: 'Siêu thị WinMart Times City',
      category: 'Mua sắm',
      amount: 1850000,
      isExpense: true,
      walletName: 'Techcombank',
      memberTag: '👩 Vợ',
      date: '20/09/2026',
      time: '19:45',
      icon: LucideIcons.shopping_cart,
      categoryColor: const Color(0xFFAF52DE),
      note: 'Thực phẩm tuần & đồ gia dụng',
    ),
    CatalogTransactionItem(
      id: 'tx4',
      title: 'Đổ xăng Petrolimex RON 95',
      category: 'Đi lại',
      amount: 850000,
      isExpense: true,
      walletName: 'MoMo',
      memberTag: '👨 Chồng',
      date: '19/09/2026',
      time: '12:15',
      icon: LucideIcons.car,
      categoryColor: const Color(0xFF5AC8FA),
      note: 'Đầy bình xe gia đình',
    ),
    CatalogTransactionItem(
      id: 'tx5',
      title: 'Cổ tức tiền mặt FPT đợt 1',
      category: 'Đầu tư',
      amount: 6000000,
      isExpense: false,
      walletName: 'Vietcombank',
      memberTag: '👨 Chồng',
      date: '18/09/2026',
      time: '10:00',
      icon: LucideIcons.trending_up,
      categoryColor: const Color(0xFF34C759),
      note: '3.000 CP FPT',
    ),
    CatalogTransactionItem(
      id: 'tx6',
      title: 'Học phí Mầm non Song ngữ',
      category: 'Giáo dục',
      amount: 6500000,
      isExpense: true,
      walletName: 'MB BANK',
      memberTag: '👨👩👧 Chung',
      date: '17/09/2026',
      time: '09:00',
      icon: LucideIcons.graduation_cap,
      categoryColor: const Color(0xFF5856D6),
      note: 'Bé Bắp tháng 9/2026',
    ),
    CatalogTransactionItem(
      id: 'tx7',
      title: 'Chuyển quỹ tích lũy Mua xe',
      category: 'Chuyển khoản',
      amount: 10000000,
      isExpense: true,
      isTransfer: true,
      walletName: 'Vietcombank ➔ Sổ tiết kiệm',
      memberTag: '👨👩👧 Chung',
      date: '16/09/2026',
      time: '14:20',
      icon: LucideIcons.repeat,
      categoryColor: const Color(0xFF007AFF),
      note: 'Tích lũy định kỳ ngày 16 hàng tháng',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Budgets
  // ---------------------------------------------------------------------------
  static final List<CatalogBudgetItem> budgets = [
    CatalogBudgetItem(
      id: 'b1',
      category: 'Ăn uống & Nhà hàng',
      limit: 10000000,
      spent: 7850000,
      icon: LucideIcons.utensils,
      color: const Color(0xFFFF9500),
    ),
    CatalogBudgetItem(
      id: 'b2',
      category: 'Nhà cửa & Hóa đơn',
      limit: 8000000,
      spent: 5400000,
      icon: LucideIcons.house,
      color: const Color(0xFF5856D6),
    ),
    CatalogBudgetItem(
      id: 'b3',
      category: 'Mua sắm & Gia đình',
      limit: 6000000,
      spent: 3250000,
      icon: LucideIcons.shopping_bag,
      color: const Color(0xFFAF52DE),
    ),
    CatalogBudgetItem(
      id: 'b4',
      category: 'Đi lại & Xăng xe',
      limit: 3000000,
      spent: 2100000,
      icon: LucideIcons.car,
      color: const Color(0xFF5AC8FA),
    ),
    CatalogBudgetItem(
      id: 'b5',
      category: 'Giáo dục & Phát triển',
      limit: 8000000,
      spent: 6500000,
      icon: LucideIcons.graduation_cap,
      color: const Color(0xFF34C759),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Goals
  // ---------------------------------------------------------------------------
  static final List<CatalogGoalItem> goals = [
    CatalogGoalItem(
      id: 'g1',
      title: 'Mua VinFast VF8 Plus',
      targetAmount: 900000000,
      currentAmount: 480000000,
      targetDate: '12/2026',
      icon: LucideIcons.car,
      color: const Color(0xFF007AFF),
    ),
    CatalogGoalItem(
      id: 'g2',
      title: 'Quỹ khẩn cấp 12 tháng',
      targetAmount: 200000000,
      currentAmount: 155000000,
      targetDate: '10/2026',
      icon: LucideIcons.shield_check,
      color: const Color(0xFF34C759),
    ),
    CatalogGoalItem(
      id: 'g3',
      title: 'Du lịch Tokyo mùa lá đỏ',
      targetAmount: 80000000,
      currentAmount: 62000000,
      targetDate: '11/2026',
      icon: LucideIcons.plane,
      color: const Color(0xFFFF2D55),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Loans & Debts
  // ---------------------------------------------------------------------------
  static final List<CatalogLoanItem> loans = [
    CatalogLoanItem(
      id: 'l1',
      name: 'Cho anh Tuấn mượn vốn',
      isLending: true,
      amount: 50000000,
      remainingAmount: 20000000,
      dueDate: '15/10/2026',
      color: GlassmorphismTokens.income,
      note: 'Mượn mở quán cafe - Đã trả 30tr',
    ),
    CatalogLoanItem(
      id: 'l2',
      name: 'Cho em Trang mượn học phí',
      isLending: true,
      amount: 15000000,
      remainingAmount: 5000000,
      dueDate: '30/11/2026',
      color: GlassmorphismTokens.income,
      note: 'Đã trả đợt 1',
    ),
    CatalogLoanItem(
      id: 'l3',
      name: 'Vay trả góp chung cư Masteri',
      isLending: false,
      amount: 800000000,
      remainingAmount: 620000000,
      dueDate: '10/2032',
      color: GlassmorphismTokens.expense,
      note: 'Lãi suất cố định BIDV 7.5%/năm',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Assets & Investment
  // ---------------------------------------------------------------------------
  static final List<CatalogAssetItem> assets = [
    CatalogAssetItem(
      id: 'a1',
      name: 'Vàng SJC 9999 Miếng',
      category: 'Vàng & Kim loại quý',
      quantity: 5,
      unit: 'lượng',
      costPrice: 425000000,
      marketValue: 450000000,
      changePercent: 5.88,
      icon: LucideIcons.coins,
      color: const Color(0xFFFFD700),
    ),
    CatalogAssetItem(
      id: 'a2',
      name: 'Cổ phiếu FPT',
      category: 'Cổ phiếu',
      quantity: 3000,
      unit: 'CP',
      costPrice: 360000000,
      marketValue: 417000000,
      changePercent: 15.83,
      icon: LucideIcons.trending_up,
      color: const Color(0xFF007AFF),
    ),
    CatalogAssetItem(
      id: 'a3',
      name: 'Đất nền Long Thành Airport',
      category: 'Bất động sản',
      quantity: 120,
      unit: 'm²',
      costPrice: 1500000000,
      marketValue: 1750000000,
      changePercent: 16.67,
      icon: LucideIcons.building_2,
      color: const Color(0xFF34C759),
    ),
    CatalogAssetItem(
      id: 'a4',
      name: 'Sổ tiết kiệm 12 tháng BIDV',
      category: 'Tiết kiệm',
      quantity: 1,
      unit: 'sổ',
      costPrice: 200000000,
      marketValue: 211000000,
      changePercent: 5.5,
      icon: LucideIcons.landmark,
      color: const Color(0xFF5856D6),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------------
  static final List<CatalogCategoryItem> categories = [
    CatalogCategoryItem(id: 'c1', name: 'Ăn uống', group: 'Chi', icon: LucideIcons.utensils, color: const Color(0xFFFF9500), count: 28, spent: 7850000),
    CatalogCategoryItem(id: 'c2', name: 'Nhà cửa', group: 'Chi', icon: LucideIcons.house, color: const Color(0xFF5856D6), count: 6, spent: 5400000),
    CatalogCategoryItem(id: 'c3', name: 'Mua sắm', group: 'Chi', icon: LucideIcons.shopping_bag, color: const Color(0xFFAF52DE), count: 14, spent: 3250000),
    CatalogCategoryItem(id: 'c4', name: 'Đi lại', group: 'Chi', icon: LucideIcons.car, color: const Color(0xFF5AC8FA), count: 18, spent: 2100000),
    CatalogCategoryItem(id: 'c5', name: 'Giáo dục', group: 'Chi', icon: LucideIcons.graduation_cap, color: const Color(0xFF34C759), count: 3, spent: 6500000),
    CatalogCategoryItem(id: 'c6', name: 'Y tế & Thuốc', group: 'Chi', icon: LucideIcons.heart_pulse, color: const Color(0xFFFF2D55), count: 2, spent: 850000),
    CatalogCategoryItem(id: 'c7', name: 'Tiền lương', group: 'Thu', icon: LucideIcons.banknote, color: const Color(0xFF34C759), count: 2, spent: 45000000),
    CatalogCategoryItem(id: 'c8', name: 'Thưởng KPI', group: 'Thu', icon: LucideIcons.trophy, color: const Color(0xFFFFD700), count: 1, spent: 15000000),
    CatalogCategoryItem(id: 'c9', name: 'Cổ tức & Đầu tư', group: 'Thu', icon: LucideIcons.trending_up, color: const Color(0xFF007AFF), count: 3, spent: 8500000),
    CatalogCategoryItem(id: 'c10', name: 'Vàng & BĐS', group: 'Đầu tư', icon: LucideIcons.coins, color: const Color(0xFFFF9500), count: 4, spent: 220000000),
  ];

  // ---------------------------------------------------------------------------
  // Audit Logs
  // ---------------------------------------------------------------------------
  static final List<CatalogAuditItem> auditLogs = [
    CatalogAuditItem(
      id: 'aud1',
      actor: 'Louis Trần (Chồng)',
      action: 'Cập nhật số dư',
      collection: 'Ví tiền',
      details: 'Đối soát số dư Vietcombank: +1,250,000đ từ tiền tip dự án',
      time: '21/09/2026 14:15',
      type: AuditType.update,
    ),
    CatalogAuditItem(
      id: 'aud2',
      actor: 'Mai Anh (Vợ)',
      action: 'Thêm giao dịch',
      collection: 'Giao dịch',
      details: 'Ghi nhận chi tiêu WinMart: -1,850,000đ (Techcombank)',
      time: '20/09/2026 19:48',
      type: AuditType.create,
    ),
    CatalogAuditItem(
      id: 'aud3',
      actor: 'Louis Trần (Chồng)',
      action: 'Tạo ngân sách',
      collection: 'Ngân sách',
      details: 'Thiết lập ngân sách Ăn uống: 10,000,000đ/tháng',
      time: '01/09/2026 08:00',
      type: AuditType.create,
    ),
    CatalogAuditItem(
      id: 'aud4',
      actor: 'Mai Anh (Vợ)',
      action: 'Khôi phục mục tiêu',
      collection: 'Mục tiêu',
      details: 'Khôi phục từ thùng rác: Quỹ Du lịch Tokyo mùa thu',
      time: '18/09/2026 11:20',
      type: AuditType.restore,
    ),
    CatalogAuditItem(
      id: 'aud5',
      actor: 'Hệ thống Finora AI',
      action: 'Tự động kiểm toán',
      collection: 'Báo cáo',
      details: 'Đồng bộ đối chiếu 42 giao dịch với sao kê ngân hàng',
      time: '15/09/2026 00:00',
      type: AuditType.info,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------
  static final List<CatalogNotificationItem> notifications = [
    CatalogNotificationItem(
      id: 'notif1',
      title: 'Cảnh báo hạn mức ngân sách',
      message: 'Hạng mục Ăn uống đã đạt 78.5% hạn mức tháng. Hãy cân nhắc chi tiêu tiết kiệm trong 9 ngày tới.',
      time: '21/09/2026 11:30',
      isRead: false,
      color: GlassmorphismTokens.warning,
      icon: LucideIcons.triangle_alert,
    ),
    CatalogNotificationItem(
      id: 'notif2',
      title: 'Lương tháng 9 đã về tài khoản',
      message: 'Ghi nhận giao dịch +45,000,000đ vào MB BANK. Finora Copilot gợi ý trích 20% vào quỹ đầu tư FPT.',
      time: '20/09/2026 17:01',
      isRead: true,
      color: GlassmorphismTokens.income,
      icon: LucideIcons.sparkles,
    ),
    CatalogNotificationItem(
      id: 'notif3',
      title: 'Nhắc lịch thanh toán thẻ tín dụng',
      message: 'Thẻ Techcombank Signature đến hạn sao kê ngày 25/09. Số dư cần thanh toán: 15,400,000đ.',
      time: '19/09/2026 09:00',
      isRead: true,
      color: GlassmorphismTokens.expense,
      icon: LucideIcons.credit_card,
    ),
    CatalogNotificationItem(
      id: 'notif4',
      title: 'Mục tiêu tài chính đạt mốc mới',
      message: 'Quỹ Mua VinFast VF8 đã vượt qua 50% chặng đường (480/900 triệu). Chúc mừng gia đình!',
      time: '18/09/2026 15:20',
      isRead: true,
      color: GlassmorphismTokens.primary,
      icon: LucideIcons.trophy,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Trash Items
  // ---------------------------------------------------------------------------
  static final List<CatalogTrashItem> trashItems = [
    CatalogTrashItem(
      id: 'tr1',
      title: 'Hóa đơn cafe The Coffee House',
      collection: 'Giao dịch',
      amountText: '-75,000đ',
      deletedDate: '19/09/2026',
      daysLeft: 28,
      icon: LucideIcons.receipt,
      color: const Color(0xFFFF9500),
    ),
    CatalogTrashItem(
      id: 'tr2',
      title: 'Ví Thẻ Timo cũ',
      collection: 'Ví tiền',
      amountText: '0đ',
      deletedDate: '15/09/2026',
      daysLeft: 24,
      icon: LucideIcons.wallet,
      color: const Color(0xFF5856D6),
    ),
    CatalogTrashItem(
      id: 'tr3',
      title: 'Ngân sách Mua đồ công nghệ Q2',
      collection: 'Ngân sách',
      amountText: 'Hạn mức: 15,000,000đ',
      deletedDate: '10/09/2026',
      daysLeft: 19,
      icon: LucideIcons.target,
      color: const Color(0xFF007AFF),
    ),
  ];
}

// -----------------------------------------------------------------------------
// Model Definitions
// -----------------------------------------------------------------------------
enum WalletType { bank, credit, eWallet, cash }

class CatalogWalletItem {
  final String id;
  final String name;
  final WalletType type;
  final String bankCode;
  final String bankName;
  final String accountNumber;
  final int balance;
  final int? creditLimit;
  final int? availableLimit;
  final int? statementDay;
  final Color color;
  final bool isDefault;
  final String owner;

  CatalogWalletItem({
    required this.id,
    required this.name,
    required this.type,
    required this.bankCode,
    required this.bankName,
    required this.accountNumber,
    required this.balance,
    this.creditLimit,
    this.availableLimit,
    this.statementDay,
    required this.color,
    this.isDefault = false,
    required this.owner,
  });
}

class CatalogTransactionItem {
  final String id;
  final String title;
  final String category;
  final int amount;
  final bool isExpense;
  final bool isTransfer;
  final String walletName;
  final String memberTag;
  final String date;
  final String time;
  final IconData icon;
  final Color categoryColor;
  final String note;

  CatalogTransactionItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.isExpense,
    this.isTransfer = false,
    required this.walletName,
    required this.memberTag,
    required this.date,
    required this.time,
    required this.icon,
    required this.categoryColor,
    required this.note,
  });
}

class CatalogBudgetItem {
  final String id;
  final String category;
  final int limit;
  final int spent;
  final IconData icon;
  final Color color;

  double get progress => (spent / limit).clamp(0.0, 1.5);
  int get remaining => limit - spent;

  CatalogBudgetItem({
    required this.id,
    required this.category,
    required this.limit,
    required this.spent,
    required this.icon,
    required this.color,
  });
}

class CatalogGoalItem {
  final String id;
  final String title;
  final int targetAmount;
  final int currentAmount;
  final String targetDate;
  final IconData icon;
  final Color color;

  double get progress => (currentAmount / targetAmount).clamp(0.0, 1.0);
  int get remaining => targetAmount - currentAmount;

  CatalogGoalItem({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.icon,
    required this.color,
  });
}

class CatalogLoanItem {
  final String id;
  final String name;
  final bool isLending; // true = cho vay, false = đi vay
  final int amount;
  final int remainingAmount;
  final String dueDate;
  final Color color;
  final String note;

  double get progress => ((amount - remainingAmount) / amount).clamp(0.0, 1.0);

  CatalogLoanItem({
    required this.id,
    required this.name,
    required this.isLending,
    required this.amount,
    required this.remainingAmount,
    required this.dueDate,
    required this.color,
    required this.note,
  });
}

class CatalogAssetItem {
  final String id;
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final int costPrice;
  final int marketValue;
  final double changePercent;
  final IconData icon;
  final Color color;

  int get profitOrLoss => marketValue - costPrice;

  CatalogAssetItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.costPrice,
    required this.marketValue,
    required this.changePercent,
    required this.icon,
    required this.color,
  });
}

class CatalogCategoryItem {
  final String id;
  final String name;
  final String group;
  final IconData icon;
  final Color color;
  final int count;
  final int spent;

  CatalogCategoryItem({
    required this.id,
    required this.name,
    required this.group,
    required this.icon,
    required this.color,
    required this.count,
    required this.spent,
  });
}

enum AuditType { create, update, delete, restore, info }

class CatalogAuditItem {
  final String id;
  final String actor;
  final String action;
  final String collection;
  final String details;
  final String time;
  final AuditType type;

  CatalogAuditItem({
    required this.id,
    required this.actor,
    required this.action,
    required this.collection,
    required this.details,
    required this.time,
    required this.type,
  });
}

class CatalogNotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final Color color;
  final IconData icon;

  CatalogNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.color,
    required this.icon,
  });

  CatalogNotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    String? time,
    bool? isRead,
    Color? color,
    IconData? icon,
  }) {
    return CatalogNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}

class CatalogTrashItem {
  final String id;
  final String title;
  final String collection;
  final String amountText;
  final String deletedDate;
  final int daysLeft;
  final IconData icon;
  final Color color;

  CatalogTrashItem({
    required this.id,
    required this.title,
    required this.collection,
    required this.amountText,
    required this.deletedDate,
    required this.daysLeft,
    required this.icon,
    required this.color,
  });
}
