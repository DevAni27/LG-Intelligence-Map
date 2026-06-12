import 'package:dio/dio.dart';
import '../models/global_event.dart';
import '../../core/constants/app_constants.dart';

/// Fetches natural disaster data from NASA's Earth Observatory
/// Natural Event Tracker (EONET) API v3.
///
/// EONET docs: https://eonet.gsfc.nasa.gov/docs/v3
/// Returns active events including wildfires, severe storms,
/// volcanoes, floods, and sea ice. No auth required.
class NASAEonetService {
  final Dio _dio;

  NASAEonetService({Dio? dio}) : _dio = dio ?? Dio();

  /// Fetches currently active natural events.
  Future<List<GlobalEvent>> fetchActiveEvents({int limit = 50}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.nasaEonetEvents,
        queryParameters: {
          'status': 'open',
          'limit': limit,
        },
      );
      return _parseEvents(response.data);
    } on DioException catch (e) {
      throw NASAEonetException('Failed to fetch EONET data: ${e.message}');
    }
  }

  /// Fetches events for a specific time range (for historical playback).
  Future<List<GlobalEvent>> fetchEventsByRange({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.nasaEonetEvents,
        queryParameters: {
          'start': startTime.toUtc().toIso8601String().split('T')[0],
          'end': endTime.toUtc().toIso8601String().split('T')[0],
        },
      );
      return _parseEvents(response.data);
    } on DioException catch (e) {
      throw NASAEonetException('Failed to fetch EONET data: ${e.message}');
    }
  }

  List<GlobalEvent> _parseEvents(dynamic data) {
    final eventsJson = data['events'] as List<dynamic>? ?? [];
    final events = <GlobalEvent>[];

    for (final event in eventsJson) {
      try {
        final id = event['id'] as String;
        final title = event['title'] as String? ?? 'Unknown event';
        final categories = event['categories'] as List<dynamic>? ?? [];
        final geometries = event['geometries'] as List<dynamic>? ?? [];
        final sources = event['sources'] as List<dynamic>? ?? [];

        if (geometries.isEmpty) continue;

        // Use the most recent geometry (last in the list)
        final latestGeo = geometries.last;
        final coords = latestGeo['coordinates'] as List<dynamic>;
        final geoDate = latestGeo['date'] as String? ?? '';

        // EONET returns [longitude, latitude] for Point geometry
        double latitude;
        double longitude;

        if (latestGeo['type'] == 'Point') {
          longitude = (coords[0] as num).toDouble();
          latitude = (coords[1] as num).toDouble();
        } else {
          // Polygon — take centroid of first coordinate set
          final ring = coords[0] as List<dynamic>;
          double sumLat = 0, sumLon = 0;
          for (final point in ring) {
            sumLon += (point[0] as num).toDouble();
            sumLat += (point[1] as num).toDouble();
          }
          longitude = sumLon / ring.length;
          latitude = sumLat / ring.length;
        }

        // Map EONET category to our EventCategory
        final category = _mapCategory(categories);

        // Build source URL from first source
        final sourceUrl = sources.isNotEmpty
            ? sources.first['url'] as String?
            : null;

        events.add(GlobalEvent(
          id: 'eonet_$id',
          title: title,
          description: _buildDescription(title, category, geometries.length),
          category: category,
          severity: _estimateSeverity(category, geometries.length),
          latitude: latitude,
          longitude: longitude,
          locationName: _extractLocation(title),
          timestamp: DateTime.tryParse(geoDate)?.toLocal() ?? DateTime.now(),
          source: EventSource.nasaEonet,
          sourceUrl: sourceUrl,
          metadata: {
            'eonet_id': id,
            'geometry_count': geometries.length,
            'categories': categories.map((c) => c['title']).toList(),
          },
        ));
      } catch (e) {
        continue;
      }
    }

    return events;
  }

  /// Maps EONET category IDs to our EventCategory enum.
  /// EONET categories: https://eonet.gsfc.nasa.gov/api/v3/categories
  EventCategory _mapCategory(List<dynamic> categories) {
    if (categories.isEmpty) return EventCategory.wildfire;

    final catId = categories.first['id'] as String? ?? '';

    switch (catId) {
      case 'wildfires':
        return EventCategory.wildfire;
      case 'severeStorms':
      case 'floods':
        return EventCategory.floodStorm;
      case 'volcanoes':
      case 'earthquakes':
        return EventCategory.earthquake;
      case 'drought':
      case 'dustHaze':
      case 'tempExtremes':
        return EventCategory.wildfire; // climate-related
      default:
        return EventCategory.wildfire;
    }
  }

  /// Estimates severity based on category and how many geometry
  /// entries exist (more entries = longer-running = potentially worse).
  EventSeverity _estimateSeverity(EventCategory category, int geoCount) {
    if (geoCount > 20) return EventSeverity.critical;
    if (geoCount > 10) return EventSeverity.high;
    if (geoCount > 3) return EventSeverity.medium;
    return EventSeverity.low;
  }

  /// Extracts a rough location name from the EONET title.
  /// Titles are often like "Wildfire - SW of City, Country".
  String _extractLocation(String title) {
    final parts = title.split(' - ');
    return parts.length > 1 ? parts.sublist(1).join(' - ').trim() : title;
  }

  String _buildDescription(
    String title,
    EventCategory category,
    int geoCount,
  ) {
    final typeLabel = category.label.toLowerCase();
    return '$title. This $typeLabel event has $geoCount recorded '
        'observation${geoCount == 1 ? '' : 's'} from NASA EONET.';
  }
}

class NASAEonetException implements Exception {
  final String message;
  const NASAEonetException(this.message);

  @override
  String toString() => 'NASAEonetException: $message';
}
