import '../models/global_event.dart';
import '../sources/usgs_service.dart';
import '../sources/nasa_eonet_service.dart';
import '../sources/who_service.dart';

/// Represents the status of a single data source.
enum SourceStatus { idle, loading, loaded, error }

/// Holds the result from a single data source along with its status.
class SourceResult {
  final EventSource source;
  final SourceStatus status;
  final List<GlobalEvent> events;
  final String? errorMessage;
  final DateTime? lastUpdated;

  const SourceResult({
    required this.source,
    required this.status,
    this.events = const [],
    this.errorMessage,
    this.lastUpdated,
  });

  SourceResult copyWith({
    SourceStatus? status,
    List<GlobalEvent>? events,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return SourceResult(
      source: source,
      status: status ?? this.status,
      events: events ?? this.events,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Orchestrates fetching events from all data sources in parallel.
/// Each source fails independently — if WHO is down, USGS events
/// still display. This is what Mudgil asked about.
class EventRepository {
  final USGSService _usgsService;
  final NASAEonetService _nasaEonetService;
  final WHOService _whoService;

  EventRepository({
    USGSService? usgsService,
    NASAEonetService? nasaEonetService,
    WHOService? whoService,
  })  : _usgsService = usgsService ?? USGSService(),
        _nasaEonetService = nasaEonetService ?? NASAEonetService(),
        _whoService = whoService ?? WHOService();

  /// Fetches events from all enabled sources in parallel.
  /// Returns a map of source → result, so each source has its own
  /// loading/success/error state.
  Future<Map<EventSource, SourceResult>> fetchAllEvents({
    Set<EventSource> enabledSources = const {
      EventSource.usgs,
      EventSource.nasaEonet,
      EventSource.who,
    },
  }) async {
    final results = <EventSource, SourceResult>{};

    // Fire all requests in parallel using Future.wait
    // Each future catches its own errors so one failure doesn't kill the rest
    final futures = <Future<void>>[];

    // Initialize all enabled sources as "loading" so UI can show status
    if (enabledSources.contains(EventSource.usgs)) {
      results[EventSource.usgs] = const SourceResult(
        source: EventSource.usgs,
        status: SourceStatus.loading,
      );
      futures.add(_fetchUSGS().then((r) => results[EventSource.usgs] = r));
    }

    if (enabledSources.contains(EventSource.nasaEonet)) {
      results[EventSource.nasaEonet] = const SourceResult(
        source: EventSource.nasaEonet,
        status: SourceStatus.loading,
      );
      futures.add(
        _fetchNASA().then((r) => results[EventSource.nasaEonet] = r),
      );
    }

    if (enabledSources.contains(EventSource.who)) {
      results[EventSource.who] = const SourceResult(
        source: EventSource.who,
        status: SourceStatus.loading,
      );
      futures.add(
        _fetchWHO().then((r) => results[EventSource.who] = r),
      );
    }

    // Wait for all to complete (they handle errors internally)
    await Future.wait(futures);

    return results;
  }

  /// Returns all events from all sources as a single flat list,
  /// sorted by timestamp (newest first).
  List<GlobalEvent> mergeAndSort(Map<EventSource, SourceResult> results) {
    final allEvents = <GlobalEvent>[];

    for (final result in results.values) {
      if (result.status == SourceStatus.loaded) {
        allEvents.addAll(result.events);
      }
    }

    // Sort newest first
    allEvents.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return allEvents;
  }

  /// Deduplicates events based on proximity in location and time.
  /// Two events are considered duplicates if they're within 50km
  /// and 1 hour of each other with the same category.
  List<GlobalEvent> deduplicate(List<GlobalEvent> events) {
    if (events.isEmpty) return events;

    final unique = <GlobalEvent>[events.first];

    for (var i = 1; i < events.length; i++) {
      final event = events[i];
      final isDuplicate = unique.any((existing) =>
          existing.category == event.category &&
          _isNearby(existing, event, thresholdKm: 50) &&
          existing.timestamp.difference(event.timestamp).abs() <
              const Duration(hours: 1));

      if (!isDuplicate) {
        unique.add(event);
      }
    }

    return unique;
  }

  /// Rough distance check using the equirectangular approximation.
  /// Good enough for deduplication — we don't need Haversine precision.
  bool _isNearby(GlobalEvent a, GlobalEvent b, {double thresholdKm = 50}) {
    const kmPerDegree = 111.0; // approximate
    final dLat = (a.latitude - b.latitude) * kmPerDegree;
    final dLon = (a.longitude - b.longitude) * kmPerDegree * 0.7; // rough cos
    return (dLat * dLat + dLon * dLon) < (thresholdKm * thresholdKm);
  }

  Future<SourceResult> _fetchUSGS() async {
    try {
      final events = await _usgsService.fetchDailyEarthquakes();
      return SourceResult(
        source: EventSource.usgs,
        status: SourceStatus.loaded,
        events: events,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      return SourceResult(
        source: EventSource.usgs,
        status: SourceStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<SourceResult> _fetchNASA() async {
    try {
      final events = await _nasaEonetService.fetchActiveEvents();
      return SourceResult(
        source: EventSource.nasaEonet,
        status: SourceStatus.loaded,
        events: events,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      return SourceResult(
        source: EventSource.nasaEonet,
        status: SourceStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<SourceResult> _fetchWHO() async {
    try {
      final events = await _whoService.fetchWHOData();
      return SourceResult(
        source: EventSource.who,
        status: SourceStatus.loaded,
        events: events,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      return SourceResult(
        source: EventSource.who,
        status: SourceStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
