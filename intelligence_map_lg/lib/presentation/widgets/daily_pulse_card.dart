import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/blocs/events/events_bloc.dart';
import '../../services/gemma_service.dart';
import '../../services/tts_service.dart';
import 'dart:async';
import '../../core/utils/top_region_helper.dart';
import '../../services/overlay_service.dart';
import '../../services/ssh_service.dart';
import '../../data/models/global_event.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';

class DailyPulseCard extends StatefulWidget {
  const DailyPulseCard({super.key});

  @override
  State<DailyPulseCard> createState() => _DailyPulseCardState();
}

class _DailyPulseCardState extends State<DailyPulseCard> {
  bool _isLoading = false;
  bool _isPlaying = false;

  Timer? _tourTimer;
  Timer? _briefingTimer;

  Future<void> _onPlayTapped() async {
    setState(() => _isLoading = true);

    // Get state
    final state = context.read<EventsBloc>().state;
    final ssh = context.read<SSHService>();
    final tts = context.read<TTSService>();
    final gemma = context.read<GemmaService>();

    // Generate AI briefing
    final briefing = await gemma.generateDailyPulse(state.allEvents);

    setState(() {
      _isLoading = false;
      _isPlaying = true;
    });

    // If LG connected — send dashboard overlay and start camera tour
    if (ssh.isConnected) {
      // Build top regions for dashboard
      final topRegions = TopRegionHelper.getTopRegions(state.filteredEvents);

      // Generate and send briefing dashboard to slave screen
      final now = DateTime.now();
      final dateTime =
          '${now.day}/${now.month}/${now.year} · ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

      final overlayKml = OverlayService.generateBriefingOverlayKml(
        totalEvents: state.totalEvents,
        earthquakeCount: state.earthquakeCount,
        disasterCount: state.disasterCount,
        diseaseCount: state.diseaseCount,
        criticalCount: state.criticalCount,
        highCount: state.highCount,
        mediumCount: state.mediumCount,
        lowCount: state.lowCount,
        topRegions: topRegions,
        dateTime: dateTime,
      );

      await ssh.sendOverlayKML(overlayKml);

      // Get tour events and start camera tour
      final tourEvents = TopRegionHelper.getBriefingTourEvents(state.allEvents);

      // Fly to first event immediately
      if (tourEvents.isNotEmpty) {
        await ssh.flyTo(
          latitude: tourEvents[0].latitude,
          longitude: tourEvents[0].longitude,
          range: _getRangeForEvent(tourEvents[0]),
          tilt: 45,
        );
      }

      // Start camera tour timer — fly to next event every 10 seconds
      int tourIndex = 1;
      _briefingTimer = Timer.periodic(const Duration(seconds: 10), (
        timer,
      ) async {
        if (!_isPlaying || tourIndex >= tourEvents.length) {
          timer.cancel();
          return;
        }
        await ssh.flyTo(
          latitude: tourEvents[tourIndex].latitude,
          longitude: tourEvents[tourIndex].longitude,
          range: _getRangeForEvent(tourEvents[tourIndex]),
          tilt: 45,
        );
        tourIndex++;
      });
    }

    // Start TTS — speaks while camera tours

    final box = Hive.box(AppConstants.settingsBox);
    final ttsEnabled = box.get(AppConstants.keyTTSEnabled, defaultValue: true);

    if (ttsEnabled) {
      await tts.speakAndWait(briefing);
    }

    // Briefing finished
    _briefingTimer?.cancel();

    if (ssh.isConnected) {
      ssh.clearoverlayKML('');
      ssh.flyToDefault();
    }

    setState(() => _isPlaying = false);
  }

  Future<void> _onStopTapped() async {
    _tourTimer?.cancel();
    _briefingTimer?.cancel();
    _tourTimer = null;

    final tts = context.read<TTSService>();
    await tts.stop();

    final ssh = context.read<SSHService>();
    if (ssh.isConnected) {
      ssh.clearoverlayKML('');
      ssh.flyToDefault();
    }

    setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Global Pulse',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'AI-generated 60s briefing',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  _isPlaying
                      ? 'Speaking...'
                      : _isLoading
                      ? 'Generating briefing...'
                      : 'Tap to hear today\'s global briefing',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _isPlaying
                        ? AppTheme.primary
                        : AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Button area
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isLoading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 6),
          Text(
            'Generating...',
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _isPlaying ? _onStopTapped : _onPlayTapped,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
          color: AppTheme.primary,
          size: 28,
        ),
      ),
    );
  }

  double _getRangeForEvent(GlobalEvent event) {
    switch (event.category) {
      case EventCategory.earthquake:
        return 500000; // 500km — city/region level
      case EventCategory.wildfire:
        return 800000; // 800km — county level
      case EventCategory.floodStorm:
        return 1500000; // 1500km — country level, storms are large
      case EventCategory.diseaseOutbreak:
        return 2000000; // 2000km — country/region level
      case EventCategory.conflict:
        return 1500000; // 1500km — country level
    }
  }
}
