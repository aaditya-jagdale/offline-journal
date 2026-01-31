import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// Singleton service for handling RevenueCat purchases and subscriptions.
class RevenueCatService {
  RevenueCatService._();
  static final RevenueCatService instance = RevenueCatService._();

  bool _isInitialized = false;
  CustomerInfo? _customerInfo;

  /// The entitlement ID for pro features.
  static const String proEntitlementId = 'pro';

  /// Product identifiers
  static const String jrnlLifetimeId = 'JRNL_lifetime';
  static const String lifetimeId = 'lifetime';

  /// Initialize the RevenueCat SDK.
  Future<void> initialize() async {
    if (_isInitialized) return;

    final apiKey = dotenv.env['REVENUECAT_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('RevenueCat: API key not found in .env');
      return;
    }

    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);

    final config = PurchasesConfiguration(apiKey);
    if (Platform.isAndroid) {
      config.store = Store.playStore;
    }

    await Purchases.configure(config);
    _isInitialized = true;

    // Fetch initial customer info
    try {
      _customerInfo = await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('RevenueCat: Error fetching customer info: $e');
    }

    debugPrint('RevenueCat: Initialized successfully');
  }

  /// Check if the SDK is initialized.
  bool get isInitialized => _isInitialized;

  /// Get current customer info.
  Future<CustomerInfo> getCustomerInfo() async {
    _customerInfo = await Purchases.getCustomerInfo();
    return _customerInfo!;
  }

  /// Check if the user has the pro entitlement.
  Future<bool> isPro() async {
    try {
      final customerInfo = await getCustomerInfo();
      return customerInfo.entitlements.all[proEntitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('RevenueCat: Error checking pro status: $e');
      return false;
    }
  }

  /// Get available offerings.
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('RevenueCat: Error fetching offerings: $e');
      return null;
    }
  }

  /// Present the paywall.
  /// Returns the result of the paywall presentation.
  Future<PaywallResult> presentPaywall() async {
    return await RevenueCatUI.presentPaywall();
  }

  /// Present the paywall only if the user does not have the pro entitlement.
  /// Returns the result of the paywall presentation.
  Future<PaywallResult> presentPaywallIfNeeded() async {
    return await RevenueCatUI.presentPaywallIfNeeded(proEntitlementId);
  }

  /// Present the customer center for subscription management.
  Future<void> presentCustomerCenter() async {
    await RevenueCatUI.presentCustomerCenter();
  }

  /// Restore purchases.
  Future<CustomerInfo> restorePurchases() async {
    final customerInfo = await Purchases.restorePurchases();
    _customerInfo = customerInfo;
    return customerInfo;
  }

  /// Purchase a package using the modern API.
  Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      final params = PurchaseParams.package(package);
      final result = await Purchases.purchase(params);
      _customerInfo = result.customerInfo;
      return result.customerInfo;
    } catch (e) {
      debugPrint('RevenueCat: Error purchasing package: $e');
      rethrow;
    }
  }

  /// Log in a user with their app user ID.
  Future<void> logIn(String appUserId) async {
    await Purchases.logIn(appUserId);
  }

  /// Log out the current user.
  Future<void> logOut() async {
    await Purchases.logOut();
  }

  /// Stream of customer info updates.
  /// Creates a stream from the callback-based listener API.
  Stream<CustomerInfo> get customerInfoStream {
    final controller = StreamController<CustomerInfo>.broadcast();

    void listener(CustomerInfo info) {
      controller.add(info);
    }

    Purchases.addCustomerInfoUpdateListener(listener);

    // Note: The listener remains active for the app lifecycle.
    // Consider calling Purchases.removeCustomerInfoUpdateListener in dispose.
    return controller.stream;
  }
}
