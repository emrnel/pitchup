// lib/core/services/navigation_service.dart
import 'package:flutter/material.dart';
import '../../presentation/screens/main/discover/video_detail_screen.dart';
import '../../presentation/screens/main/offers/offer_detail_screen.dart';
import '../../presentation/screens/main/offers/offer_form_screen.dart';
import '../../presentation/screens/messages/messages_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/main/profile/edit_profile_screen.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  static NavigationService get instance => _instance;

  static void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  static void toVideoDetail(BuildContext context, String videoId) {
    _navigateTo(context, VideoDetailScreen(videoId: videoId));
  }

  static void toOfferForm(BuildContext context, String videoId) {
    _navigateTo(context, OfferFormScreen(videoId: videoId));
  }

  static void toOfferDetail(BuildContext context, String offerId) {
    _navigateTo(context, OfferDetailScreen(offerId: offerId));
  }

  static void toMessages(BuildContext context, String offerId) {
    _navigateTo(context, MessagesScreen(offerId: offerId));
  }

  static void toSettings(BuildContext context) {
    _navigateTo(context, SettingsScreen());
  }

  static void toEditProfile(BuildContext context) {
    _navigateTo(context, EditProfileScreen());
  }

  static void pop(BuildContext context) {
    Navigator.pop(context);
  }

  static void popUntilMain(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}