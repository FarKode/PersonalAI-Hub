import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_theme.dart';
import '../services/billing_service.dart';
import '../providers/entitlement_provider.dart';

class PaywallBottomSheet extends ConsumerStatefulWidget {
  final String title;
  final String message;

  const PaywallBottomSheet({super.key, required this.title, required this.message});

  static void show(BuildContext context, {required String title, required String message}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PaywallBottomSheet(title: title, message: message),
    );
  }

  @override
  ConsumerState<PaywallBottomSheet> createState() => _PaywallBottomSheetState();
}

class _PaywallBottomSheetState extends ConsumerState<PaywallBottomSheet> {
  ProductDetails? _product;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final billing = ref.read(billingServiceProvider);
    final product = await billing.getProProduct();
    if (mounted) {
      setState(() {
        _product = product;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to entitlement changes to pop automatically on success
    ref.listen<bool>(entitlementProvider, (previous, isPro) {
      if (isPro && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pro unlocked! Thank you.'), backgroundColor: AppTheme.electricBlue),
        );
      }
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.amoledBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.neonPurple.withOpacity(0.3), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4, 
            decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2))
          ),
          const SizedBox(height: 24),
          // Fallback if network Lottie fails
          SizedBox(
            height: 120,
            child: Lottie.network(
              'https://assets9.lottiefiles.com/packages/lf20_touohxv0.json', // Premium crown/star animation
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.workspace_premium_rounded, size: 80, color: AppTheme.neonPurple,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Text(
            widget.message, 
            textAlign: TextAlign.center, 
            style: TextStyle(fontSize: 16, color: Colors.grey[400], height: 1.5)
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.neonPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.neonPurple.withOpacity(0.5)),
            ),
            child: const Text(
              'Pay Once. Use Forever. No Subscriptions. (\$9.99)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          _buildFeatureRow(Icons.all_inclusive, 'Unlimited Quick Chats'),
          _buildFeatureRow(Icons.file_copy, 'Unlimited Document Mind'),
          _buildFeatureRow(Icons.mic, 'Unlimited Voice Interactions'),
          _buildFeatureRow(Icons.person, 'Custom AI Personas'),
          const SizedBox(height: 32),
          if (_isLoading)
            const CircularProgressIndicator(color: AppTheme.electricBlue)
          else if (_product == null)
            const Text('Store currently unavailable. Check your connection.', style: TextStyle(color: Colors.redAccent))
          else
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  ref.read(billingServiceProvider).buyPro(_product!);
                },
                child: Text('Unlock Lifetime Pro - ${_product!.price}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.electricBlue, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16))),
        ],
      ),
    );
  }
}
