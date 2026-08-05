//WHO API data is fetched to add health related info to the intelligence map.

import 'package:dio/dio.dart';
import '../models/global_event.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/country_coordinates.dart';

class WHOService {
  final Dio _dio;

  WHOService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );

  Future<List<GlobalEvent>> fetchWHOData() async {
    return _fetchFromWHO(ApiEndpoints.who);
  }

  Future<List<GlobalEvent>> _fetchFromWHO(String url) async {
    try {
      final response = await _dio.get(url);
      return _parseWHOData(response.data);
    } on DioException catch (e) {
      throw WHOException('Failed to fetch WHO data: ${e.message}');
    }
  }

  List<GlobalEvent> _parseWHOData(dynamic data) {
    final items = data['value'] as List<dynamic>? ?? [];
    final events = <GlobalEvent>[];

    for (final item in items) {
      final map = item as Map<String, dynamic>;

      final title = map['Title'] as String? ?? '';
      final dateStr = map['PublicationDateAndTime'] as String? ?? '';
      final summary = map['Summary'] as String? ?? '';
      final urlName = map['UrlName'] as String? ?? '';

      //extracting country from the title
      final country = _extractCountry(title);
      if (country == null) {
        continue;
      }
      final coordinates = _getCoordinates(country);
      if (coordinates == null) {
        continue;
      }

      events.add(
        GlobalEvent(
          id: 'who_$urlName',
          title: title,
          description: cleanSummary(summary),
          category: EventCategory.diseaseOutbreak,
          severity: _estimateSeverity(summary),
          latitude: coordinates[0],
          longitude: coordinates[1],
          locationName: country,
          timestamp: DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now(),
          source: EventSource.who,
          sourceUrl:
              'https://www.who.int/emergencies/disease-outbreak-news/item/$urlName',
        ),
      );
    }
    return events;
  }

  String? _extractCountry(String title) {
    if (title.toLowerCase().contains('global') ||
        title.toLowerCase().contains('multi-country') ||
        title.toLowerCase().contains('multi-location') ||
        title.toLowerCase().contains('global situation') ||
        title.toLowerCase().contains('global update')) {
      return null;
    }

    final separators = [' – ', ' - ', '- ', '– '];
    for (final sep in separators) {
      final index = title.lastIndexOf(sep);
      if (index != -1) {
        String country = title.substring(index + sep.length).trim();

        // If multiple countries joined with &, we take the first one
        if (country.contains(' & ')) {
          country = country.split(' & ').first.trim();
        }

        return country;
      }
    }

    return null;
  }

  List<double>? _getCoordinates(String country) {
    if (kCountryCoordinates.containsKey(country)) {
      return kCountryCoordinates[country];
    } else {
      return null;
    }
  }

  EventSeverity _estimateSeverity(String summary) {
    final text = summary.toLowerCase();

    if (text.contains("death") ||
        text.contains("fatal") ||
        text.contains("killed")) {
      return EventSeverity.high;
    }
    if (text.contains("confirmed case") || text.contains("hospitali")) {
      return EventSeverity.medium;
    } else {
      return EventSeverity.low;
    }
  }

  String cleanSummary(String summary) {
    // Remove HTML tags
    final regex = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    String cleaned = summary.replaceAll(regex, '');

    // Replace multiple spaces with a single space
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    final truncated = cleaned.length > 300
        ? cleaned.substring(0, 300)
        : cleaned;
    final lastDot = truncated.lastIndexOf('.');

    return lastDot != -1
        ? truncated.substring(0, lastDot + 1).trim()
        : truncated;
  }
}

class WHOException implements Exception {
  final String message;
  const WHOException(this.message);

  @override
  String toString() => 'WHOException: $message';
}
