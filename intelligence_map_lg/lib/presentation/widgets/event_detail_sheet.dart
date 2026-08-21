import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/global_event.dart';
import '../../services/gemini_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/severity_badge.dart';
import '../../services/overlay_service.dart';
import '../../services/ssh_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/tts_service.dart';

class EventDetailSheet extends StatefulWidget {
  final GlobalEvent event;
  const EventDetailSheet({super.key, required this.event});

  @override
  State<EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<EventDetailSheet> {
  bool _isLoadingInsight = false;
  String? _insight;

  Future<void> _loadInsight() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Loading insight. Please wait for a few...'),
      ),
    );
    setState(() => _isLoadingInsight = true);
    final gemini = context.read<GeminiService>();
    final result = await gemini.eventExplain(widget.event);
    setState(() {
      _insight = result;
      _isLoadingInsight = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
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

            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Chip(
                  label: Text(widget.event.source.name.toUpperCase()),
                  backgroundColor: AppTheme.surface,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    color: Color.fromARGB(255, 238, 238, 238),
                    fontWeight: FontWeight.bold,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),

                const Spacer(),

                SeverityBadge(severity: widget.event.severity),
              ],
            ),

            const SizedBox(height: 8),
            Text(
              widget.event.description,
              style: const TextStyle(color: Color.fromARGB(255, 203, 203, 203)),
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
                Expanded(
                  child: Text(
                    widget.event.locationName + ',',
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis, // truncates with ...
                    maxLines: 1,
                  ),
                ),

                const SizedBox(width: 8),
                Text(
                  widget.event.timeAgo,
                  style: const TextStyle(color: Colors.white),
                ),
                const Spacer(),

                //ai insight button
                if (_insight == null)
                  _isLoadingInsight
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: _loadInsight,
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('AI Insight'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: BorderSide(
                              color: AppTheme.primary.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
              ],
            ),
            const SizedBox(height: 10),

            if (_insight != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'AI Insight',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _insight!,
                      style: const TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 0.756),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final ssh = context.read<SSHService>();

                  final overlayKml = OverlayService.generateEventOverlayKml(
                    widget.event,
                  );

                  await ssh.sendOverlayKML(overlayKml);

                  await ssh.flyTo(
                    latitude: widget.event.latitude,
                    longitude: widget.event.longitude,
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
                    tts.speakEventSummary(widget.event);
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
                    widget.event,
                  );

                  await ssh.clearoverlayKML(overlayKml);
                },
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Clear Overlay KML'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
