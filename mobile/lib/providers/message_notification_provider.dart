import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/message_notification.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';

class MessageNotificationProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  List<MessageNotificationItem> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  MessageNotificationItem? _latestIncoming;
  int? _connectedUserId;

  List<MessageNotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  MessageNotificationItem? get latestIncoming => _latestIncoming;

  Future<void> initialize(int userId) async {
    if (_connectedUserId == userId && _chatService.isConnected) {
      await refresh();
      return;
    }
    _connectedUserId = userId;
    await refresh();
    _connectWebSocket(userId);
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      final headers = await ApiService.getHeaders();
      final listResp = await http.get(
        Uri.parse(ApiConfig.notifications),
        headers: headers,
      );
      final countResp = await http.get(
        Uri.parse(ApiConfig.notificationsUnreadCount),
        headers: headers,
      );

      if (listResp.statusCode == 200) {
        final List<dynamic> data = json.decode(listResp.body);
        _notifications = data
            .map((e) => MessageNotificationItem.fromJson(e))
            .toList();
      }
      if (countResp.statusCode == 200) {
        final map = json.decode(countResp.body) as Map<String, dynamic>;
        _unreadCount = map['count'] is int
            ? map['count']
            : int.tryParse('${map['count']}') ?? 0;
      }
    } catch (e) {
      debugPrint('Notification refresh error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _connectWebSocket(int userId) {
    ApiService.getToken().then((token) {
      _chatService.connect(
        url: ApiConfig.webSocketUrl,
        stompConnectHeaders:
            token != null ? {'Authorization': 'Bearer $token'} : null,
        onConnect: (_) {
          _chatService.subscribe('/topic/notifications/$userId', (frame) {
            if (frame.body == null) return;
            final item = MessageNotificationItem.fromJson(
              json.decode(frame.body!) as Map<String, dynamic>,
            );
            _notifications = [
              item,
              ..._notifications.where((n) => n.id != item.id),
            ];
            if (!item.read) {
              _unreadCount++;
            }
            _latestIncoming = item;
            notifyListeners();
          });
          notifyListeners();
        },
        onWebSocketError: (e) {
          debugPrint('Notification WS error: $e');
          notifyListeners();
        },
      );
    });
  }

  void clearLatestIncoming() {
    _latestIncoming = null;
  }

  Future<void> markAsRead(int id) async {
    final headers = await ApiService.getHeaders();
    final resp = await http.put(
      Uri.parse('${ApiConfig.notifications}/$id/read'),
      headers: headers,
    );
    if (resp.statusCode == 200) {
      _notifications = _notifications.map((n) {
        if (n.id == id && !n.read) {
          _unreadCount = (_unreadCount - 1).clamp(0, 999);
          return MessageNotificationItem(
            id: n.id,
            type: n.type,
            title: n.title,
            body: n.body,
            senderId: n.senderId,
            senderName: n.senderName,
            teamId: n.teamId,
            messageId: n.messageId,
            read: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    final headers = await ApiService.getHeaders();
    final resp = await http.put(
      Uri.parse(ApiConfig.notificationsReadAll),
      headers: headers,
    );
    if (resp.statusCode == 200) {
      _notifications = _notifications
          .map((n) => MessageNotificationItem(
                id: n.id,
                type: n.type,
                title: n.title,
                body: n.body,
                senderId: n.senderId,
                senderName: n.senderName,
                teamId: n.teamId,
                messageId: n.messageId,
                read: true,
                createdAt: n.createdAt,
              ))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    }
  }

  void disconnect() {
    _chatService.disconnect();
    _connectedUserId = null;
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
