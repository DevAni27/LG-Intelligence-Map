import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lg_world_intelligence_map/core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/global_event.dart';
import '../../logic/blocs/events/events_bloc.dart';
import '../../logic/blocs/events/events_state.dart';
import '../../services/ssh_service.dart';
import '../../services/overlay_service.dart';
import '../../services/tts_service.dart';
import '../../data/sources/usgs_service.dart';
import '../../data/sources/nasa_eonet_service.dart';
import '../widgets/severity_badge.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/kml_service.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  // Date range
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  // category filter of events
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Earthquakes', 'Disasters'];

  List<GlobalEvent> _historicalEvents = [];
  bool _isLoading = false;
  String? _errorMessage;

  bool _isPlaying = false;
  int _currentIndex = 0;
  double _playbackSpeed = 1.0;
  Timer? _timer;

  final USGSService _usgsService = USGSService();
  final NASAEonetService _nasaService = NASAEonetService();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historical Timeline',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Replay global events through time',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    label: 'Start',
                    date: _startDate,
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.arrow_forward,
                    color: AppTheme.textTertiary,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: _buildDateButton(
                    label: 'End',
                    date: _endDate,
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _selectedCategory = category);
                      },
                      selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                      backgroundColor: AppTheme.surface,
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.primary.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _fetchEvents,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search, size: 18),
                label: Text(_isLoading ? 'Fetching...' : 'Fetch Events'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppTheme.severityCritical,
                  fontSize: 13,
                ),
              ),
            ),

          const SizedBox(height: 16),

          if (_historicalEvents.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildPlaybackControls(),
            ),
            const SizedBox(height: 16),
          ],

          Expanded(
            child: _historicalEvents.isEmpty && !_isLoading
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _historicalEvents.length,
                    itemBuilder: (context, index) {
                      final event = _historicalEvents[index];
                      final isCurrent = index == _currentIndex && _isPlaying;
                      return _buildEventRow(event, index, isCurrent);
                    },
                  ),
          ),

          if (_historicalEvents.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isPlaying ? null : _startPlayback,
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Replay on LG Rig'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Event ${_currentIndex + 1} of ${_historicalEvents.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              // Speed selector
              Row(
                children: [1.0, 2.0, 5.0].map((speed) {
                  final isSelected = _playbackSpeed == speed;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _playbackSpeed = speed);
                      if (_isPlaying) {
                        _pausePlayback();
                        _startPlayback();
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : AppTheme.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${speed.toInt()}x',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Play/Pause/Stop buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _stopPlayback,
                icon: const Icon(Icons.stop_rounded),
                color: AppTheme.textSecondary,
                iconSize: 28,
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _isPlaying ? _pausePlayback : _startPlayback,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventRow(GlobalEvent event, int index, bool isCurrent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppTheme.primary.withValues(alpha: 0.15)
            : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent
              ? AppTheme.primary.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _categoryColor(event.category),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${event.locationName} · ${event.timestamp.day}/${event.timestamp.month}/${event.timestamp.year}',
                  style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          SeverityBadge(severity: event.severity),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppTheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a date range and fetch events',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
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

  Future<void> _fetchEvents() async {
    if (_startDate.isAfter(_endDate)) {
      setState(() => _errorMessage = 'Start date must be before end date.');
      return;
    }

    if (_endDate.difference(_startDate).inDays > 30) {
      setState(() => _errorMessage = 'Date range cannot exceed 30 days.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _historicalEvents = [];
      _currentIndex = 0;
    });

    try {
      List<GlobalEvent> usgsEvents = [];
      List<GlobalEvent> nasaEvents = [];

      if (_selectedCategory == 'All' || _selectedCategory == 'Earthquakes') {
        usgsEvents = await _usgsService.fetchHistoricalEarthquakes(
          startTime: _startDate,
          endTime: _endDate,
          minMagnitude: 5.0,
        );
      }

      if (_selectedCategory == 'All' || _selectedCategory == 'Disasters') {
        nasaEvents = await _nasaService.fetchHistoricalEvents(
          startTime: _startDate,
          endTime: _endDate,
        );
      }

      List<GlobalEvent> finalEvents = [];

      if (_selectedCategory == 'All') {
        final significantEarthquakes = usgsEvents
            .where(
              (e) =>
                  e.severity == EventSeverity.high ||
                  e.severity == EventSeverity.critical,
            )
            .take(10)
            .toList();

        final allDisasters = nasaEvents.take(10).toList();

        finalEvents = [...significantEarthquakes, ...allDisasters];
      } else if (_selectedCategory == 'Earthquakes') {
        final significant = usgsEvents
            .where(
              (e) =>
                  e.severity == EventSeverity.high ||
                  e.severity == EventSeverity.critical,
            )
            .toList();
        finalEvents = significant.isNotEmpty
            ? significant.take(20).toList()
            : usgsEvents.take(20).toList();
      } else if (_selectedCategory == 'Disasters') {
        finalEvents = nasaEvents.take(20).toList();
      }

      finalEvents.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      setState(() {
        _historicalEvents = finalEvents;
        _isLoading = false;
        _errorMessage = finalEvents.isEmpty
            ? 'No events found for this date range.'
            : null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch events: ${e.toString()}';
      });
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              surface: AppTheme.cardColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _startPlayback() {
    if (_historicalEvents.isEmpty) return;

    final ssh = context.read<SSHService>();
    if (!ssh.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not connected to LG Rig'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final kml = context.read<KMLService>();
    final kmlContent = kml.generateEventsKML(_historicalEvents);
    ssh.sendKML(kmlContent); // fire and forget — no await needed

    setState(() {
      _isPlaying = true;
      _currentIndex = 0; // always start from beginning
    });

    _flytoEvent(_historicalEvents[0]);

    final seconds = _playbackSpeed == 5.0
        ? 3
        : _playbackSpeed == 2.0
        ? 6
        : 10;

    _timer = Timer.periodic(Duration(seconds: seconds), (timer) async {
      final nextIndex = _currentIndex + 1;
      if (nextIndex >= _historicalEvents.length) {
        _stopPlayback();
        return;
      }
      setState(() => _currentIndex = nextIndex);
      await _flytoEvent(_historicalEvents[nextIndex]);
    });
  }

  void _pausePlayback() {
    _timer?.cancel();
    context.read<TTSService>().stop();
    setState(() => _isPlaying = false);
  }

  void _stopPlayback() {
    _timer?.cancel();

    final ssh = context.read<SSHService>();
    final tts = context.read<TTSService>();

    tts.stop();

    if (ssh.isConnected) {
      ssh.clearKML();
      ssh.clearoverlayKML('');
    }

    setState(() {
      _isPlaying = false;
      _currentIndex = 0;
    });
  }

  Future<void> _flytoEvent(GlobalEvent event) async {
    final ssh = context.read<SSHService>();
    if (!ssh.isConnected) return;

    await Future.wait([
      ssh.flyTo(
        latitude: event.latitude,
        longitude: event.longitude,
        range: 500000,
        tilt: 45,
      ),
      ssh.sendOverlayKML(OverlayService.generateEventOverlayKml(event)),
    ]);

    final box = Hive.box(AppConstants.settingsBox);
    final ttsEnabled = box.get(AppConstants.keyTTSEnabled, defaultValue: true);
    if (ttsEnabled && context.mounted) {
      final tts = context.read<TTSService>();
      tts.speakTourEventSummary(event);
    }
  }
}
