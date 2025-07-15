import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app.dart';
import 'config/firebase_options.dart';
import 'core/managers/cache_manager.dart';
import 'core/managers/connection_manager.dart';
import 'core/managers/analytics_manager.dart';
import 'data/services/notification_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/video_feed_provider.dart';
import 'presentation/providers/offer_provider.dart';
import 'presentation/providers/profile_provider.dart';
import 'presentation/providers/app_state_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await _initializeServices();
  _configureApp();

  // Create ConnectionManager instance
  final connectionManager = ConnectionManager();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
            value: connectionManager), // Use .value for existing instance
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VideoFeedProvider()),
        ChangeNotifierProvider(create: (_) => OfferProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ],
      child: PitchUpApp(),
    ),
  );
}

Future<void> _initializeServices() async {
  ImageCacheManager.configureCacheSettings();
  await NotificationService.instance.initialize();
  await AnalyticsManager.instance.initialize();

  // Initialize connection manager
  final connectionManager = ConnectionManager();
  connectionManager.initialize();
}

void _configureApp() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}
