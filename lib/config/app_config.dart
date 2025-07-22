// lib/config/app_config.dart
class AppConfig {
  static const String appName = 'PitchUp';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
// API Endpoints
  static const String baseUrl = 'https://api.pitchup.app';
  static const String privacyPolicyUrl = 'https://pitchup.app/privacy';
  static const String termsOfServiceUrl = 'https://pitchup.app/terms';
// Video constraints
  static const int maxVideoDuration = 60; // seconds
  static const int maxVideoSize = 100 * 1024 * 1024; // 100MB
// Pagination
  static const int pageSize = 20;
// Cache
  static const int cacheMaxAge = 7; // days
  static const int cacheMaxSize = 100 * 1024 * 1024; // 100MB
}