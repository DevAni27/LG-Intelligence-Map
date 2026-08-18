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
import '../../services/overlay_service.dart';
import '../../core/utils/top_region_helper.dart';
import '../widgets/category_legend.dart';
import '../../services/tts_service.dart';
import '../../core/constants/app_constants.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/gemma_service.dart';
import '../widgets/event_detail_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  bool _showInfoCard = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<EventsBloc, EventsState>(
        builder: (context, state) {
          return Column(
            children: [
              _buildHeader(context, state),

              // Map inside container
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: const LatLng(20, 0),
                                initialZoom: 2.5,
                                maxZoom: 18,
                                minZoom: 2.5,
                                backgroundColor: AppTheme.background,
                                onMapReady: () {
                                  _mapController.move(const LatLng(20, 0), 2.5);
                                },
                                interactionOptions: const InteractionOptions(
                                  flags:
                                      InteractiveFlag.all &
                                      ~InteractiveFlag.rotate,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                                  subdomains: const ['a', 'b', 'c', 'd'],
                                  userAgentPackageName:
                                      'com.liquidgalaxy.global_pulse',
                                  keepBuffer: 0,
                                ),

                                MarkerClusterLayerWidget(
                                  options: MarkerClusterLayerOptions(
                                    maxClusterRadius: 80,
                                    size: const Size(60, 60),
                                    markers: state.filteredEvents
                                        .where(
                                          (event) =>
                                              event.latitude >= -90 &&
                                              event.latitude <= 90 &&
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

                            Positioned(
                              right: 14,
                              bottom: 80,
                              child: _buildRightControls(),
                            ),

                            if (_showInfoCard)
                              Positioned.fill(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _showInfoCard = false),
                                  child: Container(
                                    color: Colors.black.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            if (_showInfoCard)
                              Positioned(
                                top: 8,
                                left: 16,
                                right: 16,
                                child: _buildInfoCard(context),
                              ),

                            Positioned(
                              bottom: 16,
                              left: 16,
                              right: 16,
                              child: _buildFlyToButton(context, state),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, EventsState state) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.background.withValues(alpha: 0.97),
            AppTheme.background.withValues(alpha: 0.85),
            AppTheme.background.withValues(alpha: 0.0),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Global Event Map',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  fontSize: 24,
                ),
              ),
              const Spacer(),
              // Event count badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  '${state.filteredEvents.length} events',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info button
              GestureDetector(
                onTap: () => setState(() => _showInfoCard = !_showInfoCard),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _showInfoCard
                        ? AppTheme.primary.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _showInfoCard
                          ? AppTheme.primary.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 24,
                    color: _showInfoCard
                        ? AppTheme.primary
                        : Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Category filter chips
          _buildCategoryFilters(context, state),
          const SizedBox(height: 16),

          // Category color legend
          const CategoryLegend(),
        ],
      ),
    );
  }

  Widget _buildRightControls() {
    return Column(
      children: [
        // Zoom In
        _buildMapControlButton(
          icon: Icons.add_rounded,
          onTap: () {
            final current = _mapController.camera.zoom;
            if (current < 18) {
              _mapController.move(_mapController.camera.center, current + 1);
            }
          },
        ),
        const SizedBox(height: 6),
        // Zoom Out
        _buildMapControlButton(
          icon: Icons.remove_rounded,
          onTap: () {
            final current = _mapController.camera.zoom;
            if (current > 2.5) {
              // max zoom out limit
              _mapController.move(_mapController.camera.center, current - 1);
            }
          },
        ),
        const SizedBox(height: 10),
        _buildMapControlButton(
          icon: Icons.public_rounded,
          onTap: () {
            _mapController.move(const LatLng(20, 0), 2.5);
          },
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.background.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.8)),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.58,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1421),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.map_outlined,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'How to use the Map',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _showInfoCard = false),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Divider(color: Colors.white.withValues(alpha: 0.07)),
              const SizedBox(height: 12),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoSection(
                        icon: Icons.circle,
                        iconColor: AppTheme.primary,
                        title: 'Event Markers',
                        description:
                            'Each dot on the map represents a real-time global event. '
                            'The color shows the event type and the size shows severity — '
                            'larger dots are more severe.',
                      ),
                      const SizedBox(height: 14),

                      _buildInfoSection(
                        icon: Icons.bubble_chart_rounded,
                        iconColor: const Color(0xFFEAB308),
                        title: 'Cluster Badges',
                        description:
                            'When many events are close together, they group into a numbered badge. '
                            'The badge color shows how many events are inside — '
                            'green = few events, yellow = moderate, orange = many, red = very dense. '
                            'Tap a cluster to zoom in and see individual events.',
                      ),
                      const SizedBox(height: 14),

                      _buildInfoSection(
                        icon: Icons.palette_outlined,
                        iconColor: AppTheme.diseaseColor,
                        title: 'Color Legend',
                        description:
                            'Marker colors represent event types: '
                            'Red = Earthquakes, Blue = Floods & Storms, '
                            'Orange = Wildfires, Purple = Disease Outbreaks',
                      ),
                      const SizedBox(height: 14),

                      _buildInfoSection(
                        icon: Icons.send_rounded,
                        iconColor: AppTheme.primary,
                        title: 'Fly to View on LG',
                        description:
                            'When connected to the Liquid Galaxy rig, tap this button to fly '
                            'the rig\'s camera to your current map view and display an AI-powered '
                            'region summary on the slave screen.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
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
            child: GestureDetector(
              onTap: () {
                if (category == null) {
                  context.read<EventsBloc>().add(const FilterByCategory({}));
                } else {
                  final updated = Set<EventCategory>.from(
                    state.activeCategories,
                  );
                  if (!isActive) {
                    updated.add(category);
                  } else {
                    updated.remove(category);
                  }
                  context.read<EventsBloc>().add(FilterByCategory(updated));
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primary.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? AppTheme.primary.withValues(alpha: 0.45)
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActive) ...[
                      Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: isActive
                            ? AppTheme.primary
                            : Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFlyToButton(BuildContext context, EventsState state) {
    final ssh = context.watch<SSHService>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: ssh.isConnected
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: ElevatedButton.icon(
        onPressed: () => ssh.isConnected ? _sendToLG(context, state) : null,
        icon: Icon(
          ssh.isConnected ? Icons.send_rounded : Icons.wifi_off_rounded,
          size: 22,
        ),
        label: Text(
          ssh.isConnected ? 'Fly to View on LG' : 'Connect to LG First',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: ssh.isConnected
              ? AppTheme.primary
              : Colors.grey.withValues(alpha: 1),
          foregroundColor: ssh.isConnected
              ? Colors.white
              : Colors.white.withValues(alpha: 1),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

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
    try {
      await Future.wait([
        ssh.sendKML(kmlContent),
        ssh.flyTo(
          latitude: _mapController.camera.center.latitude,
          longitude: _mapController.camera.center.longitude,
          range: _zoomToRange(_mapController.camera.zoom),
        ),
      ]);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Flying to location!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color.fromARGB(255, 12, 109, 50),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed: ${e.toString()}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppTheme.severityCritical,
          ),
        );
      }
    }

    final bounds = _mapController.camera.visibleBounds;
    final visibleEvents = TopRegionHelper.getVisibleEvents(
      state.filteredEvents,
      bounds,
    );

    String overlayKML;

    final gemma = context.read<GemmaService>();
    overlayKML = await OverlayService.generateRegionOverlayKML(
      visibleEvents,
      gemma,
    );

    await ssh.sendOverlayKML(overlayKML);

    // Read TTS setting from Hive
    final box = Hive.box(AppConstants.settingsBox);
    final ttsEnabled = box.get(AppConstants.keyTTSEnabled, defaultValue: true);

    if (ttsEnabled) {
      tts.speakRegionSummary(visibleEvents);
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EventDetailSheet(event: event),
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
      default:
        return AppTheme.surface;
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

  double _zoomToRange(double zoom) {
    return 35000000 / (1 << zoom.round());
  }
}
