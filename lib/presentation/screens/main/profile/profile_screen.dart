// lib/presentation/screens/main/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/managers/cache_manager.dart';
import '../../../../data/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../widgets/common/loading_indicator.dart';
import '../../../widgets/common/error_widget.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../../../widgets/cards/video_thumbnail_card.dart';
import '../../../../core/services/navigation_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Consumer2<ProfileProvider, AuthProvider>(
          builder: (context, profileProvider, authProvider, child) {
            final user = authProvider.currentUser;

            if (user == null) {
              return const Center(child: LoadingIndicator());
            }

            return CustomScrollView(
              slivers: [
                // App bar
                SliverAppBar(
                  backgroundColor: AppColors.backgroundColor,
                  elevation: 0,
                  floating: true,
                  title: Text(
                    'Profil',
                    style: AppTypography.h2,
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () => NavigationService.toSettings(context),
                    ),
                  ],
                ),

                // Profile header
                SliverToBoxAdapter(
                  child: _buildProfileHeader(profileProvider, user),
                ),

                // Stats (for entrepreneurs)
                if (user.role == UserRole.entrepreneur)
                  SliverToBoxAdapter(
                    child: _buildStats(profileProvider),
                  ),

                // Videos grid
                _buildVideosGrid(profileProvider, user),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          if (user?.role == UserRole.entrepreneur) {
            return FloatingActionButton(
              onPressed: () {
                // Navigate to upload
                DefaultTabController.of(context)?.animateTo(1);
              },
              backgroundColor: AppColors.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildProfileHeader(ProfileProvider profileProvider, UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar and edit button
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.dividerColor,
                ),
                child: ClipOval(
                  child: user.profilePicture != null
                      ? ImageCacheManager.buildCachedImage(
                          imageUrl: user.profilePicture!,
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.person,
                          size: 50,
                          color: AppColors.textTertiary,
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.backgroundColor,
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                    onPressed: () => NavigationService.toEditProfile(context),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Name and role
          Text(
            user.name,
            style: AppTypography.h3,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: user.role == UserRole.investor
                  ? AppColors.infoColor.withOpacity(0.1)
                  : AppColors.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Text(
              user.role == UserRole.investor ? 'Yatırımcı' : 'Girişimci',
              style: AppTypography.bodySmallText.copyWith(
                color: user.role == UserRole.investor
                    ? AppColors.infoColor
                    : AppColors.successColor,
                fontWeight: AppTypography.fontMedium,
              ),
            ),
          ),

          // Bio
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              user.bio!,
              style: AppTypography.bodyMediumText.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          // Company info
          if (user.company != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(color: AppColors.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Şirket Bilgileri',
                    style: AppTypography.bodyMediumText.copyWith(
                      fontWeight: AppTypography.fontMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCompanyInfo('Şirket', user.company!.name),
                  _buildCompanyInfo('Sektör', user.company!.sector),
                  if (user.company!.website != null)
                    _buildCompanyInfo('Website', user.company!.website!),
                  if (user.company!.foundedYear != null)
                    _buildCompanyInfo(
                        'Kuruluş Yılı', user.company!.foundedYear.toString()),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompanyInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: AppTypography.bodySmallText.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmallText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(ProfileProvider profileProvider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Videolar',
              profileProvider.userVideos.length.toString(),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.dividerColor,
          ),
          Expanded(
            child: _buildStatItem(
              'Toplam Görüntülenme',
              Formatters.viewCount(profileProvider.totalViews),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.dividerColor,
          ),
          Expanded(
            child: _buildStatItem(
              'Toplam Teklif',
              profileProvider.totalOffers.toString(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.h4.copyWith(
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.bodySmallText.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVideosGrid(ProfileProvider profileProvider, UserModel user) {
    if (profileProvider.isLoading && profileProvider.userVideos.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: LoadingIndicator()),
      );
    }

    if (profileProvider.error != null && profileProvider.userVideos.isEmpty) {
      return SliverToBoxAdapter(
        child: AppErrorWidget(
          title: 'Videolar Yüklenemedi',
          message: profileProvider.error!,
          buttonText: 'Tekrar Dene',
          onRetry: () => profileProvider.loadUserVideos(user.id),
        ),
      );
    }

    if (profileProvider.userVideos.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyStateWidget(
          icon: Icons.video_library_outlined,
          title: 'Henüz Video Yok',
          message: user.role == UserRole.entrepreneur
              ? 'İlk videonuzu yükleyin'
              : 'Bu kullanıcının henüz videosu yok',
          buttonText: user.role == UserRole.entrepreneur ? 'Video Yükle' : null,
          onButtonPressed: user.role == UserRole.entrepreneur
              ? () => DefaultTabController.of(context)?.animateTo(1)
              : null,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 9 / 16,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final video = profileProvider.userVideos[index];
            return VideoThumbnailCard(
              video: video,
              onTap: () => _playVideo(video.id),
              onDelete: user.role == UserRole.entrepreneur
                  ? () => _deleteVideo(profileProvider, video.id)
                  : null,
            );
          },
          childCount: profileProvider.userVideos.length,
        ),
      ),
    );
  }

  void _playVideo(String videoId) {
    NavigationService.toVideoDetail(context, videoId);
  }

  Future<void> _deleteVideo(
      ProfileProvider profileProvider, String videoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Videoyu Sil', style: AppTypography.h3),
        content: Text(
          'Bu videoyu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
          style: AppTypography.bodyMediumText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await profileProvider.deleteVideo(videoId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video silindi'),
              backgroundColor: AppColors.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video silinirken hata oluştu'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      }
    }
  }
}