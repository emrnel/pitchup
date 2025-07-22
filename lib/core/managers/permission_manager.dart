// lib/core/managers/permission_manager.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    } else if (status.isPermanentlyDenied) {
      await _showPermissionDialog(
        'Kamera İzni',
        'Video çekmek için kamera izni gerekiyor. Lütfen ayarlardan izin verin.',
      );
      return false;
    }

    return status.isGranted;
  }

  // Storage/Photos permission
  static Future<bool> requestStoragePermission() async {
    if (Platform.isIOS) {
      return await requestPhotosPermission();
    }

    final status = await Permission.storage.status;

    if (status.isDenied) {
      final result = await Permission.storage.request();
      return result.isGranted;
    } else if (status.isPermanentlyDenied) {
      await _showPermissionDialog(
        'Depolama İzni',
        'Video yüklemek için depolama izni gerekiyor. Lütfen ayarlardan izin verin.',
      );
      return false;
    }

    return status.isGranted;
  }

  // Photos permission (iOS)
  static Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.status;

    if (status.isDenied) {
      final result = await Permission.photos.request();
      return result.isGranted;
    } else if (status.isPermanentlyDenied) {
      await _showPermissionDialog(
        'Fotoğraf İzni',
        'Galeriden video seçmek için fotoğraf erişim izni gerekiyor.',
      );
      return false;
    }

    return status.isGranted;
  }

  // Microphone permission
  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.status;

    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    } else if (status.isPermanentlyDenied) {
      await _showPermissionDialog(
        'Mikrofon İzni',
        'Video kaydı için mikrofon izni gerekiyor.',
      );
      return false;
    }

    return status.isGranted;
  }

  // Notification permission
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.status;

    if (status.isDenied) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }

    return status.isGranted;
  }

  // Request multiple permissions
  static Future<bool> requestVideoPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
      Platform.isIOS ? Permission.photos : Permission.storage,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  // Check permission status
  static Future<bool> hasPermission(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  // Show permission dialog
  static Future<void> _showPermissionDialog(
    String title,
    String message,
  ) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Ayarlara Git'),
          ),
        ],
      ),
    );
  }
}