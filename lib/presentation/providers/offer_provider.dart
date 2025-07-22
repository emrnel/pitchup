// lib/presentation/providers/offer_provider.dart
import 'package:flutter/foundation.dart';
import '../../data/models/offer_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/offer_repository.dart';
import '../../core/managers/analytics_manager.dart';

class OfferProvider extends ChangeNotifier {
  final OfferRepository _offerRepository = OfferRepository();

  List<OfferModel> _sentOffers = [];
  List<OfferModel> _receivedOffers = [];
  bool _isLoading = false;
  bool _isCreatingOffer = false;
  bool _isUpdatingOffer = false;
  String? _error;

  // Getters
  List<OfferModel> get sentOffers => _sentOffers;
  List<OfferModel> get receivedOffers => _receivedOffers;
  bool get isLoading => _isLoading;
  bool get isCreatingOffer => _isCreatingOffer;
  bool get isUpdatingOffer => _isUpdatingOffer;
  String? get error => _error;

  int get pendingSentOffers =>
      _sentOffers.where((o) => o.status == OfferStatus.pending).length;
  int get pendingReceivedOffers =>
      _receivedOffers.where((o) => o.status == OfferStatus.pending).length;
  int get acceptedOffers =>
      _receivedOffers.where((o) => o.status == OfferStatus.accepted).length;

  Future<void> loadSentOffers(String investorId) async {
    _setLoading(true);
    _clearError();

    try {
      _sentOffers = await _offerRepository.getSentOffers(investorId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load sent offers: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadReceivedOffers(String entrepreneurId) async {
    _setLoading(true);
    _clearError();

    try {
      _receivedOffers =
          await _offerRepository.getReceivedOffers(entrepreneurId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load received offers: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createOffer({
    required String videoId,
    required String entrepreneurId,
    required String investorId,
    required double amount,
    required double equityPercentage,
    String? note,
  }) async {
    _setCreatingOffer(true);
    _clearError();

    try {
      // Check if user already offered on this video
      final hasOffered = await _offerRepository.hasUserOfferedOnVideo(
        investorId,
        videoId,
      );

      if (hasOffered) {
        _setError('Bu video için zaten teklif gönderdiniz');
        return false;
      }

      final offer = await _offerRepository.createOffer(
        videoId: videoId,
        entrepreneurId: entrepreneurId,
        investorId: investorId,
        amount: amount,
        equityPercentage: equityPercentage,
        note: note,
      );

      _sentOffers.insert(0, offer);

      await AnalyticsManager.instance.logOfferSent(videoId, amount);

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create offer: $e');
      return false;
    } finally {
      _setCreatingOffer(false);
    }
  }

  Future<bool> updateOfferStatus(String offerId, OfferStatus status) async {
    _setUpdatingOffer(true);
    _clearError();

    try {
      await _offerRepository.updateOfferStatus(offerId, status);

      // Update local list
      final offerIndex = _receivedOffers.indexWhere((o) => o.id == offerId);
      if (offerIndex != -1) {
        _receivedOffers[offerIndex] = _receivedOffers[offerIndex].copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
      }

      if (status == OfferStatus.accepted) {
        await AnalyticsManager.instance.logOfferAccepted(offerId);
      } else if (status == OfferStatus.rejected) {
        await AnalyticsManager.instance.logOfferRejected(offerId);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update offer status: $e');
      return false;
    } finally {
      _setUpdatingOffer(false);
    }
  }

  Future<OfferModel?> getOffer(String offerId) async {
    try {
      return await _offerRepository.getOffer(offerId);
    } catch (e) {
      _setError('Failed to get offer: $e');
      return null;
    }
  }

  Future<List<OfferModel>> getVideoOffers(String videoId) async {
    try {
      return await _offerRepository.getVideoOffers(videoId);
    } catch (e) {
      _setError('Failed to get video offers: $e');
      return [];
    }
  }

  Future<void> refreshOffers(String userId, UserRole userRole) async {
    if (userRole == UserRole.investor) {
      await loadSentOffers(userId);
    } else {
      await loadReceivedOffers(userId);
    }
  }

  OfferModel? findOfferById(String offerId) {
    try {
      return _sentOffers.firstWhere((o) => o.id == offerId);
    } catch (e) {
      try {
        return _receivedOffers.firstWhere((o) => o.id == offerId);
      } catch (e) {
        return null;
      }
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setCreatingOffer(bool creating) {
    _isCreatingOffer = creating;
    notifyListeners();
  }

  void _setUpdatingOffer(bool updating) {
    _isUpdatingOffer = updating;
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