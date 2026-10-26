import 'package:flutter/material.dart';
import '../../features/ai/ai_advisor_screen.dart';

class AiContextButton extends StatelessWidget {
  final String userId, screen;
  final double size;
  const AiContextButton({
    super.key,
    required this.userId,
    required this.screen,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: 'Hỏi AI về $screen',
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                AiAdvisorScreen(userId: userId, screenContext: screen),
          ),
        ),
        borderRadius: BorderRadius.circular(100),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.08 : 0.05),
            shape: BoxShape.circle,
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.10 : 0.08),
              width: 0.8,
            ),
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: size * 0.5,
            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
          ),
        ),
      ),
    );
  }
}
