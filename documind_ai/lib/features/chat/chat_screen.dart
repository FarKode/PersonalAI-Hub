import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'providers/chat_provider.dart';
import 'models/chat_message.dart';
import '../monetization/ui/paywall_bottom_sheet.dart';
import '../monetization/services/usage_tracker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/widgets/animated_equalizer.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final int docId;
  final String docName;

  const ChatScreen({super.key, required this.docId, required this.docName});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final FlutterTts _flutterTts = FlutterTts();
  int? _playingIndex;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).setDocId(widget.docId);
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _speak(int index, String text) async {
    if (_playingIndex == index) {
      await _flutterTts.stop();
      if (mounted) setState(() => _playingIndex = null);
    } else {
      await _flutterTts.stop();
      setState(() => _playingIndex = index);
      await _flutterTts.speak(text);
      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _playingIndex = null);
      });
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      final canSend = await ref.read(usageTrackerProvider).canSendDocumentMessage();
      if (!canSend) {
        PaywallBottomSheet.show(context, title: "Daily Limit Reached", message: "You have used your 3 free Document Mind messages today. Upgrade to Pro for unlimited chatting!");
        return;
      }
      await ref.read(usageTrackerProvider).incrementDocumentMessage();

      _controller.clear();
      _scrollToBottom();
      try {
        await ref.read(chatProvider.notifier).sendMessage(text);
      } catch (e) {
        // Error handling
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final isTyping = ref.watch(chatProvider.notifier).isTyping;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docName, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton.icon(
            onPressed: () {
              ref.read(chatProvider.notifier).generateSummary();
              _scrollToBottom();
            },
            icon: const Icon(Icons.auto_awesome, color: AppTheme.neonPurple),
            label: const Text('1-Click Summary', style: TextStyle(color: AppTheme.neonPurple)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length) {
                  return const _TypingIndicator();
                }
                return _MessageBubble(
                  message: messages[index],
                  isPlaying: _playingIndex == index,
                  onRegenerate: () {
                    // Find the last user message before this AI message
                    int lastUserIdx = -1;
                    for (int i = index - 1; i >= 0; i--) {
                      if (messages[i].role == ChatRole.user) {
                        lastUserIdx = i;
                        break;
                      }
                    }
                    if (lastUserIdx != -1) {
                      _controller.text = messages[lastUserIdx].text;
                      _sendMessage();
                    }
                  },
                  onSpeak: () => _speak(index, messages[index].text.replaceAll(RegExp(r'\[Chunk (\d+)\]'), '')),
                );
              },
            ),
          ),
          _ChatInput(
            controller: _controller,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isPlaying;
  final VoidCallback onRegenerate;
  final VoidCallback onSpeak;

  const _MessageBubble({required this.message, required this.isPlaying, required this.onRegenerate, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    
    // Parse citation tags like [Chunk 12]
    final citationRegex = RegExp(r'\[Chunk (\d+)\]');
    final matches = citationRegex.allMatches(message.text);
    final Set<String> citations = matches.map((m) => m.group(1)!).toSet();
    
    // Clean text by stripping out the raw chunk tags for a cleaner UI
    String cleanText = message.text.replaceAll(citationRegex, '').trim();

    Widget bubble = Container(
      margin: const EdgeInsets.only(bottom: 16),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.85,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? AppTheme.electricBlue : Colors.grey[850],
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
              ),
              boxShadow: isPlaying && !isUser ? [
                BoxShadow(
                  color: AppTheme.neonPurple.withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ] : null,
            ),
            child: Text(
              cleanText.isEmpty && !isUser ? '...' : cleanText,
              style: const TextStyle(fontSize: 16, color: Colors.white, height: 1.4),
            ),
          ),
          if (citations.isNotEmpty && !isUser) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: citations.map((chunkId) {
                return ActionChip(
                  label: Text('Chunk $chunkId', style: const TextStyle(fontSize: 11, color: AppTheme.neonPurple)),
                  backgroundColor: AppTheme.neonPurple.withOpacity(0.1),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.all(0),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Viewing context for Chunk $chunkId...'))
                    );
                  },
                );
              }).toList(),
            )
          ],
          if (!isUser) ...[
            const SizedBox(height: 8),
            const Divider(color: Colors.white24, height: 1),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: cleanText));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share, size: 16, color: Colors.grey),
                  onPressed: () => Share.share(cleanText),
                ),
                IconButton(
                  icon: isPlaying 
                    ? const AnimatedEqualizer()
                    : const Icon(Icons.volume_up, size: 16, color: Colors.grey),
                  onPressed: onSpeak,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16, color: Colors.grey),
                  onPressed: onRegenerate,
                ),
              ],
            )
          ]
        ],
      ),
    );

    if (isPlaying && !isUser) {
      bubble = bubble.animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(duration: 2.seconds, color: Colors.white24);
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: bubble,
    );
  }
}

class _ChatInput extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ChatInput({required this.controller, required this.onSend});

  @override
  ConsumerState<_ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<_ChatInput> {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speechToText.initialize();
  }

  void _startListening() async {
    final canVoice = await ref.read(usageTrackerProvider).canUseVoice();
    if (!canVoice) {
      PaywallBottomSheet.show(context, title: 'Pro Feature', message: 'You have used your free Voice Input limit. Upgrade to Pro for unlimited usage.');
      return;
    }
    await ref.read(usageTrackerProvider).incrementVoiceUsage();

    if (!_isListening) {
      HapticFeedback.mediumImpact();
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(onResult: (result) {
          setState(() {
            widget.controller.text = result.recognizedWords;
          });
        });
      }
    } else {
      HapticFeedback.mediumImpact();
      setState(() => _isListening = false);
      _speechToText.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.amoledBlack,
        border: Border(top: BorderSide(color: Colors.grey[900]!)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: _isListening ? [
                BoxShadow(
                  color: AppTheme.neonPurple.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ] : null,
            ),
            child: IconButton(
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none, 
                color: _isListening ? AppTheme.neonPurple : Colors.grey
              ),
              onPressed: _startListening,
            ),
          ).animate(target: _isListening ? 1 : 0)
           .scaleXY(end: 1.1, duration: 200.ms)
           .then(delay: 200.ms)
           .shimmer(duration: 1.seconds, color: AppTheme.neonPurple.withOpacity(0.5)),
          Expanded(
            child: TextField(
              controller: widget.controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => widget.onSend(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ask about the document...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.electricBlue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: widget.onSend,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(0),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.neonPurple,
              ),
            ),
            SizedBox(width: 12),
            Text('AI is thinking...', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
