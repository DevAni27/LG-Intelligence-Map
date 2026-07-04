import '../../data/models/global_event.dart';

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
}
