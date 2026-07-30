import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/top_region_helper.dart';
import '../../logic/blocs/events/events_bloc.dart';
import '../../services/gemma_service.dart';
import '../../services/overlay_service.dart';
import '../../services/ssh_service.dart';
import '../../services/tts_service.dart';
import '../../services/kml_service.dart';


class FlyToSuggestionCard extends StatelessWidget {
  final FlyToSuggestion flyTo;

  const FlyToSuggestionCard({super.key, required this.flyTo});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 14,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  flyTo.locationName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final ssh = context.read<SSHService>();

                if (!ssh.isConnected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Not connected to LG. Go to Settings to connect.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                //fly camera to location
                await ssh.flyTo(
                  latitude: flyTo.latitude,
                  longitude: flyTo.longitude,
                  range: 1000000,
                );

                // get events from BLoC
                if (!context.mounted) return;
                final state = context.read<EventsBloc>().state;
                final events = state.filteredEvents;

                final kml = context.read<KMLService>();

                final kmlContent = kml.generateEventsKML(events);
                final success = await ssh.sendKML(kmlContent);

                //calculate bounding box around location
                final bounds = LatLngBounds(
                  LatLng(flyTo.latitude - 15, flyTo.longitude - 15),
                  LatLng(flyTo.latitude + 15, flyTo.longitude + 15),
                );

                //get all the visible events in that region
                final visibleEvents = TopRegionHelper.getVisibleEvents(
                  events,
                  bounds,
                );

                

                // generate and send region overlay
                if (!context.mounted) return;
                String overlayKML;
                final gemma = context.read<GemmaService>();
                overlayKML = await OverlayService.generateRegionOverlayKML(
                  visibleEvents,
                  gemma,
                );
                await ssh.sendOverlayKML(overlayKML);

                // 7. TTS
                if (!context.mounted) return;
                final box = Hive.box(AppConstants.settingsBox);
                final ttsEnabled = box.get(
                  AppConstants.keyTTSEnabled,
                  defaultValue: true,
                );
                if (ttsEnabled) {
                  final tts = context.read<TTSService>();
                  tts.speakRegionSummary(visibleEvents);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 101, 114),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.send_rounded, size: 14),
              label: const Text(
                'Fly to on LG',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}