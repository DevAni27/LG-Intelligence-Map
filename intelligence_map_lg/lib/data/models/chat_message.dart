import '../../services/gemma_service.dart';


class ChatMessage {
  final String content;
  final bool isUser;
  final FlyToSuggestion? flyTo;
  final String? historicalEvent;  

  ChatMessage({
    required this.content, 
    required this.isUser,
    this.flyTo,
    this.historicalEvent,
  });
}