import '../../data/models/global_event.dart';
import 'package:flutter_map/flutter_map.dart';

class TopRegionHelper {
  static List<MapEntry<String, int>> getTopRegions(List<GlobalEvent> events, {
    int take = 5,
  })
  {
    final counts = <String, int>{};

    for (final event in events) {
      // this is to skip empty location names
      if (event.locationName.isEmpty) continue;
      counts[event.locationName] = (counts[event.locationName] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(take).toList();
  }

  //method to filter events in the map bound box

  static List<GlobalEvent> getVisibleEvents(
    List<GlobalEvent> events,
    LatLngBounds bounds,
  )
  {
    return events.where((event) {
      return event.latitude >= bounds.southWest.latitude && event.latitude <= bounds.northEast.latitude && event.longitude >= bounds.southWest.longitude && event.longitude <= bounds.northEast.longitude;
    }).toList();
  }

  //count events by category in the respective region

  static Map<EventCategory, int> getCategoryCounts(List<GlobalEvent> events) {
    final counts = <EventCategory, int>{};
      for (final event in events) {
        counts[event.category] = (counts[event.category] ?? 0) + 1;
      }
    return counts;
  }

  //count events by severity
  static Map<EventSeverity, int> getSeverityCounts(List<GlobalEvent> events) {
    final counts = <EventSeverity, int>{};
      for (final event in events) {
      counts[event.severity] = (counts[event.severity] ?? 0) + 1;
    }
    return counts;
  }

  //get the dominant event in that region 

  static EventCategory? getDominantCategory(List<GlobalEvent> events) {
    if (events.isEmpty) return null;
      final counts = getCategoryCounts(events);
    return counts.entries
      .reduce((a, b) => a.value >= b.value ? a : b)
      .key;
  }

  //get thte top event in that region
  static GlobalEvent? getTopEvent(List<GlobalEvent> events) {
    if (events.isEmpty) return null;
    final sorted = [...events]..sort((a, b) {
      final severityCompare = b.severity.index.compareTo(a.severity.index);
      if (severityCompare != 0) return severityCompare;
      return b.timestamp.compareTo(a.timestamp);
    });
    return sorted.first;
  }
}
