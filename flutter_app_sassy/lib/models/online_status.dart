import 'package:flutter/foundation.dart';

class OnlineStatusModel extends ChangeNotifier {
  static final OnlineStatusModel _instance = OnlineStatusModel._internal();
  factory OnlineStatusModel() => _instance;
  OnlineStatusModel._internal();

  final Map<String, UserStatus> _userStatuses = {};
  final List<UserStatus> _onlineStudents = [];
  
  // Pridaj ValueNotifier pre zoznam študentov
  final ValueNotifier<List<UserStatus>> studentsNotifier = 
    ValueNotifier<List<UserStatus>>([]);

  Map<String, UserStatus> get userStatuses => _userStatuses;
  List<UserStatus> get onlineStudents => _onlineStudents;

  void updateUserStatus(String userId, bool isOnline, DateTime? lastActive) {
    _userStatuses[userId] = UserStatus(
      userId: userId,
      isOnline: isOnline,
      lastActive: lastActive,
    );
    notifyListeners();
  }

  void setUserOnline(String userId) {
    final now = DateTime.now();
    _userStatuses[userId] = UserStatus(
      userId: userId,
      isOnline: true,
      lastActive: now,
    );
    notifyListeners();
  }

  void setUserOffline(String userId) {
    final status = _userStatuses[userId];
    if (status != null) {
      _userStatuses[userId] = UserStatus(
        userId: userId,
        isOnline: false,
        lastActive: status.lastActive,
      );
      notifyListeners();
    }
  }

  void updateOnlineStudents(List<UserStatus> students) {
    _onlineStudents.clear();
    _onlineStudents.addAll(students);

    for (final student in students) {
      _userStatuses[student.userId] = student;
    }
    
    // Aktualizuj studentsNotifier
    studentsNotifier.value = List.from(_onlineStudents);
    
    notifyListeners();
  }

  UserStatus? getUserStatus(String userId) {
    return _userStatuses[userId];
  }

  bool isUserOnline(String userId) {
    final status = _userStatuses[userId];
    return status?.isOnline ?? false;
  }

  String getLastActiveText(String userId) {
    final status = _userStatuses[userId];

    if (status == null) {
      return 'Neznámy stav';
    }

    if (status.isOnline) {
      return 'Online';
    }

    if (status.lastActive == null) {
      return 'Offline';
    }

    final now = DateTime.now();
    final difference = now.difference(status.lastActive!);

    if (difference.inMinutes < 1) {
      return 'Pred chvíľou';
    } else if (difference.inHours < 1) {
      return 'Pred ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Pred ${difference.inHours} h';
    } else if (difference.inDays < 30) {
      return 'Pred ${difference.inDays} dňami';
    } else {
      return status.lastActive!.toString().substring(0, 10);
    }
  }
}

class UserStatus {
  final String userId;
  final bool isOnline;
  final DateTime? lastActive;
  String? name;
  String? studentId;

  UserStatus({
    required this.userId,
    required this.isOnline,
    this.lastActive,
    this.name,
    this.studentId,
  });

  factory UserStatus.fromJson(Map<String, dynamic> json) {
    return UserStatus(
      userId: json['userId'],
      isOnline: json['isOnline'],
      lastActive: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'])
          : null,
      name: json['name'],
      studentId: json['studentId'],
    );
  }
}