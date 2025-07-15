import '../models/video_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'dart:io';

class VideoRepository {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  Future<List<VideoModel>> getApprovedVideos({
    int limit = 20,
    String? lastVideoId,
  }) async {
    return await _firestoreService.getApprovedVideos(
      limit: limit,
      lastVideoId: lastVideoId,
    );
  }

  Future<List<VideoModel>> getUserVideos(String userId) async {
    return await _firestoreService.getUserVideos(userId);
  }

  Future<VideoModel?> getVideo(String videoId) async {
    return await _firestoreService.getVideo(videoId);
  }

  Future<VideoModel> createVideo({
    required String userId,
    required String videoUrl,
    required String thumbnailUrl,
    required String title,
    required String description,
    required String sector,
    required int duration,
    required VideoMetadata metadata,
  }) async {
    final video = VideoModel(
      id: '',
      userId: userId,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      title: title,
      description: description,
      sector: sector,
      duration: duration,
      viewCount: 0,
      likeCount: 0,
      offerCount: 0,
      status: VideoStatus.pending,
      metadata: metadata,
      createdAt: DateTime.now(),
    );

    return await _firestoreService.createVideo(video);
  }

  Future<void> incrementViewCount(String videoId) async {
    await _firestoreService.incrementVideoViewCount(videoId);
  }

  Future<void> toggleLike(String videoId, String userId) async {
    await _firestoreService.toggleVideoLike(videoId, userId);
  }

  Future<List<VideoModel>> searchVideos(String query) async {
    return await _firestoreService.searchVideos(query);
  }

  Future<List<VideoModel>> getVideosBySector(String sector) async {
    return await _firestoreService.getVideosBySector(sector);
  }

  Future<void> deleteVideo(String videoId) async {
    final video = await _firestoreService.getVideo(videoId);
    if (video != null) {
      // Delete video file
      if (video.videoUrl.isNotEmpty) {
        await _storageService.deleteFile(video.videoUrl);
      }

      // Delete thumbnail
      if (video.thumbnailUrl != null && video.thumbnailUrl!.isNotEmpty) {
        await _storageService.deleteFile(video.thumbnailUrl!);
      }

      // Delete from Firestore
      await _firestoreService.deleteVideo(videoId);
    }
  }
}
