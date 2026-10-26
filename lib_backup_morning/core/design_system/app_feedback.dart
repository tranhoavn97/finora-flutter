import 'package:flutter/services.dart';

/// Centralized haptic feedback helper for subtle micro-interactions.
/// Ensures consistent tactile response throughout the luxury UI experience.
class AppFeedback {
  AppFeedback._();

  /// Very light tick for tab changes, chips, segmented controls, or small toggles.
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Light impact for pressing primary buttons, cards, or FAB.
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact for completing a critical action like saving a transaction.
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact for destructive operations like deleting an account or reset.
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }
}
