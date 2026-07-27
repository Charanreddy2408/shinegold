/// Acreage always renders to two decimals.
///
/// Boundary polygons produce values like 3.9584887807792346, and several
/// screens either printed that raw or rounded to one decimal — so the same
/// farm read differently depending on where you looked at it.
String formatAcres(double acres) => acres.toStringAsFixed(2);

/// Acreage with the unit suffix, e.g. "3.96 ac".
String formatAcresShort(double acres) => '${formatAcres(acres)} ac';

/// Acreage with the full word, e.g. "3.96 acres".
String formatAcresLong(double acres) => '${formatAcres(acres)} acres';
