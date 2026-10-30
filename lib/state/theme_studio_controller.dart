import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/design_system/credit_card_palette.dart';

enum AppColorPalette {
  oceanicSapphire,
  emeraldWealth,
  obsidianGold,
  sunsetCoral,
  slateMinimal,
  amethystRoyal,
  cyberNeonPink,
  titaniumIce,
  crimsonRuby,
  googlePixel,
  colorOsAqua,
  hyperOsElectric,
  custom,
}

enum AppUiUxStyle {
  liquidGlass,
  neumorphicSoft,
  cyberNeon,
  cupertinoMinimal,
  luxuryObsidian,
  retroSynthwave,
  auroraBorealis,
  googleMinimal,
  colorOsAquamorphic,
  hyperOsAlive,
  ledgerEditorial,
  softPaper,
  industrialUtility,
  organicClay,
  einkFocus,
  artDecoFinance,
}

enum AmbientBlurPreset {
  rainbowAurora,
  sapphireCyan,
  midnightAurora,
  sunsetAmber,
  cyberElectric,
  obsidianSlate,
  amoledPitch,
  cosmicAmethyst,
  emeraldMatrix,
  rubyVelvet,
}

enum AppFontFamily {
  plusJakartaSans, // Neo-Fintech Flagship (Plus Jakarta Sans)
  beVietnamPro, // Bản Sắc Việt Tối Ưu Dấu 100% (Be Vietnam Pro)
  inter, // Chuẩn Mực Thụy Sĩ Hiện Đại (Inter Display)
  outfit, // Geometric Luxury Tròn Trị (Outfit)
  lexend, // Quét Thị Giác Tài Chính Nhanh (Lexend Deca)
  manrope, // Châu Âu Thanh Lịch Đẳng Cấp (Manrope)
  systemModern, // Arial Cổ Điển
  roundedFriendly, // Segoe UI Mềm Mại
  fintechMonospace, // Bahnschrift DIN
  executiveSerif, // Georgia Sang Trọng
}

enum CardBorderGlowStyle {
  subtleHairline,
  neonLuminescent,
  gradientRim,
  none,
}

enum AppMotionDynamics {
  smoothGentle,
  snappySwift,
  reducedMotion,
}

enum AppCurrencyFormat {
  symbolSuffix, // 147.277.588 ₫
  codeSuffix, // 147.277.588 VND
  symbolPrefix, // ₫ 147.277.588
}

enum AppDockNavStyle {
  floatingIsland, // Hòn đảo nổi bo tròn tách biệt đáy
  classicDock, // Dock truyền thống tràn đáy thanh lịch
  compactCapsule, // Viên nang mini siêu gọn
  glassNeonUnderline, // Kính phát quang gạch chân neon
  pillTabs, // Dạng thẻ viên thuốc chia ngăn
  hyperOsFloatingBar, // HyperOS Dynamic Floating Bar: thanh kính động đa tầng phản quang
  colorOsCurvedDock, // ColorOS Aquamorphic: đường cong mặt nước gợn sóng mềm mại
  minimalistDotDock, // Chấm bi tối giản: dock siêu mỏng với micro-dot chỉ báo
  cyberpunkSplitDock, // Cyberpunk Neo-Split: chia khối tương lai phát quang đối xứng
  notchWaveRise, // Khuyết lõm lượn sóng: đáy notch uốn lượn mềm mại, tab active/add nhô cao
  segmentedIslandBubbles, // Đảo bóng khí độc lập: từng tab là viên ngọc capsule kính lơ lửng riêng biệt
  expandedGlowTray, // Khay kính mở rộng: bề mặt kính tràn viền với dải gradient phản chiếu quang học
  stealthWireMinimal, // Vi sợi tàng hình: dock siêu mỏng 38px thanh lịch với thanh chỉ thị 1.5px
  futuristicCyberCockpit, // Buồng lái tương lai: vát góc 45 độ, led vạch telemetry công nghệ sci-fi
  balancedFloatingCta, // Thanh dock cân bằng + Nút nổi CTA (Chuẩn Iconly)
}

enum AppSeasonalTheme {
  none, // Tiêu chuẩn / Không kích hoạt
  springTet, // Tết Nguyên Đán & Mùa Xuân (Mai vàng đào đỏ, lộc phát may mắn)
  summerBreeze, // Mùa Hè Rực Rỡ (Biển xanh Aqua, nắng vàng cát mịn)
  autumnAmber, // Mùa Thu Vàng (Lá phong hổ phách, trăng rằm Trung Thu)
  winterChristmas, // Mùa Đông & Giáng Sinh (Bông tuyết pha lê, thông noel, đỏ tuyết tùng)
}

enum AppSystemIconPack {
  lucideMinimal, // Vi sợi tối giản thanh mảnh (Lucide)
  solarCurved, // Bo cong mềm mại hiện đại (Solar)
  cupertinoNative, // Nét tự nhiên chuẩn iOS SF Pro
  materialExpressive, // Hình khối sinh động Material You M3
  phosphorDuotone, // Đổ màu tương phản 2 lớp Duotone
}

enum AppTabSelectStyle {
  pillHighlight, // Viên thuốc sáng phủ trên tab
  glowUnderline, // Vạch neon gạch chân phát sáng
  bounceBadge, // Chấm bi vi chạm tỏa sáng
  filledIcon, // Icon đặc ruột gradient
  neonBorder, // Khung viền neon bao quanh tab
}

enum AppButtonColorMode {
  paletteSync, // Đồng bộ theo Palette nền (Mặc định)
  emeraldWealth, // Xanh Lục Bảo Thịnh Vượng (0xFF10B981)
  oceanicSapphire, // Lam Sapphire Đại Dương (0xFF005FEA)
  amethystRoyal, // Tím Thạch Anh Hoàng Gia (0xFF8B5CF6)
  sunsetCoral, // Cam San Hô Năng Động (0xFFF97316)
  cyberNeonPink, // Hồng Cyberpunk Neon (0xFFEC4899)
  obsidianGold, // Vàng Kim Obsidian VIP (0xFFF59E0B)
  crimsonRuby, // Đỏ Ruby Quyền Lực (0xFFEF4444)
  titaniumIce, // Xanh Băng Bạc Titanium (0xFF06B6D4)
  slateMinimal, // Đen Nhám Stealth Tối Giản (0xFF334155)
  custom, // Màu Tự Do Độc Bản
}

enum AppDockIconStyle {
  modernLucide, // Lucide Line Art Tối Giản Hiện Đại
  appleCupertino, // Apple SF Rounded Bo Cong Bóng Bẩy
  fintechDuotone, // Fintech Duotone 2 Lớp Phân Tầng
  cyberGlow, // Cyberpunk Sci-Fi Neon Glow Phát Quang
  minimalistDot, // Zen Hình Học Tinh Giản
  materialSystem, // Biểu Tượng Material 3 Hệ Thống
}

enum AppButtonStyle {
  modernPill, // Bo cong viên thuốc mềm mại
  glassElevated, // Kính nổi 3D đa tầng phản quang
  sharpTech, // Vát góc sắc nét công nghệ
  flatSubtle, // Phẳng tối giản tinh tế
  gradientGlow, // Gradient chuyển sắc rực rỡ
  outlineHairline, // Viền sợi tóc mảnh tinh xảo
}

enum AppWidgetCardStyle {
  liquidGlassCard, // Thẻ kính lỏng trong suốt phản quang
  solidCleanCard, // Thẻ phẳng chuẩn mực không rườm rà
  elevatedShadowCard, // Thẻ nổi 3D với bóng đổ mềm
  minimalOutlineCard, // Thẻ viền hairline mỏng tinh xảo
  tonalAccentCard, // Thẻ pha màu nền nhẹ theo chủ đề
}

enum AppCategoryIconStyle {
  modernSquircle, // ColorOS Squircle bo cong giọt nước mềm mại 22.5 độ, gradient lụa nước đa sắc
  minimalCircle, // HyperOS Fluid Round tròn phát quang quang học lỏng
  glassSphere, // iOS 18 Glass 3D khối kính nổi phủ sương phản quang
  duotoneTonal, // Fintech Duotone tương phản 2 tầng sắc nét
  neonBadge, // Cyberpunk Sci-Fi Neon Glow viền lục giác phát quang rực rỡ
  paperEmbossed, // Paper Neumorphic dập nổi giấy mờ bóng kép
  minimalOutline, // Minimalist Wireframe vi sợi tối giản hairline 1.5px
  diamondFacet, // Diamond Facet giác cắt kim cương vát góc hoàng gia
}

enum AppLoadingIndicatorStyle {
  liquidRipple, // Sóng ngọc lỏng Aquamorphic (ColorOS 15)
  cyberOrbit, // Quỹ đạo Hologram đa tầng neon (HyperOS / Cyberpunk)
  goldenCoin3D, // Đồng xu FINORA xoay 3D hoàng kim lấp lánh
  glassShimmer, // Dải sáng kính phủ sương quang học (iOS 18)
  infinityDots, // Hạt lượng tử động lượn vô cực
}

enum AppAppBarScrollBehavior {
  pinned, // Luôn ghim cố định trên cùng
  scrollHide, // Tự động ẩn khi vuốt xuống, hiện lại khi vuốt lên
  floating, // Nổi mờ độc lập phía trên nội dung
}

enum AppDockLabelStyle {
  always, // Luôn hiển thị nhãn chữ
  selectedOnly, // Chỉ tab đang chọn
  never, // Chỉ hiện icon tối giản
}

enum AppHeroCardStyle {
  classicFintech, // Finora chuẩn mực với 3-stat subbar
  executiveBlackVip, // Thẻ đen VIP với chip hoàng kim & hạn mức
  minimalistPulse, // Tối giản số dư lớn & nhịp đập tăng trưởng
  liquidEnergySphere, // Kính lỏng với quả cầu năng lượng 3D
  spatialPrismOrbital, // Spatial Prism 3D: Quả cầu tài sản quỹ đạo VisionOS với các ví vệ tinh lơ lửng & halo quang học
  bentoLuxuryDeck, // Bento Luxury Fintech: Thớt thẻ ngân hàng vật lý 3D & Bento nhịp chi tiêu
  netWorthModernDeck, // Net Worth Modern: Chuẩn giao diện quốc tế (Piggy 3D, Thẻ xanh Electric Blue, 5 phím Pastel, Bento kép)
  zenvestGlassDeck, // Zenvest Glass Deck: Chuẩn giao diện thẻ kính mờ lơ lửng, chào mừng tài chính, dãy phím tác vụ & danh sách giao dịch bo tròn kiểu sheet
}

enum AppHeroBalanceSize {
  compact, // Gọn gàng 26px
  standard, // Tiêu chuẩn 32px
  largeEmphasis, // Đại khủng 38px
}

enum AppAvatarGlowStyle {
  goldVip, // Ánh kim Hoàng gia Gold 24K
  cyberCyan, // Neon Cyan công nghệ cao
  royalAmethyst, // Tím Thạch Anh quyền quý
  emeraldCrown, // Ngọc Lục Bảo thịnh vượng
  none, // Mờ tối giản
}

enum AppMembershipTierBadge {
  diamondCrown, // Kim Cương Vương Giả (VIP DIAMOND)
  goldCenturion, // Hiệp Sĩ Hoàng Gia (CENTURION)
  platinumElite, // Tinh Hoa Bạch Kim (ELITE)
}

enum AppAiBubbleStyle {
  duotoneGlass, // Kính đa sắc mờ có ánh sáng lỏng
  cyberTerminal, // Dòng lệnh hacker công nghệ cao
  neumorphicClean, // Dập nổi mềm êm đềm
}

enum AppAiAvatarIcon {
  energyOrb, // Quả cầu trí tuệ đa sắc
  cyberRobot, // Robot tương lai
  hologramSpark, // Chùm sáng phát quang
}

enum AppChartCurveStyle {
  smoothSpline, // Uốn lượn mượt mà Cubic Spline
  straightSharp, // Góc cạnh sắc nét công nghệ
  steppedMatrix, // Bậc thang tài chính
}

enum AppChartAreaFill {
  neonGlow, // Gradient phát quang rực rỡ
  subtleGlass, // Kính mờ dịu mắt
  outlineOnly, // Chỉ kẻ đường viền tối giản
}

enum AppChartColorway {
  paletteSync, // Đồng bộ theo bảng màu hệ thống
  cyberpunkVibrant, // Cyan Neon & Hồng Neon
  emeraldFortune, // Xanh ngọc lục bảo & Vàng ánh kim
  sunsetPastel, // Cam hoàng hôn & Tím oải hương
}

enum AppWallpaperPreset {
  none,
  silkBlue, // Lụa xanh biếc (Silk Wave)
  midnightDark, // Bầu trời đêm carbon ánh sao (Midnight)
  skyCyan, // Thiên thanh tươi sáng (Sky Cyan)
  metallicFrost, // Băng tuyết ánh bạc (Metallic Frost)
  auroraStream, // Dòng chảy cực quang xanh (Aurora Stream)
  customGradient, // Nền Gradient tự pha chuyển màu đa tầng
}

enum AppCardSkinStyle {
  brandClassic, // Nhận diện theo thương hiệu ngân hàng
  goldMetallic, // Hoàng gia Vàng kim Gold Metallic
  carbonObsidian, // Sợi Carbon đen bóng sang trọng
  diamondHologram, // Pha lê óng ánh cầu vồng Hologram
  deepOcean, // Xanh thẳm đại dương Deep Ocean
  emeraldJade, // Ngọc bích thượng lưu Emerald Jade
  roseGoldRuby, // Vàng hồng Ruby quý phái
  cyberNeon, // Tím điện tử công nghệ Cyberpunk
  titaniumFrost, // Titan bạc băng giá tối giản
  whiteCeramic, // Gốm sứ trắng tinh khiết Apple Card
  cyberGlass, // Kính mờ Cyberpunk vi mạch đồng phát quang
  customGradient, // Tự do pha màu thẻ riêng
}

class CardSkinMeta {
  final AppCardSkinStyle style;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final IconData icon;

  const CardSkinMeta({
    required this.style,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.icon,
  });

  LinearGradient get gradient => LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

enum AppHeroCardTint {
  paletteSync, // Đồng bộ với Palette chủ đề đang chọn
  deepCosmic, // Vũ trụ huyền bí Tím đen (Cosmic Amethyst)
  emeraldGlow, // Hào quang Lục bảo (Emerald Glow)
  rubySunset, // Hoàng hôn Đỏ Ruby (Ruby Sunset)
  cyberPulse, // Xung điện Cyberpunk (Cyan & Pink)
  frostWhite, // Kính tuyết trắng Bắc cực (Frost White)
  pitchAmoled, // Đen tuyền AMOLED sâu thẳm
}

enum AppStatsCardTint {
  paletteSync, // Đồng bộ theo Theme Palette
  frostedGlass, // Kính mờ xuyên thấu phân màu
  neonAccent, // Đèn viền Neon phát quang rực rỡ
  monochrome, // Đơn sắc tối giản sang trọng
}

enum AppPrivacyStyle {
  dots, // Dấu chấm tròn ••••••••
  glassBlur, // Kính mờ phủ sương Liquid Frosted Glass
}

enum DashboardModuleId {
  heroCard, // Tổng tài sản & dòng tiền
  quickActions, // 4 nút tác vụ nhanh
  aiQuickLog, // Thanh ghi chép nhanh AI
  aiHealthScore, // Sức khỏe tài chính Finora AI
  budgetProgress, // Ngân sách & hạn mức chi tiêu
  walletsAccounts, // Ví & Tài khoản ngân hàng
  investmentsAssets, // Tài sản & Đầu tư
  loansDebts, // Cho vay & Sổ nợ
  recentTransactions, // Giao dịch gần đây
}

class DashboardModuleMeta {
  final DashboardModuleId id;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;

  const DashboardModuleMeta({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
  });
}

class WallpaperMeta {
  final AppWallpaperPreset preset;
  final String title;
  final String subtitle;
  final String? assetPath;

  const WallpaperMeta({
    required this.preset,
    required this.title,
    required this.subtitle,
    required this.assetPath,
  });
}

class AmbientBlurMeta {
  final AmbientBlurPreset preset;
  final String title;
  final String subtitle;
  final List<Color> bgColorsDark;
  final List<Color> bgColorsLight;
  final Color orb1;
  final Color orb2;
  final Color orb3;
  final Color orb4;

  const AmbientBlurMeta({
    required this.preset,
    required this.title,
    required this.subtitle,
    required this.bgColorsDark,
    required this.bgColorsLight,
    required this.orb1,
    required this.orb2,
    required this.orb3,
    required this.orb4,
  });
}

enum CardDensity {
  compact,
  standard,
  spacious,
}

enum CardSurfaceStyle {
  liquidGlass,
  solidModern,
  cyberGradient,
}

enum CardCornerStyle { subtle, rounded, extraRounded, sharp, pillUltra }

enum CardShadowIntensity { none, soft, elevated }

enum AppButtonShape {
  pill,
  squircle,
  rounded,
}

enum AppButtonSize {
  compact,
  standard,
  comfortable,
}

enum AppIconStyle {
  round,
  softSquare,
  dimensional,
  glassGlow,
  neumorphicSoft,
  cyberNeonWireframe,
  jewelCrystal,
  duotoneGlass,
}

enum AppIconShape {
  circle, // Tròn cổ điển hoàn hảo
  squircle, // Vuông siêu bo cong M3 / Apple
  roundedSquare, // Vuông bo góc dứt khoát
  teardrop, // Giọt nước nghiêng nghệ thuật
  hexagon, // Lục giác công nghệ Cyber
  diamond, // Hình thoi sắc sảo
  shield, // Khiên bảo mật tài chính
  chamferedOctagon, // Bát giác vát góc công nghệ
  capsule, // Viên nhộng ngang mềm mại
}

enum AppIconVisualEffect {
  flatMinimal, // Phẳng tối giản tinh tế (Google M3)
  liquidGlass, // 3D Kính lỏng phát quang
  neumorphicSoft, // Neumorphic dập nổi mềm mại
  cyberNeon, // Viền Neon phát sáng rực rỡ
  duotoneGlass, // Kính Duotone 2 lớp tương phản
  jewelCrystal, // Pha lê đá quý lấp lánh
  gradientFlow, // Gradient ánh sáng chuyển sắc
  outlineMinimal, // Viền mảnh thanh lịch Wireframe
}

enum AppIconBgColorMode {
  categoryOriginal, // Màu chuẩn theo từng danh mục
  paletteAccent, // Nền pha theo Palette chủ đạo (Dynamic)
  glassMonochrome, // Kính mờ đơn sắc trung tính
  vibrantRich, // Siêu rực rỡ bão hòa
  obsidianDark, // Than đen Obsidian huyền bí
  frostedWhite, // Trắng tuyết tinh khôi
  goldenAmber, // Vàng hổ phách hoàng kim
  cyberNeon, // Xanh neon phát quang điện tử
  emeraldGlow, // Ngọc lục bảo phát sáng
  rubySunset, // Đỏ ruby hoàng hôn
}

enum AppIconGlyphColorMode {
  autoContrast, // Tương phản thông minh (Trắng trên nền tối, Đen/Đậm trên nền sáng)
  pureWhite, // Trắng tinh khiết chuẩn iOS Glass (#FFFFFF)
  obsidianDark, // Đen tuyền than Obsidian (#0F172A)
  paletteAccent, // Đồng bộ màu nhấn Palette chủ đạo
  categoryOriginal, // Giữ màu gốc của danh mục
  goldLuxury, // Vàng Hoàng Gia Champagne (#F59E0B)
  cyberNeon, // Xanh ngọc huỳnh quang Neon (#06B6D4)
  neonPink, // Hồng dạ quang Cyberpunk (#EC4899)
}

enum AppBudgetStyle {
  liquidBar, // Thanh năng lượng Liquid Bar neon bo tròn
  speedometerGauge, // Vòng đồng hồ đo bán nguyệt Speedometer
  minimalCapsule, // Viên nang tối giản tích lũy
}

enum AppGoalStyle {
  treasureChest, // Hũ vàng phong thủy thịnh vượng
  growingTree, // Cây tài chính lớn dần
  batteryCharge, // Pin năng lượng sạc đầy
}

enum AppHapticIntensity {
  subtle, // Rung vi chạm êm ái
  crisp, // Rung sắc nét tiêu chuẩn
  heavy, // Rung đầm tay dứt khoát
}

enum AppTransactionSound {
  none, // Tắt âm thanh (im lặng)
  ting, // Tiếng ting tiền về ngân hàng
  kaching, // Tiếng máy đếm tiền cổ điển
  waterdrop, // Tiếng giọt nước thanh tịnh
}

enum AppTransactionListStyle {
  timelineRail, // Đường ray thời gian liên tục
  bentoCards, // Nhóm theo thẻ kính Bento theo ngày
  compactTable, // Bảng kê sao kê ngân hàng siêu gọn
  minimalDivided, // Tối giản gạch ngang phẳng M3
  modernStreamlined, // Thẻ bo tròn siêu mịn, phân đoạn kính mờ, icon danh mục nổi bật kèm status pill
  magazineLedger, // Sổ cái tạp chí tài chính thanh lịch với mốc thời gian, typography tinh tế
}

enum AppWalletViewStyle {
  stackedDeck, // Xếp chồng thẻ 3D lướt tay
  verticalList, // Danh sách thẻ dọc trực quan chi tiết
  gridBento, // Lưới thẻ đôi Bento hiện đại 2 cột
  compactList, // Bảng kê số dư ngân hàng rút gọn
  webCards, // Thẻ ngân hàng đồng nhất web
}

enum AppTopBarStyle {
  seamlessBlend, // Hòa quyện nền tự nhiên (ambient mesh gradient, triệt tiêu hoàn toàn mảng trắng đục)
  frostedGlass, // Kính mờ Liquid Glass nghệ thuật
  floatingIsland, // Đảo nổi HyperOS lơ lửng tách rời mép màn hình
  pureMinimal, // Tối giản trong suốt hoàn toàn, thanh lịch
}

enum MeshBlendStyle {
  radialMesh, // Tản sắc Đa điểm (Apple Fluid Mesh)
  auroraWave, // Dải sáng Cực quang (Aurora Waves)
  linearFlow, // Dòng chảy Chéo góc (Diagonal Flow)
  centerAura, // Hào quang Trọng tâm (Center Glow Aura)
  prismaticFusion, // Giao thoa Lăng kính (Prismatic Fusion)
}

class PaletteMeta {
  final AppColorPalette palette;
  final String title;
  final String subtitle;
  final Color primary;
  final Color secondary;
  final Color lightBg;
  final Color darkBg;
  final List<Color> heroGradient;
  final bool isCustom;
  final String? customId;

  const PaletteMeta({
    required this.palette,
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.secondary,
    required this.lightBg,
    required this.darkBg,
    required this.heroGradient,
    this.isCustom = false,
    this.customId,
  });
}

enum AppMasterUiPreset {
  cyberpunk2077,
  royalCenturion,
  visionLiquidGlass,
  emeraldFortune,
  swissMinimalist,
  sunsetRetroWave,
  googleMaterialYou,
  colorOsAquamorphic,
  hyperOsAlive,
  ledgerEditorial,
  softPaper,
  industrialUtility,
  organicClay,
  einkFocus,
  artDecoFinance,
  springTetMaster,
  summerBreezeMaster,
  autumnAmberMaster,
  winterChristmasMaster,
}

class MasterUiPresetMeta {
  final AppMasterUiPreset preset;
  final String title;
  final String subtitle;
  final String tag;
  final IconData icon;
  final List<Color> gradientColors;
  final AppColorPalette palette;
  final AppUiUxStyle uiUxStyle;
  final AppWallpaperPreset wallpaper;
  final AppIconStyle iconStyle;
  final AppHeroCardStyle heroCardStyle;
  final AppDockNavStyle dockNavStyle;
  final AppDockLabelStyle dockLabelStyle;
  final AppAvatarGlowStyle avatarGlow;
  final AppMembershipTierBadge membershipTier;
  final AppAiBubbleStyle aiBubbleStyle;
  final AppAiAvatarIcon aiAvatarIcon;
  final AppChartCurveStyle chartCurveStyle;
  final AppChartAreaFill chartAreaFill;
  final AppChartColorway chartColorway;
  final AppCardSkinStyle cardSkin;
  final CardCornerStyle cornerStyle;
  final AppIconShape? iconShape;
  final AppIconVisualEffect? iconVisualEffect;
  final AmbientBlurPreset? ambientBlur;
  final AppFontFamily? fontFamily;
  final CardDensity? density;
  final AppButtonShape? buttonShape;
  final AppMotionDynamics? motion;
  final CardBorderGlowStyle? borderGlow;
  final double? glassOpacity;
  final double? glassBlur;
  final bool? particleSparkles;
  final AppSeasonalTheme? seasonalTheme;

  const MasterUiPresetMeta({
    required this.preset,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.icon,
    required this.gradientColors,
    required this.palette,
    required this.uiUxStyle,
    required this.wallpaper,
    required this.iconStyle,
    required this.heroCardStyle,
    required this.dockNavStyle,
    required this.dockLabelStyle,
    required this.avatarGlow,
    required this.membershipTier,
    required this.aiBubbleStyle,
    required this.aiAvatarIcon,
    required this.chartCurveStyle,
    required this.chartAreaFill,
    required this.chartColorway,
    required this.cardSkin,
    required this.cornerStyle,
    this.iconShape,
    this.iconVisualEffect,
    this.ambientBlur,
    this.fontFamily,
    this.density,
    this.buttonShape,
    this.motion,
    this.borderGlow,
    this.glassOpacity,
    this.glassBlur,
    this.particleSparkles,
    this.seasonalTheme,
  });
}

class CuratedCommunityThemePreset {
  final String id;
  final String title;
  final String subtitle;
  final String author;
  final String downloads;
  final double rating;
  final List<String> tags;
  final List<Color> gradientColors;
  final AppColorPalette palette;
  final AppFontFamily fontFamily;
  final AppHeroCardStyle heroCardStyle;
  final AppDockNavStyle dockNavStyle;
  final AppCategoryIconStyle categoryIconStyle;
  final AppButtonStyle buttonVisualKind;
  final AppLoadingIndicatorStyle loadingStyle;
  final double cardRadius;
  final double buttonRadius;
  final AmbientBlurPreset ambientBlur;
  final bool highRefreshRate120Hz;

  const CuratedCommunityThemePreset({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.author,
    required this.downloads,
    required this.rating,
    required this.tags,
    required this.gradientColors,
    required this.palette,
    required this.fontFamily,
    required this.heroCardStyle,
    required this.dockNavStyle,
    required this.categoryIconStyle,
    required this.buttonVisualKind,
    required this.loadingStyle,
    required this.cardRadius,
    required this.buttonRadius,
    required this.ambientBlur,
    this.highRefreshRate120Hz = true,
  });
}

class ThemeStudioController extends ChangeNotifier {
  bool _freshAppearance = false;
  bool get freshAppearance => _freshAppearance;
  Future<void> setFreshAppearance(bool value) async {
    _freshAppearance = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('finora_fresh_appearance_v1', value);
  }

  static const _paletteKey = 'finora_studio_palette';
  static const _ambientBlurKey = 'finora_studio_ambient_blur';
  static const _densityKey = 'finora_studio_density';
  static const _surfaceKey = 'finora_studio_surface';
  static const _cornerKey = 'finora_studio_corner';
  static const _shadowKey = 'finora_studio_shadow';
  static const _txDensityKey = 'finora_studio_tx_density';
  static const _dashDensityKey = 'finora_studio_dash_density';
  static const _showAiInsightKey = 'finora_studio_show_ai_insight';
  static const _showQuickLogKey = 'finora_studio_show_quick_log';
  static const _glassOpacityKey = 'finora_studio_glass_opacity';
  static const _glassBlurKey = 'finora_studio_glass_blur';
  static const _buttonShapeKey = 'finora_studio_button_shape';
  static const _iconStyleKey = 'finora_studio_icon_style';
  static const _iconShapeKey = 'finora_studio_icon_shape';
  static const _iconVisualEffectKey = 'finora_studio_icon_visual_effect';
  static const _buttonSizeKey = 'finora_studio_button_size';
  static const _fontScaleKey = 'finora_studio_font_scale';
  static const _uiUxStyleKey = 'finora_studio_ui_ux_style';
  static const _gradientVibrancyKey = 'finora_studio_gradient_vibrancy';
  static const _fontFamilyKey = 'finora_studio_font_family';
  static const _borderGlowKey = 'finora_studio_border_glow';
  static const _motionKey = 'finora_studio_motion';
  static const _hapticKey = 'finora_studio_haptic';
  static const _privacyKey = 'finora_studio_privacy';
  static const _privacyStyleKey = 'finora_studio_privacy_style';
  static const _dashboardOrderKey = 'finora_studio_dashboard_order';
  static const _dashboardDisabledKey = 'finora_studio_dashboard_disabled';
  static const _currencyKey = 'finora_studio_currency';
  static const _dockNavKey = 'finora_studio_dock_nav';
  static const _wallpaperKey = 'finora_studio_wallpaper';
  static const _ambientIntensityKey = 'finora_studio_ambient_intensity';
  static const _particleSparklesKey = 'finora_studio_particle_sparkles';
  static const _budgetStyleKey = 'finora_studio_budget_style';
  static const _goalStyleKey = 'finora_studio_goal_style';
  static const _hapticIntensityKey = 'finora_studio_haptic_intensity';
  static const _transactionSoundKey = 'finora_studio_transaction_sound';
  static const _transactionListStyleKey =
      'finora_studio_transaction_list_style';
  static const _pageHorizontalMarginKey =
      'finora_studio_page_horizontal_margin';
  static const _customPalettesKey = 'finora_studio_custom_palettes';
  static const _selectedCustomPaletteIdKey =
      'finora_studio_selected_custom_palette_id';
  static const _globalCardSkinKey = 'finora_studio_global_card_skin';
  static const _walletCardSkinsKey = 'finora_studio_wallet_card_skins';
  static const _customCardGradientKey = 'finora_studio_custom_card_gradient';
  static const _heroCardTintKey = 'finora_studio_hero_card_tint';
  static const _statsCardTintKey = 'finora_studio_stats_card_tint';
  static const _expenseColorKey = 'finora_studio_expense_color';
  static const _incomeColorKey = 'finora_studio_income_color';
  static const _transferColorKey = 'finora_studio_transfer_color';
  static const _budgetSafeColorKey = 'finora_studio_budget_safe_color';
  static const _budgetWarningColorKey = 'finora_studio_budget_warning_color';
  static const _budgetDangerColorKey = 'finora_studio_budget_danger_color';
  static const _customBgGradientKey = 'finora_studio_custom_bg_gradient';
  static const _customBgGradientAngleKey =
      'finora_studio_custom_bg_gradient_angle';
  static const _dockLabelStyleKey = 'finora_studio_dock_label_style';
  static const _heroCardStyleKey = 'finora_studio_hero_card_style';
  static const _heroBalanceSizeKey = 'finora_studio_hero_balance_size';
  static const _avatarGlowStyleKey = 'finora_studio_avatar_glow_style';
  static const _membershipTierKey = 'finora_studio_membership_tier';
  static const _aiBubbleStyleKey = 'finora_studio_ai_bubble_style';
  static const _aiAvatarIconKey = 'finora_studio_ai_avatar_icon';
  static const _chartCurveStyleKey = 'finora_studio_chart_curve_style';
  static const _chartAreaFillKey = 'finora_studio_chart_area_fill';
  static const _chartColorwayKey = 'finora_studio_chart_colorway';
  static const _appBarOpacityKey = 'finora_studio_app_bar_opacity';
  static const _appBarBlurKey = 'finora_studio_app_bar_blur';
  static const _appBarShowBorderKey = 'finora_studio_app_bar_show_border';
  static const _topBarStyleKey = 'finora_studio_top_bar_style';
  static const _pinHeaderKey = 'finora_studio_pin_header';
  static const _walletViewStyleKey = 'finora_studio_wallet_view_style';
  static const _seasonalThemeKey = 'finora_studio_seasonal_theme';
  static const _systemIconPackKey = 'finora_studio_system_icon_pack';
  static const _tabSelectStyleKey = 'finora_studio_tab_select_style';
  static const _buttonVisualKindKey = 'finora_studio_button_visual_kind';
  static const _buttonColorModeKey = 'finora_studio_button_color_mode';
  static const _customButtonColorKey = 'finora_studio_custom_button_color';
  static const _dockIconStyleKey = 'finora_studio_dock_icon_style';
  static const _widgetCardStyleKey = 'finora_studio_widget_card_style';
  static const _categoryIconStyleKey = 'finora_studio_category_icon_style';
  static const _appBarScrollBehaviorKey =
      'finora_studio_app_bar_scroll_behavior';
  static const _highRefreshRate120HzKey = 'finora_studio_120hz';
  static const _iconBgColorModeKey = 'finora_studio_icon_bg_color_mode';
  static const _iconGlyphColorModeKey = 'finora_studio_icon_glyph_color_mode';
  static const _iconBgOpacityKey = 'finora_studio_icon_bg_opacity';
  static const _lockedComponentsKey = 'finora_studio_locked_components';
  static const _customUserPresetsKey = 'finora_studio_custom_user_presets';
  static const _widgetBorderWidthKey = 'finora_studio_widget_border_width';
  static const _customCardCornerRadiusKey =
      'finora_studio_custom_card_corner_radius';
  static const _customButtonCornerRadiusKey =
      'finora_studio_custom_button_corner_radius';
  static const _pageVerticalGapKey = 'finora_studio_page_vertical_gap';
  static const _dockHeightScaleKey = 'finora_studio_dock_height_scale';
  static const _dockOpacityKey = 'finora_studio_dock_opacity';
  static const _dockBlurKey = 'finora_studio_dock_blur';
  static const _dockActiveColorKey = 'finora_studio_dock_active_color';
  static const _dockInactiveColorKey = 'finora_studio_dock_inactive_color';
  static const _dockPlusColorKey = 'finora_studio_dock_plus_color';
  static const _chartHeightScaleKey = 'finora_studio_chart_height_scale';
  static const _chartShowAreaFillKey = 'finora_studio_chart_show_area_fill';
  static const _chartShowGridLinesKey = 'finora_studio_chart_show_grid_lines';
  static const _chartSmoothnessKey = 'finora_studio_chart_smoothness';
  static const _iconScaleKey = 'finora_studio_icon_scale';
  static const _iconCornerRadiusKey = 'finora_studio_icon_corner_radius';
  static const _iconLabelScaleKey = 'finora_studio_icon_label_scale';
  static const _backgroundTintOpacityKey = 'finora_studio_bg_tint_opacity';
  static const _loadingStyleKey = 'finora_studio_loading_style';
  static const _systemWideLiquidGlassKey =
      'finora_studio_system_wide_liquid_glass';
  static const _liquidGlassSpecularHighlightKey =
      'finora_studio_liquid_specular';
  static const _liquidGlassCausticRefractionKey =
      'finora_studio_liquid_caustic';
  static const _useCustomRgbMeshBgKey = 'finora_studio_use_custom_rgb_mesh_bg';
  static const _customBgColor1Key = 'finora_studio_custom_bg_color1';
  static const _customBgColor2Key = 'finora_studio_custom_bg_color2';
  static const _husbandAvatarKey = 'finora_husband_avatar';
  static const _wifeAvatarKey = 'finora_wife_avatar';
  static const _jointFamilyAvatarKey = 'finora_joint_family_avatar';

  String? _husbandAvatar;
  String? _wifeAvatar;
  String? _jointFamilyAvatar;
  String? get husbandAvatar => _husbandAvatar;
  String? get wifeAvatar => _wifeAvatar;
  String? get jointFamilyAvatar => _jointFamilyAvatar;

