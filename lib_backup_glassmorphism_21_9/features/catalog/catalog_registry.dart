import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'screens/demo_ai_screen.dart';
import 'screens/demo_asset_screen.dart';
import 'screens/demo_audit_screen.dart';
import 'screens/demo_auth_screen.dart';
import 'screens/demo_budget_screen.dart';
import 'screens/demo_category_screen.dart';
import 'screens/demo_dashboard_screen.dart';
import 'screens/demo_family_screen.dart';
import 'screens/demo_goal_screen.dart';
import 'screens/demo_loan_screen.dart';
import 'screens/demo_main_shell_screen.dart';
import 'screens/demo_more_screen.dart';
import 'screens/demo_notification_screen.dart';
import 'screens/demo_onboarding_screen.dart';
import 'screens/demo_profile_screen.dart';
import 'screens/demo_report_screen.dart';
import 'screens/demo_settings_screen.dart';
import 'screens/demo_showcase_screen.dart';
import 'screens/demo_splash_screen.dart';
import 'screens/demo_transaction_screen.dart';
import 'screens/demo_trash_screen.dart';
import 'screens/demo_wallet_screen.dart';

/// 5 Logical Clusters of FINORA Screens
enum ScreenCluster {
  coreFinancial('Tài chính cốt lõi', LucideIcons.wallet),
  assetAndDebt('Tài sản & Nợ', LucideIcons.trending_up),
  intelligenceAndCollab('AI & Gia đình', LucideIcons.sparkles),
  identityAndConfig('Hồ sơ & Cài đặt', LucideIcons.user),
  lifecycleAndShell('Vòng đời & Shell', LucideIcons.layout_grid);

  final String label;
  final IconData icon;
  const ScreenCluster(this.label, this.icon);
}

/// Model definition for each functional screen in the Screen Catalog
class ScreenCatalogItem {
  final String id;
  final String title;
  final String vietnameseTitle;
  final ScreenCluster cluster;
  final IconData icon;
  final String description;
  final String? badge;
  final Widget Function(BuildContext context, bool isLiveMode, VoidCallback? onBack) builder;

  const ScreenCatalogItem({
    required this.id,
    required this.title,
    required this.vietnameseTitle,
    required this.cluster,
    required this.icon,
    required this.description,
    this.badge,
    required this.builder,
  });
}

