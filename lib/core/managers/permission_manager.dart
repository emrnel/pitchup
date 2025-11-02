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

    // Android 13+ (API 33+) uses granular media permissions
    if (Platform.isAndroid) {
      // Request both video and images permissions for Android 13+
      final videoStatus = await Permission.videos.status;
      final imagesStatus = await Permission.photos.status;

      if (videoStatus.isDenied || imagesStatus.isDenied) {
        final results = await [
          Permission.videos,
          Permission.photos,
        ].request();

        return results[Permission.videos]?.isGranted ?? false;
      } else if (videoStatus.isPermanentlyDenied || imagesStatus.isPermanentlyDenied) {
        await _showPermissionDialog(
          'Medya İzni',
          'Galeriden video seçmek için medya erişim izni gerekiyor. Lütfen ayarlardan izin verin.',
        );
        return false;
      }

      return videoStatus.isGranted;
    }

    // Fallback for older Android versions
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
    List<Permission> permissions = [
      Permission.camera,
      Permission.microphone,
    ];

    // Add platform-specific media permissions
    if (Platform.isIOS) {
      permissions.add(Permission.photos);
    } else if (Platform.isAndroid) {
      // For Android 13+, use granular media permissions
      permissions.add(Permission.videos);
      permissions.add(Permission.photos);
    }

    final statuses = await permissions.request();

    // Check if all required permissions are granted
    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      // Show dialog if any permission is permanently denied
      bool anyPermanentlyDenied = statuses.values.any((status) => status.isPermanentlyDenied);
      if (anyPermanentlyDenied) {
        await _showPermissionDialog(
          'İzinler Gerekli',
          'Video çekmek için gerekli izinler verilmedi. Lütfen ayarlardan izinleri aktif edin.',
        );
      }
    }

    return allGranted;
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