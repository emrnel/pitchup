// lib/core/managers/video_upload_manager.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import '../constants/firebase_constants.dart';

class VideoUploadManager {
  static final VideoUploadManager _instance = VideoUploadManager._internal();
  factory VideoUploadManager() => _instance;
  VideoUploadManager._internal();

  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 5);
  static const int maxVideoSize = 100 * 1024 * 1024; // 100MB
  static const Duration maxVideoDuration = Duration(seconds: 60);
  static const int compressionQuality = 85; // 0-100

  UploadTask? _currentVideoUpload;
  UploadTask? _currentThumbnailUpload;
  bool _isUploading = false;
  String? _currentUploadId;

  bool get isUploading => _isUploading;
  String? get currentUploadId => _currentUploadId;

  /// Main method to upload video with comprehensive error handling and progress tracking
  Future<VideoUploadResult> uploadVideo({
    required File videoFile,
    required String userId,
    required Function(double) onProgress,
    required VoidCallback onComplete,
    required Function(String) onError,
  }) async {
    if (_isUploading) {
      onError('Başka bir video yükleniyor. Lütfen bekleyin.');
      return VideoUploadResult(success: false);
    }

    _isUploading = true;
    _currentUploadId = DateTime.now().millisecondsSinceEpoch.toString();
    int retryCount = 0;

    try {
      // Step 1: Validate video file
      onProgress(0.05);
      final validation = await _validateVideo(videoFile);
      if (!validation.isValid) {
        onError(validation.errorMessage!);
        return VideoUploadResult(
            success: false, error: validation.errorMessage);
      }

      // Step 2: Process (compress if needed) video
      onProgress(0.10);
      final processedFile = await _processVideo(
          videoFile,
          (compressionProgress) =>
              onProgress(0.10 + (compressionProgress * 0.30)));

      // Step 3: Generate thumbnail
      onProgress(0.40);
      final thumbnailFile = await _generateThumbnail(processedFile);

      // Step 4: Upload with retry mechanism
      while (retryCount < maxRetries) {
        try {
          final uploadResult = await _performUpload(
            videoFile: processedFile,
            thumbnailFile: thumbnailFile,
            userId: userId,
            onProgress: (uploadProgress) =>
                onProgress(0.50 + (uploadProgress * 0.50)),
          );

          if (uploadResult.success) {
            onComplete();
            return uploadResult;
          } else {
            throw Exception(uploadResult.error ?? 'Upload failed');
          }
        } catch (e) {
          retryCount++;
          debugPrint('Upload attempt $retryCount failed: $e');

          if (retryCount >= maxRetries) {
            final errorMsg =
                'Video yüklenemedi ($retryCount deneme). Lütfen daha sonra tekrar deneyin.';
            onError(errorMsg);
            return VideoUploadResult(success: false, error: errorMsg);
          }

          // Wait before retrying
          await Future.delayed(retryDelay);
          onProgress(0.50); // Reset progress for retry
        }
      }

      return VideoUploadResult(
          success: false, error: 'Beklenmedik hata oluştu');
    } catch (e) {
      final errorMsg = 'Video işlenirken hata oluştu: $e';
      onError(errorMsg);
      return VideoUploadResult(success: false, error: errorMsg);
    } finally {
      _isUploading = false;
      _currentVideoUpload = null;
      _currentThumbnailUpload = null;
      _currentUploadId = null;
    }
  }

  /// Validate video file before processing
  Future<VideoValidation> _validateVideo(File videoFile) async {
    try {
      // Check if file exists
      if (!await videoFile.exists()) {
        return VideoValidation(
          isValid: false,
          errorMessage: 'Video dosyası bulunamadı',
        );
      }

      // Check file size
      final fileSize = await videoFile.length();
      if (fileSize > maxVideoSize) {
        final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
        return VideoValidation(
          isValid: false,
          errorMessage:
              'Video boyutu çok büyük ($sizeMB MB). Maksimum 100MB olmalı.',
        );
      }

      // Check video duration and format using video_player
      final controller = VideoPlayerController.file(videoFile);
      try {
        await controller.initialize();

        final duration = controller.value.duration;
        if (duration > maxVideoDuration) {
          return VideoValidation(
            isValid: false,
            errorMessage: 'Video süresi 60 saniyeden uzun olamaz',
          );
        }

        // Check if video has valid dimensions
        final size = controller.value.size;
        if (size.width == 0 || size.height == 0) {
          return VideoValidation(
            isValid: false,
            errorMessage: 'Geçersiz video formatı',
          );
        }
      } finally {
        await controller.dispose();
      }

      // Check file extension
      final extension = videoFile.path.split('.').last.toLowerCase();
      const allowedExtensions = ['mp4', 'mov', 'avi', 'mkv', 'm4v'];

      if (!allowedExtensions.contains(extension)) {
        return VideoValidation(
          isValid: false,
          errorMessage:
              'Desteklenmeyen video formatı. Desteklenen: ${allowedExtensions.join(', ')}',
        );
      }

      return VideoValidation(isValid: true);
    } catch (e) {
      debugPrint('Video validation error: $e');
      return VideoValidation(
        isValid: false,
        errorMessage:
            'Video doğrulanamadı. Lütfen geçerli bir video dosyası seçin.',
      );
    }
  }

  /// Process video (compress if needed)
  Future<File> _processVideo(
    File videoFile,
    Function(double) onProgress,
  ) async {
    try {
      final fileSize = await videoFile.length();

      // If file is small enough, skip compression
      if (fileSize <= 50 * 1024 * 1024) {
        // 50MB threshold
        onProgress(1.0);
        return videoFile;
      }

      debugPrint('Compressing video: ${fileSize / (1024 * 1024)} MB');

      try {
        // Simulate progress while compressing
        onProgress(0.1);

        // Start compression
        final mediaInfo = await VideoCompress.compressVideo(
          videoFile.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
          includeAudio: true,
          frameRate: 30,
        );

        onProgress(0.9);

        if (mediaInfo == null || mediaInfo.file == null) {
          throw Exception('Video compression failed - null result');
        }

        final compressedSize = await mediaInfo.file!.length();
        debugPrint('Video compressed: ${compressedSize / (1024 * 1024)} MB');

        // Verify compressed video is valid
        if (compressedSize == 0) {
          throw Exception('Compressed video is empty');
        }

        onProgress(1.0);
        return mediaInfo.file!;
      } catch (e) {
        debugPrint('Video compression failed: $e');
        // If compression fails, try to use original file if it's not too large
        final fileSize = await videoFile.length();
        if (fileSize <= maxVideoSize) {
          debugPrint('Using original file after compression failure');
          onProgress(1.0);
          return videoFile;
        } else {
          throw Exception('Video çok büyük ve sıkıştırılamadı');
        }
      }
    } catch (e) {
      debugPrint('Video processing failed: $e');
      // If compression fails, try to use original file if it's not too large
      final fileSize = await videoFile.length();
      if (fileSize <= maxVideoSize) {
        debugPrint('Using original file after processing failure');
        onProgress(1.0);
        return videoFile;
      } else {
        throw Exception('Video çok büyük ve işlenemedi');
      }
    }
  }

  /// Generate thumbnail from video
  Future<File?> _generateThumbnail(File videoFile) async {
    try {
      final thumbnailFile = await VideoCompress.getFileThumbnail(
        videoFile.path,
        quality: compressionQuality,
        position: 1000, // 1 second into video
      );

      if (thumbnailFile == null) {
        debugPrint('Thumbnail generation returned null');
        return null;
      }

      // Verify thumbnail file
      final exists = await thumbnailFile.exists();
      if (!exists) {
        debugPrint('Generated thumbnail file does not exist');
        return null;
      }

      final size = await thumbnailFile.length();
      if (size == 0) {
        debugPrint('Generated thumbnail file is empty');
        return null;
      }

      debugPrint('Thumbnail generated successfully: ${size} bytes');
      return thumbnailFile;
    } catch (e) {
      debugPrint('Thumbnail generation failed: $e');
      return null;
    }
  }

  /// Perform the actual upload to Firebase Storage
  Future<VideoUploadResult> _performUpload({
    required File videoFile,
    required File? thumbnailFile,
    required String userId,
    required Function(double) onProgress,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final videoFileName = '${userId}_${timestamp}.mp4';
      final thumbnailFileName = '${userId}_${timestamp}_thumb.jpg';

      // Upload video
      final videoRef = FirebaseStorage.instance
          .ref()
          .child(FirebaseConstants.videosStorage)
          .child(userId)
          .child(videoFileName);

      _currentVideoUpload = videoRef.putFile(
        videoFile,
        SettableMetadata(
          contentType: 'video/mp4',
          customMetadata: {
            'uploadId': _currentUploadId!,
            'userId': userId,
            'timestamp': timestamp.toString(),
          },
        ),
      );

      // Monitor video upload progress (80% of total progress)
      _currentVideoUpload!.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress * 0.8);
      });

      final videoSnapshot = await _currentVideoUpload!;
      final videoUrl = await videoSnapshot.ref.getDownloadURL();

      String? thumbnailUrl;

      // Upload thumbnail if available
      if (thumbnailFile != null) {
        try {
          final thumbnailRef = FirebaseStorage.instance
              .ref()
              .child(FirebaseConstants.thumbnailsStorage)
              .child(userId)
              .child(thumbnailFileName);

          _currentThumbnailUpload = thumbnailRef.putFile(
            thumbnailFile,
            SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {
                'uploadId': _currentUploadId!,
                'userId': userId,
                'videoFileName': videoFileName,
              },
            ),
          );

          // Monitor thumbnail upload progress (remaining 20%)
          _currentThumbnailUpload!.snapshotEvents
              .listen((TaskSnapshot snapshot) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(0.8 + (progress * 0.2));
          });

          final thumbnailSnapshot = await _currentThumbnailUpload!;
          thumbnailUrl = await thumbnailSnapshot.ref.getDownloadURL();
        } catch (e) {
          debugPrint('Thumbnail upload failed: $e');
          // Continue without thumbnail - not critical
        }
      }

      // Cleanup temporary files
      await _cleanupTempFiles(videoFile, thumbnailFile);

      onProgress(1.0);

      return VideoUploadResult(
        success: true,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        uploadId: _currentUploadId,
      );
    } on FirebaseException catch (e) {
      throw Exception('Firebase upload error: ${e.message}');
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }

  /// Cleanup temporary files
  Future<void> _cleanupTempFiles(File videoFile, File? thumbnailFile) async {
    try {
      // Only delete if it's a temporary compressed file
      final tempDir = await getTemporaryDirectory();
      if (videoFile.path.startsWith(tempDir.path)) {
        await videoFile.delete();
        debugPrint('Cleaned up temporary video file');
      }

      if (thumbnailFile != null && await thumbnailFile.exists()) {
        await thumbnailFile.delete();
        debugPrint('Cleaned up thumbnail file');
      }
    } catch (e) {
      debugPrint('Cleanup error: $e');
      // Non-critical error
    }
  }

  /// Cancel current upload
  void cancelUpload() {
    try {
      _currentVideoUpload?.cancel();
      _currentThumbnailUpload?.cancel();
      debugPrint('Upload cancelled');
    } catch (e) {
      debugPrint('Cancel upload error: $e');
    } finally {
      _isUploading = false;
      _currentVideoUpload = null;
      _currentThumbnailUpload = null;
      _currentUploadId = null;
    }
  }

  /// Get upload progress for current upload
  Stream<double>? getUploadProgress() {
    if (_currentVideoUpload == null) return null;

    return _currentVideoUpload!.snapshotEvents.map((snapshot) {
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }

  /// Pause current upload (if supported)
  Future<bool> pauseUpload() async {
    try {
      if (_currentVideoUpload != null) {
        await _currentVideoUpload!.pause();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Pause upload error: $e');
      return false;
    }
  }

  /// Resume paused upload
  Future<bool> resumeUpload() async {
    try {
      if (_currentVideoUpload != null) {
        await _currentVideoUpload!.resume();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Resume upload error: $e');
      return false;
    }
  }
}

// Data classes for upload results
class VideoUploadResult {
  final bool success;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? uploadId;
  final String? error;

  VideoUploadResult({
    required this.success,
    this.videoUrl,
    this.thumbnailUrl,
    this.uploadId,
    this.error,
  });

  @override
  String toString() {
    return 'VideoUploadResult(success: $success, videoUrl: $videoUrl, thumbnailUrl: $thumbnailUrl, error: $error)';
  }
}

class VideoValidation {
  final bool isValid;
  final String? errorMessage;

  VideoValidation({
    required this.isValid,
    this.errorMessage,
  });

  @override
  String toString() {
    return 'VideoValidation(isValid: $isValid, errorMessage: $errorMessage)';
  }
}