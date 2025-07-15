import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsManager {
  static final AnalyticsManager _instance = AnalyticsManager._internal();
  factory AnalyticsManager() => _instance;
  AnalyticsManager._internal();

  static AnalyticsManager get instance => _instance;

  late FirebaseAnalytics _analytics;
  late FirebaseAnalyticsObserver _observer;

  FirebaseAnalytics get analytics => _analytics;
  FirebaseAnalyticsObserver get observer => _observer;

  Future<void> initialize() async {
    _analytics = FirebaseAnalytics.instance;
    _observer = FirebaseAnalyticsObserver(analytics: _analytics);

    // Set user properties
    await _analytics.setAnalyticsCollectionEnabled(!kDebugMode);
  }

  // User events
  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  // Screen events
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenName,
    );
  }

  // Video events
  Future<void> logVideoView(String videoId, int duration) async {
    await _analytics.logEvent(
      name: 'video_view',
      parameters: {
        'video_id': videoId,
        'duration': duration,
      },
    );
  }

  Future<void> logVideoLike(String videoId) async {
    await _analytics.logEvent(
      name: 'video_like',
      parameters: {'video_id': videoId},
    );
  }

  Future<void> logVideoShare(String videoId, String method) async {
    await _analytics.logShare(
      contentType: 'video',
      itemId: videoId,
      method: method,
    );
  }

  Future<void> logVideoUpload() async {
    await _analytics.logEvent(name: 'video_upload');
  }

  // Offer events
  Future<void> logOfferSent(String videoId, double amount) async {
    await _analytics.logEvent(
      name: 'offer_sent',
      parameters: {
        'video_id': videoId,
        'amount': amount,
      },
    );
  }

  Future<void> logOfferAccepted(String offerId) async {
    await _analytics.logEvent(
      name: 'offer_accepted',
      parameters: {'offer_id': offerId},
    );
  }

  Future<void> logOfferRejected(String offerId) async {
    await _analytics.logEvent(
      name: 'offer_rejected',
      parameters: {'offer_id': offerId},
    );
  }

  // Custom events
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }
}
