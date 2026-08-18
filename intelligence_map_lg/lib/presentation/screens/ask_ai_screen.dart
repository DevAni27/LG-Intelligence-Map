import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/chat_message.dart';
import '../../presentation/blocs/events/events_bloc.dart';
import '../../services/gemma_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/fly_to_suggestion_card.dart';

class AskAIScreen extends StatefulWidget {
  const AskAIScreen({super.key});

  @override
  State<AskAIScreen> createState() => _AskAIScreenState();
}

class _AskAIScreenState extends State<AskAIScreen>
    with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAiTyping = false;

  bool _hasSentMessage = false;

  late final AnimationController _headerAnimController;
  late final Animation<double> _headerScaleAnim;
  late final Animation<Alignment> _headerAlignAnim;
  late final Animation<double> _headerOpacityAnim;

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _headerScaleAnim = Tween<double>(begin: 1.0, end: 0.75).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeInOut),
    );
    _headerAlignAnim =
        AlignmentTween(begin: Alignment.center, end: Alignment.topLeft).animate(
          CurvedAnimation(
            parent: _headerAnimController,
            curve: Curves.easeInOut,
          ),
        );
    _headerOpacityAnim = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _messageController.clear();

    if (!_hasSentMessage) {
      setState(() => _hasSentMessage = true);
      _headerAnimController.forward();
    }

    setState(() {
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
    final historicalEvent = gemma.parseHistoricalEvent(result);

    final cleanResult = result
        .split('\n')
        .where(
          (line) =>
              !line.trim().startsWith('FLYTO:') &&
              !line.trim().startsWith('HISTORICAL:'),
        )
        .join('\n')
        .trim();

    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          content: cleanResult,
          isUser: false,
          flyTo: flytoResult,
          historicalEvent: historicalEvent,
        ),
      );
      _isAiTyping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Animated Header
          _buildAnimatedHeader(context),

          Expanded(
            child: _hasSentMessage
                ? ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: _messages.length + (_isAiTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isAiTyping && index == 0) {
                        return _buildTypingIndicator();
                      }
                      final messageIndex = _isAiTyping ? index - 1 : index;
                      return _buildChatBubble(_messages[messageIndex]);
                    },
                  )
                : _buildEmptyState(context),
          ),

          // Input bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _buildMessageComposer(),
          ),
        ],
      ),
    );
  }

  // Animated header
  Widget _buildAnimatedHeader(BuildContext context) {
    if (!_hasSentMessage) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: _headerContent(context, large: true),
      );
    }

    return AnimatedBuilder(
      animation: _headerAnimController,
      builder: (_, __) => Opacity(
        opacity: _headerOpacityAnim.value,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: _headerContent(context, large: false),
        ),
      ),
    );
  }

  Widget _headerContent(BuildContext context, {required bool large}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: large
          ? Column(
              key: const ValueKey('large'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Ask AI',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.auto_awesome,
                      size: 24,
                      color: AppTheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Natural language global intelligence',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            )
          : Row(
              key: const ValueKey('small'),
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 24,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Ask AI',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 28,
                  ),
                ),
              ],
            ),
    );
  }

  //Empty state
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 32,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Global Intelligence at your fingertips',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Ask anything about current world events.\nTry "What\'s happening in Asia?" or\n"Tell me about the 2004 tsunami"',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.6,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('🌏 Events in Asia'),
                _buildSuggestionChip('🔴 Critical alerts'),
                _buildSuggestionChip('🌋 Active volcanoes'),
                _buildSuggestionChip('🦠 Disease outbreaks'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String label) {
    return GestureDetector(
      onTap: () =>
          _handleSubmitted(label.replaceAll(RegExp(r'[^\w\s]'), '').trim()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1421),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  //Typing indicator
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI avatar
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 14,
              color: AppTheme.primary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1421),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: _AnimatedDots(),
          ),
        ],
      ),
    );
  }

  //Chat card
  Widget _buildChatBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: message.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (message.isUser)
            Padding(
              padding: const EdgeInsets.only(bottom: 5, right: 4),
              child: Text(
                'You',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 36),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Global Pulse AI',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!message.isUser)
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8, bottom: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 13,
                    color: AppTheme.primary,
                  ),
                ),

              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? const Color(0xFF0E4D5C)
                        : const Color(0xFF0D1421),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(message.isUser ? 18 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 18),
                    ),
                    border: Border.all(
                      color: message.isUser
                          ? AppTheme.primary.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: message.isUser
                              ? Colors.white
                              : const Color(0xFFCBD5E1),
                          fontSize: 14,
                          height: 1.55,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      if (!message.isUser) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Based on latest events sample',
                          style: TextStyle(
                            color: AppTheme.primary.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],

                      // FlyTo card
                      if (!message.isUser && message.flyTo != null) ...[
                        const SizedBox(height: 10),
                        FlyToSuggestionCard(
                          flyTo: message.flyTo!,
                          historicalEvent: message.historicalEvent,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Input composer
  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1421),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _isAiTyping
              ? AppTheme.primary.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.09),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Ask anything about global events...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 5),
                fillColor: const Color(0xFF0D1421),
              ),
              onSubmitted: _handleSubmitted,
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isAiTyping
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 32,
                    height: 32,
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    ),
                  )
                : GestureDetector(
                    key: const ValueKey('send'),
                    onTap: () => _handleSubmitted(_messageController.text),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

//three-dot typing indicator
class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _animations = _controllers.map((c) {
      return Tween<double>(
        begin: 0.0,
        end: -6.0,
      ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut));
    }).toList();

    // Stagger the dots
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (_, __) => Padding(
            padding: EdgeInsets.only(right: i < 2 ? 5.0 : 0),
            child: Transform.translate(
              offset: Offset(0, _animations[i].value),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
