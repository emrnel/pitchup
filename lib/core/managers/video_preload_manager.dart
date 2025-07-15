import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/video_model.dart';

class VideoPreloadManager {
  static final VideoPreloadManager _instance = VideoPreloadManager._internal();
  factory VideoPreloadManager() => _instance;
  VideoPreloadManager._internal();

  static const int preloadCount = 3; // Number of videos to preload ahead
  static const int maxControllers = 8; // Maximum controllers to keep in memory
  static const int preloadBehindCount =
      1; // Number of videos to keep behind current

  final Map<String, VideoPlayerController> _controllers = {};
  final Map<String, VideoControllerState> _controllerStates = {};
  final List<String> _controllerOrder = [];

  // Statistics for monitoring
  int _totalPreloaded = 0;
  int _totalDisposed = 0;
  int _cacheHits = 0;
  int _cacheMisses = 0;

  // Getters for monitoring
  int get totalControllers => _controllers.length;
  int get totalPreloaded => _totalPreloaded;
  int get totalDisposed => _totalDisposed;
  int get cacheHitRate => _cacheMisses > 0
      ? (_cacheHits / (_cacheHits + _cacheMisses) * 100).round()
      : 0;

  /// Main method to preload videos around current index
  Future<void> preloadVideos(List<VideoModel> videos, int currentIndex) async {
    if (videos.isEmpty || currentIndex < 0 || currentIndex >= videos.length) {
      return;
    }

    debugPrint('Preloading videos around index $currentIndex');

    // Clean up controllers that are too far from current position
    _cleanupDistantControllers(videos, currentIndex);

    // Preload videos ahead
    for (int i = 0; i <= preloadCount; i++) {
      final index = currentIndex + i;
      if (index < videos.length) {
        _preloadVideoAt(videos[index], index, currentIndex);
      }
    }

    // Keep some videos behind current position
    for (int i = 1; i <= preloadBehindCount; i++) {
      final index = currentIndex - i;
      if (index >= 0) {
        _preloadVideoAt(videos[index], index, currentIndex);
      }
    }

    // Ensure we don't exceed max controllers
    if (_controllers.length > maxControllers) {
      _removeOldestControllers();
    }

    _printStats();
  }

