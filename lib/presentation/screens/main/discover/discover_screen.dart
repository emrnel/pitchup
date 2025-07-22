// lib/presentation/screens/main/discover/discover_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../data/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/video_feed_provider.dart';
import '../../../widgets/common/loading_indicator.dart';
import '../../../widgets/common/error_widget.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../../../widgets/video/video_player_widget.dart';
import '../../../../routes/route_paths.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/services/share_service.dart';

class DiscoverScreen extends StatefulWidget {
  @override
  _DiscoverScreenState createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with AutomaticKeepAliveClientMixin {
  late PageController _pageController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer2<VideoFeedProvider, AuthProvider>(
        builder: (context, videoProvider, authProvider, child) {
          final user = authProvider.currentUser;

          if (user == null) {
            return const Center(child: LoadingIndicator());
          }

          if (videoProvider.isLoading && videoProvider.videos.isEmpty) {
            return const Center(child: LoadingIndicator());
          }

          if (videoProvider.error != null && videoProvider.videos.isEmpty) {
            return AppErrorWidget(
              title: 'Videolar Yüklenemedi',
              message: videoProvider.error!,
              buttonText: 'Tekrar Dene',
              onRetry: () => videoProvider.loadVideos(),
            );
          }

          if (videoProvider.videos.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.video_library_outlined,
              title: 'Henüz Video Yok',
              message: 'Henüz yüklenmiş video bulunmuyor',
              buttonText: 'Yenile',
              onButtonPressed: () => videoProvider.loadVideos(),
            );
          }

          return Stack(
            children: [
              // Video feed
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                onPageChanged: (index) {
                  videoProvider.goToVideo(index);

                  // Load more videos when near the end
                  if (index >= videoProvider.videos.length - 2) {
                    videoProvider.loadMoreVideos();
                  }
                },
                itemCount: videoProvider.videos.length,
                itemBuilder: (context, index) {
                  final video = videoProvider.videos[index];

                  return VideoPlayerWidget(
                    key: ValueKey(video.id),
                    video: video,
                    isActive: index == videoProvider.currentIndex,
                    onLike: () => _handleLike(videoProvider, video.id),
                    onInfo: () => _handleInfo(video.id),
                    onOffer: user.role == UserRole.investor && user.isApproved
                        ? () => _handleOffer(video.id, video.userId)
                        : null,
                    onShare: () => _handleShare(video.id),
                  );
                },
              ),

              // Top search bar (if needed)
              if (user.role == UserRole.investor) _buildTopBar(videoProvider),

              // Loading indicator for pagination
              if (videoProvider.isLoadingMore)
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const LoadingIndicator(
                        size: 24,
                        color: Colors.white,
                        overlay: false,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(VideoFeedProvider videoProvider) {
    return SafeArea(
      child: Container(
        height: 56,
        margin: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Search field
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        style: AppTypography.bodyMediumText.copyWith(
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Proje ara...',
                          hintStyle: AppTypography.bodyMediumText.copyWith(
                            color: Colors.white70,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (query) {
                          if (query.isNotEmpty) {
                            videoProvider.searchVideos(query);
                          } else {
                            videoProvider.refresh();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Filter button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.tune,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () => _showFilterDialog(videoProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLike(VideoFeedProvider videoProvider, String videoId) {
    videoProvider.toggleLike(videoId);
  }

  void _handleInfo(String videoId) {
    NavigationService.toVideoDetail(context, videoId);
  }

  void _handleOffer(String videoId, String entrepreneurId) {
    NavigationService.toOfferForm(context, videoId);
  }

  void _handleShare(String videoId) {
    final videoProvider =
        Provider.of<VideoFeedProvider>(context, listen: false);
    final video = videoProvider.currentVideo;

    if (video != null) {
      ShareService.shareVideo(videoId: videoId, title: video.title);
    }
  }

  void _showFilterDialog(VideoFeedProvider videoProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppDimensions.radiusLarge),
            topRight: Radius.circular(AppDimensions.radiusLarge),
          ),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filtrele',
                    style: AppTypography.h3,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Sector filters
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterOption('Tümü', () {
                    videoProvider.refresh();
                    Navigator.pop(context);
                  }),
                  _buildFilterOption('Teknoloji', () {
                    videoProvider.filterBySector('Teknoloji');
                    Navigator.pop(context);
                  }),
                  _buildFilterOption('Sağlık', () {
                    videoProvider.filterBySector('Sağlık');
                    Navigator.pop(context);
                  }),
                  _buildFilterOption('Eğitim', () {
                    videoProvider.filterBySector('Eğitim');
                    Navigator.pop(context);
                  }),
                  _buildFilterOption('Finans', () {
                    videoProvider.filterBySector('Finans');
                    Navigator.pop(context);
                  }),
                  _buildFilterOption('E-ticaret', () {
                    videoProvider.filterBySector('E-ticaret');
                    Navigator.pop(context);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(
        title,
        style: AppTypography.bodyLargeText,
      ),
      onTap: onTap,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}