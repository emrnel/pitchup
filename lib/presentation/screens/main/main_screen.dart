// lib/presentation/screens/main/main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/video_feed_provider.dart';
import '../../providers/offer_provider.dart';
import '../../providers/profile_provider.dart';
import '../../../routes/route_paths.dart';
import 'discover/discover_screen.dart';
import 'upload/upload_screen.dart';
import 'offers/offers_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeProviders();
  }

  void _initializeProviders() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user != null) {
        // Initialize video feed
        Provider.of<VideoFeedProvider>(context, listen: false).loadVideos();

        // Load user-specific data
        Provider.of<OfferProvider>(context, listen: false).refreshOffers(
          user.id,
          user.role,
        );

        Provider.of<ProfileProvider>(context, listen: false)
          ..loadUserProfile(user.id)
          ..loadUserVideos(user.id);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: [
              DiscoverScreen(),
              UploadScreen(),
              OffersScreen(),
              NotificationsScreen(),
              ProfileScreen(),
            ],
          ),
          bottomNavigationBar: _buildBottomNavigationBar(user),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(UserModel user) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 56,
          child: Row(
            children: [
              _buildTabItem(
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Keşfet',
              ),
              _buildTabItem(
                index: 1,
                icon: Icons.add_circle_outline,
                activeIcon: Icons.add_circle,
                label: 'Yükle',
              ),
              _buildTabItem(
                index: 2,
                icon: Icons.business_center_outlined,
                activeIcon: Icons.business_center,
                label: 'Teklifler',
                showBadge: _getOffersBadgeCount(user),
              ),
              _buildTabItem(
                index: 3,
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications,
                label: 'Bildirimler',
                showBadge: _getNotificationsBadgeCount(),
              ),
              _buildTabItem(
                index: 4,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int? showBadge,
  }) {
    final isActive = _currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTabTapped(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Icon(
                      isActive ? activeIcon : icon,
                      size: 24,
                      color: isActive
                          ? AppColors.primaryColor
                          : AppColors.textTertiary,
                    ),
                    if (showBadge != null && showBadge > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.errorColor,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            showBadge > 99 ? '99+' : showBadge.toString(),
                            style: AppTypography.captionText.copyWith(
                              color: Colors.white,
                              fontWeight: AppTypography.fontMedium,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTypography.captionText.copyWith(
                    color: isActive
                        ? AppColors.primaryColor
                        : AppColors.textTertiary,
                    fontWeight: isActive
                        ? AppTypography.fontMedium
                        : AppTypography.fontRegular,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  int? _getOffersBadgeCount(UserModel user) {
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);

    if (user.role == UserRole.entrepreneur) {
      final count = offerProvider.pendingReceivedOffers;
      return count > 0 ? count : null;
    } else {
      final count = offerProvider.pendingSentOffers;
      return count > 0 ? count : null;
    }
  }

  int? _getNotificationsBadgeCount() {
    return null; // Will implement when NotificationProvider is ready
    //TODO: Implement notification badge count when NotificationProvider is ready
  }
}