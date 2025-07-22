// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'presentation/providers/app_state_provider.dart';
import 'presentation/widgets/common/connection_aware_widget.dart';

class PitchUpApp extends StatefulWidget {
  @override
  _PitchUpAppState createState() => _PitchUpAppState();
}

class _PitchUpAppState extends State<PitchUpApp> {
  final AppRouterDelegate _routerDelegate = AppRouterDelegate();
  final AppRouteInformationParser _routeInformationParser =
      AppRouteInformationParser();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PitchUp',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: context.watch<AppStateProvider>().themeMode,
      routerDelegate: _routerDelegate,
      routeInformationParser: _routeInformationParser,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      builder: (context, child) {
        return ConnectionAwareWidget(
          child: child!,
          onConnectionLost: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('İnternet bağlantısı kesildi'),
                backgroundColor: Colors.red,
              ),
            );
          },
          onConnectionRestored: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('İnternet bağlantısı yeniden kuruldu'),
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _routerDelegate.dispose();
    super.dispose();
  }
}