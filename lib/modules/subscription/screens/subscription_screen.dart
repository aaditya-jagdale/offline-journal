import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:jrnl/services/revenuecat_service.dart';
import 'package:jrnl/riverpod/subscription_rvpd.dart';

/// A screen that displays the RevenueCat paywall.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isLoading = true;
  Offering? _currentOffering;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final offerings = await RevenueCatService.instance.getOfferings();
    if (mounted) {
      setState(() {
        _currentOffering = offerings?.current;
        _isLoading = false;
      });
    }
  }

  void _handlePurchaseCompleted(
    CustomerInfo customerInfo,
    StoreTransaction transaction,
  ) {
    // Refresh subscription state
    ref.invalidate(customerInfoProvider);
    ref.invalidate(isProProvider);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Purchase successful! Thank you for subscribing.'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate back
    Navigator.of(context).pop();
  }

  void _handleRestoreCompleted(CustomerInfo customerInfo) {
    // Refresh subscription state
    ref.invalidate(customerInfoProvider);
    ref.invalidate(isProProvider);

    final isPro =
        customerInfo
            .entitlements
            .all[RevenueCatService.proEntitlementId]
            ?.isActive ??
        false;

    if (isPro) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchases restored successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No previous purchases found.')),
      );
    }
  }

  void _handleDismiss() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: PaywallView(
          offering: _currentOffering,
          onPurchaseCompleted: _handlePurchaseCompleted,
          onRestoreCompleted: _handleRestoreCompleted,
          onDismiss: _handleDismiss,
        ),
      ),
    );
  }
}

/// Helper widget to show paywall as a modal.
class PaywallModal {
  /// Show the paywall using RevenueCat's built-in presentation.
  static Future<PaywallResult> show() async {
    return await RevenueCatService.instance.presentPaywall();
  }

  /// Show the paywall only if user doesn't have pro entitlement.
  static Future<PaywallResult> showIfNeeded() async {
    return await RevenueCatService.instance.presentPaywallIfNeeded();
  }

  /// Show the customer center for subscription management.
  static Future<void> showCustomerCenter() async {
    await RevenueCatService.instance.presentCustomerCenter();
  }
}
