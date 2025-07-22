// lib/core/utils/helpers.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class Helpers {
  static Future<bool> launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
      return false;
    } catch (e) {
      debugPrint('Error launching URL: $e');
      return false;
    }
  }

  static Future<bool> launchEmail(String email,
      {String? subject, String? body}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        if (subject != null) 'subject': subject,
        if (body != null) 'body': body,
      },
    );
    return launchURL(uri.toString());
  }

  static Future<bool> launchPhone(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    return launchURL(uri.toString());
  }

  static bool get isIOS => Platform.isIOS;

  static bool get isAndroid => Platform.isAndroid;

  static String getVideoThumbnail(String videoUrl) {
    // This is a placeholder. In a real app, you would:
    // 1. Extract video ID from URL if it's YouTube/Vimeo
    // 2. Use Firebase Functions to generate thumbnails
    // 3. Return the thumbnail URL
    return videoUrl;
  }

  static String generateShareText({
    required String title,
    required String url,
  }) {
    return 'PitchUp\'ta "$title" videosunu keşfet!\n\n$url';
  }

  static Future<void> shareContent({
    required BuildContext context,
    required String text,
    String? subject,
  }) async {
    try {
      await Share.share(text, subject: subject);
    } catch (e) {
      print('Share error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paylaşım özelliği şu anda kullanılamıyor'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  static String? validateVideoFile(File file) {
    final sizeInBytes = file.lengthSync();
    final sizeInMB = sizeInBytes / (1024 * 1024);

    if (sizeInMB > 100) {
      return 'Video boyutu 100MB\'dan büyük olamaz';
    }

    final extension = file.path.split('.').last.toLowerCase();
    final allowedExtensions = ['mp4', 'mov', 'avi', 'mkv'];

    if (!allowedExtensions.contains(extension)) {
      return 'Desteklenmeyen video formatı';
    }

    return null;
  }

  static String generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  static IconData getSectorIcon(String sector) {
    switch (sector.toLowerCase()) {
      case 'teknoloji':
      case 'technology':
        return Icons.computer;
      case 'sağlık':
      case 'health':
        return Icons.local_hospital;
      case 'eğitim':
      case 'education':
        return Icons.school;
      case 'finans':
      case 'finance':
        return Icons.attach_money;
      case 'e-ticaret':
      case 'e-commerce':
        return Icons.shopping_cart;
      case 'oyun':
      case 'gaming':
        return Icons.sports_esports;
      case 'gıda':
      case 'food':
        return Icons.restaurant;
      default:
        return Icons.business;
    }
  }
}