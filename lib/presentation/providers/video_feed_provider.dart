import 'package:flutter/foundation.dart';
import '../../data/models/video_model.dart';
import '../../data/repositories/video_repository.dart';
import '../../core/managers/video_preload_manager.dart';
import '../../core/managers/analytics_manager.dart';

class VideoFeedProvider extends ChangeNotifier {
  final VideoRepository _videoRepository = VideoRepository();
  final VideoPreloadManager _preloadManager = VideoPreloadManager();

  List<VideoModel> _videos = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String? _lastVideoId;
  bool _hasMore = true;

  // Getters
  List<VideoModel> get videos => _videos;
  VideoModel? get currentVideo =>
      _videos.isNotEmpty ? _videos[_currentIndex] : null;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> loadVideos() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      final videos = await _videoRepository.getApprovedVideos(limit: 20);

      _videos = videos;
      _currentIndex = 0;
      _lastVideoId = videos.isNotEmpty ? videos.last.id : null;
      _hasMore = videos.length >= 20;

      // Preload first few videos
      if (_videos.isNotEmpty) {
        await _preloadManager.preloadVideos(_videos, 0);
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to load videos: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMoreVideos() async {
    if (_isLoadingMore || !_hasMore || _lastVideoId == null) return;

    _setLoadingMore(true);

    try {
      final moreVideos = await _videoRepository.getApprovedVideos(
        limit: 20,
        lastVideoId: _lastVideoId,
      );

      if (moreVideos.isNotEmpty) {
        _videos.addAll(moreVideos);
        _lastVideoId = moreVideos.last.id;
        _hasMore = moreVideos.length >= 20;
        notifyListeners();
      } else {
        _hasMore = false;
      }
    } catch (e) {
      _setError('Failed to load more videos: $e');
    } finally {
      _setLoadingMore(false);
    }
  }

  Future<void> nextVideo() async {
    if (_currentIndex < _videos.length - 1) {
      _currentIndex++;

      // Log video view
      if (currentVideo != null) {
        await _videoRepository.incrementViewCount(currentVideo!.id);
        await AnalyticsManager.instance.logVideoView(
          currentVideo!.id,
          currentVideo!.duration,
        );
      }

      // Preload upcoming videos
      await _preloadManager.preloadVideos(_videos, _currentIndex);

      // Load more videos if needed
      if (_currentIndex >= _videos.length - 5) {
        await loadMoreVideos();
      }

      notifyListeners();
    }
  }

  void previousVideo() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void goToVideo(int index) {
    if (index >= 0 && index < _videos.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  Future<void> toggleLike(String videoId) async {
    try {
      await _videoRepository.toggleLike(
          videoId, 'current_user_id'); // TODO: Get from auth
      await AnalyticsManager.instance.logVideoLike(videoId);

      // Update video in list
      final videoIndex = _videos.indexWhere((v) => v.id == videoId);
      if (videoIndex != -1) {
        // This is a simplified update - in real app you'd track user's likes
        final video = _videos[videoIndex];
        _videos[videoIndex] = video.copyWith(
          likeCount: video.likeCount + 1, // Simplified
        );
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to toggle like: $e');
    }
  }

  Future<void> shareVideo(String videoId) async {
    try {
      await AnalyticsManager.instance.logVideoShare(videoId, 'app_share');
      // TODO: Implement actual sharing
    } catch (e) {
      _setError('Failed to share video: $e');
    }
  }

  Future<void> searchVideos(String query) async {
    if (query.isEmpty) {
      await loadVideos();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final videos = await _videoRepository.searchVideos(query);
      _videos = videos;
      _currentIndex = 0;
      _hasMore = false; // Search results don't support pagination
      notifyListeners();
    } catch (e) {
      _setError('Failed to search videos: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> filterBySector(String sector) async {
    _setLoading(true);
    _clearError();

    try {
      final videos = await _videoRepository.getVideosBySector(sector);
      _videos = videos;
      _currentIndex = 0;
      _hasMore = false; // Filtered results don't support pagination
      notifyListeners();
    } catch (e) {
      _setError('Failed to filter videos: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    _videos.clear();
    _currentIndex = 0;
    _lastVideoId = null;
    _hasMore = true;
    await loadVideos();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setLoadingMore(bool loading) {
    _isLoadingMore = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    _preloadManager.dispose();
    super.dispose();
  }
}
