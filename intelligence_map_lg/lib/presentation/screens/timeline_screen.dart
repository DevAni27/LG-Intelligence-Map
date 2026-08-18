import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lg_world_intelligence_map/core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/global_event.dart';
import '../../presentation/blocs/events/events_bloc.dart';
import '../../presentation/blocs/events/events_state.dart';
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

class _TimelineScreenState extends State<TimelineScreen>
    with SingleTickerProviderStateMixin {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

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

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),

          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
                    child: _buildDateRangeSelector(),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                    child: _buildCategoryFilters(),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                    child: _buildFetchButton(),
                  ),
                ),

                if (_errorMessage != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.severityCritical
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.severityCritical
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                size: 16,
                                color: AppTheme.severityCritical),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppTheme.severityCritical,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Playback controls
                if (_historicalEvents.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      child: _buildPlaybackControls(),
                    ),
                  ),

                // Events list 
                if (_historicalEvents.isEmpty && !_isLoading)
                  SliverFillRemaining(
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final event = _historicalEvents[index];
                          final isCurrent =
                              index == _currentIndex && _isPlaying;
                          return _buildEventRow(event, index, isCurrent);
                        },
                        childCount: _historicalEvents.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),

          // Replay on LG button
          if (_historicalEvents.isNotEmpty) _buildReplayButton(),
        ],
      ),
    );
  }

  //header
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(Icons.history_rounded,
                          color: AppTheme.primary, size: 28),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Historical Timeline',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            fontSize: 26,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.only(left: 44),
                  child: Text(
                    'Replay global events through time',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Event count 
          if (_historicalEvents.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                '${_historicalEvents.length} events',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Date range selector 
  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1421),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDateButton(
              label: 'Start Date',
              date: _startDate,
              onTap: () => _pickDate(isStart: true),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: AppTheme.primary,
                size: 22,
              ),
            ),
          ),
          Expanded(
            child: _buildDateButton(
              label: 'End Date',
              date: _endDate,
              onTap: () => _pickDate(isStart: false),
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
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: AppTheme.primary.withValues(alpha: 0.7),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Category filters
  Widget _buildCategoryFilters() {
    return Row(
      children: _categories.map((category) {
        final isSelected = _selectedCategory == category;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.check_rounded,
                        size: 13, color: AppTheme.primary),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    category,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.primary
                          : Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: isSelected
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
    );
  }

  //Fetch button
  Widget _buildFetchButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _fetchEvents,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: _isLoading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: _isLoading ? Colors.white.withValues(alpha: 0.06) : null,
          borderRadius: BorderRadius.circular(16),
          border: _isLoading
              ? Border.all(color: Colors.white.withValues(alpha: 0.08))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
              )
            else
              const Icon(Icons.search_rounded,
                  size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              _isLoading ? 'Fetching events...' : 'Fetch Events',
              style: TextStyle(
                color: _isLoading
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Playback controls
  Widget _buildPlaybackControls() {
    final progress = _historicalEvents.isEmpty
        ? 0.0
        : (_currentIndex + 1) / _historicalEvents.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1421),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event ${_currentIndex + 1} of ${_historicalEvents.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_isPlaying && _currentIndex < _historicalEvents.length)
                    Text(
                      _historicalEvents[_currentIndex].locationName,
                      style: TextStyle(
                        color: AppTheme.primary.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),

              const Spacer(),

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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? null
                            : Border.all(
                                color:
                                    Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Text(
                        '${speed.toInt()}x',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(width: 14),

              GestureDetector(
                onTap: _stopPlayback,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Icon(Icons.stop_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.6)),
                ),
              ),
              const SizedBox(width: 8),

              // Play/Pause button
              GestureDetector(
                onTap: _isPlaying ? _pausePlayback : _startPlayback,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //Event row 
  Widget _buildEventRow(GlobalEvent event, int index, bool isCurrent) {
    final color = _categoryColor(event.category);
    final isLast = index == _historicalEvents.length - 1;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isCurrent ? 14 : 10,
                  height: isCurrent ? 14 : 10,
                  decoration: BoxDecoration(
                    color: isCurrent ? color : color.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : [],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: Colors.white.withValues(alpha: 0.08),
                      margin: const EdgeInsets.symmetric(vertical: 3),
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : 8,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? color.withValues(alpha: 0.08)
                      : const Color(0xFF0D1421),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCurrent
                        ? color.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.06),
                    width: isCurrent ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: TextStyle(
                              color: isCurrent
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 1),
                              fontSize: 14,
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height:5),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  event.locationName,
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '  ·  ',
                                style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${event.timestamp.day}/${event.timestamp.month}/${event.timestamp.year}',
                                style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SeverityBadge(severity: event.severity),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.07),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Icon(
              Icons.history_rounded,
              size: 34,
              color: AppTheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No events loaded yet',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a date range and tap\nFetch Events to begin',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 13,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  //Replay on LG button
  Widget _buildReplayButton() {
    final ssh = context.watch<SSHService>();

    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: GestureDetector(
        onTap: _isPlaying || !ssh.isConnected ? null : _startPlayback,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: _isPlaying || !ssh.isConnected
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: _isPlaying || !ssh.isConnected
                ? Colors.white.withValues(alpha: 0.1)
                : null,
            borderRadius: BorderRadius.circular(18),
            border: _isPlaying || !ssh.isConnected
                ? Border.all(color: Colors.white.withValues(alpha: 0.07))
                : null,
            boxShadow: _isPlaying || !ssh.isConnected
                ? []
                : [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isPlaying
                    ? Icons.play_circle_outline_rounded
                    : ssh.isConnected
                        ? Icons.send_rounded
                        : Icons.wifi_off_rounded,
                size: 20,
                color: _isPlaying || !ssh.isConnected
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                _isPlaying
                    ? 'Tour in progress...'
                    : ssh.isConnected
                        ? 'Replay on LG Rig'
                        : 'Connect to LG First',
                style: TextStyle(
                  color: _isPlaying || !ssh.isConnected
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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
    ssh.sendKML(kmlContent); //no await needed

    setState(() {
      _isPlaying = true;
      _currentIndex = 0; //start from beginning
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
    final ttsEnabled =
        box.get(AppConstants.keyTTSEnabled, defaultValue: true);
    if (ttsEnabled && context.mounted) {
      final tts = context.read<TTSService>();
      tts.speakTourEventSummary(event);
    }
  }
}