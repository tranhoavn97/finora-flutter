import 'package:flutter/material.dart';

/// Role-based radii. Legacy aliases stay available during screen migration.
class AppRadius {
  static const double xs = 6, sm = 10, md = 12, lg = 16, xl = 20, xxl = 24;
  static final radiusXS = BorderRadius.circular(xs);
  static final radiusSM = BorderRadius.circular(sm);
  static final radiusMD = BorderRadius.circular(md);
  static final radiusLG = BorderRadius.circular(lg);
  static final radiusXL = BorderRadius.circular(xl);
  static final radiusXXL = BorderRadius.circular(xxl);
  static final button = BorderRadius.circular(12);
  static final input = BorderRadius.circular(12);
  static final card = BorderRadius.circular(16);
  static final modal = BorderRadius.circular(20);
  static const bottomSheet = BorderRadius.vertical(top: Radius.circular(20));
}
