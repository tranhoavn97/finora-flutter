import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Preserve the single row when there is room; give tabs the full width on
/// smaller screens or with large text instead of squeezing them between icons.
class WalletAdaptiveToolbar extends StatelessWidget {
  final Widget tabs;
  final List<Widget> actions;
  final String? ownerLabel;
  final VoidCallback onClearOwner;

  const WalletAdaptiveToolbar(
      {super.key,
      required this.tabs,
      required this.actions,
      this.ownerLabel,
      required this.onClearOwner});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final isLargeText = MediaQuery.textScalerOf(context).scale(12) > 16;
        final controls = Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            actions[i],
          ],
        ]);
        final status = ownerLabel == null
            ? const SizedBox.shrink()
            : InputChip(
                key: const ValueKey('wallet-owner-status'),
                label: Text('Đang lọc: $ownerLabel', maxLines: 2),
                onDeleted: onClearOwner,
                deleteButtonTooltipMessage: 'Xem tất cả thành viên',
              );

        // When accessibility large text (scale > 1.33) is active, preserve stacked layout
        // to prevent large font truncation in accessibility testing:
        if (isLargeText) {
          final stacked = box.maxWidth < 340;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (stacked) ...[
                tabs,
                const SizedBox(height: 6),
                Align(alignment: Alignment.centerRight, child: controls),
                if (ownerLabel != null)
                  Align(alignment: Alignment.centerLeft, child: status),
              ] else ...[
                Row(children: [
                  Expanded(child: tabs),
                  const SizedBox(width: 6),
                  controls,
                ]),
                if (ownerLabel != null)
                  Align(alignment: Alignment.centerLeft, child: status),
              ],
            ],
          );
        }

        // Standard user experience: STRICTLY 1 SINGLE ROW!
        return Row(
          children: [
            Expanded(child: tabs),
            const SizedBox(width: 6),
            controls,
          ],
        );
      });
}

class WalletDeckIndicator extends StatelessWidget {
  final int count;
  final int current;
  final ValueChanged<int> onSelect;
  const WalletDeckIndicator(
      {super.key,
      required this.count,
      required this.current,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (count < 2) return const SizedBox.shrink();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(builder: (context, box) {
      // Every interactive dot has a separate 44dp target. Keep room for arrows
      // and the counter; at large text sizes the counter takes its own row.
      final slots =
          math.min(5, math.max(0, ((box.maxWidth - 112) / 44).floor()));
      final visible = math.min(count, slots);
      final start = (current - visible ~/ 2).clamp(0, count - visible);
      Widget arrow(String label, IconData icon, int delta) => IconButton(
            tooltip: label,
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            padding: const EdgeInsets.all(8),
            onPressed: () => onSelect((current + delta) % count),
            icon: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (dark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.06)),
                child: Icon(icon, size: 20)),
          );
      return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Semantics(
                liveRegion: true,
                label: 'Ví ${current + 1} trên $count',
                child: ExcludeSemantics(
                    child: Text('${current + 1} / $count',
                        key: const ValueKey('wallet-deck-counter'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)))),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              arrow('Ví trước', Icons.chevron_left_rounded, -1),
              const SizedBox(width: 4),
              for (var idx = start; idx < start + visible; idx++)
                Semantics(
                    button: true,
                    selected: idx == current,
                    label: 'Chuyển đến ví ${idx + 1}',
                    child: Tooltip(
                        message: 'Ví ${idx + 1}',
                        child: InkWell(
                            key: ValueKey('wallet-deck-page-$idx'),
                            borderRadius: BorderRadius.circular(22),
                            onTap: () => onSelect(idx),
                            child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Center(
                                    child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  width: idx == current ? 16 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      color: idx == current
                                          ? const Color(0xFF007AFF)
                                          : (dark
                                              ? Colors.white38
                                              : Colors.black26)),
                                )))))),
              const SizedBox(width: 4),
              arrow('Ví tiếp theo', Icons.chevron_right_rounded, 1),
            ]),
          ]));
    });
  }
}
