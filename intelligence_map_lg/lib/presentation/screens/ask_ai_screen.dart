import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/chat_message.dart';
import '../../logic/blocs/events/events_bloc.dart';
import '../../services/gemma_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/fly_to_suggestion_card.dart';

class AskAIScreen extends StatefulWidget {
  const AskAIScreen({super.key});

  @override
  State<AskAIScreen> createState() => _AskAIScreenState();
}

class _AskAIScreenState extends State<AskAIScreen> {
  final List<ChatMessage> _messages = [];

  final TextEditingController _messageController = TextEditingController();
  bool _isAiTyping = false;

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _messageController.clear();

    setState(() {
      // Insert new messages at index 0 because the list is reversed
      _messages.insert(0, ChatMessage(content: text, isUser: true));
      _isAiTyping = true;
    });

    //fetch events from bloc
    final state = context.read<EventsBloc>().state;
    final events = state.filteredEvents;

    //calling gemma
    final gemma = context.read<GemmaService>();
    final result = await gemma.askQuestion(text, events);

    //calling fly to parser
    final flytoResult = gemma.parseFlyTo(result);

    final cleanResult = result
        .split('\n')
        .where((line) => !line.trim().startsWith('FLYTO:'))
        .join('\n')
        .trim();

    setState(() {
      _messages.insert(
        0,
        ChatMessage(content: cleanResult, isUser: false, flyTo: flytoResult),
      );
      _isAiTyping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Ask AI',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.auto_awesome,
                      size: 26,
                      color: AppTheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Natural language global intelligence',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          // Messages list — takes all remaining space
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length + (_isAiTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isAiTyping && index == 0) {
                  return _buildTypingIndicator();
                }
                final messageIndex = _isAiTyping ? index - 1 : index;
                return _buildChatBubble(_messages[messageIndex]);
              },
            ),
          ),

          // Input bar — always at bottom
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildMessageComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // three dots here — just use Text for now
            // we'll animate them later if time permits
            const Text(
              '● ● ●',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? const Color.fromARGB(255, 0, 97, 110)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
          border: message.isUser
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: message.isUser ? Colors.white : const Color(0xFFCBD5E1),
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),

            if (!message.isUser)
              Padding(
                padding: const EdgeInsets.only(left: 2, top: 10),
                child: Text(
                  'Based on latest 150 events',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 0, 145, 164),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (!message.isUser && message.flyTo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FlyToSuggestionCard(flyTo: message.flyTo!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ask anything about global events...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: _handleSubmitted,
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          _isAiTyping
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : GestureDetector(
                  onTap: () => _handleSubmitted(_messageController.text),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
