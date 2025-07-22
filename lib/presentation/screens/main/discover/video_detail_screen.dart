// lib/presentation/screens/main/discover/video_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/video_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/video_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/loading_indicator.dart';
import '../../../widgets/common/error_widget.dart';
import '../../../widgets/video/video_player_widget.dart';
import '../../../widgets/common/primary_button.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/services/share_service.dart';

class VideoDetailScreen extends StatefulWidget {
  final String videoId;

  const VideoDetailScreen({
    Key? key,
    required this.videoId,
  }) : super(key: key);

  @override
  _VideoDetailScreenState createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  final VideoRepository _videoRepository = VideoRepository();
  final UserRepository _userRepository = UserRepository();
  VideoModel? _video;
  UserModel? _entrepreneur;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVideoDetails();
  }

  Future<void> _loadVideoDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _video = await _videoRepository.getVideo(widget.videoId);
      if (_video != null) {
        _entrepreneur = await _userRepository.getUser(_video!.userId);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Video yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: LoadingIndicator(color: Colors.white))
          : _error != null
              ? AppErrorWidget(
                  message: _error!,
                  onRetry: _loadVideoDetails,
                )
              : _video == null
                  ? const AppErrorWidget(message: 'Video bulunamadı')
                  : Stack(
                      children: [
                        // Video Player
                        VideoPlayerWidget(
                          video: _video!,
                          isActive: true,
                          onLike: () => _handleLike(),
                          onInfo: () => _showVideoInfo(),
                          onOffer: _canMakeOffer()
                              ? () => _navigateToOfferForm()
                              : null,
                          onShare: () => _handleShare(),
                        ),

                        // Top bar
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            child: Container(
                              height: 56,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _video!.title,
                                      style: AppTypography.h4.copyWith(
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => _showMoreOptions(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Bottom sheet with details
                        DraggableScrollableSheet(
                          initialChildSize: 0.1,
                          minChildSize: 0.1,
                          maxChildSize: 0.8,
                          builder: (context, scrollController) {
                            return Container(
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceColor,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(
                                      AppDimensions.radiusLarge),
                                  topRight: Radius.circular(
                                      AppDimensions.radiusLarge),
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Drag handle
                                  Container(
                                    width: 32,
                                    height: 4,
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.dividerColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),

                                  // Content
                                  Expanded(
                                    child: ListView(
                                      controller: scrollController,
                                      padding: const EdgeInsets.all(16),
                                      children: [
                                        // Video title and stats
                                        Text(
                                          _video!.title,
                                          style: AppTypography.h3,
                                        ),
                                        const SizedBox(height: 8),

                                        Row(
                                          children: [
                                            _buildStatChip(
                                              Icons.visibility,
                                              Formatters.viewCount(
                                                  _video!.viewCount),
                                            ),
                                            const SizedBox(width: 8),
                                            _buildStatChip(
                                              Icons.favorite,
                                              _video!.likeCount.toString(),
                                            ),
                                            const SizedBox(width: 8),
                                            _buildStatChip(
                                              Icons.business_center,
                                              _video!.offerCount.toString(),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 16),

                                        // Sector
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryColor
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                                AppDimensions.radiusSmall),
                                          ),
                                          child: Text(
                                            _video!.sector,
                                            style: AppTypography.bodySmallText
                                                .copyWith(
                                              color: AppColors.primaryColor,
                                              fontWeight:
                                                  AppTypography.fontMedium,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 16),

                                        // Description
                                        Text(
                                          'Açıklama',
                                          style: AppTypography.h4,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _video!.description,
                                          style: AppTypography.bodyMediumText,
                                        ),

                                        const SizedBox(height: 16),

                                        // Financial details
                                        if (_video!.metadata.requestedAmount !=
                                                null ||
                                            _video!.metadata.equityOffered !=
                                                null) ...[
                                          Text(
                                            'Finansal Bilgiler',
                                            style: AppTypography.h4,
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: AppColors.backgroundColor,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppDimensions
                                                          .radiusMedium),
                                            ),
                                            child: Row(
                                              children: [
                                                if (_video!.metadata
                                                        .requestedAmount !=
                                                    null)
                                                  Expanded(
                                                    child: _buildFinancialItem(
                                                      'Talep Edilen',
                                                      Formatters.currency(_video!
                                                          .metadata
                                                          .requestedAmount!),
                                                    ),
                                                  ),
                                                if (_video!.metadata
                                                            .requestedAmount !=
                                                        null &&
                                                    _video!.metadata
                                                            .equityOffered !=
                                                        null)
                                                  Container(
                                                    width: 1,
                                                    height: 40,
                                                    color:
                                                        AppColors.dividerColor,
                                                  ),
                                                if (_video!.metadata
                                                        .equityOffered !=
                                                    null)
                                                  Expanded(
                                                    child: _buildFinancialItem(
                                                      'Sunulan Hisse',
                                                      '${_video!.metadata.equityOffered!}%',
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                        ],

                                        // Entrepreneur info
                                        if (_entrepreneur != null) ...[
                                          Text(
                                            'Girişimci',
                                            style: AppTypography.h4,
                                          ),
                                          const SizedBox(height: 8),
                                          ListTile(
                                            leading: CircleAvatar(
                                              backgroundImage: _entrepreneur!
                                                          .profilePicture !=
                                                      null
                                                  ? NetworkImage(_entrepreneur!
                                                      .profilePicture!)
                                                  : null,
                                              child: _entrepreneur!
                                                          .profilePicture ==
                                                      null
                                                  ? const Icon(Icons.person)
                                                  : null,
                                            ),
                                            title: Text(
                                              _entrepreneur!.name,
                                              style:
                                                  AppTypography.bodyLargeText,
                                            ),
                                            subtitle: _entrepreneur!.bio != null
                                                ? Text(
                                                    _entrepreneur!.bio!,
                                                    style: AppTypography
                                                        .bodySmallText,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(height: 16),
                                        ],

                                        // Action button
                                        if (_canMakeOffer())
                                          PrimaryButton(
                                            text: 'Teklif Gönder',
                                            onPressed: _navigateToOfferForm,
                                            icon: Icons.business_center,
                                          ),

                                        const SizedBox(height: 32),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
    );
  }

  Widget _buildStatChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.dividerColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTypography.captionText.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.captionText.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyLargeText.copyWith(
            fontWeight: AppTypography.fontMedium,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  bool _canMakeOffer() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;

    return user != null &&
        user.role == UserRole.investor &&
        user.isApproved &&
        user.id != _video?.userId;
  }

  void _handleLike() {
    // TODO: Implement like functionality
  }

  void _showVideoInfo() {
    // Already showing in the bottom sheet
  }

  void _navigateToOfferForm() {
    if (_video != null) {
      NavigationService.toOfferForm(context, _video!.id);
    }
  }

  void _handleShare() {
    if (_video != null) {
      ShareService.shareVideo(videoId: _video!.id, title: _video!.title);
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Şikayet Et'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement report functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Paylaş'),
              onTap: () {
                Navigator.pop(context);
                _handleShare();
              },
            ),
          ],
        ),
      ),
    );
  }
}