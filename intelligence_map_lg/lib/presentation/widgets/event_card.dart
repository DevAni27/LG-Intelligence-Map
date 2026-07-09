import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/global_event.dart';
import 'severity_badge.dart';

/// Displays a single [GlobalEvent] as a card in lists.
/// Shows the category color bar, title, location, time, and severity badge.
class EventCard extends StatelessWidget {
  final GlobalEvent event;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category color indicator bar
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: _categoryColor(event.category),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Event info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: const Color.fromARGB(255, 155, 175, 184),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          event.locationName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color.fromARGB(255, 155, 175, 184),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        event.timeAgo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color.fromARGB(255, 155, 175, 184),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Severity badge
            SeverityBadge(severity: event.severity),
          ],
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
}

