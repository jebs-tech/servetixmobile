// lib/models/notification_models.dart

class NotificationItem {
  final int id;
  final String message;
  final String createdAt;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      message: json['message'],
      createdAt: json['created_at'],
      isRead: json['is_read'] ?? false,
    );
  }
}

class NotificationUnreadCount {
  final int unreadCount;
  final List<NotificationItem> latest;

  NotificationUnreadCount({
    required this.unreadCount,
    required this.latest,
  });

  factory NotificationUnreadCount.fromJson(Map<String, dynamic> json) {
    List<NotificationItem> latestList = [];
    if (json['latest'] != null) {
      latestList = (json['latest'] as List).map((item) => NotificationItem.fromJson(item)).toList();
    }

    return NotificationUnreadCount(
      unreadCount: json['unread_count'] ?? 0,
      latest: latestList,
    );
  }
}

