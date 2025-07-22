// lib/presentation/widgets/cards/video_thumbnail_card.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/managers/cache_manager.dart';
import '../../../data/models/video_model.dart';

class VideoThumbnailCard extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const VideoThumbnailCard({
    Key? key,
    required this.video,
    required this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          child: Stack(
            children: [
              // Thumbnail
              AspectRatio(
                aspectRatio: 9 / 16,
                child: video.thumbnailUrl != null
                    ? ImageCacheManager.buildCachedImage(
                        imageUrl: video.thumbnailUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AppColors.dividerColor,
                        child: const Icon(
                          Icons.video_library,
                          color: AppColors.textTertiary,
                          size: 32,
                        ),
                      ),
              ),

              // Play overlay
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),

              // Bottom info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: AppTypography.bodySmallText.copyWith(
                          color: Colors.white,
                          fontWeight: AppTypography.fontMedium,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Formatters.viewCount(video.viewCount),
                            style: AppTypography.captionText.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.business_center,
                            size: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            video.offerCount.toString(),
                            style: AppTypography.captionText.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Status indicator
              if (video.status != VideoStatus.approved)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSmall),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: AppTypography.captionText.copyWith(
                        color: Colors.white,
                        fontWeight: AppTypography.fontMedium,
                      ),
                    ),
                  ),
                ),

              // Delete button
              if (onDelete != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 16,
                      ),
                      onPressed: onDelete,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (video.status) {
      case VideoStatus.pending:
        return AppColors.pendingColor;
      case VideoStatus.rejected:
        return AppColors.errorColor;
      case VideoStatus.approved:
        return AppColors.successColor;
    }
  }

  String _getStatusText() {
    switch (video.status) {
      case VideoStatus.pending:
        return 'Beklemede';
      case VideoStatus.rejected:
        return 'Reddedildi';
      case VideoStatus.approved:
        return 'Onaylandı';
    }
  }
}