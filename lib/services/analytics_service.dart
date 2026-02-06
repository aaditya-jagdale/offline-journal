import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/rendering.dart';

class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._();

  AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // Custom event logging
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint("----------------Logging event failed: $e");
    }
  }

  // User details
  Future<void> setUserId(String? id) async {
    await _analytics.setUserId(id: id);
  }

  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  // Screen tracking
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  // Standard Events
  Future<void> logLogin({String? loginMethod}) async {
    await _analytics.logLogin(loginMethod: loginMethod);
  }

  Future<void> logSignUp({required String signUpMethod}) async {
    await _analytics.logSignUp(signUpMethod: signUpMethod);
  }

  Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  Future<void> logShare({
    required String contentType,
    required String itemId,
    required String method,
  }) async {
    await _analytics.logShare(
      contentType: contentType,
      itemId: itemId,
      method: method,
    );
  }

  Future<void> logSearch({required String searchTerm}) async {
    await _analytics.logSearch(searchTerm: searchTerm);
  }

  Future<void> logTutorialBegin() async {
    await _analytics.logTutorialBegin();
  }

  Future<void> logTutorialComplete() async {
    await _analytics.logTutorialComplete();
  }

  Future<void> logPurchase({
    String? currency,
    double? value,
    String? transactionId,
    List<AnalyticsEventItem>? items,
  }) async {
    await _analytics.logPurchase(
      currency: currency,
      value: value,
      transactionId: transactionId,
      items: items,
    );
  }

  Future<void> logLevelUp({required int level, String? character}) async {
    await _analytics.logLevelUp(level: level, character: character);
  }

  Future<void> logPostScore({
    required int score,
    int? level,
    String? character,
  }) async {
    await _analytics.logPostScore(
      score: score,
      level: level,
      character: character,
    );
  }

  // Settings
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    await _analytics.setAnalyticsCollectionEnabled(enabled);
  }

  Future<void> setDefaultEventParameters(
    Map<String, dynamic>? defaultParameters,
  ) async {
    await _analytics.setDefaultEventParameters(defaultParameters);
  }

  Future<void> resetAnalyticsData() async {
    await _analytics.resetAnalyticsData();
  }

  Future<void> setSessionTimeoutDuration(Duration duration) async {
    await _analytics.setSessionTimeoutDuration(duration);
  }

  Future<void> setConsent({
    bool? adStorageConsentGranted,
    bool? adUserDataConsentGranted,
    bool? adPersonalizationSignalsConsentGranted,
    bool? analyticsStorageConsentGranted,
  }) async {
    await _analytics.setConsent(
      adStorageConsentGranted: adStorageConsentGranted,
      adUserDataConsentGranted: adUserDataConsentGranted,
      adPersonalizationSignalsConsentGranted:
          adPersonalizationSignalsConsentGranted,
      analyticsStorageConsentGranted: analyticsStorageConsentGranted,
    );
  }

  Future<String?> get appInstanceId => _analytics.appInstanceId;

  Future<void> initiateOnDeviceConversionMeasurementWithEmailAddress(
    String email,
  ) async {
    await _analytics.initiateOnDeviceConversionMeasurementWithEmailAddress(
      email,
    );
  }
}
