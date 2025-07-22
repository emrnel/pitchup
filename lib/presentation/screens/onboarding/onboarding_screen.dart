// lib/presentation/screens/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/constants/asset_paths.dart';
import '../../providers/app_state_provider.dart';

class OnboardingPage {
  final String image;
  final String title;
  final String description;

  const OnboardingPage({
    required this.image,
    required this.title,
    required this.description,
  });
}

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      image: AssetPaths.onboarding1,
      title: 'Hızlı ve Etkili Pitch',
      description: '60 saniyede fikrini anlat, yatırımcıların dikkatini çek',
    ),
    const OnboardingPage(
      image: AssetPaths.onboarding2,
      title: 'Kolay Keşif',
      description: 'Yatırımcılar için TikTok benzeri akıcı keşif deneyimi',
    ),
    const OnboardingPage(
      image: AssetPaths.onboarding3,
      title: 'Anında Teklif',
      description: 'Beğendiğin projeye hemen yatırım teklifi gönder',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  'Atla',
                  style: AppTypography.bodyMediumText.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            // Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image placeholder (since we don't have actual images)
                        Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(120),
                          ),
                          child: Icon(
                            _getIconForPage(index),
                            size: 120,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Title
                        Text(
                          _pages[index].title,
                          style: AppTypography.h2,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Description
                        Text(
                          _pages[index].description,
                          style: AppTypography.bodyLargeText.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Navigation
            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  AnimatedOpacity(
                    opacity: _currentPage > 0 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _currentPage > 0 ? _previousPage : null,
                    ),
                  ),
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primaryColor
                              : AppColors.dividerColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Next/Complete button
                  TextButton(
                    onPressed: _currentPage < _pages.length - 1
                        ? _nextPage
                        : _completeOnboarding,
                    child: Text(
                      _currentPage < _pages.length - 1 ? 'İleri' : 'Başla',
                      style: AppTypography.bodyLargeText.copyWith(
                        color: AppColors.primaryColor,
                        fontWeight: AppTypography.fontMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForPage(int index) {
    switch (index) {
      case 0:
        return Icons.video_camera_front;
      case 1:
        return Icons.explore;
      case 2:
        return Icons.handshake;
      default:
        return Icons.star;
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() {
    Provider.of<AppStateProvider>(context, listen: false).completeOnboarding();
  }
}