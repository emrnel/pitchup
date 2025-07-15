import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/constants/firebase_constants.dart';
import 'firebase_service.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseService.storage;

  Future<String> uploadProfilePicture({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage
          .ref()
          .child(FirebaseConstants.profilePicturesStorage)
          .child(userId)
          .child(fileName);

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  Future<String> uploadDocument({
    required String userId,
    required File documentFile,
    required String fileName,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uploadFileName = '${userId}_${timestamp}_$fileName';
      final ref = _storage
          .ref()
          .child(FirebaseConstants.documentsStorage)
          .child(userId)
          .child(uploadFileName);

      final uploadTask = ref.putFile(documentFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      // File might already be deleted or doesn't exist
      print('Failed to delete file: $e');
    }
  }

  Future<List<String>> getUserFiles(String userId, String folder) async {
    try {
      final ref = _storage.ref().child(folder).child(userId);
      final listResult = await ref.listAll();

      final urls = <String>[];
      for (final item in listResult.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }

      return urls;
    } catch (e) {
      throw Exception('Failed to get user files: $e');
    }
  }

  Future<int> getFileSize(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      final metadata = await ref.getMetadata();
      return metadata.size ?? 0;
    } catch (e) {
      return 0;
    }
  }

  UploadTask? uploadVideoWithProgress({
    required String userId,
    required File videoFile,
    required String fileName,
  }) {
    try {
      final ref = _storage
          .ref()
          .child(FirebaseConstants.videosStorage)
          .child(userId)
          .child(fileName);

      return ref.putFile(videoFile);
    } catch (e) {
      throw Exception('Failed to start video upload: $e');
    }
  }

  UploadTask? uploadThumbnailWithProgress({
    required String userId,
    required File thumbnailFile,
    required String fileName,
  }) {
    try {
      final ref = _storage
          .ref()
          .child(FirebaseConstants.thumbnailsStorage)
          .child(userId)
          .child(fileName);

      return ref.putFile(thumbnailFile);
    } catch (e) {
      throw Exception('Failed to start thumbnail upload: $e');
    }
  }
}
