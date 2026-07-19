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
    with TickerProviderStateMixin {
  List<IndiaStateShape> _rawStates = [];
  List<IndiaStateShape> _states = [];
  bool _loadingMap = true;
  Farm? _selectedFarm;
  String? _selectedState;
  late final AnimationController _pulseController;
  late final AnimationController _zoomAnim;
  final TransformationController _transform = TransformationController();
  Size _viewportSize = Size.zero;
  ScrollHoldController? _scrollHold;
  double _scale = 1.0;
  static const _minScale = 0.85;
  static const _maxScale = 10.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _zoomAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _transform.addListener(_onTransformChanged);
    _loadMap();
  }

  void _onTransformChanged() {
    final next = _transform.value.getMaxScaleOnAxis();
    if ((next - _scale).abs() < 0.02) return;
    setState(() => _scale = next);
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
    _scrollHold?.cancel();
    _transform.removeListener(_onTransformChanged);
    _pulseController.dispose();
    _zoomAnim.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _holdParentScroll() {
    _scrollHold?.cancel();
    final position = Scrollable.maybeOf(context)?.position;
    if (position == null || !position.hasPixels) return;
    _scrollHold = position.hold(() {});
  }

  void _releaseParentScroll() {
    _scrollHold?.cancel();
    _scrollHold = null;
  }

  /// Smooth zoom centered on the middle of the visible map.
  void _zoomBy(double factor) {
    if (_viewportSize == Size.zero) return;
    final begin = Matrix4.copy(_transform.value);
    final currentScale = begin.getMaxScaleOnAxis();
    final nextScale = (currentScale * factor).clamp(_minScale, _maxScale);
    if ((nextScale - currentScale).abs() < 0.01) return;

    final ratio = nextScale / currentScale;
    final focal = _transform.toScene(
      Offset(_viewportSize.width / 2, _viewportSize.height / 2),
    );
    final end = Matrix4.copy(begin)
      ..translateByDouble(focal.dx, focal.dy, 0, 1)
      ..scaleByDouble(ratio, ratio, ratio, 1)
      ..translateByDouble(-focal.dx, -focal.dy, 0, 1);

    _zoomAnim.stop();
    final animation = Matrix4Tween(begin: begin, end: end).animate(
      CurvedAnimation(parent: _zoomAnim, curve: Curves.easeOutCubic),
    );
    void tick() => _transform.value = animation.value;
    animation.addListener(tick);
    _zoomAnim.forward(from: 0).whenComplete(() {
      animation.removeListener(tick);
    });
  }

  void _resetZoom() {
    _zoomAnim.stop();
    _transform.value = Matrix4.identity();
    setState(() {
      _scale = 1.0;
      _selectedState = null;
      _selectedFarm = null;
    });
  }

  void _openFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => IndiaFarmMapFullscreenPage(
          farms: widget.farms,
          onFarmTap: widget.onFarmTap,
        ),
      ),
    );
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

  List<Farm> get _plottedFarms {
    final withCoords = widget.farms
        .where(
          (f) => IndiaMapProjection.hasValidCoords(f.latitude, f.longitude),
        )
        .toList();
    if (withCoords.isNotEmpty) return withCoords;
    // Fallback: still show farms we can place via state centroid.
    return widget.farms
        .where((f) => FarmStateResolver.resolve(f) != 'Unknown')
        .toList();
  }

  Offset? _pinOffset(Farm farm, Size size, int index) {
    if (IndiaMapProjection.hasValidCoords(farm.latitude, farm.longitude)) {
      return IndiaMapProjection.project(
        LatLng(farm.latitude, farm.longitude),
        size,
      );
    }
    final stateName = FarmStateResolver.resolve(farm);
    IndiaStateShape? shape;
    for (final s in _states) {
      if (s.name == stateName) {
        shape = s;
        break;
      }
    }
    if (shape == null || shape.centroid == Offset.zero) return null;
    // Slight jitter so stacked farms remain distinguishable.
    final jitter = (index % 7) - 3;
    return shape.centroid + Offset(jitter * 4.0, ((index ~/ 7) % 5 - 2) * 4.0);
  }

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
    final mapHeight = widget.height ?? (screenH * 0.58).clamp(460.0, 640.0);

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
                            _plottedFarms.isEmpty
                                ? 'Pinch to zoom · drag to pan · tap states'
                                : 'Pinch to zoom in on farms · ${_plottedFarms.length} locations',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _openFullscreen,
                      icon: const Icon(Icons.fullscreen_rounded, size: 22),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                      ),
                      tooltip: 'Full screen map',
                    ),
                    if (_selectedState != null ||
                        _selectedFarm != null ||
                        _scale > 1.05)
                      IconButton(
                        onPressed: _resetZoom,
                        icon: const Icon(Icons.restart_alt_rounded, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.canvasDeep,
                        ),
                        tooltip: 'Reset view',
                      ),
                  ],
                ),
                const SizedBox(height: 8),
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
                                _viewportSize = paintSize;
                                _states = IndiaStatesMapData.layout(
                                  _rawStates,
                                  paintSize,
                                );

                                return Stack(
                                  clipBehavior: Clip.hardEdge,
                                  children: [
                                    Listener(
                                      behavior: HitTestBehavior.opaque,
                                      onPointerDown: (_) => _holdParentScroll(),
                                      onPointerUp: (_) =>
                                          _releaseParentScroll(),
                                      onPointerCancel: (_) =>
                                          _releaseParentScroll(),
                                      child: InteractiveViewer(
                                        transformationController: _transform,
                                        minScale: _minScale,
                                        maxScale: _maxScale,
                                        constrained: false,
                                        clipBehavior: Clip.hardEdge,
                                        panEnabled: true,
                                        scaleEnabled: true,
                                        trackpadScrollCausesScale: true,
                                        boundaryMargin:
                                            const EdgeInsets.all(280),
                                        onInteractionStart: (_) =>
                                            _holdParentScroll(),
                                        onInteractionEnd: (_) =>
                                            _releaseParentScroll(),
                                        child: SizedBox(
                                          width: paintSize.width,
                                          height: paintSize.height,
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              GestureDetector(
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                onTapDown: (d) => _onMapTap(
                                                  d.localPosition,
                                                  paintSize,
                                                ),
                                                child: CustomPaint(
                                                  size: paintSize,
                                                  painter:
                                                      IndiaChoroplethMapPainter(
                                                    states: _states,
                                                    countsByState: stateCounts,
                                                    selectedState:
                                                        _selectedState,
                                                  ),
                                                ),
                                              ),
                                              ..._buildFarmMarkers(paintSize),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 10,
                                      top: 10,
                                      child: Column(
                                        children: [
                                          _ZoomButton(
                                            icon: Icons.add_rounded,
                                            onTap: () => _zoomBy(1.35),
                                          ),
                                          const SizedBox(height: 6),
                                          _ZoomButton(
                                            icon: Icons.remove_rounded,
                                            onTap: () => _zoomBy(1 / 1.35),
                                          ),
                                          const SizedBox(height: 6),
                                          _ZoomButton(
                                            icon: Icons.fullscreen_rounded,
                                            onTap: _openFullscreen,
                                          ),
                                        ],
                                      ),
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
                                          color: Colors.white.withValues(
                                            alpha: 0.92,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: AppColors.borderSubtle,
                                          ),
                                        ),
                                        child: Text(
                                          '${_scale.toStringAsFixed(1)}×',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
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

  /// Farm pins always visible; state filter narrows pins when selected.
  List<Widget> _buildFarmMarkers(Size size) {
    return _buildIndividualFarmPins(size);
  }

  List<Widget> _buildIndividualFarmPins(Size size) {
    // Cluster less as the user zooms in so individual farms appear smoothly.
    final cell = _scale >= 3.2
        ? 4.0
        : _scale >= 2.0
            ? 8.0
            : _scale >= 1.35
                ? 12.0
                : 18.0;

    final clusters = <String, List<({Farm farm, Offset offset})>>{};
    var index = 0;
    for (final farm in _plottedFarms) {
      if (_selectedState != null) {
        final state = FarmStateResolver.resolve(farm);
        if (state != _selectedState) continue;
      }
      final offset = _pinOffset(farm, size, index);
      index++;
      if (offset == null) continue;
      final key =
          '${(offset.dx / cell).round()}_${(offset.dy / cell).round()}';
      clusters.putIfAbsent(key, () => []).add((farm: farm, offset: offset));
    }

    final markers = <Widget>[];
    for (final group in clusters.values) {
      final lead = group.first;
      final farm = lead.farm;
      // Spread stacked farms slightly when zoomed in.
      Offset offset = lead.offset;
      if (group.length > 1 && _scale >= 2.0) {
        var sx = 0.0;
        var sy = 0.0;
        for (final g in group) {
          sx += g.offset.dx;
          sy += g.offset.dy;
        }
        offset = Offset(sx / group.length, sy / group.length);
      }
      final color = _pinColor(farm.status);
      final isSelected = group.any((g) => g.farm.id == _selectedFarm?.id);
      final pulse =
          farm.status == FarmVisitStatus.pending && !isSelected;
      final pinSize = _scale >= 2.5 ? 30.0 : 36.0;
      final state = FarmStateResolver.resolve(farm);
      final count = group.length;

      markers.add(
        Positioned(
          left: offset.dx - pinSize / 2,
          top: offset.dy - pinSize,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (count > 1 && _scale < 2.2) {
                // Zoom into the cluster so farms separate.
                _zoomBy(1.8);
                setState(() {
                  _selectedFarm = null;
                  _selectedState = state == 'Unknown' ? null : state;
                });
                return;
              }
              setState(() {
                _selectedFarm = farm;
                _selectedState = state == 'Unknown' ? null : state;
              });
            },
            child: pulse
                ? AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) => _FarmPin(
                      color: color,
                      isSelected: isSelected,
                      pulse: true,
                      pulseValue: _pulseController.value,
                      label: count > 1
                          ? '$count'
                          : (farm.name.isNotEmpty ? farm.name[0] : 'F'),
                    ),
                  )
                : _FarmPin(
                    color: color,
                    isSelected: isSelected,
                    pulse: false,
                    pulseValue: 0,
                    label: count > 1
                        ? '$count'
                        : (farm.name.isNotEmpty ? farm.name[0] : 'F'),
                  ),
          ),
        ),
      );
    }
    return markers;
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
            'Pinch to zoom · drag to pan · tap a pin for farm details',
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
    final size = isSelected ? 36.0 : 32.0;

    return SizedBox(
      width: size,
      height: size + 6,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          if (pulse)
            Positioned(
              top: 0,
              child: Container(
                width: size + pulseValue * 10,
                height: size + pulseValue * 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.22 * (1 - pulseValue)),
                ),
              ),
            ),
          Icon(
            Icons.location_on_rounded,
            size: size,
            color: color,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          Positioned(
            top: size * 0.22,
            child: Container(
              width: size * 0.42,
              height: size * 0.42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: color,
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: isSelected ? 10 : 9,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
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

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: AppColors.shadowLight,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 22, color: AppColors.primaryDark),
        ),
      ),
    );
  }
}

