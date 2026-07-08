import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/ai_provider.dart';
import '../monetization/providers/entitlement_provider.dart';
import '../monetization/services/billing_service.dart';
import '../monetization/ui/paywall_bottom_sheet.dart';
import '../auth/provider_bottom_sheet.dart';
import '../../core/widgets/premium_background.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(entitlementProvider);

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonPurple.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                      image: const DecorationImage(
                        image: AssetImage('assets/images/app_logo.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PersonalAI Hub',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Pro Card
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPro 
                    ? [AppTheme.neonPurple.withOpacity(0.2), AppTheme.electricBlue.withOpacity(0.2)]
                    : [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isPro ? AppTheme.neonPurple.withOpacity(0.5) : Colors.white.withOpacity(0.1),
                ),
              ),
              child: ListTile(
                onTap: () {
                  if (!isPro) {
                    PaywallBottomSheet.show(context, title: 'Upgrade to Pro', message: 'Unlock unlimited access to all features forever.');
                  }
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isPro ? AppTheme.neonPurple.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPro ? Icons.workspace_premium : Icons.stars_rounded,
                    color: isPro ? AppTheme.neonPurple : Colors.grey[300],
                    size: 28,
                  ),
                ),
                title: Text(
                  isPro ? 'Pro Member' : 'Upgrade to Pro',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Text(
                  isPro ? 'Lifetime access unlocked' : 'Unlock unlimited documents & chats',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
                trailing: isPro 
                  ? const Icon(Icons.check_circle, color: AppTheme.neonPurple)
                  : ElevatedButton(
                      onPressed: () async {
                        HapticFeedback.selectionClick();
                        try {
                          await ref.read(billingServiceProvider).restorePurchases();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Purchase restored successfully')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to restore purchases')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Restore'),
                    ),
              ),
            ),
            const SizedBox(height: 32),

            // Account Section
            const Text('Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.electricBlue)),
            const SizedBox(height: 12),
            _buildSettingsTile(
              icon: Icons.vpn_key_rounded,
              title: 'AI Provider Configuration',
              subtitle: 'Manage your AI Provider & API Keys',
              onTap: () async {
                HapticFeedback.lightImpact();
                await ProviderBottomSheet.show(context);
              },
            ),

            const SizedBox(height: 24),

            // Resources Section
            const Text('Resources', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.electricBlue)),
            const SizedBox(height: 12),
            _buildSettingsTile(
              icon: Icons.menu_book_rounded,
              title: 'API Setup Guide',
              onTap: () => _launchUrl('https://github.com/yourusername/documind-ai/blob/main/API_GUIDE.md'),
            ),
            _buildSettingsTile(
              icon: Icons.privacy_tip_rounded,
              title: 'Privacy & Legal',
              onTap: () => _launchUrl('https://github.com/yourusername/documind-ai/blob/main/LEGAL.md'),
            ),
            _buildSettingsTile(
              icon: Icons.subscriptions_rounded,
              title: 'Manage Subscription',
              onTap: () => _launchUrl('https://play.google.com/store/account/subscriptions'),
            ),

            const SizedBox(height: 24),

            // Support Section
            const Text('Support', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.electricBlue)),
            const SizedBox(height: 12),
            _buildSettingsTile(
              icon: Icons.star_rate_rounded,
              title: 'Rate App',
              onTap: () => _launchUrl('https://play.google.com/store/apps/details?id=com.farkode.documind_ai'),
            ),
            _buildSettingsTile(
              icon: Icons.share_rounded,
              title: 'Share App',
              onTap: () {
                Share.share('Check out PersonalAI Hub - your local AI document assistant! https://play.google.com/store/apps/details?id=com.farkode.documind_ai');
              },
            ),
            _buildSettingsTile(
              icon: Icons.email_rounded,
              title: 'Contact Support',
              onTap: () => _launchUrl('mailto:farkode.dev@gmail.com?subject=PersonalAI%20Hub%20Support'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.electricBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.electricBlue, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)) : null,
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
      ),
    );
  }
}