/// Master Registry containing all 22 functional screens in Glassmorphism 2.0
class CatalogRegistry {
  static final List<ScreenCatalogItem> items = [
    // -------------------------------------------------------------------------
    // 1. Core Financial
    // -------------------------------------------------------------------------
    ScreenCatalogItem(
      id: 'dashboard',
      title: 'Dashboard',
      vietnameseTitle: 'Tổng quan tài chính & số dư',
      cluster: ScreenCluster.coreFinancial,
      icon: LucideIcons.layout_dashboard,
      description: 'Hero net worth card, Quick actions kính mờ, Health score gauge, Budget preview và Giao dịch gần đây.',
      badge: 'Core',
      builder: (context, isLive, onBack) => DemoDashboardScreen(isLiveMode: isLive, onBack: onBack),
    ),
    ScreenCatalogItem(
      id: 'transaction',
      title: 'Transaction',
      vietnameseTitle: 'Lịch sử & chi tiết giao dịch',
      cluster: ScreenCluster.coreFinancial,
      icon: LucideIcons.receipt,
      description: 'Hero spending card, thanh công cụ tìm kiếm đơn dòng, nhóm ngày theo date pill và chi tiết giao dịch.',
      badge: 'Core',
      builder: (context, isLive, onBack) => DemoTransactionScreen(isLiveMode: isLive, onBack: onBack),
    ),
    ScreenCatalogItem(
      id: 'wallet',
      title: 'Wallet',
      vietnameseTitle: 'Quản lý ví, thẻ & tài khoản',
      cluster: ScreenCluster.coreFinancial,
      icon: LucideIcons.wallet,
      description: 'Thẻ tín dụng carousel 3D, danh sách ví tiền mặt/ngân hàng, đối soát số dư thời gian thực.',
      badge: 'Core',
      builder: (context, isLive, onBack) => DemoWalletScreen(isLiveMode: isLive, onBack: onBack),
    ),
    ScreenCatalogItem(
      id: 'budget',
      title: 'Budget',
      vietnameseTitle: 'Ngân sách & hạn mức chi tiêu',
      cluster: ScreenCluster.coreFinancial,
      icon: LucideIcons.piggy_bank,
      description: 'Sunset Orange Hero limit card, tiến độ từng danh mục, AI phân tích tối ưu dòng tiền cuối tháng.',
      badge: 'Core',
      builder: (context, isLive, onBack) => DemoBudgetScreen(isLiveMode: isLive, onBack: onBack),
    ),
    ScreenCatalogItem(
      id: 'goal',
      title: 'Goal',
      vietnameseTitle: 'Mục tiêu tiết kiệm & tích lũy',
      cluster: ScreenCluster.coreFinancial,
      icon: LucideIcons.target,
      description: 'Tiến độ tích lũy, thời hạn mục tiêu, modal nạp tiền vào quỹ và dự báo ngày về đích.',
      badge: 'Core',
      builder: (context, isLive, onBack) => DemoGoalScreen(isLiveMode: isLive, onBack: onBack),
    ),
    ScreenCatalogItem(
      id: 'report',
      title: 'Report',
      vietnameseTitle: 'Báo cáo thống kê, biểu đồ phân tích',
      cluster: ScreenCluster.coreFinancial,
      icon: LucideIcons.chart_pie,
      description: 'Tích lũy ròng trong kỳ, tỷ lệ chi tiêu vợ/chồng, cơ cấu nhóm ngành và xu hướng 6 tháng.',
      badge: 'Core',
      builder: (context, isLive, onBack) => DemoReportScreen(isLiveMode: isLive, onBack: onBack),
    ),

    // -------------------------------------------------------------------------
    // 2. Asset & Debt
    // -------------------------------------------------------------------------
    ScreenCatalogItem(
      id: 'loan',
      title: 'Loan',
      vietnameseTitle: 'Sổ theo dõi vay nợ & trả góp',
      cluster: ScreenCluster.assetAndDebt,
      icon: LucideIcons.hand_coins,
      description: 'Pill tabs [Cho vay / Vay nợ], thẻ nợ cá nhân, lịch trả góp và modal hoàn trả nhanh.',
      builder: (context, isLive, onBack) => DemoLoanScreen(isLiveMode: isLive, onBack: onBack),
    ),
    ScreenCatalogItem(
      id: 'asset',
      title: 'Asset',
      vietnameseTitle: 'Quản lý tài sản & danh mục đầu tư',
      cluster: ScreenCluster.assetAndDebt,
      icon: LucideIcons.gem,
      description: 'Định giá tổng tài sản, lãi lỗ chưa chốt, phân loại Vàng, BĐS, Cổ phiếu, Tiết kiệm.',
      builder: (context, isLive, onBack) => DemoAssetScreen(isLiveMode: isLive, onBack: onBack),
    ),
    ScreenCatalogItem(
      id: 'category',
      title: 'Category',
      vietnameseTitle: 'Danh mục thu chi & tùy biến nhãn',
      cluster: ScreenCluster.assetAndDebt,
      icon: LucideIcons.tags,
      description: 'Nhóm Chi/Thu/Đầu tư, chuyển đổi Grid/List, orb 3D icon và thống kê số giao dịch.',
      builder: (context, isLive, onBack) => DemoCategoryScreen(isLiveMode: isLive, onBack: onBack),
    ),

    // -------------------------------------------------------------------------
    // 3. Intelligence & Collaboration
    // -------------------------------------------------------------------------
    ScreenCatalogItem(
      id: 'ai',
      title: 'AI Advisor',
      vietnameseTitle: 'Trợ lý tài chính thông minh Finora AI',
      cluster: ScreenCluster.intelligenceAndCollab,
      icon: LucideIcons.sparkles,
      description: 'Khung chat Liquid Glass, phiếu giao dịch NLP trích xuất tự động, thanh nhập liệu con nhộng.',
      badge: 'AI 2.0',
      builder: (context, isLive, onBack) => DemoAiScreen(isLiveMode: isLive, onBack: onBack),
    ),
    ScreenCatalogItem(
      id: 'family',
      title: 'Family',
      vietnameseTitle: 'Tài chính gia đình & chia sẻ ví',
      cluster: ScreenCluster.intelligenceAndCollab,
      icon: LucideIcons.users,
      description: 'Tổng tài sản tổ ấm, danh sách thành viên phân quyền, mã mời 6 chữ số và chia sẻ ví.',
      builder: (context, isLive, onBack) => DemoFamilyScreen(isLiveMode: isLive, onBack: onBack),
    ),
    ScreenCatalogItem(
      id: 'audit',
      title: 'Audit Logs',
      vietnameseTitle: 'Nhật ký kiểm toán & lịch sử thay đổi',
      cluster: ScreenCluster.intelligenceAndCollab,
      icon: LucideIcons.shield_check,
      description: 'Toàn vẹn số dư, thẻ kiểm toán thời gian thực theo dõi mọi thao tác thêm/sửa/xóa.',
      builder: (context, isLive, onBack) => DemoAuditScreen(isLiveMode: isLive, onBack: onBack),
    ),
    ScreenCatalogItem(
      id: 'notification',
      title: 'Notification',
      vietnameseTitle: 'Trung tâm thông báo & cảnh báo tài chính',
      cluster: ScreenCluster.intelligenceAndCollab,
      icon: LucideIcons.bell,
      description: 'Thẻ thông báo kính mờ, cảnh báo vượt hạn mức, biến động số dư và nút đánh dấu đã đọc.',
      builder: (context, isLive, onBack) => DemoNotificationScreen(isLiveMode: isLive, onBack: onBack),
    ),

    // -------------------------------------------------------------------------
    // 4. Identity & Configuration
    // -------------------------------------------------------------------------
    ScreenCatalogItem(
      id: 'profile',
      title: 'Profile',
      vietnameseTitle: 'Hồ sơ cá nhân & thông tin người dùng',
      cluster: ScreenCluster.identityAndConfig,
      icon: LucideIcons.user,
      description: 'Thẻ người dùng VIP, avatar kính tròn, trung tâm điều hướng tài chính và đăng xuất an toàn.',
      builder: (context, isLive, onBack) => DemoProfileScreen(isLiveMode: isLive, onBack: onBack),
    ),
    ScreenCatalogItem(
      id: 'settings',
      title: 'Settings',
      vietnameseTitle: 'Cài đặt hệ thống, tiền tệ, bảo mật',
      cluster: ScreenCluster.identityAndConfig,
      icon: LucideIcons.settings,
      description: 'Bộ chọn chế độ sáng/tối Aurora, 5 bảng màu Accent Palette, sinh trắc học và phản hồi xúc giác.',
      builder: (context, isLive, onBack) => DemoSettingsScreen(isLiveMode: isLive, onBack: onBack),
    ),
    ScreenCatalogItem(
      id: 'auth',
      title: 'Auth',
      vietnameseTitle: 'Đăng nhập, đăng ký & xác thực bảo mật',
      cluster: ScreenCluster.identityAndConfig,
      icon: LucideIcons.lock,
      description: 'Logo FINORA vector phát sáng, chuyển đổi Đăng nhập / Đăng ký, Google Sign-in chuẩn HIG.',
      builder: (context, isLive, onBack) => DemoAuthScreen(isLiveMode: isLive, onBack: onBack),
    ),
    ScreenCatalogItem(
      id: 'onboarding',
      title: 'Onboarding',
      vietnameseTitle: 'Giới thiệu luồng khởi động người dùng mới',
      cluster: ScreenCluster.identityAndConfig,
      icon: LucideIcons.compass,
      description: '3 slide PageView trình diễn tính năng, hiệu ứng bóng mờ 3D và nút Bắt đầu ngay.',
      builder: (context, isLive, onBack) => DemoOnboardingScreen(isLiveMode: isLive, onBack: onBack),
    ),

    // -------------------------------------------------------------------------
    // 5. Lifecycle & Shell
    // -------------------------------------------------------------------------
    ScreenCatalogItem(
      id: 'splash',
      title: 'Splash',
      vietnameseTitle: 'Màn hình chào & loading hệ thống',
      cluster: ScreenCluster.lifecycleAndShell,
      icon: LucideIcons.sparkle,
      description: 'Hoạt ảnh đàn hồi (elastic scale & fade), logo thương hiệu và thanh tiến trình kính mờ.',
      builder: (context, isLive, onBack) => DemoSplashScreen(isLiveMode: isLive, onBack: onBack),
    ),
    ScreenCatalogItem(
      id: 'trash',
      title: 'Trash',
      vietnameseTitle: 'Thùng rác & khôi phục dữ liệu đã xóa',
      cluster: ScreenCluster.lifecycleAndShell,
      icon: LucideIcons.trash,
      description: 'Banner lưu trữ 30 ngày, bộ lọc nhóm mục, thẻ khôi phục 1 chạm và dọn sạch an toàn.',
      builder: (context, isLive, onBack) => DemoTrashScreen(isLiveMode: isLive, onBack: onBack),
    ),
    ScreenCatalogItem(
      id: 'showcase',
      title: 'Showcase',
      vietnameseTitle: 'Trình diễn tính năng nổi bật',
      cluster: ScreenCluster.lifecycleAndShell,
      icon: LucideIcons.layers,
      description: 'Bộ điều khiển trực tiếp thông số Blur Sigma, Surface Alpha, Corner Radius của Glassmorphism 2.0.',
      builder: (context, isLive, onBack) => DemoShowcaseScreen(isLiveMode: isLive, onBack: onBack),
    ),
    ScreenCatalogItem(
      id: 'more',
      title: 'More Utilities',
      vietnameseTitle: 'Menu mở rộng & tiện ích tài chính',
      cluster: ScreenCluster.lifecycleAndShell,
      icon: LucideIcons.grid_2x2,
      description: 'Hệ sinh thái tiện ích tài chính: Tính lãi suất, ước tính khoản vay, tỷ giá vàng, xuất báo cáo.',
      builder: (context, isLive, onBack) => DemoMoreScreen(isLiveMode: isLive, onBack: onBack),
    ),
    ScreenCatalogItem(
      id: 'main_shell',
      title: 'Main Shell',
      vietnameseTitle: 'Thanh điều hướng chính Navigation Bar & Header',
      cluster: ScreenCluster.lifecycleAndShell,
      icon: LucideIcons.layout_template,
      description: 'Thanh dock lơ lửng FinoraNavigation trong suốt, chuyển 4 tab chính và nút (+) mở bảng ghi nhanh.',
      badge: 'Shell',
      builder: (context, isLive, onBack) => DemoMainShellScreen(isLiveMode: isLive, onBack: onBack),
    ),
  ];
}
