import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/global_event.dart';
import '../../logic/blocs/events/events_bloc.dart';
import '../../logic/blocs/events/events_event.dart';
import '../../logic/blocs/events/events_state.dart';
import '../../services/ssh_service.dart';
import '../../services/kml_service.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import '../widgets/cluster_badge.dart';
import '../widgets/severity_badge.dart';
import '../../services/overlay_service.dart';
import '../../core/utils/top_region_helper.dart';
import '../widgets/category_legend.dart';
import '../../services/tts_service.dart';
import '../../core/constants/app_constants.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/gemma_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<EventsBloc, EventsState>(
        builder: (context, state) {
          return Stack(
            children: [
              // ── Map ───────────────────────────────────────
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(20, 0),
                  initialZoom: 2.5,
                  maxZoom: 18,
                  minZoom: 2,
                  backgroundColor: AppTheme.background,
                ),
                children: [
                  // Dark-themed OpenStreetMap tiles
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.liquidgalaxy.global_pulse',
                  ),

                  // Event cluster markers
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 80,
                      size: const Size(60, 60),
                      markers: state.filteredEvents
                          .where(
                            (event) =>
                                event.latitude >= -90 &&
                                event.latitude <=
                                    90 && // coordinates having longitude above 180 or -180 were giving error
                                event.longitude >= -180 &&
                                event.longitude <= 180,
                          )
                          .map((event) => _buildMarker(event))
                          .toList(),
                      builder: (context, markers) =>
                          ClusterBadge(count: markers.length),
                    ),
                  ),
                ],
              ),

              // ── Header ────────────────────────────────────
              Positioned(
                top: 8,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Global Event Map',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryFilters(context, state),
                    const SizedBox(height: 12),

                    const CategoryLegend(),
                  ],
                ),
              ),

              // ── Fly to View on LG Button ──────────────────
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _buildFlyToButton(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Marker _buildMarker(GlobalEvent event) {
    final color = _categoryColor(event.category);
    final size = _sizeForSeverity(event.severity);

    return Marker(
      point: LatLng(event.latitude, event.longitude),
      width: size,
      height: size,
      child: GestureDetector(
        onTap: () {
          context.read<EventsBloc>().add(SelectEvent(event));
          _showEventDetail(context, event);
        },
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: size * 0.4,
              height: size * 0.4,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(BuildContext context, EventsState state) {
    final categories = [
      (null, 'All'),
      (EventCategory.earthquake, 'Earthquakes'),
      (EventCategory.floodStorm, 'Storms'),
      (EventCategory.wildfire, 'Wildfires'),
      (EventCategory.diseaseOutbreak, 'Disease'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((entry) {
          final category = entry.$1;
          final label = entry.$2;
          final isActive = category == null
              ? state.activeCategories.isEmpty
              : state.activeCategories.contains(category);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: isActive,
              onSelected: (selected) {
                if (category == null) {
                  // "All" selected — clear filters
                  context.read<EventsBloc>().add(const FilterByCategory({}));
                } else {
                  final updated = Set<EventCategory>.from(
                    state.activeCategories,
                  );
                  if (selected) {
                    updated.add(category);
                  } else {
                    updated.remove(category);
                  }
                  context.read<EventsBloc>().add(FilterByCategory(updated));
                }
              },
              selectedColor: AppTheme.primary.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                fontSize: 13,
              ),
              backgroundColor: AppTheme.surface,
              side: BorderSide(
                color: isActive
                    ? AppTheme.primary.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFlyToButton(BuildContext context, EventsState state) {
    final ssh = context.watch<SSHService>();

    return ElevatedButton.icon(
      onPressed: () => ssh.isConnected ? _sendToLG(context, state) : null,
      icon: const Icon(Icons.send_rounded, size: 18),
      label: ssh.isConnected
          ? const Text(
              'Fly to View on LG',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            )
          : const Text(
              "Connect to LG First",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
      style: ElevatedButton.styleFrom(
        backgroundColor: ssh.isConnected
            ? AppTheme.primary
            : const Color.fromARGB(255, 96, 96, 96),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  /// Sends the current map view and events to the LG rig.
  Future<void> _sendToLG(BuildContext context, EventsState state) async {
    final ssh = context.read<SSHService>();
    final kml = context.read<KMLService>();
    final tts = context.read<TTSService>();

    if (!ssh.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not connected to LG. Go to Settings to connect.'),
          backgroundColor: AppTheme.severityCritical,
        ),
      );
      return;
    }

    // Generate and send KML
    final kmlContent = kml.generateEventsKML(state.filteredEvents);
    final success = await ssh.sendKML(kmlContent);

    final bounds = _mapController.camera.visibleBounds;
    final visibleEvents = TopRegionHelper.getVisibleEvents(
      state.filteredEvents,
      bounds,
    );

    String overlayKML;

    final gemini = context.read<GemmaService>();
    overlayKML = await OverlayService.generateRegionOverlayKML(
      visibleEvents,
      gemini,
    );

    await ssh.sendOverlayKML(overlayKML);

    // Read TTS setting from Hive
    final box = Hive.box(AppConstants.settingsBox);
    final ttsEnabled = box.get(AppConstants.keyTTSEnabled, defaultValue: true);

    if (ttsEnabled) {
      tts.speakRegionSummary(visibleEvents);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Flying to the location!'
                : 'Failed to fly to the location.',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: success
              ? const Color.fromARGB(255, 12, 109, 50)
              : AppTheme.severityCritical,
        ),
      );
    }

    // Also fly to the current map center
    final center = _mapController.camera.center;
    await ssh.flyTo(
      latitude: center.latitude,
      longitude: center.longitude,
      range: _zoomToRange(_mapController.camera.zoom),
    );
  }

  void _showEventDetail(BuildContext context, GlobalEvent event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(event.title, style: Theme.of(context).textTheme.titleLarge),

              const SizedBox(height: 10),

              Row(
                children: [
                  Chip(
                    label: Text(event.source.name.toUpperCase()),
                    backgroundColor: AppTheme.surface,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      color: Color.fromARGB(255, 238, 238, 238),
                      fontWeight: FontWeight.bold,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),

                  const Spacer(),

                  SeverityBadge(severity: event.severity),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                event.description,
                style: const TextStyle(
                  color: Color.fromARGB(255, 203, 203, 203),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    event.locationName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    event.timeAgo,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final ssh = context.read<SSHService>();

                    final overlayKml = OverlayService.generateEventOverlayKml(
                      event,
                    );

                    await ssh.sendOverlayKML(overlayKml);

                    await ssh.flyTo(
                      latitude: event.latitude,
                      longitude: event.longitude,
                      range: 500000,
                      tilt: 45,
                    );

                    final box = Hive.box(AppConstants.settingsBox);
                    final ttsEnabled = box.get(
                      AppConstants.keyTTSEnabled,
                      defaultValue: true,
                    );
                    if (ttsEnabled && context.mounted) {
                      final tts = context.read<TTSService>();
                      tts.speakEventSummary(event);
                    }
                  },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Fly to on LG'),
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      const Color.fromARGB(255, 209, 17, 3),
                    ),
                  ),
                  onPressed: () async {
                    final ssh = context.read<SSHService>();

                    final overlayKml = OverlayService.generateEventOverlayKml(
                      event,
                    );

                    await ssh.clearoverlayKML(overlayKml);
                  },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Clear Overlay KML'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _categoryColor(EventCategory category) {
    switch (category) {
      case EventCategory.earthquake:
        return AppTheme.earthquakeColor;
      case EventCategory.floodStorm:
        return AppTheme.floodStormColor;
      case EventCategory.wildfire:
        return AppTheme.wildfireColor;
      case EventCategory.diseaseOutbreak:
        return AppTheme.diseaseColor;
      case EventCategory.conflict:
        return AppTheme.conflictColor;
    }
  }

  double _sizeForSeverity(EventSeverity severity) {
    switch (severity) {
      case EventSeverity.critical:
        return 36;
      case EventSeverity.high:
        return 30;
      case EventSeverity.medium:
        return 24;
      case EventSeverity.low:
        return 18;
    }
  }

  /// Converts flutter_map zoom level to a Google Earth range value.
  double _zoomToRange(double zoom) {
    // Rough approximation: GE range ≈ 35000000 / 2^zoom
    return 35000000 / (1 << zoom.round());
  }
}
