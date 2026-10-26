import 'package:flutter/material.dart';

/// Trình hiển thị văn bản Markdown tài chính cao cấp cho Finora AI
/// Hỗ trợ: Bold **...**, Tiêu đề #/##/###, Gạch đầu dòng •/-/*, Danh sách số 1.,
/// Blockquote >, Highlight số tiền VND (+50.000 đ, -150.000 đ), Bảng & Mã tóm tắt.
class FinoraMarkdownView extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;
  final Color primaryAccent;
  final bool isDark;

  const FinoraMarkdownView({
    super.key,
    required this.text,
    required this.baseStyle,
    required this.primaryAccent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      final budget = RegExp(
              r'^[•*-]\s*(.+?):\s*Đã (?:tiêu|chi)\s+(.+?)\s*/\s*(.+?)\s*\((\d+(?:[.,]\d+)?)%\)$',
              caseSensitive: false)
          .firstMatch(trimmed.replaceAll('**', ''));
      if (budget != null) {
        final percent = double.tryParse(budget[4]!.replaceAll(',', '.')) ?? 0;
        final color = percent >= 100
            ? const Color(0xFFe82246)
            : percent >= 80
                ? const Color(0xFFd96700)
                : const Color(0xFF009e60);
        widgets.add(Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: .05)
                    : const Color(0xFFf8fafc),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFe2e8f0))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(budget[1]!,
                        style:
                            baseStyle.copyWith(fontWeight: FontWeight.w700))),
                Text('${budget[4]}%',
                    style: baseStyle.copyWith(fontWeight: FontWeight.w700))
              ]),
              const SizedBox(height: 4),
              Text('Đã chi ${budget[2]} / ${budget[3]}',
                  style: baseStyle.copyWith(fontSize: 11)),
              const SizedBox(height: 7),
              LinearProgressIndicator(
                  value: (percent / 100).clamp(0, 1),
                  color: color,
                  backgroundColor:
                      isDark ? Colors.white12 : const Color(0xFFe2e8f0),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(9)),
              if (percent > 100)
                Text('Đã vượt hạn mức',
                    style: baseStyle.copyWith(color: color, fontSize: 10)),
            ])));
        continue;
      }

      final moneyRow = RegExp(r'^[•*-]\s+(.+?):\s*\*\*([-+]?[^*]+[₫đ])\*\*$')
          .firstMatch(trimmed);
      if (moneyRow != null) {
        widgets.add(Container(
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: .04)
                    : const Color(0xFFF4F6FA),
                borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Expanded(
                  flex: 5,
                  child: Text(moneyRow[1]!.replaceAll('**', ''),
                      style: baseStyle.copyWith(fontSize: 12))),
              const SizedBox(width: 10),
              Expanded(
                  flex: 6,
                  child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(moneyRow[2]!,
                          style:
                              baseStyle.copyWith(fontWeight: FontWeight.w700))))
            ])));
        continue;
      }

      // 1. Heading 1, 2, 3
      if (trimmed.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            trimmed.substring(4),
            style: baseStyle.copyWith(
              fontSize: (baseStyle.fontSize ?? 14.5) + 1.5,
              fontWeight: FontWeight.w800,
              color: primaryAccent,
              letterSpacing: -0.2,
            ),
          ),
        ));
      } else if (trimmed.startsWith('## ') || trimmed.startsWith('# ')) {
        final headingText = trimmed.startsWith('## ')
            ? trimmed.substring(3)
            : trimmed.substring(2);
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(
            headingText,
            style: baseStyle.copyWith(
              fontSize: (baseStyle.fontSize ?? 14.5) + 3.0,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
        ));
      }
      // 2. Blockquote (> ...)
      else if (trimmed.startsWith('> ')) {
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: primaryAccent.withValues(alpha: isDark ? 0.12 : 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(color: primaryAccent, width: 3.5),
            ),
          ),
          child: _buildRichText(
            trimmed.substring(2),
            baseStyle.copyWith(
              fontStyle: FontStyle.italic,
              fontSize: (baseStyle.fontSize ?? 14.5) - 0.5,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ));
      }
      // 3. Bullet points (•, -, *)
      else if (trimmed.startsWith('• ') ||
          trimmed.startsWith('- ') ||
          trimmed.startsWith('* ')) {
        final content = trimmed.substring(2);
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 5, left: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6, right: 8),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryAccent,
                  boxShadow: [
                    BoxShadow(
                      color: primaryAccent.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildRichText(content, baseStyle),
              ),
            ],
          ),
        ));
      }
      // 4. Numbered list (1. , 2. )
      else if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
        final match = RegExp(r'^(\d+)\.\s').firstMatch(trimmed)!;
        final numStr = match.group(1)!;
        final content = trimmed.substring(match.end);
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2, right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: primaryAccent.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  numStr,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: primaryAccent,
                  ),
                ),
              ),
              Expanded(
                child: _buildRichText(content, baseStyle),
              ),
            ],
          ),
        ));
      }
      // 5. Standard line
      else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: _buildRichText(trimmed, baseStyle),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  /// Phân tích cú pháp inline: **bold**, `code`, và số tiền VND
  Widget _buildRichText(String text, TextStyle currentStyle) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(
      r'(\*\*[^*]+\*\*|`[^`]+`|[-+]?\b\d{1,3}(?:\.\d{3})+(?:\s*(?:đ|vnd|vnđ))?\b)',
      caseSensitive: false,
    );

    int lastMatchEnd = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: currentStyle,
        ));
      }

      final matchedText = match.group(0)!;

      // Bold **...**
      if (matchedText.startsWith('**') && matchedText.endsWith('**')) {
        final inner = matchedText.substring(2, matchedText.length - 2);
        spans.add(TextSpan(
          text: inner,
          style: currentStyle.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ));
      }
      // Code `...`
      else if (matchedText.startsWith('`') && matchedText.endsWith('`')) {
        final inner = matchedText.substring(1, matchedText.length - 1);
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              inner,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: (currentStyle.fontSize ?? 14.5) - 1.5,
                fontWeight: FontWeight.w700,
                color: primaryAccent,
              ),
            ),
          ),
        ));
      }
      // Money values (e.g. 15.000.000 đ or +500.000 đ)
      else {
        final isNegative = matchedText.startsWith('-');
        final isPositive = matchedText.startsWith('+');
        final color = isNegative
            ? const Color(0xFFEF4444)
            : isPositive
                ? const Color(0xFF10B981)
                : primaryAccent;

        spans.add(TextSpan(
          text: matchedText,
          style: currentStyle.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: currentStyle,
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      style: currentStyle,
    );
  }
}
