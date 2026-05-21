import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/themed_app_bar.dart';

class MesEntrainementsScreen extends StatefulWidget {
  const MesEntrainementsScreen({super.key});

  @override
  State<MesEntrainementsScreen> createState() => _MesEntrainementsScreenState();
}

class _MesEntrainementsScreenState extends State<MesEntrainementsScreen> {
  List<Entrainement> _entrainements = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      if (user == null) {
        setState(() {
          _error = 'Utilisateur non connecté';
          _isLoading = false;
        });
        return;
      }

      // Get user's equipe ID
      final equipeId = user.equipeId;
      
      if (equipeId == null) {
        setState(() {
          _entrainements = [];
          _isLoading = false;
        });
        return;
      }

      // Load entrainements for the user's equipe
      final entrainements = await ApiService.getEntrainementsByEquipe(equipeId);
      
      setState(() {
        _entrainements = entrainements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ThemedAppBar(titleText: 'Mes Entraînements'),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getGradient(context)),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.masYellow));
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_entrainements.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 80, color: AppTheme.masYellow),
            SizedBox(height: 16),
            Text('Aucun entraînement planifié pour votre équipe', style: TextStyle(fontSize: 18, color: Colors.white70)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _entrainements.length,
        itemBuilder: (context, index) {
          final entrainement = _entrainements[index];
          return _buildEntrainementCard(entrainement);
        },
      ),
    );
  }

  Widget _buildEntrainementCard(Entrainement entrainement) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final date = DateTime.parse(entrainement.dateHeure);

    Color statusColor;
    switch (entrainement.statut) {
      case 'PLANIFIE':
        statusColor = Colors.blue;
        break;
      case 'EN_COURS':
        statusColor = Colors.orange;
        break;
      case 'TERMINE':
        statusColor = Colors.green;
        break;
      case 'ANNULE':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Entraînement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    entrainement.statut,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(dateFormat.format(date)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(entrainement.duree != null ? '${entrainement.duree} minutes' : 'Durée non spécifiée'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(entrainement.lieu),
              ],
            ),
            if (entrainement.encadrantNom != null || entrainement.encadrantPrenom != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Encadrant: ${entrainement.encadrantPrenom ?? ''} ${entrainement.encadrantNom ?? ''}'
                        .trim(),
                  ),
                ],
              ),
            ],
            if (entrainement.objectif != null && entrainement.objectif!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Objectif:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                entrainement.objectif!,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
            if (entrainement.exercices != null && entrainement.exercices!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Exercices:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                entrainement.exercices!,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
            if (entrainement.notes != null && entrainement.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Notes:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                entrainement.notes!,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
