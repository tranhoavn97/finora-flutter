import 'dart:async';
import 'package:flutter/material.dart';

class FinoraSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final String? initialValue;
  final EdgeInsetsGeometry? margin;
  final bool autofocus;

  const FinoraSearchBar({
    super.key,
    String? hintText,
    String? hint,
    required this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.initialValue,
    this.margin,
    this.autofocus = false,
  }) : hintText = hint ?? hintText ?? 'Tìm kiếm...';

  @override
  State<FinoraSearchBar> createState() => _FinoraSearchBarState();
}

class _FinoraSearchBarState extends State<FinoraSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void didUpdateWidget(covariant FinoraSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != null && widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChange(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        widget.onChanged(val.trim());
      }
    });
    setState(() {}); // Rebuild for clear button visibility
  }

  void _clear() {
    _controller.clear();
    _debounceTimer?.cancel();
    widget.onChanged('');
    widget.onClear?.call();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF1F5F9);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final hintColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      height: 44,
      margin: widget.margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search_rounded, color: hintColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: widget.autofocus,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: textColor,
                letterSpacing: -0.2,
              ),
              cursorColor: const Color(0xFF007AFF),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: hintColor,
                ),
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: _onTextChange,
              onSubmitted: widget.onSubmitted,
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _clear,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                ),
              ),
            )
          else
            const SizedBox(width: 6),
        ],
      ),
    );
  }
}
