import 'package:dio/dio.dart';
import '../models/global_event.dart';
import 'dart:convert';


import 'package:flutter/material.dart';

/// Fetches natural disaster data from NASA's Earth Observatory
/// Natural Event Tracker (EONET) API v3 — GeoJSON endpoint.
///
/// Using the GeoJSON endpoint instead of the regular one because
/// it returns standard GeoJSON FeatureCollection format, which is
/// much cleaner to parse. Each feature has properties + geometry
/// in a predictable structure.
///
/// Endpoint: https://eonet.gsfc.nasa.gov/api/v3/events/geojson
/// No auth required.
class NASAEonetService {
  final Dio _dio;

  NASAEonetService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );

  /// Fetches currently active natural events in GeoJSON format.
  Future<List<GlobalEvent>> fetchActiveEvents({int days = 60}) async {
    try {
      final response = await _dio.get(
        'https://eonet.gsfc.nasa.gov/api/v3/events/geojson',
        queryParameters: {'status': 'open', 'days': days},
      );

      // EONET sometimes returns content-type as rss+xml instead of json,
      // which makes Dio return a raw String. Handle both cases.
      final data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      return _parseGeoJson(data);
    } on DioException catch (e) {
      throw NASAEonetException('Failed to fetch EONET data: ${e.message}');
    }
  }

  /// Parses GeoJSON FeatureCollection from EONET.
  ///
  /// Each feature looks like:
  /// {
  ///   "type": "Feature",
  ///   "properties": {
  ///     "id": "EONET_19405",
  ///     "title": "Wildfire, Waukesha, Wisconsin",
  ///     "categories": [{"id": "wildfires", "title": "Wildfires"}],
  ///     "sources": [{"id": "IRWIN", "url": "..."}],
  ///     "date": "2026-04-09T15:09:00Z",
  ///     "magnitudeValue": 1375.50,
  ///     "magnitudeUnit": "acres"
  ///   },
  ///   "geometry": {
  ///     "type": "Point",
  ///     "coordinates": [-88.483243, 42.9227232]
  ///   }
  /// }
  List<GlobalEvent> _parseGeoJson(dynamic data) {
    final features = data['features'] as List<dynamic>? ?? [];
    final events = <GlobalEvent>[];
    // Track seen IDs to avoid duplicates (EONET returns one feature
    // per observation, so the same event can appear multiple times)
    final seenIds = <String>{};

    for (final feature in features) {
      try {
        final props = feature['properties'] as Map<String, dynamic>;
        final geometry = feature['geometry'] as Map<String, dynamic>?;

        if (geometry == null) continue;

        final id = props['id']?.toString() ?? '';
        if (id.isEmpty) continue;

        // Skip duplicate events — keep only the first (most recent) one
        if (seenIds.contains(id)) continue;
        seenIds.add(id);

        final title = props['title']?.toString() ?? 'Unknown event';
        final categories = props['categories'] as List<dynamic>? ?? [];
        final sources = props['sources'] as List<dynamic>? ?? [];
        final dateStr = props['date']?.toString() ?? '';
        final magnitudeValue = props['magnitudeValue'];
        final magnitudeUnit = props['magnitudeUnit']?.toString();

        // Parse coordinates from geometry
        final coords = geometry['coordinates'] as List<dynamic>?;
        if (coords == null || coords.length < 2) continue;

        final longitude = (coords[0] as num).toDouble();
        final latitude = (coords[1] as num).toDouble();

        // Map EONET category to our EventCategory
        final category = _mapCategory(categories);

        // Build source URL
        final sourceUrl = sources.isNotEmpty
            ? sources.first['url']?.toString()
            : null;

        // Build description with magnitude if available
        final description = _buildDescription(
          title,
          category,
          magnitudeValue,
          magnitudeUnit,
        );

        events.add(
          GlobalEvent(
            id: 'eonet_$id',
            title: title,
            description: description,
            category: category,
            severity: _estimateSeverity(category, magnitudeValue),
            latitude: latitude,
            longitude: longitude,
            locationName: _extractLocation(title),
            timestamp: DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now(),
            source: EventSource.nasaEonet,
            sourceUrl: sourceUrl,
            metadata: {
              'eonet_id': id,
              'magnitude_value': magnitudeValue,
              'magnitude_unit': magnitudeUnit,
            },
          ),
        );
      } catch (e) {
        // Skip malformed features
        continue;
      }
    }

    return events;
  }

  /// Maps EONET category IDs to our EventCategory enum.
  EventCategory _mapCategory(List<dynamic> categories) {
    if (categories.isEmpty) return EventCategory.wildfire;

    final catId = categories.first['id']?.toString() ?? '';

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
        return EventCategory.wildfire;
      case 'seaLakeIce':
      case 'snow':
        return EventCategory.floodStorm;
      default:
        return EventCategory.wildfire;
    }
  }

  /// Estimates severity based on category and magnitude.
  EventSeverity _estimateSeverity(EventCategory category, dynamic magnitude) {
    if (magnitude == null) return EventSeverity.medium;

    final value = (magnitude is num) ? magnitude.toDouble() : 0.0;

    // For wildfires, magnitude is in acres
    if (category == EventCategory.wildfire) {
      if (value > 50000) return EventSeverity.critical;
      if (value > 10000) return EventSeverity.high;
      if (value > 1000) return EventSeverity.medium;
      return EventSeverity.low;
    }

    // For storms, magnitude is in knots (wind speed)
    if (category == EventCategory.floodStorm) {
      if (value > 100) return EventSeverity.critical;
      if (value > 64) return EventSeverity.high;
      if (value > 34) return EventSeverity.medium;
      return EventSeverity.low;
    }

    return EventSeverity.medium;
  }

  /// Extracts a rough location name from the EONET title.
  String _extractLocation(String title) {
    // Titles often look like "Wildfire - SW of City, Country"
    // or "HARRISON Wildfire, Osage, Oklahoma"
    final parts = title.split(' - ');
    if (parts.length > 1) return parts.sublist(1).join(' - ').trim();

    // Try splitting by comma for "Name, Location" format
    final commaParts = title.split(', ');
    if (commaParts.length > 1) return commaParts.sublist(1).join(', ').trim();

    return title;
  }

  String _buildDescription(
    String title,
    EventCategory category,
    dynamic magnitudeValue,
    String? magnitudeUnit,
  ) {
    final typeLabel = category.label;
    if (magnitudeValue != null && magnitudeUnit != null) {
      return '$typeLabel event: $title. Magnitude: $magnitudeValue $magnitudeUnit.';
    }
    return '$typeLabel event: $title. Tracked by NASA EONET.';
  }

  //fetches all the historic events

  Future<List<GlobalEvent>> fetchHistoricalEvents({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final start = startTime.toIso8601String().split('T')[0];
    final end = endTime.toIso8601String().split('T')[0];

    final url =
        'https://eonet.gsfc.nasa.gov/api/v3/events'
        '?status=closed'
        '&start=$start'
        '&end=$end'
        '&limit=50';

    try {
      final response = await _dio.get(url);
      final data = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      final events = data['events'] as List<dynamic>? ?? [];

      final result = <GlobalEvent>[];

      for (final event in events) {
        try {
          final events = event is String ? jsonDecode(event) as Map<String, dynamic> : event as Map<String, dynamic>;
          final id = events['id']?.toString() ?? '';
          final title = events['title']?.toString() ?? 'Unknown event';
          final categories = events['categories'] as List<dynamic>? ?? [];
          final sources = events['sources'] as List<dynamic>? ?? [];

          // Geometry is an array — take the first one
          final geometries = events['geometry'] as List<dynamic>? ?? [];
          if (geometries.isEmpty) continue;

          final geometry = geometries.first as Map<String, dynamic>;
          final coords = geometry['coordinates'] as List<dynamic>?;
          if (coords == null || coords.length < 2) continue;

          final longitude = (coords[0] as num).toDouble();
          final latitude = (coords[1] as num).toDouble();
          final dateStr = geometry['date']?.toString() ?? '';

          final category = _mapCategory(categories);
          final sourceUrl = sources.isNotEmpty
              ? sources.first['url']?.toString()
              : null;

          result.add(
            GlobalEvent(
              id: 'eonet_hist_$id',
              title: title,
              description: _buildDescription(title, category, null, null),
              category: category,
              severity: _estimateSeverity(category, null),
              latitude: latitude,
              longitude: longitude,
              locationName: _extractLocation(title),
              timestamp:
                  DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now(),
              source: EventSource.nasaEonet,
              sourceUrl: sourceUrl,
              metadata: {'eonet_id': id},
            ),
          );
        } catch (e) {
          continue;
        }
      }

      return result;
    } catch (e) {
      return [];
    }
  }
}

class NASAEonetException implements Exception {
  final String message;
  const NASAEonetException(this.message);

  @override
  String toString() => 'NASAEonetException: $message';
}
