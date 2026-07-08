import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../providers/entitlement_provider.dart';

final billingServiceProvider = Provider((ref) => BillingService(ref));

class BillingService {
  final Ref _ref;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  static const String _proProductId = 'documind_pro_lifetime';

  BillingService(this._ref) {
    _initialize();
  }

  void _initialize() {
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription?.cancel();
    }, onError: (error) {
      debugPrint("Purchase stream error: $error");
    });
  }

  void dispose() {
    _subscription?.cancel();
  }

  Future<bool> isAvailable() => _iap.isAvailable();

  Future<ProductDetails?> getProProduct() async {
    final available = await isAvailable();
    if (!available) return null;

    final response = await _iap.queryProductDetails({_proProductId});
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint("Product not found: $_proProductId");
      return null;
    }
    
    return response.productDetails.first;
  }

  Future<void> buyPro(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Pending UI handled elsewhere or natively
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint("Purchase error: ${purchaseDetails.error}");
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          
          if (purchaseDetails.productID == _proProductId) {
             _ref.read(entitlementProvider.notifier).unlockPro();
          }
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }
}
