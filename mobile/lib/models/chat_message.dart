class ChatMessage {
  final String content;
  final int senderId;
  final String senderName;
  final int? teamId;
  final String type;
  final DateTime timestamp;
  final int? recipientId;
  final String? recipientRole;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? attachmentContentType;
  final int? attachmentSize;

  ChatMessage({
    required this.content,
    required this.senderId,
    required this.senderName,
    this.teamId,
    required this.type,
    required this.timestamp,
    this.recipientId,
    this.recipientRole,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentContentType,
    this.attachmentSize,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawTeamId = json['teamId'];
    int? teamId;
    if (rawTeamId == null) {
      teamId = null;
    } else if (rawTeamId is int) {
      teamId = rawTeamId > 0 ? rawTeamId : null;
    } else {
      final parsed = int.tryParse('$rawTeamId');
      teamId = (parsed != null && parsed > 0) ? parsed : null;
    }

    return ChatMessage(
      content: json['content'] ?? '',
      senderId: json['senderId'] ?? 0,
      senderName: json['senderName'] ?? 'Unknown',
      teamId: teamId,
      type: json['type']?.toString() ?? 'TEXT',
      recipientId: json['recipientId'] is int ? json['recipientId'] : int.tryParse('${json['recipientId']}'),
      recipientRole: json['recipientRole'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      attachmentUrl: json['attachmentUrl'] as String?,
      attachmentName: json['attachmentName'] as String?,
      attachmentContentType: json['attachmentContentType'] as String?,
      attachmentSize: json['attachmentSize'] is int ? json['attachmentSize'] : int.tryParse('${json['attachmentSize']}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'senderId': senderId,
      'senderName': senderName,
      if (teamId != null && teamId! > 0) 'teamId': teamId,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      if (recipientId != null) 'recipientId': recipientId,
      if (recipientRole != null) 'recipientRole': recipientRole,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      if (attachmentName != null) 'attachmentName': attachmentName,
      if (attachmentContentType != null) 'attachmentContentType': attachmentContentType,
      if (attachmentSize != null) 'attachmentSize': attachmentSize,
    };
  }
}
