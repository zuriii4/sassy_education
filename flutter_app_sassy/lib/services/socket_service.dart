import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:sassy/services/notification_service.dart';
import '../models/online_status.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  late IO.Socket socket;
  bool isConnected = false;

  final NotificationService _notificationService = NotificationService();
  final OnlineStatusModel _onlineStatusModel = OnlineStatusModel();


  void initialize(String serverUrl, String userId, String userRole) {
    socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setQuery({'userId': userId, 'role': userRole})
            .build()
    );


    socket.onConnect((_) {
      // print('Socket pripojený: ${socket.id}');
      isConnected = true;

      authenticate(userId, userRole);
    });

    socket.onDisconnect((_) {
      // print('Socket odpojený');
      isConnected = false;
    });

    socket.onConnectError((data) {
      // print('Chyba pripojenia socketu: $data');
      isConnected = false;
    });

    // Počúvanie udalostí

    // Notifikácie
    socket.on('notification', (data) {
      // print('Prijatá notifikácia: $data');
      _notificationService.addNotification(
        id: data['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: data['title'] ?? 'Nová notifikácia',
        message: data['message'] ?? '',
        type: data['type'] ?? 'general',
        relatedId: data['relatedId'],
      );
    });

    // Online stavy používateľov
    socket.on('userStatusChanged', (data) {
      // print('Zmena stavu používateľa: $data');
      if (data != null && data['userId'] != null) {
        _onlineStatusModel.updateUserStatus(
            data['userId'],
            data['isOnline'] ?? false,
            data['lastActive'] != null ? DateTime.parse(data['lastActive']) : null
        );
      }
    });

    // Zoznam online študentov
    socket.on('onlineUsers', (data) {
      // print('Zoznam online používateľov: $data');
      if (data is List) {
        final onlineUsers = data.map((user) => UserStatus.fromJson(user)).toList();
        _onlineStatusModel.updateOnlineStudents(onlineUsers);
      }
    });

    // Nový materiál
    socket.on('materialAssigned', (data) {
      // print('Priradený nový materiál: $data');
      _notificationService.addNotification(
        id: data['notificationId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Nový materiál',
        message: 'Bol vám priradený nový učebný materiál: ${data['materialName'] ?? 'materiál'}',
        type: 'material_assigned',
        relatedId: data['materialId'],
      );
    });

    // Dokončený materiál
    socket.on('materialCompleted', (data) {
      print('Dokončený materiál: $data');
      if (userRole == 'teacher') {
        _notificationService.addNotification(
          id: data['notificationId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Dokončený materiál',
          message: '${data['studentName'] ?? 'Študent'} dokončil materiál: ${data['materialName'] ?? 'materiál'}',
          type: 'material_completed',
          relatedId: data['materialId'],
        );
      }
    });
  }

  // Autentifikácia používateľa
  void authenticate(String userId, String userRole) {
    if (isConnected) {
      socket.emit('authenticate', {
        'userId': userId,
        'role': userRole
      });
    }
  }

  // Zaznamenanie aktivity používateľa
  void recordActivity(String userId) {
    if (isConnected) {
      socket.emit('activity', {'userId': userId});
    }
  }

  // Požiadanie o zoznam online študentov
  void requestOnlineStudents() {
    if (isConnected) {
      socket.emit('getOnlineStudents');
    }
  }

  // Označenie notifikácie ako prečítanej
  void markNotificationRead(String notificationId) {
    if (isConnected) {
      socket.emit('markNotificationRead', {'notificationId': notificationId});
      _notificationService.markAsRead(notificationId);
    }
  }

  // Označenie všetkých notifikácií ako prečítaných
  void markAllNotificationsRead() {
    if (isConnected) {
      socket.emit('markAllNotificationsRead');
      _notificationService.markAllAsRead();
    }
  }

  // Odpojenie socketu
  void disconnect() {
    socket.disconnect();
    isConnected = false;
  }
}
