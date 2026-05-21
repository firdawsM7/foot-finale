import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/message_notification_provider.dart';

/// Affiche un SnackBar à chaque nouvelle notification messagerie.
class MessageNotificationListener extends StatefulWidget {
  final Widget child;

  const MessageNotificationListener({super.key, required this.child});

  @override
  State<MessageNotificationListener> createState() =>
      _MessageNotificationListenerState();
}

class _MessageNotificationListenerState extends State<MessageNotificationListener> {
  MessageNotificationProvider? _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = context.read<MessageNotificationProvider>();
    if (_provider != p) {
      _provider?.removeListener(_onNotification);
      _provider = p;
      _provider!.addListener(_onNotification);
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_onNotification);
    super.dispose();
  }

  void _onNotification() {
    final provider = context.read<MessageNotificationProvider>();
    final incoming = provider.latestIncoming;
    if (incoming == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${incoming.title}: ${incoming.body}'),
        backgroundColor: AppTheme.masBlack,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Voir',
          textColor: AppTheme.masYellow,
          onPressed: () => Navigator.pushNamed(context, '/messages'),
        ),
      ),
    );
    provider.clearLatestIncoming();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
