class ChatMessageModel {
  final int senderId;
  final int receiverId;
  final String message;
  final String? timestamp;

  ChatMessageModel({
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.timestamp,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      senderId: json['sender_id'] is int
          ? json['sender_id']
          : int.tryParse(json['sender_id'].toString()) ?? 0,
      receiverId: json['receiver_id'] is int
          ? json['receiver_id']
          : int.tryParse(json['receiver_id'].toString()) ?? 0,
      message: json['message'] ?? '',
      timestamp: json['timestamp']?.toString(),
    );
  }
}
