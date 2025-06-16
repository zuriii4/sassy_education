import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final List<NotificationItem> notifications = [];
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  final ValueNotifier<List<NotificationItem>> notificationsNotifier =
  ValueNotifier<List<NotificationItem>>([]);

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    final DarwinInitializationSettings initializationSettingsMacOS =
    DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsMacOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }


  Future<void> showNotification(String title, String body, {String? payload}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'sassy_notifications_channel',
      'Sassy Notifications',
      channelDescription: 'Kanál pre notifikácie aplikácie Sassy',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
    DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }


  void addNotification({
    required String id,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) {
    final notification = NotificationItem(
      id: id,
      title: title,
      message: message,
      type: type,
      relatedId: relatedId,
      timestamp: DateTime.now(),
      isRead: false,
    );

    notifications.insert(0, notification);
    unreadCount.value++;
    notificationsNotifier.value = List.from(notifications);


    showNotification(title, message, payload: relatedId);
  }


  void markAsRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final notification = notifications[index];
      if (!notification.isRead) {
        notification.isRead = true;
        unreadCount.value--;
        notificationsNotifier.value = List.from(notifications);
      }
    }
  }


  void markAllAsRead() {
    int count = 0;
    for (final notification in notifications) {
      if (!notification.isRead) {
        notification.isRead = true;
        count++;
      }
    }

    if (count > 0) {
      unreadCount.value = 0;
      notificationsNotifier.value = List.from(notifications);
    }
  }


  void loadNotificationsFromServer(List<dynamic> serverNotifications) {
    notifications.clear();
    unreadCount.value = 0;

    for (final notification in serverNotifications) {
      final notificationItem = NotificationItem(
        id: notification['_id'],
        title: notification['title'],
        message: notification['message'],
        type: notification['type'],
        relatedId: notification['relatedId'],
        timestamp: DateTime.parse(notification['createdAt']),
        isRead: notification['isRead'],
      );

      notifications.add(notificationItem);
      if (!notificationItem.isRead) {
        unreadCount.value++;
      }
    }

    notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notificationsNotifier.value = List.from(notifications);
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type;
  final String? relatedId;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    required this.timestamp,
    this.isRead = false,
  });
}
