import 'package:flutter/material.dart';
import 'package:sassy/services/api_service.dart';
import 'dart:async';
import 'package:sassy/services/notification_service.dart';

class StudentNotificationPage extends StatefulWidget {
  const StudentNotificationPage({Key? key}) : super(key: key);

  @override
  State<StudentNotificationPage> createState() => _StudentNotificationPageState();
}

class _StudentNotificationPageState extends State<StudentNotificationPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showUnreadOnly = false;
  Timer? _pollingTimer;
  int _currentNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    NotificationService().notificationsNotifier.addListener(_onNotificationsChanged);
    
    _pollingTimer = Timer.periodic(const Duration(seconds: 6), (_) => _checkForNewNotifications());
    
  }

  @override
  void dispose() {
    NotificationService().notificationsNotifier.removeListener(_onNotificationsChanged);
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkForNewNotifications() async {
    try {
      final notifications = await _apiService.getNotifications(unreadOnly: _showUnreadOnly);
      
      if (notifications.length != _currentNotificationCount || 
          (notifications.isNotEmpty && _notifications.isNotEmpty && 
           notifications[0]['_id'] != _notifications[0]['_id'])) {
        if (mounted) {
          _loadNotifications();
        }
      } else {
        print("No new notifications found during polling");
      }
    } catch (e) {
      print("Error during notification polling: $e");
    }
  }

  void _onNotificationsChanged() {
    if (mounted) {
      setState(() {
        _notifications = List.from(NotificationService().notifications.map((item) => {
          '_id': item.id,
          'title': item.title,
          'message': item.message,
          'type': item.type,
          'relatedId': item.relatedId,
          'isRead': item.isRead,
          'createdAt': item.timestamp.toIso8601String(),
        }));
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final notifications = await _apiService.getNotifications(unreadOnly: _showUnreadOnly);
      _currentNotificationCount = notifications.length;
      
      NotificationService().loadNotificationsFromServer(notifications);
      
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
      print('Error loading notifications: $e');
    }
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return 'Neznámy dátum';
    
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return 'Pred ${difference.inMinutes} minútami';
        }
        return 'Pred ${difference.inHours} hodinami';
      } else if (difference.inDays < 7) {
        return 'Pred ${difference.inDays} dňami';
      } else {
        return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'Neznámy dátum';
    }
  }

  Future<void> _handleRefresh() async {
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje notifikácie', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF5D69BE),
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(
              _showUnreadOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showUnreadOnly = !_showUnreadOnly;
              });
              _loadNotifications();
            },
            tooltip: _showUnreadOnly ? 'Zobraziť všetky' : 'Len neprečítané',
          ),
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.white),
            onPressed: () async {
              try {
                final success = await _apiService.markAllNotificationsAsRead();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Všetky oznámenia označené ako prečítané')),
                  );
                  _loadNotifications();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Chyba: ${e.toString()}')),
                );
              }
            },
            tooltip: 'Označiť všetky ako prečítané',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadNotifications,
            tooltip: 'Obnoviť',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorView()
              : _buildNotificationList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Nepodarilo sa načítať notifikácie',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Skúsiť znova'),
            onPressed: _loadNotifications,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5D69BE),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _showUnreadOnly
                  ? 'Nemáš žiadne neprečítané notifikácie'
                  : 'Nemáš žiadne notifikácie',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (_showUnreadOnly) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Zobraziť všetky notifikácie'),
                onPressed: () {
                  setState(() {
                    _showUnreadOnly = false;
                  });
                  _loadNotifications();
                },
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          final bool isRead = notification['isRead'] ?? false;
          final String type = notification['type'] ?? 'system';
          final content = notification['message'] ?? '';
          
          IconData iconData;
          Color iconColor;
          Color cardColor = isRead ? Colors.white : const Color(0xFFE3F2FD);
          
          switch (type) {
            case 'material_assigned':
              iconData = Icons.assignment;
              iconColor = Colors.blue;
              break;
            case 'material_completed':
              iconData = Icons.task_alt;
              iconColor = Colors.green;
              break;
            case 'group_added':
              iconData = Icons.group_add;
              iconColor = Colors.purple;
              break;
            case 'quiz_feedback':
              iconData = Icons.quiz;
              iconColor = Colors.orange;
              break;
            default:
              iconData = Icons.notifications;
              iconColor = const Color(0xFF5D69BE);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isRead ? Colors.transparent : Colors.blue.shade200,
                  width: 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  if (!isRead) {
                    try {
                      await _apiService.markNotificationAsRead(notification['_id']);
                      _loadNotifications();
                    } catch (e) {
                      print('Error marking notification as read: $e');
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon 
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          iconData,
                          color: iconColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification['title'] ?? 'Notifikácia',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (content.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                content,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(notification['createdAt']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      if (!isRead)
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          color: Colors.blue,
                          onPressed: () async {
                            try {
                              await _apiService.markNotificationAsRead(notification['_id']);
                              _loadNotifications();
                            } catch (e) {
                              print('Error marking notification as read: $e');
                            }
                          },
                          tooltip: 'Označiť ako prečítané',
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}