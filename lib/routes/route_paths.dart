// lib/routes/route_paths.dart
class AppRoutePath {
  final String location;
  final String? id;
  final Map<String, String>? queryParameters;

  AppRoutePath._(this.location, this.id, this.queryParameters);

  // Static routes
  static AppRoutePath splash() => AppRoutePath._('/', null, null);
  static AppRoutePath onboarding() => AppRoutePath._('/onboarding', null, null);
  static AppRoutePath auth() => AppRoutePath._('/auth', null, null);
  static AppRoutePath roleSelection() =>
      AppRoutePath._('/role-selection', null, null);

  // Main app routes
  static AppRoutePath discover() => AppRoutePath._('/discover', null, null);
  static AppRoutePath upload() => AppRoutePath._('/upload', null, null);
  static AppRoutePath offers() => AppRoutePath._('/offers', null, null);
  static AppRoutePath notifications() =>
      AppRoutePath._('/notifications', null, null);
  static AppRoutePath profile() => AppRoutePath._('/profile', null, null);

  // Detail routes
  static AppRoutePath videoDetail(String videoId) =>
      AppRoutePath._('/video-detail', videoId, null);
  static AppRoutePath offerDetail(String offerId) =>
      AppRoutePath._('/offer-detail', offerId, null);
  static AppRoutePath offerForm(String videoId) =>
      AppRoutePath._('/offer-form', videoId, null);
  static AppRoutePath uploadForm() =>
      AppRoutePath._('/upload-form', null, null);
  static AppRoutePath messages(String offerId) =>
      AppRoutePath._('/messages', offerId, null);
  static AppRoutePath settings() => AppRoutePath._('/settings', null, null);
  static AppRoutePath editProfile() =>
      AppRoutePath._('/edit-profile', null, null);

  // Route type checks
  bool get isSplashPage => location == '/';
  bool get isOnboardingPage => location == '/onboarding';
  bool get isAuthPage => location == '/auth';
  bool get isRoleSelectionPage => location == '/role-selection';
  bool get isDiscoverPage => location == '/discover';
  bool get isUploadPage => location == '/upload';
  bool get isOffersPage => location == '/offers';
  bool get isNotificationsPage => location == '/notifications';
  bool get isProfilePage => location == '/profile';
  bool get isVideoDetailPage => location == '/video-detail';
  bool get isOfferDetailPage => location == '/offer-detail';
  bool get isOfferFormPage => location == '/offer-form';
  bool get isUploadFormPage => location == '/upload-form';
  bool get isMessagesPage => location == '/messages';
  bool get isSettingsPage => location == '/settings';
  bool get isEditProfilePage => location == '/edit-profile';

  // Main tab index
  int get mainTabIndex {
    switch (location) {
      case '/discover':
        return 0;
      case '/upload':
        return 1;
      case '/offers':
        return 2;
      case '/notifications':
        return 3;
      case '/profile':
        return 4;
      default:
        return 0;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is AppRoutePath &&
        other.location == location &&
        other.id == id;
  }

  @override
  int get hashCode => location.hashCode ^ (id?.hashCode ?? 0);

  @override
  String toString() => 'AppRoutePath($location${id != null ? '/$id' : ''})';
}