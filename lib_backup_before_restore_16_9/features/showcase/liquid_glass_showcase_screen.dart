import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/liquid_glass/liquid_glass_card.dart';
import '../../core/widgets/liquid_glass/fluid_mesh_background.dart';
import '../../core/widgets/liquid_glass/liquid_controls.dart';

/// Complete Showcase Screen: AETHER // Liquidity & Wealth Command Center.
///
/// Demonstrates high-refraction liquid glass surfaces, directional Fresnel
/// refraction borders, animated chromatic fluid mesh backgrounds, and tactile
/// organic controls.
class LiquidGlassShowcaseScreen extends StatefulWidget {
  const LiquidGlassShowcaseScreen({super.key});

  @override
  State<LiquidGlassShowcaseScreen> createState() =>
      _LiquidGlassShowcaseScreenState();
}

class _LiquidGlassShowcaseScreenState extends State<LiquidGlassShowcaseScreen> {
  double _yieldAllocation = 0.68; // 68%
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final projectedApy = (8.4 + _yieldAllocation * 4.2).toStringAsFixed(1);
    final projectedRewards =
        (_yieldAllocation * 148920.45 * 0.12).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: const Color(0xFF040714),
      body: FluidMeshBackground(
        speedMultiplier: 1.1,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Scrollable Liquid Feed
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App Bar / Top Navigation
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // User profile avatar badge in liquid glass
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF005FEA), Color(0xFF9333EA)],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF005FEA).withValues(alpha: 0.4),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    "Æ",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        "AETHER",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF10B981),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0xFF10B981),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "Liquid Wealth v2.5",
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.55),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Top Action Pills
                          Row(
                            children: [
                              _buildGlassIconAction(
                                icon: Icons.notifications_none_rounded,
                                hasBadge: true,
                              ),
                              const SizedBox(width: 10),
                              _buildGlassIconAction(
                                icon: Icons.tune_rounded,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Hero Liquid Card: Total Liquid Assets
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      child: LiquidGlassCard(
                        borderRadius: 32.0,
                        blurSigma: 32.0,
                        tintColor: Colors.white,
                        tintOpacity: 0.08,
                        glowColor: const Color(0x33005FEA),
                        glowRadius: 32.0,
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.all_inclusive_rounded,
                                        size: 14,
                                        color: Color(0xFF38BDF8),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "TOTAL LIQUID NET ASSETS",
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.65),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                                const LiquidMetricBadge(
                                  text: "+18.4%",
                                  isPositive: true,
                                  icon: Icons.trending_up_rounded,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Main Big Tabular Number
                            const Text(
                              "\$148,920.45",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.0,
                                height: 1.1,
                                fontFeatures: [ui.FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "≈ 46.25 ETH · Available across 4 liquidity pools",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.50),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Sparkline Wave Custom Paint
                            SizedBox(
                              height: 48,
                              width: double.infinity,
                              child: CustomPaint(
                                painter: _LiquidSparklinePainter(),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Mini Metrics Footer
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.white.withValues(alpha: 0.04),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildSubMetric(
                                    label: "24h Inflow",
                                    value: "+\$4,210.80",
                                    color: const Color(0xFF10B981),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 24,
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                  _buildSubMetric(
                                    label: "Vault Health",
                                    value: "99.8%",
                                    color: const Color(0xFF38BDF8),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 24,
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                  _buildSubMetric(
                                    label: "Gas Base",
                                    value: "14 Gwei",
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Quick Liquid Actions Row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildActionTile(
                            icon: Icons.north_east_rounded,
                            label: "Send",
                            gradient: const [Color(0xFF005FEA), Color(0xFF2563EB)],
                          ),
                          _buildActionTile(
                            icon: Icons.swap_horiz_rounded,
                            label: "Swap",
                            gradient: const [Color(0xFF9333EA), Color(0xFFC026D3)],
                          ),
                          _buildActionTile(
                            icon: Icons.water_drop_rounded,
                            label: "Stake",
                            gradient: const [Color(0xFF06B6D4), Color(0xFF0284C7)],
                          ),
                          _buildActionTile(
                            icon: Icons.shield_outlined,
                            label: "Vault",
                            gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Fluid Slider: Dynamic Yield Rebalancer
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 8.0,
                      ),
                      child: LiquidGlassCard(
                        borderRadius: 26.0,
                        blurSigma: 26.0,
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const LiquidEmbossedIcon(
                                      icon: Icons.auto_graph_rounded,
                                      size: 36,
                                      iconSize: 18,
                                      iconColor: Color(0xFF38BDF8),
                                      baseColor: Color(0xFF0284C7),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Dynamic Yield Rebalancer",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          "Est. APY: $projectedApy% · Projected +\$$projectedRewards/yr",
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.5),
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  "${(_yieldAllocation * 100).toInt()}%",
                                  style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            LiquidFluidSlider(
                              value: _yieldAllocation,
                              onChanged: (val) {
                                setState(() => _yieldAllocation = val);
                              },
                              activeGlowColor: const Color(0xFF005FEA),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bento Grid: Two Liquid Cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          // Left Bento Card
                          Expanded(
                            child: LiquidGlassCard(
                              borderRadius: 24.0,
                              blurSigma: 26.0,
                              padding: const EdgeInsets.all(18.0),
                              glowColor: const Color(0x229333EA),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: const Color(0xFF9333EA)
                                              .withValues(alpha: 0.2),
                                          border: Border.all(
                                            color: const Color(0xFF9333EA)
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.currency_bitcoin_rounded,
                                            size: 18,
                                            color: Color(0xFFD8B4FE),
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.north_east_rounded,
                                        size: 14,
                                        color: Colors.white38,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    "ETH Staking",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "32.40 ETH",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "≈ \$112,450.00",
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.45),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Right Bento Card
                          Expanded(
                            child: LiquidGlassCard(
                              borderRadius: 24.0,
                              blurSigma: 26.0,
                              padding: const EdgeInsets.all(18.0),
                              glowColor: const Color(0x22F59E0B),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: const Color(0xFFF59E0B)
                                              .withValues(alpha: 0.2),
                                          border: Border.all(
                                            color: const Color(0xFFF59E0B)
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.lock_outline_rounded,
                                            size: 18,
                                            color: Color(0xFFFCD34D),
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 14,
                                        color: Color(0xFF10B981),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    "Cold Vault",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "100% Secured",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Timelock 48h active",
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.45),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Recent Liquid Transactions Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "LIVE REHYDRATION STREAM",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            "View ledger ➔",
                            style: TextStyle(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.85),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Transaction List Items
                  SliverList(
                    delegate: SliverChildListDelegate([
                      _buildTransactionRow(
                        title: "Compound Liquidity Yield",
                        subtitle: "Aave V3 · Automated rebalance",
                        amount: "+\$342.18",
                        isPositive: true,
                        icon: Icons.water_drop_rounded,
                        accentColor: const Color(0xFF10B981),
                      ),
                      _buildTransactionRow(
                        title: "Arbitrum Bridge Transfer",
                        subtitle: "L2 Optimism ➔ Arbitrum One",
                        amount: "-\$1,200.00",
                        isPositive: false,
                        icon: Icons.swap_calls_rounded,
                        accentColor: const Color(0xFF38BDF8),
                      ),
                      _buildTransactionRow(
                        title: "Uniswap LP Fee Harvest",
                        subtitle: "USDC / ETH 0.05% Tier",
                        amount: "+\$89.40",
                        isPositive: true,
                        icon: Icons.grain_rounded,
                        accentColor: const Color(0xFFF59E0B),
                      ),
                    ]),
                  ),

                  // Extra bottom padding for floating navigation dock
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 120),
                  ),
                ],
              ),

              // Floating Liquid Glass Navigation Dock at Bottom
              Positioned(
                left: 20,
                right: 20,
                bottom: 24,
                child: _buildFloatingLiquidDock(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconAction({
    required IconData icon,
    bool hasBadge = false,
  }) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.07),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.0,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.white),
          if (hasBadge)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEF4444),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFEF4444),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required List<Color> gradient,
  }) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gradient.first.withValues(alpha: 0.35),
                gradient.last.withValues(alpha: 0.15),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              size: 22,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionRow({
    required String title,
    required String subtitle,
    required String amount,
    required bool isPositive,
    required IconData icon,
    required Color accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
      child: LiquidGlassCard(
        borderRadius: 20.0,
        blurSigma: 24.0,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                color: accentColor.withValues(alpha: 0.18),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.35),
                ),
              ),
              child: Center(
                child: Icon(icon, size: 19, color: accentColor),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                color: isPositive ? const Color(0xFF10B981) : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFeatures: const [ui.FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingLiquidDock() {
    return LiquidGlassCard(
      borderRadius: 9999,
      blurSigma: 32.0,
      tintOpacity: 0.10,
      borderWidth: 1.3,
      glowColor: const Color(0x33005FEA),
      glowRadius: 28.0,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDockItem(icon: Icons.grid_view_rounded, index: 0, label: "Vault"),
          _buildDockItem(icon: Icons.pie_chart_outline_rounded, index: 1, label: "Analytics"),
          // Elevated Center Fluid Pill
          GestureDetector(
            onTap: () => HapticFeedback.heavyImpact(),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF005FEA), Color(0xFF38BDF8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF005FEA).withValues(alpha: 0.55),
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          _buildDockItem(icon: Icons.swap_vert_rounded, index: 2, label: "Bridge"),
          _buildDockItem(icon: Icons.person_outline_rounded, index: 3, label: "Identity"),
        ],
      ),
    );
  }

  Widget _buildDockItem({
    required IconData icon,
    required int index,
    required String label,
  }) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = index);
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9999),
          color: isSelected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for a luminous liquid sparkline wave.
class _LiquidSparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final points = [
      Offset(0, h * 0.75),
      Offset(w * 0.15, h * 0.65),
      Offset(w * 0.30, h * 0.80),
      Offset(w * 0.45, h * 0.40),
      Offset(w * 0.60, h * 0.55),
      Offset(w * 0.75, h * 0.20),
      Offset(w * 0.90, h * 0.35),
      Offset(w, h * 0.10),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final cx = (p0.dx + p1.dx) / 2;
      path.quadraticBezierTo(p0.dx, p0.dy, cx, (p0.dy + p1.dy) / 2);
    }
    path.lineTo(points.last.dx, points.last.dy);

    // Gradient Stroke
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.8
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(w, 0),
        const [
          Color(0xFF005FEA),
          Color(0xFF38BDF8),
          Color(0xFF10B981),
        ],
      );

    canvas.drawPath(path, strokePaint);

    // Glowing Dot at apex
    final dotPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
    canvas.drawCircle(points.last, 4.5, dotPaint);

    final innerDot = Paint()..color = Colors.white;
    canvas.drawCircle(points.last, 2.2, innerDot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
