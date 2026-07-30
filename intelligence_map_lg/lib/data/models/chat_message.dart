import '../../services/gemma_service.dart';


class ChatMessage {
  final String content;
  final bool isUser;
  final FlyToSuggestion? flyTo;  // ← add this too, for the fly-to card

  ChatMessage({
    required this.content, 
    required this.isUser,
    this.flyTo,
  });
}