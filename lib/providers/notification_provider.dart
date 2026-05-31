import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';

class NotificationProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _currentUserId;

  StreamSubscription<List<NotificationModel>>?
      _notifSubscription;
  StreamSubscription<int>? _countSubscription;

  List<NotificationModel> get notifications =>
      _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasUnread => _unreadCount > 0;

  /// Call this right after user logs in
  void startListening(String userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;

    // Stream all notifications
    _notifSubscription?.cancel();
    _notifSubscription = _service
        .streamUserNotifications(userId)
        .listen((notifs) {
      _notifications = notifs;
      notifyListeners();
    });

    // Stream unread count separately for the badge
    _countSubscription?.cancel();
    _countSubscription =
        _service.streamUnreadCount(userId).listen((count) {
      _unreadCount = count;
      notifyListeners();
    });
  }

  /// Call on logout
  void stopListening() {
    _notifSubscription?.cancel();
    _countSubscription?.cancel();
    _notifications = [];
    _unreadCount = 0;
    _currentUserId = null;
    notifyListeners();
  }

  Future<void> markRead(String notificationId) async {
    await _service.markNotificationRead(notificationId);
    // Optimistic update
    final index = _notifications
        .indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] =
          _notifications[index].copyWith(isRead: true);
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    if (_currentUserId == null) return;
    await _service
        .markAllNotificationsRead(_currentUserId!);
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> deleteNotification(
      String notificationId) async {
    await _service.deleteNotification(notificationId);
    _notifications.removeWhere(
        (n) => n.id == notificationId);
    notifyListeners();
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    _countSubscription?.cancel();
    super.dispose();
  }
}
