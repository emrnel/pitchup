import '../models/notification_model.dart';
import '../services/firestore_service.dart';

class NotificationRepository {
  final FirestoreService _firestoreService = FirestoreService();

  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    return await _firestoreService.getUserNotifications(userId);
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestoreService.markNotificationAsRead(notificationId);
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    await _firestoreService.markAllNotificationsAsRead(userId);
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    return await _firestoreService.getUnreadNotificationCount(userId);
  }

  Stream<int> unreadNotificationCountStream(String userId) {
    return _firestoreService.unreadNotificationCountStream(userId);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestoreService.deleteNotification(notificationId);
  }

  Future<void> deleteAllNotifications(String userId) async {
    await _firestoreService.deleteAllNotifications(userId);
  }
}
