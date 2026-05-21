import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../config/api_config.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  int? _connectedTeamId;
  
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isConnected => _chatService.isConnected;
  int? get connectedTeamId => _connectedTeamId;

  void connect(int teamId, int userId, String userName) async {
    if (_connectedTeamId == teamId && _chatService.isConnected) {
      return;
    }

    disconnect(clearMessages: false);
    _connectedTeamId = teamId;

    final wsUrl = ApiConfig.webSocketUrl;

    _chatService.connect(
      url: wsUrl,
      onConnect: (frame) {
        // Subscribe to team topic
        _chatService.subscribe('/topic/team/$teamId', (frame) {
          if (frame.body != null) {
            final messageJson = json.decode(frame.body!);
            final message = ChatMessage.fromJson(messageJson);
            _addMessage(message);
          }
        });

        // Subscribe to private inbox for direct messages
        _chatService.subscribe('/topic/user/$userId', (frame) {
          if (frame.body != null) {
            final messageJson = json.decode(frame.body!);
            final message = ChatMessage.fromJson(messageJson);
            _addMessage(message);
          }
        });
        
        // Notify join (optional)
        // _chatService.send('/app/chat.addUser', ...);
        notifyListeners();
      },
      onWebSocketError: (error) {
        print('WebSocket Error: $error');
        notifyListeners();
      },
    );
  }

  Future<void> loadHistory(int teamId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.chatHistory}/$teamId'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _messages = _dedupeMessages(
          data.map((json) => ChatMessage.fromJson(json)).toList(),
        );
      } else {
        print('Error loading history: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void sendMessage(String content, int teamId, int senderId, String senderName) {
    if (content.trim().isEmpty) return;

    final message = ChatMessage(
      content: content,
      senderId: senderId,
      senderName: senderName,
      teamId: teamId,
      type: 'TEXT',
      timestamp: DateTime.now(),
    );

    _chatService.send('/app/chat.sendMessage', message.toJson());
  }

  void sendPrivateMessage({
    required String content,
    required int teamId,
    required int senderId,
    required String senderName,
    required int recipientId,
    String? attachmentUrl,
    String? attachmentName,
    String? attachmentContentType,
    int? attachmentSize,
  }) {
    final message = ChatMessage(
      content: content,
      senderId: senderId,
      senderName: senderName,
      teamId: teamId,
      type: 'TEXT',
      timestamp: DateTime.now(),
      recipientId: recipientId,
      attachmentUrl: attachmentUrl,
      attachmentName: attachmentName,
      attachmentContentType: attachmentContentType,
      attachmentSize: attachmentSize,
    );
    _chatService.send('/app/chat.sendMessage', message.toJson());
  }

  Future<Map<String, dynamic>?> uploadAttachment({
    required int teamId,
    required PlatformFile file,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.apiBaseUrl}/chat/attachments');
      final request = http.MultipartRequest('POST', uri);
      request.fields['teamId'] = teamId.toString();

      final headers = await ApiService.getHeaders();
      // MultipartRequest manages content-type; keep auth headers only.
      if (headers['Authorization'] != null) {
        request.headers['Authorization'] = headers['Authorization']!;
      }

      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name),
        );
      } else if (file.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', file.path!, filename: file.name),
        );
      } else {
        return null;
      }

      final resp = await request.send();
      final body = await resp.stream.bytesToString();
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return json.decode(body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('uploadAttachment error: $e');
      return null;
    }
  }

  void _addMessage(ChatMessage message) {
    final exists = _messages.any(
      (m) =>
          m.senderId == message.senderId &&
          m.teamId == message.teamId &&
          m.content == message.content &&
          m.timestamp == message.timestamp,
    );
    if (!exists) {
      _messages = [..._messages, message];
    }
    notifyListeners();
  }

  List<ChatMessage> _dedupeMessages(List<ChatMessage> input) {
    final seen = <String>{};
    final result = <ChatMessage>[];
    for (final message in input) {
      final key =
          '${message.senderId}|${message.teamId ?? 0}|${message.recipientId ?? 0}|${message.timestamp.toIso8601String()}|${message.content}|${message.attachmentUrl ?? ''}';
      if (seen.add(key)) {
        result.add(message);
      }
    }
    return result;
  }

  void disconnect({bool clearMessages = true}) {
    _chatService.disconnect();
    _connectedTeamId = null;
    if (clearMessages) {
      _messages = [];
    }
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
