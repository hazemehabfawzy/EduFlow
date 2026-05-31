import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final String? imageUrl;
  final String? courseId;
  final bool isRead;
  final DateTime createdAt;
  final String receiverRole;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.courseId,
    this.isRead = false,
    required this.createdAt,
    required this.receiverRole,
  });

  factory NotificationModel.fromMap(
      Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      type: map['type'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      courseId: map['courseId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.now(),
      receiverRole:
          map['receiverRole'] as String? ?? 'student',
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'type': type,
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'courseId': courseId,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
        'receiverRole': receiverRole,
      };

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      imageUrl: imageUrl,
      courseId: courseId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      receiverRole: receiverRole,
    );
  }

  // Icon per notification type
  String get emoji {
    switch (type) {
      case 'new_course': return '📚';
      case 'new_enrollment': return '🎉';
      case 'course_complete': return '🏆';
      case 'new_rating': return '⭐';
      case 'new_lesson': return '🎬';
      default: return '🔔';
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
