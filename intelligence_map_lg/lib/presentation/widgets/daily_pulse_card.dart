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

    if (ssh.isConnected) {
      final topRegions = TopRegionHelper.getTopRegions(state.filteredEvents);

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

      final tourEvents = TopRegionHelper.getBriefingTourEvents(state.allEvents);

      if (tourEvents.isNotEmpty) {
        await ssh.flyTo(
          latitude: tourEvents[0].latitude,
          longitude: tourEvents[0].longitude,
          range: _getRangeForEvent(tourEvents[0]),
          tilt: 45,
        );
      }

      // Start camera tour timer
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect to the RIG first...')),
      );
      setState(() {
      _isLoading = false;
      _isPlaying = false;
    });
    }

    // Start TTS
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1A1040), const Color(0xFF0D0B2A)],
        ),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.podcasts_rounded,
                color: Color(0xFFA78BFA),
                size: 28,
              ),
            ),
            const SizedBox(width: 20),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Global Pulse',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'AI-generated 60s briefing',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _isPlaying
                        ? 'Speaking...'
                        : _isLoading
                        ? 'Generating briefing...'
                        : 'Tap to hear today\'s global briefing',
                    style: TextStyle(
                      color: _isPlaying
                          ? const Color(0xFFA78BFA)
                          : Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
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
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isLoading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: const Color(0xFFA78BFA),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Generating...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 10,
            ),
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
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
          ),
          shape: BoxShape.circle,
          boxShadow: [],
        ),
        child: Icon(
          _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 26,
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
