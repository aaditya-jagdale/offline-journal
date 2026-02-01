import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:jrnl/riverpod/entries_rvpd.dart';
import 'package:jrnl/services/revenuecat_service.dart';

/// Provider for getting the current customer info.
final customerInfoProvider = FutureProvider<CustomerInfo>((ref) async {
  return await RevenueCatService.instance.getCustomerInfo();
});

/// Provider for checking if the user has the pro entitlement.
final isProProvider = FutureProvider<bool>((ref) async {
  return await RevenueCatService.instance.isPro();
});

/// Stream provider for real-time customer info updates.
final customerInfoStreamProvider = StreamProvider<CustomerInfo>((ref) {
  return RevenueCatService.instance.customerInfoStream;
});

/// Derived provider that checks pro status from the stream.
final isProStreamProvider = Provider<AsyncValue<bool>>((ref) {
  final customerInfoAsync = ref.watch(customerInfoStreamProvider);
  return customerInfoAsync.whenData((customerInfo) {
    return customerInfo
            .entitlements
            .all[RevenueCatService.proEntitlementId]
            ?.isActive ??
        false;
  });
});

/// Provider for available offerings.
final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  return await RevenueCatService.instance.getOfferings();
});

/// Provider that checks if user can create a new entry.
/// Combines pro status with entry count check.
/// This is defense layer 2 - the provider layer check.
final canCreateEntryProvider = FutureProvider<bool>((ref) async {
  final isPro = await RevenueCatService.instance.isPro();
  if (isPro) return true;

  final entryCount = await ref.watch(entryCountProvider.future);
  return entryCount < RevenueCatService.freeEntryLimit;
});
