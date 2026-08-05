import 'package:dio/dio.dart';
import '../models/global_event.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/country_coordinates.dart';
import 'package:flutter/foundation.dart';

class GDELTService {
  DateTime? _lastFetch;
  final Dio _dio;

  GDELTService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              headers:{
                'User-Agent': 'LG Intelligence Map/1.0 (LiquidGalaxy GESOC2026)',
              },
            ),
          );

  Future<List<GlobalEvent>> fetchGDELTData() async {
    
    if (_lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < const Duration(minutes: 5)) {
      debugPrint('GDELT: skipping fetch, too soon');
      return _cachedEvents;
    }

    await Future.delayed(const Duration(seconds: 8));

    final events = await _fetchFromGDELT(ApiEndpoints.gdelt);
    _lastFetch = DateTime.now();
    _cachedEvents = events;
    return events;
  }

  List<GlobalEvent> _cachedEvents = [];

  Future<List<GlobalEvent>> _fetchFromGDELT(String url) async {
    try {
      debugPrint('=== FETCHING GDELT: $url ===');
      final response = await _dio.get(url);
      debugPrint('=== GDELT STATUS: ${response.statusCode} ===');
      debugPrint('=== GDELT RESPONSE: ${response.data} ===');

      final data = response.data;
      final articles = data['articles'] as List<dynamic>? ?? [];
      debugPrint('=== GDELT ARTICLES COUNT: ${articles.length} ===');

      return articles
          .map((article) => _parseGDELTData(article as Map<String, dynamic>))
          .whereType<GlobalEvent>()
          .toList();
    } on DioException catch (e) {
      debugPrint('=== GDELT DIO ERROR: ${e.message} ===');
      debugPrint('=== GDELT RESPONSE: ${e.response?.data} ===');
      throw GDELTException('Failed to fetch GDELT data: ${e.message}');
    }
  }

  GlobalEvent? _parseGDELTData(Map<String, dynamic> article) {
    try {
      final title = article['title'] as String? ?? '';
      final url = article['url'] as String? ?? '';
      final domain = article['domain'] as String? ?? '';
      final sourcecountry = article['sourcecountry'] as String? ?? '';
      final seendate = article['seendate'] as String? ?? '';

      if (title.isEmpty || sourcecountry.isEmpty) return null;

      // Parse timestamp from "20260801T120000Z" format
      DateTime timestamp;
      try {
        timestamp = DateTime.parse(
          seendate.replaceFirst('T', ' ').replaceFirst('Z', ''),
        );
      } catch (_) {
        timestamp = DateTime.now();
      }

      // Geocode using hardcoded coordinates
      final coords = kCountryCoordinates[sourcecountry];
      if (coords == null) return null;

      return GlobalEvent(
        id: 'gdelt_${url.hashCode}',
        title: title,
        description:
            'Reported by $domain. Tap AI Insight for full analysis. Source: $url',
        category: EventCategory.conflict,
        severity: _parseSeverity(title),
        latitude: coords[0],
        longitude: coords[1],
        locationName: sourcecountry,
        timestamp: timestamp,
        source: EventSource.gdelt,
        sourceUrl: url,
        metadata: {'domain': domain},
      );
    } catch (e) {
      return null;
    }
  }

  EventSeverity _parseSeverity(String title) {
    final lower = title.toLowerCase();

    // Critical keywords
    if (lower.contains('massacre') ||
        lower.contains('genocide') ||
        lower.contains('nuclear') ||
        lower.contains('chemical attack') ||
        lower.contains('mass casualty') ||
        lower.contains('war crimes')) {
      return EventSeverity.critical;
    }

    // High keywords
    if (lower.contains('attack') ||
        lower.contains('bombing') ||
        lower.contains('killed') ||
        lower.contains('airstrike') ||
        lower.contains('explosion') ||
        lower.contains('coup') ||
        lower.contains('invasion') ||
        lower.contains('war')) {
      return EventSeverity.high;
    }

    // Medium keywords
    if (lower.contains('protest') ||
        lower.contains('clash') ||
        lower.contains('riot') ||
        lower.contains('strike') ||
        lower.contains('arrested') ||
        lower.contains('conflict') ||
        lower.contains('tensions')) {
      return EventSeverity.medium;
    }

    // Default for unknown
    return EventSeverity.low;
  }
}

class GDELTException implements Exception {
  final String message;
  const GDELTException(this.message);

  @override
  String toString() => 'GDELTException: $message';
}
