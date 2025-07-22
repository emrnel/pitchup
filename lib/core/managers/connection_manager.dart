// lib/core/managers/connection_manager.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectionManager extends ChangeNotifier {
  static final ConnectionManager _instance = ConnectionManager._internal();
  factory ConnectionManager() => _instance;
  ConnectionManager._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  bool _isCheckingConnection = false;
  Timer? _connectionCheckTimer;

  ConnectivityResult get connectionStatus => _connectionStatus;
  bool get isConnected => _connectionStatus != ConnectivityResult.none;
  bool get isWifi => _connectionStatus == ConnectivityResult.wifi;
  bool get isMobile => _connectionStatus == ConnectivityResult.mobile;

  void initialize() {
    _checkConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );

    // Periodic connection check
    _connectionCheckTimer = Timer.periodic(
      Duration(seconds: 30),
      (_) => _checkConnectivity(),
    );
  }

  Future<void> _checkConnectivity() async {
    if (_isCheckingConnection) return;

    _isCheckingConnection = true;
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
    } finally {
      _isCheckingConnection = false;
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    if (_connectionStatus != result) {
      final wasConnected = isConnected;
      _connectionStatus = result;
      notifyListeners();

      // Notify connection state changes
      if (!wasConnected && isConnected) {
        _onConnectionRestored();
      } else if (wasConnected && !isConnected) {
        _onConnectionLost();
      }
    }
  }

  void _onConnectionLost() {
    debugPrint('Connection lost');
    // Additional logic when connection is lost
  }

  void _onConnectionRestored() {
    debugPrint('Connection restored');
    // Additional logic when connection is restored
    // e.g., sync pending data, refresh content
  }

  Future<bool> checkInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionCheckTimer?.cancel();
    super.dispose();
  }
}