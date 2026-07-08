import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/premium_background.dart';
import '../../../../core/services/ai_service.dart';
import '../../history/services/history_service.dart';
import '../../monetization/services/usage_tracker.dart';
import '../../monetization/ui/paywall_bottom_sheet.dart';

class LanguageTutorScreen extends ConsumerStatefulWidget {
  const LanguageTutorScreen({super.key});

  @override
  ConsumerState<LanguageTutorScreen> createState() => _LanguageTutorScreenState();
}

class _LanguageTutorScreenState extends ConsumerState<LanguageTutorScreen> {
  final TextEditingController _sentenceController = TextEditingController();
  bool _isLoading = false;
  String _explanation = '';

  final List<String> _quickPrompts = [
    'She don\'t like apples.',
    'I have went to the store yesterday.',
    'He is more taller than me.',
    'I look forward to hear from you.'
  ];

  Future<void> _analyzeSentence() async {
    final text = _sentenceController.text.trim();
    if (text.isEmpty) return;

    final canUse = await ref.read(usageTrackerProvider).canUseLanguageTutor();
    if (!canUse) {
      PaywallBottomSheet.show(context, title: "Daily Limit Reached", message: "You have used your free Grammar Check today. Upgrade to Pro for unlimited checks!");
      return;
    }
    await ref.read(usageTrackerProvider).incrementLanguageTutor();

    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _explanation = '';
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final response = await aiService.generateText(
        systemPrompt: "You are a friendly language tutor. The user will give you a sentence. You must:\n1. Correct any grammatical errors.\n2. Explain the corrections in Bengali.",
        userPrompt: text,
      );

      if (mounted) {
        // Save to History
        ref.read(historyServiceProvider).createSingleTurnSession(
          'Language Tutor', 
          text, 
          response
        );

        setState(() {
          _explanation = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _explanation = "Error: $e";
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
          title: const Text('Language Tutor'),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push('/history', extra: 'Language Tutor');
              },
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _quickPrompts.map((prompt) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0, bottom: 16.0),
                      child: ActionChip(
                        label: Text(prompt, maxLines: 1, overflow: TextOverflow.ellipsis),
                        backgroundColor: Colors.greenAccent.withOpacity(0.1),
                        side: BorderSide(color: Colors.greenAccent.withOpacity(0.5)),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _sentenceController.text = prompt;
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Text('Enter a sentence to check:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              TextField(
                controller: _sentenceController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "E.g., She don't like apples.",
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _analyzeSentence,
                icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.spellcheck),
                label: Text(_isLoading ? 'Analyzing...' : 'Check Grammar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
              if (_explanation.isNotEmpty) ...[
                const Text('Tutor\'s Explanation (বাংলা):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: SelectableText(_explanation, style: const TextStyle(fontSize: 16, height: 1.5)),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
