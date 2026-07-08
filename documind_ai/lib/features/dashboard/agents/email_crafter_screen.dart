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

class EmailCrafterScreen extends ConsumerStatefulWidget {
  const EmailCrafterScreen({super.key});

  @override
  ConsumerState<EmailCrafterScreen> createState() => _EmailCrafterScreenState();
}

class _EmailCrafterScreenState extends ConsumerState<EmailCrafterScreen> {
  final TextEditingController _pointsController = TextEditingController();
  String _selectedTone = 'Professional';
  final List<String> _tones = ['Professional', 'Friendly', 'Urgent', 'Apologetic', 'Persuasive'];
  bool _isLoading = false;
  String _generatedEmail = '';

  final List<String> _quickPrompts = [
    'Sick leave for 2 days due to fever',
    'Follow up on the project proposal sent last week',
    'Job application for Senior Flutter Developer role',
    'Thank you note for the amazing interview today'
  ];

  Future<void> _generateEmail() async {
    final points = _pointsController.text.trim();
    if (points.isEmpty) return;

    final canUse = await ref.read(usageTrackerProvider).canUseEmailCrafter();
    if (!canUse) {
      PaywallBottomSheet.show(context, title: "Daily Limit Reached", message: "You have used your free Email generation today. Upgrade to Pro for unlimited emails!");
      return;
    }
    await ref.read(usageTrackerProvider).incrementEmailCrafter();

    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _generatedEmail = '';
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final response = await aiService.generateText(
        systemPrompt: "You are an expert email copywriter. Write an email based on the user's bullet points. Tone: $_selectedTone. Output ONLY the email text, no introductory text.",
        userPrompt: "Bullet points:\n$points",
      );

      if (mounted) {
        // Save to History
        ref.read(historyServiceProvider).createSingleTurnSession(
          'Email Crafter', 
          "Tone: $_selectedTone\nPoints:\n$points", 
          response
        );

        setState(() {
          _generatedEmail = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generatedEmail = "Error generating email: $e";
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
          title: const Text('Email Crafter'),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                HapticFeedback.lightImpact();
                // We'll push with go_router and pass initial filter
                context.push('/history', extra: 'Email Crafter');
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
                        backgroundColor: AppTheme.electricBlue.withOpacity(0.1),
                        side: BorderSide(color: AppTheme.electricBlue.withOpacity(0.5)),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _pointsController.text = prompt;
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Text('1. Enter key points:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              TextField(
                controller: _pointsController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "- Meeting tomorrow at 10 AM\n- Discuss Q3 goals\n- Please prepare slides",
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              const Text('2. Select Tone:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tones.map((tone) {
                  final isSelected = _selectedTone == tone;
                  return ChoiceChip(
                    label: Text(tone),
                    selected: isSelected,
                    selectedColor: AppTheme.electricBlue.withOpacity(0.3),
                    backgroundColor: Colors.grey[900],
                    side: BorderSide(color: isSelected ? AppTheme.electricBlue : Colors.transparent),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedTone = tone);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateEmail,
                icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome),
                label: Text(_isLoading ? 'Crafting...' : 'Generate Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
              if (_generatedEmail.isNotEmpty) ...[
                const Text('Generated Email:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: SelectableText(_generatedEmail, style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _generatedEmail));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard!')));
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy to Clipboard'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
