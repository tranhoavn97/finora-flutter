with open('lib/features/settings/theme_customizer_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Season badge text fix
old_season = """                                      if (seasonBadge != null)
                                        Text(' ',
                                            style:
                                                const TextStyle(fontSize: 10.5)),"""

new_season = """                                      if (seasonBadge != null)
                                        Text('${seasonBadge.$1} ',
                                            style:
                                                const TextStyle(fontSize: 10.5)),"""

assert old_season in text, "old_season not found"
text = text.replace(old_season, new_season, 1)

# 2. _buildLiveIconStudioPreview
old_icon_tap = """            children: demoCategories.map((c) {
              return GestureDetector(
                onTap: () => _showFeedback('Icon: ${c.name}'),"""

new_icon_tap = """            children: demoCategories.map((c) {
              return GestureDetector(
                onTap: () => _jumpToComponent(5, 'Biểu tượng: ${c.name}', previewMode: 4),"""

assert old_icon_tap in text, "old_icon_tap not found"
text = text.replace(old_icon_tap, new_icon_tap, 1)

old_trans_row = """        // Live Transaction Row item
        Container(
          padding: const EdgeInsets.all(12),"""

new_trans_row = """        // Live Transaction Row item - Click to jump
        GestureDetector(
          onTap: () => _jumpToComponent(4, 'Danh sách giao dịch (Nút & danh sách)', previewMode: 4),
          child: Container(
          padding: const EdgeInsets.all(12),"""

assert old_trans_row in text, "old_trans_row not found"
text = text.replace(old_trans_row, new_trans_row, 1)

old_trans_end = """              const Text(
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

        const SizedBox(height: 10),"""

new_trans_end = """              const Text(
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
        ),

        const SizedBox(height: 10),"""

assert old_trans_end in text, "old_trans_end not found"
text = text.replace(old_trans_end, new_trans_end, 1)

old_icon_ind = """        // Indicator showing active icon settings
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),"""

new_icon_ind = """        // Indicator showing active icon settings - Click to jump
        GestureDetector(
          onTap: () => _jumpToComponent(5, 'Hình dạng & hiệu ứng biểu tượng', previewMode: 4),
          child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),"""

assert old_icon_ind in text, "old_icon_ind not found"
text = text.replace(old_icon_ind, new_icon_ind, 1)

old_icon_ind_end = """              Text(
                'Độ đậm nền: ${(studio.iconBgOpacity * 100).toInt()}%',
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600, color: primary),
              ),
            ],
          ),
        ),
      ],
    );
  }"""

new_icon_ind_end = """              Text(
                'Độ đậm nền: ${(studio.iconBgOpacity * 100).toInt()}%',
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600, color: primary),
              ),
            ],
          ),
        ),
        ),
      ],
    );
  }"""

assert old_icon_ind_end in text, "old_icon_ind_end not found"
text = text.replace(old_icon_ind_end, new_icon_ind_end, 1)

# 3. _buildLiveOverviewMiniPreview
old_top_bar = """          // 1. Mini Top Bar
          ClipRRect("""

new_top_bar = """          // 1. Mini Top Bar - Click to jump
          GestureDetector(
            onTap: () => _jumpToComponent(3, 'Thanh tiêu đề (AppBar)', previewMode: 3),
            child: ClipRRect("""

assert old_top_bar in text, "old_top_bar not found"
text = text.replace(old_top_bar, new_top_bar, 1)

old_top_bar_end = """                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),"""

new_top_bar_end = """                    ),
                  ],
                ),
              ),
            ),
          ),
          ),

          const SizedBox(height: 10),"""

assert old_top_bar_end in text, "old_top_bar_end not found"
text = text.replace(old_top_bar_end, new_top_bar_end, 1)

old_overview_hero = """          // 2. Mini Hero Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: palette.heroGradient,"""

new_overview_hero = """          // 2. Mini Hero Card - Click to jump
          GestureDetector(
            onTap: () => _jumpToComponent(6, 'Thẻ tổng tài sản & Cỡ số dư', previewMode: 0),
            child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: palette.heroGradient,"""

assert old_overview_hero in text, "old_overview_hero not found"
text = text.replace(old_overview_hero, new_overview_hero, 1)

old_overview_hero_end = """                const Text(
                  '125.450.000 ₫',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),"""

new_overview_hero_end = """                const Text(
                  '125.450.000 ₫',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          ),

          const SizedBox(height: 10),"""

assert old_overview_hero_end in text, "old_overview_hero_end not found"
text = text.replace(old_overview_hero_end, new_overview_hero_end, 1)

old_quick_actions = """          // 3. Quick Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniQuickAction('Nạp tiền', LucideIcons.plus,
                  const Color(0xFF10B981), studio, isDark),
              _buildMiniQuickAction('Chuyển', LucideIcons.arrow_up_right,
                  const Color(0xFF3B82F6), studio, isDark),
              _buildMiniQuickAction('Quét QR', LucideIcons.qr_code,
                  const Color(0xFF8B5CF6), studio, isDark),
              _buildMiniQuickAction('Ví phụ', LucideIcons.wallet,
                  const Color(0xFFF59E0B), studio, isDark),
            ],
          ),"""

new_quick_actions = """          // 3. Quick Action Buttons - Click to jump
          GestureDetector(
            onTap: () => _jumpToComponent(4, 'Nút thao tác nhanh & danh sách', previewMode: 4),
            child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniQuickAction('Nạp tiền', LucideIcons.plus,
                  const Color(0xFF10B981), studio, isDark),
              _buildMiniQuickAction('Chuyển', LucideIcons.arrow_up_right,
                  const Color(0xFF3B82F6), studio, isDark),
              _buildMiniQuickAction('Quét QR', LucideIcons.qr_code,
                  const Color(0xFF8B5CF6), studio, isDark),
              _buildMiniQuickAction('Ví phụ', LucideIcons.wallet,
                  const Color(0xFFF59E0B), studio, isDark),
            ],
          ),
          ),"""

assert old_quick_actions in text, "old_quick_actions not found"
text = text.replace(old_quick_actions, new_quick_actions, 1)

# 4. _buildLiveButtonsAndLedgerPreview
old_buttons_row = """          // Primary & Secondary Buttons Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: studio.getButtonHeight(),"""

new_buttons_row = """          // Primary & Secondary Buttons Row - Click to jump
          GestureDetector(
            onTap: () => _jumpToComponent(4, 'Màu nút & phong cách nút', previewMode: 0),
            child: Row(
            children: [
              Expanded(
                child: Container(
                  height: studio.getButtonHeight(),"""

assert old_buttons_row in text, "old_buttons_row not found"
text = text.replace(old_buttons_row, new_buttons_row, 1)

old_buttons_end = """                  child: Center(
                    child: Text(
                      'Kính Phụ',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),"""

new_buttons_end = """                  child: Center(
                    child: Text(
                      'Kính Phụ',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),

          const SizedBox(height: 12),"""

assert old_buttons_end in text, "old_buttons_end not found"
text = text.replace(old_buttons_end, new_buttons_end, 1)

old_ledger = """          // Transaction Ledger Item
          Container(
            padding: const EdgeInsets.all(12),
            decoration: studio.getCardDecoration(
              isDark: isDark,
            ),"""

new_ledger = """          // Transaction Ledger Item - Click to jump
          GestureDetector(
            onTap: () => _jumpToComponent(4, 'Phong cách thẻ sổ cái & danh sách', previewMode: 4),
            child: Container(
            padding: const EdgeInsets.all(12),
            decoration: studio.getCardDecoration(
              isDark: isDark,
            ),"""

assert old_ledger in text, "old_ledger not found"
text = text.replace(old_ledger, new_ledger, 1)

old_ledger_end = """                const Text(
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

          const SizedBox(height: 10),"""

new_ledger_end = """                const Text(
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
          ),

          const SizedBox(height: 10),"""

assert old_ledger_end in text, "old_ledger_end not found"
text = text.replace(old_ledger_end, new_ledger_end, 1)

with open('lib/features/settings/theme_customizer_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print('All interactive click-to-jump enhancements successfully applied!')
