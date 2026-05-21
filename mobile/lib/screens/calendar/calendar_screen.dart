import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/themed_app_bar.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ThemedAppBar(titleText: 'Calendrier'),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getGradient(context)),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 80, color: AppTheme.masYellow),
              SizedBox(height: 24),
              Text('Calendrier des \u00c9v\u00e9nements', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.masYellow)),
              SizedBox(height: 12),
              Text('Fonctionnalit\u00e9 en cours de d\u00e9veloppement', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
