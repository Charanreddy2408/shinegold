import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/enums.dart';
import '../../data/models/farm.dart';
import 'status_chip.dart';

/// India-only farm map with state-aware pins and tap details.
class AdminIndiaFarmMap extends StatefulWidget {
  const AdminIndiaFarmMap({
    super.key,
    required this.farms,
    this.onFarmTap,
    this.height = 320,
  });

  final List<Farm> farms;
  final void Function(Farm farm)? onFarmTap;
  final double height;

  /// Approximate India mainland — kept for docs / potential future framing.
  static final LatLngBounds indiaBounds = LatLngBounds(
    const LatLng(8.0, 68.05),
    const LatLng(35.7, 97.5),
  );

  @override
  State<AdminIndiaFarmMap> createState() => _AdminIndiaFarmMapState();
}

class _AdminIndiaFarmMapState extends State<AdminIndiaFarmMap>
    with SingleTickerProviderStateMixin {
  Farm? _selected;
  late final AnimationController _pulseController;

  static const _indiaCenter = LatLng(22.5, 79.0);
  static const _indiaZoom = 4.5;

  LatLng _center = _indiaCenter;
  double _zoom = _indiaZoom;
  int _mapEpoch = 0;

  /// Must keep a stable instance — a new MapOptions each build makes
  /// flutter_map re-run options= and assert (issue #1760), especially after
  /// hot reload left a ContainCamera constraint on the controller.
  late MapOptions _mapOptions;

  @override
  void initState() {
    super.initState();
    _mapOptions = _buildOptions(_center, _zoom);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  MapOptions _buildOptions(LatLng center, double zoom) {
    return MapOptions(
      initialCenter: center,
      initialZoom: zoom,
      minZoom: 3.5,
      maxZoom: 12,
      // Explicit — never inherit a stale constraint via hot reload of old fields.
      cameraConstraint: const CameraConstraint.unconstrained(),
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.pinchZoom |
            InteractiveFlag.drag |
            InteractiveFlag.doubleTapZoom |
            InteractiveFlag.flingAnimation,
      ),
      onTap: _onMapTap,
    );
  }

  void _onMapTap(TapPosition _, LatLng __) => _clearSelection();

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _fitIndia() {
    setState(() {
      _selected = null;
      _center = _indiaCenter;
      _zoom = _indiaZoom;
      _mapEpoch++;
      _mapOptions = _buildOptions(_center, _zoom);
    });
  }

  void _selectFarm(Farm farm) {
    setState(() {
      _selected = farm;
      _center = LatLng(farm.latitude, farm.longitude);
      _zoom = 6.0;
      _mapEpoch++;
      _mapOptions = _buildOptions(_center, _zoom);
    });
  }

  void _clearSelection() {
    if (_selected == null) return;
    setState(() => _selected = null);
  }

  int _count(FarmVisitStatus status) =>
      widget.farms.where((f) => f.status == status).length;

  Map<String, int> get _stateCounts {
    final counts = <String, int>{};
    for (final farm in widget.farms) {
      final state = _farmState(farm);
      counts[state] = (counts[state] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final stateCounts = _stateCounts;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientBrand,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.public_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'India Farm Map',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        '${widget.farms.length} farms · ${stateCounts.length} states',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _fitIndia,
                  icon: const Icon(Icons.zoom_out_map_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.canvasDeep,
                  ),
                  tooltip: 'Show full India',
                ),
              ],
            ),
          ),
          if (stateCounts.isNotEmpty)
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: stateCounts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final entry = stateCounts.entries.elementAt(index);
                  return _StateChip(
                    state: entry.key,
                    count: entry.value,
                    isActive: _selected != null &&
                        _farmState(_selected!) == entry.key,
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            height: widget.height,
            child: Stack(
              children: [
                FlutterMap(
                  key: ValueKey('admin-india-map-$_mapEpoch'),
                  options: _mapOptions,
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.shinegold.shine_gold',
                    ),
                    MarkerLayer(
                      markers: [
                        for (var i = 0; i < widget.farms.length; i++)
                          _buildMarker(widget.farms[i], i),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.flag_rounded,
                          size: 14,
                          color: AppColors.primaryDark,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'India',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: _selected != null ? 118 : 12,
                  child: _MapLegend(
                    pending: _count(FarmVisitStatus.pending),
                    ongoing: _count(FarmVisitStatus.ongoing),
                    completed: _count(FarmVisitStatus.visited),
                  ),
                ),
                if (_selected != null)
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: _FarmInfoPanel(
                      farm: _selected!,
                      onView: () => widget.onFarmTap?.call(_selected!),
                      onClose: () => setState(() => _selected = null),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }

  Marker _buildMarker(Farm farm, int index) {
    final color = _pinColor(farm.status);
    final isSelected = _selected?.id == farm.id;
    final stateCode = _stateCode(farm);
    final pulse = farm.status == FarmVisitStatus.pending;

    return Marker(
      point: LatLng(farm.latitude, farm.longitude),
      width: isSelected ? 44 : 32,
      height: isSelected ? 52 : 40,
      child: GestureDetector(
        onTap: () => _selectFarm(farm),
        child: AnimatedScale(
          scale: isSelected ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: pulse && !isSelected
              ? AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 24 + _pulseController.value * 12,
                          height: 24 + _pulseController.value * 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(
                              alpha: 0.22 * (1 - _pulseController.value),
                            ),
                          ),
                        ),
                        child!,
                      ],
                    );
                  },
                  child: _MapPin(
                    color: color,
                    stateCode: stateCode,
                    showLabel: isSelected,
                    index: index,
                  ),
                )
              : _MapPin(
                  color: color,
                  stateCode: stateCode,
                  showLabel: isSelected,
                  index: index,
                ),
        ),
      ),
    );
  }

  Color _pinColor(FarmVisitStatus status) {
    switch (status) {
      case FarmVisitStatus.pending:
        return AppColors.error;
      case FarmVisitStatus.ongoing:
        return AppColors.info;
      case FarmVisitStatus.visited:
        return AppColors.success;
      case FarmVisitStatus.harvested:
        return AppColors.secondary;
      case FarmVisitStatus.blocked:
        return AppColors.textMuted;
    }
  }
}

