import 'package:flutter/material.dart';

/// Mobile counterpart of web/AiMessageContent: metric rows, budget progress,
/// headings, short lists and source notes. Content remains selectable plain text.
class AssistantResponseBody extends StatelessWidget {
  final String text;
  const AssistantResponseBody({super.key, required this.text});

  List<InlineSpan> _inline(String value, TextStyle style) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*|`([^`]+)`|\*([^*\n]+)\*');
    var start = 0;
    for (final match in pattern.allMatches(value)) {
      if (match.start > start)
        spans.add(TextSpan(text: value.substring(start, match.start)));
      spans.add(TextSpan(
          text: match.group(1) ?? match.group(2) ?? match.group(3),
          style: match.group(1) != null
              ? style.copyWith(fontWeight: FontWeight.w700)
              : match.group(2) != null
                  ? style.copyWith(fontFamily: 'monospace', fontSize: 12)
                  : style.copyWith(fontStyle: FontStyle.italic)));
      start = match.end;
    }
    if (start < value.length) spans.add(TextSpan(text: value.substring(start)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final positive = dark ? const Color(0xFF6EE7B7) : const Color(0xFF087C61);
    final negative = dark ? const Color(0xFFFDA4AF) : const Color(0xFFBE374B);
    final style =
        TextStyle(fontSize: 13, height: 1.65, color: colors.onSurface);
    Widget rich(String value, [TextStyle? custom]) =>
        SelectableText.rich(TextSpan(
            style: custom ?? style, children: _inline(value, custom ?? style)));
    final blocks = <Widget>[];
    var code = false;
    for (final line in text.trim().split('\n')) {
      final raw = line.trim();
      if (raw.startsWith('```')) {
        code = !code;
        continue;
      }
      if (raw.isEmpty) continue;
      final plain = raw
          .replaceAll('**', '')
          .replaceFirst(RegExp(r'^(?:[-*•]|\d+[.)])\s+'), '');
      final budget = !code
          ? RegExp(
                  r'^(.+?):\s*Đã (?:tiêu|chi)\s+(.+?)\s*/\s*(.+?)\s*\((\d+(?:[.,]\d+)?)%\)$',
                  caseSensitive: false)
              .firstMatch(plain)
          : null;
      final metric = !code
          ? RegExp(r'^([^:]+):\s*([+−\-]?\s*\d[\d.,\s]*\s*(?:₫|đ|vnd|vnđ))$',
                  caseSensitive: false)
              .firstMatch(plain)
          : null;
      if (budget != null) {
        final percent = double.tryParse(budget[4]!.replaceAll(',', '.')) ?? 0;
        final accent = percent >= 100
            ? negative
            : percent >= 80
                ? (dark ? Colors.amber.shade200 : Colors.brown)
                : positive;
        blocks.add(Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: .5))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(budget[1]!,
                        style: style.copyWith(fontWeight: FontWeight.w700))),
                const SizedBox(width: 8),
                Text('${budget[4]}%',
                    style: style.copyWith(
                        color: accent, fontWeight: FontWeight.w700))
              ]),
              const SizedBox(height: 4),
              rich('Đã chi ${budget[2]} / ${budget[3]}',
                  style.copyWith(fontSize: 11, color: colors.onSurfaceVariant)),
              const SizedBox(height: 10),
              Semantics(
                  label: 'Ngân sách ${budget[1]}, đã chi $percent phần trăm',
                  child: LinearProgressIndicator(
                      value: (percent / 100).clamp(0, 1),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(8),
                      color: accent,
                      backgroundColor:
                          colors.outlineVariant.withValues(alpha: .3))),
              if (percent > 100)
                Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('Đã vượt hạn mức',
                        style: style.copyWith(fontSize: 11, color: negative))),
            ])));
      } else if (metric != null) {
        final label = metric[1]!;
        final accent =
            RegExp('thu nhập|tổng thu|thặng dư|giảm', caseSensitive: false)
                    .hasMatch(label)
                ? positive
                : RegExp('tổng chi|chi tiêu|đã chi|thâm hụt|dư nợ|tăng',
                            caseSensitive: false)
                        .hasMatch(label)
                    ? negative
                    : positive;
        blocks.add(Container(
            key: ValueKey('metric-$label'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: .45))),
            child: LayoutBuilder(builder: (_, constraints) {
              final name = Text(label,
                  style: style.copyWith(
                      fontSize: 11, color: colors.onSurfaceVariant));
              final value = rich(
                  metric[2]!,
                  style.copyWith(
                      fontWeight: FontWeight.w800,
                      color: accent,
                      fontSize: 14,
                      fontFeatures: const [FontFeature.tabularFigures()]));
              return constraints.maxWidth < 240 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.2
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [name, const SizedBox(height: 4), value])
                  : Row(children: [
                      Expanded(child: name),
                      const SizedBox(width: 12),
                      Flexible(child: value)
                    ]);
            })));
      } else if (raw.startsWith('> ')) {
        blocks.add(Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: positive.withValues(alpha: .06),
                border: Border(
                    left: BorderSide(
                        color: positive.withValues(alpha: .5), width: 2))),
            child: rich(
                raw.substring(2),
                style.copyWith(
                    fontSize: 11,
                    height: 1.5,
                    color: colors.onSurfaceVariant))));
      } else if (!code && RegExp(r'^#{1,6}\s+').hasMatch(raw)) {
        blocks.add(Padding(
            padding: EdgeInsets.only(top: blocks.isEmpty ? 0 : 10, bottom: 2),
            child: rich(
                raw.replaceFirst(RegExp(r'^#{1,6}\s+'), ''),
                style.copyWith(
                    fontSize: 15, fontWeight: FontWeight.w700, height: 1.4))));
      } else {
        final bullet =
            !code ? RegExp(r'^(?:[-*•]|\d+[.)])\s+').firstMatch(raw) : null;
        Widget body = rich(
            bullet == null ? raw : raw.substring(bullet.end),
            code
                ? style.copyWith(fontFamily: 'monospace', fontSize: 12)
                : null);
        if (bullet != null)
          body = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                        color: positive, shape: BoxShape.circle))),
            Expanded(child: body)
          ]);
        if (code)
          body = Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: colors.surfaceContainerHighest,
              child: body);
        blocks.add(body);
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (var i = 0; i < blocks.length; i++)
        Padding(
            padding: EdgeInsets.only(bottom: i == blocks.length - 1 ? 0 : 8),
            child: blocks[i])
    ]);
  }
}
