with open('lib/features/settings/theme_customizer_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Line 8904 (0-index 8903)
lines[8903] = "                        'Th\u1ebb M\u1eabu: ${_getWidgetCardName(studio.widgetCardStyle)}',\n"

# Line 8913 (0-index 8912)
lines[8912] = "                        'Trong su\u1ed1t: ${(studio.glassOpacity * 100).toInt()}% \u2022 \u0110\u1ed9 m\u1edd: ${studio.glassBlur.toInt()}px',\n"

# Line 9179 (0-index 9178)
lines[9178] = "                  'Ki\u1ec3u: ${isFloating ? 'Đ\u1ea3o N\u1ed5i \u0110\u1ed9c L\u1eadp' : (studio.appBarScrollBehavior == AppAppBarScrollBehavior.pinned ? 'Ghim K\xednh C\u1ed1 \u0110\u1ecbnh' : 'T\u1ef1 \u0110\u1ed9ng \u1ea8n Khi Cu\u1ed9n')}',\n"

# Line 9184 (0-index 9183)
lines[9183] = "                  '\u0110\u1ed9 m\u1edd: ${(studio.appBarOpacity * 100).toInt()}% \u2022 Nh\xf2e: ${studio.appBarBlur.toInt()}px',\n"

with open('lib/features/settings/theme_customizer_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print('Lines successfully replaced via patch_strings.py!')
