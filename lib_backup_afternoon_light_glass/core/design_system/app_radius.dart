import 'package:flutter/material.dart';

class AppRadius {
  static const double xs = 12.0;
  static const double sm = 18.0;
  static const double md = 24.0;
  static const double lg = 28.0;
  static const double xl = 32.0;
  static const double xxl = 36.0;

  // BorderRadius shortcuts
  static final BorderRadius radiusXS = BorderRadius.circular(xs);
  static final BorderRadius radiusSM = BorderRadius.circular(sm);
  static final BorderRadius radiusMD = BorderRadius.circular(md);
  static final BorderRadius radiusLG = BorderRadius.circular(lg);
  static final BorderRadius radiusXL = BorderRadius.circular(xl);
  static final BorderRadius radiusXXL = BorderRadius.circular(xxl);

  // Button, input, card standard configurations
  static final BorderRadius button = BorderRadius.circular(24.0);
  static final BorderRadius input = BorderRadius.circular(24.0);
  static final BorderRadius card = BorderRadius.circular(lg);
  static final BorderRadius modal = BorderRadius.circular(xl);
  static final BorderRadius bottomSheet = const BorderRadius.only(
    topLeft: Radius.circular(xxl),
    topRight: Radius.circular(xxl),
  );
}