String _farmState(Farm farm) {
  final parts = farm.location.split(',').map((e) => e.trim()).toList();
  if (parts.length >= 2) return parts.last;
  return farm.location;
}

String _farmCity(Farm farm) {
  final parts = farm.location.split(',').map((e) => e.trim()).toList();
  return parts.isNotEmpty ? parts.first : farm.location;
}

String _stateCode(Farm farm) {
  final state = _farmState(farm);
  const codes = {
    'Maharashtra': 'MH',
    'Kerala': 'KL',
    'Punjab': 'PB',
    'West Bengal': 'WB',
    'Karnataka': 'KA',
    'Tamil Nadu': 'TN',
    'Gujarat': 'GJ',
    'Rajasthan': 'RJ',
    'Uttar Pradesh': 'UP',
    'Madhya Pradesh': 'MP',
    'Andhra Pradesh': 'AP',
    'Telangana': 'TS',
    'Odisha': 'OD',
    'Bihar': 'BR',
    'Haryana': 'HR',
  };
  return codes[state] ?? state.substring(0, state.length.clamp(0, 2)).toUpperCase();
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.color,
    required this.stateCode,
    required this.showLabel,
    required this.index,
  });

  final Color color;
  final String stateCode;
  final bool showLabel;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Container(
            margin: const EdgeInsets.only(bottom: 3),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              stateCode,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        Icon(
          Icons.location_on_rounded,
          color: color,
          size: showLabel ? 34 : 28,
          shadows: [
            Shadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
            ),
          ],
        ),
      ],
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 60 * index), duration: 380.ms)
        .scale(
          begin: const Offset(0, 0),
          end: const Offset(1, 1),
          delay: Duration(milliseconds: 60 * index),
          curve: Curves.easeOutBack,
        );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({
    required this.state,
    required this.count,
    required this.isActive,
  });

  final String state;
  final int count;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.canvasDeep,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.borderSubtle,
        ),
      ),
      child: Text(
        '$state ($count)',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.primaryDark : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({
    required this.pending,
    required this.ongoing,
    required this.completed,
  });

  final int pending;
  final int ongoing;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendRow(AppColors.error, 'Pending', pending),
          const SizedBox(height: 4),
          _legendRow(AppColors.info, 'Ongoing', ongoing),
          const SizedBox(height: 4),
          _legendRow(AppColors.success, 'Done', completed),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _FarmInfoPanel extends StatelessWidget {
  const _FarmInfoPanel({
    required this.farm,
    required this.onView,
    required this.onClose,
  });

  final Farm farm;
  final VoidCallback onView;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final state = _farmState(farm);
    final city = _farmCity(farm);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientBrand,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _stateCode(farm),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                      ),
                      Text(
                        city,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        farm.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _infoChip(Icons.grass_rounded, farm.crop),
                const SizedBox(width: 8),
                _infoChip(Icons.square_foot_rounded, '${farm.totalAcres} ac'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Executive: ${farm.assignedExecutiveName}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusChip(status: farm.status),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onView,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.canvasDeep,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'View Farm Details',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.canvasDeep,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.secondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
