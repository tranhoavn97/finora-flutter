import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class TransactionCalculatorSheet extends StatefulWidget {
  final int initialAmount;
  final Color? accentColor;

  const TransactionCalculatorSheet({
    super.key,
    this.initialAmount = 0,
    this.accentColor,
  });

  static Future<int?> show(
    BuildContext context, {
    required int initialAmount,
    Color? accentColor,
  }) async {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionCalculatorSheet(
        initialAmount: initialAmount,
        accentColor: accentColor,
      ),
    );
  }

  @override
  State<TransactionCalculatorSheet> createState() =>
      _TransactionCalculatorSheetState();
}

class _TransactionCalculatorSheetState
    extends State<TransactionCalculatorSheet> {
  String _expression = '';
  double _currentResult = 0;
  bool _justCalculated = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount > 0) {
      _expression = widget.initialAmount.toString();
      _currentResult = widget.initialAmount.toDouble();
    }
  }

  void _onNumber(String val) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_justCalculated) {
        _expression = val;
        _justCalculated = false;
      } else {
        _expression += val;
      }
      _evaluateLive();
    });
  }

  void _onOperator(String op) {
    HapticFeedback.selectionClick();
    setState(() {
      _justCalculated = false;
      if (_expression.isEmpty) {
        if (_currentResult > 0) {
          _expression = _currentResult.toInt().toString() + op;
        } else {
          _expression = '0$op';
        }
        return;
      }

      final lastChar = _expression[_expression.length - 1];
      if ('+−×÷*/-'.contains(lastChar)) {
        // Replace previous operator
        _expression = _expression.substring(0, _expression.length - 1) + op;
      } else {
        _expression += op;
      }
      _evaluateLive();
    });
  }

  void _onClear() {
    HapticFeedback.mediumImpact();
    setState(() {
      _expression = '';
      _currentResult = 0;
      _justCalculated = false;
    });
  }

  void _onBackspace() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_expression.isNotEmpty) {
        _expression = _expression.substring(0, _expression.length - 1);
        _evaluateLive();
      }
    });
  }

  void _onEqual() {
    HapticFeedback.mediumImpact();
    setState(() {
      _evaluateLive();
      if (_currentResult > 0) {
        _expression = _currentResult.toInt().toString();
        _justCalculated = true;
      }
    });
  }

  void _evaluateLive() {
    if (_expression.isEmpty) {
      _currentResult = 0;
      return;
    }

    // Clean operators for math engine
    String clean = _expression
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll(' ', '');

    // Trim trailing operators if incomplete
    while (clean.isNotEmpty && '+-*/'.contains(clean[clean.length - 1])) {
      clean = clean.substring(0, clean.length - 1);
    }

    if (clean.isEmpty) return;

    try {
      final parsed = _MathEngine(clean).parse();
      if (!parsed.isNaN && !parsed.isInfinite && parsed >= 0) {
        _currentResult = parsed;
      }
    } catch (_) {
      // Incomplete formula, keep last result
    }
  }

  void _applyResult() {
    HapticFeedback.heavyImpact();
    _evaluateLive();
    final finalInt = _currentResult.round();
    Navigator.of(context).pop(finalInt);
  }

  static String formatAmountNumber(num val) {
    final intVal = val.round();
    if (intVal == 0) return '0';
    final s = intVal.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(s[i]);
    }
    return intVal < 0 ? '-${buffer.toString()}' : buffer.toString();
  }

  String _formatDisplayExpression(String expr) {
    if (expr.isEmpty) return '0';
    // Format numeric chunks with thousand separators
    final regex = RegExp(r'(\d+)|([+−×÷()\-*/])');
    final matches = regex.allMatches(expr);
    final buffer = StringBuffer();
    for (final m in matches) {
      final chunk = m.group(0)!;
      if (RegExp(r'^\d+$').hasMatch(chunk)) {
        final numVal = int.tryParse(chunk);
        if (numVal != null) {
          buffer.write(formatAmountNumber(numVal));
        } else {
          buffer.write(chunk);
        }
      } else {
        buffer.write(' $chunk ');
      }
    }
    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accentColor ?? const Color(0xFF00866A);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final displayResultInt = _currentResult.round();
    final formattedResult = formatAmountNumber(displayResultInt);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 10, 18, bottomPadding + 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        LucideIcons.calculator,
                        size: 18,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Máy tính giao dịch',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Tính toán & điền trực tiếp vào số tiền',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 12,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white60 : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Display Bento Screen
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Expression line
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(
                        _formatDisplayExpression(_expression),
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Result line
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            formattedResult,
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '₫',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Keypad (4 columns x 5 rows)
              Column(
                children: [
                  // Row 1: C, (, ), ÷
                  Row(
                    children: [
                      _buildKeyBtn(
                        text: 'C',
                        isDark: isDark,
                        textColor: const Color(0xFFE11D48),
                        bgColor: isDark
                            ? const Color(0xFF4C0519).withValues(alpha: 0.35)
                            : const Color(0xFFFFF1F2),
                        onTap: _onClear,
                      ),
                      const SizedBox(width: 8),
                      _buildKeyBtn(
                        text: '(',
                        isDark: isDark,
                        onTap: () => _onNumber('('),
                      ),
                      const SizedBox(width: 8),
                      _buildKeyBtn(
                        text: ')',
                        isDark: isDark,
                        onTap: () => _onNumber(')'),
                      ),
                      const SizedBox(width: 8),
                      _buildKeyBtn(
                        text: '÷',
                        isDark: isDark,
                        textColor: accent,
                        bgColor: accent.withValues(alpha: isDark ? 0.25 : 0.12),
                        onTap: () => _onOperator('÷'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 2: 7, 8, 9, ×
                  Row(
                    children: [
                      _buildKeyBtn(
                        text: '7',
                        isDark: isDark,
                        onTap: () => _onNumber('7'),
                      ),
                      const SizedBox(width: 8),
                      _buildKeyBtn(
                        text: '8',
                        isDark: isDark,
                        onTap: () => _onNumber('8'),
                      ),
                      const SizedBox(width: 8),
                      _buildKeyBtn(
                        text: '9',
                        isDark: isDark,
                        onTap: () => _onNumber('9'),
                      ),
                      const SizedBox(width: 8),
                      _buildKeyBtn(
                        text: '×',
                        isDark: isDark,
                        textColor: accent,
                        bgColor: accent.withValues(alpha: isDark ? 0.25 : 0.12),
                        onTap: () => _onOperator('×'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 3: 4, 5, 6, −
                  Row(
                    children: [
                      _buildKeyBtn(
                        text: '4',
                        isDark: isDark,
                        onTap: () => _onNumber('4'),
                      ),
                      const SizedBox(width: 8),
                      _buildKeyBtn(
                        text: '5',
                        isDark: isDark,
                        onTap: () => _onNumber('5'),
                      ),
                      const SizedBox(width: 8),
                      _buildKeyBtn(
                        text: '6',
                        isDark: isDark,
                        onTap: () => _onNumber('6'),
                      ),
                      const SizedBox(width: 8),
                      _buildKeyBtn(
                        text: '−',
                        isDark: isDark,
                        textColor: accent,
                        bgColor: accent.withValues(alpha: isDark ? 0.25 : 0.12),
                        onTap: () => _onOperator('−'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 4: 1, 2, 3, +
                  Row(
                    children: [
                      _buildKeyBtn(
                        text: '1',
                        isDark: isDark,
                        onTap: () => _onNumber('1'),
                      ),
                      const SizedBox(width: 8),
                      _buildKeyBtn(
                        text: '2',
                        isDark: isDark,
                        onTap: () => _onNumber('2'),
                      ),
                      const SizedBox(width: 8),
                      _buildKeyBtn(
                        text: '3',
                        isDark: isDark,
                        onTap: () => _onNumber('3'),
                      ),
                      const SizedBox(width: 8),
                      _buildKeyBtn(
                        text: '+',
                        isDark: isDark,
                        textColor: accent,
                        bgColor: accent.withValues(alpha: isDark ? 0.25 : 0.12),
                        onTap: () => _onOperator('+'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 5: 0, 000, ⌫, =
                  Row(
                    children: [
                      _buildKeyBtn(
                        text: '0',
                        isDark: isDark,
                        onTap: () => _onNumber('0'),
                      ),
                      const SizedBox(width: 8),
                      _buildKeyBtn(
                        text: '000',
                        isDark: isDark,
                        onTap: () => _onNumber('000'),
                      ),
                      const SizedBox(width: 8),
                      _buildKeyBtn(
                        icon: Icons.backspace_outlined,
                        isDark: isDark,
                        onTap: _onBackspace,
                      ),
                      const SizedBox(width: 8),
                      _buildKeyBtn(
                        text: '=',
                        isDark: isDark,
                        textColor: Colors.white,
                        bgColor: accent,
                        onTap: _onEqual,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Apply Action Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _applyResult,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00866A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text(
                    'Áp dụng kết quả ($formattedResult ₫)',
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyBtn({
    String? text,
    IconData? icon,
    required bool isDark,
    Color? textColor,
    Color? bgColor,
    required VoidCallback onTap,
  }) {
    final effectiveBg = bgColor ??
        (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
    final effectiveText = textColor ??
        (isDark ? Colors.white : const Color(0xFF0F172A));

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: effectiveBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155).withValues(alpha: 0.6)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 20, color: effectiveText)
                  : Text(
                      text ?? '',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: (text?.length ?? 1) > 2 ? 16 : 20,
                        fontWeight: FontWeight.w700,
                        color: effectiveText,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Recursive descent parser for basic math (+, -, *, /, parentheses)
class _MathEngine {
  final String text;
  int _pos = 0;

  _MathEngine(this.text);

  double parse() {
    _pos = 0;
    return _parseExpr();
  }

  double _parseExpr() {
    double left = _parseTerm();
    while (_pos < text.length) {
      final ch = text[_pos];
      if (ch == '+') {
        _pos++;
        left += _parseTerm();
      } else if (ch == '-') {
        _pos++;
        left -= _parseTerm();
      } else {
        break;
      }
    }
    return left;
  }

  double _parseTerm() {
    double left = _parseFactor();
    while (_pos < text.length) {
      final ch = text[_pos];
      if (ch == '*') {
        _pos++;
        left *= _parseFactor();
      } else if (ch == '/') {
        _pos++;
        final div = _parseFactor();
        left = div != 0 ? left / div : 0;
      } else {
        break;
      }
    }
    return left;
  }

  double _parseFactor() {
    if (_pos >= text.length) return 0;
    if (text[_pos] == '+') {
      _pos++;
      return _parseFactor();
    }
    if (text[_pos] == '-') {
      _pos++;
      return -_parseFactor();
    }
    if (text[_pos] == '(') {
      _pos++;
      final res = _parseExpr();
      if (_pos < text.length && text[_pos] == ')') {
        _pos++;
      }
      return res;
    }
    final start = _pos;
    while (_pos < text.length && ('0123456789.'.contains(text[_pos]))) {
      _pos++;
    }
    if (start == _pos) return 0;
    return double.tryParse(text.substring(start, _pos)) ?? 0;
  }
}
