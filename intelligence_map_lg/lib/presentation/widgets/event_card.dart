import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/global_event.dart';

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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 15,
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
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          event.locationName,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        event.timeAgo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Severity badge
            _SeverityBadge(severity: event.severity),
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

class _SeverityBadge extends StatelessWidget {
  final EventSeverity severity;

  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        severity.label.toUpperCase(),
        style: TextStyle(
          color: _badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color get _badgeColor {
    switch (severity) {
      case EventSeverity.critical:
        return AppTheme.severityCritical;
      case EventSeverity.high:
        return AppTheme.severityHigh;
      case EventSeverity.medium:
        return AppTheme.severityMedium;
      case EventSeverity.low:
        return AppTheme.severityLow;
    }
  }
}
