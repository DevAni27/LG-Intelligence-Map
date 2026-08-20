import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';
import '../data/models/global_event.dart';
import '../core/utils/top_region_helper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeminiService {
  final Map<String, String> _explanationCache = {};

  //method to get the gemini model

  String? _getApiKey() {
    final box = Hive.box(AppConstants.settingsBox);
    final key = box.get(AppConstants.keyGoogleAIStudioApiKey, defaultValue: '');
    debugPrint('=== API KEY LENGTH: ${key?.length}');
    debugPrint('=== API KEY FIRST 10: ${key?.substring(0, 10)}');
    if (key == null || key.isEmpty) return null;
    return key.trim();
  }

  bool _isProcessing = false;

  Future<String> _callGemini(String prompt) async {
    final apiKey = _getApiKey();
    if (apiKey == null) {
      return 'Please add your API key in Settings to use AI features.';
    }

    if (_isProcessing) {
      return 'Please wait for the current request to complete.';
    }

    _isProcessing = true;

    try {
      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent',
        ),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey, // ← auth key goes here
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {'maxOutputTokens': 1024, 'temperature': 0.7},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Native Gemini API response format
        final candidates = data['candidates'];
        if (candidates == null || candidates.isEmpty) {
          return 'No response received. Please try again.';
        }

        final content = candidates[0]['content'];
        if (content == null) return 'No response received. Please try again.';

        final parts = content['parts'];
        if (parts == null || parts.isEmpty) {
          return 'No response received. Please try again.';
        }

        return parts[0]['text'] ?? 'No response received. Please try again.';
      } else {
        debugPrint('=== ERROR STATUS: ${response.statusCode}');
        debugPrint('=== ERROR BODY: ${response.body}');
        return 'Error ${response.statusCode}: Please try again.';
      }
    } catch (e) {
      return 'Failed to get response: ${e.toString()}';
    } finally {
      _isProcessing = false;
    }
  }

  //ask a question method(ask ai screen)

  String _buildAskPrompt(String question, List<GlobalEvent> events) {
    // Balanced sample across all categories
    final earthquakes = events
        .where((e) => e.category == EventCategory.earthquake)
        .take(40)
        .toList();
    final disasters = events
        .where(
          (e) =>
              e.category == EventCategory.floodStorm ||
              e.category == EventCategory.wildfire,
        )
        .take(30)
        .toList();
    final disease = events
        .where((e) => e.category == EventCategory.diseaseOutbreak)
        .take(40)
        .toList();
    final conflict = events
        .where((e) => e.category == EventCategory.conflict)
        .take(20)
        .toList();

    final sample = [...earthquakes, ...disasters, ...disease, ...conflict];
    final totalCount = events.length;
    final eventCount = sample.length;

    final eventList = sample
        .map(
          (e) =>
              '${e.title} | ${e.locationName} | ${e.severity.name} | ${e.category.name}',
        )
        .join('\n');

    return '''You are Global Pulse, an AI assistant into a real-time world event monitoring system.
Current live events (analyzing $eventCount of $totalCount total active events):
$eventList

Important: Total active events in system: $totalCount. When asked about counts clarify you are working from this sample.

Rules:
- Answer in 1-2 short paragraphs
- Use simple conversational English
- Only reference events from the list above
- Never say you are an AI or reading a list
- You ONLY answer questions related to current global events, disasters, disease outbreaks, conflicts, or world news
- If the question is unrelated to global events say exactly: "I can only answer questions about current global events. Try asking about earthquakes, disasters, disease outbreaks, or what is happening in a specific region."
- Never answer general knowledge, geography trivia, or personal questions
- If answer relates to a specific location add on final line: FLYTO:[name]|[lat]|[lon]
- Add FLYTO for any specific location mentioned — country, city, OR region (like Asia, Africa, Europe)
- For regions use approximate center coordinates: Asia = 34|100, Africa = 0|20, Europe = 50|10, Americas = 15|-90
- Never add FLYTO for truly global questions only
- Never add FLYTO:|0|0
- You can also answer questions about famous historical events 
  (earthquakes, tsunamis, disasters, conflicts, pandemics) 
  using your training knowledge
- For historical events always add FLYTO with the event location
- For historical events also add on a new line: 
  HISTORICAL:[full event name and year]
- Only add HISTORICAL for specific well-known named events
- Never add HISTORICAL for general or current event questions

Question: $question''';
  }

  Future<String> askQuestion(String question, List<GlobalEvent> events) async {
    try {
      final prompt = _buildAskPrompt(question, events);
      final response = await _callGemini(prompt);
      return response;
    } catch (e) {
      return 'Failed to get response: ${e.toString()}';
    }
  }

  //method to generate region summary

  String _buildRegionPrompt(List<GlobalEvent> visibleEvents) {
    final dominant = TopRegionHelper.getDominantCategory(visibleEvents);
    final severityCount = TopRegionHelper.getSeverityCounts(visibleEvents);
    final totalEvents = visibleEvents.length;
    final urgentEvents = visibleEvents
        .where(
          (event) =>
              event.severity == EventSeverity.high ||
              event.severity == EventSeverity.critical,
        )
        .toList();

    return '''You are a regional event analyst. 
    Overall statistics of the region: 
    - Total events: $totalEvents
    - Severity Count: $severityCount
    - Dominant Category: $dominant

    Most urgent events: $urgentEvents

    Rules:
    - Generate 2-3 sentences of what is happening in the region.
    - Use simple conversational English and no use of bullet points.
    - Refer to the list of events and focus on the most severe and high or critical risk events.
    - Never say you are an AI or reading a list
    ''';
  }

  Future<String> generateRegionSummary(List<GlobalEvent> visibleEvents) async {
    if (visibleEvents.isEmpty) {
      return 'No active events detected in this region.';
    }

    try {
      final prompt = _buildRegionPrompt(visibleEvents);
      final response = await _callGemini(prompt);
      return response;
    } catch (e) {
      return 'Failed to get response: ${e.toString()}';
    }
  }

  //method to explain event(AI insight)

  String _buildEventPrompt(GlobalEvent event) {
    return '''You are Global Pulse, a real-time world event assistant.
    Event Details:
    - Event title: ${event.title}
    - Event category: ${event.category.name}
    - Event severity: ${event.severity.name}
    - Event location: ${event.locationName}
    - Event description: ${event.description}

    Rules:
    - Generate 2-3 sentences which explain what this means, why it matters, and likely ground impact.
    - Refer to the event details provided for better understanding.
    - Use simple conversational English and no use of bullet points.
    - Never say you are an AI or reading a list
    ''';
  }

  Future<String> eventExplain(GlobalEvent event) async {
    try {
      //checking cache first before calling the model
      if (_explanationCache.containsKey(event.id)) {
        return _explanationCache[event.id]!;
      }

      final prompt = _buildEventPrompt(event);
      final response = await _callGemini(prompt);

      _explanationCache[event.id] = response;
      return response;
    } catch (e) {
      return 'Failed to get response: ${e.toString()}';
    }
  }

  //method for the daily global pulse feature

  String _buildDailyPulsePrompt(List<GlobalEvent> recentEvents) {
    final urgentEvents = recentEvents
        .where(
          (e) =>
              e.severity == EventSeverity.high ||
              e.severity == EventSeverity.critical,
        )
        .toList();

    final dominant = TopRegionHelper.getDominantCategory(recentEvents);
    final topEvent = TopRegionHelper.getTopEvent(recentEvents);

    final eventList = urgentEvents
        .take(20)
        .map((e) => '${e.title} | ${e.locationName} | ${e.severity.name}')
        .join('\n');

    return '''You are Global Pulse, a real-time world event assistant.

Last 24 hours overview:
- Total events: $eventList
- Most affected event type: $dominant
- Most critical event: $topEvent

Urgent events:
$urgentEvents

Rules:
- Write a 120-150 word spoken briefing like a news anchor
- Cover the most significant events and high risk regions
- Flowing natural sentences, no bullet points, no headers
- Start with: "Here is your Global Pulse briefing."
- End with: "Stay informed and stay safe."
- Never mention you are an AI or reading a list''';
  }

  Future<String> generateDailyPulse(List<GlobalEvent> events) async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final recentEvents = events
        .where((e) => e.timestamp.isAfter(cutoff))
        .toList();

    if (recentEvents.isEmpty) {
      return 'No significant events recorded in the last 24 hours.';
    }

    try {
      final prompt = _buildDailyPulsePrompt(recentEvents);
      final response = await _callGemini(prompt);
      return response;
    } catch (e) {
      return 'Failed to get response: ${e.toString()}';
    }
  }

  FlyToSuggestion? parseFlyTo(String response) {
    final word = "FLYTO:";
    final check = response.contains(word);

    if (!check) {
      return null;
    }
    List<String> lines = response.split('\n');
    final flytoLine = lines.firstWhere((line) => line.startsWith(word));
    String result = flytoLine.replaceAll(word, "").replaceAll("  ", " ").trim();

    List<String> info = result.split("|");

    if (info.length != 3) return null;

    final locName = info[0].trim();
    final lat = double.tryParse(info[1].trim());
    final lon = double.tryParse(info[2].trim());
    if (lat == null || lon == null) return null;

    //check if the location is global, worldwide, etc [0,0]

    if (locName.toLowerCase() == 'global') return null;
    if (locName.toLowerCase() == 'worldwide') return null;
    if (locName.toLowerCase() == 'world') return null;
    if (lat == 0.0 && lon == 0.0) return null;

    return FlyToSuggestion(
      locationName: locName,
      latitude: lat,
      longitude: lon,
    );
  }

  String? parseHistoricalEvent(String response) {
    final lines = response.split('\n');
    final line = lines.firstWhere(
      (l) => l.trim().startsWith('HISTORICAL:'),
      orElse: () => '',
    );
    if (line.isEmpty) return null;
    return line.replaceFirst('HISTORICAL:', '').trim();
  }

  Future<String> generateHistoricalSummary(String eventName) async {
    return await _callGemini('''
You are Global Pulse, a world event analyst.
Provide a structured factual summary of this historical event: $eventName

Return ONLY this exact format with no extra text:
DATE: [when it happened]
LOCATION: [where it happened]
SCALE: [magnitude/size/death toll if known]
DESCRIPTION: [2-3 sentences on what happened and its impact]
SIGNIFICANCE: [1 sentence on why it matters historically]
''');
  }
}

class FlyToSuggestion {
  final String locationName;
  final double latitude;
  final double longitude;

  const FlyToSuggestion({
    required this.locationName,
    required this.latitude,
    required this.longitude,
  });
}
