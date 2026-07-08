import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/premium_background.dart';
import '../../../../core/services/ai_service.dart';
import '../../history/services/history_service.dart';
import '../../../../core/database/models/agent_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/widgets/animated_equalizer.dart';
import '../../monetization/services/usage_tracker.dart';
import '../../monetization/ui/paywall_bottom_sheet.dart';

class QuickChatScreen extends ConsumerStatefulWidget {
  const QuickChatScreen({super.key});

  @override
  ConsumerState<QuickChatScreen> createState() => _QuickChatScreenState();
}

class _QuickChatScreenState extends ConsumerState<QuickChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  AgentSession? _currentSession;
  String _systemPersona = "You are a helpful, smart, and friendly AI assistant.";

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  final FlutterTts _flutterTts = FlutterTts();
  int? _playingIndex;

  final List<String> _quickPrompts = [
    'Write a short poem about AI',
    'Explain quantum computing simply',
    'What are the best habits for productivity?',
    'Tell me a joke'
  ];

  @override
  void initState() {
    super.initState();
    _loadPersona();
    _speechToText.initialize();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speechToText.stop();
    _controller.dispose();
    super.dispose();
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
            _controller.text = result.recognizedWords;
          });
        });
      }
    } else {
      HapticFeedback.mediumImpact();
      setState(() => _isListening = false);
      _speechToText.stop();
    }
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

  Future<void> _loadPersona() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _systemPersona = prefs.getString('quick_chat_persona') ?? "You are a helpful, smart, and friendly AI assistant.";
    });
  }

  Future<void> _savePersona(String persona) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quick_chat_persona', persona);
    setState(() {
      _systemPersona = persona;
    });
  }

  void _showPersonaSettings() {
    final canUse = ref.read(usageTrackerProvider).canUseCustomPersona();
    if (!canUse) {
      PaywallBottomSheet.show(context, title: 'Pro Feature', message: 'Custom AI Personas are only available for Pro users.');
      return;
    }

    final controller = TextEditingController(text: _systemPersona);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.amoledBlack,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Custom System Persona', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'E.g., You are a senior software engineer...',
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonPurple, padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () {
                  _savePersona(controller.text.trim());
                  Navigator.pop(context);
                },
                child: const Text('Save Persona', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final canChat = await ref.read(usageTrackerProvider).canUseQuickChat();
    if (!canChat) {
      PaywallBottomSheet.show(context, title: 'Daily Limit Reached', message: 'You have used your 5 free Quick Chat messages today. Upgrade to Pro to continue.');
      return;
    }
    await ref.read(usageTrackerProvider).incrementQuickChat();

    final historyService = ref.read(historyServiceProvider);

    if (_currentSession == null) {
      String title = text.replaceAll('\n', ' ');
      if (title.length > 30) title = '${title.substring(0, 30)}...';
      _currentSession = historyService.createSession(agentType: 'Quick Chat', title: title);
    }

    historyService.addMessageToSession(_currentSession!.id, 'user', text);

    setState(() {
      _messages.add({"role": "user", "text": text});
      _isLoading = true;
    });
    _controller.clear();

    try {
      final aiService = ref.read(aiServiceProvider);
      final response = await aiService.generateText(
        systemPrompt: _systemPersona,
        userPrompt: text,
      );

      if (mounted) {
        historyService.addMessageToSession(_currentSession!.id, 'ai', response);

        setState(() {
          _messages.add({"role": "ai", "text": response});
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({"role": "ai", "text": "Error: $e"});
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Quick Chat'),
          actions: [
            IconButton(
              icon: const Icon(Icons.psychology),
              onPressed: () {
                HapticFeedback.lightImpact();
                _showPersonaSettings();
              },
            ),
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push('/history', extra: 'Quick Chat');
              },
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg["role"] == "user";
                  final isPlaying = _playingIndex == index;
                  
                  Widget bubble = Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.electricBlue : Colors.grey[800],
                      borderRadius: BorderRadius.circular(12).copyWith(
                        bottomRight: isUser ? Radius.zero : const Radius.circular(12),
                        bottomLeft: !isUser ? Radius.zero : const Radius.circular(12),
                      ),
                      boxShadow: isPlaying && !isUser ? [
                        BoxShadow(
                          color: AppTheme.neonPurple.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ] : null,
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(msg["text"] ?? '', style: const TextStyle(color: Colors.white)),
                          if (!isUser) ...[
                            const SizedBox(height: 8),
                            const Divider(color: Colors.white24, height: 1),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: msg["text"] ?? ''));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share, size: 16, color: Colors.grey),
                                  onPressed: () => Share.share(msg["text"] ?? ''),
                                ),
                                IconButton(
                                  icon: isPlaying 
                                    ? const AnimatedEqualizer()
                                    : const Icon(Icons.volume_up, size: 16, color: Colors.grey),
                                  onPressed: () => _speak(index, msg["text"] ?? ''),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 16, color: Colors.grey),
                                  onPressed: () {
                                    // simple regenerate logic: send same prompt
                                    // Need to find last user message
                                    final lastUser = _messages.lastWhere((m) => m['role'] == 'user', orElse: () => {});
                                    if (lastUser.isNotEmpty) {
                                      _controller.text = lastUser['text']!;
                                      _sendMessage();
                                    }
                                  },
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
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            Container(
              color: AppTheme.amoledBlack,
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: _quickPrompts.map((prompt) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            label: Text(prompt, style: const TextStyle(fontSize: 12)),
                            backgroundColor: Colors.orangeAccent.withOpacity(0.1),
                            side: BorderSide(color: Colors.orangeAccent.withOpacity(0.5)),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _controller.text = prompt;
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
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
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: "Type your message...",
                              filled: true,
                              fillColor: Colors.grey[900],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: AppTheme.neonPurple,
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _isLoading ? null : _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
