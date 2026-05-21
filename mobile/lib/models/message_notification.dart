class MessageNotificationItem {
  final int id;
  final String type;
  final String title;
  final String body;
  final int? senderId;
  final String? senderName;
  final int? teamId;
  final int? messageId;
  final bool read;
  final DateTime createdAt;

  MessageNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.senderId,
    this.senderName,
    this.teamId,
    this.messageId,
    required this.read,
    required this.createdAt,
  });

  factory MessageNotificationItem.fromJson(Map<String, dynamic> json) {
    return MessageNotificationItem(
      id: json['id'] is int ? json['id'] : int.parse('${json['id']}'),
      type: json['type'] ?? 'TEAM',
      title: json['title'] ?? 'Notification',
      body: json['body'] ?? '',
      senderId: json['senderId'] is int ? json['senderId'] : int.tryParse('${json['senderId']}'),
      senderName: json['senderName'] as String?,
      teamId: json['teamId'] is int ? json['teamId'] : int.tryParse('${json['teamId']}'),
      messageId: json['messageId'] is int ? json['messageId'] : int.tryParse('${json['messageId']}'),
      read: json['read'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
