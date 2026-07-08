import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/premium_background.dart';
import '../../core/providers/ai_provider.dart';
import '../auth/provider_bottom_sheet.dart';
import '../auth/welcome_setup_bottom_sheet.dart';
import '../monetization/services/api_usage_tracker.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.history_outlined),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push('/history');
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push('/settings');
              },
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 2))],
                ),
              ).animate().fade(duration: 500.ms).slideY(begin: -0.2),
              const SizedBox(height: 8),
              Text(
                'Welcome to your AI Hub. Select an agent to begin.',
                style: TextStyle(fontSize: 15, color: Colors.grey[400], fontWeight: FontWeight.w400),
              ).animate().fade(delay: 200.ms),
              const SizedBox(height: 24),
              _buildUsageCard(context, ref).animate().fade(delay: 300.ms).slideY(begin: 0.2),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _AgentCard(
                      title: 'Document Mind',
                      icon: Icons.auto_stories,
                      color: AppTheme.neonPurple,
                      description: 'Chat with PDFs',
                      onTap: () => _handleAgentTap(context, ref, '/document-mind'),
                    ).animate().fade(delay: 300.ms).scale(),
                    
                    _AgentCard(
                      title: 'Email Crafter',
                      icon: Icons.mark_email_read,
                      color: AppTheme.electricBlue,
                      description: 'Write pro emails',
                      onTap: () => _handleAgentTap(context, ref, '/email-crafter'),
                    ).animate().fade(delay: 400.ms).scale(),

                    _AgentCard(
                      title: 'Language Tutor',
                      icon: Icons.language,
                      color: Colors.greenAccent,
                      description: 'Grammar in Bengali',
                      onTap: () => _handleAgentTap(context, ref, '/language-tutor'),
                    ).animate().fade(delay: 500.ms).scale(),

                    _AgentCard(
                      title: 'Quick Chat',
                      icon: Icons.chat_bubble_outline,
                      color: Colors.cyanAccent,
                      description: 'Instant AI assistant',
                      onTap: () => _handleAgentTap(context, ref, '/quick-chat'),
                    ).animate().fade(delay: 600.ms).scale(),
                  ],
                ),
              ),
              _buildPrivacyFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAgentTap(BuildContext context, WidgetRef ref, String route) async {
    HapticFeedback.selectionClick();
    final config = ref.read(aiProviderConfigProvider).value;
    
    if (config == null || config.apiKey.isEmpty) {
      final success = await WelcomeSetupBottomSheet.show(context);
      if (success == true) {
        if (context.mounted) context.push(route);
      }
    } else {
      context.push(route);
    }
  }

  Widget _buildUsageCard(BuildContext context, WidgetRef ref) {
    final usageTracker = ref.read(apiUsageTrackerProvider);
    return FutureBuilder<Map<String, int>>(
      future: usageTracker.getUsageStats(),
      builder: (context, snapshot) {
        final today = snapshot.data?['today'] ?? 0;
        final total = snapshot.data?['total'] ?? 0;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Today: ', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    Text('$today', style: const TextStyle(color: AppTheme.neonPurple, fontSize: 14, fontWeight: FontWeight.bold)),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      height: 16,
                      width: 1,
                      color: Colors.white24,
                    ),
                    Text('Total: ', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    Text('$total', style: const TextStyle(color: AppTheme.electricBlue, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildPrivacyFooter() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.electricBlue.withOpacity(0.2), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.gpp_good_outlined, // Shield icon
                  color: AppTheme.electricBlue,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '100% Private & Local',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No servers, no tracking. Your data lives only on your device. If you uninstall the app, everything is permanently erased.',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fade(delay: 700.ms).slideY(begin: 0.2);
  }
}

class _AgentCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final VoidCallback onTap;

  const _AgentCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.onTap,
  });

  @override
  State<_AgentCard> createState() => _AgentCardState();
}

class _AgentCardState extends State<_AgentCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.color.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(widget.icon, color: widget.color, size: 32),
                    const Spacer(),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
