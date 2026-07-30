import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/blocs/events/events_bloc.dart';
import '../../services/gemma_service.dart';
import '../../services/tts_service.dart';

class DailyPulseCard extends StatefulWidget {
  const DailyPulseCard({super.key});

  @override
  State<DailyPulseCard> createState() => _DailyPulseCardState();
}

class _DailyPulseCardState extends State<DailyPulseCard> {
  bool _isLoading = false;
  bool _isPlaying = false;

  Future<void> _onPlayTapped() async {
    setState(() => _isLoading = true);

    final state = context.read<EventsBloc>().state;
    final events = state.allEvents;

    final gemma = context.read<GemmaService>();
    final briefing = await gemma.generateDailyPulse(events);

    setState(() {
      _isLoading = false;
      _isPlaying = true;
    });

    final tts = context.read<TTSService>();
    await tts.speakAndWait(briefing);
    setState(() => _isPlaying = false);
  }

  Future<void> _onStopTapped() async {
    final tts = context.read<TTSService>();
    tts.stop();
    setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
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
      return const SizedBox(
        width: 48,
        height: 48,
        child: CircularProgressIndicator(strokeWidth: 2),
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
}