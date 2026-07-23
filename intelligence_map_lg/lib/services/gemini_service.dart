import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';
import '../data/models/global_event.dart';
import '../core/utils/top_region_helper.dart';

class GeminiService{
  //method to get the gemini model
  GenerativeModel? _getmodel(){
    final apiKey = AppConstants.keyGeminiApiKey;

    if (apiKey == null) {
      return null;
    }
    else{
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      return model;
    }
    
  }

  //ask a question method(ask ai screen)

  String _buildAskPrompt(String question, List<GlobalEvent> events){
    final eventList = events.take(50).map((e) =>
    '${e.title} | ${e.locationName} | ${e.severity.name} | ${e.category.name}'
    ).join('\n');
    return '''You are Global Pulse, an AI assistant into a real-time world event monitoring system.
  Current live events:
  $eventList

  Rules:
  - Answer in 1-2 short paragraphs
  - Use simple conversational English
  - Only reference events from the list above
  - Never say you are an AI or reading a list
  - If answer relates to a specific location add on final line: FLYTO:[name]|[lat]|[lon]

  Question: $question''';
  }
  
  Future<String> askQuestion(String question, List<GlobalEvent> events) async {
    final model = _getmodel();

    if(model == null){
      return "Please add your Gemini API key in Settings to use AI features.";
    }
    
    try{
      final prompt = _buildAskPrompt(question, events);
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No response received. Please try again.';
    }catch(e){
      return 'Failed to get response: ${e.toString()}';
    }  
  }

  //method to generate region summary

  String _buildRegionPrompt(List<GlobalEvent> visibleEvents){
    final dominant = TopRegionHelper.getDominantCategory(visibleEvents);
    final severityCount = TopRegionHelper.getSeverityCounts(visibleEvents);
    final totalEvents = visibleEvents.length;
    final urgentEvents = visibleEvents.where((event) =>
      event.severity == EventSeverity.high || event.severity == EventSeverity.critical
    ).toList();

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

    final model = _getmodel();

    if(model == null){
      return "Please add your Gemini API key in Settings to use AI features.";
    }
    
    try{
      final prompt = _buildRegionPrompt(visibleEvents);
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No response received. Please try again.';
    }catch(e){
      return 'Failed to get response: ${e.toString()}';
    }
  }

  //method to explain event(AI insight)

  String _buildEventPrompt(GlobalEvent event){
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
    final model = _getmodel();
    
    if(model == null){
      return "Please add your Gemini API key in Settings to use AI features.";
    }

    try{
      final prompt = _buildEventPrompt(event);
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No response received. Please try again.';
    }catch(e){
      return 'Failed to get response: ${e.toString()}';
    }

  }

  //method for the daily global pulse feature 

  String _buildDailyPulsePrompt(List<GlobalEvent> recentEvents) {
  final urgentEvents = recentEvents.where((e) =>
    e.severity == EventSeverity.high ||
    e.severity == EventSeverity.critical
  ).toList();

  final dominant = TopRegionHelper.getDominantCategory(recentEvents);
  final topEvent = TopRegionHelper.getTopEvent(recentEvents);

  final eventList = urgentEvents.take(20).map((e) =>
    '${e.title} | ${e.locationName} | ${e.severity.name}'
  ).join('\n');

  return '''You are Global Pulse, a real-time world event assistant.

Last 24 hours overview:
- Total events: ${eventList}
- Most affected event type: ${dominant}
- Most critical event: ${topEvent}

Urgent events:
${urgentEvents}

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
    final recentEvents = events.where((e) => e.timestamp.isAfter(cutoff)).toList();

    if (recentEvents.isEmpty) {
      return 'No significant events recorded in the last 24 hours.';
    }
    
    final model = _getmodel();
    
    if(model == null){
      return "Please add your Gemini API key in Settings to use AI features.";
    }

    try{
      final prompt = _buildDailyPulsePrompt(recentEvents);
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No response received. Please try again.';
    }catch(e){
      return 'Failed to get response: ${e.toString()}';
    }
  }
}