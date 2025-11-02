// lib/presentation/screens/main/upload/upload_form_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/managers/video_upload_manager.dart';
import '../../../../data/models/video_model.dart';
import '../../../../data/repositories/video_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../widgets/common/primary_button.dart';
import '../../../widgets/common/input_field.dart';
import '../../../widgets/common/loading_indicator.dart';

class UploadFormScreen extends StatefulWidget {
  final XFile? videoFile;

  const UploadFormScreen({
    Key? key,
    this.videoFile,
  }) : super(key: key);

  @override
  _UploadFormScreenState createState() => _UploadFormScreenState();
}

class _UploadFormScreenState extends State<UploadFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requestedAmountController = TextEditingController();
  final _equityOfferedController = TextEditingController();

  VideoPlayerController? _videoController;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _selectedSector = 'Teknoloji';
  String? _error;

  final List<String> _sectors = [
    'Teknoloji',
    'Sağlık',
    'Eğitim',
    'Finans',
    'E-ticaret',
    'Oyun',
    'Gıda',
    'Turizm',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.videoFile != null) {
      _initializeVideoPlayer();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _requestedAmountController.dispose();
    _equityOfferedController.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPlayer() async {
    if (widget.videoFile != null) {
      _videoController =
          VideoPlayerController.file(File(widget.videoFile!.path));
      await _videoController!.initialize();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Video Yükle',
          style: AppTypography.h3,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isUploading)
            TextButton(
              onPressed: _handleUpload,
              child: Text(
                'Yayımla',
                style: AppTypography.bodyMediumText.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: AppTypography.fontMedium,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video preview
                  if (_videoController?.value.isInitialized == true) ...[
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMedium),
                          color: Colors.black,
                        ),
                        child: AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_videoController!.value.isPlaying) {
                              _videoController!.pause();
                            } else {
                              _videoController!.play();
                            }
                            setState(() {});
                          },
                          icon: Icon(
                            _videoController!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                        ),
                        Text(
                          '${_formatDuration(_videoController!.value.position)} / ${_formatDuration(_videoController!.value.duration)}',
                          style: AppTypography.bodySmallText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Upload progress
                  if (_isUploading) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.infoColor.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.cloud_upload,
                                color: AppColors.infoColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Video yükleniyor...',
                                style: AppTypography.bodyMediumText.copyWith(
                                  color: AppColors.infoColor,
                                  fontWeight: AppTypography.fontMedium,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${(_uploadProgress * 100).toInt()}%',
                                style: AppTypography.bodySmallText.copyWith(
                                  color: AppColors.infoColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _uploadProgress,
                            backgroundColor: AppColors.dividerColor,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.infoColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Title
                  InputField(
                    controller: _titleController,
                    label: 'Proje Başlığı',
                    hint: 'Projenizin çekici bir başlığını yazın',
                    validator: (value) => Validators.required(value, 'Başlık'),
                    enabled: !_isUploading,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  InputField(
                    controller: _descriptionController,
                    label: 'Açıklama',
                    hint: 'Projenizi detaylı bir şekilde açıklayın',
                    maxLines: 4,
                    validator: (value) =>
                        Validators.required(value, 'Açıklama'),
                    enabled: !_isUploading,
                  ),
                  const SizedBox(height: 16),

                  // Sector
                  Text(
                    'Sektör',
                    style: AppTypography.bodyMediumText.copyWith(
                      fontWeight: AppTypography.fontMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                      border: Border.all(color: AppColors.dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSector,
                        isExpanded: true,
                        onChanged: _isUploading
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedSector = value!;
                                });
                              },
                        items: _sectors.map((sector) {
                          return DropdownMenuItem(
                            value: sector,
                            child: Text(
                              sector,
                              style: AppTypography.bodyLargeText,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Financial details
                  Text(
                    'Finansal Bilgiler',
                    style: AppTypography.h4,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: InputField(
                          controller: _requestedAmountController,
                          label: 'Talep Edilen Tutar (₺)',
                          hint: '1000000',
                          keyboardType: TextInputType.number,
                          validator: Validators.amount,
                          enabled: !_isUploading,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InputField(
                          controller: _equityOfferedController,
                          label: 'Sunulan Hisse (%)',
                          hint: '10',
                          keyboardType: TextInputType.number,
                          validator: Validators.percentage,
                          enabled: !_isUploading,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorColor.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.errorColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: AppTypography.bodyMediumText.copyWith(
                                color: AppColors.errorColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Upload button
                  PrimaryButton(
                    text: _isUploading ? 'Yükleniyor...' : 'Videoyu Yayımla',
                    onPressed: _isUploading ? null : _handleUpload,
                    isLoading: _isUploading,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          if (_isUploading) const LoadingIndicator(),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate() || widget.videoFile == null) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) {
      setState(() {
        _error = 'Kullanıcı bilgisi bulunamadı';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
      _uploadProgress = 0.0;
    });

    try {
      final videoFile = File(widget.videoFile!.path);

      // Upload video
      final uploadResult = await VideoUploadManager().uploadVideo(
        videoFile: videoFile,
        userId: user.id,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
        onComplete: () {
          // Upload completed
        },
        onError: (error) {
          setState(() {
            _error = error;
            _isUploading = false;
          });
        },
      );

      if (uploadResult.success && uploadResult.videoUrl != null) {
        // Create video record
        final videoRepository = VideoRepository();

        final metadata = VideoMetadata(
          requestedAmount: double.tryParse(
              _requestedAmountController.text.replaceAll(',', '')),
          equityOffered: double.tryParse(
              _equityOfferedController.text.replaceAll(',', '')),
        );

        final video = await videoRepository.createVideo(
          userId: user.id,
          videoUrl: uploadResult.videoUrl!,
          thumbnailUrl: uploadResult.thumbnailUrl ?? '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          sector: _selectedSector,
          duration: _videoController?.value.duration.inSeconds ?? 0,
          metadata: metadata,
        );

        // Add to profile provider
        if (mounted) {
          Provider.of<ProfileProvider>(context, listen: false).addVideo(video);

          context.showSnackBar('Video başarıyla yüklendi!');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Video yüklenirken bir hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
}