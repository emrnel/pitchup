// lib/presentation/screens/main/upload/upload_screen.dart
import 'package:flutter/material.dart';
import 'package:pitchup_app/presentation/screens/main/upload/upload_form_screen.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/managers/permission_manager.dart';
import '../../../../core/utils/extensions.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/primary_button.dart';
import '../../../widgets/common/secondary_button.dart';
import 'package:image_picker/image_picker.dart';

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final user = authProvider.currentUser;

            if (user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Header
                  Text(
                    'Pitch Videonu Yükle',
                    style: AppTypography.h2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Projenizi 60 saniyede anlatın',
                    style: AppTypography.bodyMediumText.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Upload options
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Camera option
                        _buildUploadOption(
                          icon: Icons.videocam_outlined,
                          title: 'Kamera ile Kaydet',
                          description: 'Doğrudan kamera ile video çekin',
                          onTap: () => _handleCameraRecord(),
                        ),
                        const SizedBox(height: 24),

                        // Gallery option
                        _buildUploadOption(
                          icon: Icons.video_library_outlined,
                          title: 'Galeriden Seç',
                          description: 'Var olan videoyu galeriden seçin',
                          onTap: () => _handleGalleryPick(),
                        ),

                        const SizedBox(height: 48),

                        // Requirements
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.infoColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMedium),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppColors.infoColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Video Gereksinimleri',
                                    style:
                                        AppTypography.bodyMediumText.copyWith(
                                      fontWeight: AppTypography.fontMedium,
                                      color: AppColors.infoColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildRequirement('• Maksimum 60 saniye'),
                              _buildRequirement('• Maksimum 100MB boyut'),
                              _buildRequirement(
                                  '• Dikey video önerilir (9:16)'),
                              _buildRequirement(
                                  '• MP4, MOV formatları desteklenir'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          border: Border.all(color: AppColors.dividerColor),
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
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.h4,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTypography.bodyMediumText.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: AppTypography.bodySmallText.copyWith(
            color: AppColors.infoColor,
          ),
        ),
      ),
    );
  }

  Future<void> _handleCameraRecord() async {
    // Check permissions
    final hasPermissions = await PermissionManager.requestVideoPermissions();
    if (!hasPermissions) {
      context.showSnackBar(
        'Video çekmek için kamera ve mikrofon izni gerekiyor',
        isError: true,
      );
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 60),
      );

      if (video != null) {
        // Navigate to upload form with video
        _navigateToUploadForm(video);
      }
    } catch (e) {
      context.showSnackBar(
        'Video kaydedilirken bir hata oluştu',
        isError: true,
      );
    }
  }

  Future<void> _handleGalleryPick() async {
    // Check permissions
    final hasPermissions = await PermissionManager.requestStoragePermission();
    if (!hasPermissions) {
      context.showSnackBar(
        'Galeriye erişim için izin gerekiyor',
        isError: true,
      );
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );

      if (video != null) {
        // Navigate to upload form with video
        _navigateToUploadForm(video);
      }
    } catch (e) {
      context.showSnackBar(
        'Video seçilirken bir hata oluştu',
        isError: true,
      );
    }
  }

  void _navigateToUploadForm(XFile video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadFormScreen(videoFile: video),
      ),
    );
  }
}