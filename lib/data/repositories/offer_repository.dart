// lib/data/repositories/offer_repository.dart
import '../models/offer_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class OfferRepository {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService.instance;

  Future<List<OfferModel>> getSentOffers(String investorId) async {
    return await _firestoreService.getSentOffers(investorId);
  }

  Future<List<OfferModel>> getReceivedOffers(String entrepreneurId) async {
    return await _firestoreService.getReceivedOffers(entrepreneurId);
  }

  Future<OfferModel?> getOffer(String offerId) async {
    return await _firestoreService.getOffer(offerId);
  }

  Future<OfferModel> createOffer({
    required String videoId,
    required String entrepreneurId,
    required String investorId,
    required double amount,
    required double equityPercentage,
    String? note,
  }) async {
    final offer = OfferModel(
      id: '',
      videoId: videoId,
      entrepreneurId: entrepreneurId,
      investorId: investorId,
      amount: amount,
      equityPercentage: equityPercentage,
      note: note,
      status: OfferStatus.pending,
      createdAt: DateTime.now(),
    );

    final createdOffer = await _firestoreService.createOffer(offer);

    // Send notification to entrepreneur
    await _notificationService.sendOfferReceivedNotification(
      entrepreneurId: entrepreneurId,
      offerId: createdOffer.id,
      amount: amount,
    );

    // Update video offer count
    await _firestoreService.incrementVideoOfferCount(videoId);

    return createdOffer;
  }

  Future<void> updateOfferStatus(
    String offerId,
    OfferStatus status,
  ) async {
    await _firestoreService.updateOfferStatus(offerId, status);

    // Get offer details for notification
    final offer = await _firestoreService.getOffer(offerId);
    if (offer != null) {
      // Send notification to investor
      if (status == OfferStatus.accepted) {
        await _notificationService.sendOfferAcceptedNotification(
          investorId: offer.investorId,
          offerId: offerId,
        );
      } else if (status == OfferStatus.rejected) {
        await _notificationService.sendOfferRejectedNotification(
          investorId: offer.investorId,
          offerId: offerId,
        );
      }
    }
  }

  Future<bool> hasUserOfferedOnVideo(String userId, String videoId) async {
    return await _firestoreService.hasUserOfferedOnVideo(userId, videoId);
  }

  Future<List<OfferModel>> getVideoOffers(String videoId) async {
    return await _firestoreService.getVideoOffers(videoId);
  }
}