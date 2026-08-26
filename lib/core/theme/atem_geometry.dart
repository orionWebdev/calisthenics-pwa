import 'package:flutter/widgets.dart';

// ---------------------------------------------------------------------------
// GEOMETRIE & ABSTÄNDE
// ---------------------------------------------------------------------------

abstract final class AtemRadii {
  static const card = 20.0;
  static const sheet = 28.0;
  static const pill = 30.0;
  static const statBox = 14.0;
  static const iconBox = 10.0;

  static const cardR = BorderRadius.all(Radius.circular(card));
  static const statBoxR = BorderRadius.all(Radius.circular(statBox));
  static const pillR = BorderRadius.all(Radius.circular(pill));
  static const sheetR =
      BorderRadius.vertical(top: Radius.circular(sheet));
}

abstract final class AtemSpacing {
  static const screenPadding = 16.0;
  static const cardPadding = 14.0;
  static const cardGap = 13.0;
  static const gridGap = 11.0;

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}
