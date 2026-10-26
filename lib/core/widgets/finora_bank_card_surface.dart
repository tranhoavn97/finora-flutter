import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../state/theme_studio_controller.dart';
import 'bank_icon.dart';
import 'finora_motion.dart';

/// Renders realistic physical materials, textures, EMV chip, and contactless icons
/// for Finora Visa and Banking cards.
class FinoraBankCardSurface extends StatelessWidget {
  final AppCardSkinStyle skin;
  final List<Color> gradientColors;
  final double borderRadius;
  final double? width;
  final double? height;
  final String? bankCode;
  final String? bankName;
  final String? cardName;
  final String? accountNumber;
  final String? cardHolder;
  final String? expiryDate;
  final String? cardNetwork; // 'visa', 'mastercard', 'napas'
  final Widget? topTrailing;
  final Widget? bottomContent;
  final Widget? child;
  final bool isDark;
  final bool preserveBankColors;
  final VoidCallback? onTap;

  const FinoraBankCardSurface({
    super.key,
    required this.skin,
    required this.gradientColors,
    this.borderRadius = 22.0,
    this.width,
    this.height,
    this.bankCode,
    this.bankName,
    this.cardName,
    this.accountNumber,
    this.cardHolder,
    this.expiryDate,
    this.cardNetwork,
    this.topTrailing,
    this.bottomContent,
    this.child,
    this.isDark = true,
    this.preserveBankColors = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: GestureDetector(
        onTap: onTap,
        child: FinoraShimmerGlint(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            width: width ?? double.infinity,
            height: height ?? 200.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: _buildBaseGradient(),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.20),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
                if (skin == AppCardSkinStyle.cyberNeon || skin == AppCardSkinStyle.cyberGlass)
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.28),
                    blurRadius: 22,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  )
                else if (skin == AppCardSkinStyle.goldMetallic)
                  BoxShadow(
                    color: const Color(0xFFE5A93C).withValues(alpha: 0.32),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
              ],
              border: _buildCardBorder(),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Physical Material Texture Layer with Beveled Edge
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CardMaterialTexturePainter(
                      skin: skin,
                      borderRadius: borderRadius,
                    ),
                  ),
                ),

                // 2. Specular Light Sheen Overlay
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: const Alignment(-0.8, -1.0),
                          end: const Alignment(0.8, 1.0),
                          colors: [
                            Colors.white.withValues(
                              alpha: skin == AppCardSkinStyle.whiteCeramic
                                  ? 0.35
                                  : (skin == AppCardSkinStyle.titaniumFrost ? 0.22 : 0.14),
                            ),
                            Colors.white.withValues(alpha: 0.0),
                            Colors.black.withValues(
                              alpha: skin == AppCardSkinStyle.carbonObsidian ? 0.35 : 0.08,
                            ),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Card Content & Details Layer
                if (child != null)
                  child!
                else
                  _buildDefaultCardContent(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Gradient _buildBaseGradient() {
    if (preserveBankColors && gradientColors.isNotEmpty) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      );
    }
    if (!preserveBankColors && skin == AppCardSkinStyle.brandClassic && gradientColors.isNotEmpty) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      );
    }
    switch (skin) {
      case AppCardSkinStyle.carbonObsidian:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B1E24), Color(0xFF111317), Color(0xFF090A0D)],
        );
      case AppCardSkinStyle.whiteCeramic:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
        );
      case AppCardSkinStyle.titaniumFrost:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF475569), Color(0xFF64748B), Color(0xFF334155)],
        );
      case AppCardSkinStyle.cyberGlass:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A192F), Color(0xFF0F2B48), Color(0xFF08182B)],
        );
      case AppCardSkinStyle.goldMetallic:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8C6D23), Color(0xFFE5B94C), Color(0xFF7A5816)],
        );
      case AppCardSkinStyle.diamondHologram:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFDB2777), Color(0xFF06B6D4)],
        );
      case AppCardSkinStyle.emeraldJade:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064E3B), Color(0xFF059669), Color(0xFF022C22)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF005FEA), Color(0xFF00C2FA)],
        );
    }
  }

  Border? _buildCardBorder() {
    switch (skin) {
      case AppCardSkinStyle.carbonObsidian:
        return Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.65), // 24K Gold Hairline
          width: 1.0,
        );
      case AppCardSkinStyle.whiteCeramic:
        return Border.all(
          color: const Color(0xFFCBD5E1).withValues(alpha: 0.8),
          width: 0.9,
        );
      case AppCardSkinStyle.cyberNeon:
      case AppCardSkinStyle.cyberGlass:
        return Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.75), // Cyber Neon
          width: 1.2,
        );
      case AppCardSkinStyle.goldMetallic:
        return Border.all(
          color: const Color(0xFFFDE047).withValues(alpha: 0.8),
          width: 1.2,
        );
      case AppCardSkinStyle.titaniumFrost:
        return Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.0,
        );
      default:
        return Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.0,
        );
    }
  }

  Widget _buildDefaultCardContent(BuildContext context) {
    final isLightSkin = skin == AppCardSkinStyle.whiteCeramic;
    final primaryTextColor = isLightSkin ? const Color(0xFF0F172A) : Colors.white;
    final secondaryTextColor = isLightSkin
        ? const Color(0xFF475569)
        : Colors.white.withValues(alpha: 0.75);

    final cleanName = cardName ?? bankName ?? 'FINORA CARD';
    final cleanAccount = accountNumber != null && accountNumber!.length >= 4
        ? '•••• •••• •••• ${accountNumber!.substring(accountNumber!.length - 4)}'
        : '•••• •••• •••• 8888';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Bank Icon, Name & Top Trailing Action
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (bankCode != null || bankName != null)
                BankIcon(
                  bankCode: bankCode,
                  bankName: bankName ?? cleanName,
                  size: 32,
                )
              else
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isLightSkin ? Colors.black12 : Colors.white12,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.credit_card_rounded,
                    color: primaryTextColor,
                    size: 18,
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cleanName.toUpperCase(),
                      style: TextStyle(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getSkinBadgeTitle(),
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              if (topTrailing != null) topTrailing!,
            ],
          ),

          // Middle Row: 3D EMV Chip & Contactless Symbol
          Row(
            children: [
              _buildEmvChip(),
              const SizedBox(width: 12),
              _buildContactlessWave(isLightSkin),
            ],
          ),

          // Bottom Content or Standard Card Number & Network Logo
          if (bottomContent != null)
            bottomContent!
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cleanAccount,
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (cardHolder != null || expiryDate != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (cardHolder != null)
                              Flexible(
                                child: Text(
                                  cardHolder!.toUpperCase(),
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (cardHolder != null && expiryDate != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '•',
                                  style: TextStyle(color: secondaryTextColor, fontSize: 8),
                                ),
                              ),
                            if (expiryDate != null)
                              Text(
                                expiryDate!,
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                _buildCardNetworkLogo(isLightSkin),
              ],
            ),
        ],
      ),
    );
  }

  String _getSkinBadgeTitle() {
    switch (skin) {
      case AppCardSkinStyle.carbonObsidian:
        return 'VIP CENTURION • CARBON';
      case AppCardSkinStyle.whiteCeramic:
        return 'PURE CERAMIC • PLATINUM';
      case AppCardSkinStyle.titaniumFrost:
        return 'AEROSPACE TITANIUM';
      case AppCardSkinStyle.cyberGlass:
      case AppCardSkinStyle.cyberNeon:
        return 'CYBERPUNK PCB • NEON';
      case AppCardSkinStyle.goldMetallic:
        return '24K ROYAL GOLD BULLION';
      case AppCardSkinStyle.diamondHologram:
        return 'HOLOGRAPHIC PRISM';
      case AppCardSkinStyle.emeraldJade:
        return 'IMPERIAL EMERALD JADE';
      case AppCardSkinStyle.roseGoldRuby:
        return 'ROSE GOLD & RUBY';
      default:
        return 'FINORA SIGNATURE';
    }
  }

  static Widget buildEmvChip({
    AppCardSkinStyle? skinStyle,
    double width = 38,
    double height = 28,
  }) {
    Color baseGold = const Color(0xFFD4AF37);
    Color highlightGold = const Color(0xFFF7E08A);
    Color lineDark = const Color(0xFF9A7B1C);

    if (skinStyle == AppCardSkinStyle.titaniumFrost || skinStyle == AppCardSkinStyle.whiteCeramic) {
      baseGold = const Color(0xFF94A3B8);
      highlightGold = const Color(0xFFE2E8F0);
      lineDark = const Color(0xFF475569);
    } else if (skinStyle == AppCardSkinStyle.cyberNeon || skinStyle == AppCardSkinStyle.cyberGlass) {
      baseGold = const Color(0xFF00E5FF);
      highlightGold = const Color(0xFFE0F7FA);
      lineDark = const Color(0xFF00838F);
    }

    final chipRadius = math.max(3.0, height * 0.21);
    final centerLineWidth = math.max(6.0, width * 0.36);
    final centerLineHeight = math.max(6.0, height * 0.35);
    final coreCircleSize = math.max(4.0, height * 0.28);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(chipRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [highlightGold, baseGold, highlightGold],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 3,
            offset: const Offset(0, 1.5),
          ),
        ],
        border: Border.all(color: lineDark.withValues(alpha: 0.6), width: 0.8),
      ),
      child: Stack(
        children: [
          // Middle contact lines pattern
          Center(
            child: Container(
              width: centerLineWidth,
              height: height,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: lineDark.withValues(alpha: 0.7), width: 0.8),
                  right: BorderSide(color: lineDark.withValues(alpha: 0.7), width: 0.8),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              height: centerLineHeight,
              width: width,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: lineDark.withValues(alpha: 0.7), width: 0.8),
                  bottom: BorderSide(color: lineDark.withValues(alpha: 0.7), width: 0.8),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: coreCircleSize,
              height: coreCircleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: baseGold,
                border: Border.all(color: lineDark.withValues(alpha: 0.8), width: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildContactlessSymbol({
    double width = 16,
    double height = 16,
    Color color = Colors.white70,
  }) {
    return Transform.rotate(
      angle: 1.57079632679, // 90 degrees
      child: Icon(
        Icons.wifi_rounded,
        size: width,
        color: color,
      ),
    );
  }

  Widget _buildEmvChip() {
    return buildEmvChip(skinStyle: skin, width: 38, height: 28);
  }

  Widget _buildContactlessWave(bool isLightSkin) {
    final color = isLightSkin ? const Color(0xFF475569) : Colors.white.withValues(alpha: 0.65);
    return buildContactlessSymbol(width: 18, height: 18, color: color);
  }

  Widget _buildCardNetworkLogo(bool isLightSkin) {
    final net = (cardNetwork ?? 'visa').toLowerCase();

    if (net.contains('master')) {
      return SizedBox(
        width: 44,
        height: 26,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 4,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEB001B),
                ),
              ),
            ),
            Positioned(
              right: 4,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF79E1B).withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (net.contains('napas')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isLightSkin ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'napas',
          style: TextStyle(
            color: isLightSkin ? Colors.white : const Color(0xFF005FEA),
            fontWeight: FontWeight.w900,
            fontSize: 10,
            letterSpacing: -0.5,
          ),
        ),
      );
    }

    // Default: Premium VISA badge
    return Text(
      'VISA',
      style: TextStyle(
        color: isLightSkin ? const Color(0xFF1E3A8A) : Colors.white,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        fontSize: 20,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// Custom painter for physical card materials
class _CardMaterialTexturePainter extends CustomPainter {
  final AppCardSkinStyle skin;
  final double borderRadius;

  const _CardMaterialTexturePainter({
    required this.skin,
    this.borderRadius = 22.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (skin) {
      case AppCardSkinStyle.carbonObsidian:
        _paintCarbonWeave(canvas, size);
        break;
      case AppCardSkinStyle.cyberGlass:
      case AppCardSkinStyle.cyberNeon:
        _paintCyberCircuits(canvas, size);
        break;
      case AppCardSkinStyle.titaniumFrost:
        _paintBrushedTitanium(canvas, size);
        break;
      case AppCardSkinStyle.goldMetallic:
        _paintGoldMetallic(canvas, size);
        break;
      case AppCardSkinStyle.diamondHologram:
        _paintDiamondHologram(canvas, size);
        break;
      case AppCardSkinStyle.emeraldJade:
        _paintEmeraldMarble(canvas, size);
        break;
      default:
        break;
    }

    // Always paint beveled specular edge for 3D realism
    _paintBeveledSpecularEdge(canvas, size);
  }

  /// 3D Beveled Glass Specular Edge Highlights
  void _paintBeveledSpecularEdge(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0.7, 0.7, size.width - 1.4, size.height - 1.4);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Top-Left Light Specular Highlight
    final lightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.38),
          Colors.white.withValues(alpha: 0.08),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.30),
        ],
        stops: const [0.0, 0.25, 0.65, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, lightPaint);
  }

  void _paintCarbonWeave(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final crossPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.40)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const step = 6.0;
    // Draw 45 degree diagonal woven lines
    for (double i = -size.height; i < size.width + size.height; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), linePaint);
    }
    // Draw cross -45 degree lines for carbon twill weave
    for (double i = 0; i < size.width + size.height * 2; i += step * 2) {
      canvas.drawLine(Offset(i, 0), Offset(i - size.height, size.height), crossPaint);
    }

    // Inner 24K gold geometric accent lines
    final goldPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.28)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
        Radius.circular(math.max(8, borderRadius - 6)),
      ),
      goldPaint,
    );
  }

  void _paintGoldMetallic(Canvas canvas, Size size) {
    // 1. Guilloche Micro-Waves Pattern
    final wavePaint = Paint()
      ..color = const Color(0xFFFDE047).withValues(alpha: 0.09)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    for (int wave = 0; wave < 6; wave++) {
      final path = Path();
      final phase = wave * 0.45;
      final yBase = (size.height / 7) * (wave + 1);

      path.moveTo(0, yBase);
      for (double x = 0; x <= size.width; x += 12) {
        final y = yBase + math.sin((x / size.width) * 4 * math.pi + phase) * 8;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, wavePaint);
    }

    // 2. 24K Radial Sunburst Luster (Ánh kim vàng 24K)
    final lusterPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.4, -0.6),
        radius: 1.1,
        colors: [
          const Color(0xFFFFFBEB).withValues(alpha: 0.25),
          const Color(0xFFFBBF24).withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), lusterPaint);

    // 3. Double Gold Filigree Border
    final goldBorderPaint = Paint()
      ..color = const Color(0xFFFDE047).withValues(alpha: 0.22)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(9, 9, size.width - 18, size.height - 18),
        Radius.circular(math.max(8, borderRadius - 6)),
      ),
      goldBorderPaint,
    );
  }

  void _paintCyberCircuits(Canvas canvas, Size size) {
    final tracePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.24)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    // Path 1
    final path1 = Path()
      ..moveTo(size.width * 0.4, 0)
      ..lineTo(size.width * 0.4, 40)
      ..lineTo(size.width * 0.55, 65)
      ..lineTo(size.width, 65);
    canvas.drawPath(path1, tracePaint);
    canvas.drawCircle(Offset(size.width * 0.55, 65), 2.5, dotPaint);

    // Path 2
    final path2 = Path()
      ..moveTo(0, size.height * 0.7)
      ..lineTo(60, size.height * 0.7)
      ..lineTo(100, size.height * 0.85)
      ..lineTo(size.width * 0.8, size.height * 0.85);
    canvas.drawPath(path2, tracePaint);
    canvas.drawCircle(Offset(60, size.height * 0.7), 2.5, dotPaint);
    canvas.drawCircle(Offset(100, size.height * 0.85), 2.5, dotPaint);

    // Path 3 (Corner accent)
    final path3 = Path()
      ..moveTo(size.width - 30, size.height)
      ..lineTo(size.width - 30, size.height - 40)
      ..lineTo(size.width, size.height - 70);
    canvas.drawPath(path3, tracePaint);
  }

  void _paintBrushedTitanium(Canvas canvas, Size size) {
    final brushPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    // Ultra fine horizontal hairline strokes
    for (double y = 2; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), brushPaint);
    }

    // Diagonal specular beam
    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.35, 0.5, 0.65],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), beamPaint);
  }

  void _paintDiamondHologram(Canvas canvas, Size size) {
    final holoPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFEC4899).withValues(alpha: 0.18),
          const Color(0xFF06B6D4).withValues(alpha: 0.18),
          const Color(0xFFFBBF24).withValues(alpha: 0.18),
          const Color(0xFF8B5CF6).withValues(alpha: 0.18),
        ],
        stops: const [0.0, 0.33, 0.66, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), holoPaint);
  }

  void _paintEmeraldMarble(Canvas canvas, Size size) {
    final goldVeinPaint = Paint()
      ..color = const Color(0xFFFDE047).withValues(alpha: 0.14)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.1, size.width * 0.6, size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.7, size.width, size.height * 0.5);
    canvas.drawPath(path, goldVeinPaint);
  }

  @override
  bool shouldRepaint(covariant _CardMaterialTexturePainter oldDelegate) =>
      oldDelegate.skin != skin || oldDelegate.borderRadius != borderRadius;
}
