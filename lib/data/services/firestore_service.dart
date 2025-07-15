import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/video_model.dart';
import '../models/offer_model.dart';
import '../models/notification_model.dart';
import '../models/message_model.dart';
import '../../core/constants/firebase_constants.dart';
import 'firebase_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // User operations
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.id)
          .set(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.id)
          .update({
        ...user.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  Future<void> updateUserRole(String userId, UserRole role) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({
        'role': role == UserRole.investor ? 'investor' : 'entrepreneur',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  Future<void> updateUserProfilePicture(String userId, String imageUrl) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({
        'profilePicture': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update profile picture: $e');
    }
  }

  Future<void> updateUserCompanyInfo(String userId, CompanyInfo company) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({
        'company': company.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update company info: $e');
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  Future<List<UserModel>> getInvestors({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .where('role', isEqualTo: 'investor')
          .where('isApproved', isEqualTo: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get investors: $e');
    }
  }

  Future<List<UserModel>> getEntrepreneurs({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .where('role', isEqualTo: 'entrepreneur')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get entrepreneurs: $e');
    }
  }

  // Video operations
  Future<List<VideoModel>> getApprovedVideos({
    int limit = 20,
    String? lastVideoId,
  }) async {
    try {
      Query query = _firestore
          .collection(FirebaseConstants.videosCollection)
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true);

      if (lastVideoId != null) {
        final lastDoc = await _firestore
            .collection(FirebaseConstants.videosCollection)
            .doc(lastVideoId)
            .get();

        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs.map((doc) => VideoModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get approved videos: $e');
    }
  }

  Future<List<VideoModel>> getUserVideos(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.videosCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => VideoModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get user videos: $e');
    }
  }

  Future<VideoModel?> getVideo(String videoId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.videosCollection)
          .doc(videoId)
          .get();

      if (doc.exists) {
        return VideoModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get video: $e');
    }
  }

  Future<VideoModel> createVideo(VideoModel video) async {
    try {
      final docRef = await _firestore
          .collection(FirebaseConstants.videosCollection)
          .add(video.toFirestore());

      final doc = await docRef.get();
      return VideoModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to create video: $e');
    }
  }

  Future<void> incrementVideoViewCount(String videoId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.videosCollection)
          .doc(videoId)
          .update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to increment view count: $e');
    }
  }

  Future<void> incrementVideoOfferCount(String videoId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.videosCollection)
          .doc(videoId)
          .update({
        'offerCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to increment offer count: $e');
    }
  }

  Future<void> toggleVideoLike(String videoId, String userId) async {
    try {
      final likeDoc = await _firestore
          .collection(FirebaseConstants.videosCollection)
          .doc(videoId)
          .collection('likes')
          .doc(userId)
          .get();

      if (likeDoc.exists) {
        // Unlike
        await likeDoc.reference.delete();
        await _firestore
            .collection(FirebaseConstants.videosCollection)
            .doc(videoId)
            .update({
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        // Like
        await _firestore
            .collection(FirebaseConstants.videosCollection)
            .doc(videoId)
            .collection('likes')
            .doc(userId)
            .set({
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _firestore
            .collection(FirebaseConstants.videosCollection)
            .doc(videoId)
            .update({
          'likeCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  Future<List<VideoModel>> searchVideos(String query) async {
    try {
      // Simple search by title
      final snapshot = await _firestore
          .collection(FirebaseConstants.videosCollection)
          .where('status', isEqualTo: 'approved')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: query + 'z')
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => VideoModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to search videos: $e');
    }
  }

  Future<List<VideoModel>> getVideosBySector(String sector) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.videosCollection)
          .where('status', isEqualTo: 'approved')
          .where('sector', isEqualTo: sector)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => VideoModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get videos by sector: $e');
    }
  }

  Future<void> deleteVideo(String videoId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.videosCollection)
          .doc(videoId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete video: $e');
    }
  }

  // Offer operations
  Future<List<OfferModel>> getSentOffers(String investorId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.offersCollection)
          .where('investorId', isEqualTo: investorId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => OfferModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get sent offers: $e');
    }
  }

  Future<List<OfferModel>> getReceivedOffers(String entrepreneurId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.offersCollection)
          .where('entrepreneurId', isEqualTo: entrepreneurId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => OfferModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get received offers: $e');
    }
  }

  Future<OfferModel?> getOffer(String offerId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.offersCollection)
          .doc(offerId)
          .get();

      if (doc.exists) {
        return OfferModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get offer: $e');
    }
  }

  Future<OfferModel> createOffer(OfferModel offer) async {
    try {
      final docRef = await _firestore
          .collection(FirebaseConstants.offersCollection)
          .add(offer.toFirestore());

      final doc = await docRef.get();
      return OfferModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to create offer: $e');
    }
  }

  Future<void> updateOfferStatus(String offerId, OfferStatus status) async {
    try {
      await _firestore
          .collection(FirebaseConstants.offersCollection)
          .doc(offerId)
          .update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update offer status: $e');
    }
  }

  Future<bool> hasUserOfferedOnVideo(String userId, String videoId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.offersCollection)
          .where('investorId', isEqualTo: userId)
          .where('videoId', isEqualTo: videoId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check user offer: $e');
    }
  }

  Future<List<OfferModel>> getVideoOffers(String videoId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.offersCollection)
          .where('videoId', isEqualTo: videoId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => OfferModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get video offers: $e');
    }
  }

  // Notification operations
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }

  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .add(notification.toFirestore());
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get unread notification count: $e');
    }
  }

  Stream<int> unreadNotificationCountStream(String userId) {
    return _firestore
        .collection(FirebaseConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  Future<void> deleteAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(FirebaseConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  // Message operations
  Future<List<MessageModel>> getOfferMessages(String offerId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.messagesCollection)
          .where('offerId', isEqualTo: offerId)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  Future<MessageModel> createMessage(MessageModel message) async {
    try {
      final docRef = await _firestore
          .collection(FirebaseConstants.messagesCollection)
          .add(message.toFirestore());

      final doc = await docRef.get();
      return MessageModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to create message: $e');
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.messagesCollection)
          .doc(messageId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  Stream<List<MessageModel>> offerMessagesStream(String offerId) {
    return _firestore
        .collection(FirebaseConstants.messagesCollection)
        .where('offerId', isEqualTo: offerId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }
}
