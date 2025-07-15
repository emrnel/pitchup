import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../data/models/video_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/video_repository.dart';
import '../../core/managers/analytics_manager.dart';

class ProfileProvider extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();
  final VideoRepository _videoRepository = VideoRepository();

  UserModel? _user;
  List<VideoModel> _userVideos = [];
  bool _isLoading = false;
  bool _isUpdatingProfile = false;
  bool _isUploadingImage = false;
  String? _error;

  // Getters
  UserModel? get user => _user;
  List<VideoModel> get userVideos => _userVideos;
  bool get isLoading => _isLoading;
  bool get isUpdatingProfile => _isUpdatingProfile;
  bool get isUploadingImage => _isUploadingImage;
  String? get error => _error;

  int get totalViews =>
      _userVideos.fold(0, (sum, video) => sum + video.viewCount);
  int get totalLikes =>
      _userVideos.fold(0, (sum, video) => sum + video.likeCount);
  int get totalOffers =>
      _userVideos.fold(0, (sum, video) => sum + video.offerCount);

  Future<void> loadUserProfile(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _userRepository.getUser(userId);
      await AnalyticsManager.instance.logScreenView('profile');
      notifyListeners();
    } catch (e) {
      _setError('Failed to load profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUserVideos(String userId) async {
    try {
      _userVideos = await _videoRepository.getUserVideos(userId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user videos: $e');
    }
  }

  Future<bool> updateProfile({
    required String userId,
    required String name,
    String? bio,
    CompanyInfo? company,
  }) async {
    if (_user == null) return false;

    _setUpdatingProfile(true);
    _clearError();

    try {
      final updatedUser = _user!.copyWith(
        name: name,
        bio: bio,
        company: company,
        updatedAt: DateTime.now(),
      );

      await _userRepository.updateUser(updatedUser);
      _user = updatedUser;

      await AnalyticsManager.instance.logEvent(name: 'profile_updated');

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update profile: $e');
      return false;
    } finally {
      _setUpdatingProfile(false);
    }
  }

  Future<bool> updateProfilePicture(String userId, File imageFile) async {
    _setUploadingImage(true);
    _clearError();

    try {
      final imageUrl = await _userRepository.updateProfilePicture(
        userId,
        imageFile,
      );

      if (_user != null && imageUrl != null) {
        _user = _user!.copyWith(
          profilePicture: imageUrl,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to update profile picture: $e');
      return false;
    } finally {
      _setUploadingImage(false);
    }
  }

  Future<bool> updateCompanyInfo(String userId, CompanyInfo company) async {
    _setUpdatingProfile(true);
    _clearError();

    try {
      await _userRepository.updateCompanyInfo(userId, company);

      if (_user != null) {
        _user = _user!.copyWith(
          company: company,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to update company info: $e');
      return false;
    } finally {
      _setUpdatingProfile(false);
    }
  }

  Future<void> deleteVideo(String videoId) async {
    try {
      await _videoRepository.deleteVideo(videoId);
      _userVideos.removeWhere((video) => video.id == videoId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete video: $e');
    }
  }

  void updateUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void addVideo(VideoModel video) {
    _userVideos.insert(0, video);
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setUpdatingProfile(bool updating) {
    _isUpdatingProfile = updating;
    notifyListeners();
  }

  void _setUploadingImage(bool uploading) {
    _isUploadingImage = uploading;
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
}