  Future<void> setHusbandAvatar(String? value) async {
    final clean = value?.trim();
    _husbandAvatar = (clean == null || clean.isEmpty) ? null : clean;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_husbandAvatar == null) {
        await prefs.remove(_husbandAvatarKey);
      } else {
        await prefs.setString(_husbandAvatarKey, _husbandAvatar!);
      }
    } catch (_) {}
  }

  Future<void> setWifeAvatar(String? value) async {
    final clean = value?.trim();
    _wifeAvatar = (clean == null || clean.isEmpty) ? null : clean;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_wifeAvatar == null) {
        await prefs.remove(_wifeAvatarKey);
      } else {
        await prefs.setString(_wifeAvatarKey, _wifeAvatar!);
      }
    } catch (_) {}
  }

  Future<void> setJointFamilyAvatar(String? value) async {
    final clean = value?.trim();
    _jointFamilyAvatar = (clean == null || clean.isEmpty) ? null : clean;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_jointFamilyAvatar == null) {
        await prefs.remove(_jointFamilyAvatarKey);
      } else {
        await prefs.setString(_jointFamilyAvatarKey, _jointFamilyAvatar!);
      }
    } catch (_) {}
  }
  static const _customBgColor3Key = 'finora_studio_custom_bg_color3';
  static const _customBgIntensityKey = 'finora_studio_custom_bg_intensity';
  static const _customBgBlurKey = 'finora_studio_custom_bg_blur';
  static const _meshBlendStyleKey = 'finora_studio_mesh_blend_style';

  static const List<CardSkinMeta> allCardSkins = [
    CardSkinMeta(
      style: AppCardSkinStyle.brandClassic,
      title: 'Màu Ngân Hàng',
      subtitle: 'Tự động theo chuẩn Vietcombank, Techcombank, MB...',
      colors: [Color(0xFF0F63A1), Color(0xFF0B7CBE), Color(0xFF22ACEB)],
      icon: Icons.account_balance_rounded,
    ),
    CardSkinMeta(
      style: AppCardSkinStyle.goldMetallic,
      title: 'Vàng Kim Hoàng Gia',
      subtitle: 'Gold Metallic dập nổi ánh kim vương giả',
      colors: [Color(0xFF6B4E12), Color(0xFFC5A038), Color(0xFF4A380A)],
      icon: Icons.workspace_premium_rounded,
    ),
    CardSkinMeta(
      style: AppCardSkinStyle.carbonObsidian,
      title: 'Sợi Carbon Đen',
      subtitle: 'Carbon Fiber đen bóng tối thượng',
      colors: [Color(0xFF1E2128), Color(0xFF2E3440), Color(0xFF0F1115)],
      icon: Icons.shield_rounded,
    ),
    CardSkinMeta(
      style: AppCardSkinStyle.diamondHologram,
      title: 'Pha Lê Hologram',
      subtitle: 'Cầu vồng quang học đa sắc tương lai',
      colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFDB2777)],
      icon: Icons.auto_awesome_rounded,
    ),
    CardSkinMeta(
      style: AppCardSkinStyle.deepOcean,
      title: 'Đại Dương Xanh Thẳm',
      subtitle: 'Deep Ocean xanh thẫm quyền lực',
      colors: [Color(0xFF0B3B60), Color(0xFF0D5C75), Color(0xFF1B8A8A)],
      icon: Icons.water_rounded,
    ),
    CardSkinMeta(
      style: AppCardSkinStyle.emeraldJade,
      title: 'Ngọc Bích Thượng Lưu',
      subtitle: 'Emerald Jade ngọc xanh may mắn trường thọ',
      colors: [Color(0xFF064E3B), Color(0xFF059669), Color(0xFF047857)],
      icon: Icons.diamond_rounded,
    ),
    CardSkinMeta(
      style: AppCardSkinStyle.roseGoldRuby,
      title: 'Vàng Hồng Ruby',
      subtitle: 'Rose Gold & Ruby quý phái tinh tế',
      colors: [Color(0xFF701A75), Color(0xFFBE185D), Color(0xFF9F1239)],
      icon: Icons.favorite_rounded,
    ),
    CardSkinMeta(
      style: AppCardSkinStyle.cyberNeon,
      title: 'Cyberpunk Neon',
      subtitle: 'Tím hồng kỹ thuật số viễn tưởng 2077',
      colors: [Color(0xFF4A044E), Color(0xFF86198F), Color(0xFF0284C7)],
      icon: Icons.bolt_rounded,
    ),
    CardSkinMeta(
      style: AppCardSkinStyle.titaniumFrost,
      title: 'Titanium Băng Giá',
      subtitle: 'Titan xám bạc tối giản hiện đại',
      colors: [Color(0xFF334155), Color(0xFF64748B), Color(0xFF475569)],
      icon: Icons.layers_rounded,
    ),
    CardSkinMeta(
      style: AppCardSkinStyle.whiteCeramic,
      title: 'Gốm Sứ Apple Card',
      subtitle: 'Trắng sứ mờ tinh khiết dập chìm sang trọng',
      colors: [Color(0xFFE2E8F0), Color(0xFFF8FAFC), Color(0xFFCBD5E1)],
      icon: Icons.credit_card_rounded,
    ),
    CardSkinMeta(
      style: AppCardSkinStyle.cyberGlass,
      title: 'Kính Vi Mạch Cyber',
      subtitle: 'Kính mờ bán trong suốt đường mạch đồng neon',
      colors: [Color(0xFF0F172A), Color(0xFF0284C7), Color(0xFF0D9488)],
      icon: Icons.memory_rounded,
    ),
  ];

  static const List<DashboardModuleMeta> allDashboardModules = [
    DashboardModuleMeta(
      id: DashboardModuleId.heroCard,
      title: 'Tổng tài sản & Dòng tiền',
      description: 'Số dư ròng, thu vào, chi ra & dòng tiền tháng',
      icon: Icons.account_balance_rounded,
      accentColor: Color(0xFF005FEA),
    ),
    DashboardModuleMeta(
      id: DashboardModuleId.quickActions,
      title: 'Thao tác nhanh',
      description: '4 phím tắt: Ghi chép, Ví & thẻ, Báo cáo, Trợ lý AI',
      icon: Icons.grid_view_rounded,
      accentColor: Color(0xFF38BDF8),
    ),
    DashboardModuleMeta(
      id: DashboardModuleId.aiQuickLog,
      title: 'Thanh ghi chép nhanh AI',
      description: 'Nhập liệu giao dịch 1 chạm bằng giọng nói/AI',
      icon: Icons.bolt_rounded,
      accentColor: Color(0xFF10B981),
    ),
    DashboardModuleMeta(
      id: DashboardModuleId.aiHealthScore,
      title: 'Sức khỏe tài chính Finora AI',
      description: 'Chỉ số an toàn, tỷ lệ tích lũy và quỹ khẩn cấp',
      icon: Icons.health_and_safety_rounded,
      accentColor: Color(0xFF059669),
    ),
    DashboardModuleMeta(
      id: DashboardModuleId.budgetProgress,
      title: 'Ngân sách chi tiêu',
      description: 'Hạn mức chi tiêu và tiến độ ngân sách trong tháng',
      icon: Icons.pie_chart_outline_rounded,
      accentColor: Color(0xFFEA580C),
    ),
    DashboardModuleMeta(
      id: DashboardModuleId.walletsAccounts,
      title: 'Ví & Tài khoản ngân hàng',
      description: 'Danh sách thẻ ATM, thẻ tín dụng và tiền mặt',
      icon: Icons.account_balance_wallet_rounded,
      accentColor: Color(0xFF0284C7),
    ),
    DashboardModuleMeta(
      id: DashboardModuleId.investmentsAssets,
      title: 'Tài sản & Đầu tư',
      description: 'Vàng, Bất động sản, Cổ phiếu & Tiết kiệm',
      icon: Icons.trending_up_rounded,
      accentColor: Color(0xFF0D9488),
    ),
    DashboardModuleMeta(
      id: DashboardModuleId.loansDebts,
      title: 'Cho vay & Sổ nợ',
      description: 'Theo dõi tiền cho vay, nợ phải trả và đối soát',
      icon: Icons.handshake_rounded,
      accentColor: Color(0xFFD97706),
    ),
    DashboardModuleMeta(
      id: DashboardModuleId.recentTransactions,
      title: 'Nhật ký giao dịch gần đây',
      description: 'Lịch sử thu chi chi tiết mới nhất',
      icon: Icons.receipt_long_rounded,
      accentColor: Color(0xFF8B5CF6),
    ),
  ];

  static const List<DashboardModuleId> defaultDashboardOrder = [
    DashboardModuleId.heroCard,
    DashboardModuleId.quickActions,
    DashboardModuleId.aiQuickLog,
    DashboardModuleId.aiHealthScore,
    DashboardModuleId.recentTransactions,
    DashboardModuleId.budgetProgress,
    DashboardModuleId.walletsAccounts,
    DashboardModuleId.investmentsAssets,
    DashboardModuleId.loansDebts,
  ];

  AppColorPalette _palette = AppColorPalette.emeraldWealth;
  AmbientBlurPreset _ambientBlur = AmbientBlurPreset.emeraldMatrix;
  AppWallpaperPreset _wallpaperPreset = AppWallpaperPreset.none;
  CardDensity _globalDensity = CardDensity.standard;
  CardDensity _dashboardDensity = CardDensity.standard;
  CardDensity _transactionDensity = CardDensity.compact;
  CardSurfaceStyle _surfaceStyle = CardSurfaceStyle.liquidGlass;
  CardCornerStyle _cornerStyle = CardCornerStyle.rounded;
  CardShadowIntensity _shadowIntensity = CardShadowIntensity.soft;
  bool _showAiInsight = true;
  bool _showQuickLog = true;
  double _glassOpacity = 0.88;
  double _glassBlur = 20.0;
  double _pageHorizontalMargin = 16.0;
  AppButtonShape _buttonShape = AppButtonShape.pill;
  AppIconStyle _iconStyle = AppIconStyle.round;
  AppIconShape _iconShape = AppIconShape.squircle;
  AppIconVisualEffect _iconVisualEffect = AppIconVisualEffect.flatMinimal;
  AppButtonSize _buttonSize = AppButtonSize.standard;
  double _fontScale = 1.0;
  AppUiUxStyle _uiUxStyle = AppUiUxStyle.cupertinoMinimal;
  double _gradientVibrancy = 1.0;
  AppFontFamily _fontFamily = AppFontFamily.beVietnamPro;
  CardBorderGlowStyle _borderGlowStyle = CardBorderGlowStyle.subtleHairline;
  AppMotionDynamics _motionDynamics = AppMotionDynamics.smoothGentle;
  bool _hapticEnabled = true;
  bool _privacyShieldDefault = false;
  AppPrivacyStyle _privacyStyle = AppPrivacyStyle.dots;
  bool _isPrivacyShieldActive = false;
  List<DashboardModuleId> _dashboardOrder = List.from(defaultDashboardOrder);
  Set<DashboardModuleId> _disabledDashboardModules = {
    DashboardModuleId.walletsAccounts,
    DashboardModuleId.investmentsAssets,
    DashboardModuleId.loansDebts,
    DashboardModuleId.budgetProgress,
  };
  AppCurrencyFormat _currencyFormat = AppCurrencyFormat.symbolSuffix;
  AppDockNavStyle _dockNavStyle = AppDockNavStyle.balancedFloatingCta;
  double _ambientIntensity = 0.0;
  bool _particleSparkles = false;
  AppBudgetStyle _budgetStyle = AppBudgetStyle.liquidBar;
  AppGoalStyle _goalStyle = AppGoalStyle.treasureChest;
  AppHapticIntensity _hapticIntensity = AppHapticIntensity.crisp;
  AppTransactionSound _transactionSound = AppTransactionSound.ting;
  AppTransactionListStyle _transactionListStyle =
      AppTransactionListStyle.timelineRail;
  List<PaletteMeta> _customPalettes = [];
  String? _selectedCustomPaletteId;
  AppCardSkinStyle _globalCardSkin = AppCardSkinStyle.brandClassic;
  bool _preserveBankCardColors = true;
  Map<String, String> _walletCardSkins = {};
  List<Color> _customCardGradientColors = [
    const Color(0xFF6366F1),
    const Color(0xFFA855F7),
    const Color(0xFFEC4899)
  ];
  AppHeroCardTint _heroCardTint = AppHeroCardTint.paletteSync;
  AppStatsCardTint _statsCardTint = AppStatsCardTint.paletteSync;
  Color _expenseColor = const Color(0xFFEF4444);
  Color _incomeColor = const Color(0xFF10B981);
  Color _transferColor = const Color(0xFF3B82F6);
  Color _budgetSafeColor = const Color(0xFF10B981);
  Color _budgetWarningColor = const Color(0xFFF59E0B);
  Color _budgetDangerColor = const Color(0xFFEF4444);
  List<Color> _customBgGradientColors = [
    const Color(0xFF0F172A),
    const Color(0xFF1E1B4B),
    const Color(0xFF312E81)
  ];
  List<Color> _customBgGradientColorsLight = [
    const Color(0xFFF8FAFC),
    const Color(0xFFF1F5F9),
    const Color(0xFFE2E8F0)
  ];
  int _customBgGradientAngle = 0;
  bool _useCustomBgGradient = false;
  double _backgroundTintOpacity = 0.85;
  double _backgroundBlurSigma = 35.0;
  bool _useCustomRgbMeshBg = false;
  Color _customBgColor1 = const Color(0xFF10B981);
  Color _customBgColor2 = const Color(0xFF0284C7);
  Color _customBgColor3 = const Color(0xFF8B5CF6);
  double _customBgIntensity = 0.18;
  double _customBgBlur = 65.0;
  MeshBlendStyle _meshBlendStyle = MeshBlendStyle.radialMesh;
  AppDockLabelStyle _dockLabelStyle = AppDockLabelStyle.always;
  AppHeroCardStyle _heroCardStyle = AppHeroCardStyle.zenvestGlassDeck;
  AppHeroBalanceSize _heroBalanceSize = AppHeroBalanceSize.standard;
  AppAvatarGlowStyle _avatarGlowStyle = AppAvatarGlowStyle.goldVip;
  AppMembershipTierBadge _membershipTier = AppMembershipTierBadge.diamondCrown;
  AppAiBubbleStyle _aiBubbleStyle = AppAiBubbleStyle.neumorphicClean;
  AppAiAvatarIcon _aiAvatarIcon = AppAiAvatarIcon.energyOrb;
  AppChartCurveStyle _chartCurveStyle = AppChartCurveStyle.smoothSpline;
  AppChartAreaFill _chartAreaFill = AppChartAreaFill.neonGlow;
  AppChartColorway _chartColorway = AppChartColorway.paletteSync;
  double _appBarOpacity = 1.0;
  double _appBarBlur = 0.0;
  bool _appBarShowBorder = true;
  AppTopBarStyle _topBarStyle = AppTopBarStyle.seamlessBlend;
  bool _pinHeader = true;
  AppWalletViewStyle _walletViewStyle = AppWalletViewStyle.webCards;
  AppSeasonalTheme _seasonalTheme = AppSeasonalTheme.none;
  AppSystemIconPack _systemIconPack = AppSystemIconPack.materialExpressive;
  AppTabSelectStyle _tabSelectStyle = AppTabSelectStyle.pillHighlight;
  AppButtonStyle _buttonVisualKind = AppButtonStyle.modernPill;
  AppButtonColorMode _buttonColorMode = AppButtonColorMode.paletteSync;
  Color? _customButtonColor;
  AppDockIconStyle _dockIconStyle = AppDockIconStyle.materialSystem;
  AppWidgetCardStyle _widgetCardStyle = AppWidgetCardStyle.solidCleanCard;
  AppCategoryIconStyle _categoryIconStyle = AppCategoryIconStyle.minimalCircle;
  AppAppBarScrollBehavior _appBarScrollBehavior =
      AppAppBarScrollBehavior.pinned;
  bool _highRefreshRate120Hz = true;
  AppLoadingIndicatorStyle _loadingStyle =
      AppLoadingIndicatorStyle.infinityDots;
  AppIconBgColorMode _iconBgColorMode = AppIconBgColorMode.categoryOriginal;
  AppIconGlyphColorMode _iconGlyphColorMode =
      AppIconGlyphColorMode.autoContrast;
  double _iconBgOpacity = 0.22;
  double _widgetBorderWidth = 0.8;
  double? _customCardCornerRadius;
  double? _customButtonCornerRadius;
  double _pageVerticalGap = 12.0;
  double _dockHeightScale = 1.0;
  double _dockOpacity = 1.0;
  double _dockBlur = 0.0;
  Color? _dockActiveColor;
  Color? _dockInactiveColor;
  Color? _dockPlusColor;
  double _chartHeightScale = 1.0;
  bool _chartShowAreaFill = true;
  bool _chartShowGridLines = true;
  double _chartSmoothness = 0.5;
  double _iconScale = 1.0;
  double _iconCornerRadius = 18.0;
  double _iconLabelScale = 1.0;
  final Set<String> _lockedComponents = {};
  Map<String, String> _customPresetsMap = {};
  bool _systemWideLiquidGlass = false;
  bool _liquidGlassSpecularHighlight = false;
  bool _liquidGlassCausticRefraction = false;

  bool get systemWideLiquidGlass => _systemWideLiquidGlass;
  bool get isSystemWideLiquidGlass => _systemWideLiquidGlass;
  bool get liquidGlassSpecularHighlight => _liquidGlassSpecularHighlight;
  bool get liquidGlassCausticRefraction => _liquidGlassCausticRefraction;

  double get iconScale => _iconScale;
  double get iconCornerRadius => _iconCornerRadius;
  double get iconLabelScale => _iconLabelScale;

  double get appBarOpacity => _appBarOpacity;
  double get appBarBlur => _appBarBlur;
  bool get appBarShowBorder => _appBarShowBorder;
  AppTopBarStyle get topBarStyle => _topBarStyle;
  bool get isAppBarFloating =>
      _topBarStyle == AppTopBarStyle.floatingIsland ||
      _appBarScrollBehavior == AppAppBarScrollBehavior.floating;
  bool get isAppBarScrollHide =>
      _appBarScrollBehavior == AppAppBarScrollBehavior.scrollHide;
  bool get pinHeader => _pinHeader;
  AppWalletViewStyle get walletViewStyle => _walletViewStyle;
  AppSeasonalTheme get seasonalTheme => _seasonalTheme;
  AppSystemIconPack get systemIconPack => _systemIconPack;
  AppTabSelectStyle get tabSelectStyle => _tabSelectStyle;
  AppButtonStyle get buttonVisualKind => _buttonVisualKind;
  AppButtonColorMode get buttonColorMode => _buttonColorMode;
  Color? get customButtonColor => _customButtonColor;
  AppDockIconStyle get dockIconStyle => _dockIconStyle;
  double get dockOpacity => _dockOpacity;
  double get dockBlur => _dockBlur;
  Color? get dockActiveColor => _dockActiveColor;
  Color? get dockInactiveColor => _dockInactiveColor;
  Color? get dockPlusColor => _dockPlusColor;
  Color get resolvedDockActiveColor => _dockActiveColor ?? resolvedPrimary;
  Color get resolvedDockPlusColor =>
      _dockPlusColor ?? _dockActiveColor ?? resolvedPrimary;
  Color resolvedDockInactiveColor(bool isDark) =>
      _dockInactiveColor ??
      (isDark ? const Color(0xFFA3B4D4) : const Color(0xFF64748B));
  Set<String> get lockedComponents => Set.unmodifiable(_lockedComponents);
  bool isLocked(String component) => _lockedComponents.contains(component);
  List<String> get customPresetNames => _customPresetsMap.keys.toList();

  Color get resolvedButtonPrimary {
    switch (_buttonColorMode) {
      case AppButtonColorMode.paletteSync:
        return primaryColor;
      case AppButtonColorMode.emeraldWealth:
        return const Color(0xFF10B981);
      case AppButtonColorMode.oceanicSapphire:
        return const Color(0xFF005FEA);
      case AppButtonColorMode.amethystRoyal:
        return const Color(0xFF8B5CF6);
      case AppButtonColorMode.sunsetCoral:
        return const Color(0xFFF97316);
      case AppButtonColorMode.cyberNeonPink:
        return const Color(0xFFEC4899);
      case AppButtonColorMode.obsidianGold:
        return const Color(0xFFF59E0B);
      case AppButtonColorMode.crimsonRuby:
        return const Color(0xFFEF4444);
      case AppButtonColorMode.titaniumIce:
        return const Color(0xFF06B6D4);
      case AppButtonColorMode.slateMinimal:
        return const Color(0xFF334155);
      case AppButtonColorMode.custom:
        return _customButtonColor ?? primaryColor;
    }
  }

  List<Color> get resolvedButtonGradient {
    final p = resolvedButtonPrimary;
    switch (_buttonColorMode) {
      case AppButtonColorMode.paletteSync:
        return currentPaletteMeta.heroGradient;
      case AppButtonColorMode.emeraldWealth:
        return const [Color(0xFF10B981), Color(0xFF059669)];
      case AppButtonColorMode.oceanicSapphire:
        return const [Color(0xFF005FEA), Color(0xFF00C2FF)];
      case AppButtonColorMode.amethystRoyal:
        return const [Color(0xFF8B5CF6), Color(0xFFD946EF)];
      case AppButtonColorMode.sunsetCoral:
        return const [Color(0xFFF97316), Color(0xFFEF4444)];
      case AppButtonColorMode.cyberNeonPink:
        return const [Color(0xFFEC4899), Color(0xFF8B5CF6)];
      case AppButtonColorMode.obsidianGold:
        return const [Color(0xFFF59E0B), Color(0xFFD97706)];
      case AppButtonColorMode.crimsonRuby:
        return const [Color(0xFFEF4444), Color(0xFFB91C1C)];
      case AppButtonColorMode.titaniumIce:
        return const [Color(0xFF06B6D4), Color(0xFF3B82F6)];
      case AppButtonColorMode.slateMinimal:
        return const [Color(0xFF334155), Color(0xFF1E293B)];
      case AppButtonColorMode.custom:
        return [p, Color.lerp(p, Colors.black, 0.20)!];
    }
  }

  AppWidgetCardStyle get widgetCardStyle => _widgetCardStyle;
  AppCategoryIconStyle get categoryIconStyle => _categoryIconStyle;
  AppAppBarScrollBehavior get appBarScrollBehavior => _appBarScrollBehavior;
  bool get highRefreshRate120Hz => _highRefreshRate120Hz;
  AppLoadingIndicatorStyle get loadingStyle => _loadingStyle;
  AppIconBgColorMode get iconBgColorMode => _iconBgColorMode;
  AppIconGlyphColorMode get iconGlyphColorMode => _iconGlyphColorMode;
  double get iconBgOpacity => _iconBgOpacity;
  double get widgetBorderWidth => _widgetBorderWidth;
  double? get customCardCornerRadius => _customCardCornerRadius;
  double? get customButtonCornerRadius => _customButtonCornerRadius;
  double get pageVerticalGap => _pageVerticalGap;
  double get dockHeightScale => _dockHeightScale;
  double get chartHeightScale => _chartHeightScale;
  bool get chartShowAreaFill => _chartShowAreaFill;
  bool get chartShowGridLines => _chartShowGridLines;
  double get chartSmoothness => _chartSmoothness;

  AppColorPalette get palette => _palette;
  AmbientBlurPreset get ambientBlur => _ambientBlur;
  CardDensity get globalDensity => _globalDensity;
  CardDensity get dashboardDensity => _dashboardDensity;
  CardDensity get transactionDensity => _transactionDensity;
  CardSurfaceStyle get surfaceStyle => _surfaceStyle;
  CardCornerStyle get cornerStyle => _cornerStyle;
  double get cardCornerRadius => _freshAppearance
      ? 24
      : _customCardCornerRadius ??
          switch (_cornerStyle) {
            CardCornerStyle.sharp => 8.0,
            CardCornerStyle.subtle => 16.0,
            CardCornerStyle.rounded => 22.0,
            CardCornerStyle.extraRounded => 30.0,
            CardCornerStyle.pillUltra => 36.0,
          };
  double get buttonCornerRadius => _freshAppearance
      ? 999
      : _customButtonCornerRadius ??
          switch (_buttonShape) {
            AppButtonShape.pill => 999.0,
            AppButtonShape.squircle => 24.0,
            AppButtonShape.rounded => 20.0,
          };
  CardShadowIntensity get shadowIntensity => _shadowIntensity;
  bool get showAiInsight => _showAiInsight;
  bool get showQuickLog => _showQuickLog;
  double get glassOpacity => _glassOpacity;
  double get glassBlur => _glassBlur;
  double get pageHorizontalMargin => _pageHorizontalMargin;
  AppButtonShape get buttonShape => _buttonShape;
  AppIconStyle get iconStyle => _iconStyle;
  AppIconShape get iconShape => _iconShape;
  AppIconVisualEffect get iconVisualEffect => _iconVisualEffect;
  AppButtonSize get buttonSize => _buttonSize;
  AppUiUxStyle get uiUxStyle => _uiUxStyle;
  double get gradientVibrancy => _gradientVibrancy;
  double get fontScale => _fontScale;
  AppFontFamily get fontFamily => _fontFamily;
  CardBorderGlowStyle get borderGlowStyle => _borderGlowStyle;
  AppMotionDynamics get motionDynamics => _motionDynamics;
  bool get hapticEnabled => _hapticEnabled;
  bool get privacyShieldDefault => _privacyShieldDefault;
  AppPrivacyStyle get privacyStyle => _privacyStyle;
  bool get isPrivacyShieldActive => _isPrivacyShieldActive;
  List<DashboardModuleId> get dashboardOrder =>
      List.unmodifiable(_dashboardOrder);
  Set<DashboardModuleId> get disabledDashboardModules =>
      Set.unmodifiable(_disabledDashboardModules);
  bool isDashboardModuleEnabled(DashboardModuleId id) =>
      !_disabledDashboardModules.contains(id);
  AppCurrencyFormat get currencyFormat => _currencyFormat;
  AppDockNavStyle get dockNavStyle => _dockNavStyle;
  AppWallpaperPreset get wallpaperPreset => _wallpaperPreset;
  double get ambientIntensity => _ambientIntensity;
  bool get particleSparkles => _particleSparkles;
  AppBudgetStyle get budgetStyle => _budgetStyle;
  AppGoalStyle get goalStyle => _goalStyle;
  AppHapticIntensity get hapticIntensity => _hapticIntensity;
  AppTransactionSound get transactionSound => _transactionSound;
  AppTransactionListStyle get transactionListStyle => _transactionListStyle;
  List<PaletteMeta> get customPalettes => List.unmodifiable(_customPalettes);
  String? get selectedCustomPaletteId => _selectedCustomPaletteId;
  List<PaletteMeta> get allPalettes => [...palettes, ..._customPalettes];
  AppCardSkinStyle get globalCardSkin => _globalCardSkin;
  bool get preserveBankCardColors => _preserveBankCardColors;
  Map<String, String> get walletCardSkins => Map.unmodifiable(_walletCardSkins);
  List<Color> get customCardGradientColors =>
      List.unmodifiable(_customCardGradientColors);
  AppHeroCardTint get heroCardTint => _heroCardTint;
  AppStatsCardTint get statsCardTint => _statsCardTint;
  Color get expenseColor => _expenseColor;
  Color get incomeColor => _incomeColor;
  Color get transferColor => _transferColor;
  Color get budgetSafeColor => _budgetSafeColor;
  Color get budgetWarningColor => _budgetWarningColor;
  Color get budgetDangerColor => _budgetDangerColor;
  bool get hasCustomTransactionColors =>
      _expenseColor != const Color(0xFFEF4444) ||
      _incomeColor != const Color(0xFF10B981) ||
      _transferColor != const Color(0xFF3B82F6);
  bool get hasCustomBudgetColors =>
      _budgetSafeColor != const Color(0xFF10B981) ||
      _budgetWarningColor != const Color(0xFFF59E0B) ||
      _budgetDangerColor != const Color(0xFFEF4444);
  List<Color> get customBgGradientColors =>
      List.unmodifiable(_customBgGradientColors);
  List<Color> get customBgGradientColorsLight =>
      List.unmodifiable(_customBgGradientColorsLight);

  List<Color> getEffectiveCustomBgGradientColors(bool isDark) {
    if (isDark) {
      if (_customBgGradientColors.isNotEmpty &&
          ThemeData.estimateBrightnessForColor(_customBgGradientColors.first) ==
              Brightness.light) {
        return const [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)];
      }
      return _customBgGradientColors;
    } else {
      if (_customBgGradientColorsLight.isNotEmpty) {
        final allLight = _customBgGradientColorsLight.every((c) =>
            ThemeData.estimateBrightnessForColor(c) == Brightness.light ||
            c.computeLuminance() > 0.40);
        if (allLight) {
          return _customBgGradientColorsLight;
        }
      }
      return const [Color(0xFFF8FAFC), Color(0xFFF1F5F9), Color(0xFFE2E8F0)];
    }
  }

  int get customBgGradientAngle => _customBgGradientAngle;
  bool get useCustomBgGradient => _useCustomBgGradient;
  double get backgroundTintOpacity => _backgroundTintOpacity;
  double get backgroundBlurSigma => _backgroundBlurSigma;
  bool get useCustomRgbMeshBg => _useCustomRgbMeshBg;
  Color get customBgColor1 => _customBgColor1;
  Color get customBgColor2 => _customBgColor2;
  Color get customBgColor3 => _customBgColor3;
  double get customBgIntensity => _customBgIntensity;
  double get customBgBlur => _customBgBlur;
  MeshBlendStyle get meshBlendStyle => _meshBlendStyle;
  AppDockLabelStyle get dockLabelStyle => _dockLabelStyle;
  AppHeroCardStyle get heroCardStyle => _heroCardStyle;
  AppHeroBalanceSize get heroBalanceSize => _heroBalanceSize;
  AppAvatarGlowStyle get avatarGlowStyle => _avatarGlowStyle;
  AppMembershipTierBadge get membershipTier => _membershipTier;
  AppAiBubbleStyle get aiBubbleStyle => _aiBubbleStyle;
  AppAiAvatarIcon get aiAvatarIcon => _aiAvatarIcon;
  AppChartCurveStyle get chartCurveStyle => _chartCurveStyle;
  AppChartAreaFill get chartAreaFill => _chartAreaFill;
  AppChartColorway get chartColorway => _chartColorway;

  double getHeroBalanceFontSize() => switch (_heroBalanceSize) {
        AppHeroBalanceSize.compact => 26.0,
        AppHeroBalanceSize.standard => 32.0,
        AppHeroBalanceSize.largeEmphasis => 38.0,
      };

  Color getAvatarGlowColor() {
    switch (_avatarGlowStyle) {
      case AppAvatarGlowStyle.goldVip:
        return const Color(0xFFF59E0B);
      case AppAvatarGlowStyle.cyberCyan:
        return const Color(0xFF06B6D4);
      case AppAvatarGlowStyle.royalAmethyst:
        return const Color(0xFF8B5CF6);
      case AppAvatarGlowStyle.emeraldCrown:
        return const Color(0xFF10B981);
      case AppAvatarGlowStyle.none:
        return Colors.transparent;
    }
  }

  List<Color> getChartColors(bool isDark) {
    switch (_chartColorway) {
      case AppChartColorway.paletteSync:
        return [currentPaletteMeta.primary, currentPaletteMeta.secondary];
      case AppChartColorway.cyberpunkVibrant:
        return const [Color(0xFF06B6D4), Color(0xFFF43F5E)];
      case AppChartColorway.emeraldFortune:
        return const [Color(0xFF10B981), Color(0xFFF59E0B)];
      case AppChartColorway.sunsetPastel:
        return const [Color(0xFFF97316), Color(0xFF8B5CF6)];
    }
  }

  static const List<PaletteMeta> palettes = [
    PaletteMeta(
      palette: AppColorPalette.oceanicSapphire,
      title: 'Oceanic Sapphire',
      subtitle: 'Xanh hoàng gia chuẩn mực tài chính',
      primary: Color(0xFF005FEA),
      secondary: Color(0xFF0284C7),
      lightBg: Color(0xFFF8FAFC),
      darkBg: Color(0xFF070B14),
      heroGradient: [Color(0xFF005FEA), Color(0xFF0284C7), Color(0xFF0369A1)],
    ),
    PaletteMeta(
      palette: AppColorPalette.emeraldWealth,
      title: 'Finora Emerald',
      subtitle: 'Xanh ngọc lục bảo chuẩn nhận diện thương hiệu Finora',
      primary: Color(0xFF0F6E56),
      secondary: Color(0xFF10B981),
      lightBg: Color(0xFFF6F8F7),
      darkBg: Color(0xFF0A100E),
      heroGradient: [Color(0xFF0B5240), Color(0xFF0F6E56), Color(0xFF147A60)],
    ),
    PaletteMeta(
      palette: AppColorPalette.amethystRoyal,
      title: 'Amethyst Royal',
      subtitle: 'Tím Thạch Anh Hoàng Gia & VIP Luxury',
      primary: Color(0xFF8B5CF6),
      secondary: Color(0xFF7C3AED),
      lightBg: Color(0xFFFBF7FE),
      darkBg: Color(0xFF0A0714),
      heroGradient: [Color(0xFF4C1D95), Color(0xFF7C3AED), Color(0xFF8B5CF6)],
    ),
    PaletteMeta(
      palette: AppColorPalette.obsidianGold,
      title: 'Obsidian Gold',
      subtitle: 'Hổ phách & Vàng Champagne sang trọng',
      primary: Color(0xFFD97706),
      secondary: Color(0xFFB45309),
      lightBg: Color(0xFFFFFBEB),
      darkBg: Color(0xFF0F0C07),
      heroGradient: [Color(0xFF78350F), Color(0xFFB45309), Color(0xFFD97706)],
    ),
    PaletteMeta(
      palette: AppColorPalette.sunsetCoral,
      title: 'Sunset Coral',
      subtitle: 'San hô & Đỏ hoàng hôn hiện đại',
      primary: Color(0xFFE11D48),
      secondary: Color(0xFFBE123C),
      lightBg: Color(0xFFFFF1F2),
      darkBg: Color(0xFF0F070A),
      heroGradient: [Color(0xFF881337), Color(0xFFBE123C), Color(0xFFE11D48)],
    ),
    PaletteMeta(
      palette: AppColorPalette.cyberNeonPink,
      title: 'Cyber Neon Pink',
      subtitle: 'Hồng Neon Tương lai & Cá tính',
      primary: Color(0xFFEC4899),
      secondary: Color(0xFFF43F5E),
      lightBg: Color(0xFFFFF1F6),
      darkBg: Color(0xFF10060E),
      heroGradient: [Color(0xFF831843), Color(0xFFBE185D), Color(0xFFEC4899)],
    ),
    PaletteMeta(
      palette: AppColorPalette.titaniumIce,
      title: 'Titanium Ice',
      subtitle: 'Xanh Băng Tuyết & Hàng không Vũ trụ',
      primary: Color(0xFF06B6D4),
      secondary: Color(0xFF0EA5E9),
      lightBg: Color(0xFFF0FDFE),
      darkBg: Color(0xFF060D14),
      heroGradient: [Color(0xFF0E7490), Color(0xFF0891B2), Color(0xFF06B6D4)],
    ),
    PaletteMeta(
      palette: AppColorPalette.crimsonRuby,
      title: 'Crimson Ruby',
      subtitle: 'Đỏ Ruby Quyền lực & Quản trị Rủi ro',
      primary: Color(0xFFDC2626),
      secondary: Color(0xFFB91C1C),
      lightBg: Color(0xFFFEF2F2),
      darkBg: Color(0xFF100606),
      heroGradient: [Color(0xFF7F1D1D), Color(0xFFB91C1C), Color(0xFFDC2626)],
    ),
    PaletteMeta(
      palette: AppColorPalette.slateMinimal,
      title: 'Slate Minimal',
      subtitle: 'Xám than chì công nghệ & tối giản',
      primary: Color(0xFF475569),
      secondary: Color(0xFF334155),
      lightBg: Color(0xFFF1F5F9),
      darkBg: Color(0xFF090D14),
      heroGradient: [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF475569)],
    ),
    PaletteMeta(
      palette: AppColorPalette.googlePixel,
      title: 'Google Pixel M3',
      subtitle: 'Tối giản Google Material You: Xanh Pixel, Xanh Mint & Coral',
      primary: Color(0xFF1A73E8),
      secondary: Color(0xFF34A853),
      lightBg: Color(0xFFF8F9FA),
      darkBg: Color(0xFF0B0D11),
      heroGradient: [Color(0xFF1A73E8), Color(0xFF4285F4), Color(0xFF34A853)],
    ),
    PaletteMeta(
      palette: AppColorPalette.colorOsAqua,
      title: 'ColorOS Aquamorphic',
      subtitle: 'Mặt nước mềm mại: Xanh Aqua, Lam ngọc & Sapphire thuần khiết',
      primary: Color(0xFF00C4B4),
      secondary: Color(0xFF0066FF),
      lightBg: Color(0xFFF0FDFA),
      darkBg: Color(0xFF060E12),
      heroGradient: [Color(0xFF00C4B4), Color(0xFF009688), Color(0xFF0066FF)],
    ),
    PaletteMeta(
      palette: AppColorPalette.hyperOsElectric,
      title: 'Xiaomi HyperOS Alive',
      subtitle: 'Năng động sống động: Electric Blue, Hyper Orange & Titanium',
      primary: Color(0xFF0070F3),
      secondary: Color(0xFFFF6B00),
      lightBg: Color(0xFFF3F4F6),
      darkBg: Color(0xFF080A10),
      heroGradient: [Color(0xFF0070F3), Color(0xFF1E40AF), Color(0xFFFF6B00)],
    ),
  ];

  static const List<AmbientBlurMeta> ambientBlurPresets = [
    AmbientBlurMeta(
      preset: AmbientBlurPreset.rainbowAurora,
      title: 'Rainbow Aurora (Đa sắc rực rỡ)',
      subtitle:
          'Sóng màu ngũ sắc: Tím Neon, Xanh biển, Hồng phấn & Ngọc lục bảo',
      bgColorsDark: [Color(0xFF070914), Color(0xFF101328), Color(0xFF140D26)],
      bgColorsLight: [Color(0xFFF6F4FE), Color(0xFFF0F7FF), Color(0xFFFFF0F5)],
      orb1: Color(0xFF8B5CF6), // Electric Violet
      orb2: Color(0xFF06B6D4), // Cyan Sky
      orb3: Color(0xFFEC4899), // Pink Rose
      orb4: Color(0xFF10B981), // Emerald Mint
    ),
    AmbientBlurMeta(
      preset: AmbientBlurPreset.cosmicAmethyst,
      title: 'Cosmic Nebula (Tinh vân tím vũ trụ)',
      subtitle: 'Ánh tím thạch anh, sao băng hồng tím & xanh thẳm',
      bgColorsDark: [Color(0xFF0F0A1F), Color(0xFF1A0D33), Color(0xFF260F45)],
      bgColorsLight: [Color(0xFFFAF5FF), Color(0xFFF3E8FF), Color(0xFFFAF5FF)],
      orb1: Color(0xFF9333EA),
      orb2: Color(0xFFC084FC),
      orb3: Color(0xFFEC4899),
      orb4: Color(0xFF6366F1),
    ),
    AmbientBlurMeta(
      preset: AmbientBlurPreset.sapphireCyan,
      title: 'Oceanic Sapphire & Sky',
      subtitle: 'Xanh hoàng gia và ánh trời thanh thoát',
      bgColorsDark: [Color(0xFF070B14), Color(0xFF0F172A), Color(0xFF0B1B36)],
      bgColorsLight: [Color(0xFFF1F5F9), Color(0xFFE0F2FE), Color(0xFFF8FAFC)],
      orb1: Color(0xFF005FEA),
      orb2: Color(0xFF0284C7),
      orb3: Color(0xFF0369A1),
      orb4: Color(0xFF059669),
    ),
    AmbientBlurMeta(
      preset: AmbientBlurPreset.midnightAurora,
      title: 'Midnight Aurora',
      subtitle: 'Cực quang xanh ngọc bích & lục bảo huyền bí',
      bgColorsDark: [Color(0xFF04130F), Color(0xFF062118), Color(0xFF0A2B20)],
      bgColorsLight: [Color(0xFFF0FDF4), Color(0xFFE6F4EA), Color(0xFFF8FAFC)],
      orb1: Color(0xFF059669),
      orb2: Color(0xFF0D9488),
      orb3: Color(0xFF10B981),
      orb4: Color(0xFF0284C7),
    ),
    AmbientBlurMeta(
      preset: AmbientBlurPreset.emeraldMatrix,
      title: 'Emerald Matrix (Ngọc lục bảo siêu thực)',
      subtitle: 'Ma trận xanh ngọc phát quang bừng sáng thịnh vượng',
      bgColorsDark: [Color(0xFF021B14), Color(0xFF042B20), Color(0xFF083D2E)],
      bgColorsLight: [Color(0xFFECFDF5), Color(0xFFD1FAE5), Color(0xFFF0FDF4)],
      orb1: Color(0xFF10B981),
      orb2: Color(0xFF059669),
      orb3: Color(0xFF34D399),
      orb4: Color(0xFF0D9488),
    ),
    AmbientBlurMeta(
      preset: AmbientBlurPreset.sunsetAmber,
      title: 'Sunset Amber Glow',
      subtitle: 'Hoàng hôn ấm áp, cam san hô & hổ phách',
      bgColorsDark: [Color(0xFF170C06), Color(0xFF261208), Color(0xFF381A0B)],
      bgColorsLight: [Color(0xFFFFFBEB), Color(0xFFFFEDD5), Color(0xFFFFF7ED)],
      orb1: Color(0xFFEA580C),
      orb2: Color(0xFFF59E0B),
      orb3: Color(0xFFE11D48),
      orb4: Color(0xFFD97706),
    ),
    AmbientBlurMeta(
      preset: AmbientBlurPreset.rubyVelvet,
      title: 'Ruby Velvet Fire (Nhung đỏ hoàng kim)',
      subtitle: 'Ánh lửa nung huyền ảo & nhung đỏ hoàng tộc rực cháy',
      bgColorsDark: [Color(0xFF1B070B), Color(0xFF2B0A11), Color(0xFF3B0E17)],
      bgColorsLight: [Color(0xFFFFF1F2), Color(0xFFFFE4E6), Color(0xFFFFF5F5)],
      orb1: Color(0xFFEF4444),
      orb2: Color(0xFFF43F5E),
      orb3: Color(0xFFFB7185),
      orb4: Color(0xFFE11D48),
    ),
    AmbientBlurMeta(
      preset: AmbientBlurPreset.cyberElectric,
      title: 'Cyber Electric Neon',
      subtitle: 'Xanh điện quang rực rỡ & băng tuyết công nghệ',
      bgColorsDark: [Color(0xFF081226), Color(0xFF0E1E3D), Color(0xFF082247)],
      bgColorsLight: [Color(0xFFE0F2FE), Color(0xFFE8F0FE), Color(0xFFF0F9FF)],
      orb1: Color(0xFF2563EB),
      orb2: Color(0xFF38BDF8),
      orb3: Color(0xFF06B6D4),
      orb4: Color(0xFF005FEA),
    ),
    AmbientBlurMeta(
      preset: AmbientBlurPreset.obsidianSlate,
      title: 'Obsidian Minimal Slate',
      subtitle: 'Khói than chì & đá phiến tối giản tĩnh lặng',
      bgColorsDark: [Color(0xFF0B0F17), Color(0xFF111827), Color(0xFF1A2233)],
      bgColorsLight: [Color(0xFFF1F5F9), Color(0xFFE2E8F0), Color(0xFFF8FAFC)],
      orb1: Color(0xFF334155),
      orb2: Color(0xFF475569),
      orb3: Color(0xFF1E293B),
      orb4: Color(0xFF64748B),
    ),
    AmbientBlurMeta(
      preset: AmbientBlurPreset.amoledPitch,
      title: 'AMOLED True Black',
      subtitle: 'Đen tuyền tuyệt đối 100% tiết kiệm pin OLED',
      bgColorsDark: [Color(0xFF000000), Color(0xFF000000), Color(0xFF000000)],
      bgColorsLight: [Color(0xFFFAFAFA), Color(0xFFF5F5F5), Color(0xFFFFFFFF)],
      orb1: Color(0x00000000),
      orb2: Color(0x00000000),
      orb3: Color(0x00000000),
      orb4: Color(0x00000000),
    ),
  ];

  static const List<WallpaperMeta> wallpapers = [
    WallpaperMeta(
      preset: AppWallpaperPreset.none,
      title: 'Hào quang động (Không hình nền)',
      subtitle: 'Nền chuyển sắc Aurora Mesh mờ kính mềm mại',
      assetPath: null,
    ),
    WallpaperMeta(
      preset: AppWallpaperPreset.silkBlue,
      title: 'Lụa Xanh Biếc (Silk Wave)',
      subtitle: 'Dải lụa hoàng gia uốn lượn thấu quang sâu thẳm',
      assetPath: 'assets/wallpapers/wallpaper_silk_blue.jpg',
    ),
    WallpaperMeta(
      preset: AppWallpaperPreset.midnightDark,
      title: 'Đêm Sao Carbon (Midnight)',
      subtitle: 'Bầu trời đen huyền bí điểm xuyết bụi sao phát quang',
      assetPath: 'assets/wallpapers/wallpaper_midnight_dark.jpg',
    ),
    WallpaperMeta(
      preset: AppWallpaperPreset.skyCyan,
      title: 'Thiên Thanh Sáng (Sky Cyan)',
      subtitle: 'Bầu trời thanh khiết, gradient xanh lơ trong trẻo',
      assetPath: 'assets/wallpapers/wallpaper_sky_cyan.jpg',
    ),
    WallpaperMeta(
      preset: AppWallpaperPreset.metallicFrost,
      title: 'Băng Tuyết Ánh Bạc (Metallic Frost)',
      subtitle: 'Mặt băng phủ sương bạc ánh kim loại công nghệ cao',
      assetPath: 'assets/wallpapers/wallpaper_metallic_frost.jpg',
    ),
    WallpaperMeta(
      preset: AppWallpaperPreset.auroraStream,
      title: 'Dòng Chảy Cực Quang (Aurora Stream)',
      subtitle: 'Sóng ánh sáng đại dương xanh sapphire kỳ ảo',
      assetPath: 'assets/wallpapers/wallpaper_aurora_stream.jpg',
    ),
  ];

  PaletteMeta get currentPaletteMeta {
    if (_freshAppearance) {
      return const PaletteMeta(
        palette: AppColorPalette.oceanicSapphire,
        title: 'Sáng trong & Xanh tươi',
        subtitle: 'Trắng dịu, xanh trong và bo mềm',
        primary: Color(0xFF0066CC),
        secondary: Color(0xFF147D64),
        lightBg: Color(0xFFF5F8FF),
        darkBg: Color(0xFF111820),
        heroGradient: [Color(0xFF007AFF), Color(0xFF36A5FF)],
      );
    }
    if (_palette == AppColorPalette.custom &&
        _selectedCustomPaletteId != null) {
      final matches =
          _customPalettes.where((p) => p.customId == _selectedCustomPaletteId);
      if (matches.isNotEmpty) return matches.first;
      if (_customPalettes.isNotEmpty) return _customPalettes.first;
    }
    return palettes.firstWhere(
      (p) => p.palette == _palette,
      orElse: () => palettes[0],
    );
  }

  WallpaperMeta get currentWallpaperMeta {
    return wallpapers.firstWhere(
      (w) => w.preset == _wallpaperPreset,
      orElse: () => wallpapers[1],
    );
  }

  AmbientBlurMeta get currentAmbientBlurMeta {
    return ambientBlurPresets.firstWhere(
      (p) => p.preset == _ambientBlur,
      orElse: () => ambientBlurPresets[0],
    );
  }

  Color get primaryColor => currentPaletteMeta.primary;
  Color get secondaryColor => currentPaletteMeta.secondary;
  Color get resolvedPrimary => primaryColor;
  Color get resolvedSecondary => secondaryColor;

  double getCardPadding([CardDensity? density]) {
    final effectiveDensity = density ?? _globalDensity;
    switch (effectiveDensity) {
      case CardDensity.compact:
        return 12.0;
      case CardDensity.standard:
        return 16.0;
      case CardDensity.spacious:
        return 22.0;
    }
  }

  EdgeInsetsGeometry getCardInsets([CardDensity? density]) {
    return EdgeInsets.all(getCardPadding(density));
  }

  double getCardSpacing([CardDensity? density]) {
    final d = density ?? _globalDensity;
    return switch (d) {
      CardDensity.compact => 8.0,
      CardDensity.standard => 14.0,
      CardDensity.spacious => 20.0,
    };
  }

  double getCardRadius([CardDensity? density]) {
    if (_customCardCornerRadius != null) {
      final ratio = switch (density ?? _globalDensity) {
        CardDensity.compact => 0.85,
        CardDensity.standard => 1.0,
        CardDensity.spacious => 1.15,
      };
      return (_customCardCornerRadius! * ratio).clamp(4.0, 48.0);
    }
    final effectiveDensity = density ?? _globalDensity;
    final multiplier = switch (_cornerStyle) {
      CardCornerStyle.sharp => .45,
      CardCornerStyle.subtle => .72,
      CardCornerStyle.rounded => 1.0,
      CardCornerStyle.extraRounded => 1.28,
      CardCornerStyle.pillUltra => 1.65,
    };
    switch (effectiveDensity) {
      case CardDensity.compact:
        return 16.0 * multiplier;
      case CardDensity.standard:
        return 20.0 * multiplier;
      case CardDensity.spacious:
        return 24.0 * multiplier;
    }
  }

  List<BoxShadow> cardShadows(Color color) => switch (_shadowIntensity) {
        CardShadowIntensity.none => const [],
        CardShadowIntensity.soft => [
            BoxShadow(
              color: color.withValues(alpha: .10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        CardShadowIntensity.elevated => [
            BoxShadow(
              color: color.withValues(alpha: .18),
              blurRadius: 24,
              offset: const Offset(0, 9),
            ),
          ],
      };

  double getHeroCardHeight(CardDensity density) {
    switch (density) {
      case CardDensity.compact:
        return 168.0;
      case CardDensity.standard:
        return 196.0;
      case CardDensity.spacious:
        return 228.0;
    }
  }

  double getTxRowHeight(CardDensity density) {
    switch (density) {
      case CardDensity.compact:
        return 50.0;
      case CardDensity.standard:
        return 58.0;
      case CardDensity.spacious:
        return 66.0;
    }
  }

  double? _readDouble(SharedPreferences prefs, String key) {
    try {
      final raw = prefs.get(key);
      if (raw == null) return null;
      if (raw is double) return raw;
      if (raw is int) return raw.toDouble();
      if (raw is num) return raw.toDouble();
      if (raw is String) return double.tryParse(raw);
    } catch (_) {}
    return null;
  }

  int? _readInt(SharedPreferences prefs, String key) {
    try {
      final raw = prefs.get(key);
      if (raw == null) return null;
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw);
    } catch (_) {}
    return null;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v27Migrated =
          prefs.getBool('finora_migrated_v27_apple_minimalist_rev_3') ?? false;
      if (!v27Migrated) {
        _freshAppearance = false;
        await prefs.setBool('finora_fresh_appearance_v1', false);
        _uiUxStyle = AppUiUxStyle.cupertinoMinimal;
        _heroCardStyle = AppHeroCardStyle.zenvestGlassDeck;
        _dockNavStyle = AppDockNavStyle.balancedFloatingCta;
        _palette = AppColorPalette.emeraldWealth;
        _ambientBlur = AmbientBlurPreset.emeraldMatrix;
        _surfaceStyle = CardSurfaceStyle.liquidGlass;
        _glassOpacity = 0.88;
        _glassBlur = 20.0;
        await prefs.setBool('finora_migrated_v27_apple_minimalist_rev_3', true);
      } else {
        _freshAppearance = prefs.getBool('finora_fresh_appearance_v1') ?? false;
      }
      final pIdx = _readInt(prefs, _paletteKey);
      if (pIdx != null && pIdx >= 0 && pIdx < AppColorPalette.values.length) {
        _palette = AppColorPalette.values[pIdx];
      }
      final bIdx = _readInt(prefs, _ambientBlurKey);
      if (bIdx != null && bIdx >= 0 && bIdx < AmbientBlurPreset.values.length) {
        _ambientBlur = AmbientBlurPreset.values[bIdx];
      }
      final dIdx = _readInt(prefs, _densityKey);
      if (dIdx != null && dIdx >= 0 && dIdx < CardDensity.values.length) {
        _globalDensity = CardDensity.values[dIdx];
      }
      final dashIdx = _readInt(prefs, _dashDensityKey);
      if (dashIdx != null &&
          dashIdx >= 0 &&
          dashIdx < CardDensity.values.length) {
        _dashboardDensity = CardDensity.values[dashIdx];
      }
      final txIdx = _readInt(prefs, _txDensityKey);
      if (txIdx != null && txIdx >= 0 && txIdx < CardDensity.values.length) {
        _transactionDensity = CardDensity.values[txIdx];
      }
      final sIdx = _readInt(prefs, _surfaceKey);
      if (sIdx != null && sIdx >= 0 && sIdx < CardSurfaceStyle.values.length) {
        _surfaceStyle = CardSurfaceStyle.values[sIdx];
      }
      final cornerIdx = _readInt(prefs, _cornerKey);
      if (cornerIdx != null &&
          cornerIdx >= 0 &&
          cornerIdx < CardCornerStyle.values.length) {
        _cornerStyle = CardCornerStyle.values[cornerIdx];
      }
      final shadowIdx = _readInt(prefs, _shadowKey);
      if (shadowIdx != null &&
          shadowIdx >= 0 &&
          shadowIdx < CardShadowIntensity.values.length) {
        _shadowIntensity = CardShadowIntensity.values[shadowIdx];
      }
      _showAiInsight = true;
      _showQuickLog = true;
      _husbandAvatar = prefs.getString(_husbandAvatarKey);
      _wifeAvatar = prefs.getString(_wifeAvatarKey);
      _jointFamilyAvatar = prefs.getString(_jointFamilyAvatarKey);
      final op = _readDouble(prefs, _glassOpacityKey);
      if (op != null) {
        _glassOpacity = op.clamp(0.20, 1.0);
      }
      final bl = _readDouble(prefs, _glassBlurKey);
      if (bl != null) {
        _glassBlur = (bl < 20.0) ? 25.0 : bl.clamp(4.0, 32.0);
      }
      final phm = _readDouble(prefs, _pageHorizontalMarginKey);
      if (phm != null) _pageHorizontalMargin = phm.clamp(8.0, 32.0);
      final bShape = _readInt(prefs, _buttonShapeKey);
      if (bShape != null &&
          bShape >= 0 &&
          bShape < AppButtonShape.values.length) {
        _buttonShape = AppButtonShape.values[bShape];
      }
      final iconStyle = _readInt(prefs, _iconStyleKey);
      if (iconStyle != null &&
          iconStyle >= 0 &&
          iconStyle < AppIconStyle.values.length) {
        _iconStyle = AppIconStyle.values[iconStyle];
      }
      final iconShapeIdx = _readInt(prefs, _iconShapeKey);
      if (iconShapeIdx != null &&
          iconShapeIdx >= 0 &&
          iconShapeIdx < AppIconShape.values.length) {
        _iconShape = AppIconShape.values[iconShapeIdx];
      }
      final iconVisualEffectIdx = _readInt(prefs, _iconVisualEffectKey);
      if (iconVisualEffectIdx != null &&
          iconVisualEffectIdx >= 0 &&
          iconVisualEffectIdx < AppIconVisualEffect.values.length) {
        _iconVisualEffect = AppIconVisualEffect.values[iconVisualEffectIdx];
      }
      final bSize = _readInt(prefs, _buttonSizeKey);
      if (bSize != null && bSize >= 0 && bSize < AppButtonSize.values.length) {
        _buttonSize = AppButtonSize.values[bSize];
      }
      final fs = _readDouble(prefs, _fontScaleKey);
      if (fs != null) _fontScale = fs.clamp(0.85, 1.25);
      final sUiIdx = _readInt(prefs, _uiUxStyleKey);
      if (sUiIdx != null &&
          sUiIdx >= 0 &&
          sUiIdx < AppUiUxStyle.values.length) {
        _uiUxStyle = AppUiUxStyle.values[sUiIdx];
      }
      final vib = _readDouble(prefs, _gradientVibrancyKey);
      if (vib != null) _gradientVibrancy = vib.clamp(0.5, 2.0);
      final fontFamIdx = _readInt(prefs, _fontFamilyKey);
      if (fontFamIdx != null &&
          fontFamIdx >= 0 &&
          fontFamIdx < AppFontFamily.values.length) {
        _fontFamily = AppFontFamily.values[fontFamIdx];
      }
      final glowIdx = _readInt(prefs, _borderGlowKey);
      if (glowIdx != null &&
          glowIdx >= 0 &&
          glowIdx < CardBorderGlowStyle.values.length) {
        _borderGlowStyle = CardBorderGlowStyle.values[glowIdx];
      }
      final motionIdx = _readInt(prefs, _motionKey);
      if (motionIdx != null &&
          motionIdx >= 0 &&
          motionIdx < AppMotionDynamics.values.length) {
        _motionDynamics = AppMotionDynamics.values[motionIdx];
      }
      final hapticVal = prefs.getBool(_hapticKey);
      if (hapticVal != null) _hapticEnabled = hapticVal;
      final privacyVal = prefs.getBool(_privacyKey);
      if (privacyVal != null) _privacyShieldDefault = privacyVal;
      final psIdx = _readInt(prefs, _privacyStyleKey);
      if (psIdx != null &&
          psIdx >= 0 &&
          psIdx < AppPrivacyStyle.values.length) {
        _privacyStyle = AppPrivacyStyle.values[psIdx];
      }
      final migratedStreamlined =
          prefs.getBool('finora_migrated_cashflow_hub_v1') ?? false;
      if (!migratedStreamlined) {
        _dashboardOrder = List.from(defaultDashboardOrder);
        _disabledDashboardModules = {
          DashboardModuleId.walletsAccounts,
          DashboardModuleId.investmentsAssets,
          DashboardModuleId.loansDebts,
          DashboardModuleId.budgetProgress,
        };
        await prefs.setStringList(
            _dashboardOrderKey, _dashboardOrder.map((m) => m.name).toList());
        await prefs.setStringList(_dashboardDisabledKey,
            _disabledDashboardModules.map((m) => m.name).toList());
        await prefs.setBool('finora_migrated_cashflow_hub_v1', true);
      } else {
        final rawOrder = prefs.getStringList(_dashboardOrderKey);
        if (rawOrder != null && rawOrder.isNotEmpty) {
          final parsedOrder = <DashboardModuleId>[];
          for (final name in rawOrder) {
            final matches =
                DashboardModuleId.values.where((m) => m.name == name);
            if (matches.isNotEmpty) {
              parsedOrder.add(matches.first);
            }
          }
          for (final def in defaultDashboardOrder) {
            if (!parsedOrder.contains(def)) parsedOrder.add(def);
          }
          _dashboardOrder = parsedOrder;
        }
        final rawDisabled = prefs.getStringList(_dashboardDisabledKey);
        if (rawDisabled != null) {
          _disabledDashboardModules = rawDisabled
              .map((name) {
                final matches =
                    DashboardModuleId.values.where((m) => m.name == name);
                return matches.isNotEmpty ? matches.first : null;
              })
              .whereType<DashboardModuleId>()
              .toSet();
        }
      }
      _isPrivacyShieldActive = _privacyShieldDefault;
      final currIdx = _readInt(prefs, _currencyKey);
      if (currIdx != null &&
          currIdx >= 0 &&
          currIdx < AppCurrencyFormat.values.length) {
        _currencyFormat = AppCurrencyFormat.values[currIdx];
      }
      final dockIdx = _readInt(prefs, _dockNavKey);
      if (dockIdx != null &&
          dockIdx >= 0 &&
          dockIdx < AppDockNavStyle.values.length) {
        _dockNavStyle = AppDockNavStyle.values[dockIdx];
      }
      final wIdx = _readInt(prefs, _wallpaperKey);
      if (wIdx != null &&
          wIdx >= 0 &&
          wIdx < AppWallpaperPreset.values.length) {
        _wallpaperPreset = AppWallpaperPreset.none;
      }
      final ambInt = _readDouble(prefs, _ambientIntensityKey);
      if (ambInt != null) _ambientIntensity = ambInt.clamp(0.1, 1.0);
      final sparkles = prefs.getBool(_particleSparklesKey);
      if (sparkles != null) _particleSparkles = sparkles;
      final bStyle = _readInt(prefs, _budgetStyleKey);
      if (bStyle != null &&
          bStyle >= 0 &&
          bStyle < AppBudgetStyle.values.length) {
        _budgetStyle = AppBudgetStyle.values[bStyle];
      }
      final gStyle = _readInt(prefs, _goalStyleKey);
      if (gStyle != null &&
          gStyle >= 0 &&
          gStyle < AppGoalStyle.values.length) {
        _goalStyle = AppGoalStyle.values[gStyle];
      }
      final hapticInt = _readInt(prefs, _hapticIntensityKey);
      if (hapticInt != null &&
          hapticInt >= 0 &&
          hapticInt < AppHapticIntensity.values.length) {
        _hapticIntensity = AppHapticIntensity.values[hapticInt];
      }
      final txSound = _readInt(prefs, _transactionSoundKey);
      if (txSound != null &&
          txSound >= 0 &&
          txSound < AppTransactionSound.values.length) {
        _transactionSound = AppTransactionSound.values[txSound];
      }
      final txListStyle = _readInt(prefs, _transactionListStyleKey);
      if (txListStyle != null &&
          txListStyle >= 0 &&
          txListStyle < AppTransactionListStyle.values.length) {
        _transactionListStyle = AppTransactionListStyle.values[txListStyle];
      }
      final rawCustomPalettes = prefs.getStringList(_customPalettesKey);
      if (rawCustomPalettes != null) {
        final list = <PaletteMeta>[];
        for (final itemStr in rawCustomPalettes) {
          try {
            final map = jsonDecode(itemStr) as Map<String, dynamic>;
            final id = map['id'] as String;
            final title = map['title'] as String;
            final subtitle =
                map['subtitle'] as String? ?? 'Bảng màu tùy chỉnh Finora';
            final primary = Color(map['primary'] as int);
            final secondary = Color(map['secondary'] as int);
            final lightBg = Color(map['lightBg'] as int);
            final darkBg = Color(map['darkBg'] as int);
            final heroColors = (map['heroGradient'] as List<dynamic>?)
                    ?.map((c) => Color(c as int))
                    .toList() ??
                [primary, secondary];
            list.add(PaletteMeta(
              palette: AppColorPalette.custom,
              title: title,
              subtitle: subtitle,
              primary: primary,
              secondary: secondary,
              lightBg: lightBg,
              darkBg: darkBg,
              heroGradient: heroColors,
              isCustom: true,
              customId: id,
            ));
          } catch (_) {}
        }
        _customPalettes = list;
      }
      _selectedCustomPaletteId = prefs.getString(_selectedCustomPaletteIdKey);

      final cardSkinIdx = _readInt(prefs, _globalCardSkinKey);
      if (cardSkinIdx != null &&
          cardSkinIdx >= 0 &&
          cardSkinIdx < AppCardSkinStyle.values.length) {
        _globalCardSkin = AppCardSkinStyle.values[cardSkinIdx];
      }
      final rawWalletSkins = prefs.getString(_walletCardSkinsKey);
      if (rawWalletSkins != null) {
        try {
          final decoded = jsonDecode(rawWalletSkins) as Map<String, dynamic>;
          _walletCardSkins = decoded.map((k, v) => MapEntry(k, v.toString()));
        } catch (_) {}
      }
      final rawCustomCardGradient = prefs.getStringList(_customCardGradientKey);
      if (rawCustomCardGradient != null && rawCustomCardGradient.isNotEmpty) {
        _customCardGradientColors =
            rawCustomCardGradient.map((s) => Color(int.parse(s))).toList();
      }
      final heroTintIdx = _readInt(prefs, _heroCardTintKey);
      if (heroTintIdx != null &&
          heroTintIdx >= 0 &&
          heroTintIdx < AppHeroCardTint.values.length) {
        _heroCardTint = AppHeroCardTint.values[heroTintIdx];
      }
      final statsTintIdx = _readInt(prefs, _statsCardTintKey);
      if (statsTintIdx != null &&
          statsTintIdx >= 0 &&
          statsTintIdx < AppStatsCardTint.values.length) {
        _statsCardTint = AppStatsCardTint.values[statsTintIdx];
      }
      final expCol = _readInt(prefs, _expenseColorKey);
      if (expCol != null) _expenseColor = Color(expCol);
      final incCol = _readInt(prefs, _incomeColorKey);
      if (incCol != null) _incomeColor = Color(incCol);
      final trCol = _readInt(prefs, _transferColorKey);
      if (trCol != null) _transferColor = Color(trCol);
      final bSafe = _readInt(prefs, _budgetSafeColorKey);
      if (bSafe != null) _budgetSafeColor = Color(bSafe);
      final bWarn = _readInt(prefs, _budgetWarningColorKey);
      if (bWarn != null) _budgetWarningColor = Color(bWarn);
      final bDang = _readInt(prefs, _budgetDangerColorKey);
      if (bDang != null) _budgetDangerColor = Color(bDang);
      final rawBgGradient = prefs.getStringList(_customBgGradientKey);
      if (rawBgGradient != null && rawBgGradient.isNotEmpty) {
        _customBgGradientColors =
            rawBgGradient.map((s) => Color(int.parse(s))).toList();
      }
      final rawBgGradientLight =
          prefs.getStringList('${_customBgGradientKey}_light');
      if (rawBgGradientLight != null && rawBgGradientLight.isNotEmpty) {
        _customBgGradientColorsLight =
            rawBgGradientLight.map((s) => Color(int.parse(s))).toList();
      }
      final bgAngle = _readInt(prefs, _customBgGradientAngleKey);
      if (bgAngle != null) _customBgGradientAngle = bgAngle;
      final useCbg = prefs.getBool('finora_studio_use_custom_bg_gradient');
      if (useCbg != null) _useCustomBgGradient = useCbg;
      final bgTint = _readDouble(prefs, 'finora_studio_bg_tint_opacity');
      if (bgTint != null) _backgroundTintOpacity = bgTint.clamp(0.05, 1.0);
      final bgBlur = _readDouble(prefs, 'finora_studio_bg_blur_sigma');
      if (bgBlur != null) _backgroundBlurSigma = bgBlur.clamp(0.0, 60.0);
      final useRgbMesh = prefs.getBool(_useCustomRgbMeshBgKey);
      if (useRgbMesh != null) _useCustomRgbMeshBg = useRgbMesh;
      final rgbCol1 = _readInt(prefs, _customBgColor1Key);
      if (rgbCol1 != null) _customBgColor1 = Color(rgbCol1);
      final rgbCol2 = _readInt(prefs, _customBgColor2Key);
      if (rgbCol2 != null) _customBgColor2 = Color(rgbCol2);
      final rgbCol3 = _readInt(prefs, _customBgColor3Key);
      if (rgbCol3 != null) _customBgColor3 = Color(rgbCol3);
      final rgbInt = _readDouble(prefs, _customBgIntensityKey);
      if (rgbInt != null) _customBgIntensity = rgbInt.clamp(0.0, 0.45);
      final rgbBlur = _readDouble(prefs, _customBgBlurKey);
      if (rgbBlur != null) _customBgBlur = rgbBlur.clamp(20.0, 100.0);
      final blendStyleIdx = _readInt(prefs, _meshBlendStyleKey);
      if (blendStyleIdx != null &&
          blendStyleIdx >= 0 &&
          blendStyleIdx < MeshBlendStyle.values.length) {
        _meshBlendStyle = MeshBlendStyle.values[blendStyleIdx];
      }
      final preserveBank =
          prefs.getBool('finora_studio_preserve_bank_card_colors');
      if (preserveBank != null) _preserveBankCardColors = preserveBank;
      final dockLblIdx = _readInt(prefs, _dockLabelStyleKey);
      if (dockLblIdx != null &&
          dockLblIdx >= 0 &&
          dockLblIdx < AppDockLabelStyle.values.length) {
        _dockLabelStyle = AppDockLabelStyle.values[dockLblIdx];
      }
      final hasMigratedToLedger2026 =
          prefs.getBool('finora_migrated_ledger_2026_v1') ?? false;
      if (!hasMigratedToLedger2026) {
        _heroCardStyle = AppHeroCardStyle.zenvestGlassDeck;
        _uiUxStyle = AppUiUxStyle.ledgerEditorial;
        _fontFamily = AppFontFamily.beVietnamPro;
        await prefs.setInt(
            _heroCardStyleKey, AppHeroCardStyle.zenvestGlassDeck.index);
        await prefs.setInt(_uiUxStyleKey, AppUiUxStyle.ledgerEditorial.index);
        await prefs.setInt(_fontFamilyKey, AppFontFamily.beVietnamPro.index);
        await prefs.setBool('finora_migrated_ledger_2026_v1', true);
      } else {
        final heroStyleIdx = _readInt(prefs, _heroCardStyleKey);
        if (heroStyleIdx != null &&
            heroStyleIdx >= 0 &&
            heroStyleIdx < AppHeroCardStyle.values.length) {
          _heroCardStyle = AppHeroCardStyle.values[heroStyleIdx];
        }
      }
      final hasMigratedGlassOpacity =
          prefs.getBool('finora_migrated_glass_opacity_v3') ?? false;
      if (!hasMigratedGlassOpacity) {
        if (_glassOpacity <= 0.45) {
          _glassOpacity = 0.88;
          await prefs.setDouble(_glassOpacityKey, 0.88);
        }
        await prefs.setBool('finora_migrated_glass_opacity_v3', true);
      }
      final heroSizeIdx = _readInt(prefs, _heroBalanceSizeKey);
      if (heroSizeIdx != null &&
          heroSizeIdx >= 0 &&
          heroSizeIdx < AppHeroBalanceSize.values.length) {
        _heroBalanceSize = AppHeroBalanceSize.values[heroSizeIdx];
      }
      final glowIdx2 = _readInt(prefs, _avatarGlowStyleKey);
      if (glowIdx2 != null &&
          glowIdx2 >= 0 &&
          glowIdx2 < AppAvatarGlowStyle.values.length) {
        _avatarGlowStyle = AppAvatarGlowStyle.values[glowIdx2];
      }
      final tierIdx = _readInt(prefs, _membershipTierKey);
      if (tierIdx != null &&
          tierIdx >= 0 &&
          tierIdx < AppMembershipTierBadge.values.length) {
        _membershipTier = AppMembershipTierBadge.values[tierIdx];
      }
      final aiBubbleIdx = _readInt(prefs, _aiBubbleStyleKey);
      if (aiBubbleIdx != null &&
          aiBubbleIdx >= 0 &&
          aiBubbleIdx < AppAiBubbleStyle.values.length) {
        _aiBubbleStyle = AppAiBubbleStyle.values[aiBubbleIdx];
      }
      final aiAvatarIdx = _readInt(prefs, _aiAvatarIconKey);
      if (aiAvatarIdx != null &&
          aiAvatarIdx >= 0 &&
          aiAvatarIdx < AppAiAvatarIcon.values.length) {
        _aiAvatarIcon = AppAiAvatarIcon.values[aiAvatarIdx];
      }
      final chartCurveIdx = _readInt(prefs, _chartCurveStyleKey);
      if (chartCurveIdx != null &&
          chartCurveIdx >= 0 &&
          chartCurveIdx < AppChartCurveStyle.values.length) {
        _chartCurveStyle = AppChartCurveStyle.values[chartCurveIdx];
      }
      final chartFillIdx = _readInt(prefs, _chartAreaFillKey);
      if (chartFillIdx != null &&
          chartFillIdx >= 0 &&
          chartFillIdx < AppChartAreaFill.values.length) {
        _chartAreaFill = AppChartAreaFill.values[chartFillIdx];
      }
      final chartColorIdx = _readInt(prefs, _chartColorwayKey);
      if (chartColorIdx != null &&
          chartColorIdx >= 0 &&
          chartColorIdx < AppChartColorway.values.length) {
        _chartColorway = AppChartColorway.values[chartColorIdx];
      }
      final abOp = _readDouble(prefs, _appBarOpacityKey);
      if (abOp != null) _appBarOpacity = abOp.clamp(0.0, 1.0);
      final abBl = _readDouble(prefs, _appBarBlurKey);
      if (abBl != null) _appBarBlur = abBl.clamp(0.0, 30.0);
      final abShowBorder = prefs.getBool(_appBarShowBorderKey);
      if (abShowBorder != null) _appBarShowBorder = abShowBorder;
      final topBarIdx = _readInt(prefs, _topBarStyleKey);
      if (topBarIdx != null &&
          topBarIdx >= 0 &&
          topBarIdx < AppTopBarStyle.values.length) {
        _topBarStyle = (topBarIdx == 0)
            ? AppTopBarStyle.frostedGlass
            : AppTopBarStyle.values[topBarIdx];
      }
      final pin = prefs.getBool(_pinHeaderKey);
      if (pin != null) _pinHeader = pin;
      if (!(prefs.getBool('finora_wallet_web_parity_v1') ?? false)) {
        await prefs.setInt(
            _walletViewStyleKey, AppWalletViewStyle.webCards.index);
        await prefs.setBool('finora_wallet_web_parity_v1', true);
      }
      final wvsIdx = _readInt(prefs, _walletViewStyleKey);
      if (wvsIdx != null &&
          wvsIdx >= 0 &&
          wvsIdx < AppWalletViewStyle.values.length) {
        _walletViewStyle = AppWalletViewStyle.values[wvsIdx];
      }
      final seasonIdx = _readInt(prefs, _seasonalThemeKey);
      if (seasonIdx != null &&
          seasonIdx >= 0 &&
          seasonIdx < AppSeasonalTheme.values.length) {
        _seasonalTheme = AppSeasonalTheme.values[seasonIdx];
      }
      final iconPackIdx = _readInt(prefs, _systemIconPackKey);
      if (iconPackIdx != null &&
          iconPackIdx >= 0 &&
          iconPackIdx < AppSystemIconPack.values.length) {
        _systemIconPack = AppSystemIconPack.values[iconPackIdx];
      }
      final tabSelIdx = _readInt(prefs, _tabSelectStyleKey);
      if (tabSelIdx != null &&
          tabSelIdx >= 0 &&
          tabSelIdx < AppTabSelectStyle.values.length) {
        _tabSelectStyle = AppTabSelectStyle.values[tabSelIdx];
      }
      final btnKindIdx = _readInt(prefs, _buttonVisualKindKey);
      if (btnKindIdx != null &&
          btnKindIdx >= 0 &&
          btnKindIdx < AppButtonStyle.values.length) {
        _buttonVisualKind = AppButtonStyle.values[btnKindIdx];
      }
      final btnColorIdx = _readInt(prefs, _buttonColorModeKey);
      if (btnColorIdx != null &&
          btnColorIdx >= 0 &&
          btnColorIdx < AppButtonColorMode.values.length) {
        _buttonColorMode = AppButtonColorMode.values[btnColorIdx];
      }
      final customBtnVal = _readInt(prefs, _customButtonColorKey);
      if (customBtnVal != null) {
        _customButtonColor = Color(customBtnVal);
      }
      final dockIconIdx = _readInt(prefs, _dockIconStyleKey);
      if (dockIconIdx != null &&
          dockIconIdx >= 0 &&
          dockIconIdx < AppDockIconStyle.values.length) {
        _dockIconStyle = AppDockIconStyle.values[dockIconIdx];
      }
      final wCardIdx = _readInt(prefs, _widgetCardStyleKey);
      if (wCardIdx != null &&
          wCardIdx >= 0 &&
          wCardIdx < AppWidgetCardStyle.values.length) {
        _widgetCardStyle = AppWidgetCardStyle.values[wCardIdx];
      }
      final catIconIdx = _readInt(prefs, _categoryIconStyleKey);
      if (catIconIdx != null &&
          catIconIdx >= 0 &&
          catIconIdx < AppCategoryIconStyle.values.length) {
        _categoryIconStyle = AppCategoryIconStyle.values[catIconIdx];
      }
      final appBarBehaviorIdx = _readInt(prefs, _appBarScrollBehaviorKey);
      if (appBarBehaviorIdx != null &&
          appBarBehaviorIdx >= 0 &&
          appBarBehaviorIdx < AppAppBarScrollBehavior.values.length) {
        _appBarScrollBehavior =
            AppAppBarScrollBehavior.values[appBarBehaviorIdx];
        _pinHeader = (_appBarScrollBehavior == AppAppBarScrollBehavior.pinned);
      }
      final hr120 = prefs.getBool(_highRefreshRate120HzKey);
      if (hr120 != null) _highRefreshRate120Hz = hr120;
      final loadStyleIdx = _readInt(prefs, _loadingStyleKey);
      if (loadStyleIdx != null &&
          loadStyleIdx >= 0 &&
          loadStyleIdx < AppLoadingIndicatorStyle.values.length) {
        _loadingStyle = AppLoadingIndicatorStyle.values[loadStyleIdx];
      }
      final iconBgIdx = _readInt(prefs, _iconBgColorModeKey);
      if (iconBgIdx != null &&
          iconBgIdx >= 0 &&
          iconBgIdx < AppIconBgColorMode.values.length) {
        _iconBgColorMode = AppIconBgColorMode.values[iconBgIdx];
      }
      final iconGlyphIdx = _readInt(prefs, _iconGlyphColorModeKey);
      if (iconGlyphIdx != null &&
          iconGlyphIdx >= 0 &&
          iconGlyphIdx < AppIconGlyphColorMode.values.length) {
        _iconGlyphColorMode = AppIconGlyphColorMode.values[iconGlyphIdx];
      }
      final iconOpacity = prefs.getDouble(_iconBgOpacityKey);
      if (iconOpacity != null) _iconBgOpacity = iconOpacity;

      final wbw = _readDouble(prefs, _widgetBorderWidthKey);
      if (wbw != null) _widgetBorderWidth = wbw.clamp(0.0, 3.0);
      final ccr = _readDouble(prefs, _customCardCornerRadiusKey);
      if (ccr != null) _customCardCornerRadius = ccr.clamp(4.0, 36.0);
      final bcr = _readDouble(prefs, _customButtonCornerRadiusKey);
      if (bcr != null) _customButtonCornerRadius = bcr.clamp(4.0, 28.0);
      final pvg = _readDouble(prefs, _pageVerticalGapKey);
      if (pvg != null) _pageVerticalGap = pvg.clamp(6.0, 28.0);
      final dhs = _readDouble(prefs, _dockHeightScaleKey);
      if (dhs != null) _dockHeightScale = dhs.clamp(0.80, 1.30);
      final dOp = _readDouble(prefs, _dockOpacityKey);
      if (dOp != null) {
        _dockOpacity = (dOp >= 0.60) ? 0.38 : dOp.clamp(0.05, 1.0);
      }
      final dBl = _readDouble(prefs, _dockBlurKey);
      if (dBl != null) {
        _dockBlur = (dBl < 22.0) ? 28.0 : dBl.clamp(0.0, 40.0);
      }
      final dActCol = _readInt(prefs, _dockActiveColorKey);
      if (dActCol != null) _dockActiveColor = Color(dActCol);
      final dInactCol = _readInt(prefs, _dockInactiveColorKey);
      if (dInactCol != null) _dockInactiveColor = Color(dInactCol);
      final dPlusCol = _readInt(prefs, _dockPlusColorKey);
      if (dPlusCol != null) _dockPlusColor = Color(dPlusCol);
      final chs = _readDouble(prefs, _chartHeightScaleKey);
      if (chs != null) _chartHeightScale = chs.clamp(0.70, 1.40);
      final csaf = prefs.getBool(_chartShowAreaFillKey);
      if (csaf != null) _chartShowAreaFill = csaf;
      final csgl = prefs.getBool(_chartShowGridLinesKey);
      if (csgl != null) _chartShowGridLines = csgl;
      final csmt = _readDouble(prefs, _chartSmoothnessKey);
      if (csmt != null) _chartSmoothness = csmt.clamp(0.0, 1.0);
      final ics = _readDouble(prefs, _iconScaleKey);
      if (ics != null) _iconScale = ics.clamp(0.65, 1.45);
      final icr = _readDouble(prefs, _iconCornerRadiusKey);
      if (icr != null) _iconCornerRadius = icr.clamp(0.0, 36.0);
      final ils = _readDouble(prefs, _iconLabelScaleKey);
      if (ils != null) _iconLabelScale = ils.clamp(0.75, 1.35);

      final lockedList = prefs.getStringList(_lockedComponentsKey);
      if (lockedList != null) {
        _lockedComponents.clear();
        _lockedComponents.addAll(lockedList);
      }
      final customPresetsRaw = prefs.getString(_customUserPresetsKey);
      if (customPresetsRaw != null) {
        try {
          final decoded = jsonDecode(customPresetsRaw) as Map<String, dynamic>;
          _customPresetsMap = decoded.map((k, v) => MapEntry(k, v.toString()));
        } catch (_) {}
      }
      final swlg = prefs.getBool(_systemWideLiquidGlassKey);
      if (swlg != null) _systemWideLiquidGlass = swlg;
      final lgsh = prefs.getBool(_liquidGlassSpecularHighlightKey);
      if (lgsh != null) _liquidGlassSpecularHighlight = lgsh;
      final lgcr = prefs.getBool(_liquidGlassCausticRefractionKey);
      if (lgcr != null) _liquidGlassCausticRefraction = lgcr;

      if (!(prefs.getBool('finora_migrated_material_3_clean_v1') ?? false)) {
        _uiUxStyle = AppUiUxStyle.googleMinimal;
        _surfaceStyle = CardSurfaceStyle.solidModern;
        _widgetCardStyle = AppWidgetCardStyle.solidCleanCard;
        _systemWideLiquidGlass = false;
        _liquidGlassSpecularHighlight = false;
        _liquidGlassCausticRefraction = false;
        _glassOpacity = 1.0;
        _glassBlur = 0.0;
        _appBarBlur = 0.0;
        _dockBlur = 0.0;
        _dockOpacity = 1.0;
        _topBarStyle = AppTopBarStyle.seamlessBlend;
        _dockNavStyle = AppDockNavStyle.classicDock;
        _systemIconPack = AppSystemIconPack.materialExpressive;
        _dockIconStyle = AppDockIconStyle.materialSystem;
        _iconVisualEffect = AppIconVisualEffect.flatMinimal;
        _particleSparkles = false;
        _ambientIntensity = 0.0;
        _loadingStyle = AppLoadingIndicatorStyle.infinityDots;
        _aiBubbleStyle = AppAiBubbleStyle.neumorphicClean;

        await prefs.setInt(_uiUxStyleKey, AppUiUxStyle.googleMinimal.index);
        await prefs.setInt(_surfaceKey, CardSurfaceStyle.solidModern.index);
        await prefs.setInt(
            _widgetCardStyleKey, AppWidgetCardStyle.solidCleanCard.index);
        await prefs.setBool(_systemWideLiquidGlassKey, false);
        await prefs.setBool(_liquidGlassSpecularHighlightKey, false);
        await prefs.setBool(_liquidGlassCausticRefractionKey, false);
        await prefs.setDouble(_glassOpacityKey, 1.0);
        await prefs.setDouble(_glassBlurKey, 0.0);
        await prefs.setDouble(_appBarBlurKey, 0.0);
        await prefs.setDouble(_dockBlurKey, 0.0);
        await prefs.setDouble(_dockOpacityKey, 1.0);
        await prefs.setInt(_topBarStyleKey, AppTopBarStyle.seamlessBlend.index);
        await prefs.setInt(_dockNavKey, AppDockNavStyle.classicDock.index);
        await prefs.setInt(
            _systemIconPackKey, AppSystemIconPack.materialExpressive.index);
        await prefs.setInt(
            _dockIconStyleKey, AppDockIconStyle.materialSystem.index);
        await prefs.setInt(
            _iconVisualEffectKey, AppIconVisualEffect.flatMinimal.index);
        await prefs.setBool(_particleSparklesKey, false);
        await prefs.setDouble(_ambientIntensityKey, 0.0);
        await prefs.setInt(
            _loadingStyleKey, AppLoadingIndicatorStyle.infinityDots.index);
        await prefs.setBool('finora_migrated_material_3_clean_v1', true);
      }

      if (!(prefs.getBool('finora_migrated_material_3_full_v2') ?? false)) {
        _uiUxStyle = AppUiUxStyle.googleMinimal;
        _surfaceStyle = CardSurfaceStyle.solidModern;
        _widgetCardStyle = AppWidgetCardStyle.solidCleanCard;
        _systemWideLiquidGlass = false;
        _liquidGlassSpecularHighlight = false;
        _liquidGlassCausticRefraction = false;
        _glassOpacity = 1.0;
        _glassBlur = 0.0;
        _appBarBlur = 0.0;
        _dockBlur = 0.0;
        _dockOpacity = 1.0;
        _topBarStyle = AppTopBarStyle.seamlessBlend;
        _dockNavStyle = AppDockNavStyle.classicDock;
        _systemIconPack = AppSystemIconPack.materialExpressive;
        _dockIconStyle = AppDockIconStyle.materialSystem;
        _iconVisualEffect = AppIconVisualEffect.flatMinimal;
        _particleSparkles = false;
        _ambientIntensity = 0.0;
        _loadingStyle = AppLoadingIndicatorStyle.infinityDots;
        _aiBubbleStyle = AppAiBubbleStyle.neumorphicClean;
        _buttonShape = AppButtonShape.pill;
        _buttonVisualKind = AppButtonStyle.flatSubtle;

        await prefs.setInt(_uiUxStyleKey, AppUiUxStyle.googleMinimal.index);
        await prefs.setInt(_surfaceKey, CardSurfaceStyle.solidModern.index);
        await prefs.setInt(
            _widgetCardStyleKey, AppWidgetCardStyle.solidCleanCard.index);
        await prefs.setBool(_systemWideLiquidGlassKey, false);
        await prefs.setBool(_liquidGlassSpecularHighlightKey, false);
        await prefs.setBool(_liquidGlassCausticRefractionKey, false);
        await prefs.setDouble(_glassOpacityKey, 1.0);
        await prefs.setDouble(_glassBlurKey, 0.0);
        await prefs.setDouble(_appBarBlurKey, 0.0);
        await prefs.setDouble(_dockBlurKey, 0.0);
        await prefs.setDouble(_dockOpacityKey, 1.0);
        await prefs.setInt(_topBarStyleKey, AppTopBarStyle.seamlessBlend.index);
        await prefs.setInt(_dockNavKey, AppDockNavStyle.classicDock.index);
        await prefs.setInt(
            _systemIconPackKey, AppSystemIconPack.materialExpressive.index);
        await prefs.setInt(
            _dockIconStyleKey, AppDockIconStyle.materialSystem.index);
        await prefs.setInt(
            _iconVisualEffectKey, AppIconVisualEffect.flatMinimal.index);
        await prefs.setBool(_particleSparklesKey, false);
        await prefs.setDouble(_ambientIntensityKey, 0.0);
        await prefs.setInt(
            _loadingStyleKey, AppLoadingIndicatorStyle.infinityDots.index);
        await prefs.setBool('finora_migrated_material_3_full_v2', true);
      }

      if (!(prefs.getBool('finora_migrated_minimalist_circle_icons_v1') ??
          false)) {
        _categoryIconStyle = AppCategoryIconStyle.minimalCircle;
        _iconShape = AppIconShape.circle;
        _iconVisualEffect = AppIconVisualEffect.flatMinimal;
        _iconStyle = AppIconStyle.round;
        _widgetCardStyle = AppWidgetCardStyle.solidCleanCard;
        _systemIconPack = AppSystemIconPack.solarCurved;
        _dockIconStyle = AppDockIconStyle.modernLucide;

        await prefs.setInt(
            _categoryIconStyleKey, AppCategoryIconStyle.minimalCircle.index);
        await prefs.setInt(_iconShapeKey, AppIconShape.circle.index);
        await prefs.setInt(
            _iconVisualEffectKey, AppIconVisualEffect.flatMinimal.index);
        await prefs.setInt(_iconStyleKey, AppIconStyle.round.index);
        await prefs.setInt(
            _widgetCardStyleKey, AppWidgetCardStyle.solidCleanCard.index);
        await prefs.setInt(
            _dockIconStyleKey, AppDockIconStyle.modernLucide.index);
        await prefs.setBool('finora_migrated_minimalist_circle_icons_v1', true);
      }

      if (!(prefs.getBool('finora_migrated_health_above_transactions_v2') ??
          false)) {
        _dashboardOrder.remove(DashboardModuleId.aiHealthScore);
        final txIdx =
            _dashboardOrder.indexOf(DashboardModuleId.recentTransactions);
        if (txIdx >= 0) {
          _dashboardOrder.insert(txIdx, DashboardModuleId.aiHealthScore);
        } else {
          _dashboardOrder.add(DashboardModuleId.aiHealthScore);
        }
        _disabledDashboardModules.remove(DashboardModuleId.aiHealthScore);
        await prefs.setStringList(
            _dashboardOrderKey, _dashboardOrder.map((m) => m.name).toList());
        await prefs.setStringList(_dashboardDisabledKey,
            _disabledDashboardModules.map((m) => m.name).toList());
        await prefs.setBool(
            'finora_migrated_health_above_transactions_v2', true);
      }

      if (!(prefs.getBool('finora_migrated_balanced_floating_cta_v1') ??
          false)) {
        _dockNavStyle = AppDockNavStyle.balancedFloatingCta;
        await prefs.setInt(
            _dockNavKey, AppDockNavStyle.balancedFloatingCta.index);
        await prefs.setBool('finora_migrated_balanced_floating_cta_v1', true);
      }

      if (!(prefs.getBool('finora_migrated_net_worth_modern_deck_v1') ??
          false)) {
        _heroCardStyle = AppHeroCardStyle.netWorthModernDeck;
        await prefs.setInt(
            _heroCardStyleKey, AppHeroCardStyle.netWorthModernDeck.index);
        await prefs.setBool('finora_migrated_net_worth_modern_deck_v1', true);
      }

      if (!(prefs.getBool('finora_migrated_zenvest_glass_deck_v1') ?? false)) {
        _heroCardStyle = AppHeroCardStyle.zenvestGlassDeck;
        await prefs.setInt(
            _heroCardStyleKey, AppHeroCardStyle.zenvestGlassDeck.index);
        await prefs.setBool('finora_migrated_zenvest_glass_deck_v1', true);
      }

      if (!(prefs.getBool('finora_migrated_brand_emerald_minimal_v1') ??
          false)) {
        _palette = AppColorPalette.emeraldWealth;
        _ambientBlur = AmbientBlurPreset.emeraldMatrix;
        _heroCardStyle = AppHeroCardStyle.zenvestGlassDeck;
        _dockNavStyle = AppDockNavStyle.balancedFloatingCta;
        await prefs.setInt(_paletteKey, AppColorPalette.emeraldWealth.index);
        await prefs.setInt(
            _ambientBlurKey, AmbientBlurPreset.emeraldMatrix.index);
        await prefs.setInt(
            _heroCardStyleKey, AppHeroCardStyle.zenvestGlassDeck.index);
        await prefs.setInt(
            _dockNavKey, AppDockNavStyle.balancedFloatingCta.index);
        await prefs.setBool('finora_migrated_brand_emerald_minimal_v1', true);
      }

      if (!(prefs.getBool('finora_migrated_v27_apple_minimalist_rev_1') ??
          false)) {
        _uiUxStyle = AppUiUxStyle.cupertinoMinimal;
        _palette = AppColorPalette.emeraldWealth;
        _ambientBlur = AmbientBlurPreset.emeraldMatrix;
        _heroCardStyle = AppHeroCardStyle.zenvestGlassDeck;
        _dockNavStyle = AppDockNavStyle.balancedFloatingCta;
        _surfaceStyle = CardSurfaceStyle.liquidGlass;
        _glassOpacity = 0.88;
        _glassBlur = 20.0;
        _fontFamily = AppFontFamily.beVietnamPro;
        await prefs.setInt(_uiUxStyleKey, AppUiUxStyle.cupertinoMinimal.index);
        await prefs.setInt(_paletteKey, AppColorPalette.emeraldWealth.index);
        await prefs.setInt(
            _ambientBlurKey, AmbientBlurPreset.emeraldMatrix.index);
        await prefs.setInt(
            _heroCardStyleKey, AppHeroCardStyle.zenvestGlassDeck.index);
        await prefs.setInt(
            _dockNavKey, AppDockNavStyle.balancedFloatingCta.index);
        await prefs.setInt(_surfaceKey, CardSurfaceStyle.liquidGlass.index);
        await prefs.setDouble(_glassOpacityKey, 0.88);
        await prefs.setDouble(_glassBlurKey, 20.0);
        await prefs.setInt(_fontFamilyKey, AppFontFamily.beVietnamPro.index);
        await prefs.setBool('finora_migrated_v27_apple_minimalist_rev_1', true);
      }

      if (!(prefs.getBool('finora_migrated_unified_pill_buttons_v2') ??
          false)) {
        _buttonShape = AppButtonShape.pill;
        _customButtonCornerRadius = null;
        await prefs.setInt(_buttonShapeKey, AppButtonShape.pill.index);
        await prefs.remove(_customButtonCornerRadiusKey);
        await prefs.setBool('finora_migrated_unified_pill_buttons_v2', true);
      }
    } catch (e) {
      debugPrint('[ThemeStudioController] load error: $e');
    }

    notifyListeners();
  }

  Future<void> setSystemWideLiquidGlass(bool val) async {
    _systemWideLiquidGlass = val;
    if (val) {
      _surfaceStyle = CardSurfaceStyle.liquidGlass;
      _widgetCardStyle = AppWidgetCardStyle.liquidGlassCard;
      _iconVisualEffect = AppIconVisualEffect.liquidGlass;
    }
    notifyListeners();
    performHaptic();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_systemWideLiquidGlassKey, val);
      await prefs.setInt(_surfaceKey, _surfaceStyle.index);
      await prefs.setInt(_widgetCardStyleKey, _widgetCardStyle.index);
      await prefs.setInt(_iconVisualEffectKey, _iconVisualEffect.index);
    } catch (_) {}
  }

  Future<void> setLiquidGlassSpecularHighlight(bool val) async {
    _liquidGlassSpecularHighlight = val;
    notifyListeners();
    performHaptic();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_liquidGlassSpecularHighlightKey, val);
    } catch (_) {}
  }

  Future<void> setLiquidGlassCausticRefraction(bool val) async {
    _liquidGlassCausticRefraction = val;
    notifyListeners();
    performHaptic();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_liquidGlassCausticRefractionKey, val);
    } catch (_) {}
  }

  Future<void> setSeasonalTheme(AppSeasonalTheme val) async {
    _seasonalTheme = val;
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seasonalThemeKey, val.index);
  }

  Future<void> setSystemIconPack(AppSystemIconPack val) async {
    _systemIconPack = val;
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_systemIconPackKey, val.index);
  }

  Future<void> setTabSelectStyle(AppTabSelectStyle val) async {
    _tabSelectStyle = val;
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tabSelectStyleKey, val.index);
  }

  Future<void> setButtonVisualKind(AppButtonStyle val) async {
    _buttonVisualKind = val;
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_buttonVisualKindKey, val.index);
  }

  Future<void> setButtonColorMode(AppButtonColorMode val,
      [Color? customColor]) async {
    _buttonColorMode = val;
    if (customColor != null) {
      _customButtonColor = customColor;
    }
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_buttonColorModeKey, val.index);
    if (_customButtonColor != null) {
      await prefs.setInt(_customButtonColorKey, _customButtonColor!.toARGB32());
    }
  }

  Future<void> setDockIconStyle(AppDockIconStyle val) async {
    _dockIconStyle = val;
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dockIconStyleKey, val.index);
  }

  Future<void> setDockOpacity(double val) async {
    _dockOpacity = val.clamp(0.05, 1.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_dockOpacityKey, _dockOpacity);
  }

  Future<void> setDockBlur(double val) async {
    _dockBlur = val.clamp(0.0, 40.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_dockBlurKey, _dockBlur);
  }

  Future<void> setDockActiveColor(Color? val) async {
    _dockActiveColor = val;
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    if (val != null) {
      await prefs.setInt(_dockActiveColorKey, val.toARGB32());
    } else {
      await prefs.remove(_dockActiveColorKey);
    }
  }

  Future<void> setDockInactiveColor(Color? val) async {
    _dockInactiveColor = val;
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    if (val != null) {
      await prefs.setInt(_dockInactiveColorKey, val.toARGB32());
    } else {
      await prefs.remove(_dockInactiveColorKey);
    }
  }

  Future<void> setDockPlusColor(Color? val) async {
    _dockPlusColor = val;
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    if (val != null) {
      await prefs.setInt(_dockPlusColorKey, val.toARGB32());
    } else {
      await prefs.remove(_dockPlusColorKey);
    }
  }

  Future<void> setWidgetCardStyle(AppWidgetCardStyle val) async {
    _widgetCardStyle = val;
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_widgetCardStyleKey, val.index);
  }

  Future<void> setCategoryIconStyle(AppCategoryIconStyle val) async {
    _categoryIconStyle = val;
    switch (val) {
      case AppCategoryIconStyle.modernSquircle:
        _iconShape = AppIconShape.squircle;
        _iconVisualEffect = AppIconVisualEffect.gradientFlow;
        break;
      case AppCategoryIconStyle.minimalCircle:
        _iconShape = AppIconShape.circle;
        _iconVisualEffect = AppIconVisualEffect.flatMinimal;
        break;
      case AppCategoryIconStyle.glassSphere:
        _iconShape = AppIconShape.circle;
        _iconVisualEffect = AppIconVisualEffect.liquidGlass;
        break;
      case AppCategoryIconStyle.duotoneTonal:
        _iconShape = AppIconShape.roundedSquare;
        _iconVisualEffect = AppIconVisualEffect.duotoneGlass;
        break;
      case AppCategoryIconStyle.neonBadge:
        _iconShape = AppIconShape.hexagon;
        _iconVisualEffect = AppIconVisualEffect.cyberNeon;
        break;
      case AppCategoryIconStyle.paperEmbossed:
        _iconShape = AppIconShape.squircle;
        _iconVisualEffect = AppIconVisualEffect.neumorphicSoft;
        break;
      case AppCategoryIconStyle.minimalOutline:
        _iconShape = AppIconShape.roundedSquare;
        _iconVisualEffect = AppIconVisualEffect.outlineMinimal;
        break;
      case AppCategoryIconStyle.diamondFacet:
        _iconShape = AppIconShape.diamond;
        _iconVisualEffect = AppIconVisualEffect.jewelCrystal;
        break;
    }
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_categoryIconStyleKey, val.index);
    await prefs.setInt(_iconShapeKey, _iconShape.index);
    await prefs.setInt(_iconVisualEffectKey, _iconVisualEffect.index);
  }

  Future<void> setIconBgColorMode(AppIconBgColorMode val) async {
    _iconBgColorMode = val;
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_iconBgColorModeKey, val.index);
  }

  Future<void> setIconGlyphColorMode(AppIconGlyphColorMode val) async {
    _iconGlyphColorMode = val;
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_iconGlyphColorModeKey, val.index);
  }

  Future<void> setIconBgOpacity(double val) async {
    _iconBgOpacity = val.clamp(0.05, 1.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_iconBgOpacityKey, _iconBgOpacity);
  }

  Future<void> setIconScale(double val) async {
    _iconScale = val.clamp(0.65, 1.45);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_iconScaleKey, _iconScale);
  }

  Future<void> setIconCornerRadius(double val) async {
    _iconCornerRadius = val.clamp(0.0, 36.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_iconCornerRadiusKey, _iconCornerRadius);
  }

  Future<void> setIconLabelScale(double val) async {
    _iconLabelScale = val.clamp(0.75, 1.35);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_iconLabelScaleKey, _iconLabelScale);
  }

  Color resolveIconGlyphColor(Color categoryColor, bool isDark) {
    switch (_iconGlyphColorMode) {
      case AppIconGlyphColorMode.pureWhite:
        return Colors.white;
      case AppIconGlyphColorMode.obsidianDark:
        return isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
      case AppIconGlyphColorMode.paletteAccent:
        return primaryColor;
      case AppIconGlyphColorMode.categoryOriginal:
        return categoryColor;
      case AppIconGlyphColorMode.goldLuxury:
        return const Color(0xFFF59E0B);
      case AppIconGlyphColorMode.cyberNeon:
        return const Color(0xFF06B6D4);
      case AppIconGlyphColorMode.neonPink:
        return const Color(0xFFEC4899);
      case AppIconGlyphColorMode.autoContrast:
        final effect = _iconVisualEffect;
        if (effect == AppIconVisualEffect.liquidGlass ||
            effect == AppIconVisualEffect.jewelCrystal ||
            effect == AppIconVisualEffect.gradientFlow ||
            _categoryIconStyle == AppCategoryIconStyle.modernSquircle ||
            _categoryIconStyle == AppCategoryIconStyle.glassSphere) {
          return Colors.white;
        } else if (effect == AppIconVisualEffect.cyberNeon) {
          return categoryColor;
        } else {
          return isDark
              ? categoryColor
              : Color.lerp(categoryColor, Colors.black, 0.15)!;
        }
    }
  }

  Color resolveIconBgColor(Color categoryColor, bool isDark) {
    switch (_iconBgColorMode) {
      case AppIconBgColorMode.paletteAccent:
        return primaryColor;
      case AppIconBgColorMode.glassMonochrome:
        return isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8);
      case AppIconBgColorMode.vibrantRich:
        return categoryColor;
      case AppIconBgColorMode.categoryOriginal:
        return categoryColor;
      case AppIconBgColorMode.obsidianDark:
        return isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B);
      case AppIconBgColorMode.frostedWhite:
        return isDark ? const Color(0xFFCBD5E1) : Colors.white;
      case AppIconBgColorMode.goldenAmber:
        return const Color(0xFFF59E0B);
      case AppIconBgColorMode.cyberNeon:
        return const Color(0xFF06B6D4);
      case AppIconBgColorMode.emeraldGlow:
        return const Color(0xFF10B981);
      case AppIconBgColorMode.rubySunset:
        return const Color(0xFFEF4444);
    }
  }

  Future<void> setAppBarScrollBehavior(AppAppBarScrollBehavior val) async {
    _appBarScrollBehavior = val;
    _pinHeader = (val == AppAppBarScrollBehavior.pinned);
    if (val == AppAppBarScrollBehavior.floating) {
      _topBarStyle = AppTopBarStyle.floatingIsland;
    } else if (_topBarStyle == AppTopBarStyle.floatingIsland) {
      _topBarStyle = AppTopBarStyle.seamlessBlend;
    }
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_appBarScrollBehaviorKey, val.index);
    await prefs.setInt(_topBarStyleKey, _topBarStyle.index);
    await prefs.setBool(_pinHeaderKey, _pinHeader);
  }

  Future<void> setHighRefreshRate120Hz(bool val) async {
    _highRefreshRate120Hz = val;
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highRefreshRate120HzKey, val);
    if (val) {
      await applyHighRefreshRateNative();
    }
  }

  Future<double> applyHighRefreshRateNative() async {
    try {
      const channel = MethodChannel('com.finora.display/refresh_rate');
      final result = await channel.invokeMethod<double>('enable120Hz');
      return result ?? 120.0;
    } catch (_) {
      return 120.0;
    }
  }

  Future<double> getNativeRefreshRate() async {
    try {
      const channel = MethodChannel('com.finora.display/refresh_rate');
      final result = await channel.invokeMethod<double>('getRefreshRate');
      return result ?? 120.0;
    } catch (_) {
      return 120.0;
    }
  }

  Future<void> setLoadingStyle(AppLoadingIndicatorStyle val) async {
    _loadingStyle = val;
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_loadingStyleKey, val.index);
  }

  (String, IconData, Color)? getSeasonalBadge() {
    return switch (_seasonalTheme) {
      AppSeasonalTheme.springTet => (
          'Tết Giáp Thìn · Lộc Phát',
          Icons.celebration_rounded,
          const Color(0xFFDC2626)
        ),
      AppSeasonalTheme.summerBreeze => (
          'Hè Rực Rỡ · Sóng Biển',
          Icons.wb_sunny_rounded,
          const Color(0xFF0284C7)
        ),
      AppSeasonalTheme.autumnAmber => (
          'Thu Vàng · Trăng Rằm',
          Icons.eco_rounded,
          const Color(0xFFD97706)
        ),
      AppSeasonalTheme.winterChristmas => (
          'Đông Băng Giá & Giáng Sinh',
          Icons.ac_unit_rounded,
          const Color(0xFF059669)
        ),
      AppSeasonalTheme.none => null,
    };
  }

  Color? getSeasonalAccentColor() {
    return switch (_seasonalTheme) {
      AppSeasonalTheme.springTet => const Color(0xFFDC2626),
      AppSeasonalTheme.summerBreeze => const Color(0xFF00C4B4),
      AppSeasonalTheme.autumnAmber => const Color(0xFFD97706),
      AppSeasonalTheme.winterChristmas => const Color(0xFF059669),
      AppSeasonalTheme.none => null,
    };
  }

  BoxDecoration getWidgetCardDecoration({
    required bool isDark,
    Color? customBg,
    double? customRadius,
    Border? customBorder,
  }) {
    final radius = customRadius ?? cardCornerRadius;
    final primary = resolvedPrimary;
    final Border? effectiveBorder;
    if (customBorder != null) {
      effectiveBorder = customBorder;
    } else if (_widgetBorderWidth <= 0.05) {
      effectiveBorder = null;
    } else if (_borderGlowStyle == CardBorderGlowStyle.none) {
      effectiveBorder = Border.all(
        color: (isDark ? Colors.white : Colors.black)
            .withValues(alpha: isDark ? 0.12 : 0.08),
        width: _widgetBorderWidth,
      );
    } else {
      final base = getCardBorder(isDark);
      effectiveBorder = base != null
          ? Border.all(
              color: base.top.color,
              width: _widgetBorderWidth,
            )
          : Border.all(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: isDark ? 0.12 : 0.08),
              width: _widgetBorderWidth,
            );
    }
    final glowShadows = getGlowShadows(isDark);

    final effectiveGlassOpacity = glassOpacity.clamp(0.15, 1.0);

    switch (_widgetCardStyle) {
      case AppWidgetCardStyle.liquidGlassCard:
        final bool isDefaultCardBase = customBg == null ||
            customBg == Colors.white ||
            (customBg.r >= 0.90 && customBg.g >= 0.90 && customBg.b >= 0.90) ||
            (isDark &&
                (customBg.r < 0.15 && customBg.g < 0.15 && customBg.b < 0.20));
        final glassGrad = isDefaultCardBase
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Color.alphaBlend(primary.withValues(alpha: 0.12),
                                const Color(0xFF142036))
                            .withValues(
                                alpha:
                                    (_glassOpacity * 0.96).clamp(0.15, 0.96)),
                        const Color(0xFF0C1424).withValues(
                            alpha: (_glassOpacity * 0.98).clamp(0.18, 0.98)),
                      ]
                    : [
                        Colors.white.withValues(
                            alpha: (_glassOpacity * 0.98).clamp(0.15, 0.98)),
                        Color.alphaBlend(primary.withValues(alpha: 0.05),
                                const Color(0xFFF6F9FD))
                            .withValues(
                                alpha:
                                    (_glassOpacity * 0.94).clamp(0.15, 0.96)),
                      ],
              )
            : null;
        return BoxDecoration(
          color: isDefaultCardBase
              ? null
              : applyWhiteTransparency(customBg, isDark: isDark),
          gradient: glassGrad,
          borderRadius: BorderRadius.circular(radius),
          border: _widgetBorderWidth <= 0.05
              ? null
              : (effectiveBorder ??
                  Border.all(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: isDark ? 0.12 : 0.08),
                    width: _widgetBorderWidth,
                  )),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.28)
                  : const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: isDark ? 16 : 12,
              spreadRadius: -2,
              offset: const Offset(0, 4),
            ),
            if (_borderGlowStyle != CardBorderGlowStyle.none)
              BoxShadow(
                color: primary.withValues(alpha: isDark ? 0.08 : 0.04),
                blurRadius: 18,
                spreadRadius: -3,
                offset: const Offset(0, 5),
              ),
          ],
        );
      case AppWidgetCardStyle.solidCleanCard:
        return BoxDecoration(
          color: customBg != null
              ? applyWhiteTransparency(customBg, isDark: isDark)
              : (isDark ? const Color(0xFF182030) : const Color(0xFFFFFFFF))
                  .withValues(alpha: effectiveGlassOpacity),
          borderRadius: BorderRadius.circular(radius),
          border: _widgetBorderWidth <= 0.05
              ? null
              : (effectiveBorder ??
                  Border.all(
                    color: (isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0)),
                    width: _widgetBorderWidth,
                  )),
          boxShadow: [
            ...glowShadows,
            if (!isDark)
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        );
      case AppWidgetCardStyle.elevatedShadowCard:
        return BoxDecoration(
          color: customBg != null
              ? applyWhiteTransparency(customBg, isDark: isDark)
              : (isDark ? const Color(0xFF1A2234) : Colors.white)
                  .withValues(alpha: effectiveGlassOpacity),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            ...glowShadows,
            BoxShadow(
              color: (isDark ? Colors.black : const Color(0xFF0F172A))
                  .withValues(alpha: isDark ? 0.20 : 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
          border: _widgetBorderWidth <= 0.05
              ? null
              : (effectiveBorder ??
                  Border.all(
                    color: (isDark ? Colors.white : const Color(0xFFE2E8F0))
                        .withValues(alpha: isDark ? 0.08 : 0.80),
                    width: _widgetBorderWidth,
                  )),
        );
      case AppWidgetCardStyle.minimalOutlineCard:
        return BoxDecoration(
          color: customBg != null
              ? applyWhiteTransparency(customBg, isDark: isDark)
              : (isDark ? const Color(0xFF0F172A) : Colors.white).withValues(
                  alpha:
                      isDark ? (glassOpacity * 0.40).clamp(0.05, 0.95) : 0.92),
          borderRadius: BorderRadius.circular(radius),
          border: _widgetBorderWidth <= 0.05
              ? null
              : (effectiveBorder ??
                  Border.all(
                    color: primary.withValues(alpha: isDark ? 0.35 : 0.25),
                    width: _widgetBorderWidth,
                  )),
          boxShadow: glowShadows.isNotEmpty ? glowShadows : null,
        );
      case AppWidgetCardStyle.tonalAccentCard:
        return BoxDecoration(
          color: customBg != null
              ? applyWhiteTransparency(customBg, isDark: isDark)
              : primary.withValues(
                  alpha: ((isDark ? 0.16 : 0.09) * (glassOpacity / 0.65))
                      .clamp(0.04, 0.50)),
          borderRadius: BorderRadius.circular(radius),
          border: _widgetBorderWidth <= 0.05
              ? null
              : (effectiveBorder ??
                  Border.all(
                    color: primary.withValues(alpha: isDark ? 0.24 : 0.16),
                    width: _widgetBorderWidth,
                  )),
          boxShadow: glowShadows.isNotEmpty ? glowShadows : null,
        );
    }
  }

  Decoration getCategoryIconDecoration({
    required bool isDark,
    required Color categoryColor,
    double size = 40,
  }) {
    // Luôn áp dụng sự kết hợp giữa AppIconShape và AppIconVisualEffect đã chọn
    return getIconContainerDecoration(
      color: categoryColor,
      isDark: isDark,
      size: size,
    );
  }

  Future<void> setAppBarOpacity(double val) async {
    _appBarOpacity = val.clamp(0.0, 1.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_appBarOpacityKey, _appBarOpacity);
  }

  Future<void> setAppBarBlur(double val) async {
    _appBarBlur = val.clamp(0.0, 30.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_appBarBlurKey, _appBarBlur);
  }

  Future<void> setAppBarShowBorder(bool val) async {
    _appBarShowBorder = val;
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appBarShowBorderKey, val);
  }

  Future<void> setTopBarStyle(AppTopBarStyle val) async {
    _topBarStyle = val;
    switch (val) {
      case AppTopBarStyle.seamlessBlend:
        _appBarScrollBehavior = AppAppBarScrollBehavior.pinned;
        _appBarOpacity = 0.55;
        _appBarBlur = 18.0;
        _appBarShowBorder = true;
        break;
      case AppTopBarStyle.frostedGlass:
        _appBarScrollBehavior = AppAppBarScrollBehavior.pinned;
        _appBarOpacity = 0.78;
        _appBarBlur = 28.0;
        _appBarShowBorder = true;
        break;
      case AppTopBarStyle.floatingIsland:
        _appBarScrollBehavior = AppAppBarScrollBehavior.floating;
        _appBarOpacity = 0.85;
        _appBarBlur = 24.0;
        _appBarShowBorder = true;
        break;
      case AppTopBarStyle.pureMinimal:
        _appBarScrollBehavior = AppAppBarScrollBehavior.pinned;
        _appBarOpacity = 0.0;
        _appBarBlur = 0.0;
        _appBarShowBorder = false;
        break;
    }
    _pinHeader = (_appBarScrollBehavior == AppAppBarScrollBehavior.pinned);
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_topBarStyleKey, val.index);
    await prefs.setInt(_appBarScrollBehaviorKey, _appBarScrollBehavior.index);
    await prefs.setDouble(_appBarOpacityKey, _appBarOpacity);
    await prefs.setDouble(_appBarBlurKey, _appBarBlur);
    await prefs.setBool(_appBarShowBorderKey, _appBarShowBorder);
    await prefs.setBool(_pinHeaderKey, _pinHeader);
  }

  Future<void> setPinHeader(bool val) async {
    _pinHeader = val;
    _appBarScrollBehavior = val
        ? AppAppBarScrollBehavior.pinned
        : AppAppBarScrollBehavior.scrollHide;
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinHeaderKey, _pinHeader);
    await prefs.setInt(_appBarScrollBehaviorKey, _appBarScrollBehavior.index);
  }

  Future<void> setWalletViewStyle(AppWalletViewStyle val) async {
    _walletViewStyle = val;
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_walletViewStyleKey, _walletViewStyle.index);
  }

  Future<void> setUiUxStyle(AppUiUxStyle val) async {
    await setFreshAppearance(false);
    _uiUxStyle = val;
    if (val == AppUiUxStyle.googleMinimal) {
      _surfaceStyle = CardSurfaceStyle.solidModern;
      _widgetCardStyle = AppWidgetCardStyle.solidCleanCard;
      _systemWideLiquidGlass = false;
      _liquidGlassSpecularHighlight = false;
      _liquidGlassCausticRefraction = false;
      _glassOpacity = 1.0;
      _glassBlur = 0.0;
      _appBarBlur = 0.0;
      _dockBlur = 0.0;
      _dockOpacity = 1.0;
      _topBarStyle = AppTopBarStyle.seamlessBlend;
      _dockNavStyle = AppDockNavStyle.classicDock;
      _systemIconPack = AppSystemIconPack.materialExpressive;
      _dockIconStyle = AppDockIconStyle.materialSystem;
      _iconVisualEffect = AppIconVisualEffect.flatMinimal;
      _particleSparkles = false;
      _ambientIntensity = 0.0;
      _loadingStyle = AppLoadingIndicatorStyle.infinityDots;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_uiUxStyleKey, val.index);
    if (val == AppUiUxStyle.googleMinimal) {
      await prefs.setInt(_surfaceKey, _surfaceStyle.index);
      await prefs.setInt(_widgetCardStyleKey, _widgetCardStyle.index);
      await prefs.setBool(_systemWideLiquidGlassKey, false);
      await prefs.setBool(_liquidGlassSpecularHighlightKey, false);
      await prefs.setBool(_liquidGlassCausticRefractionKey, false);
      await prefs.setDouble(_glassOpacityKey, 1.0);
      await prefs.setDouble(_glassBlurKey, 0.0);
      await prefs.setDouble(_appBarBlurKey, 0.0);
      await prefs.setDouble(_dockBlurKey, 0.0);
      await prefs.setDouble(_dockOpacityKey, 1.0);
      await prefs.setInt(_topBarStyleKey, _topBarStyle.index);
      await prefs.setInt(_dockNavKey, _dockNavStyle.index);
      await prefs.setInt(_systemIconPackKey, _systemIconPack.index);
      await prefs.setInt(_dockIconStyleKey, _dockIconStyle.index);
      await prefs.setInt(_iconVisualEffectKey, _iconVisualEffect.index);
      await prefs.setBool(_particleSparklesKey, false);
      await prefs.setDouble(_ambientIntensityKey, 0.0);
      await prefs.setInt(_loadingStyleKey, _loadingStyle.index);
    }
  }

  Future<void> setGradientVibrancy(double val) async {
    _gradientVibrancy = val.clamp(0.5, 2.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_gradientVibrancyKey, _gradientVibrancy);
  }

  Future<void> setPalette(AppColorPalette val) async {
    await setFreshAppearance(false);
    _palette = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_paletteKey, val.index);
  }

  Future<void> setAmbientBlur(AmbientBlurPreset val) async {
    _ambientBlur = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_ambientBlurKey, val.index);
  }

  Future<void> setGlobalDensity(CardDensity val) async {
    _globalDensity = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_densityKey, val.index);
  }

  Future<void> setDashboardDensity(CardDensity val) async {
    _dashboardDensity = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dashDensityKey, val.index);
  }

  Future<void> setTransactionDensity(CardDensity val) async {
    _transactionDensity = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_txDensityKey, val.index);
  }

  Future<void> setSurfaceStyle(CardSurfaceStyle val) async {
    _surfaceStyle = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_surfaceKey, val.index);
  }

  Future<void> setCornerStyle(CardCornerStyle val) async {
    _cornerStyle = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cornerKey, val.index);
  }

  Future<void> setShadowIntensity(CardShadowIntensity val) async {
    _shadowIntensity = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_shadowKey, val.index);
  }

  Future<void> setShowAiInsight(bool val) async {
    _showAiInsight = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showAiInsightKey, val);
  }

  Future<void> setShowQuickLog(bool val) async {
    _showQuickLog = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showQuickLogKey, val);
  }

  Future<void> setGlassOpacity(double val) async {
    _glassOpacity = val.clamp(0.08, 1.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_glassOpacityKey, _glassOpacity);
  }

  Future<void> setGlassBlur(double val) async {
    _glassBlur = val.clamp(0.0, 32.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_glassBlurKey, _glassBlur);
  }

  Future<void> setPageHorizontalMargin(double val) async {
    _pageHorizontalMargin = val.clamp(8.0, 32.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_pageHorizontalMarginKey, _pageHorizontalMargin);
  }

  Future<void> setWidgetBorderWidth(double val) async {
    _widgetBorderWidth = val.clamp(0.0, 3.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_widgetBorderWidthKey, _widgetBorderWidth);
  }

  Future<void> setCardCornerRadius(double val) async {
    _customCardCornerRadius = val.clamp(4.0, 36.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_customCardCornerRadiusKey, _customCardCornerRadius!);
  }

  Future<void> setCustomCardCornerRadius(double val) =>
      setCardCornerRadius(val);

  Future<void> setButtonCornerRadius(double val) async {
    _customButtonCornerRadius = val.clamp(4.0, 28.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(
        _customButtonCornerRadiusKey, _customButtonCornerRadius!);
  }

  Future<void> setCustomButtonCornerRadius(double val) =>
      setButtonCornerRadius(val);

  Future<void> setPageVerticalGap(double val) async {
    _pageVerticalGap = val.clamp(6.0, 28.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_pageVerticalGapKey, _pageVerticalGap);
  }

  Future<void> setDockHeightScale(double val) async {
    _dockHeightScale = val.clamp(0.80, 1.30);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_dockHeightScaleKey, _dockHeightScale);
  }

  Future<void> setChartHeightScale(double val) async {
    _chartHeightScale = val.clamp(0.70, 1.40);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_chartHeightScaleKey, _chartHeightScale);
  }

  Future<void> setChartShowAreaFill(bool val) async {
    _chartShowAreaFill = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chartShowAreaFillKey, _chartShowAreaFill);
  }

  Future<void> setChartShowGridLines(bool val) async {
    _chartShowGridLines = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chartShowGridLinesKey, _chartShowGridLines);
  }

  Future<void> setChartSmoothness(double val) async {
    _chartSmoothness = val.clamp(0.0, 1.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_chartSmoothnessKey, _chartSmoothness);
  }

  Future<void> setButtonShape(AppButtonShape val) async {
    _buttonShape = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_buttonShapeKey, val.index);
  }

  Future<void> setIconShape(AppIconShape val) async {
    _iconShape = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_iconShapeKey, val.index);
  }

  Future<void> setIconVisualEffect(AppIconVisualEffect val) async {
    _iconVisualEffect = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_iconVisualEffectKey, val.index);
  }

  Future<void> setIconStyle(AppIconStyle val) async {
    _iconStyle = val;
    switch (val) {
      case AppIconStyle.round:
        _iconShape = AppIconShape.circle;
        _iconVisualEffect = AppIconVisualEffect.flatMinimal;
      case AppIconStyle.softSquare:
        _iconShape = AppIconShape.squircle;
        _iconVisualEffect = AppIconVisualEffect.flatMinimal;
      case AppIconStyle.dimensional:
        _iconShape = AppIconShape.squircle;
        _iconVisualEffect = AppIconVisualEffect.liquidGlass;
      case AppIconStyle.glassGlow:
        _iconShape = AppIconShape.circle;
        _iconVisualEffect = AppIconVisualEffect.cyberNeon;
      case AppIconStyle.neumorphicSoft:
        _iconShape = AppIconShape.squircle;
        _iconVisualEffect = AppIconVisualEffect.neumorphicSoft;
      case AppIconStyle.cyberNeonWireframe:
        _iconShape = AppIconShape.roundedSquare;
        _iconVisualEffect = AppIconVisualEffect.outlineMinimal;
      case AppIconStyle.jewelCrystal:
        _iconShape = AppIconShape.hexagon;
        _iconVisualEffect = AppIconVisualEffect.jewelCrystal;
      case AppIconStyle.duotoneGlass:
        _iconShape = AppIconShape.squircle;
        _iconVisualEffect = AppIconVisualEffect.duotoneGlass;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_iconStyleKey, val.index);
    await prefs.setInt(_iconShapeKey, _iconShape.index);
    await prefs.setInt(_iconVisualEffectKey, _iconVisualEffect.index);
  }

  Future<void> setButtonSize(AppButtonSize val) async {
    _buttonSize = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_buttonSizeKey, val.index);
  }

  Future<void> setFontScale(double val) async {
    _fontScale = val.clamp(0.85, 1.25);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, _fontScale);
  }

  Future<void> setFontFamily(AppFontFamily val) async {
    _fontFamily = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_fontFamilyKey, val.index);
  }

  Future<void> setBorderGlowStyle(CardBorderGlowStyle val) async {
    _borderGlowStyle = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_borderGlowKey, val.index);
  }

  Future<void> setMotionDynamics(AppMotionDynamics val) async {
    _motionDynamics = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_motionKey, val.index);
  }

  Future<void> setHapticEnabled(bool val) async {
    _hapticEnabled = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticKey, val);
  }

  Future<void> setPrivacyShieldDefault(bool val) async {
    _privacyShieldDefault = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyKey, val);
  }

  Future<void> setPrivacyStyle(AppPrivacyStyle val) async {
    _privacyStyle = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_privacyStyleKey, val.index);
  }

  void togglePrivacyShield() {
    _isPrivacyShieldActive = !_isPrivacyShieldActive;
    notifyListeners();
  }

  void setPrivacyShieldActive(bool val) {
    _isPrivacyShieldActive = val;
    notifyListeners();
  }

  Future<void> toggleDashboardModule(DashboardModuleId id) async {
    if (_disabledDashboardModules.contains(id)) {
      _disabledDashboardModules.remove(id);
    } else {
      _disabledDashboardModules.add(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _dashboardDisabledKey,
      _disabledDashboardModules.map((m) => m.name).toList(),
    );
  }

  Future<void> reorderDashboardModules(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _dashboardOrder.removeAt(oldIndex);
    _dashboardOrder.insert(newIndex, item);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _dashboardOrderKey,
      _dashboardOrder.map((m) => m.name).toList(),
    );
  }

  Future<void> resetDashboardModules() async {
    _dashboardOrder = List.from(defaultDashboardOrder);
    _disabledDashboardModules.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dashboardOrderKey);
    await prefs.remove(_dashboardDisabledKey);
  }

  Future<void> setCurrencyFormat(AppCurrencyFormat val) async {
    _currencyFormat = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currencyKey, val.index);
  }

  Future<void> setDockNavStyle(AppDockNavStyle val) async {
    _dockNavStyle = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dockNavKey, val.index);
  }

  Future<void> setWallpaperPreset(AppWallpaperPreset val) async {
    _wallpaperPreset = AppWallpaperPreset.none;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_wallpaperKey, AppWallpaperPreset.none.index);
  }

  Future<void> setAmbientIntensity(double val) async {
    _ambientIntensity = val.clamp(0.1, 1.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_ambientIntensityKey, _ambientIntensity);
  }

  Future<void> setParticleSparkles(bool val) async {
    _particleSparkles = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_particleSparklesKey, val);
  }

  Future<void> setBudgetStyle(AppBudgetStyle val) async {
    _budgetStyle = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_budgetStyleKey, val.index);
  }

  Future<void> setGoalStyle(AppGoalStyle val) async {
    _goalStyle = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_goalStyleKey, val.index);
  }

  Future<void> setHapticIntensity(AppHapticIntensity val) async {
    _hapticIntensity = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hapticIntensityKey, val.index);
  }

  Future<void> setTransactionSound(AppTransactionSound val) async {
    _transactionSound = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_transactionSoundKey, val.index);
  }

  Future<void> setTransactionListStyle(AppTransactionListStyle val) async {
    _transactionListStyle = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_transactionListStyleKey, val.index);
  }

  void performHaptic() {
    if (!_hapticEnabled) return;
    switch (_hapticIntensity) {
      case AppHapticIntensity.subtle:
        HapticFeedback.selectionClick();
        break;
      case AppHapticIntensity.crisp:
        HapticFeedback.lightImpact();
        break;
      case AppHapticIntensity.heavy:
        HapticFeedback.mediumImpact();
        break;
    }
  }

  Future<void> _saveCustomPalettes() async {
    final prefs = await SharedPreferences.getInstance();
    final strList = _customPalettes.map((p) {
      return jsonEncode({
        'id': p.customId,
        'title': p.title,
        'subtitle': p.subtitle,
        'primary': p.primary.toARGB32(),
        'secondary': p.secondary.toARGB32(),
        'lightBg': p.lightBg.toARGB32(),
        'darkBg': p.darkBg.toARGB32(),
        'heroGradient': p.heroGradient.map((c) => c.toARGB32()).toList(),
      });
    }).toList();
    await prefs.setStringList(_customPalettesKey, strList);
    if (_selectedCustomPaletteId != null) {
      await prefs.setString(
          _selectedCustomPaletteIdKey, _selectedCustomPaletteId!);
    } else {
      await prefs.remove(_selectedCustomPaletteIdKey);
    }
  }

  Future<void> addCustomPalette(PaletteMeta meta) async {
    _customPalettes.removeWhere((p) => p.customId == meta.customId);
    _customPalettes.add(meta);
    _selectedCustomPaletteId = meta.customId;
    _palette = AppColorPalette.custom;
    notifyListeners();
    await _saveCustomPalettes();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_paletteKey, _palette.index);
  }

  Future<void> selectCustomPalette(String id) async {
    _selectedCustomPaletteId = id;
    _palette = AppColorPalette.custom;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedCustomPaletteIdKey, id);
    await prefs.setInt(_paletteKey, _palette.index);
  }

  Future<void> deleteCustomPalette(String id) async {
    _customPalettes.removeWhere((p) => p.customId == id);
    if (_selectedCustomPaletteId == id) {
      if (_customPalettes.isNotEmpty) {
        _selectedCustomPaletteId = _customPalettes.first.customId;
      } else {
        _selectedCustomPaletteId = null;
        _palette = AppColorPalette.oceanicSapphire;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_paletteKey, _palette.index);
      }
    }
    notifyListeners();
    await _saveCustomPalettes();
  }

  Future<void> setGlobalCardSkin(AppCardSkinStyle val) async {
    _globalCardSkin = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_globalCardSkinKey, val.index);
  }

  Future<void> setWalletCardSkin(String walletId, String skinName) async {
    _walletCardSkins[walletId] = skinName;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_walletCardSkinsKey, jsonEncode(_walletCardSkins));
  }

  Future<void> removeWalletCardSkin(String walletId) async {
    if (_walletCardSkins.remove(walletId) != null) {
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_walletCardSkinsKey, jsonEncode(_walletCardSkins));
    }
  }

  Future<void> setCustomCardGradientColors(List<Color> colors) async {
    _customCardGradientColors = List.from(colors);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customCardGradientKey,
        colors.map((c) => c.toARGB32().toString()).toList());
  }

  Future<void> setCustomCardGradient(List<Color> colors) =>
      setCustomCardGradientColors(colors);

  Future<void> setHeroCardTint(AppHeroCardTint val) async {
    _heroCardTint = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_heroCardTintKey, val.index);
  }

  Future<void> setStatsCardTint(AppStatsCardTint val) async {
    _statsCardTint = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_statsCardTintKey, val.index);
  }

  Future<void> setExpenseColor(Color? val) async {
    _expenseColor = val ?? const Color(0xFFEF4444);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (val != null) {
      await prefs.setInt(_expenseColorKey, val.toARGB32());
    } else {
      await prefs.remove(_expenseColorKey);
    }
  }

  Future<void> setIncomeColor(Color? val) async {
    _incomeColor = val ?? const Color(0xFF10B981);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (val != null) {
      await prefs.setInt(_incomeColorKey, val.toARGB32());
    } else {
      await prefs.remove(_incomeColorKey);
    }
  }

  Future<void> setTransferColor(Color? val) async {
    _transferColor = val ?? const Color(0xFF3B82F6);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (val != null) {
      await prefs.setInt(_transferColorKey, val.toARGB32());
    } else {
      await prefs.remove(_transferColorKey);
    }
  }

  Future<void> setBudgetColors(
      {Color? safe, Color? warning, Color? danger}) async {
    if (safe != null) {
      _budgetSafeColor = safe;
    }
    if (warning != null) {
      _budgetWarningColor = warning;
    }
    if (danger != null) {
      _budgetDangerColor = danger;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (safe != null) {
      await prefs.setInt(_budgetSafeColorKey, safe.toARGB32());
    }
    if (warning != null) {
      await prefs.setInt(_budgetWarningColorKey, warning.toARGB32());
    }
    if (danger != null) {
      await prefs.setInt(_budgetDangerColorKey, danger.toARGB32());
    }
  }

  Future<void> setCustomBgGradient(
      {required List<Color> colors,
      int angle = 0,
      List<Color>? colorsLight}) async {
    _customBgGradientColors = List.from(colors);
    if (colorsLight != null) {
      _customBgGradientColorsLight = List.from(colorsLight);
    } else {
      _customBgGradientColorsLight =
          colors.map((c) => Color.lerp(c, Colors.white, 0.88)!).toList();
    }
    _customBgGradientAngle = angle;
    _useCustomBgGradient = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customBgGradientKey,
        colors.map((c) => c.toARGB32().toString()).toList());
    if (colorsLight != null) {
      await prefs.setStringList('${_customBgGradientKey}_light',
          colorsLight.map((c) => c.toARGB32().toString()).toList());
    }
    await prefs.setInt(_customBgGradientAngleKey, angle);
    await prefs.setBool('finora_studio_use_custom_bg_gradient', true);
  }

  Future<void> setCustomGradientDirect({
    required Color startColor,
    required Color endColor,
    required bool isDark,
    int? angle,
  }) async {
    if (isDark) {
      _customBgGradientColors = [startColor, endColor];
    } else {
      _customBgGradientColorsLight = [startColor, endColor];
    }
    if (angle != null) {
      _customBgGradientAngle = angle;
    }
    _useCustomBgGradient = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _customBgGradientKey,
      _customBgGradientColors.map((c) => c.toARGB32().toString()).toList(),
    );
    await prefs.setStringList(
      '${_customBgGradientKey}_light',
      _customBgGradientColorsLight.map((c) => c.toARGB32().toString()).toList(),
    );
    if (angle != null) {
      await prefs.setInt(_customBgGradientAngleKey, angle);
    }
    await prefs.setBool('finora_studio_use_custom_bg_gradient', true);
  }

  Future<void> setPreserveBankCardColors(bool val) async {
    _preserveBankCardColors = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('finora_studio_preserve_bank_card_colors', val);
  }

  Future<void> setUseCustomBgGradient(bool val) async {
    _useCustomBgGradient = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('finora_studio_use_custom_bg_gradient', val);
  }

  Future<void> setBackgroundTintOpacity(double val) async {
    _backgroundTintOpacity = val.clamp(0.05, 1.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(
        'finora_studio_bg_tint_opacity', _backgroundTintOpacity);
  }

  Future<void> setBackgroundBlurSigma(double val) async {
    _backgroundBlurSigma = val.clamp(0.0, 60.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('finora_studio_bg_blur_sigma', _backgroundBlurSigma);
  }

  Future<void> setUseCustomRgbMeshBg(bool val) async {
    _useCustomRgbMeshBg = val;
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useCustomRgbMeshBgKey, val);
  }

  Future<void> setCustomBgColor1(Color val) async {
    _customBgColor1 = val;
    _useCustomRgbMeshBg = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_customBgColor1Key, val.toARGB32());
    await prefs.setBool(_useCustomRgbMeshBgKey, true);
  }

  Future<void> setCustomBgColor2(Color val) async {
    _customBgColor2 = val;
    _useCustomRgbMeshBg = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_customBgColor2Key, val.toARGB32());
    await prefs.setBool(_useCustomRgbMeshBgKey, true);
  }

  Future<void> setCustomBgColor3(Color val) async {
    _customBgColor3 = val;
    _useCustomRgbMeshBg = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_customBgColor3Key, val.toARGB32());
    await prefs.setBool(_useCustomRgbMeshBgKey, true);
  }

  Future<void> setCustomBgIntensity(double val) async {
    _customBgIntensity = val.clamp(0.0, 0.45);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_customBgIntensityKey, _customBgIntensity);
  }

  Future<void> setCustomBgBlur(double val) async {
    _customBgBlur = val.clamp(20.0, 100.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_customBgBlurKey, _customBgBlur);
  }

  Future<void> setMeshBlendStyle(MeshBlendStyle val) async {
    _meshBlendStyle = val;
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_meshBlendStyleKey, val.index);
  }

  Future<void> applyRgbMeshPreset(
    Color c1,
    Color c2,
    Color c3, {
    double intensity = 0.18,
  }) async {
    _useCustomRgbMeshBg = true;
    _customBgColor1 = c1;
    _customBgColor2 = c2;
    _customBgColor3 = c3;
    _customBgIntensity = intensity.clamp(0.0, 0.45);
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useCustomRgbMeshBgKey, true);
    await prefs.setInt(_customBgColor1Key, c1.toARGB32());
    await prefs.setInt(_customBgColor2Key, c2.toARGB32());
    await prefs.setInt(_customBgColor3Key, c3.toARGB32());
    await prefs.setDouble(_customBgIntensityKey, _customBgIntensity);
  }

  Future<void> setDockLabelStyle(AppDockLabelStyle val) async {
    _dockLabelStyle = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dockLabelStyleKey, val.index);
  }

  Future<void> setHeroCardStyle(AppHeroCardStyle val) async {
    _heroCardStyle = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_heroCardStyleKey, val.index);
  }

  Future<void> setHeroBalanceSize(AppHeroBalanceSize val) async {
    _heroBalanceSize = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_heroBalanceSizeKey, val.index);
  }

  Future<void> setAvatarGlowStyle(AppAvatarGlowStyle val) async {
    _avatarGlowStyle = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_avatarGlowStyleKey, val.index);
  }

  Future<void> setMembershipTier(AppMembershipTierBadge val) async {
    _membershipTier = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_membershipTierKey, val.index);
  }

  Future<void> setAiBubbleStyle(AppAiBubbleStyle val) async {
    _aiBubbleStyle = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_aiBubbleStyleKey, val.index);
  }

  Future<void> setAiAvatarIcon(AppAiAvatarIcon val) async {
    _aiAvatarIcon = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_aiAvatarIconKey, val.index);
  }

  Future<void> setChartCurveStyle(AppChartCurveStyle val) async {
    _chartCurveStyle = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_chartCurveStyleKey, val.index);
  }

  Future<void> setChartAreaFill(AppChartAreaFill val) async {
    _chartAreaFill = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_chartAreaFillKey, val.index);
  }

  Future<void> setChartColorway(AppChartColorway val) async {
    _chartColorway = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_chartColorwayKey, val.index);
  }

  static const List<MasterUiPresetMeta> allMasterUiPresets = [
    MasterUiPresetMeta(
      preset: AppMasterUiPreset.cyberpunk2077,
      title: 'Cyberpunk 2077',
      subtitle: 'Tương lai công nghệ cao Neon & Terminal',
      tag: 'NEON MATRIX',
      icon: Icons.electric_bolt_rounded,
      gradientColors: [Color(0xFFFF2A85), Color(0xFF00E5FF)],
      palette: AppColorPalette.cyberNeonPink,
      uiUxStyle: AppUiUxStyle.cyberNeon,
      wallpaper: AppWallpaperPreset.midnightDark,
      iconStyle: AppIconStyle.cyberNeonWireframe,
      heroCardStyle: AppHeroCardStyle.executiveBlackVip,
      dockNavStyle: AppDockNavStyle.glassNeonUnderline,
      dockLabelStyle: AppDockLabelStyle.selectedOnly,
      avatarGlow: AppAvatarGlowStyle.cyberCyan,
      membershipTier: AppMembershipTierBadge.diamondCrown,
      aiBubbleStyle: AppAiBubbleStyle.cyberTerminal,
      aiAvatarIcon: AppAiAvatarIcon.cyberRobot,
      chartCurveStyle: AppChartCurveStyle.straightSharp,
      chartAreaFill: AppChartAreaFill.neonGlow,
      chartColorway: AppChartColorway.cyberpunkVibrant,
      cardSkin: AppCardSkinStyle.cyberNeon,
      cornerStyle: CardCornerStyle.sharp,
    ),
    MasterUiPresetMeta(
      preset: AppMasterUiPreset.royalCenturion,
      title: 'Royal Centurion Gold',
      subtitle: 'Hoàng gia Vàng Đen & Thẻ VIP Thượng lưu',
      tag: 'VIP LUXURY',
      icon: Icons.workspace_premium_rounded,
      gradientColors: [Color(0xFFD4AF37), Color(0xFF1E2430)],
      palette: AppColorPalette.obsidianGold,
      uiUxStyle: AppUiUxStyle.luxuryObsidian,
      wallpaper: AppWallpaperPreset.midnightDark,
      iconStyle: AppIconStyle.jewelCrystal,
      heroCardStyle: AppHeroCardStyle.executiveBlackVip,
      dockNavStyle: AppDockNavStyle.pillTabs,
      dockLabelStyle: AppDockLabelStyle.always,
      avatarGlow: AppAvatarGlowStyle.goldVip,
      membershipTier: AppMembershipTierBadge.goldCenturion,
      aiBubbleStyle: AppAiBubbleStyle.neumorphicClean,
      aiAvatarIcon: AppAiAvatarIcon.energyOrb,
      chartCurveStyle: AppChartCurveStyle.smoothSpline,
      chartAreaFill: AppChartAreaFill.neonGlow,
      chartColorway: AppChartColorway.emeraldFortune,
      cardSkin: AppCardSkinStyle.goldMetallic,
      cornerStyle: CardCornerStyle.extraRounded,
    ),
    MasterUiPresetMeta(
      preset: AppMasterUiPreset.visionLiquidGlass,
      title: 'Vision Liquid Glass',
      subtitle: 'Thấu quang chiều sâu & Kính lỏng tương lai',
      tag: 'APPLE VISION',
      icon: Icons.water_drop_rounded,
      gradientColors: [Color(0xFF0070F3), Color(0xFF00DFD8)],
      palette: AppColorPalette.oceanicSapphire,
      uiUxStyle: AppUiUxStyle.liquidGlass,
      wallpaper: AppWallpaperPreset.silkBlue,
      iconStyle: AppIconStyle.duotoneGlass,
      heroCardStyle: AppHeroCardStyle.spatialPrismOrbital,
      dockNavStyle: AppDockNavStyle.floatingIsland,
      dockLabelStyle: AppDockLabelStyle.selectedOnly,
      avatarGlow: AppAvatarGlowStyle.royalAmethyst,
      membershipTier: AppMembershipTierBadge.diamondCrown,
      aiBubbleStyle: AppAiBubbleStyle.duotoneGlass,
      aiAvatarIcon: AppAiAvatarIcon.energyOrb,
      chartCurveStyle: AppChartCurveStyle.smoothSpline,
      chartAreaFill: AppChartAreaFill.subtleGlass,
      chartColorway: AppChartColorway.paletteSync,
      cardSkin: AppCardSkinStyle.deepOcean,
      cornerStyle: CardCornerStyle.extraRounded,
    ),
    MasterUiPresetMeta(
      preset: AppMasterUiPreset.emeraldFortune,
      title: 'Emerald Fortune',
      subtitle: 'Ngọc lục bảo sinh tài & Dòng chảy cực quang',
      tag: 'PROSPERITY',
      icon: Icons.forest_rounded,
      gradientColors: [Color(0xFF059669), Color(0xFF10B981)],
      palette: AppColorPalette.emeraldWealth,
      uiUxStyle: AppUiUxStyle.auroraBorealis,
      wallpaper: AppWallpaperPreset.auroraStream,
      iconStyle: AppIconStyle.dimensional,
      heroCardStyle: AppHeroCardStyle.minimalistPulse,
      dockNavStyle: AppDockNavStyle.compactCapsule,
      dockLabelStyle: AppDockLabelStyle.never,
      avatarGlow: AppAvatarGlowStyle.emeraldCrown,
      membershipTier: AppMembershipTierBadge.diamondCrown,
      aiBubbleStyle: AppAiBubbleStyle.neumorphicClean,
      aiAvatarIcon: AppAiAvatarIcon.hologramSpark,
      chartCurveStyle: AppChartCurveStyle.smoothSpline,
      chartAreaFill: AppChartAreaFill.neonGlow,
      chartColorway: AppChartColorway.emeraldFortune,
      cardSkin: AppCardSkinStyle.emeraldJade,
      cornerStyle: CardCornerStyle.rounded,
    ),
    MasterUiPresetMeta(
      preset: AppMasterUiPreset.swissMinimalist,
      title: 'Swiss Minimalist',
      subtitle: 'Đen trắng Bauhaus tinh gọn & Tập trung tối đa',
      tag: 'BAUHAUS',
      icon: Icons.crop_square_rounded,
      gradientColors: [Color(0xFF475569), Color(0xFF0F172A)],
      palette: AppColorPalette.slateMinimal,
      uiUxStyle: AppUiUxStyle.cupertinoMinimal,
      wallpaper: AppWallpaperPreset.metallicFrost,
      iconStyle: AppIconStyle.softSquare,
      heroCardStyle: AppHeroCardStyle.classicFintech,
      dockNavStyle: AppDockNavStyle.classicDock,
      dockLabelStyle: AppDockLabelStyle.always,
      avatarGlow: AppAvatarGlowStyle.none,
      membershipTier: AppMembershipTierBadge.platinumElite,
      aiBubbleStyle: AppAiBubbleStyle.neumorphicClean,
      aiAvatarIcon: AppAiAvatarIcon.energyOrb,
      chartCurveStyle: AppChartCurveStyle.steppedMatrix,
      chartAreaFill: AppChartAreaFill.outlineOnly,
      chartColorway: AppChartColorway.paletteSync,
      cardSkin: AppCardSkinStyle.titaniumFrost,
      cornerStyle: CardCornerStyle.sharp,
    ),
    MasterUiPresetMeta(
      preset: AppMasterUiPreset.sunsetRetroWave,
      title: 'Sunset Retro Wave',
      subtitle: 'Hoàng hôn Pastel ấm áp & Pha lê đá quý',
      tag: 'RETRO VIBES',
      icon: Icons.wb_twilight_rounded,
      gradientColors: [Color(0xFFF97316), Color(0xFFEC4899)],
      palette: AppColorPalette.sunsetCoral,
      uiUxStyle: AppUiUxStyle.retroSynthwave,
      wallpaper: AppWallpaperPreset.skyCyan,
      iconStyle: AppIconStyle.jewelCrystal,
      heroCardStyle: AppHeroCardStyle.liquidEnergySphere,
      dockNavStyle: AppDockNavStyle.floatingIsland,
      dockLabelStyle: AppDockLabelStyle.selectedOnly,
      avatarGlow: AppAvatarGlowStyle.royalAmethyst,
      membershipTier: AppMembershipTierBadge.diamondCrown,
      aiBubbleStyle: AppAiBubbleStyle.duotoneGlass,
      aiAvatarIcon: AppAiAvatarIcon.hologramSpark,
      chartCurveStyle: AppChartCurveStyle.smoothSpline,
      chartAreaFill: AppChartAreaFill.neonGlow,
      chartColorway: AppChartColorway.sunsetPastel,
      cardSkin: AppCardSkinStyle.roseGoldRuby,
      cornerStyle: CardCornerStyle.pillUltra,
      iconShape: AppIconShape.hexagon,
      iconVisualEffect: AppIconVisualEffect.jewelCrystal,
    ),
    MasterUiPresetMeta(
      preset: AppMasterUiPreset.googleMaterialYou,
      title: 'Google Material You',
      subtitle: 'Google Minimalist: M3 Tonal Surface, Bo tròn & Thoáng sạch',
      tag: 'PIXEL MINIMAL',
      icon: Icons.android_rounded,
      gradientColors: [Color(0xFF1A73E8), Color(0xFF34A853)],
      palette: AppColorPalette.googlePixel,
      uiUxStyle: AppUiUxStyle.googleMinimal,
      wallpaper: AppWallpaperPreset.metallicFrost,
      iconStyle: AppIconStyle.softSquare,
      iconShape: AppIconShape.squircle,
      iconVisualEffect: AppIconVisualEffect.flatMinimal,
      heroCardStyle: AppHeroCardStyle.minimalistPulse,
      dockNavStyle: AppDockNavStyle.compactCapsule,
      dockLabelStyle: AppDockLabelStyle.selectedOnly,
      avatarGlow: AppAvatarGlowStyle.cyberCyan,
      membershipTier: AppMembershipTierBadge.platinumElite,
      aiBubbleStyle: AppAiBubbleStyle.neumorphicClean,
      aiAvatarIcon: AppAiAvatarIcon.hologramSpark,
      chartCurveStyle: AppChartCurveStyle.smoothSpline,
      chartAreaFill: AppChartAreaFill.subtleGlass,
      chartColorway: AppChartColorway.paletteSync,
      cardSkin: AppCardSkinStyle.titaniumFrost,
      cornerStyle: CardCornerStyle.extraRounded,
    ),
    MasterUiPresetMeta(
      preset: AppMasterUiPreset.colorOsAquamorphic,
      title: 'ColorOS Aquamorphic',
      subtitle: 'Thiết kế dòng chảy nước: Mượt mà, gợn sóng & trong veo',
      tag: 'AQUAMORPHIC',
      icon: Icons.water_drop_rounded,
      gradientColors: [Color(0xFF00C4B4), Color(0xFF0066FF)],
      palette: AppColorPalette.colorOsAqua,
      uiUxStyle: AppUiUxStyle.colorOsAquamorphic,
      wallpaper: AppWallpaperPreset.silkBlue,
      iconStyle: AppIconStyle.round,
      iconShape: AppIconShape.teardrop,
      iconVisualEffect: AppIconVisualEffect.liquidGlass,
      heroCardStyle: AppHeroCardStyle.liquidEnergySphere,
      dockNavStyle: AppDockNavStyle.colorOsCurvedDock,
      dockLabelStyle: AppDockLabelStyle.always,
      avatarGlow: AppAvatarGlowStyle.cyberCyan,
      membershipTier: AppMembershipTierBadge.platinumElite,
      aiBubbleStyle: AppAiBubbleStyle.duotoneGlass,
      aiAvatarIcon: AppAiAvatarIcon.energyOrb,
      chartCurveStyle: AppChartCurveStyle.smoothSpline,
      chartAreaFill: AppChartAreaFill.subtleGlass,
      chartColorway: AppChartColorway.paletteSync,
      cardSkin: AppCardSkinStyle.deepOcean,
      cornerStyle: CardCornerStyle.pillUltra,
    ),
    MasterUiPresetMeta(
      preset: AppMasterUiPreset.hyperOsAlive,
      title: 'Xiaomi HyperOS Alive',
      subtitle: 'Alive Design: Đa tầng ánh sáng, viền phản quang & siêu tốc độ',
      tag: 'ALIVE DYNAMIC',
      icon: Icons.bolt_rounded,
      gradientColors: [Color(0xFF0070F3), Color(0xFFFF6B00)],
      palette: AppColorPalette.hyperOsElectric,
      uiUxStyle: AppUiUxStyle.hyperOsAlive,
      wallpaper: AppWallpaperPreset.midnightDark,
      iconStyle: AppIconStyle.softSquare,
      iconShape: AppIconShape.squircle,
      iconVisualEffect: AppIconVisualEffect.cyberNeon,
      heroCardStyle: AppHeroCardStyle.executiveBlackVip,
      dockNavStyle: AppDockNavStyle.hyperOsFloatingBar,
      dockLabelStyle: AppDockLabelStyle.selectedOnly,
      avatarGlow: AppAvatarGlowStyle.goldVip,
      membershipTier: AppMembershipTierBadge.diamondCrown,
      aiBubbleStyle: AppAiBubbleStyle.cyberTerminal,
      aiAvatarIcon: AppAiAvatarIcon.cyberRobot,
      chartCurveStyle: AppChartCurveStyle.straightSharp,
      chartAreaFill: AppChartAreaFill.neonGlow,
      chartColorway: AppChartColorway.cyberpunkVibrant,
      cardSkin: AppCardSkinStyle.carbonObsidian,
      cornerStyle: CardCornerStyle.extraRounded,
    ),
    MasterUiPresetMeta(
      preset: AppMasterUiPreset.ledgerEditorial,
      title: 'Ledger Editorial',
      subtitle: 'Sổ cái biên tập: chữ số nổi bật, đường kẻ mảnh',
      tag: 'EDITORIAL',
      icon: Icons.menu_book_rounded,
      gradientColors: [Color(0xFF1F2937), Color(0xFFB45309)],
      palette: AppColorPalette.slateMinimal,
      uiUxStyle: AppUiUxStyle.ledgerEditorial,
      wallpaper: AppWallpaperPreset.none,
      iconStyle: AppIconStyle.softSquare,
      heroCardStyle: AppHeroCardStyle.minimalistPulse,
      dockNavStyle: AppDockNavStyle.classicDock,
      dockLabelStyle: AppDockLabelStyle.always,
      avatarGlow: AppAvatarGlowStyle.none,
      membershipTier: AppMembershipTierBadge.platinumElite,
      aiBubbleStyle: AppAiBubbleStyle.neumorphicClean,
      aiAvatarIcon: AppAiAvatarIcon.energyOrb,
      chartCurveStyle: AppChartCurveStyle.straightSharp,
      chartAreaFill: AppChartAreaFill.outlineOnly,
      chartColorway: AppChartColorway.paletteSync,
      cardSkin: AppCardSkinStyle.whiteCeramic,
      cornerStyle: CardCornerStyle.sharp,
      ambientBlur: AmbientBlurPreset.obsidianSlate,
      fontFamily: AppFontFamily.executiveSerif,
      density: CardDensity.spacious,
      buttonShape: AppButtonShape.rounded,
      motion: AppMotionDynamics.smoothGentle,
      borderGlow: CardBorderGlowStyle.subtleHairline,
      glassOpacity: 0.90,
      glassBlur: 6,
      particleSparkles: false,
    ),
    MasterUiPresetMeta(
      preset: AppMasterUiPreset.softPaper,
      title: 'Soft Paper',
      subtitle: 'Giấy ấm nhẹ: bề mặt dịu, chuyển động êm',
      tag: 'PAPER',
      icon: Icons.description_rounded,
      gradientColors: [Color(0xFFF4EDE1), Color(0xFFB98A5A)],
      palette: AppColorPalette.sunsetCoral,
      uiUxStyle: AppUiUxStyle.softPaper,
      wallpaper: AppWallpaperPreset.none,
      iconStyle: AppIconStyle.softSquare,
      heroCardStyle: AppHeroCardStyle.classicFintech,
      dockNavStyle: AppDockNavStyle.classicDock,
      dockLabelStyle: AppDockLabelStyle.always,
      avatarGlow: AppAvatarGlowStyle.none,
      membershipTier: AppMembershipTierBadge.platinumElite,
      aiBubbleStyle: AppAiBubbleStyle.neumorphicClean,
      aiAvatarIcon: AppAiAvatarIcon.energyOrb,
      chartCurveStyle: AppChartCurveStyle.smoothSpline,
      chartAreaFill: AppChartAreaFill.subtleGlass,
      chartColorway: AppChartColorway.sunsetPastel,
      cardSkin: AppCardSkinStyle.whiteCeramic,
      cornerStyle: CardCornerStyle.rounded,
      ambientBlur: AmbientBlurPreset.sunsetAmber,
      fontFamily: AppFontFamily.roundedFriendly,
      density: CardDensity.spacious,
      buttonShape: AppButtonShape.squircle,
      motion: AppMotionDynamics.smoothGentle,
      borderGlow: CardBorderGlowStyle.none,
      glassOpacity: 0.94,
      glassBlur: 5,
      particleSparkles: false,
    ),
    MasterUiPresetMeta(
      preset: AppMasterUiPreset.industrialUtility,
      title: 'Industrial Utility',
      subtitle: 'Mật độ cao, hình học rõ, dữ liệu đọc nhanh',
      tag: 'UTILITY',
      icon: Icons.grid_view_rounded,
      gradientColors: [Color(0xFF263238), Color(0xFFF59E0B)],
      palette: AppColorPalette.titaniumIce,
      uiUxStyle: AppUiUxStyle.industrialUtility,
      wallpaper: AppWallpaperPreset.none,
      iconStyle: AppIconStyle.softSquare,
      heroCardStyle: AppHeroCardStyle.minimalistPulse,
      dockNavStyle: AppDockNavStyle.classicDock,
      dockLabelStyle: AppDockLabelStyle.always,
      avatarGlow: AppAvatarGlowStyle.none,
      membershipTier: AppMembershipTierBadge.platinumElite,
      aiBubbleStyle: AppAiBubbleStyle.cyberTerminal,
      aiAvatarIcon: AppAiAvatarIcon.cyberRobot,
      chartCurveStyle: AppChartCurveStyle.steppedMatrix,
      chartAreaFill: AppChartAreaFill.outlineOnly,
      chartColorway: AppChartColorway.paletteSync,
      cardSkin: AppCardSkinStyle.titaniumFrost,
      cornerStyle: CardCornerStyle.sharp,
      ambientBlur: AmbientBlurPreset.obsidianSlate,
      fontFamily: AppFontFamily.fintechMonospace,
      density: CardDensity.compact,
      buttonShape: AppButtonShape.rounded,
      motion: AppMotionDynamics.snappySwift,
      borderGlow: CardBorderGlowStyle.subtleHairline,
      glassOpacity: 0.95,
      glassBlur: 4,
      particleSparkles: false,
    ),
    MasterUiPresetMeta(
      preset: AppMasterUiPreset.organicClay,
      title: 'Organic Clay',
      subtitle: 'Khối đất mềm nổi, màu thiên nhiên ấm',
      tag: 'ORGANIC',
      icon: Icons.spa_rounded,
      gradientColors: [Color(0xFFD7A782), Color(0xFF6F9270)],
      palette: AppColorPalette.emeraldWealth,
      uiUxStyle: AppUiUxStyle.organicClay,
      wallpaper: AppWallpaperPreset.none,
      iconStyle: AppIconStyle.dimensional,
      heroCardStyle: AppHeroCardStyle.liquidEnergySphere,
      dockNavStyle: AppDockNavStyle.floatingIsland,
      dockLabelStyle: AppDockLabelStyle.selectedOnly,
      avatarGlow: AppAvatarGlowStyle.emeraldCrown,
      membershipTier: AppMembershipTierBadge.platinumElite,
      aiBubbleStyle: AppAiBubbleStyle.neumorphicClean,
      aiAvatarIcon: AppAiAvatarIcon.energyOrb,
      chartCurveStyle: AppChartCurveStyle.smoothSpline,
      chartAreaFill: AppChartAreaFill.subtleGlass,
      chartColorway: AppChartColorway.emeraldFortune,
      cardSkin: AppCardSkinStyle.emeraldJade,
      cornerStyle: CardCornerStyle.pillUltra,
      ambientBlur: AmbientBlurPreset.emeraldMatrix,
      fontFamily: AppFontFamily.roundedFriendly,
      density: CardDensity.spacious,
      buttonShape: AppButtonShape.pill,
      motion: AppMotionDynamics.smoothGentle,
      borderGlow: CardBorderGlowStyle.none,
      glassOpacity: 0.92,
      glassBlur: 8,
      particleSparkles: false,
    ),
    MasterUiPresetMeta(
      preset: AppMasterUiPreset.einkFocus,
      title: 'E-ink Focus',
      subtitle: 'Đơn sắc tương phản, ít hiệu ứng, tập trung số liệu',
      tag: 'FOCUS',
      icon: Icons.contrast_rounded,
      gradientColors: [Color(0xFF111827), Color(0xFFE5E7EB)],
      palette: AppColorPalette.slateMinimal,
      uiUxStyle: AppUiUxStyle.einkFocus,
      wallpaper: AppWallpaperPreset.none,
      iconStyle: AppIconStyle.softSquare,
      heroCardStyle: AppHeroCardStyle.minimalistPulse,
      dockNavStyle: AppDockNavStyle.minimalistDotDock,
      dockLabelStyle: AppDockLabelStyle.selectedOnly,
      avatarGlow: AppAvatarGlowStyle.none,
      membershipTier: AppMembershipTierBadge.platinumElite,
      aiBubbleStyle: AppAiBubbleStyle.neumorphicClean,
      aiAvatarIcon: AppAiAvatarIcon.energyOrb,
      chartCurveStyle: AppChartCurveStyle.straightSharp,
      chartAreaFill: AppChartAreaFill.outlineOnly,
      chartColorway: AppChartColorway.paletteSync,
      cardSkin: AppCardSkinStyle.whiteCeramic,
      cornerStyle: CardCornerStyle.sharp,
      ambientBlur: AmbientBlurPreset.obsidianSlate,
      fontFamily: AppFontFamily.systemModern,
      density: CardDensity.compact,
      buttonShape: AppButtonShape.rounded,
      motion: AppMotionDynamics.reducedMotion,
      borderGlow: CardBorderGlowStyle.subtleHairline,
      glassOpacity: 0.95,
      glassBlur: 4,
      particleSparkles: false,
    ),
    MasterUiPresetMeta(
      preset: AppMasterUiPreset.artDecoFinance,
      title: 'Art Deco Finance',
      subtitle: 'Đối xứng hình học, viền kim loại thanh lịch',
      tag: 'ART DECO',
      icon: Icons.diamond_rounded,
      gradientColors: [Color(0xFF1B2431), Color(0xFFD4AF37)],
      palette: AppColorPalette.obsidianGold,
      uiUxStyle: AppUiUxStyle.artDecoFinance,
      wallpaper: AppWallpaperPreset.midnightDark,
      iconStyle: AppIconStyle.jewelCrystal,
      heroCardStyle: AppHeroCardStyle.executiveBlackVip,
      dockNavStyle: AppDockNavStyle.pillTabs,
      dockLabelStyle: AppDockLabelStyle.always,
      avatarGlow: AppAvatarGlowStyle.goldVip,
      membershipTier: AppMembershipTierBadge.goldCenturion,
      aiBubbleStyle: AppAiBubbleStyle.duotoneGlass,
      aiAvatarIcon: AppAiAvatarIcon.hologramSpark,
      chartCurveStyle: AppChartCurveStyle.straightSharp,
      chartAreaFill: AppChartAreaFill.outlineOnly,
      chartColorway: AppChartColorway.paletteSync,
      cardSkin: AppCardSkinStyle.goldMetallic,
      cornerStyle: CardCornerStyle.subtle,
      ambientBlur: AmbientBlurPreset.obsidianSlate,
      fontFamily: AppFontFamily.executiveSerif,
      density: CardDensity.standard,
      buttonShape: AppButtonShape.rounded,
      motion: AppMotionDynamics.smoothGentle,
      borderGlow: CardBorderGlowStyle.gradientRim,
      glassOpacity: 0.90,
      glassBlur: 10,
      particleSparkles: false,
    ),
    MasterUiPresetMeta(
      preset: AppMasterUiPreset.springTetMaster,
      title: 'Tết Giáp Thìn & Xuân Quý',
      subtitle: 'Sắc đỏ may mắn, vàng mai đào, lộc tài phát tài',
      tag: 'FESTIVE TẾT',
      icon: Icons.celebration_rounded,
      gradientColors: [Color(0xFFDC2626), Color(0xFFEAB308)],
      palette: AppColorPalette.crimsonRuby,
      uiUxStyle: AppUiUxStyle.liquidGlass,
      wallpaper: AppWallpaperPreset.none,
      iconStyle: AppIconStyle.round,
      iconShape: AppIconShape.circle,
      iconVisualEffect: AppIconVisualEffect.liquidGlass,
      heroCardStyle: AppHeroCardStyle.classicFintech,
      dockNavStyle: AppDockNavStyle.notchWaveRise,
      dockLabelStyle: AppDockLabelStyle.always,
      avatarGlow: AppAvatarGlowStyle.goldVip,
      membershipTier: AppMembershipTierBadge.diamondCrown,
      aiBubbleStyle: AppAiBubbleStyle.duotoneGlass,
      aiAvatarIcon: AppAiAvatarIcon.hologramSpark,
      chartCurveStyle: AppChartCurveStyle.smoothSpline,
      chartAreaFill: AppChartAreaFill.neonGlow,
      chartColorway: AppChartColorway.paletteSync,
      cardSkin: AppCardSkinStyle.goldMetallic,
      cornerStyle: CardCornerStyle.extraRounded,
      seasonalTheme: AppSeasonalTheme.springTet,
    ),
    MasterUiPresetMeta(
      preset: AppMasterUiPreset.summerBreezeMaster,
      title: 'Hè Biển Ngọc Aqua',
      subtitle: 'Sảng khoái mát lành: Nắng vàng, sóng biếc, cát mịn',
      tag: 'SUMMER BREEZE',
      icon: Icons.wb_sunny_rounded,
      gradientColors: [Color(0xFF00C4B4), Color(0xFF0284C7)],
      palette: AppColorPalette.colorOsAqua,
      uiUxStyle: AppUiUxStyle.colorOsAquamorphic,
      wallpaper: AppWallpaperPreset.none,
      iconStyle: AppIconStyle.softSquare,
      iconShape: AppIconShape.teardrop,
      iconVisualEffect: AppIconVisualEffect.liquidGlass,
      heroCardStyle: AppHeroCardStyle.liquidEnergySphere,
      dockNavStyle: AppDockNavStyle.segmentedIslandBubbles,
      dockLabelStyle: AppDockLabelStyle.selectedOnly,
      avatarGlow: AppAvatarGlowStyle.cyberCyan,
      membershipTier: AppMembershipTierBadge.platinumElite,
      aiBubbleStyle: AppAiBubbleStyle.duotoneGlass,
      aiAvatarIcon: AppAiAvatarIcon.energyOrb,
      chartCurveStyle: AppChartCurveStyle.smoothSpline,
      chartAreaFill: AppChartAreaFill.subtleGlass,
      chartColorway: AppChartColorway.paletteSync,
      cardSkin: AppCardSkinStyle.deepOcean,
      cornerStyle: CardCornerStyle.pillUltra,
      seasonalTheme: AppSeasonalTheme.summerBreeze,
    ),
    MasterUiPresetMeta(
      preset: AppMasterUiPreset.autumnAmberMaster,
      title: 'Thu Vàng & Trung Thu',
      subtitle: 'Lãng mạn ấm áp: Cam mật ong, lá phong hổ phách, trăng rằm',
      tag: 'AUTUMN AMBER',
      icon: Icons.eco_rounded,
      gradientColors: [Color(0xFFD97706), Color(0xFFEA580C)],
      palette: AppColorPalette.sunsetCoral,
      uiUxStyle: AppUiUxStyle.softPaper,
      wallpaper: AppWallpaperPreset.none,
      iconStyle: AppIconStyle.dimensional,
      iconShape: AppIconShape.squircle,
      iconVisualEffect: AppIconVisualEffect.gradientFlow,
      heroCardStyle: AppHeroCardStyle.minimalistPulse,
      dockNavStyle: AppDockNavStyle.expandedGlowTray,
      dockLabelStyle: AppDockLabelStyle.always,
      avatarGlow: AppAvatarGlowStyle.royalAmethyst,
      membershipTier: AppMembershipTierBadge.goldCenturion,
      aiBubbleStyle: AppAiBubbleStyle.neumorphicClean,
      aiAvatarIcon: AppAiAvatarIcon.energyOrb,
      chartCurveStyle: AppChartCurveStyle.smoothSpline,
      chartAreaFill: AppChartAreaFill.subtleGlass,
      chartColorway: AppChartColorway.sunsetPastel,
      cardSkin: AppCardSkinStyle.roseGoldRuby,
      cornerStyle: CardCornerStyle.rounded,
      seasonalTheme: AppSeasonalTheme.autumnAmber,
    ),
    MasterUiPresetMeta(
      preset: AppMasterUiPreset.winterChristmasMaster,
      title: 'Mùa Đông & Giáng Sinh',
      subtitle: 'Ấm cúng lung linh: Bông tuyết pha lê, thông xanh, chuông vàng',
      tag: 'WINTER XMAS',
      icon: Icons.ac_unit_rounded,
      gradientColors: [Color(0xFF059669), Color(0xFFE11D48)],
      palette: AppColorPalette.emeraldWealth,
      uiUxStyle: AppUiUxStyle.auroraBorealis,
      wallpaper: AppWallpaperPreset.none,
      iconStyle: AppIconStyle.jewelCrystal,
      iconShape: AppIconShape.diamond,
      iconVisualEffect: AppIconVisualEffect.jewelCrystal,
      heroCardStyle: AppHeroCardStyle.minimalistPulse,
      dockNavStyle: AppDockNavStyle.stealthWireMinimal,
      dockLabelStyle: AppDockLabelStyle.selectedOnly,
      avatarGlow: AppAvatarGlowStyle.emeraldCrown,
      membershipTier: AppMembershipTierBadge.diamondCrown,
      aiBubbleStyle: AppAiBubbleStyle.duotoneGlass,
      aiAvatarIcon: AppAiAvatarIcon.hologramSpark,
      chartCurveStyle: AppChartCurveStyle.smoothSpline,
      chartAreaFill: AppChartAreaFill.neonGlow,
      chartColorway: AppChartColorway.emeraldFortune,
      cardSkin: AppCardSkinStyle.whiteCeramic,
      cornerStyle: CardCornerStyle.extraRounded,
      seasonalTheme: AppSeasonalTheme.winterChristmas,
    ),
  ];

  Future<void> toggleLock(String component) async {
    if (_lockedComponents.contains(component)) {
      _lockedComponents.remove(component);
    } else {
      _lockedComponents.add(component);
    }
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_lockedComponentsKey, _lockedComponents.toList());
  }

  Future<void> setLock(String component, bool locked) async {
    if (locked) {
      _lockedComponents.add(component);
    } else {
      _lockedComponents.remove(component);
    }
    notifyListeners();
    performHaptic();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_lockedComponentsKey, _lockedComponents.toList());
  }

  /// Xuất toàn bộ cấu hình Theme hiện tại thành mã chia sẻ
  String exportThemeCode() {
    final map = <String, dynamic>{
      'v': 2,
      'palette': _palette.index,
      'mode': _uiUxStyle.index,
      'seasonal': _seasonalTheme.index,
      'dockNav': _dockNavStyle.index,
      'dockIcon': _dockIconStyle.index,
      'dockLabel': _dockLabelStyle.index,
      'btnVisual': _buttonVisualKind.index,
      'btnColor': _buttonColorMode.index,
      'btnShape': _buttonShape.index,
      'btnSize': _buttonSize.index,
      'widgetCard': _widgetCardStyle.index,
      'catIcon': _categoryIconStyle.index,
      'glassOp': (_glassOpacity * 100).round(),
      'glassBlur': _glassBlur.round(),
      'appBarBlur': _appBarBlur.round(),
      'appBarOp': (_appBarOpacity * 100).round(),
      'pageMargin': _pageHorizontalMargin.round(),
      'corner': _cornerStyle.index,
      'borderGlow': _borderGlowStyle.index,
      'avatarGlow': _avatarGlowStyle.index,
      'tier': _membershipTier.index,
      'iconBg': _iconBgColorMode.index,
      'iconGlyph': _iconGlyphColorMode.index,
      'fps120': _highRefreshRate120Hz ? 1 : 0,
      'txList': _transactionListStyle.index,
      'font': _fontFamily.index,
      'fontScale': (_fontScale * 100).round(),
      'loading': _loadingStyle.index,
      'heroCard': _heroCardStyle.index,
      'chartCurve': _chartCurveStyle.index,
      'ambient': _ambientBlur.index,
      'bgTint': (_backgroundTintOpacity * 100).round(),
      'cardRadius': (_customCardCornerRadius ?? 20.0).round(),
      'btnRadius': (_customButtonCornerRadius ?? 18.0).round(),
      'iconScale': (_iconScale * 100).round(),
      'iconRadius': _iconCornerRadius.round(),
      'swlg': _systemWideLiquidGlass ? 1 : 0,
      'lgsh': _liquidGlassSpecularHighlight ? 1 : 0,
      'lgcr': _liquidGlassCausticRefraction ? 1 : 0,
    };
    final jsonStr = jsonEncode(map);
    final b64 = base64UrlEncode(utf8.encode(jsonStr));
    return 'FINORA-$b64';
  }

  /// Nhập mã Theme chia sẻ và kích hoạt đồng bộ
  Future<bool> importThemeCode(String code) async {
    try {
      var raw = code.trim();
      if (raw.startsWith('FINORA-')) {
        raw = raw.substring(7);
      }
      final jsonStr = utf8.decode(base64Url.decode(raw));
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (map['palette'] != null &&
          (map['palette'] as int) < AppColorPalette.values.length) {
        _palette = AppColorPalette.values[map['palette'] as int];
      }
      if (map['mode'] != null &&
          (map['mode'] as int) < AppUiUxStyle.values.length) {
        _uiUxStyle = AppUiUxStyle.values[map['mode'] as int];
      }
      if (map['seasonal'] != null &&
          (map['seasonal'] as int) < AppSeasonalTheme.values.length) {
        _seasonalTheme = AppSeasonalTheme.values[map['seasonal'] as int];
      }
      if (map['dockNav'] != null &&
          (map['dockNav'] as int) < AppDockNavStyle.values.length) {
        _dockNavStyle = AppDockNavStyle.values[map['dockNav'] as int];
      }
      if (map['dockIcon'] != null &&
          (map['dockIcon'] as int) < AppDockIconStyle.values.length) {
        _dockIconStyle = AppDockIconStyle.values[map['dockIcon'] as int];
      }
      if (map['dockLabel'] != null &&
          (map['dockLabel'] as int) < AppDockLabelStyle.values.length) {
        _dockLabelStyle = AppDockLabelStyle.values[map['dockLabel'] as int];
      }
      if (map['btnVisual'] != null &&
          (map['btnVisual'] as int) < AppButtonStyle.values.length) {
        _buttonVisualKind = AppButtonStyle.values[map['btnVisual'] as int];
      }
      if (map['btnColor'] != null &&
          (map['btnColor'] as int) < AppButtonColorMode.values.length) {
        _buttonColorMode = AppButtonColorMode.values[map['btnColor'] as int];
      }
      if (map['btnShape'] != null &&
          (map['btnShape'] as int) < AppButtonShape.values.length) {
        _buttonShape = AppButtonShape.values[map['btnShape'] as int];
      }
      if (map['btnSize'] != null &&
          (map['btnSize'] as int) < AppButtonSize.values.length) {
        _buttonSize = AppButtonSize.values[map['btnSize'] as int];
      }
      if (map['widgetCard'] != null &&
          (map['widgetCard'] as int) < AppWidgetCardStyle.values.length) {
        _widgetCardStyle = AppWidgetCardStyle.values[map['widgetCard'] as int];
      }
      if (map['catIcon'] != null &&
          (map['catIcon'] as int) < AppCategoryIconStyle.values.length) {
        _categoryIconStyle = AppCategoryIconStyle.values[map['catIcon'] as int];
      }
      if (map['glassOp'] != null) {
        _glassOpacity = ((map['glassOp'] as num) / 100.0).clamp(0.20, 0.95);
      }
      if (map['glassBlur'] != null) {
        _glassBlur = (map['glassBlur'] as num).toDouble().clamp(4.0, 32.0);
      }
      if (map['appBarBlur'] != null) {
        _appBarBlur = (map['appBarBlur'] as num).toDouble().clamp(0.0, 30.0);
      }
      if (map['appBarOp'] != null) {
        _appBarOpacity = ((map['appBarOp'] as num) / 100.0).clamp(0.0, 1.0);
      }
      if (map['pageMargin'] != null) {
        _pageHorizontalMargin =
            (map['pageMargin'] as num).toDouble().clamp(8.0, 32.0);
      }
      if (map['corner'] != null &&
          (map['corner'] as int) < CardCornerStyle.values.length) {
        _cornerStyle = CardCornerStyle.values[map['corner'] as int];
      }
      if (map['borderGlow'] != null &&
          (map['borderGlow'] as int) < CardBorderGlowStyle.values.length) {
        _borderGlowStyle = CardBorderGlowStyle.values[map['borderGlow'] as int];
      }
      if (map['avatarGlow'] != null &&
          (map['avatarGlow'] as int) < AppAvatarGlowStyle.values.length) {
        _avatarGlowStyle = AppAvatarGlowStyle.values[map['avatarGlow'] as int];
      }
      if (map['tier'] != null &&
          (map['tier'] as int) < AppMembershipTierBadge.values.length) {
        _membershipTier = AppMembershipTierBadge.values[map['tier'] as int];
      }
      if (map['iconBg'] != null &&
          (map['iconBg'] as int) < AppIconBgColorMode.values.length) {
        _iconBgColorMode = AppIconBgColorMode.values[map['iconBg'] as int];
      }
      if (map['iconGlyph'] != null &&
          (map['iconGlyph'] as int) < AppIconGlyphColorMode.values.length) {
        _iconGlyphColorMode =
            AppIconGlyphColorMode.values[map['iconGlyph'] as int];
      }
      if (map['fps120'] != null) {
        _highRefreshRate120Hz = (map['fps120'] as int) == 1;
      }
      if (map['txList'] != null &&
          (map['txList'] as int) < AppTransactionListStyle.values.length) {
        _transactionListStyle =
            AppTransactionListStyle.values[map['txList'] as int];
      }
      if (map['font'] != null &&
          (map['font'] as int) < AppFontFamily.values.length) {
        _fontFamily = AppFontFamily.values[map['font'] as int];
      }
      if (map['fontScale'] != null) {
        _fontScale = ((map['fontScale'] as num) / 100.0).clamp(0.85, 1.25);
      }
      if (map['loading'] != null &&
          (map['loading'] as int) < AppLoadingIndicatorStyle.values.length) {
        _loadingStyle = AppLoadingIndicatorStyle.values[map['loading'] as int];
      }
      if (map['heroCard'] != null &&
          (map['heroCard'] as int) < AppHeroCardStyle.values.length) {
        _heroCardStyle = AppHeroCardStyle.values[map['heroCard'] as int];
      }
      if (map['chartCurve'] != null &&
          (map['chartCurve'] as int) < AppChartCurveStyle.values.length) {
        _chartCurveStyle = AppChartCurveStyle.values[map['chartCurve'] as int];
      }
      if (map['ambient'] != null &&
          (map['ambient'] as int) < AmbientBlurPreset.values.length) {
        _ambientBlur = AmbientBlurPreset.values[map['ambient'] as int];
      }
      if (map['bgTint'] != null) {
        _backgroundTintOpacity =
            ((map['bgTint'] as num) / 100.0).clamp(0.05, 1.0);
      }
      if (map['cardRadius'] != null) {
        _customCardCornerRadius =
            (map['cardRadius'] as num).toDouble().clamp(4.0, 36.0);
      }
      if (map['btnRadius'] != null) {
        _customButtonCornerRadius =
            (map['btnRadius'] as num).toDouble().clamp(4.0, 28.0);
      }
      if (map['iconScale'] != null) {
        _iconScale = ((map['iconScale'] as num) / 100.0).clamp(0.65, 1.45);
      }
      if (map['iconRadius'] != null) {
        _iconCornerRadius =
            (map['iconRadius'] as num).toDouble().clamp(0.0, 36.0);
      }
      if (map['swlg'] != null) {
        _systemWideLiquidGlass = (map['swlg'] as int) == 1;
      }
      if (map['lgsh'] != null) {
        _liquidGlassSpecularHighlight = (map['lgsh'] as int) == 1;
      }
      if (map['lgcr'] != null) {
        _liquidGlassCausticRefraction = (map['lgcr'] as int) == 1;
      }

      notifyListeners();
      performHaptic();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_paletteKey, _palette.index);
      await prefs.setInt(_uiUxStyleKey, _uiUxStyle.index);
      await prefs.setInt(_seasonalThemeKey, _seasonalTheme.index);
      await prefs.setInt(_dockNavKey, _dockNavStyle.index);
      await prefs.setInt(_dockIconStyleKey, _dockIconStyle.index);
      await prefs.setInt(_dockLabelStyleKey, _dockLabelStyle.index);
      await prefs.setInt(_buttonVisualKindKey, _buttonVisualKind.index);
      await prefs.setInt(_buttonColorModeKey, _buttonColorMode.index);
      await prefs.setInt(_buttonShapeKey, _buttonShape.index);
      await prefs.setInt(_buttonSizeKey, _buttonSize.index);
      await prefs.setInt(_widgetCardStyleKey, _widgetCardStyle.index);
      await prefs.setInt(_categoryIconStyleKey, _categoryIconStyle.index);
      await prefs.setDouble(_glassOpacityKey, _glassOpacity);
      await prefs.setDouble(_glassBlurKey, _glassBlur);
      await prefs.setDouble(_appBarBlurKey, _appBarBlur);
      await prefs.setDouble(_appBarOpacityKey, _appBarOpacity);
      await prefs.setDouble(_pageHorizontalMarginKey, _pageHorizontalMargin);
      await prefs.setInt(_cornerKey, _cornerStyle.index);
      await prefs.setInt(_borderGlowKey, _borderGlowStyle.index);
      await prefs.setInt(_avatarGlowStyleKey, _avatarGlowStyle.index);
      await prefs.setInt(_membershipTierKey, _membershipTier.index);
      await prefs.setInt(_iconBgColorModeKey, _iconBgColorMode.index);
      await prefs.setInt(_iconGlyphColorModeKey, _iconGlyphColorMode.index);
      await prefs.setBool(_highRefreshRate120HzKey, _highRefreshRate120Hz);
      await prefs.setInt(_transactionListStyleKey, _transactionListStyle.index);
      await prefs.setInt(_fontFamilyKey, _fontFamily.index);
      await prefs.setDouble(_fontScaleKey, _fontScale);
      await prefs.setInt(_loadingStyleKey, _loadingStyle.index);
      await prefs.setInt(_heroCardStyleKey, _heroCardStyle.index);
      await prefs.setInt(_chartCurveStyleKey, _chartCurveStyle.index);
      await prefs.setInt(_ambientBlurKey, _ambientBlur.index);
      await prefs.setDouble(_backgroundTintOpacityKey, _backgroundTintOpacity);
      if (_customCardCornerRadius != null) {
        await prefs.setDouble(
            _customCardCornerRadiusKey, _customCardCornerRadius!);
      }
      if (_customButtonCornerRadius != null) {
        await prefs.setDouble(
            _customButtonCornerRadiusKey, _customButtonCornerRadius!);
      }
      await prefs.setDouble(_iconScaleKey, _iconScale);
      await prefs.setDouble(_iconCornerRadiusKey, _iconCornerRadius);

      return true;
    } catch (e) {
      debugPrint('[ThemeStudioController] Error importing theme code: $e');
      return false;
    }
  }

  /// Danh sách 8 Theme Presets Cộng Đồng tuyển chọn đỉnh cao
  static const List<CuratedCommunityThemePreset> curatedCommunityPresets = [
    CuratedCommunityThemePreset(
      id: 'swiss_centurion_black',
      title: 'Swiss Centurion Black',
      subtitle: 'Đẳng cấp ngân hàng tư nhân Thụy Sĩ, đen huyền bí ánh vàng',
      author: 'Zurich Private Banking',
      downloads: '14.8k',
      rating: 4.98,
      tags: ['VIP LUXURY', 'PLUS JAKARTA', '120FPS'],
      gradientColors: [Color(0xFFD4AF37), Color(0xFF1E2430)],
      palette: AppColorPalette.obsidianGold,
      fontFamily: AppFontFamily.plusJakartaSans,
      heroCardStyle: AppHeroCardStyle.executiveBlackVip,
      dockNavStyle: AppDockNavStyle.floatingIsland,
      categoryIconStyle: AppCategoryIconStyle.diamondFacet,
      buttonVisualKind: AppButtonStyle.gradientGlow,
      loadingStyle: AppLoadingIndicatorStyle.goldenCoin3D,
      cardRadius: 20.0,
      buttonRadius: 16.0,
      ambientBlur: AmbientBlurPreset.obsidianSlate,
      highRefreshRate120Hz: true,
    ),
    CuratedCommunityThemePreset(
      id: 'nordic_emerald_wealth',
      title: 'Nordic Emerald Wealth',
      subtitle: 'Xanh lục bảo tài lộc Bắc Âu, 100% chuẩn dấu tiếng Việt',
      author: 'Finora Hanoi Atelier',
      downloads: '21.5k',
      rating: 4.96,
      tags: ['TÀI LỘC', 'BE VIETNAM', 'FLUID'],
      gradientColors: [Color(0xFF10B981), Color(0xFF047857)],
      palette: AppColorPalette.emeraldWealth,
      fontFamily: AppFontFamily.beVietnamPro,
      heroCardStyle: AppHeroCardStyle.minimalistPulse,
      dockNavStyle: AppDockNavStyle.compactCapsule,
      categoryIconStyle: AppCategoryIconStyle.modernSquircle,
      buttonVisualKind: AppButtonStyle.modernPill,
      loadingStyle: AppLoadingIndicatorStyle.liquidRipple,
      cardRadius: 22.0,
      buttonRadius: 20.0,
      ambientBlur: AmbientBlurPreset.emeraldMatrix,
      highRefreshRate120Hz: true,
    ),
    CuratedCommunityThemePreset(
      id: 'tokyo_cyberpunk_2077',
      title: 'Tokyo Cyberpunk 2077',
      subtitle: 'Ánh hồng neon tương lai & Terminal đa chiều Shinjuku',
      author: 'Neo Tokyo Lab',
      downloads: '18.2k',
      rating: 4.92,
      tags: ['NEON GLOW', 'OUTFIT', 'CYBER'],
      gradientColors: [Color(0xFFFF2A85), Color(0xFF00E5FF)],
      palette: AppColorPalette.cyberNeonPink,
      fontFamily: AppFontFamily.outfit,
      heroCardStyle: AppHeroCardStyle.liquidEnergySphere,
      dockNavStyle: AppDockNavStyle.glassNeonUnderline,
      categoryIconStyle: AppCategoryIconStyle.neonBadge,
      buttonVisualKind: AppButtonStyle.sharpTech,
      loadingStyle: AppLoadingIndicatorStyle.cyberOrbit,
      cardRadius: 16.0,
      buttonRadius: 10.0,
      ambientBlur: AmbientBlurPreset.rainbowAurora,
      highRefreshRate120Hz: true,
    ),
    CuratedCommunityThemePreset(
      id: 'hyperos_amber_dynamic',
      title: 'HyperOS Amber Dynamic',
      subtitle: 'Cam san hô Alive năng động, tối ưu đọc lướt số dư cực nhanh',
      author: 'HyperOS Fluid Studio',
      downloads: '12.4k',
      rating: 4.89,
      tags: ['ALIVE DYNAMIC', 'LEXEND', 'HIGH SPEED'],
      gradientColors: [Color(0xFFFF6B00), Color(0xFFFF9E00)],
      palette: AppColorPalette.sunsetCoral,
      fontFamily: AppFontFamily.lexend,
      heroCardStyle: AppHeroCardStyle.classicFintech,
      dockNavStyle: AppDockNavStyle.floatingIsland,
      categoryIconStyle: AppCategoryIconStyle.minimalCircle,
      buttonVisualKind: AppButtonStyle.modernPill,
      loadingStyle: AppLoadingIndicatorStyle.infinityDots,
      cardRadius: 24.0,
      buttonRadius: 22.0,
      ambientBlur: AmbientBlurPreset.sunsetAmber,
      highRefreshRate120Hz: true,
    ),
    CuratedCommunityThemePreset(
      id: 'titanium_glacier_ice',
      title: 'Titanium Glacier Ice',
      subtitle: 'Băng tuyết titan công nghệ cao, thanh lịch bán hình học Euro',
      author: 'Nordic Clean Studio',
      downloads: '9.7k',
      rating: 4.94,
      tags: ['EURO MODERN', 'MANROPE', 'GLASS 3D'],
      gradientColors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
      palette: AppColorPalette.titaniumIce,
      fontFamily: AppFontFamily.manrope,
      heroCardStyle: AppHeroCardStyle.minimalistPulse,
      dockNavStyle: AppDockNavStyle.compactCapsule,
      categoryIconStyle: AppCategoryIconStyle.glassSphere,
      buttonVisualKind: AppButtonStyle.glassElevated,
      loadingStyle: AppLoadingIndicatorStyle.glassShimmer,
      cardRadius: 26.0,
      buttonRadius: 18.0,
      ambientBlur: AmbientBlurPreset.sapphireCyan,
      highRefreshRate120Hz: true,
    ),
    CuratedCommunityThemePreset(
      id: 'wall_street_executive',
      title: 'Wall Street Executive',
      subtitle: 'Bản lĩnh phố Wall: Cột số ma trận DIN Đức thẳng tắp',
      author: 'Manhattan Capital',
      downloads: '11.3k',
      rating: 4.91,
      tags: ['MATRIX DIN', 'BAHNSCHRIFT', 'STEALTH'],
      gradientColors: [Color(0xFF475569), Color(0xFF1E293B)],
      palette: AppColorPalette.slateMinimal,
      fontFamily: AppFontFamily.fintechMonospace,
      heroCardStyle: AppHeroCardStyle.executiveBlackVip,
      dockNavStyle: AppDockNavStyle.classicDock,
      categoryIconStyle: AppCategoryIconStyle.duotoneTonal,
      buttonVisualKind: AppButtonStyle.flatSubtle,
      loadingStyle: AppLoadingIndicatorStyle.liquidRipple,
      cardRadius: 14.0,
      buttonRadius: 12.0,
      ambientBlur: AmbientBlurPreset.obsidianSlate,
      highRefreshRate120Hz: true,
    ),
    CuratedCommunityThemePreset(
      id: 'sakura_rose_gold',
      title: 'Sakura Rose Gold',
      subtitle: 'Hồng phấn cánh hoa anh đào thanh nhã quý phái hoàng gia',
      author: 'Kyoto Aesthetic Lab',
      downloads: '15.6k',
      rating: 4.95,
      tags: ['PASTEL LUXURY', 'OUTFIT', 'NEUMORPHIC'],
      gradientColors: [Color(0xFFFB7185), Color(0xFFF43F5E)],
      palette: AppColorPalette.crimsonRuby,
      fontFamily: AppFontFamily.outfit,
      heroCardStyle: AppHeroCardStyle.minimalistPulse,
      dockNavStyle: AppDockNavStyle.floatingIsland,
      categoryIconStyle: AppCategoryIconStyle.paperEmbossed,
      buttonVisualKind: AppButtonStyle.gradientGlow,
      loadingStyle: AppLoadingIndicatorStyle.goldenCoin3D,
      cardRadius: 24.0,
      buttonRadius: 20.0,
      ambientBlur: AmbientBlurPreset.rubyVelvet,
      highRefreshRate120Hz: true,
    ),
    CuratedCommunityThemePreset(
      id: 'cosmic_deep_aurora',
      title: 'Cosmic Deep Aurora',
      subtitle: 'Cực quang vũ trụ tím thạch anh, Swiss Modernist cân đối',
      author: 'Cosmic Atelier',
      downloads: '16.9k',
      rating: 4.97,
      tags: ['SWISS UI', 'INTER', 'AURORA'],
      gradientColors: [Color(0xFF8B5CF6), Color(0xFFC084FC)],
      palette: AppColorPalette.amethystRoyal,
      fontFamily: AppFontFamily.inter,
      heroCardStyle: AppHeroCardStyle.liquidEnergySphere,
      dockNavStyle: AppDockNavStyle.glassNeonUnderline,
      categoryIconStyle: AppCategoryIconStyle.diamondFacet,
      buttonVisualKind: AppButtonStyle.modernPill,
      loadingStyle: AppLoadingIndicatorStyle.infinityDots,
      cardRadius: 20.0,
      buttonRadius: 18.0,
      ambientBlur: AmbientBlurPreset.cosmicAmethyst,
      highRefreshRate120Hz: true,
    ),
  ];

  /// Kích hoạt Preset Cộng Đồng tuyển chọn và lưu trữ
  Future<void> applyCuratedCommunityPreset(
      CuratedCommunityThemePreset preset) async {
    if (!_lockedComponents.contains('palette')) {
      _palette = preset.palette;
    }
    if (!_lockedComponents.contains('font')) {
      _fontFamily = preset.fontFamily;
    }
    if (!_lockedComponents.contains('heroCard')) {
      _heroCardStyle = preset.heroCardStyle;
    }
    if (!_lockedComponents.contains('dockNav')) {
      _dockNavStyle = preset.dockNavStyle;
    }
    if (!_lockedComponents.contains('categoryIcon')) {
      _categoryIconStyle = preset.categoryIconStyle;
    }
    if (!_lockedComponents.contains('buttonVisual')) {
      _buttonVisualKind = preset.buttonVisualKind;
    }
    if (!_lockedComponents.contains('loading')) {
      _loadingStyle = preset.loadingStyle;
    }
    if (!_lockedComponents.contains('cardRadius')) {
      _customCardCornerRadius = preset.cardRadius;
    }
    if (!_lockedComponents.contains('buttonRadius')) {
      _customButtonCornerRadius = preset.buttonRadius;
    }
    if (!_lockedComponents.contains('ambientBlur')) {
      _ambientBlur = preset.ambientBlur;
    }
    _highRefreshRate120Hz = preset.highRefreshRate120Hz;

    notifyListeners();
    performHaptic();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_paletteKey, _palette.index);
    await prefs.setInt(_fontFamilyKey, _fontFamily.index);
    await prefs.setInt(_heroCardStyleKey, _heroCardStyle.index);
    await prefs.setInt(_dockNavKey, _dockNavStyle.index);
    await prefs.setInt(_categoryIconStyleKey, _categoryIconStyle.index);
    await prefs.setInt(_buttonVisualKindKey, _buttonVisualKind.index);
    await prefs.setInt(_loadingStyleKey, _loadingStyle.index);
    if (_customCardCornerRadius != null) {
      await prefs.setDouble(
          _customCardCornerRadiusKey, _customCardCornerRadius!);
    }
    if (_customButtonCornerRadius != null) {
      await prefs.setDouble(
          _customButtonCornerRadiusKey, _customButtonCornerRadius!);
    }
    await prefs.setInt(_ambientBlurKey, _ambientBlur.index);
    await prefs.setBool(_highRefreshRate120HzKey, _highRefreshRate120Hz);
  }

  Future<bool> saveCustomPreset(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    final code = exportThemeCode();
    _customPresetsMap[trimmed] = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customUserPresetsKey, jsonEncode(_customPresetsMap));
    return true;
  }

  Future<void> saveAllToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_iconScaleKey, _iconScale);
    await prefs.setDouble(_iconCornerRadiusKey, _iconCornerRadius);
    await prefs.setDouble(_iconLabelScaleKey, _iconLabelScale);
    await prefs.setInt(_paletteKey, _palette.index);
    await prefs.setInt(_dockNavKey, _dockNavStyle.index);
    await prefs.setInt(_dockIconStyleKey, _dockIconStyle.index);
    await prefs.setInt(_buttonVisualKindKey, _buttonVisualKind.index);
    await prefs.setInt(_buttonColorModeKey, _buttonColorMode.index);
    await prefs.setDouble(_customButtonCornerRadiusKey, buttonCornerRadius);
    await prefs.setDouble(_customCardCornerRadiusKey, cardCornerRadius);
    await prefs.setDouble(_glassBlurKey, _glassBlur);
    await prefs.setDouble(_glassOpacityKey, _glassOpacity);
    await prefs.setDouble(_fontScaleKey, _fontScale);
    await prefs.setInt(_fontFamilyKey, _fontFamily.index);
    await prefs.setDouble(_backgroundTintOpacityKey, _backgroundTintOpacity);
    await prefs.setInt(_ambientBlurKey, _ambientBlur.index);
    await prefs.setInt(_chartCurveStyleKey, _chartCurveStyle.index);
    await prefs.setInt(_categoryIconStyleKey, _categoryIconStyle.index);
    await prefs.setInt(_aiBubbleStyleKey, _aiBubbleStyle.index);
    await prefs.setInt(_loadingStyleKey, _loadingStyle.index);
    await prefs.setBool(_highRefreshRate120HzKey, _highRefreshRate120Hz);
    notifyListeners();
  }

  Future<void> resetAllToDefault() async {
    _iconScale = 1.0;
    _iconCornerRadius = 18.0;
    _iconLabelScale = 1.0;
    _palette = AppColorPalette.oceanicSapphire;
    _dockNavStyle = AppDockNavStyle.floatingIsland;
    _dockIconStyle = AppDockIconStyle.modernLucide;
    _buttonVisualKind = AppButtonStyle.modernPill;
    _buttonColorMode = AppButtonColorMode.paletteSync;
    _customButtonCornerRadius = null;
    _customCardCornerRadius = null;
    _glassBlur = 25.0;
    _glassOpacity = 0.88;
    _fontScale = 1.0;
    _fontFamily = AppFontFamily.plusJakartaSans;
    _backgroundTintOpacity = 0.85;
    _ambientBlur = AmbientBlurPreset.rainbowAurora;
    _chartCurveStyle = AppChartCurveStyle.smoothSpline;
    _categoryIconStyle = AppCategoryIconStyle.modernSquircle;
    _heroCardStyle = AppHeroCardStyle.spatialPrismOrbital;
    _loadingStyle = AppLoadingIndicatorStyle.liquidRipple;
    _highRefreshRate120Hz = true;
    applyHighRefreshRateNative();
    notifyListeners();
    await saveAllToPrefs();
  }

  Future<bool> loadCustomPreset(String name) async {
    final code = _customPresetsMap[name];
    if (code == null) return false;
    return await importThemeCode(code);
  }

  Future<bool> deleteCustomPreset(String name) async {
    if (!_customPresetsMap.containsKey(name)) return false;
    _customPresetsMap.remove(name);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customUserPresetsKey, jsonEncode(_customPresetsMap));
    return true;
  }

  Future<void> applyMasterUiPreset(AppMasterUiPreset preset,
      {bool respectLocks = true}) async {
    final meta = allMasterUiPresets.firstWhere((p) => p.preset == preset);
    if (!respectLocks || !isLocked('palette')) {
      _palette = meta.palette;
    }
    if (!respectLocks || !isLocked('uiUxStyle')) {
      _uiUxStyle = meta.uiUxStyle;
    }
    _wallpaperPreset = AppWallpaperPreset.none;
    final bool iconLocked = isLocked('icon_style') || isLocked('iconStyle');
    if (!respectLocks || !iconLocked) {
      _iconStyle = meta.iconStyle;
      if (meta.iconShape != null) {
        _iconShape = meta.iconShape!;
      }
      if (meta.iconVisualEffect != null) {
        _iconVisualEffect = meta.iconVisualEffect!;
      }
    }
    if (meta.seasonalTheme != null &&
        (!respectLocks || !isLocked('seasonalTheme'))) {
      _seasonalTheme = meta.seasonalTheme!;
    }
    _heroCardStyle = meta.heroCardStyle;
    final bool dockLocked = isLocked('dock_style') || isLocked('dockStyle');
    if (!respectLocks || !dockLocked) {
      _dockNavStyle = meta.dockNavStyle;
    }
    if (!respectLocks || !isLocked('dockLabel')) {
      _dockLabelStyle = meta.dockLabelStyle;
    }
    _avatarGlowStyle = meta.avatarGlow;
    _membershipTier = meta.membershipTier;
    _aiBubbleStyle = meta.aiBubbleStyle;
    _aiAvatarIcon = meta.aiAvatarIcon;
    _chartCurveStyle = meta.chartCurveStyle;
    _chartAreaFill = meta.chartAreaFill;
    _chartColorway = meta.chartColorway;
    final bool cardSkinLocked = isLocked('card_skin') || isLocked('cardSkin');
    if (!respectLocks || !cardSkinLocked) {
      _globalCardSkin = meta.cardSkin;
    }
    if (!respectLocks || !isLocked('corner')) {
      _cornerStyle = meta.cornerStyle;
    }
    if (meta.ambientBlur != null) _ambientBlur = meta.ambientBlur!;
    final bool typographyLocked =
        isLocked('typography') || isLocked('fontFamily');
    if (!respectLocks || !typographyLocked) {
      if (meta.fontFamily != null) _fontFamily = meta.fontFamily!;
    }
    if (meta.density != null) _globalDensity = meta.density!;
    final bool buttonLocked = isLocked('button_style') ||
        isLocked('buttonStyle') ||
        isLocked('buttonShape');
    if (!respectLocks || !buttonLocked) {
      if (meta.buttonShape != null) _buttonShape = meta.buttonShape!;
    }
    if (meta.motion != null) _motionDynamics = meta.motion!;
    final bool borderGlowLocked =
        isLocked('border_glow') || isLocked('borderGlow');
    if (!respectLocks || !borderGlowLocked) {
      if (meta.borderGlow != null) _borderGlowStyle = meta.borderGlow!;
    }
    final bool glassLocked =
        isLocked('glass_optics') || isLocked('glassOptics');
    if (!respectLocks || !glassLocked) {
      if (meta.glassOpacity != null) {
        _glassOpacity = meta.glassOpacity!.clamp(0.08, 1.0);
      }
      if (meta.glassBlur != null) {
        _glassBlur = meta.glassBlur!.clamp(0.0, 32.0);
      }
    }
    if (meta.particleSparkles != null) {
      _particleSparkles = meta.particleSparkles!;
    }

    notifyListeners();
    performHaptic();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_paletteKey, _palette.index);
    await prefs.setInt(_uiUxStyleKey, _uiUxStyle.index);
    await prefs.setInt(_wallpaperKey, _wallpaperPreset.index);
    await prefs.setInt(_iconStyleKey, _iconStyle.index);
    await prefs.setInt(_iconShapeKey, _iconShape.index);
    await prefs.setInt(_iconVisualEffectKey, _iconVisualEffect.index);
    await prefs.setInt(_heroCardStyleKey, _heroCardStyle.index);
    await prefs.setInt(_dockNavKey, _dockNavStyle.index);
    await prefs.setInt(_dockLabelStyleKey, _dockLabelStyle.index);
    await prefs.setInt(_avatarGlowStyleKey, _avatarGlowStyle.index);
    await prefs.setInt(_membershipTierKey, _membershipTier.index);
    await prefs.setInt(_aiBubbleStyleKey, _aiBubbleStyle.index);
    await prefs.setInt(_aiAvatarIconKey, _aiAvatarIcon.index);
    await prefs.setInt(_chartCurveStyleKey, _chartCurveStyle.index);
    await prefs.setInt(_chartAreaFillKey, _chartAreaFill.index);
    await prefs.setInt(_chartColorwayKey, _chartColorway.index);
    await prefs.setInt(_globalCardSkinKey, _globalCardSkin.index);
    await prefs.setInt(_cornerKey, _cornerStyle.index);
    if (meta.seasonalTheme != null) {
      await prefs.setInt(_seasonalThemeKey, _seasonalTheme.index);
    }
    if (meta.ambientBlur != null) {
      await prefs.setInt(_ambientBlurKey, _ambientBlur.index);
    }
    if (meta.fontFamily != null) {
      await prefs.setInt(_fontFamilyKey, _fontFamily.index);
    }
    if (meta.density != null) {
      await prefs.setInt(_densityKey, _globalDensity.index);
    }
    if (meta.buttonShape != null) {
      await prefs.setInt(_buttonShapeKey, _buttonShape.index);
    }
    if (meta.motion != null) {
      await prefs.setInt(_motionKey, _motionDynamics.index);
    }
    if (meta.borderGlow != null) {
      await prefs.setInt(_borderGlowKey, _borderGlowStyle.index);
    }
    if (meta.glassOpacity != null) {
      await prefs.setDouble(_glassOpacityKey, _glassOpacity);
    }
    if (meta.glassBlur != null) {
      await prefs.setDouble(_glassBlurKey, _glassBlur);
    }
    if (meta.particleSparkles != null) {
      await prefs.setBool(_particleSparklesKey, _particleSparkles);
    }
  }

  /// Resolve gradient for Bank & Credit Cards
  AppCardSkinStyle resolveWalletCardSkinStyle(String? walletId) {
    if (walletId != null && _walletCardSkins.containsKey(walletId)) {
      final val = _walletCardSkins[walletId]!;
      final skin = AppCardSkinStyle.values.cast<AppCardSkinStyle?>().firstWhere(
            (s) => s?.name == val,
            orElse: () => null,
          );
      if (skin != null) return skin;
    }
    return _globalCardSkin;
  }

  List<Color> getBankCardGradient({
    String? walletId,
    String? bankCode,
    String? bankName,
    String? name,
    String? themeColor,
  }) {
    if (walletId != null && _walletCardSkins.containsKey(walletId)) {
      final val = _walletCardSkins[walletId]!;
      if (val.startsWith('custom:')) {
        try {
          final hexList = val.substring(7).split(',');
          final cols =
              hexList.map((h) => Color(int.parse(h, radix: 16))).toList();
          if (cols.length >= 2) return cols;
        } catch (_) {}
      }
    }

    return resolveBankBrandGradient(
      bankCode: bankCode,
      bankName: bankName,
      name: name,
      themeColor: themeColor,
    );
  }

  List<Color> getCardSkinGradient(AppCardSkinStyle style) {
    if (style == AppCardSkinStyle.customGradient) {
      return _customCardGradientColors;
    }
    final meta = allCardSkins.cast<CardSkinMeta?>().firstWhere(
          (m) => m?.style == style,
          orElse: () => null,
        );
    return meta?.colors ??
        const [Color(0xFF0F63A1), Color(0xFF0B7CBE), Color(0xFF22ACEB)];
  }

  List<Color> resolveBankBrandGradient({
    String? bankCode,
    String? bankName,
    String? name,
    String? themeColor,
  }) {
    // 1. If wallet has an assigned custom color in settings, honor it first!
    if (themeColor != null && themeColor.isNotEmpty) {
      if (CreditCardPalette.skins.containsKey(themeColor)) {
        return CreditCardPalette.skins[themeColor]!;
      }
      Color base = const Color(0xFF005FEA);
      try {
        final hex = themeColor.replaceAll('#', '').replaceAll('0x', '');
        if (hex.length == 6) {
          base = Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          base = Color(int.parse(hex, radix: 16));
        }
        return [
          base,
          HSLColor.fromColor(base)
              .withLightness(
                  (HSLColor.fromColor(base).lightness + 0.15).clamp(0.0, 1.0))
              .toColor(),
          HSLColor.fromColor(base)
              .withLightness(
                  (HSLColor.fromColor(base).lightness - 0.12).clamp(0.0, 1.0))
              .toColor(),
        ];
      } catch (_) {}
    }

    // 2. Otherwise resolve official bank brand identity gradient
    final effective = (bankCode ?? bankName ?? name ?? '').toLowerCase();
    final clean = effective.replaceAll(RegExp(r'[^a-z0-9]'), '');

    if (clean.contains('techcom') || clean.contains('tcb')) {
      return const [Color(0xFF8B0000), Color(0xFFCC0000), Color(0xFFFF2222)];
    }
    if (clean.contains('vietcombank') || clean.contains('vcb')) {
      return const [Color(0xFF0D47A1), Color(0xFF00695C), Color(0xFF00897B)];
    }
    if (clean.contains('mb') || clean.contains('mbbank')) {
      return const [Color(0xFF002244), Color(0xFF003882), Color(0xFF0056B3)];
    }
    if (clean.contains('bidv')) {
      return const [Color(0xFF00564B), Color(0xFF00796B), Color(0xFF00A896)];
    }
    if (clean.contains('ctg') ||
        clean.contains('vtb') ||
        clean.contains('vietinbank')) {
      return const [Color(0xFF003865), Color(0xFF005BAA), Color(0xFF0088FF)];
    }
    if (clean.contains('acb')) {
      return const [Color(0xFF0A3D91), Color(0xFF0F56B3), Color(0xFF2563EB)];
    }
    if (clean.contains('vpb') || clean.contains('vpbank')) {
      return const [Color(0xFF006837), Color(0xFF00904B), Color(0xFF10B981)];
    }
    if (clean.contains('tpb') || clean.contains('tpbank')) {
      return const [Color(0xFF581C87), Color(0xFF7E22CE), Color(0xFFA855F7)];
    }
    if (clean.contains('stb') || clean.contains('sacombank')) {
      return const [Color(0xFF004080), Color(0xFF0058A8), Color(0xFF0077CC)];
    }
    if (clean.contains('timo')) {
      return const [Color(0xFF4318FF), Color(0xFF6B46C1), Color(0xFF7928CA)];
    }
    if (clean.contains('momo')) {
      return const [Color(0xFF830051), Color(0xFFA50064), Color(0xFFD81B60)];
    }
    if (clean.contains('zalo')) {
      return const [Color(0xFF0052CC), Color(0xFF0088FF), Color(0xFF38B6FF)];
    }
    if (clean.contains('cake')) {
      return const [Color(0xFFB71C1C), Color(0xFFFF424E)];
    }
    if (clean.contains('vib')) {
      return const [Color(0xFF003C78), Color(0xFF0072CE)];
    }
    if (clean.contains('hdb') || clean.contains('hdbank')) {
      return const [Color(0xFF9E1B20), Color(0xFFCA2624), Color(0xFFE4333A)];
    }

    if (themeColor != null && themeColor.isNotEmpty) {
      Color base = const Color(0xFF005FEA);
      try {
        final hex = themeColor.replaceAll('#', '').replaceAll('0x', '');
        if (hex.length == 6) {
          base = Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          base = Color(int.parse(hex, radix: 16));
        }
      } catch (_) {}
      return [
        base,
        HSLColor.fromColor(base)
            .withLightness(
                (HSLColor.fromColor(base).lightness + 0.15).clamp(0.0, 1.0))
            .toColor(),
      ];
    }

    return const [Color(0xFF0F63A1), Color(0xFF0B7CBE), Color(0xFF22ACEB)];
  }

  /// Gradient riêng cho Hero Card (Tổng tài sản) theo AppHeroCardTint
  List<Color> getHeroCardGradient(bool isDark) {
    switch (_heroCardTint) {
      case AppHeroCardTint.paletteSync:
        return currentPaletteMeta.heroGradient;
      case AppHeroCardTint.deepCosmic:
        return const [Color(0xFF4C1D95), Color(0xFF6D28D9), Color(0xFF2E1065)];
      case AppHeroCardTint.emeraldGlow:
        return const [Color(0xFF065F46), Color(0xFF059669), Color(0xFF047857)];
      case AppHeroCardTint.rubySunset:
        return const [Color(0xFF9F1239), Color(0xFFE11D48), Color(0xFFBE123C)];
      case AppHeroCardTint.cyberPulse:
        return const [Color(0xFF0369A1), Color(0xFF0284C7), Color(0xFF8B5CF6)];
      case AppHeroCardTint.frostWhite:
        return isDark
            ? const [Color(0xFF334155), Color(0xFF475569), Color(0xFF1E293B)]
            : const [Color(0xFFE2E8F0), Color(0xFFCBD5E1), Color(0xFFF1F5F9)];
      case AppHeroCardTint.pitchAmoled:
        return const [Color(0xFF090D16), Color(0xFF131A2A), Color(0xFF05070B)];
    }
  }

  /// Màu sắc theo loại giao dịch
  Color getExpenseColor(bool isDark) => _expenseColor;
  Color getIncomeColor(bool isDark) => _incomeColor;
  Color getTransferColor(bool isDark) => _transferColor;

  /// Màu sắc thanh tiến độ ngân sách theo tỷ lệ chi tiêu
  Color getBudgetColor(double percent) {
    if (percent >= 1.0) return _budgetDangerColor;
    if (percent >= 0.7) return _budgetWarningColor;
    return _budgetSafeColor;
  }

  String? get fontFamilyName => switch (_fontFamily) {
        AppFontFamily.plusJakartaSans => 'PlusJakartaSans',
        AppFontFamily.beVietnamPro => 'BeVietnamPro',
        AppFontFamily.inter => 'Inter',
        AppFontFamily.outfit => 'Outfit',
        AppFontFamily.lexend => 'Lexend',
        AppFontFamily.manrope => 'Manrope',
        AppFontFamily.systemModern => 'Arial',
        AppFontFamily.roundedFriendly => 'SegoeUI',
        AppFontFamily.fintechMonospace => 'Bahnschrift',
        AppFontFamily.executiveSerif => 'Georgia',
      };

  List<String> get fontFamilyFallback => switch (_fontFamily) {
        AppFontFamily.plusJakartaSans => const [
            'PlusJakartaSans',
            'BeVietnamPro',
            'Inter',
            'Roboto',
            'sans-serif',
          ],
        AppFontFamily.beVietnamPro => const [
            'BeVietnamPro',
            'PlusJakartaSans',
            'Inter',
            'Roboto',
            'sans-serif',
          ],
        AppFontFamily.inter => const [
            'Inter',
            'PlusJakartaSans',
            'BeVietnamPro',
            'Roboto',
            'sans-serif',
          ],
        AppFontFamily.outfit => const [
            'Outfit',
            'PlusJakartaSans',
            'BeVietnamPro',
            'Roboto',
            'sans-serif',
          ],
        AppFontFamily.lexend => const [
            'Lexend',
            'PlusJakartaSans',
            'BeVietnamPro',
            'Roboto',
            'sans-serif',
          ],
        AppFontFamily.manrope => const [
            'Manrope',
            'PlusJakartaSans',
            'BeVietnamPro',
            'Roboto',
            'sans-serif',
          ],
        AppFontFamily.systemModern => const [
            'Arial',
            'Roboto',
            'sans-serif',
          ],
        AppFontFamily.roundedFriendly => const [
            'SegoeUI',
            'system-ui',
            'sans-serif',
          ],
        AppFontFamily.fintechMonospace => const [
            'Bahnschrift',
            'monospace',
          ],
        AppFontFamily.executiveSerif => const [
            'Georgia',
            'serif',
          ],
      };

  Duration get motionDuration => getAnimationDuration();
  Curve get motionCurve => getAnimationCurve();

  Duration getAnimationDuration(
      [Duration base = const Duration(milliseconds: 300)]) {
    switch (_motionDynamics) {
      case AppMotionDynamics.reducedMotion:
        return Duration.zero;
      case AppMotionDynamics.snappySwift:
        return Duration(milliseconds: (base.inMilliseconds * 0.55).round());
      case AppMotionDynamics.smoothGentle:
        return base;
    }
  }

  Curve getAnimationCurve() {
    switch (_motionDynamics) {
      case AppMotionDynamics.reducedMotion:
        return Curves.linear;
      case AppMotionDynamics.snappySwift:
        return Curves.easeOutCubic;
      case AppMotionDynamics.smoothGentle:
        return Curves.easeInOutCubicEmphasized;
    }
  }

  String formatCurrency(num amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final intPart = absAmount.truncate();
    final strInt = intPart.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    final prefix = isNegative ? '-' : '';
    switch (_currencyFormat) {
      case AppCurrencyFormat.symbolSuffix:
        return '$prefix$strInt ₫';
      case AppCurrencyFormat.codeSuffix:
        return '$prefix$strInt VND';
      case AppCurrencyFormat.symbolPrefix:
        return '$prefix₫ $strInt';
    }
  }

  Color getCardFillColor(bool isDark) {
    if (_freshAppearance) {
      return isDark ? const Color(0xFF1B2531) : Colors.white;
    }
    final base = getStyleSurfaceBase(isDark) ??
        (isDark ? const Color(0xFF131B26) : Colors.white);
    return base;
  }

  /// Lấy màu nền thực tế ở đỉnh màn hình để AppBar/Header kính mờ hòa quyện đồng điệu
  /// theo đúng màu nền/wallpaper/gradient đang áp dụng, triệt tiêu hoàn toàn mảng trắng đục.
  Color getScreenTopBackgroundColor(bool isDark) {
    if (_freshAppearance) {
      return isDark ? const Color(0xFF111820) : const Color(0xFFF5F8FF);
    }
    if (_useCustomBgGradient ||
        _wallpaperPreset == AppWallpaperPreset.customGradient) {
      final customColors = getEffectiveCustomBgGradientColors(isDark);
      if (customColors.isNotEmpty) return customColors.first;
    }
    final styleBase = getStyleSurfaceBase(isDark);
    if (styleBase != null) return styleBase;
    final styleBg = getStyleBackgroundColors(isDark);
    if (styleBg != null && styleBg.isNotEmpty) return styleBg.first;
    if (_ambientBlur == AmbientBlurPreset.amoledPitch && isDark) {
      return Colors.black;
    }
    final meta = currentAmbientBlurMeta;
    if (meta.preset != AmbientBlurPreset.rainbowAurora) {
      final raw = isDark ? meta.bgColorsDark : meta.bgColorsLight;
      if (raw.isNotEmpty) {
        return Color.alphaBlend(
            primaryColor.withValues(alpha: isDark ? 0.12 : 0.05), raw.first);
      }
    }
    final paletteBg =
        isDark ? currentPaletteMeta.darkBg : currentPaletteMeta.lightBg;
    return Color.alphaBlend(
        primaryColor.withValues(alpha: isDark ? 0.12 : 0.04), paletteBg);
  }

  /// Palette accents remain independently editable; these surfaces define the
  /// material of the six additional design families on real app screens.
  Color? getStyleSurfaceBase(bool isDark) => switch (_uiUxStyle) {
        AppUiUxStyle.googleMinimal =>
          isDark ? const Color(0xFF131B26) : Colors.white,
        AppUiUxStyle.ledgerEditorial =>
          isDark ? const Color(0xFF20252B) : const Color(0xFFFCFAF5),
        AppUiUxStyle.softPaper =>
          isDark ? const Color(0xFF302923) : const Color(0xFFFFF9EF),
        AppUiUxStyle.industrialUtility =>
          isDark ? const Color(0xFF20262A) : const Color(0xFFF0F2F2),
        AppUiUxStyle.organicClay =>
          isDark ? const Color(0xFF263329) : const Color(0xFFF5EBDD),
        AppUiUxStyle.einkFocus =>
          isDark ? const Color(0xFF111111) : Colors.white,
        AppUiUxStyle.artDecoFinance =>
          isDark ? const Color(0xFF19212C) : const Color(0xFFFAF7F0),
        _ => null,
      };

  List<Color>? getStyleBackgroundColors(bool isDark) => switch (_uiUxStyle) {
        AppUiUxStyle.googleMinimal => isDark
            ? const [Color(0xFF090D14), Color(0xFF0F1522)]
            : const [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        AppUiUxStyle.ledgerEditorial => isDark
            ? const [Color(0xFF171C22), Color(0xFF252930), Color(0xFF171C22)]
            : const [Color(0xFFF5F0E7), Color(0xFFFCFAF5), Color(0xFFEDE5D8)],
        AppUiUxStyle.softPaper => isDark
            ? const [Color(0xFF251F1A), Color(0xFF342B23), Color(0xFF251F1A)]
            : const [Color(0xFFFFF8EC), Color(0xFFF7EDDF), Color(0xFFFFF9EF)],
        AppUiUxStyle.industrialUtility => isDark
            ? const [Color(0xFF151A1D), Color(0xFF242D31), Color(0xFF151A1D)]
            : const [Color(0xFFE7ECEE), Color(0xFFF3F5F4), Color(0xFFE3E9EA)],
        AppUiUxStyle.organicClay => isDark
            ? const [Color(0xFF1C2B21), Color(0xFF354437), Color(0xFF26291E)]
            : const [Color(0xFFF1E5D5), Color(0xFFEEE4D6), Color(0xFFE4EBDD)],
        AppUiUxStyle.einkFocus => isDark
            ? const [Color(0xFF080808), Color(0xFF101010), Color(0xFF080808)]
            : const [Colors.white, Color(0xFFF7F7F7), Colors.white],
        AppUiUxStyle.artDecoFinance => isDark
            ? const [Color(0xFF101722), Color(0xFF253044), Color(0xFF101722)]
            : const [Color(0xFFF5EFE2), Color(0xFFFCFAF5), Color(0xFFE9E0CE)],
        _ => null,
      };

  bool get prefersQuietBackground => switch (_uiUxStyle) {
        AppUiUxStyle.googleMinimal ||
        AppUiUxStyle.ledgerEditorial ||
        AppUiUxStyle.softPaper ||
        AppUiUxStyle.industrialUtility ||
        AppUiUxStyle.einkFocus =>
          true,
        _ => false,
      };

  Color getCardFill(bool isDark) => getCardFillColor(isDark);

  /// Lấy màu nền cho các thẻ card / widget màu trắng
  /// Cho phép điều chỉnh độ trong suốt theo `_glassOpacity` (từ 35% đến 95%).
  Color getWhiteCardBg(bool isDark) {
    final base = getStyleSurfaceBase(isDark) ??
        (isDark ? const Color(0xFF1E293B) : Colors.white);
    return base.withValues(alpha: _glassOpacity);
  }

  /// Lấy màu nền cho các Modal / BottomSheet / Dialog màu trắng (độ che phủ chắc chắn, tương phản chữ cao, không bị thấu quang bừa bãi làm lóa mắt)
  Color getWhiteModalBg(bool isDark) {
    final base = getStyleSurfaceBase(isDark) ??
        (isDark ? const Color(0xFF0F172A) : Colors.white);
    final alpha = isDark
        ? (0.88 + _glassOpacity * 0.08).clamp(0.88, 0.96)
        : (0.91 + _glassOpacity * 0.07).clamp(0.91, 0.98);
    return base.withValues(alpha: alpha);
  }

  /// Quy tắc:
  /// - Widget/thẻ màu trắng (hoặc thẻ panel sáng / nền dark panel): áp dụng độ trong suốt `_glassOpacity`.
  /// - Widget CÓ MÀU SẮC (xanh, đỏ, cam, tím, vàng, gradient, accent): GIỮ NGUYÊN 100% MÀU SẮC ĐẬM ĐÀ!
  Color applyWhiteTransparency(Color color, {required bool isDark}) {
    // Nhận diện màu trắng hoặc gần trắng (không có sắc thái màu riêng)
    final r = (color.r * 255.0).round();
    final g = (color.g * 255.0).round();
    final b = (color.b * 255.0).round();
    final bool isWhiteLike = (color == Colors.white) ||
        (r >= 235 &&
            g >= 235 &&
            b >= 235 &&
            (r - g).abs() <= 12 &&
            (g - b).abs() <= 12);
    if (isWhiteLike) {
      return Colors.white.withValues(alpha: _glassOpacity);
    }

    // Nhận diện nền thẻ tối mặc định ở dark mode (xám/đen trung tính, không phải màu thương hiệu)
    if (isDark) {
      final isDarkCardBase = color == const Color(0xFF1E293B) ||
          color == const Color(0xFF0F172A) ||
          color == const Color(0xFF111C30) ||
          color == const Color(0xFF131D33) ||
          color == const Color(0xFF161B26) ||
          color == const Color(0xFF182030) ||
          color == const Color(0xFF1A2234) ||
          (color.r < 0.15 && color.g < 0.15 && color.b < 0.20);
      if (isDarkCardBase) {
        return color.withValues(alpha: _glassOpacity);
      }
    }

    // Áp dụng độ trong suốt _glassOpacity theo tỷ lệ của màu sắc
    return color.withValues(
        alpha: (color.a * (_glassOpacity / 0.65)).clamp(0.12, 1.0));
  }

  Color getModalFillColor(bool isDark) => getWhiteModalBg(isDark);

  Color getModalBorderColor(bool isDark) {
    return isDark
        ? const Color(0xFF334155).withValues(alpha: 0.5)
        : const Color(0xFFE2E8F0);
  }

  Color getBorderColor(bool isDark) {
    if (_borderGlowStyle == CardBorderGlowStyle.none) {
      return Colors.transparent;
    }
    return isDark
        ? Colors.white.withValues(alpha: 0.14)
        : const Color(0xFFE2E8F0);
  }

  /// Lấy viền thẻ card đồng bộ theo CardBorderGlowStyle và _widgetBorderWidth
  Border? getCardBorder(bool isDark) {
    if (_widgetBorderWidth <= 0.05) return null;
    final primary = primaryColor;
    switch (_borderGlowStyle) {
      case CardBorderGlowStyle.none:
        return Border.all(
          color: (isDark ? Colors.white : const Color(0xFF0F172A))
              .withValues(alpha: isDark ? 0.12 : 0.08),
          width: _widgetBorderWidth,
        );
      case CardBorderGlowStyle.neonLuminescent:
        return Border.all(
          color: primary.withValues(alpha: isDark ? 0.85 : 0.70),
          width: _widgetBorderWidth,
        );
      case CardBorderGlowStyle.gradientRim:
        return Border.all(
          color: primary.withValues(alpha: isDark ? 0.55 : 0.45),
          width: _widgetBorderWidth,
        );
      case CardBorderGlowStyle.subtleHairline:
        return Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : const Color(0xFFE2E8F0),
          width: _widgetBorderWidth,
        );
    }
  }

  /// Lấy danh sách đổ bóng hào quang theo CardBorderGlowStyle
  List<BoxShadow> getGlowShadows(bool isDark) {
    final primary = primaryColor;
    if (_borderGlowStyle == CardBorderGlowStyle.neonLuminescent) {
      return [
        BoxShadow(
          color: primary.withValues(alpha: isDark ? 0.18 : 0.10),
          blurRadius: 20,
          spreadRadius: -1,
          offset: const Offset(0, 3),
        ),
      ];
    } else if (_borderGlowStyle == CardBorderGlowStyle.gradientRim) {
      return [
        BoxShadow(
          color: primary.withValues(alpha: isDark ? 0.12 : 0.06),
          blurRadius: 16,
          spreadRadius: -2,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return const [];
  }

  double getButtonRadius() => buttonCornerRadius;

  double getButtonHeight() => switch (_buttonSize) {
        AppButtonSize.compact => 40.0,
        AppButtonSize.standard => 48.0,
        AppButtonSize.comfortable => 54.0,
      };

  EdgeInsetsGeometry getButtonPadding() => switch (_buttonSize) {
        AppButtonSize.compact =>
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        AppButtonSize.standard =>
          const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        AppButtonSize.comfortable =>
          const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
      };

  double getIconButtonSize() => switch (_buttonSize) {
        AppButtonSize.compact => 38.0,
        AppButtonSize.standard => 44.0,
        AppButtonSize.comfortable => 50.0,
      };

  /// Lấy Decoration cho icon container kết hợp tự do giữa AppIconShape và AppIconVisualEffect
  Decoration getIconContainerDecoration({
    required Color color,
    required bool isDark,
    double size = 44,
  }) {
    return getPreviewDecorationForCategoryStyle(
      _categoryIconStyle,
      color: color,
      isDark: isDark,
      size: size,
    );
  }

  /// Lấy Decoration xem trước cho một kiểu danh mục cụ thể (không phụ thuộc vào thiết lập đang chọn)
  Decoration getPreviewDecorationForCategoryStyle(
    AppCategoryIconStyle style, {
    required Color color,
    required bool isDark,
    double size = 40,
  }) {
    final (AppIconShape shape, AppIconVisualEffect effect) = switch (style) {
      AppCategoryIconStyle.modernSquircle => (
          AppIconShape.squircle,
          AppIconVisualEffect.gradientFlow
        ),
      AppCategoryIconStyle.minimalCircle => (
          AppIconShape.circle,
          AppIconVisualEffect.flatMinimal
        ),
      AppCategoryIconStyle.glassSphere => (
          AppIconShape.circle,
          AppIconVisualEffect.liquidGlass
        ),
      AppCategoryIconStyle.duotoneTonal => (
          AppIconShape.roundedSquare,
          AppIconVisualEffect.duotoneGlass
        ),
      AppCategoryIconStyle.neonBadge => (
          AppIconShape.hexagon,
          AppIconVisualEffect.cyberNeon
        ),
      AppCategoryIconStyle.paperEmbossed => (
          AppIconShape.squircle,
          AppIconVisualEffect.neumorphicSoft
        ),
      AppCategoryIconStyle.minimalOutline => (
          AppIconShape.roundedSquare,
          AppIconVisualEffect.outlineMinimal
        ),
      AppCategoryIconStyle.diamondFacet => (
          AppIconShape.diamond,
          AppIconVisualEffect.jewelCrystal
        ),
    };
    return getIconContainerDecorationExplicit(
      shape: shape,
      effect: effect,
      color: color,
      isDark: isDark,
      size: size,
    );
  }

  Decoration getIconContainerDecorationExplicit({
    required AppIconShape shape,
    required AppIconVisualEffect effect,
    required Color color,
    required bool isDark,
    double size = 44,
  }) {
    final effectiveColor = resolveIconBgColor(color, isDark);
    final op = _iconBgOpacity;

    // 1. Xác định ShapeBorder theo shape và góc bo _iconCornerRadius
    final OutlinedBorder baseShape;
    switch (shape) {
      case AppIconShape.circle:
        baseShape = const CircleBorder();
      case AppIconShape.squircle:
        baseShape = RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(_iconCornerRadius.clamp(2.0, size * 0.48)),
        );
      case AppIconShape.roundedSquare:
        baseShape = RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
              (_iconCornerRadius * 0.7).clamp(2.0, size * 0.45)),
        );
      case AppIconShape.teardrop:
        baseShape = RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(size * 0.45),
            topRight: Radius.circular(size * 0.45),
            bottomRight: Radius.circular(size * 0.45),
            bottomLeft: Radius.circular(size * 0.12),
          ),
        );
      case AppIconShape.hexagon:
        baseShape = const StarBorder.polygon(sides: 6, pointRounding: 0.18);
      case AppIconShape.diamond:
        baseShape = const StarBorder.polygon(sides: 4, pointRounding: 0.15);
      case AppIconShape.shield:
        baseShape = RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(size * 0.36),
            topRight: Radius.circular(size * 0.36),
            bottomLeft: Radius.circular(size * 0.48),
            bottomRight: Radius.circular(size * 0.48),
          ),
        );
      case AppIconShape.chamferedOctagon:
        baseShape = BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(size * 0.28),
        );
      case AppIconShape.capsule:
        baseShape = const StadiumBorder();
    }

    // 2. Xác định màu, viền, gradient, bóng đổ theo effect
    BorderSide borderSide;
    Color? fillColor;
    Gradient? fillGradient;
    List<BoxShadow> shadows = [];

    switch (effect) {
      case AppIconVisualEffect.flatMinimal:
        // Google M3 / Flat Minimalist: phẳng, tông màu pastel dịu, sạch thoáng
        fillColor = isDark
            ? effectiveColor.withValues(alpha: op.clamp(0.08, 0.95))
            : effectiveColor.withValues(alpha: (op * 0.65).clamp(0.06, 0.90));
        borderSide = BorderSide(
          color: effectiveColor.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.0,
        );
        shadows = [];

      case AppIconVisualEffect.liquidGlass:
        // Khối 3D kính lỏng phát quang
        fillGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? effectiveColor.withValues(alpha: (op * 1.6).clamp(0.15, 0.95))
                : effectiveColor.withValues(
                    alpha: (op * 1.1).clamp(0.10, 0.90)),
            isDark ? const Color(0xFF1E293B) : Colors.white,
          ],
        );
        borderSide = BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.28) : Colors.white,
          width: 1.6,
        );
        shadows = [
          BoxShadow(
            color: effectiveColor.withValues(alpha: isDark ? 0.35 : 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ];

      case AppIconVisualEffect.neumorphicSoft:
        // Neumorphic dập nổi mềm
        fillColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF3F8);
        borderSide = BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white,
          width: 1.2,
        );
        shadows = [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.45)
                : const Color(0xFFB8C4D6).withValues(alpha: 0.7),
            blurRadius: 7,
            offset: const Offset(3, 3),
          ),
          BoxShadow(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
            blurRadius: 5,
            offset: const Offset(-2, -2),
          ),
        ];

      case AppIconVisualEffect.cyberNeon:
        // Viền Neon phát sáng rực rỡ
        fillColor = (isDark ? const Color(0xFF030712) : const Color(0xFF0F172A))
            .withValues(alpha: 0.90);
        borderSide = BorderSide(color: effectiveColor, width: 2.0);
        shadows = [
          BoxShadow(
            color: effectiveColor.withValues(alpha: 0.65),
            blurRadius: 10,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: effectiveColor.withValues(alpha: 0.35),
            blurRadius: 22,
            spreadRadius: 2,
          ),
        ];

      case AppIconVisualEffect.duotoneGlass:
        // Kính Duotone 2 lớp tương phản
        fillGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            effectiveColor.withValues(alpha: (op * 2.8).clamp(0.2, 0.95)),
            const Color(0xFFEC4899).withValues(alpha: 0.55),
          ],
        );
        borderSide = BorderSide(
          color: Colors.white.withValues(alpha: 0.50),
          width: 1.5,
        );
        shadows = [
          BoxShadow(
            color: effectiveColor.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];

      case AppIconVisualEffect.jewelCrystal:
        // Pha lê đá quý lấp lánh giác cắt
        fillGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.65 : 0.85),
            effectiveColor.withValues(alpha: 0.80),
            effectiveColor.withValues(alpha: 0.35),
            isDark ? const Color(0xFF0F172A) : Colors.white,
          ],
          stops: const [0.0, 0.28, 0.70, 1.0],
        );
        borderSide = BorderSide(
          color: Colors.white.withValues(alpha: 0.75),
          width: 1.8,
        );
        shadows = [
          BoxShadow(
            color: effectiveColor.withValues(alpha: isDark ? 0.55 : 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];

      case AppIconVisualEffect.gradientFlow:
        // Gradient ánh sáng chuyển sắc
        fillGradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            effectiveColor.withValues(alpha: 0.85),
            effectiveColor.withValues(alpha: 0.30),
            isDark ? const Color(0xFF1E293B) : Colors.white,
          ],
        );
        borderSide = BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.30) : Colors.white,
          width: 1.5,
        );
        shadows = [
          BoxShadow(
            color: effectiveColor.withValues(alpha: 0.40),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ];

      case AppIconVisualEffect.outlineMinimal:
        // Viền mảnh thanh lịch Wireframe
        fillColor = Colors.transparent;
        borderSide = BorderSide(
          color: effectiveColor.withValues(alpha: isDark ? 0.85 : 0.75),
          width: 1.8,
        );
        shadows = [
          BoxShadow(
            color: effectiveColor.withValues(alpha: 0.20),
            blurRadius: 6,
          ),
        ];
    }

    final OutlinedBorder finalShape = baseShape.copyWith(side: borderSide);
    return ShapeDecoration(
      shape: finalShape,
      color: fillColor,
      gradient: fillGradient,
      shadows: shadows,
    );
  }

  BorderRadius? getIconBorderRadius(double size) {
    return switch (_iconShape) {
      AppIconShape.circle => BorderRadius.circular(size / 2),
      AppIconShape.squircle => BorderRadius.circular(size * 0.32),
      AppIconShape.roundedSquare => BorderRadius.circular(size * 0.18),
      AppIconShape.teardrop => BorderRadius.only(
          topLeft: Radius.circular(size * 0.45),
          topRight: Radius.circular(size * 0.45),
          bottomRight: Radius.circular(size * 0.45),
          bottomLeft: Radius.circular(size * 0.12),
        ),
      AppIconShape.capsule => BorderRadius.circular(size * 0.5),
      AppIconShape.chamferedOctagon => BorderRadius.circular(size * 0.28),
      _ => BorderRadius.circular(size * 0.25),
    };
  }

  BoxDecoration getCardDecoration({
    required bool isDark,
    double? radius,
    Color? customFill,
    Border? customBorder,
    List<BoxShadow>? customShadows,
  }) {
    final effectiveRadius = radius ?? getCardRadius();
    final primary = primaryColor;
    final effectiveFill = customFill != null
        ? applyWhiteTransparency(customFill, isDark: isDark)
        : getCardFillColor(isDark);

    final glowShadow = getGlowShadows(isDark);

    Border? computeBorder(Border? styleDefault) {
      if (_borderGlowStyle == CardBorderGlowStyle.none) return null;
      if (customBorder != null) return customBorder;
      if (_borderGlowStyle == CardBorderGlowStyle.subtleHairline) {
        return styleDefault;
      }
      return getCardBorder(isDark);
    }

    switch (_uiUxStyle) {
      case AppUiUxStyle.liquidGlass:
        return BoxDecoration(
          color: effectiveFill,
          borderRadius: BorderRadius.circular(effectiveRadius),
          border: computeBorder(
            Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.65),
              width: 1.0,
            ),
          ),
          boxShadow: customShadows ??
              [
                ...glowShadow,
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
        );

      case AppUiUxStyle.neumorphicSoft:
        return BoxDecoration(
          color: customFill != null
              ? applyWhiteTransparency(customFill, isDark: isDark)
              : (isDark ? const Color(0xFF1E2430) : const Color(0xFFEFF3F8)),
          borderRadius: BorderRadius.circular(effectiveRadius),
          border: computeBorder(
            Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.9),
              width: 1.2,
            ),
          ),
          boxShadow: customShadows ??
              [
                ...glowShadow,
                BoxShadow(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white,
                  blurRadius: 10,
                  offset: const Offset(-4, -4),
                ),
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : const Color(0xFFB8C4D6).withValues(alpha: 0.6),
                  blurRadius: 12,
                  offset: const Offset(4, 4),
                ),
              ],
        );

      case AppUiUxStyle.cyberNeon:
        return BoxDecoration(
          color: customFill ??
              (isDark
                  ? const Color(0xFF090D16).withValues(alpha: 0.92)
                  : Colors.white.withValues(alpha: 0.95)),
          borderRadius: BorderRadius.circular(effectiveRadius),
          border: computeBorder(
            Border.all(
              color: primary.withValues(alpha: isDark ? 0.75 : 0.60),
              width: 1.5,
            ),
          ),
          boxShadow: customShadows ??
              [
                ...glowShadow,
                BoxShadow(
                  color: primary.withValues(alpha: isDark ? 0.35 : 0.20),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
        );

      case AppUiUxStyle.cupertinoMinimal:
        return BoxDecoration(
          color: customFill ??
              (isDark ? const Color(0xFF161B26) : Colors.white)
                  .withValues(alpha: _glassOpacity.clamp(0.15, 1.0)),
          borderRadius: BorderRadius.circular(effectiveRadius),
          border: computeBorder(
            Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
              width: 0.6,
            ),
          ),
          boxShadow: customShadows ??
              [
                ...glowShadow,
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
        );

      case AppUiUxStyle.luxuryObsidian:
        const goldColor = Color(0xFFE5A93C);
        return BoxDecoration(
          color: customFill ??
              (isDark ? const Color(0xFF0D0F14) : const Color(0xFFFDFCFA)),
          borderRadius: BorderRadius.circular(effectiveRadius),
          border: computeBorder(
            Border.all(
              color: goldColor.withValues(alpha: isDark ? 0.45 : 0.35),
              width: 1.2,
            ),
          ),
          boxShadow: customShadows ??
              [
                ...glowShadow,
                BoxShadow(
                  color: goldColor.withValues(alpha: isDark ? 0.15 : 0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
        );

      case AppUiUxStyle.retroSynthwave:
        const synthPink = Color(0xFFFF2A85);
        const synthPurple = Color(0xFF8B5CF6);
        return BoxDecoration(
          color: customFill ??
              (isDark
                  ? const Color(0xFF140D26).withValues(alpha: 0.90)
                  : const Color(0xFFFAF5FF)),
          borderRadius: BorderRadius.circular(effectiveRadius),
          border: computeBorder(
            Border.all(
              color: synthPink.withValues(alpha: isDark ? 0.65 : 0.45),
              width: 1.4,
            ),
          ),
          boxShadow: customShadows ??
              [
                ...glowShadow,
                BoxShadow(
                  color: synthPurple.withValues(alpha: isDark ? 0.30 : 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: synthPink.withValues(alpha: isDark ? 0.20 : 0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
        );

      case AppUiUxStyle.auroraBorealis:
        const auroraEmerald = Color(0xFF10B981);
        const auroraTeal = Color(0xFF06B6D4);
        return BoxDecoration(
          color: customFill ??
              (isDark
                  ? const Color(0xFF061A19).withValues(alpha: 0.88)
                  : const Color(0xFFF0FDF4)),
          borderRadius: BorderRadius.circular(effectiveRadius),
          border: computeBorder(
            Border.all(
              color: auroraEmerald.withValues(alpha: isDark ? 0.55 : 0.40),
              width: 1.3,
            ),
          ),
          boxShadow: customShadows ??
              [
                ...glowShadow,
                BoxShadow(
                  color: auroraTeal.withValues(alpha: isDark ? 0.25 : 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
        );

      case AppUiUxStyle.googleMinimal:
        final m3Tonal = isDark
            ? Color.alphaBlend(
                primary.withValues(alpha: 0.08), const Color(0xFF1E222A))
            : Color.alphaBlend(
                primary.withValues(alpha: 0.06), const Color(0xFFF2F5FA));
        return BoxDecoration(
          color: customFill != null
              ? applyWhiteTransparency(customFill, isDark: isDark)
              : m3Tonal,
          borderRadius: BorderRadius.circular(effectiveRadius),
          border: computeBorder(
            Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : primary.withValues(alpha: 0.14),
              width: 0.8,
            ),
          ),
          boxShadow: customShadows ??
              [
                ...glowShadow,
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
        );

      case AppUiUxStyle.colorOsAquamorphic:
        const aquaColor = Color(0xFF00C4B4);
        final aquaFill = isDark
            ? Color.alphaBlend(
                aquaColor.withValues(alpha: 0.10), const Color(0xFF0C1924))
            : Color.alphaBlend(
                aquaColor.withValues(alpha: 0.08), const Color(0xFFF2FBF9));
        return BoxDecoration(
          color: customFill != null
              ? applyWhiteTransparency(customFill, isDark: isDark)
              : aquaFill,
          borderRadius: BorderRadius.circular(effectiveRadius + 4),
          border: computeBorder(
            Border.all(
              color: isDark
                  ? aquaColor.withValues(alpha: 0.28)
                  : aquaColor.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          boxShadow: customShadows ??
              [
                ...glowShadow,
                BoxShadow(
                  color: aquaColor.withValues(alpha: isDark ? 0.22 : 0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
        );

      case AppUiUxStyle.hyperOsAlive:
        const hyperBlue = Color(0xFF0070F3);
        final hyperFill = isDark
            ? Color.alphaBlend(
                hyperBlue.withValues(alpha: 0.12), const Color(0xFF0E1118))
            : Color.alphaBlend(
                hyperBlue.withValues(alpha: 0.06), const Color(0xFFF4F7FC));
        return BoxDecoration(
          color: customFill != null
              ? applyWhiteTransparency(customFill, isDark: isDark)
              : hyperFill,
          borderRadius: BorderRadius.circular(effectiveRadius),
          border: computeBorder(
            Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : hyperBlue.withValues(alpha: 0.30),
              width: 0.9,
            ),
          ),
          boxShadow: customShadows ??
              [
                ...glowShadow,
                BoxShadow(
                  color: hyperBlue.withValues(alpha: isDark ? 0.30 : 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ],
        );

      case AppUiUxStyle.ledgerEditorial:
      case AppUiUxStyle.softPaper:
      case AppUiUxStyle.industrialUtility:
      case AppUiUxStyle.organicClay:
      case AppUiUxStyle.einkFocus:
      case AppUiUxStyle.artDecoFinance:
        final treatment = switch (_uiUxStyle) {
          AppUiUxStyle.ledgerEditorial => (
              fill: isDark ? const Color(0xFF20252B) : const Color(0xFFFCFAF5),
              edge: isDark ? const Color(0xFFB7A790) : const Color(0xFF9E8D78),
              width: 0.8,
              shadow: 0.04,
              blur: 5.0,
              lift: 1.0,
              radius: -4.0
            ),
          AppUiUxStyle.softPaper => (
              fill: isDark ? const Color(0xFF302923) : const Color(0xFFFFF9EF),
              edge: isDark ? const Color(0xFF6F5A48) : const Color(0xFFE7D9C6),
              width: 0.6,
              shadow: 0.08,
              blur: 14.0,
              lift: 4.0,
              radius: 2.0
            ),
          AppUiUxStyle.industrialUtility => (
              fill: isDark ? const Color(0xFF20262A) : const Color(0xFFF0F2F2),
              edge: isDark ? const Color(0xFF7B898F) : const Color(0xFF88949A),
              width: 1.2,
              shadow: 0.02,
              blur: 2.0,
              lift: 0.0,
              radius: -3.0
            ),
          AppUiUxStyle.organicClay => (
              fill: isDark ? const Color(0xFF263329) : const Color(0xFFF5EBDD),
              edge: isDark ? const Color(0xFF79967B) : const Color(0xFFD3B99C),
              width: 0.7,
              shadow: 0.15,
              blur: 20.0,
              lift: 8.0,
              radius: 6.0
            ),
          AppUiUxStyle.einkFocus => (
              fill: isDark ? const Color(0xFF111111) : Colors.white,
              edge: isDark ? Colors.white : const Color(0xFF262626),
              width: 1.0,
              shadow: 0.0,
              blur: 0.0,
              lift: 0.0,
              radius: -5.0
            ),
          AppUiUxStyle.artDecoFinance => (
              fill: isDark ? const Color(0xFF19212C) : const Color(0xFFFAF7F0),
              edge: const Color(0xFFB9924A),
              width: 1.3,
              shadow: 0.14,
              blur: 14.0,
              lift: 4.0,
              radius: -2.0
            ),
          _ => throw StateError('Unknown editorial style'),
        };
        final surface = customFill == null
            ? treatment.fill.withValues(alpha: _glassOpacity)
            : applyWhiteTransparency(customFill, isDark: isDark);
        final radiusValue =
            (effectiveRadius + treatment.radius).clamp(4.0, 48.0);
        return BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(radiusValue),
          border: computeBorder(Border.all(
            color: treatment.edge.withValues(alpha: isDark ? 0.75 : 0.65),
            width: treatment.width,
          )),
          boxShadow: customShadows ??
              [
                ...glowShadow,
                if (treatment.shadow > 0)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: treatment.shadow),
                    blurRadius: treatment.blur,
                    offset: Offset(0, treatment.lift),
                  ),
              ],
        );
    }
  }

  Future<void> resetBackgroundSettings() async {
    _useCustomBgGradient = false;
    _customBgGradientAngle = 0;
    _backgroundTintOpacity = 0.85;
    _backgroundBlurSigma = 18.0;
    _customBgGradientColors = [
      const Color(0xFF0F172A),
      const Color(0xFF1E1B4B),
      const Color(0xFF312E81),
    ];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customBgGradientKey);
  }

  Future<void> resetGlassSettings() async {
    _glassOpacity = 0.88;
    _glassBlur = 25.0;
    _widgetCardStyle = AppWidgetCardStyle.liquidGlassCard;
    _systemWideLiquidGlass = true;
    _liquidGlassSpecularHighlight = true;
    _liquidGlassCausticRefraction = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_glassOpacityKey);
    await prefs.remove(_glassBlurKey);
    await prefs.remove(_widgetCardStyleKey);
    await prefs.remove(_systemWideLiquidGlassKey);
    await prefs.remove(_liquidGlassSpecularHighlightKey);
    await prefs.remove(_liquidGlassCausticRefractionKey);
  }

  Future<void> resetCardSettings() async {
    _globalCardSkin = AppCardSkinStyle.brandClassic;
    _walletViewStyle = AppWalletViewStyle.webCards;
    _borderGlowStyle = CardBorderGlowStyle.subtleHairline;
    _widgetBorderWidth = 0.8;
    _customCardCornerRadius = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_globalCardSkinKey);
    await prefs.remove(_walletViewStyleKey);
    await prefs.remove(_borderGlowKey);
    await prefs.remove(_widgetBorderWidthKey);
    await prefs.remove(_customCardCornerRadiusKey);
  }

  Future<void> resetDockSettings() async {
    _dockNavStyle = AppDockNavStyle.floatingIsland;
    _dockIconStyle = AppDockIconStyle.modernLucide;
    _dockLabelStyle = AppDockLabelStyle.always;
    _dockHeightScale = 1.0;
    _dockOpacity = 0.38;
    _dockBlur = 28.0;
    _dockActiveColor = null;
    _dockInactiveColor = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dockNavKey);
    await prefs.remove(_dockIconStyleKey);
    await prefs.remove(_dockLabelStyleKey);
    await prefs.remove(_dockHeightScaleKey);
    await prefs.remove(_dockOpacityKey);
    await prefs.remove(_dockBlurKey);
    await prefs.remove(_dockActiveColorKey);
    await prefs.remove(_dockInactiveColorKey);
  }

  Future<void> resetButtonSettings() async {
    _buttonColorMode = AppButtonColorMode.paletteSync;
    _customButtonColor = null;
    _buttonVisualKind = AppButtonStyle.modernPill;
    _buttonShape = AppButtonShape.pill;
    _customButtonCornerRadius = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_buttonColorModeKey);
    await prefs.remove(_customButtonColorKey);
    await prefs.remove(_buttonVisualKindKey);
    await prefs.remove(_buttonShapeKey);
    await prefs.remove(_customButtonCornerRadiusKey);
  }

  Future<void> resetIconSettings() async {
    _iconStyle = AppIconStyle.round;
    _iconShape = AppIconShape.circle;
    _iconVisualEffect = AppIconVisualEffect.liquidGlass;
    _categoryIconStyle = AppCategoryIconStyle.modernSquircle;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_iconStyleKey);
    await prefs.remove(_iconShapeKey);
    await prefs.remove(_iconVisualEffectKey);
    await prefs.remove(_categoryIconStyleKey);
  }

  Future<void> resetTypographySettings() async {
    _fontFamily = AppFontFamily.plusJakartaSans;
    _fontScale = 1.0;
    _currencyFormat = AppCurrencyFormat.symbolSuffix;
    _chartCurveStyle = AppChartCurveStyle.smoothSpline;
    _heroCardStyle = AppHeroCardStyle.zenvestGlassDeck;
    _heroBalanceSize = AppHeroBalanceSize.standard;
    _chartHeightScale = 1.0;
    _chartShowAreaFill = true;
    _chartShowGridLines = true;
    _chartSmoothness = 0.5;
    _pageVerticalGap = 12.0;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fontFamilyKey);
    await prefs.remove(_fontScaleKey);
    await prefs.remove(_currencyKey);
    await prefs.remove(_chartCurveStyleKey);
    await prefs.remove(_heroCardStyleKey);
    await prefs.remove(_heroBalanceSizeKey);
    await prefs.remove(_chartHeightScaleKey);
    await prefs.remove(_chartShowAreaFillKey);
    await prefs.remove(_chartShowGridLinesKey);
    await prefs.remove(_chartSmoothnessKey);
    await prefs.remove(_pageVerticalGapKey);
  }

  Future<void> resetToDefault() async {
    _palette = AppColorPalette.slateMinimal;
    _ambientBlur = AmbientBlurPreset.obsidianSlate;
    _globalDensity = CardDensity.standard;
    _dashboardDensity = CardDensity.standard;
    _transactionDensity = CardDensity.compact;
    _surfaceStyle = CardSurfaceStyle.solidModern;
    _cornerStyle = CardCornerStyle.rounded;
    _shadowIntensity = CardShadowIntensity.soft;
    _showAiInsight = true;
    _showQuickLog = true;
    _glassOpacity = 1.0;
    _glassBlur = 0.0;
    _pageHorizontalMargin = 16.0;
    _appBarOpacity = 1.0;
    _appBarBlur = 0.0;
    _pinHeader = true;
    _walletViewStyle = AppWalletViewStyle.webCards;
    _buttonShape = AppButtonShape.rounded;
    _iconStyle = AppIconStyle.round;
    _iconShape = AppIconShape.squircle;
    _iconVisualEffect = AppIconVisualEffect.flatMinimal;
    _buttonSize = AppButtonSize.standard;
    _fontScale = 1.0;
    _uiUxStyle = AppUiUxStyle.ledgerEditorial;
    _gradientVibrancy = 1.0;
    _fontFamily = AppFontFamily.beVietnamPro;
    _borderGlowStyle = CardBorderGlowStyle.subtleHairline;
    _motionDynamics = AppMotionDynamics.smoothGentle;
    _hapticEnabled = true;
    _privacyShieldDefault = false;
    _privacyStyle = AppPrivacyStyle.dots;
    _isPrivacyShieldActive = false;
    _dashboardOrder = List.from(defaultDashboardOrder);
    _disabledDashboardModules.clear();
    _currencyFormat = AppCurrencyFormat.symbolSuffix;
    _dockNavStyle = AppDockNavStyle.floatingIsland;
    _ambientIntensity = 0.65;
    _particleSparkles = true;
    _budgetStyle = AppBudgetStyle.liquidBar;
    _goalStyle = AppGoalStyle.treasureChest;
    _hapticIntensity = AppHapticIntensity.crisp;
    _transactionSound = AppTransactionSound.ting;
    _transactionListStyle = AppTransactionListStyle.timelineRail;
    _globalCardSkin = AppCardSkinStyle.brandClassic;
    _walletCardSkins.clear();
    _customCardGradientColors = [
      const Color(0xFF6366F1),
      const Color(0xFFA855F7),
      const Color(0xFFEC4899)
    ];
    _heroCardTint = AppHeroCardTint.paletteSync;
    _statsCardTint = AppStatsCardTint.paletteSync;
    _expenseColor = const Color(0xFFEF4444);
    _incomeColor = const Color(0xFF10B981);
    _transferColor = const Color(0xFF3B82F6);
    _budgetSafeColor = const Color(0xFF10B981);
    _budgetWarningColor = const Color(0xFFF59E0B);
    _budgetDangerColor = const Color(0xFFEF4444);
    _customBgGradientColors = [
      const Color(0xFF0F172A),
      const Color(0xFF1E1B4B),
      const Color(0xFF312E81)
    ];
    _customBgGradientAngle = 0;
    _dockLabelStyle = AppDockLabelStyle.always;
    _heroCardStyle = AppHeroCardStyle.zenvestGlassDeck;
    _heroBalanceSize = AppHeroBalanceSize.standard;
    _avatarGlowStyle = AppAvatarGlowStyle.goldVip;
    _membershipTier = AppMembershipTierBadge.diamondCrown;
    _aiBubbleStyle = AppAiBubbleStyle.duotoneGlass;
    _aiAvatarIcon = AppAiAvatarIcon.energyOrb;
    _chartCurveStyle = AppChartCurveStyle.smoothSpline;
    _chartAreaFill = AppChartAreaFill.neonGlow;
    _chartColorway = AppChartColorway.paletteSync;
    _seasonalTheme = AppSeasonalTheme.none;
    _systemIconPack = AppSystemIconPack.solarCurved;
    _tabSelectStyle = AppTabSelectStyle.pillHighlight;
    _buttonVisualKind = AppButtonStyle.modernPill;
    _buttonColorMode = AppButtonColorMode.paletteSync;
    _customButtonColor = null;
    _dockIconStyle = AppDockIconStyle.modernLucide;
    _widgetCardStyle = AppWidgetCardStyle.liquidGlassCard;
    _categoryIconStyle = AppCategoryIconStyle.modernSquircle;
    _appBarScrollBehavior = AppAppBarScrollBehavior.pinned;
    _highRefreshRate120Hz = true;
    _iconBgColorMode = AppIconBgColorMode.categoryOriginal;
    _iconGlyphColorMode = AppIconGlyphColorMode.autoContrast;
    _iconBgOpacity = 0.22;
    _widgetBorderWidth = 0.8;
    _customCardCornerRadius = null;
    _customButtonCornerRadius = null;
    _pageVerticalGap = 12.0;
    _dockHeightScale = 1.0;
    _dockOpacity = 0.38;
    _dockBlur = 28.0;
    _dockActiveColor = null;
    _dockInactiveColor = null;
    _chartHeightScale = 1.0;
    _chartShowAreaFill = true;
    _chartShowGridLines = true;
    _chartSmoothness = 0.5;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_widgetBorderWidthKey);
    await prefs.remove(_customCardCornerRadiusKey);
    await prefs.remove(_customButtonCornerRadiusKey);
    await prefs.remove(_pageVerticalGapKey);
    await prefs.remove(_dockHeightScaleKey);
    await prefs.remove(_chartHeightScaleKey);
    await prefs.remove(_chartShowAreaFillKey);
    await prefs.remove(_chartShowGridLinesKey);
    await prefs.remove(_chartSmoothnessKey);
    await prefs.remove(_paletteKey);
    await prefs.remove(_ambientBlurKey);
    await prefs.remove(_densityKey);
    await prefs.remove(_dashDensityKey);
    await prefs.remove(_txDensityKey);
    await prefs.remove(_surfaceKey);
    await prefs.remove(_cornerKey);
    await prefs.remove(_shadowKey);
    await prefs.remove(_seasonalThemeKey);
    await prefs.remove(_systemIconPackKey);
    await prefs.remove(_tabSelectStyleKey);
    await prefs.remove(_buttonVisualKindKey);
    await prefs.remove(_buttonColorModeKey);
    await prefs.remove(_customButtonColorKey);
    await prefs.remove(_dockIconStyleKey);
    await prefs.remove(_widgetCardStyleKey);
    await prefs.remove(_categoryIconStyleKey);
    await prefs.remove(_appBarScrollBehaviorKey);
    await prefs.remove(_highRefreshRate120HzKey);
    await prefs.remove(_iconBgColorModeKey);
    await prefs.remove(_iconGlyphColorModeKey);
    await prefs.remove(_iconBgOpacityKey);
    await prefs.remove(_showAiInsightKey);
    await prefs.remove(_showQuickLogKey);
    await prefs.remove(_glassOpacityKey);
    await prefs.remove(_glassBlurKey);
    await prefs.remove(_buttonShapeKey);
    await prefs.remove(_iconStyleKey);
    await prefs.remove(_iconShapeKey);
    await prefs.remove(_iconVisualEffectKey);
    await prefs.remove(_buttonSizeKey);
    await prefs.remove(_fontScaleKey);
    await prefs.remove(_uiUxStyleKey);
    await prefs.remove(_gradientVibrancyKey);
    await prefs.remove(_fontFamilyKey);
    await prefs.remove(_borderGlowKey);
    await prefs.remove(_motionKey);
    await prefs.remove(_hapticKey);
    await prefs.remove(_privacyKey);
    await prefs.remove(_privacyStyleKey);
    await prefs.remove(_dashboardOrderKey);
    await prefs.remove(_dashboardDisabledKey);
    await prefs.remove(_currencyKey);
    await prefs.remove(_dockNavKey);
    await prefs.remove(_dockOpacityKey);
    await prefs.remove(_dockBlurKey);
    await prefs.remove(_dockActiveColorKey);
    await prefs.remove(_dockInactiveColorKey);
    await prefs.remove(_wallpaperKey);
    await prefs.remove(_ambientIntensityKey);
    await prefs.remove(_particleSparklesKey);
    await prefs.remove(_budgetStyleKey);
    await prefs.remove(_goalStyleKey);
    await prefs.remove(_hapticIntensityKey);
    await prefs.remove(_transactionSoundKey);
    await prefs.remove(_transactionListStyleKey);
    await prefs.remove(_pageHorizontalMarginKey);
    await prefs.remove(_globalCardSkinKey);
    await prefs.remove(_walletCardSkinsKey);
    await prefs.remove(_customCardGradientKey);
    await prefs.remove(_heroCardTintKey);
    await prefs.remove(_statsCardTintKey);
    await prefs.remove(_expenseColorKey);
    await prefs.remove(_incomeColorKey);
    await prefs.remove(_transferColorKey);
    await prefs.remove(_budgetSafeColorKey);
    await prefs.remove(_budgetWarningColorKey);
    await prefs.remove(_budgetDangerColorKey);
    await prefs.remove(_customBgGradientKey);
    await prefs.remove(_customBgGradientAngleKey);
    await prefs.remove(_dockLabelStyleKey);
    await prefs.remove(_heroCardStyleKey);
    await prefs.remove(_heroBalanceSizeKey);
    await prefs.remove(_avatarGlowStyleKey);
    await prefs.remove(_membershipTierKey);
    await prefs.remove(_aiBubbleStyleKey);
    await prefs.remove(_aiAvatarIconKey);
    await prefs.remove(_chartCurveStyleKey);
    await prefs.remove(_chartAreaFillKey);
    await prefs.remove(_chartColorwayKey);
    await prefs.remove(_appBarOpacityKey);
    await prefs.remove(_appBarBlurKey);
    _lockedComponents.clear();
    await prefs.remove(_lockedComponentsKey);
  }
}
