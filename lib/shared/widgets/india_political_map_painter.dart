import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../utils/india_map_projection.dart';
import '../utils/india_states_map_data.dart';

/// Choropleth political map of India — states shaded by farm density.
class IndiaChoroplethMapPainter extends CustomPainter {
  IndiaChoroplethMapPainter({
    required this.states,
    required this.countsByState,
    this.selectedState,
    this.highlightedState,
  });

  final List<IndiaStateShape> states;
  final Map<String, int> countsByState;
  final String? selectedState;
  final String? highlightedState;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = IndiaMapProjection.layoutFor(size);
    final mapRect = layout.rect;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF7F9FC),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        mapRect.inflate(6),
        const Radius.circular(14),
      ),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        mapRect.inflate(6),
        const Radius.circular(14),
      ),
      Paint()
        ..color = AppColors.borderSubtle
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(mapRect, const Radius.circular(10)),
    );
    canvas.drawRect(
      mapRect,
      Paint()..color = const Color(0xFFFAFCF8),
    );

    for (final state in states) {
      final count = countsByState[state.name] ?? 0;
      final isSelected = state.name == selectedState;
      final isHighlight = state.name == highlightedState;
      final fill = IndiaStatesMapData.colorForCount(
        count,
        selected: isSelected || isHighlight,
      );

      canvas.drawPath(
        state.path,
        Paint()
          ..color = fill
          ..style = PaintingStyle.fill,
      );

      canvas.drawPath(
        state.path,
        Paint()
          ..color = isSelected
              ? AppColors.primaryDark
              : const Color(0xFFD8DED4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 1.8 : 0.65,
      );

      // Counts are shown as cluster badges in the overlay — avoid faint
      // floating numerals that clash with farm markers.
    }

    final border = ui.Path();
    for (final state in states) {
      border.addPath(state.path, Offset.zero);
    }
    canvas.drawPath(
      border,
      Paint()
        ..color = AppColors.primaryDark.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant IndiaChoroplethMapPainter oldDelegate) =>
      oldDelegate.states != states ||
      oldDelegate.countsByState != countsByState ||
      oldDelegate.selectedState != selectedState ||
      oldDelegate.highlightedState != highlightedState;
}
