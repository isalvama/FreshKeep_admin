import 'package:flutter/painting.dart';

/// The single series color for every dashboard chart (each chart has one
/// series, so there is no categorical palette).
///
/// Material Teal 600, in the family of the app's teal seed. The theme's own
/// `primary` (#006a60) was rejected: it fails the chroma floor and reads as
/// gray in a chart fill.
///
/// Validated with the dataviz skill's `validate_palette.js` against the card
/// surface the charts sit on (M3 `surfaceContainerLow` for the teal seed,
/// #eff5f2). Re-run it if the theme or card color changes:
///
///   node validate_palette.js "#00897b" --mode light --surface "#eff5f2"
///
///   [PASS] Lightness band         all 1 inside L 0.43–0.77
///   [PASS] Chroma floor           all 1 >= 0.1
///   [PASS] CVD separation         n/a
///   [PASS] Normal-vision floor    n/a
///   [PASS] Contrast vs surface    all 1 >= 3:1   (3.91:1)
///   → ALL CHECKS PASS
const kChartSeriesColor = Color(0xFF00897B);
