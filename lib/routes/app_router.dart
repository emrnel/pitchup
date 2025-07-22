// lib/routes/app_router.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/app_state_provider.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/auth/auth_screen.dart';
import '../presentation/screens/auth/role_selection_screen.dart';
import '../presentation/screens/main/main_screen.dart';
import '../presentation/screens/main/discover/video_detail_screen.dart';
import '../presentation/screens/main/offers/offer_detail_screen.dart';
import '../presentation/screens/main/offers/offer_form_screen.dart';
import '../presentation/screens/main/upload/upload_form_screen.dart';
import '../presentation/screens/messages/messages_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/main/profile/edit_profile_screen.dart';
import 'route_paths.dart';

class AppRouteInformationParser extends RouteInformationParser<AppRoutePath> {
  @override
  Future<AppRoutePath> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final uri = Uri.parse(routeInformation.location ?? '/');

    // Handle different routes
    switch (uri.path) {
      case '/':
        return AppRoutePath.splash();
      case '/onboarding':
        return AppRoutePath.onboarding();
      case '/auth':
        return AppRoutePath.auth();
      case '/role-selection':
        return AppRoutePath.roleSelection();
      case '/discover':
        return AppRoutePath.discover();
      case '/upload':
        return AppRoutePath.upload();
      case '/offers':
        return AppRoutePath.offers();
      case '/notifications':
        return AppRoutePath.notifications();
      case '/profile':
        return AppRoutePath.profile();
      case '/settings':
        return AppRoutePath.settings();
      case '/edit-profile':
        return AppRoutePath.editProfile();
      case '/upload-form':
        return AppRoutePath.uploadForm();
      default:
        // Handle parameterized routes
        if (uri.pathSegments.length == 2) {
          final segment = uri.pathSegments[0];
          final id = uri.pathSegments[1];

          switch (segment) {
            case 'video-detail':
              return AppRoutePath.videoDetail(id);
            case 'offer-detail':
              return AppRoutePath.offerDetail(id);
            case 'offer-form':
              return AppRoutePath.offerForm(id);
            case 'messages':
              return AppRoutePath.messages(id);
          }
        }

        // Default to discover
        return AppRoutePath.discover();
    }
  }

  @override
  RouteInformation restoreRouteInformation(AppRoutePath path) {
    String location = path.location;
    if (path.id != null) {
      location += '/${path.id}';
    }
    return RouteInformation(location: location);
  }
}

