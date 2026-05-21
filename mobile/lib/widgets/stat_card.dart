import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const StatCard({super.key, required this.title, required this.value, this.icon = Icons.bar_chart});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          CircleAvatar(backgroundColor: const Color(0xFFFFC107), child: Icon(icon, color: const Color(0xFF212121))),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(value, style: const TextStyle(fontSize: 18))])
        ]),
      ),
    );
  }
}