/// Full-screen India map — pinch/pan works reliably outside the dashboard scroll.
class IndiaFarmMapFullscreenPage extends StatefulWidget {
  const IndiaFarmMapFullscreenPage({
    super.key,
    required this.farms,
    this.onFarmTap,
  });

  final List<Farm> farms;
  final void Function(Farm farm)? onFarmTap;

  @override
  State<IndiaFarmMapFullscreenPage> createState() =>
      _IndiaFarmMapFullscreenPageState();
}

class _IndiaFarmMapFullscreenPageState extends State<IndiaFarmMapFullscreenPage>
    with TickerProviderStateMixin {
  List<IndiaStateShape> _rawStates = [];
  List<IndiaStateShape> _states = [];
  bool _loading = true;
  Farm? _selectedFarm;
  final TransformationController _transform = TransformationController();
  late final AnimationController _pulse;
  late final AnimationController _zoomAnim;
  Size _viewportSize = Size.zero;
  double _scale = 1.0;
  static const _minScale = 0.85;
  static const _maxScale = 12.0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _zoomAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _transform.addListener(() {
      final next = _transform.value.getMaxScaleOnAxis();
      if ((next - _scale).abs() < 0.02) return;
      setState(() => _scale = next);
    });
    _load();
  }

  Future<void> _load() async {
    final raw = await IndiaStatesMapData.loadRaw();
    if (!mounted) return;
    setState(() {
      _rawStates = raw;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _zoomAnim.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _zoomBy(double factor) {
    if (_viewportSize == Size.zero) return;
    final begin = Matrix4.copy(_transform.value);
    final currentScale = begin.getMaxScaleOnAxis();
    final nextScale = (currentScale * factor).clamp(_minScale, _maxScale);
    if ((nextScale - currentScale).abs() < 0.01) return;
    final ratio = nextScale / currentScale;
    final focal = _transform.toScene(
      Offset(_viewportSize.width / 2, _viewportSize.height / 2),
    );
    final end = Matrix4.copy(begin)
      ..translateByDouble(focal.dx, focal.dy, 0, 1)
      ..scaleByDouble(ratio, ratio, ratio, 1)
      ..translateByDouble(-focal.dx, -focal.dy, 0, 1);
    _zoomAnim.stop();
    final animation = Matrix4Tween(begin: begin, end: end).animate(
      CurvedAnimation(parent: _zoomAnim, curve: Curves.easeOutCubic),
    );
    void tick() => _transform.value = animation.value;
    animation.addListener(tick);
    _zoomAnim.forward(from: 0).whenComplete(() {
      animation.removeListener(tick);
    });
  }

  List<Farm> get _plotted {
    final withCoords = widget.farms
        .where(
          (f) => IndiaMapProjection.hasValidCoords(f.latitude, f.longitude),
        )
        .toList();
    if (withCoords.isNotEmpty) return withCoords;
    return widget.farms
        .where((f) => FarmStateResolver.resolve(f) != 'Unknown')
        .toList();
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

  Widget _fullscreenPin({required Farm farm, required Offset offset}) {
    final selected = _selectedFarm?.id == farm.id;
    return Positioned(
      left: offset.dx - 16,
      top: offset.dy - 32,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedFarm = farm),
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => _FarmPin(
            color: _pinColor(farm.status),
            isSelected: selected,
            pulse: farm.status == FarmVisitStatus.pending && !selected,
            pulseValue: _pulse.value,
            label: farm.name.isNotEmpty ? farm.name[0] : 'F',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final farm in widget.farms) {
      final state = FarmStateResolver.resolve(farm);
      if (state == 'Unknown') continue;
      counts[state] = (counts[state] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: AppColors.canvasDeep,
      appBar: AppBar(
        title: const Text('India farm map'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Zoom out',
            onPressed: () => _zoomBy(0.8),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          IconButton(
            tooltip: 'Zoom in',
            onPressed: () => _zoomBy(1.25),
            icon: const Icon(Icons.add_circle_outline),
          ),
          IconButton(
            tooltip: 'Reset',
            onPressed: () {
              _transform.value = Matrix4.identity();
              setState(() => _selectedFarm = null);
            },
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _zoomBy(0.8),
                          icon: const Icon(Icons.remove_rounded),
                          label: const Text('Zoom out'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _zoomBy(1.25),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Zoom in'),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Pinch with two fingers · drag to pan · ${_plotted.length} farms · ${_scale.toStringAsFixed(1)}×',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      _viewportSize = size;
                      _states = IndiaStatesMapData.layout(_rawStates, size);
                      return Stack(
                        children: [
                          InteractiveViewer(
                            transformationController: _transform,
                            minScale: _minScale,
                            maxScale: _maxScale,
                            constrained: false,
                            panEnabled: true,
                            scaleEnabled: true,
                            trackpadScrollCausesScale: true,
                            boundaryMargin: const EdgeInsets.all(320),
                            child: SizedBox(
                              width: size.width,
                              height: size.height,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CustomPaint(
                                    size: size,
                                    painter: IndiaChoroplethMapPainter(
                                      states: _states,
                                      countsByState: counts,
                                      selectedState: null,
                                    ),
                                  ),
                                  ..._plotted.asMap().entries.map((entry) {
                                    final farm = entry.value;
                                    final offset =
                                        IndiaMapProjection.hasValidCoords(
                                      farm.latitude,
                                      farm.longitude,
                                    )
                                            ? IndiaMapProjection.project(
                                                LatLng(
                                                  farm.latitude,
                                                  farm.longitude,
                                                ),
                                                size,
                                              )
                                            : null;
                                    if (offset == null) {
                                      final stateName =
                                          FarmStateResolver.resolve(farm);
                                      IndiaStateShape? shape;
                                      for (final s in _states) {
                                        if (s.name == stateName) {
                                          shape = s;
                                          break;
                                        }
                                      }
                                      if (shape == null) {
                                        return const SizedBox.shrink();
                                      }
                                      final jitter = (entry.key % 7) - 3;
                                      final o = shape.centroid +
                                          Offset(
                                            jitter * 5.0,
                                            ((entry.key ~/ 7) % 5 - 2) * 5.0,
                                          );
                                      return _fullscreenPin(
                                        farm: farm,
                                        offset: o,
                                      );
                                    }
                                    return _fullscreenPin(
                                      farm: farm,
                                      offset: offset,
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                          if (_selectedFarm != null)
                            Positioned(
                              left: 12,
                              right: 12,
                              bottom: 16,
                              child: _FarmInfoPanel(
                                farm: _selectedFarm!,
                                onView: () {
                                  final farm = _selectedFarm!;
                                  Navigator.of(context).pop();
                                  widget.onFarmTap?.call(farm);
                                },
                                onClose: () =>
                                    setState(() => _selectedFarm = null),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