class AppRouterDelegate extends RouterDelegate<AppRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoutePath> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Current route state
  AppRoutePath _currentPath = AppRoutePath.splash();

  // Modal stack for overlay screens
  final List<AppRoutePath> _modalStack = [];

  AppRouterDelegate();

  @override
  AppRoutePath get currentConfiguration => _currentPath;

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, AppStateProvider>(
      builder: (context, auth, appState, child) {
        return Navigator(
          key: navigatorKey,
          pages: _buildPages(context, auth, appState),
          onPopPage: _onPopPage,
        );
      },
    );
  }

  List<Page> _buildPages(
    BuildContext context,
    AuthProvider auth,
    AppStateProvider appState,
  ) {
    final pages = <Page>[];

    // Always start with splash if not initialized
    if (!appState.isInitialized || !auth.isInitialized) {
      pages.add(MaterialPage(
        key: const ValueKey('SplashPage'),
        child: SplashScreen(),
      ));
      return pages;
    }

    // Onboarding flow
    if (!appState.hasCompletedOnboarding) {
      pages.add(MaterialPage(
        key: const ValueKey('OnboardingPage'),
        child: OnboardingScreen(),
      ));
      return pages;
    }

    // Auth flow
    if (!auth.isLoggedIn) {
      pages.add(MaterialPage(
        key: const ValueKey('AuthPage'),
        child: AuthScreen(),
      ));
      return pages;
    }

    // Role selection
    if (auth.currentUser?.role == null) {
      pages.add(MaterialPage(
        key: const ValueKey('RoleSelectionPage'),
        child: RoleSelectionScreen(),
      ));
      return pages;
    }

    // Main app - always add the main screen
    pages.add(MaterialPage(
      key: const ValueKey('MainPage'),
      child: MainScreen(),
    ));

    // Add modal pages on top
    for (final modalPath in _modalStack) {
      pages.add(_buildModalPage(modalPath));
    }

    return pages;
  }

  Page _buildModalPage(AppRoutePath path) {
    if (path.isVideoDetailPage && path.id != null) {
      return MaterialPage(
        key: ValueKey('VideoDetailPage-${path.id}'),
        child: VideoDetailScreen(videoId: path.id!),
        fullscreenDialog: true,
      );
    }

    if (path.isOfferDetailPage && path.id != null) {
      return MaterialPage(
        key: ValueKey('OfferDetailPage-${path.id}'),
        child: OfferDetailScreen(offerId: path.id!),
      );
    }

    if (path.isOfferFormPage && path.id != null) {
      return MaterialPage(
        key: ValueKey('OfferFormPage-${path.id}'),
        child: OfferFormScreen(videoId: path.id!),
        fullscreenDialog: true,
      );
    }

    if (path.isUploadFormPage) {
      return MaterialPage(
        key: const ValueKey('UploadFormPage'),
        child: UploadFormScreen(),
        fullscreenDialog: true,
      );
    }

    if (path.isMessagesPage && path.id != null) {
      return MaterialPage(
        key: ValueKey('MessagesPage-${path.id}'),
        child: MessagesScreen(offerId: path.id!),
      );
    }

    if (path.isSettingsPage) {
      return MaterialPage(
        key: const ValueKey('SettingsPage'),
        child: SettingsScreen(),
      );
    }

    if (path.isEditProfilePage) {
      return MaterialPage(
        key: const ValueKey('EditProfilePage'),
        child: EditProfileScreen(),
        fullscreenDialog: true,
      );
    }

    // Fallback
    return MaterialPage(
      key: const ValueKey('FallbackPage'),
      child: Container(),
    );
  }

  bool _onPopPage(Route route, dynamic result) {
    if (!route.didPop(result)) {
      return false;
    }

    // Pop from modal stack if available
    if (_modalStack.isNotEmpty) {
      _modalStack.removeLast();
      notifyListeners();
      return true;
    }

    return false;
  }

  @override
  Future<void> setNewRoutePath(AppRoutePath path) async {
    // Handle main routes (replace current path)
    if (_isMainRoute(path)) {
      _currentPath = path;
      _modalStack.clear();
    } else {
      // Handle modal routes (add to stack)
      if (_modalStack.isEmpty || _modalStack.last != path) {
        _modalStack.add(path);
      }
    }

    notifyListeners();
  }

  bool _isMainRoute(AppRoutePath path) {
    return path.isSplashPage ||
        path.isOnboardingPage ||
        path.isAuthPage ||
        path.isRoleSelectionPage ||
        path.isDiscoverPage ||
        path.isUploadPage ||
        path.isOffersPage ||
        path.isNotificationsPage ||
        path.isProfilePage;
  }

  // Public navigation methods
  void navigateToDiscover() {
    setNewRoutePath(AppRoutePath.discover());
  }

  void navigateToUpload() {
    setNewRoutePath(AppRoutePath.upload());
  }

  void navigateToOffers() {
    setNewRoutePath(AppRoutePath.offers());
  }

  void navigateToNotifications() {
    setNewRoutePath(AppRoutePath.notifications());
  }

  void navigateToProfile() {
    setNewRoutePath(AppRoutePath.profile());
  }

  void navigateToVideoDetail(String videoId) {
    setNewRoutePath(AppRoutePath.videoDetail(videoId));
  }

  void navigateToOfferDetail(String offerId) {
    setNewRoutePath(AppRoutePath.offerDetail(offerId));
  }

  void navigateToOfferForm(String videoId) {
    setNewRoutePath(AppRoutePath.offerForm(videoId));
  }

  void navigateToUploadForm() {
    setNewRoutePath(AppRoutePath.uploadForm());
  }

  void navigateToMessages(String offerId) {
    setNewRoutePath(AppRoutePath.messages(offerId));
  }

  void navigateToSettings() {
    setNewRoutePath(AppRoutePath.settings());
  }

  void navigateToEditProfile() {
    setNewRoutePath(AppRoutePath.editProfile());
  }

  void pop() {
    if (_modalStack.isNotEmpty) {
      _modalStack.removeLast();
      notifyListeners();
    }
  }

  void popUntilMain() {
    _modalStack.clear();
    notifyListeners();
  }

  // Deep link handling
  void handleDeepLink(String link) {
    final uri = Uri.parse(link);

    // Parse the deep link and navigate accordingly
    switch (uri.path) {
      case '/video':
        final videoId = uri.queryParameters['id'];
        if (videoId != null) {
          navigateToVideoDetail(videoId);
        }
        break;
      case '/offer':
        final offerId = uri.queryParameters['id'];
        if (offerId != null) {
          navigateToOfferDetail(offerId);
        }
        break;
      case '/profile':
        navigateToProfile();
        break;
      default:
        navigateToDiscover();
    }
  }

  @override
  void dispose() {
    _modalStack.clear();
    super.dispose();
  }
}

// Navigation helper service
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  static NavigationService get instance => _instance;

  AppRouterDelegate? _router;

  void initialize(AppRouterDelegate router) {
    _router = router;
  }

  void navigateToDiscover() => _router?.navigateToDiscover();
  void navigateToUpload() => _router?.navigateToUpload();
  void navigateToOffers() => _router?.navigateToOffers();
  void navigateToNotifications() => _router?.navigateToNotifications();
  void navigateToProfile() => _router?.navigateToProfile();
  void navigateToVideoDetail(String videoId) =>
      _router?.navigateToVideoDetail(videoId);
  void navigateToOfferDetail(String offerId) =>
      _router?.navigateToOfferDetail(offerId);
  void navigateToOfferForm(String videoId) =>
      _router?.navigateToOfferForm(videoId);
  void navigateToUploadForm() => _router?.navigateToUploadForm();
  void navigateToMessages(String offerId) =>
      _router?.navigateToMessages(offerId);
  void navigateToSettings() => _router?.navigateToSettings();
  void navigateToEditProfile() => _router?.navigateToEditProfile();
  void pop() => _router?.pop();
  void popUntilMain() => _router?.popUntilMain();
  void handleDeepLink(String link) => _router?.handleDeepLink(link);
}