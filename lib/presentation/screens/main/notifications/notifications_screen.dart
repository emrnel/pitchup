// lib/presentation/screens/main/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/repositories/notification_repository.dart';
import '../../../../data/models/notification_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/loading_indicator.dart';
import '../../../widgets/common/error_widget.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../../../widgets/cards/notification_card.dart';
import '../../../../core/services/navigation_service.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final NotificationRepository _notificationRepository =
      NotificationRepository();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _notifications =
          await _notificationRepository.getUserNotifications(user.id);
    } catch (e) {
      _error = 'Bildirimler yüklenirken hata oluştu: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Bildirimler',
                    style: AppTypography.h2,
                  ),
                  const Spacer(),
                  if (_notifications.any((n) => !n.isRead))
                    TextButton(
                      onPressed: _markAllAsRead,
                      child: Text(
                        'Tümünü Okundu İşaretle',
                        style: AppTypography.bodySmallText.copyWith(
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadNotifications,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _notifications.isEmpty) {
      return const Center(child: LoadingIndicator());
    }

    if (_error != null && _notifications.isEmpty) {
      return AppErrorWidget(
        title: 'Bildirimler Yüklenemedi',
        message: _error!,
        buttonText: 'Tekrar Dene',
        onRetry: _loadNotifications,
      );
    }

    if (_notifications.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.notifications_outlined,
        title: 'Henüz Bildirim Yok',
        message: 'Yeni bildirimleriniz burada görünecek',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return NotificationCard(
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
            onDismiss: () => _dismissNotification(notification),
          );
        },
      ),
    );
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    if (!notification.isRead) {
      await _notificationRepository.markNotificationAsRead(notification.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.copyWith(isRead: true);
        }
      });
    }

    final data = notification.data;
    if (data != null) {
      switch (notification.type) {
        case NotificationType.offerReceived:
        case NotificationType.offerAccepted:
        case NotificationType.offerRejected:
          final offerId = data['offerId'];
          if (offerId != null) {
            NavigationService.toOfferDetail(context, offerId);
          }
          break;
        case NotificationType.newMessage:
          final offerId = data['offerId'];
          if (offerId != null) {
            NavigationService.toMessages(context, offerId);
          }
          break;
      }
    }
  }

  Future<void> _dismissNotification(NotificationModel notification) async {
    try {
      await _notificationRepository.deleteNotification(notification.id);
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
      });
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bildirim silinirken hata oluştu'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) return;

    try {
      await _notificationRepository.markAllNotificationsAsRead(user.id);
      setState(() {
        _notifications =
            _notifications.map((n) => n.copyWith(isRead: true)).toList();
      });
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bildirimler güncellenirken hata oluştu'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }
}