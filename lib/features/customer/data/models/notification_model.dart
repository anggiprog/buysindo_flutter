class NotificationModel {
  final int id;
  final String judul;
  final String message;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.judul,
    required this.message,
    required this.imageUrl,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? (json['id'] is int ? json['id'] as int : 0),
      judul: json['judul']?.toString() ?? json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      isRead: (json['is_read']?.toString() == '1') || (json['is_read'] == true),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'judul': judul,
        'message': message,
        'image_url': imageUrl,
        'is_read': isRead ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };
}
