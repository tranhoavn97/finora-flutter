  Widget _buildLiveHeroCardProPreview({
    required ThemeStudioController studio,
    required bool isDark,
    required Color primary,
    required PaletteMeta palette,
  }) {
    final balanceFontSize = switch (studio.heroBalanceSize) {
      AppHeroBalanceSize.compact => 24.0,
      AppHeroBalanceSize.standard => 30.0,
      AppHeroBalanceSize.largeEmphasis => 36.0,
    };

    final cardTintColors = studio.getHeroCardGradient(isDark);

    return Column(
      children: [
        // Hero Card Pro Container
        AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          height: 165,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: cardTintColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(
                studio.cardCornerRadius.clamp(16.0, 26.0)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: cardTintColors.first.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const 
                          width: 0.8),
                    ),
                    child: Text(
                      _getHeroStyleName(studio.heroCardStyle),
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '128.500.000',
                    style: TextStyle(
                      fontSize: balanceFontSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '₫',
                    style: TextStyle(
                      fontSize: balanceFontSize * 0.65,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
              if (studio.heroCardStyle == AppHeroCardStyle.executiveBlackVip)
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text(
                      '•••• •••• •••• 8899',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 2,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.nfc_rounded,
                            size: 14, color: Color(0xFFF59E0B)),
                        SizedBox(width: 4),
                        Text('VIP PLATINUM',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFF59E0B))),
                      ],
                    ),
                  ],
                )
              else if (studio.heroCardStyle == AppHeroCardStyle.minimalistPulse)
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
     
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF10B981)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_upward_rounded,
                                size: 12, color: Color(0xFFF43F5E)),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '-18.650.000 ₫',
                                style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFF43F5E)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Live Action Buttons Row
        Row(
          children: [
            Expanded(
              child: GradientButton(
                height: 38,
                onPressed: () => _showFeedback('Chạm nút Nạp tiền'),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, size: 15, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Nạp',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF1E293B) : Colors.white)
                      .withValues(alpha: 0.8),
                  borderRadius: BorderRadiu
                  border: Border.all(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.1)),
                ),
                child: InkWell(
                  onTap: () => _showFeedback('Chạm nút Quét QR'),
                  borderRadius: BorderRadius.circular(studio.getButtonRadius()),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.qr_code, size: 14, color: primary),
                        const SizedBox(width: 4),
                        Text('Quét QR',
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Mini Dock Bar
        _buildMiniDockPreview(studio: studio, primary: primary, isDark: isDark),
      ],
    );
  }

  Widget _buildLiveBankCardAndDockPreview({
    required ThemeStudioController studio,
    required bool isDark,
    required Color primary,
    required PaletteMeta palette,
  }) {
    return Column(
      children: [
        // Live Morphing Bank Card Preview
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _previewVisaMode = !_previewVisaMode);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            height: 155,
            child: FinoraBankCardSurface(
              skin: studio.globalCardSkin,
              gradientColors: palette.heroGradient,
              borderRadius: studio.cardCornerRadius.clamp(14.0, 24.0),
              cardNetwork: _previewVisaMode ? 'visa' : null,
              bankName:
                  _previewVisaMode ? 'FINORA PLATINUM VISA' : 'VIETCOMBANK ATM',
              bankCode: _previewVisaMode ? 'vcb' : 'vcb',
              accountNumber: '•••• •••• •••• 8899',
              cardHolder: 'NGUYEN VAN A',
              expiryDate: '12/29',
              isDark: isDark,
              bottomContent: Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    childre
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF1E293B) : Colors.white)
                      .withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CategoryIconBadge(
                      icon: 'shopping-cart',
                      categoryName: 'Mua sắm',
                      color: const Color(0xFFEC4899),
                      size: 28,
                      isDark: isDark,
                    ),
                    CategoryIconBadge(
                      icon: 'utensils',
                      categoryName: 'Ăn uống',
                      color: const Color(0xFFF59E0B),
                      size: 28,
                      isDark: isDark,
                    ),
                    CategoryIconBadge(
                      icon: 'car',
                      categoryName: 'Đi lại',
                      color: const Color(0xFF3B82F6),
                      size: 28,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  Widget _buildLiveChartAndWidgetCardPreview({
    required ThemeStudioController studio,
    required bool isDark,
    required Color primary,
    required PaletteMeta palette,
  }) {
    final chartColors = switch (studio.chartColorway) {
      AppChartColorway.paletteSync => [primary, studio.secondaryColor],
      AppChartColorway.cyberpunkVibrant => const [
          Color(0xFF06B6D4),
          Color(0xFFEC4899)
        ],
      AppChartColorway.emeraldFortune => const [
          Color(0xFF10B981),
          Color(0xFFF59E0B)
        ],
      AppChartColorway.sunsetPastel => const [
          Color(0xFFFB923C),
          Color(0xFFA855F7)
        ],
    };

    return Column(
      children: [
        // Mini Chart Container
        ClipRRect(
          borderRadius:
              BorderRadius.circular(studio.cardCornerRadius.clamp(14.0, 24.0)),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: studio.glassBlur.clamp(0.0, 30.0),
              sigmaY: studio.glassBlur.clamp(0.0, 30.0),
            ),
            child: Container(
              height: 145,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF0F172A) : Colors.white)
                    .withValues(alpha: studio.glassOp
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.auto_awesome_rounded, size: 18, color: primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thẻ Mẫu: ${_getWidgetCardName(studio.widgetCardStyle)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Trong suốt: ${(studio.glassOpacity * 100).toInt()}% • Độ mờ: ${studio.glassBlur.toInt()}px',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: primary),
            ],
          ),
        ),
      ],
  Widget _buildLiveAppBarPreview({
    required ThemeStudioController studio,
    required bool isDark,
    required Color primary,
    required PaletteMeta palette,
  }) {
    final isFloating =
        studio.appBarScrollBehavior == AppAppBarScrollBehavior.floating;
    final seasonBadge = studio.getSeasonalBadge();

    return Column(
      children: [
        // Simulated Mobile Top Frame
        Container(
          height: 155,
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF090D16) : const Color(0xFFE2E8F0))
                .withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            ),
          ),
          child: Stack(
            children: [
              // Content placeholder inside screen
              Positioned.fill(
                top: 72,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
     
                                      alpha: isDark ? 0.22 : 0.12),
                                  blurRadius: 14,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient:
                                  LinearGradient(colors: palette.heroGradient),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text('H',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Chào, Hoà Trần',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (seasonBadge != null)
                                      Text('${seasonBadge.$1} ',
                                          style:
                                              const TextStyle(fontSize: 10.5)),
                                    Text(
                                      seasonBadge != null
                                          ? 'Tết Giáp Thìn'
                                          : 'Finora AI Pro',
                                      style: TextStyle(
                                        fontSize: 10,
        
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Indicator Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
                .withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                'Kiểu: ${isFloating ? 'Đảo Nổi Độc Lập' : (studio.appBarScrollBehavior == AppAppBarScrollBehavior.pinned ? 'Ghim Kính Cố Định' : 'Tự Động Ẩn Khi Cuộn')}',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: primary),
              ),
              Text(
                'Độ mờ: ${(studio.appBarOpacity * 100).toInt()}% • Nhòe: ${studio.appBarBlur.toInt()}px',
                style: TextStyle(
                    fontSize: 10.5,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveIconStudioPreview({
    required ThemeStudioController studio,
    required bool isDark,
    required Color primary,
    required PaletteMeta palette,
  }) {
    const demoCategories = [
      (icon: 'shopping-cart', name: 'Mua sắm', color: Color(0xFFEC4899)),
      (icon: 'utensils', name: 'Ăn uống', color: Color(0xFFF59E0B)),
      (icon: 'car', name: 'Đi lại', color: Color(0xFF3B82F6)),
      (icon: 'wallet', name: 'Tiền lương', color: Color(0xFF10B981)),
      (icon: 'receipt', name: 'Hóa đơn', color: Color(0xFF8B5CF6)),
      (icon: 'cross', name: 'Y tế', color: Color(0xFFEF4444)),
    ];

    return Column(
      children: [
        // 6 Category Icon Badges in a Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF0F172A) : Colors.white)
                .withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: demoCategories.map((c) {
              return GestureDetector(
                onT
                  ],
                ),
              ),
              const Text(
                '-350.000 ₫',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF43F5E),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Indicator showing active icon settings
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: primary.withValues(alpha: 0.25), width: 0.8),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                'Hình: ${_getIconShapeName(studio.iconShape)} • Hiệu ứng: ${_getIconEffectName(studio.iconVisualEffect)}',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: primary),
              ),
              Text(
                'Độ đậm nền: ${(studio.iconBgOpacity * 100).toInt()}%',
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600, color: primary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveOverviewMiniPreview({
    required ThemeStudioController studio,
    required bool isDark,
    required Color primary,
    required PaletteMeta palette,
  }) {
    final isFloating =
        studio.appBarScrollBehavior == AppAppBarScrollBehavior.floating;
    final seasonBadge = studio.getSeasonalBadge();
    final surfaceBase = studio.getStyleSurfaceBase(isDark);
    final effectiveBorder = studio.getCardBorder(isDark);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF090D16) : const Color(0xFFF1F5F9))
            .withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          // 1. Mini Top Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(isFloating ? 16 : 12),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: studio.appBarBlur.clamp(0.0, 30.0),
                sigmaY: studio.appBarBlur.clamp(0.0, 30.0),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: const Color(0xFFF59E0B)
                                          .withValues(alpha: 0.4),
                                      width: 0.6),
                                ),
                                child: Text(
                                  studio.membershipTier ==
                                          AppMembershipTierBadge.diamondCrown
                                      ? '👑 VIP'
                                      : '⭐ PRO',
                                  style: const TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFF59E0B)),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            seasonBadge != null
                                ? '${seasonBadge.$1} Tết Giáp Thìn'
                                : 'FINORA AI • Tổng quan',
                            style: TextStyle(
                              fontSize: 9,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Notification Icon
                    Container(
                      width: 28,
                      height: 28,
                      decoration: studio.getIconContainerDecoration(
                        color: primary,
                        isDark: isDark,
                        size: 28,
                      ),
                      child: Center(
                        child: Icon(
                          LucideIcons.bell,
                          size: 14,
                          color: studio.resolveIconGlyphColor(primary, isDark),
                        ),
                      ),
                Text(
                  'AppBar: ${(studio.appBarOpacity * 100).toInt()}% • Blur: ${studio.appBarBlur.toInt()}px',
                  style: TextStyle(
                      fontSize: 9.5,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniQuickAction(
    String label,
    IconData icon,
    Color color,
    ThemeStudioController studio,
    bool isDark,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: studio.getIconContainerDecoration(
            color: color,
            isDark: isDark,
            size: 38,
          ),
          child: Center(
            child: Icon(
              icon,
              size: 16,
              color: studio.resolveIconGlyphColor(color, isDark),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveButtonsAndLedgerPreview({
    required ThemeStudioController studio,
    required bool isDark,
    required Color primary,
    required PaletteMeta palette,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF090D16) : const Color(0xFFF1F5F9))
            .withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xem Trước Nút Bấm & Phong Cách Sổ Cái',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          // Primary & Secondary Buttons Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: studio.getButtonHeight(),
                  padding: studio.getButtonPadding(),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: palette.hero
            child: Row(
              children: [
                CategoryIconBadge(
                  icon: 'utensils',
                  categoryName: 'Ăn uống',
                  color: const Color(0xFFF59E0B),
                  size: 38,
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cà phê sáng Highlands',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hôm nay • Ăn uống & giải trí',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  '-45.000 ₫',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFF43F5E),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  'Bo nút: ${studio.getButtonRadius().toInt()}px • Cao: ${studio.getButtonHeight().toInt()}px',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: primary),
                ),
                Text(
                  'Thẻ: Bo ${studio.cardCornerRadius.toInt()}px • Bề mặt: ${studio.surfaceStyle.name}',
                  style: TextStyle(
                      fontSize: 9.5,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
                ),
              ],
            ),
   
        icon: Icons.layers_rounded,
      ),
      (
        behavior: AppAppBarScrollBehavior.scrollHide,
        title: 'Tự Động Ẩn Khi Cuộn',
        badge: 'Tự Ẩn',
        desc: 'Ẩn khi vuốt xuống, xuất hiện lại ngay khi vuốt lên',
        icon: Icons.visibility_off_rounded,
      ),
    ];

    return Column(
      children: [
        // 3 Behaviors
        ...behaviors.map((item) {
          final isSelected = studio.appBarScrollBehavior == item.behavior;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () async {
                await studio.setAppBarScrollBehavior(item.behavior);
                _showFeedback('Tiêu đề: ${item.title}');
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF1E293B) : Colors.white)
                      .withValues(alpha: isSelected ? 0.95 : 0.65),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? primary
                        : (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.08),
                    width: isSelected ? 1.8 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
