import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class FarmMapPreview extends StatelessWidget {
  const FarmMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 160,
    this.onTap,
    this.showOpenInMaps = true,
  });

  final double latitude;
  final double longitude;
  final double height;
  final VoidCallback? onTap;
  final bool showOpenInMaps;

  Future<void> _openInGoogleMaps(BuildContext context) async {
    final lat = latitude.toStringAsFixed(6);
    final lng = longitude.toStringAsFixed(6);
    final label = Uri.encodeComponent('Shine Gold Farm');

    // Prefer https — works with Maps app OR browser (emulator-friendly).
    final candidates = <Uri>[
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
      Uri.parse('https://maps.google.com/?q=$lat,$lng'),
      Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)'),
      Uri.parse('google.navigation:q=$lat,$lng&mode=d'),
    ];

    Object? lastError;
    for (final uri in candidates) {
      try {
        // Do not gate on canLaunchUrl — it often returns false on Android 11+
        // even when launch succeeds after queries are declared.
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      } catch (e) {
        lastError = e;
      }
    }

    // Last resort: in-app browser / platform default.
    try {
      final fallback = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
      final launched = await launchUrl(
        fallback,
        mode: LaunchMode.platformDefault,
      );
      if (launched) return;
    } catch (e) {
      lastError = e;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lastError == null
                ? 'Could not open Google Maps. Install Maps or a browser.'
                : 'Could not open Google Maps ($lastError)',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: height,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(latitude, longitude),
                  initialZoom: 14,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.shinegold.shine_gold',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(latitude, longitude),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.fieldGreen,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showOpenInMaps) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _openInGoogleMaps(context),
            icon: const Icon(Icons.map_rounded, size: 18),
            label: const Text('Open in Google Maps'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: const BorderSide(color: AppColors.secondary),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ],
    );
  }
}
