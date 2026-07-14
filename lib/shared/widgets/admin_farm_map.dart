import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/enums.dart';
import '../../data/models/farm.dart';
import '../utils/farm_state_resolver.dart';
import '../utils/india_map_projection.dart';
import '../utils/india_states_map_data.dart';
import 'india_political_map_painter.dart';
import 'status_chip.dart';

/// Dashboard-style India choropleth map with farm markers.
class AdminIndiaFarmMap extends StatefulWidget {
  const AdminIndiaFarmMap({
    super.key,
    required this.farms,
    this.onFarmTap,
    this.height,
  });

  final List<Farm> farms;
  final void Function(Farm farm)? onFarmTap;
  /// When null, height is computed from screen size (~46% of viewport).
  final double? height;

  @override
  State<AdminIndiaFarmMap> createState() => _AdminIndiaFarmMapState();
}

class _AdminIndiaFarmMapState extends State<AdminIndiaFarmMap>
    with SingleTickerProviderStateMixin {
  List<IndiaStateShape> _rawStates = [];
  List<IndiaStateShape> _states = [];
  bool _loadingMap = true;
  Farm? _selectedFarm;
  String? _selectedState;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _loadMap();
  }

  Future<void> _loadMap() async {
    final raw = await IndiaStatesMapData.loadRaw();
    if (!mounted) return;
    setState(() {
      _rawStates = raw;
      _loadingMap = false;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Map<String, int> get _stateCounts {
    final counts = <String, int>{};
    for (final farm in widget.farms) {
      final state = FarmStateResolver.resolve(farm);
      if (state == 'Unknown') continue;
      counts[state] = (counts[state] ?? 0) + 1;
    }
    return counts;
  }

  List<Farm> get _plottedFarms => widget.farms
      .where(
        (f) => IndiaMapProjection.hasValidCoords(f.latitude, f.longitude),
      )
      .toList();

  int _count(FarmVisitStatus status) =>
      widget.farms.where((f) => f.status == status).length;

  void _onMapTap(Offset local, Size size) {
    final state = IndiaStatesMapData.stateAt(_states, local);
    setState(() {
      if (state != null) {
        _selectedState = state.name;
        _selectedFarm = null;
      } else {
        _selectedState = null;
        _selectedFarm = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stateCounts = _stateCounts;
    final activeStates = stateCounts.keys.length;
    final screenH = MediaQuery.sizeOf(context).height;
    final mapHeight = widget.height ?? (screenH * 0.46).clamp(400.0, 520.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientBrand,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.map_rounded,
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
                            'Farm Network — India',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Bubbles show farm count by state',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedState != null || _selectedFarm != null)
                      IconButton(
                        onPressed: () => setState(() {
                          _selectedState = null;
                          _selectedFarm = null;
                        }),
                        icon: const Icon(Icons.restart_alt_rounded, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.canvasDeep,
                        ),
                        tooltip: 'Reset view',
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatPill(
                      label: 'Farms',
                      value: '${widget.farms.length}',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    _StatPill(
                      label: 'States',
                      value: '$activeStates',
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    _StatPill(
                      label: 'Pending',
                      value: '${_count(FarmVisitStatus.pending)}',
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    _StatPill(
                      label: 'Done',
                      value: '${_count(FarmVisitStatus.visited)}',
                      color: AppColors.success,
                    ),
                  ],
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
                    isActive: _selectedState == entry.key,
                    onTap: () => setState(() {
                      _selectedState =
                          _selectedState == entry.key ? null : entry.key;
                      _selectedFarm = null;
                    }),
                  );
                },
              ),
            ),
          const SizedBox(height: 6),
          SizedBox(
            height: mapHeight,
            child: _loadingMap
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, mapConstraints) {
                                final paintSize = Size(
                                  mapConstraints.maxWidth,
                                  mapConstraints.maxHeight,
                                );
                                _states =
                                    IndiaStatesMapData.layout(_rawStates, paintSize);

                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    GestureDetector(
                                      onTapDown: (d) => _onMapTap(
                                        d.localPosition,
                                        paintSize,
                                      ),
                                      child: CustomPaint(
                                        size: paintSize,
                                        painter: IndiaChoroplethMapPainter(
                                          states: _states,
                                          countsByState: stateCounts,
                                          selectedState: _selectedState,
                                        ),
                                      ),
                                    ),
                                    ..._buildFarmMarkers(paintSize),
                                    if (_selectedFarm != null)
                                      Positioned(
                                        left: 8,
                                        right: 8,
                                        bottom: 8,
                                        child: _FarmInfoPanel(
                                          farm: _selectedFarm!,
                                          onView: () => widget.onFarmTap
                                              ?.call(_selectedFarm!),
                                          onClose: () => setState(
                                            () => _selectedFarm = null,
                                          ),
                                        ),
                                      )
                                    else if (_selectedState != null)
                                      Positioned(
                                        left: 8,
                                        right: 8,
                                        bottom: 8,
                                        child: _StateFarmsPanel(
                                          state: _selectedState!,
                                          farms: widget.farms
                                              .where(
                                                (f) =>
                                                    FarmStateResolver.resolve(
                                                          f,
                                                        ) ==
                                                    _selectedState,
                                              )
                                              .toList(),
                                          onFarmTap: (farm) {
                                            widget.onFarmTap?.call(farm);
                                          },
                                          onClose: () => setState(
                                            () => _selectedState = null,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const _MapLegendBar(),
                        ],
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms);
  }

  /// Overview: one clear count bubble per state (avoids overlapping pins).
  /// State selected: individual farm pins at coordinates.
  List<Widget> _buildFarmMarkers(Size size) {
    if (_selectedState == null) {
      return _buildStateClusterMarkers(size);
    }
    return _buildIndividualFarmPins(size);
  }

  List<Widget> _buildStateClusterMarkers(Size size) {
    final byState = <String, List<Farm>>{};
    for (final farm in _plottedFarms) {
      final state = FarmStateResolver.resolve(farm);
      if (state == 'Unknown') continue;
      byState.putIfAbsent(state, () => []).add(farm);
    }

    final markers = <Widget>[];
    for (final entry in byState.entries) {
      final farms = entry.value;
      final centroid = _stateShapeCentroid(entry.key) ??
          _averageProjected(farms, size);
      if (centroid == null) continue;

      final pending = farms
          .where((f) => f.status == FarmVisitStatus.pending)
          .length;
      final accent = pending > 0 ? AppColors.error : AppColors.secondary;
      const bubble = 36.0;

      markers.add(
        Positioned(
          left: centroid.dx - bubble / 2,
          top: centroid.dy - bubble / 2,
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedState = entry.key;
              _selectedFarm = null;
            }),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => _StateClusterBadge(
                count: farms.length,
                accent: accent,
                pulse: pending > 0,
                pulseValue: _pulseController.value,
              ),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  List<Widget> _buildIndividualFarmPins(Size size) {
    final markers = <Widget>[];
    for (final farm in _plottedFarms) {
      final state = FarmStateResolver.resolve(farm);
      if (state != _selectedState) continue;

      final offset = IndiaMapProjection.project(
        LatLng(farm.latitude, farm.longitude),
        size,
      );
      final color = _pinColor(farm.status);
      final isSelected = _selectedFarm?.id == farm.id;
      final pulse = farm.status == FarmVisitStatus.pending && !isSelected;
      const pinSize = 28.0;

      markers.add(
        Positioned(
          left: offset.dx - pinSize / 2,
          top: offset.dy - pinSize / 2,
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedFarm = farm;
              _selectedState = state;
            }),
            child: pulse
                ? AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) => _FarmPin(
                      color: color,
                      isSelected: isSelected,
                      pulse: true,
                      pulseValue: _pulseController.value,
                      label: farm.name.isNotEmpty ? farm.name[0] : 'F',
                    ),
                  )
                : _FarmPin(
                    color: color,
                    isSelected: isSelected,
                    pulse: false,
                    pulseValue: 0,
                    label: farm.name.isNotEmpty ? farm.name[0] : 'F',
                  ),
          ),
        ),
      );
    }
    return markers;
  }

  Offset? _stateShapeCentroid(String stateName) {
    for (final shape in _states) {
      if (shape.name == stateName) return shape.centroid;
    }
    return null;
  }

  Offset? _averageProjected(List<Farm> farms, Size size) {
    if (farms.isEmpty) return null;
    var x = 0.0;
    var y = 0.0;
    for (final farm in farms) {
      final p = IndiaMapProjection.project(
        LatLng(farm.latitude, farm.longitude),
        size,
      );
      x += p.dx;
      y += p.dy;
    }
    return Offset(x / farms.length, y / farms.length);
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

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapLegendBar extends StatelessWidget {
  const _MapLegendBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F5F0),
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tap a bubble to open farms in that state',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _legendDot(AppColors.error, 'Pending'),
              const SizedBox(width: 10),
              _legendDot(AppColors.info, 'Ongoing'),
              const SizedBox(width: 10),
              _legendDot(AppColors.success, 'Done'),
              const SizedBox(width: 10),
              _legendDot(AppColors.secondary, 'Harvest'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Clear count bubble for overview mode (one per state).
class _StateClusterBadge extends StatelessWidget {
  const _StateClusterBadge({
    required this.count,
    required this.accent,
    required this.pulse,
    required this.pulseValue,
  });

  final int count;
  final Color accent;
  final bool pulse;
  final double pulseValue;

  @override
  Widget build(BuildContext context) {
    final ring = pulse ? 4.0 + pulseValue * 6 : 0.0;

    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (pulse)
            Container(
              width: 34 + ring,
              height: 34 + ring,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.18 * (1 - pulseValue)),
              ),
            ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent,
                  Color.lerp(accent, Colors.black, 0.18)!,
                ],
              ),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 6,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                height: 1,
                shadows: [
                  Shadow(
                    color: Colors.black38,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmPin extends StatelessWidget {
  const _FarmPin({
    required this.color,
    required this.isSelected,
    required this.pulse,
    required this.pulseValue,
    required this.label,
  });

  final Color color;
  final bool isSelected;
  final bool pulse;
  final double pulseValue;
  final String label;

  @override
  Widget build(BuildContext context) {
    final size = isSelected ? 30.0 : 26.0;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (pulse)
          Container(
            width: size + pulseValue * 8,
            height: size + pulseValue * 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16 * (1 - pulseValue)),
            ),
          ),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: Colors.white,
              width: isSelected ? 3 : 2.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: isSelected ? 8 : 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: isSelected ? 12 : 11,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({
    required this.state,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final String state;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}

class _StateFarmsPanel extends StatelessWidget {
  const _StateFarmsPanel({
    required this.state,
    required this.farms,
    required this.onFarmTap,
    required this.onClose,
  });

  final String state;
  final List<Farm> farms;
  final ValueChanged<Farm> onFarmTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
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
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$state — ${farms.length} farm(s)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
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
            const SizedBox(height: 8),
            ...farms.take(3).map(
                  (farm) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.secondaryMuted,
                      child: Text(
                        farm.name.isNotEmpty ? farm.name[0] : 'F',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    title: Text(
                      farm.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(farm.location),
                    trailing: StatusChip(status: farm.status),
                    onTap: () => onFarmTap(farm),
                  ),
                ),
          ],
        ),
      ),
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
    final state = FarmStateResolver.resolve(farm);

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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        farm.name,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
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
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    farm.location,
                    style: Theme.of(context).textTheme.bodySmall,
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
    );
  }
}