  /// Preload a specific video
  Future<void> _preloadVideoAt(
      VideoModel video, int videoIndex, int currentIndex) async {
    if (_controllers.containsKey(video.id)) {
      // Update last accessed time
      _controllerStates[video.id] = _controllerStates[video.id]!.copyWith(
        lastAccessed: DateTime.now(),
      );
      return;
    }

    try {
      final controller = VideoPlayerController.network(
        video.videoUrl,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      // Store controller and its state
      _controllers[video.id] = controller;
      _controllerOrder.add(video.id);
      _controllerStates[video.id] = VideoControllerState(
        videoId: video.id,
        index: videoIndex,
        createdAt: DateTime.now(),
        lastAccessed: DateTime.now(),
        isInitialized: false,
        priority: _calculatePriority(videoIndex, currentIndex),
      );

      // Initialize controller
      await controller.initialize();

      // Update state
      _controllerStates[video.id] = _controllerStates[video.id]!.copyWith(
        isInitialized: true,
        initializationTime: DateTime.now(),
      );

      // Set to muted by default (user can unmute)
      await controller.setVolume(0);

      _totalPreloaded++;
      debugPrint('✅ Preloaded video: ${video.title} (${video.id})');
    } catch (e) {
      debugPrint('❌ Failed to preload video ${video.id}: $e');

      // Clean up on failure
      _controllers.remove(video.id);
      _controllerOrder.remove(video.id);
      _controllerStates.remove(video.id);
    }
  }

  /// Calculate priority for controller (higher = more important)
  int _calculatePriority(int videoIndex, int currentIndex) {
    final distance = (videoIndex - currentIndex).abs();
    if (distance == 0) return 100; // Current video
    if (distance == 1) return 80; // Next/previous video
    if (distance == 2) return 60; // Two positions away
    if (distance == 3) return 40; // Three positions away
    return 20; // Far away
  }

  /// Clean up controllers that are too far from current position
  void _cleanupDistantControllers(List<VideoModel> videos, int currentIndex) {
    final toRemove = <String>[];

    _controllers.forEach((id, controller) {
      final state = _controllerStates[id];
      if (state == null) {
        toRemove.add(id);
        return;
      }

      final videoIndex = videos.indexWhere((v) => v.id == id);
      if (videoIndex == -1) {
        // Video no longer in list
        toRemove.add(id);
        return;
      }

      final distance = (videoIndex - currentIndex).abs();
      if (distance > preloadCount + preloadBehindCount) {
        toRemove.add(id);
      }
    });

    for (final id in toRemove) {
      _removeController(id);
    }
  }

  /// Remove oldest controllers when we exceed the limit
  void _removeOldestControllers() {
    while (
        _controllers.length > maxControllers && _controllerOrder.isNotEmpty) {
      // Sort by priority and last accessed time
      final sortedIds = _controllerStates.keys.toList()
        ..sort((a, b) {
          final stateA = _controllerStates[a]!;
          final stateB = _controllerStates[b]!;

          // First sort by priority (lower priority gets removed first)
          final priorityCompare = stateA.priority.compareTo(stateB.priority);
          if (priorityCompare != 0) return priorityCompare;

          // Then by last accessed time (older gets removed first)
          return stateA.lastAccessed.compareTo(stateB.lastAccessed);
        });

      if (sortedIds.isNotEmpty) {
        _removeController(sortedIds.first);
      }
    }
  }

  /// Remove a specific controller
  void _removeController(String id) {
    final controller = _controllers[id];
    if (controller != null) {
      try {
        controller.dispose();
        _totalDisposed++;
        debugPrint('🗑️ Disposed controller: $id');
      } catch (e) {
        debugPrint('Error disposing controller $id: $e');
      }

      _controllers.remove(id);
      _controllerOrder.remove(id);
      _controllerStates.remove(id);
    }
  }

  /// Get controller for a specific video (for immediate use)
  VideoPlayerController? getController(String videoId) {
    final controller = _controllers[videoId];

    if (controller != null) {
      _cacheHits++;
      // Update last accessed time
      _controllerStates[videoId] = _controllerStates[videoId]!.copyWith(
        lastAccessed: DateTime.now(),
      );
    } else {
      _cacheMisses++;
    }

    return controller;
  }

  /// Get or create controller (blocking operation)
  Future<VideoPlayerController> getOrCreateController(VideoModel video) async {
    var controller = _controllers[video.id];

    if (controller == null) {
      debugPrint('🔄 Creating controller on demand for: ${video.title}');

      controller = VideoPlayerController.network(
        video.videoUrl,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      _controllers[video.id] = controller;
      _controllerOrder.add(video.id);
      _controllerStates[video.id] = VideoControllerState(
        videoId: video.id,
        index: -1, // Unknown index
        createdAt: DateTime.now(),
        lastAccessed: DateTime.now(),
        isInitialized: false,
        priority: 50, // Medium priority
      );

      await controller.initialize();
      await controller.setVolume(0);

      _controllerStates[video.id] = _controllerStates[video.id]!.copyWith(
        isInitialized: true,
        initializationTime: DateTime.now(),
      );

      _totalPreloaded++;

      // Manage memory
      if (_controllers.length > maxControllers) {
        _removeOldestControllers();
      }
    } else {
      _cacheHits++;
      // Update last accessed time
      _controllerStates[video.id] = _controllerStates[video.id]!.copyWith(
        lastAccessed: DateTime.now(),
      );
    }

    return controller;
  }

  /// Pause all controllers (e.g., when app goes to background)
  void pauseAll() {
    _controllers.values.forEach((controller) {
      try {
        if (controller.value.isInitialized && controller.value.isPlaying) {
          controller.pause();
        }
      } catch (e) {
        debugPrint('Error pausing controller: $e');
      }
    });
  }

  /// Resume specific controller
  void resumeController(String videoId) {
    final controller = _controllers[videoId];
    if (controller?.value.isInitialized == true) {
      try {
        controller!.play();
      } catch (e) {
        debugPrint('Error resuming controller $videoId: $e');
      }
    }
  }

  /// Set volume for all controllers
  void setVolumeForAll(double volume) {
    _controllers.values.forEach((controller) {
      try {
        if (controller.value.isInitialized) {
          controller.setVolume(volume);
        }
      } catch (e) {
        debugPrint('Error setting volume: $e');
      }
    });
  }

  /// Check if a video is preloaded and ready
  bool isVideoReady(String videoId) {
    final controller = _controllers[videoId];
    return controller?.value.isInitialized == true;
  }

  /// Get detailed information about a controller
  VideoControllerInfo? getControllerInfo(String videoId) {
    final controller = _controllers[videoId];
    final state = _controllerStates[videoId];

    if (controller == null || state == null) return null;

    return VideoControllerInfo(
      videoId: videoId,
      isInitialized: controller.value.isInitialized,
      isPlaying: controller.value.isPlaying,
      duration: controller.value.duration,
      position: controller.value.position,
      hasError: controller.value.hasError,
      state: state,
    );
  }

  /// Print statistics for debugging
  void _printStats() {
    debugPrint('''
📊 VideoPreloadManager Stats:
   Controllers: ${_controllers.length}/$maxControllers
   Preloaded: $_totalPreloaded | Disposed: $_totalDisposed
   Cache Hit Rate: $cacheHitRate%
   Controller IDs: ${_controllers.keys.take(3).join(', ')}${_controllers.length > 3 ? '...' : ''}
''');
  }

  /// Force cleanup of all controllers
  void dispose() {
    debugPrint('🧹 Disposing all controllers (${_controllers.length})');

    _controllers.forEach((id, controller) {
      try {
        controller.dispose();
      } catch (e) {
        debugPrint('Error disposing controller $id: $e');
      }
    });

    _controllers.clear();
    _controllerOrder.clear();
    _controllerStates.clear();

    debugPrint('✅ All controllers disposed');
  }

  /// Preload specific videos by IDs (useful for bookmarks, etc.)
  Future<void> preloadSpecificVideos(List<VideoModel> videos) async {
    for (final video in videos) {
      if (!_controllers.containsKey(video.id)) {
        await _preloadVideoAt(video, -1, -1);
      }
    }
  }

  /// Get memory usage statistics
  Map<String, dynamic> getMemoryStats() {
    return {
      'totalControllers': _controllers.length,
      'maxControllers': maxControllers,
      'preloadCount': preloadCount,
      'totalPreloaded': _totalPreloaded,
      'totalDisposed': _totalDisposed,
      'cacheHitRate': cacheHitRate,
      'memoryPressure': _controllers.length / maxControllers,
    };
  }
}

// Supporting data classes
class VideoControllerState {
  final String videoId;
  final int index;
  final DateTime createdAt;
  final DateTime lastAccessed;
  final DateTime? initializationTime;
  final bool isInitialized;
  final int priority;

  VideoControllerState({
    required this.videoId,
    required this.index,
    required this.createdAt,
    required this.lastAccessed,
    this.initializationTime,
    required this.isInitialized,
    required this.priority,
  });

  VideoControllerState copyWith({
    String? videoId,
    int? index,
    DateTime? createdAt,
    DateTime? lastAccessed,
    DateTime? initializationTime,
    bool? isInitialized,
    int? priority,
  }) {
    return VideoControllerState(
      videoId: videoId ?? this.videoId,
      index: index ?? this.index,
      createdAt: createdAt ?? this.createdAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      initializationTime: initializationTime ?? this.initializationTime,
      isInitialized: isInitialized ?? this.isInitialized,
      priority: priority ?? this.priority,
    );
  }
}

class VideoControllerInfo {
  final String videoId;
  final bool isInitialized;
  final bool isPlaying;
  final Duration duration;
  final Duration position;
  final bool hasError;
  final VideoControllerState state;

  VideoControllerInfo({
    required this.videoId,
    required this.isInitialized,
    required this.isPlaying,
    required this.duration,
    required this.position,
    required this.hasError,
    required this.state,
  });

  @override
  String toString() {
    return 'VideoControllerInfo(id: $videoId, initialized: $isInitialized, playing: $isPlaying, duration: $duration)';
  }
}
