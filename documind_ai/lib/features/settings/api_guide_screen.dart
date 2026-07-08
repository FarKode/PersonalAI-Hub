import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/premium_background.dart';

class ApiGuideScreen extends StatelessWidget {
  const ApiGuideScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Get Free API Keys'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Power PersonalAI Hub with Free API Keys from top providers. Follow the steps below.',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            _ProviderGuideCard(
              provider: 'Groq (Lightning Fast & Free)',
              description: 'Groq offers extremely fast inference for Llama 3 models for free.',
              steps: const [
                '1. Go to console.groq.com',
                '2. Sign in with your Google or GitHub account',
                '3. Navigate to "API Keys" on the left menu',
                '4. Click "Create API Key" and copy it',
                '5. In PersonalAI Hub, select "Groq" and paste the key',
              ],
              buttonText: 'Open Groq Console',
              url: 'https://console.groq.com/keys',
              color: Colors.orangeAccent,
              onTapLink: () {
                HapticFeedback.lightImpact();
                _launchUrl('https://console.groq.com/keys');
              },
            ),
            const SizedBox(height: 16),
            _ProviderGuideCard(
              provider: 'Gemini (Google)',
              description: 'Google offers generous free tiers for Gemini models via Google AI Studio.',
              steps: const [
                '1. Go to aistudio.google.com',
                '2. Sign in with your Google account',
                '3. Click "Get API key" on the left menu',
                '4. Click "Create API key in new project"',
                '5. Copy the key and select "Gemini" in PersonalAI Hub',
              ],
              buttonText: 'Open AI Studio',
              url: 'https://aistudio.google.com/app/apikey',
              color: Colors.blueAccent,
              onTapLink: () {
                HapticFeedback.lightImpact();
                _launchUrl('https://aistudio.google.com/app/apikey');
              },
            ),
            const SizedBox(height: 16),
            _ProviderGuideCard(
              provider: 'OpenRouter (Best Variety)',
              description: 'Access hundreds of models. They have a "Free" tier for Meta Llama and other open-source models.',
              steps: const [
                '1. Go to openrouter.ai',
                '2. Sign in or create an account',
                '3. Go to "Keys" and create a new key',
                '4. In PersonalAI Hub, select "OpenRouter" and paste it',
              ],
              buttonText: 'Open OpenRouter',
              url: 'https://openrouter.ai/keys',
              color: AppTheme.neonPurple,
              onTapLink: () {
                HapticFeedback.lightImpact();
                _launchUrl('https://openrouter.ai/keys');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderGuideCard extends StatelessWidget {
  final String provider;
  final String description;
  final List<String> steps;
  final String buttonText;
  final String url;
  final Color color;
  final VoidCallback onTapLink;

  const _ProviderGuideCard({
    required this.provider,
    required this.description,
    required this.steps,
    required this.buttonText,
    required this.url,
    required this.color,
    required this.onTapLink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.key, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  provider,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: steps
                  .map((step) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(step, style: const TextStyle(fontSize: 14)),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTapLink,
              icon: const Icon(Icons.open_in_browser),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: color.withOpacity(0.2),
                foregroundColor: color,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
