import 'package:flutter/material.dart';
import '../../data/models/global_event.dart';

class SeverityBadge extends StatelessWidget {
  final EventSeverity severity;

  const SeverityBadge({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _severityColor(severity).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _severityColor(severity).withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        severity.name.toUpperCase(),
        style: TextStyle(
          color: _severityColor(severity),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _severityColor(EventSeverity severity) {
    switch (severity) {
      case EventSeverity.critical:
        return const Color(0xFFEF4444);
      case EventSeverity.high:
        return const Color(0xFFF97316);
      case EventSeverity.medium:
        return const Color(0xFFEAB308);
      case EventSeverity.low:
        return const Color(0xFF22C55E);
    }
  }
}