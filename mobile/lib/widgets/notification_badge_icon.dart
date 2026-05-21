import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/message_notification_provider.dart';
import '../screens/notifications_screen.dart';

class NotificationBadgeIcon extends StatelessWidget {
  const NotificationBadgeIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MessageNotificationProvider>(
      builder: (context, provider, _) {
        final count = provider.unreadCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Icône bottom nav Messages avec badge non lu.
class MessagesNavIcon extends StatelessWidget {
  final bool isSelected;

  const MessagesNavIcon({super.key, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<MessageNotificationProvider>(
      builder: (context, provider, _) {
        final count = provider.unreadCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(isSelected ? Icons.chat : Icons.chat_outlined),
            if (count > 0)
              Positioned(
                right: -6,
                top: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppTheme.masYellow,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(
                        color: AppTheme.masBlack,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
