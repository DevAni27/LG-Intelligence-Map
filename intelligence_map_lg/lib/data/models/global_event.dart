import 'package:equatable/equatable.dart';

/// The severity level of a global event.
enum EventSeverity {
  low,
  medium,
  high,
  critical;

  String get label => name[0].toUpperCase() + name.substring(1);
}

/// The category of a global event, each with its own color on the map/KML.
enum EventCategory {
  earthquake,
  floodStorm,
  wildfire,
  diseaseOutbreak,
  conflict;

  String get label {
    switch (this) {
      case earthquake:
        return 'Earthquake';
      case floodStorm:
        return 'Flood / Storm';
      case wildfire:
        return 'Wildfire';
      case diseaseOutbreak:
        return 'Disease Outbreak';
      case conflict:
        return 'Conflict / Incident';
    }
  }

  /// KML color in AABBGGRR format (KML uses reversed hex).
  String get kmlColor {
    switch (this) {
      case earthquake:
        return 'FF4444EF'; // red
      case floodStorm:
        return 'FFF6823B'; // blue (reversed)
      case wildfire:
        return 'FF1673F9'; // orange (reversed)
      case diseaseOutbreak:
        return 'FFF755A8'; // purple (reversed)
      case conflict:
        return 'FF08B3EA'; // yellow (reversed)
    }
  }
}

/// The data source that provided this event.
enum EventSource {
  usgs,
  nasaEonet,
  who,
  gdelt,
  simulated;

  String get label {
    switch (this) {
      case usgs:
        return 'USGS';
      case nasaEonet:
        return 'NASA EONET';
      case who:
        return 'WHO';
      case gdelt:
        return 'GDELT';
      case simulated:
        return 'Simulated';
    }
  }
}

/// Represents a single global event from any data source.
/// This is the unified data model that all sources normalize into.
class GlobalEvent extends Equatable {
  final String id;
  final String title;
  final String description;
  final EventCategory category;
  final EventSeverity severity;
  final double latitude;
  final double longitude;
  final String locationName;
  final DateTime timestamp;
  final EventSource source;
  final String? sourceUrl;
  final Map<String, dynamic>? metadata;

  const GlobalEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.timestamp,
    required this.source,
    this.sourceUrl,
    this.metadata,
  });

  /// The altitude for 3D KML extrusion based on severity.
  double get kmlAltitude {
    switch (severity) {
      case EventSeverity.critical:
        return 500000;
      case EventSeverity.high:
        return 350000;
      case EventSeverity.medium:
        return 200000;
      case EventSeverity.low:
        return 80000;
    }
  }

  /// Formatted time string like "2 hours ago".
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
  }

  @override
  List<Object?> get props => [id, source];
}
