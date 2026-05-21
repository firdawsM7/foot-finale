import 'package:flutter/material.dart';
import '../models/models.dart';

class PlayerCard extends StatelessWidget {
  final Joueur joueur;
  final VoidCallback? onTap;
  const PlayerCard({super.key, required this.joueur, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(radius: 28, child: Text(joueur.nom.isNotEmpty ? joueur.nom[0].toUpperCase() : '?')),
              const SizedBox(height: 8),
              Text('${joueur.nom} ${joueur.prenom}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(joueur.poste, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
}
