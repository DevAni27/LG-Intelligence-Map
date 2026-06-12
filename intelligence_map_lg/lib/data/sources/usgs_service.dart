import 'package:dio/dio.dart';
import '../models/global_event.dart';
import '../../core/constants/app_constants.dart';

/// Fetches earthquake data from the USGS GeoJSON API and normalizes
/// it into [GlobalEvent] objects.
///
/// USGS API docs: https://earthquake.usgs.gov/earthquakes/feed/
/// Returns GeoJSON FeatureCollection with coordinates, magnitude,
/// depth, place name, and timestamp. No auth required.
class USGSService {
  final Dio _dio;

  USGSService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ));

  /// Fetches all earthquakes from the last 24 hours.
  Future<List<GlobalEvent>> fetchDailyEarthquakes() async {
    return _fetchFromEndpoint(ApiEndpoints.usgsAllDay);
  }

  /// Fetches all earthquakes from the last 7 days.
  Future<List<GlobalEvent>> fetchWeeklyEarthquakes() async {
    return _fetchFromEndpoint(ApiEndpoints.usgsAllWeek);
  }

  /// Fetches earthquakes for a custom time range (for historical playback).
  Future<List<GlobalEvent>> fetchEarthquakesByRange({
    required DateTime startTime,
    required DateTime endTime,
    double? minMagnitude,
  }) async {
    final params = <String, dynamic>{
      'format': 'geojson',
      'starttime': startTime.toUtc().toIso8601String(),
      'endtime': endTime.toUtc().toIso8601String(),
    };

    if (minMagnitude != null) {
      params['minmagnitude'] = minMagnitude;
    }

    try {
      final response = await _dio.get(
        ApiEndpoints.usgsQuery,
        queryParameters: params,
      );
      return _parseGeoJson(response.data);
    } on DioException catch (e) {
      throw USGSException('Failed to fetch USGS data: ${e.message}');
    }
  }

  Future<List<GlobalEvent>> _fetchFromEndpoint(String url) async {
    try {
      final response = await _dio.get(url);
      return _parseGeoJson(response.data);
    } on DioException catch (e) {
      throw USGSException('Failed to fetch USGS data: ${e.message}');
    }
  }

  /// Parses USGS GeoJSON FeatureCollection into a list of [GlobalEvent].
  ///
  /// Each feature has:
  /// - geometry.coordinates: [longitude, latitude, depth]
  /// - properties.mag: magnitude
  /// - properties.place: location description
  /// - properties.time: Unix timestamp in milliseconds
  /// - properties.title: event title
  /// - properties.url: USGS event page
  /// - properties.alert: PAGER alert level (green/yellow/orange/red)
  List<GlobalEvent> _parseGeoJson(dynamic data) {
    final features = data['features'] as List<dynamic>? ?? [];
    final events = <GlobalEvent>[];

    for (final feature in features) {
      try {
        final props = feature['properties'] as Map<String, dynamic>;
        final coords = feature['geometry']['coordinates'] as List<dynamic>;

        final magnitude = (props['mag'] as num?)?.toDouble() ?? 0.0;
        final longitude = (coords[0] as num).toDouble();
        final latitude = (coords[1] as num).toDouble();
        final depth = coords.length > 2 ? (coords[2] as num).toDouble() : 0.0;
        final place = props['place'] as String? ?? 'Unknown location';
        final time = props['time'] as int? ?? 0;
        final title = props['title'] as String? ?? 'M$magnitude - $place';
        final url = props['url'] as String?;
        final alert = props['alert'] as String?;
        final id = feature['id'] as String? ?? 'usgs_$time';

        events.add(GlobalEvent(
          id: 'usgs_$id',
          title: title,
          description: _buildDescription(magnitude, depth, place),
          category: EventCategory.earthquake,
          severity: _magnitudeToSeverity(magnitude, alert),
          latitude: latitude,
          longitude: longitude,
          locationName: place,
          timestamp: DateTime.fromMillisecondsSinceEpoch(time, isUtc: true),
          source: EventSource.usgs,
          sourceUrl: url,
          metadata: {
            'magnitude': magnitude,
            'depth_km': depth,
            'alert': alert,
            'felt': props['felt'],
            'tsunami': props['tsunami'],
          },
        ));
      } catch (e) {
        // Skip malformed features rather than failing the whole batch
        continue;
      }
    }

    return events;
  }

  /// Converts earthquake magnitude to our severity scale.
  /// Uses PAGER alert level if available, falls back to magnitude thresholds.
  EventSeverity _magnitudeToSeverity(double magnitude, String? alert) {
    // PAGER alert takes priority if available
    if (alert != null) {
      switch (alert) {
        case 'red':
          return EventSeverity.critical;
        case 'orange':
          return EventSeverity.high;
        case 'yellow':
          return EventSeverity.medium;
        case 'green':
          return EventSeverity.low;
      }
    }

    // Fallback to magnitude-based severity
    if (magnitude >= 7.0) return EventSeverity.critical;
    if (magnitude >= 5.0) return EventSeverity.high;
    if (magnitude >= 3.0) return EventSeverity.medium;
    return EventSeverity.low;
  }

  String _buildDescription(double magnitude, double depth, String place) {
    return 'A magnitude $magnitude earthquake occurred at a depth of '
        '${depth.toStringAsFixed(1)} km near $place.';
  }
}

class USGSException implements Exception {
  final String message;
  const USGSException(this.message);

  @override
  String toString() => 'USGSException: $message';
}
