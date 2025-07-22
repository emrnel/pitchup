// lib/data/repositories/user_repository.dart
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'dart:io';

class UserRepository {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  Future<UserModel?> getUser(String userId) async {
    return await _firestoreService.getUser(userId);
  }

  Future<void> updateUser(UserModel user) async {
    await _firestoreService.updateUser(user);
  }

  Future<String?> updateProfilePicture(String userId, File imageFile) async {
    try {
      final imageUrl = await _storageService.uploadProfilePicture(
        userId: userId,
        imageFile: imageFile,
      );

      await _firestoreService.updateUserProfilePicture(userId, imageUrl);

      return imageUrl;
    } catch (e) {
      throw Exception('Failed to update profile picture: $e');
    }
  }

  Future<void> updateCompanyInfo(String userId, CompanyInfo company) async {
    await _firestoreService.updateUserCompanyInfo(userId, company);
  }

  Future<List<UserModel>> searchUsers(String query) async {
    return await _firestoreService.searchUsers(query);
  }

  Future<List<UserModel>> getInvestors({int limit = 20}) async {
    return await _firestoreService.getInvestors(limit: limit);
  }

  Future<List<UserModel>> getEntrepreneurs({int limit = 20}) async {
    return await _firestoreService.getEntrepreneurs(limit: limit);
  }
}