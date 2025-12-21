// lib/notifications/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:servetix/models/notification_models.dart';
import 'dart:convert';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  Future<List<NotificationItem>>? _notificationsFuture;
  int _unreadCount = 0;

  // Warna sesuai Django
  final Color _darkBlue = const Color(0xFF1e2c4f); // brand-dark-blue
  final Color _gold = const Color(0xFFf6ca50); // brand-gold
  final Color _cream = const Color(0xFFfdf4d9); // cream background
  final Color _creamTop = const Color(0xFFFFF7D1); // cream top gradient

  @override
  void initState() {
    super.initState();
    final request = Provider.of<CookieRequest>(context, listen: false);
    _loadNotifications(request);
    _loadUnreadCount(request);
  }

  void _loadNotifications(CookieRequest request) {
    setState(() {
      _notificationsFuture = fetchNotifications(request);
    });
  }

  void _loadUnreadCount(CookieRequest request) async {
    try {
      final response = await request.get("http://127.0.0.1:8000/notifications/api/notifications/unread_count/");
      if (response['success'] == true) {
        setState(() {
          _unreadCount = response['unread_count'] ?? 0;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<List<NotificationItem>> fetchNotifications(CookieRequest request) async {
    final response = await request.get("http://127.0.0.1:8000/notifications/api/notifications/");
    if (response['success'] == true) {
      List<dynamic> list = response['notifications'];
      return list.map((d) => NotificationItem.fromJson(d)).toList();
    } else {
      throw Exception('Gagal load notifications');
    }
  }

  Future<void> _markAsRead(CookieRequest request, int notificationId) async {
    try {
      final response = await request.postJson(
        "http://127.0.0.1:8000/notifications/api/notifications/$notificationId/mark_read/",
        jsonEncode({}),
      );

      if (response['success'] == true) {
        _loadNotifications(request);
        _loadUnreadCount(request);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _markAllAsRead(CookieRequest request) async {
    try {
      final response = await request.postJson(
        "http://127.0.0.1:8000/notifications/api/notifications/mark_all_read/",
        jsonEncode({}),
      );

      if (response['success'] == true) {
        _loadNotifications(request);
        _loadUnreadCount(request);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Semua notifikasi ditandai sebagai sudah dibaca"), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return "${date.day}/${date.month}/${date.year}";
      } else if (difference.inDays > 0) {
        return "${difference.inDays} hari yang lalu";
      } else if (difference.inHours > 0) {
        return "${difference.inHours} jam yang lalu";
      } else if (difference.inMinutes > 0) {
        return "${difference.inMinutes} menit yang lalu";
      } else {
        return "Baru saja";
      }
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: _creamTop,
      appBar: AppBar(
        backgroundColor: _darkBlue,
        title: Row(
          children: [
            Icon(Icons.notifications, color: _gold, size: 28),
            const SizedBox(width: 12),
            const Text("Notifikasi", style: TextStyle(color: Color(0xFFfdf4d9), fontWeight: FontWeight.bold)),
          ],
        ),
        iconTheme: const IconThemeData(color: Color(0xFFfdf4d9)),
        actions: [
          if (_unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: () => _markAllAsRead(request),
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text("Tandai Semua"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[500],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
        ],
      ),
      body: FutureBuilder<List<NotificationItem>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("Tidak ada notifikasi", style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              _loadNotifications(request);
              _loadUnreadCount(request);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _cream,
                    borderRadius: BorderRadius.circular(16),
                    border: Border(
                      left: BorderSide(
                        color: notification.isRead ? Colors.grey[300]! : _gold,
                        width: 4,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      if (!notification.isRead) {
                        _markAsRead(request, notification.id);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!notification.isRead)
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(top: 6, right: 12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _gold,
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.message,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                                    color: _darkBlue,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatDate(notification.createdAt),
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

