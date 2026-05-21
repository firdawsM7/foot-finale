import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../models/message_notification.dart';
import '../providers/message_notification_provider.dart';
import '../widgets/theme_mode_toggle.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _iconForType(String type) {
    switch (type) {
      case 'PRIVATE':
        return Icons.lock_outline;
      case 'BROADCAST':
        return Icons.campaign_outlined;
      case 'GROUP':
        return Icons.groups_outlined;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          const ThemeModeToggle(),
          TextButton(
            onPressed: () =>
                context.read<MessageNotificationProvider>().markAllAsRead(),
            child: const Text(
              'Tout lire',
              style: TextStyle(color: AppTheme.masYellow),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getGradient(context)),
        child: Consumer<MessageNotificationProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.notifications.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.masYellow));
            }
            if (provider.notifications.isEmpty) {
              return const Center(
                child: Text(
                  'Aucune notification',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              );
            }
            return RefreshIndicator(
              color: AppTheme.masYellow,
              onRefresh: provider.refresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.notifications.length,
                itemBuilder: (context, index) {
                  final n = provider.notifications[index];
                  return _NotificationTile(
                    notification: n,
                    icon: _iconForType(n.type),
                    onTap: () async {
                      await provider.markAsRead(n.id);
                      if (context.mounted) {
                        Navigator.pushNamed(context, '/messages');
                      }
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final MessageNotificationItem notification;
  final IconData icon;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.containerDecoration(context).copyWith(
        border: Border.all(
          color: notification.read
              ? Colors.transparent
              : AppTheme.masYellow.withOpacity(0.5),
          width: notification.read ? 0 : 1.5,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.masYellow.withOpacity(0.15),
          child: Icon(icon, color: AppTheme.masYellow),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(notification.createdAt),
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        trailing: notification.read
            ? null
            : Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppTheme.masYellow,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }
}
