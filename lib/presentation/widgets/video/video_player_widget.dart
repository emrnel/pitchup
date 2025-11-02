// lib/presentation/widgets/video/video_player_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/managers/video_preload_manager.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/video_model.dart';
import '../animations/like_animation.dart';

class VideoPlayerWidget extends StatefulWidget {
  final VideoModel video;
  final bool isActive;
  final VoidCallback onLike;
  final VoidCallback onInfo;
  final VoidCallback? onOffer;
  final VoidCallback onShare;

  const VideoPlayerWidget({
    Key? key,
    required this.video,
    required this.isActive,
    required this.onLike,
    required this.onInfo,
    this.onOffer,
    required this.onShare,
  }) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _showOverlay = true;
  bool _showDetails = false;
  bool _isLikeAnimating = false;
  Timer? _overlayTimer;
  Timer? _progressTimer;
  double _progress = 0.0;
  bool _isPreloadedController = false; // Track if controller is from preload manager

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _play();
        _startProgressTimer();
      } else {
        _pause();
        _stopProgressTimer();
      }
    }
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    _progressTimer?.cancel();

    // Only dispose controller if we created it ourselves (not from preload manager)
    // VideoPreloadManager manages its own controller lifecycle
    if (_controller != null && !_isPreloadedController) {
      _controller!.removeListener(_videoListener);
      _controller!.dispose();
    } else if (_controller != null) {
      // Just remove listener for preloaded controllers
      _controller!.removeListener(_videoListener);
    }

    super.dispose();
  }

  Future<void> _initializeController() async {
    try {
      // Try to get preloaded controller first
      _controller = VideoPreloadManager().getController(widget.video.id);

      if (_controller == null) {
        // Create new controller if not preloaded
        _controller =
            await VideoPreloadManager().getOrCreateController(widget.video);
      }

      // Mark as preloaded since it came from VideoPreloadManager
      // VideoPreloadManager will handle disposal
      _isPreloadedController = true;

      if (_controller != null && mounted) {
        _controller!.addListener(_videoListener);
        setState(() {});

        if (widget.isActive) {
          _play();
          _startProgressTimer();
        }
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;

    final value = _controller!.value;

    if (value.hasError) {
      print('Video error: ${value.errorDescription}');
      return;
    }

    if (value.isInitialized) {
      final position = value.position;
      final duration = value.duration;

      if (duration.inMilliseconds > 0) {
        setState(() {
          _progress = position.inMilliseconds / duration.inMilliseconds;
        });
      }

      // Auto-loop
      if (position >= duration && widget.isActive) {
        _controller!.seekTo(Duration.zero);
        _controller!.play();
      }
    }
  }

  void _startProgressTimer() {
    _stopProgressTimer();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _controller == null || !_controller!.value.isInitialized)
        return;

      final position = _controller!.value.position;
      final duration = _controller!.value.duration;

      if (duration.inMilliseconds > 0) {
        setState(() {
          _progress = position.inMilliseconds / duration.inMilliseconds;
        });
      }
    });
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  void _startOverlayTimer() {
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showOverlay = false;
        });
      }
    });
  }

  void _play() {
    if (_controller?.value.isInitialized == true) {
      _controller!.play();
      setState(() {
        _isPlaying = true;
      });
      _startOverlayTimer();
    }
  }

  void _pause() {
    if (_controller?.value.isInitialized == true) {
      _controller!.pause();
      setState(() {
        _isPlaying = false;
      });
      _overlayTimer?.cancel();
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }

    setState(() {
      _showOverlay = true;
    });

    if (_isPlaying) {
      _startOverlayTimer();
    }
  }

  void _toggleMute() {
    if (_controller?.value.isInitialized == true) {
      setState(() {
        _isMuted = !_isMuted;
        _controller!.setVolume(_isMuted ? 0 : 1);
      });
    }
  }

  void _toggleDetails() {
    setState(() {
      _showDetails = !_showDetails;
    });
  }

  void _handleLike() {
    setState(() {
      _isLikeAnimating = true;
    });

    widget.onLike();

    // Reset animation after delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLikeAnimating = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showOverlay = !_showOverlay;
        });
        if (_showOverlay && _isPlaying) {
          _startOverlayTimer();
        }
      },
      onDoubleTap: _handleLike,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),

          // Gradient overlays
          AnimatedOpacity(
            opacity: _showOverlay ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.2, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // Top info bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: _showOverlay ? 0 : -120,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                height: 100,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.video.title,
                            style: AppTypography.h4.copyWith(
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusMedium),
                            ),
                            child: Text(
                              widget.video.sector,
                              style: AppTypography.bodySmallText.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Stats
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatItem(
                          Icons.visibility,
                          Formatters.viewCount(widget.video.viewCount),
                        ),
                        const SizedBox(height: 4),
                        _buildStatItem(
                          Icons.business_center,
                          widget.video.offerCount.toString(),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Mute button
                    IconButton(
                      icon: Icon(
                        _isMuted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                      ),
                      onPressed: _toggleMute,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Center play/pause button
          if (!_isPlaying)
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.play_arrow,
                    size: 48,
                    color: Colors.white,
                  ),
                  onPressed: _togglePlayPause,
                ),
              ),
            ),

          // Like animation overlay
          if (_isLikeAnimating)
            Center(
              child: LikeAnimation(
                isAnimating: _isLikeAnimating,
                child: Icon(
                  Icons.favorite,
                  size: 100,
                  color: Colors.red.withOpacity(0.8),
                ),
              ),
            ),

          // Action buttons
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            right: _showOverlay ? 16 : -80,
            bottom: 120,
            child: Column(
              children: [
                _buildActionButton(
                  Icons.favorite_outline,
                  widget.video.likeCount.toString(),
                  _handleLike,
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  Icons.info_outline,
                  '',
                  () {
                    _toggleDetails();
                    widget.onInfo();
                  },
                ),
                const SizedBox(height: 16),
                if (widget.onOffer != null)
                  _buildActionButton(
                    Icons.business_center_outlined,
                    '',
                    widget.onOffer!,
                  ),
                if (widget.onOffer != null) const SizedBox(height: 16),
                _buildActionButton(
                  Icons.share_outlined,
                  '',
                  widget.onShare,
                ),
              ],
            ),
          ),

          // Bottom details section
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _showDetails ? 0 : -200,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.radiusLarge),
                  topRight: Radius.circular(AppDimensions.radiusLarge),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Title
                  Text(
                    'Proje Özeti',
                    style: AppTypography.h4.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        widget.video.description,
                        style: AppTypography.bodyMediumText.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  // Metadata
                  if (widget.video.metadata.requestedAmount != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMetadataItem(
                          'Talep Edilen',
                          Formatters.currency(
                              widget.video.metadata.requestedAmount!),
                        ),
                        const SizedBox(width: 16),
                        if (widget.video.metadata.equityOffered != null)
                          _buildMetadataItem(
                            'Hisse',
                            '${widget.video.metadata.equityOffered!}%',
                          ),
                      ],
                    ),
                  ],
                  // Close button
                  Center(
                    child: TextButton(
                      onPressed: _toggleDetails,
                      child: Text(
                        'Kapat',
                        style: AppTypography.bodyMediumText.copyWith(
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Progress bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String count,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, size: 24),
            color: Colors.black87,
            onPressed: onPressed,
          ),
        ),
        if (count.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            count,
            style: AppTypography.captionText.copyWith(
              color: Colors.white,
              fontWeight: AppTypography.fontMedium,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.white.withOpacity(0.8),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTypography.captionText.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.captionText.copyWith(
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmallText.copyWith(
            color: Colors.white,
            fontWeight: AppTypography.fontMedium,
          ),
        ),
      ],
    );
  }
}