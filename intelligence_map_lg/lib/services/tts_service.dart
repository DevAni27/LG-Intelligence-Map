import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import '../data/models/global_event.dart';
import '../core/utils/top_region_helper.dart';
import 'gemini_service.dart';

class TTSService {
  final FlutterTts _tts = FlutterTts();
  final GeminiService _geminiService = GeminiService();

  TTSService() {
    _init();
  }

  Future<void> _init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  //tts for a particular event
  Future<void> speakEventSummary(GlobalEvent event) async {
    final text = _buildEventSpeech(event);
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> speakTourEventSummary(GlobalEvent event) async {
    final text = _buildTourEventSpeech(event);
    await _tts.stop();
    await _tts.speak(text);
  }

  //tts for a specific region
  Future<void> speakRegionSummary(List<GlobalEvent> visibleEvents) async {
    final aiSummary = await _geminiService.generateRegionSummary(visibleEvents);
    final text = _buildRegionSpeech(visibleEvents, aiSummary);
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> speakAndWait(String text) async {
    final completer = Completer();
    _tts.setCompletionHandler(() => completer.complete());
    await _tts.speak(text);
    await completer.future;
  }

  String _buildTourEventSpeech(GlobalEvent event) {
    return '${event.title}. '
        '${_severityToSpeech(event.severity)} severity '
        '${_categoryToSpeech(event.category)} '
        'in ${event.locationName}.';
  }

  String _buildEventSpeech(GlobalEvent event) {
    final desc = event.description.length > 150
        ? event.description.substring(0, 150)
        : event.description;
    return "We are looking at ${event.title}, where the severity level right now is ${event.severity.name.toUpperCase()}. The reason behind this severity level is the occurence of a ${_categoryToSpeech(event.category)} in ${event.locationName}. Let me provide some more details on this, $desc";
  }

  String _buildRegionSpeech(List<GlobalEvent> visibleEvents, String summary) {
    if (visibleEvents.isEmpty) {
      return 'No active events detected in the current map view.';
    }

    final categoryCounts = TopRegionHelper.getCategoryCounts(visibleEvents);
    final topEvent = TopRegionHelper.getTopEvent(visibleEvents);
    final dominant = TopRegionHelper.getDominantCategory(visibleEvents);

    final categoryParts = categoryCounts.entries
        .where((e) => e.value > 0)
        .map((e) => '${e.value} ${e.key.name}')
        .join(', ');

    final topEventSpeech = topEvent != null
        ? 'The most significant event is ${topEvent.title}, '
              'rated ${topEvent.severity.name} severity.'
        : '';

    return 'The current map view shows ${visibleEvents.length} active events, '
        'including $categoryParts. '
        '$topEventSpeech '
        'The dominant event type in this region is ${dominant?.name ?? "unknown"}.'
        '$summary';
  }

  String _categoryToSpeech(EventCategory category) {
    switch (category) {
      case EventCategory.earthquake:
        return 'earthquake';
      case EventCategory.floodStorm:
        return 'flood or storm';
      case EventCategory.wildfire:
        return 'wildfire';
      case EventCategory.diseaseOutbreak:
        return 'disease outbreak';
      case EventCategory.conflict:
        return 'conflict';
    }
  }

  String _severityToSpeech(EventSeverity severity) {
    switch (severity) {
      case EventSeverity.critical:
        return 'critical';
      case EventSeverity.high:
        return 'high';
      case EventSeverity.medium:
        return 'medium';
      case EventSeverity.low:
        return 'low';
    }
  }
}
