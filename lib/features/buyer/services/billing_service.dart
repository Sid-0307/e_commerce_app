import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class BillingService {
  static final BillingService _instance = BillingService._internal();
  factory BillingService() => _instance;
  BillingService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // Your product ID - must match what you set in Google Play Console
  static const String premiumProductId = 'premium_plan';

  // Product details
  ProductDetails? _premiumProduct;

  Future<void> initialize() async {
    // Check if billing is available
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      throw Exception('In-app purchases not available');
    }

    // Listen to purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription.cancel(),
      onError: (error) => print('Purchase stream error: $error'),
    );

    // Load product details
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    const Set<String> productIds = {premiumProductId};
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);

    if (response.notFoundIDs.isNotEmpty) {
      print('Products not found: ${response.notFoundIDs}');
    }

    if (response.productDetails.isNotEmpty) {
      _premiumProduct = response.productDetails.first;
    }
  }

  Future<bool> purchasePremium() async {
    if (_premiumProduct == null) {
      throw Exception('Premium product not available');
    }

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: _premiumProduct!,
    );

    try {
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      return success;
    } catch (e) {
      print('Purchase error: $e');
      return false;
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final PurchaseDetails purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased) {
        _handleSuccessfulPurchase(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        _handlePurchaseError(purchase);
      }

      // Complete the purchase
      if (purchase.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Update user's premium status in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'isPremium': true,
        'premiumPurchaseDate': Timestamp.now(),
        'premiumTransactionId': purchase.purchaseID,
      });

      print('Premium status updated successfully');
    } catch (e) {
      print('Error updating premium status: $e');
    }
  }

  void _handlePurchaseError(PurchaseDetails purchase) {
    print('Purchase failed: ${purchase.error}');
  }

  Future<bool> checkUserPremiumStatus() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return false;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['isPremium'] == true;
      }
      return false;
    } catch (e) {
      print('Error checking premium status: $e');
      return false;
    }
  }

  Future<int> getUserRequestCount() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return 0;

      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('buyerRequests')
          .get();

      return requestsSnapshot.docs.length;
    } catch (e) {
      print('Error getting request count: $e');
      return 0;
    }
  }

  String get premiumProductPrice => _premiumProduct?.price ?? '₹100';

  void dispose() {
    _subscription.cancel();
  }
}