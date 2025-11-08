import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<NotificationItem> _notifications = [];
  final List<NotificationListener> _listeners = [];

  // Initialize notification service
  Future<void> initialize() async {
    await _loadNotifications();
  }

  // Add notification listener
  void addListener(NotificationListener listener) {
    _listeners.add(listener);
  }

  // Remove notification listener
  void removeListener(NotificationListener listener) {
    _listeners.remove(listener);
  }

  // Notify all listeners
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener.onNotificationsChanged(_notifications);
    }
  }

  // Create a new notification
  Future<void> createNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? action,
    Map<String, dynamic>? data,
    DateTime? scheduledFor,
  }) async {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      action: action,
      data: data ?? {},
      createdAt: DateTime.now(),
      scheduledFor: scheduledFor,
      isRead: false,
    );

    _notifications.insert(0, notification);
    await _saveNotifications();
    _notifyListeners();
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
      _notifyListeners();
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    await _saveNotifications();
    _notifyListeners();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
    _notifyListeners();
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    await _saveNotifications();
    _notifyListeners();
  }

  // Get all notifications
  List<NotificationItem> getNotifications() {
    return List.from(_notifications);
  }

  // Get unread notifications
  List<NotificationItem> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  // Get notification count
  int getNotificationCount() {
    return _notifications.length;
  }

  // Get unread count
  int getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

  // Get notifications by type
  List<NotificationItem> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Get recent notifications
  List<NotificationItem> getRecentNotifications({int limit = 10}) {
    return _notifications.take(limit).toList();
  }

  // Create system notifications
  Future<void> createSystemNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
  }) async {
    await createNotification(
      title: title,
      message: message,
      type: type,
    );
  }

  // Create customer notification
  Future<void> createCustomerNotification({
    required String customerName,
    required String message,
    NotificationType type = NotificationType.info,
  }) async {
    await createNotification(
      title: 'Customer: $customerName',
      message: message,
      type: type,
    );
  }

  // Create invoice notification
  Future<void> createInvoiceNotification({
    required String invoiceNumber,
    required String message,
    NotificationType type = NotificationType.info,
  }) async {
    await createNotification(
      title: 'Invoice: $invoiceNumber',
      message: message,
      type: type,
    );
  }

  // Create payment notification
  Future<void> createPaymentNotification({
    required String customerName,
    required double amount,
    NotificationType type = NotificationType.success,
  }) async {
    await createNotification(
      title: 'Payment Received',
      message: 'Payment of ${amount.toStringAsFixed(0)} UGX received from $customerName',
      type: type,
    );
  }

  // Create reminder notification
  Future<void> createReminderNotification({
    required String customerName,
    required String message,
    DateTime? scheduledFor,
  }) async {
    await createNotification(
      title: 'Reminder: $customerName',
      message: message,
      type: NotificationType.warning,
      scheduledFor: scheduledFor,
    );
  }

  // Create overdue notification
  Future<void> createOverdueNotification({
    required String customerName,
    required String invoiceNumber,
    required double amount,
  }) async {
    await createNotification(
      title: 'Overdue Payment',
      message: 'Invoice $invoiceNumber from $customerName is overdue (${amount.toStringAsFixed(0)} UGX)',
      type: NotificationType.error,
    );
  }

  // Load notifications from storage
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('notifications');
      if (notificationsJson != null) {
        final List<dynamic> notificationsList = jsonDecode(notificationsJson);
        _notifications.clear();
        for (final notificationData in notificationsList) {
          _notifications.add(NotificationItem.fromJson(notificationData));
        }
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  // Save notifications to storage
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = jsonEncode(
        _notifications.map((n) => n.toJson()).toList(),
      );
      await prefs.setString('notifications', notificationsJson);
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  // Clean old notifications
  Future<void> cleanOldNotifications({int daysToKeep = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    _notifications.removeWhere((n) => n.createdAt.isBefore(cutoffDate));
    await _saveNotifications();
    _notifyListeners();
  }
}

// Notification item data class
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String? action;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.action,
    required this.data,
    required this.createdAt,
    this.scheduledFor,
    required this.isRead,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    String? action,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? scheduledFor,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      action: action ?? this.action,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString(),
      'action': action,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'scheduledFor': scheduledFor?.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => NotificationType.info,
      ),
      action: json['action'],
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      scheduledFor: json['scheduledFor'] != null 
          ? DateTime.parse(json['scheduledFor'])
          : null,
      isRead: json['isRead'] ?? false,
    );
  }
}

// Notification type enum
enum NotificationType {
  info,
  success,
  warning,
  error,
  reminder,
  payment,
  invoice,
  customer,
}

// Notification listener interface
abstract class NotificationListener {
  void onNotificationsChanged(List<NotificationItem> notifications);
}
