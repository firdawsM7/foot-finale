import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/theme_mode_toggle.dart';

class EncadrantEntrainementsScreen extends StatefulWidget {
  const EncadrantEntrainementsScreen({super.key});

  @override
  State<EncadrantEntrainementsScreen> createState() => _EncadrantEntrainementsScreenState();
}

class _EncadrantEntrainementsScreenState extends State<EncadrantEntrainementsScreen> {
  List<Entrainement> _entrainements = [];
  bool _isLoading = true;
  String _error = '';
  String _filter = 'TOUS'; // TOUS, PLANIFIE, EN_COURS, TERMINE, ANNULE

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
      final userId = user?.id;

      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final entrainements = await ApiService.getAllEntrainements(
        'ENCADRANT',
        encadrantId: userId,
      );

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

  List<Entrainement> get _filteredEntrainements {
    if (_filter == 'TOUS') return _entrainements;
    return _entrainements.where((e) => e.statut == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Entraînements'),
        actions: AppBarActions.withTheme(
          extra: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
      ),
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

    return Column(
      children: [
        // Filter chips
        _buildFilterChips(),
        // Training list
        Expanded(child: _buildEntrainementsList()),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = ['TOUS', 'PLANIFIE', 'EN_COURS', 'TERMINE', 'ANNULE'];

    return Container(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _filter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_getFilterLabel(filter)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _filter = filter;
                  });
                },
                backgroundColor: Colors.white10,
                selectedColor: AppTheme.masYellow.withOpacity(0.3),
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.masYellow : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'TOUS':
        return 'Tous (${_entrainements.length})';
      case 'PLANIFIE':
        return 'Planifiés (${_entrainements.where((e) => e.statut == 'PLANIFIE').length})';
      case 'EN_COURS':
        return 'En cours (${_entrainements.where((e) => e.statut == 'EN_COURS').length})';
      case 'TERMINE':
        return 'Terminés (${_entrainements.where((e) => e.statut == 'TERMINE').length})';
      case 'ANNULE':
        return 'Annulés (${_entrainements.where((e) => e.statut == 'ANNULE').length})';
      default:
        return filter;
    }
  }

  Widget _buildEntrainementsList() {
    final filtered = _filteredEntrainements;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _filter == 'TOUS' ? Icons.fitness_center : Icons.event_busy,
              size: 80,
              color: AppTheme.masYellow.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _filter == 'TOUS'
                  ? 'Aucun entraînement assigné'
                  : 'Aucun entraînement $_filter',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final entrainement = filtered[index];
          return _buildEntrainementCard(entrainement);
        },
      ),
    );
  }

  Widget _buildEntrainementCard(Entrainement entrainement) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final date = DateTime.parse(entrainement.dateHeure);

    Color statusColor = _getStatusColor(entrainement.statut);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Entraînement ${entrainement.equipeId > 0 ? '- Équipe ${entrainement.equipeId}' : ''}',
                    style: const TextStyle(
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
                    _getStatusLabel(entrainement.statut),
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date and Time
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(dateFormat.format(date)),
              ],
            ),
            const SizedBox(height: 8),

            // Duration
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(entrainement.duree != null
                    ? '${entrainement.duree} minutes'
                    : 'Durée non spécifiée'),
              ],
            ),
            const SizedBox(height: 8),

            // Location
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(entrainement.lieu),
              ],
            ),

            // Objective
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

            // Exercises
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

            // Notes
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

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Update status button
                ElevatedButton.icon(
                  onPressed: () => _showUpdateStatusDialog(entrainement),
                  icon: const Icon(Icons.update, size: 18),
                  label: const Text('Mettre à jour'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.masYellow,
                    foregroundColor: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                // View details button
                OutlinedButton.icon(
                  onPressed: () => _showDetailsDialog(entrainement),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('Détails'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'PLANIFIE':
        return Colors.blue;
      case 'EN_COURS':
        return Colors.orange;
      case 'TERMINE':
        return Colors.green;
      case 'ANNULE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String statut) {
    switch (statut) {
      case 'PLANIFIE':
        return 'Planifié';
      case 'EN_COURS':
        return 'En cours';
      case 'TERMINE':
        return 'Terminé';
      case 'ANNULE':
        return 'Annulé';
      default:
        return statut;
    }
  }

  Future<void> _showUpdateStatusDialog(Entrainement entrainement) async {
    final newStatus = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mettre à jour le statut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.schedule, color: Colors.blue),
              title: const Text('Planifié'),
              onTap: () => Navigator.pop(context, 'PLANIFIE'),
            ),
            ListTile(
              leading: const Icon(Icons.play_circle, color: Colors.orange),
              title: const Text('En cours'),
              onTap: () => Navigator.pop(context, 'EN_COURS'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Terminé'),
              onTap: () => Navigator.pop(context, 'TERMINE'),
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Annulé'),
              onTap: () => Navigator.pop(context, 'ANNULE'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (newStatus != null && newStatus != entrainement.statut) {
      await _updateStatut(entrainement, newStatus);
    }
  }

  Future<void> _updateStatut(Entrainement entrainement, String newStatut) async {
    try {
      final updatedData = {
        'equipe': {'id': entrainement.equipeId},
        'dateHeure': entrainement.dateHeure,
        'lieu': entrainement.lieu,
        'statut': newStatut,
        if (entrainement.duree != null) 'duree': entrainement.duree,
        if (entrainement.objectif != null) 'objectif': entrainement.objectif,
        if (entrainement.exercices != null) 'exercices': entrainement.exercices,
        if (entrainement.notes != null) 'notes': entrainement.notes,
        if (entrainement.encadrantId != null) 'encadrant': {'id': entrainement.encadrantId},
      };

      await ApiService.updateEntrainement(entrainement.id!, updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Statut mis à jour: ${_getStatusLabel(newStatut)}')),
      );

      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _showDetailsDialog(Entrainement entrainement) async {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final date = DateTime.parse(entrainement.dateHeure);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails de l\'entraînement'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Date', dateFormat.format(date)),
              _buildDetailRow('Durée', entrainement.duree != null ? '${entrainement.duree} min' : 'Non spécifiée'),
              _buildDetailRow('Lieu', entrainement.lieu),
              _buildDetailRow('Statut', _getStatusLabel(entrainement.statut)),
              if (entrainement.objectif != null && entrainement.objectif!.isNotEmpty)
                _buildDetailRow('Objectif', entrainement.objectif!),
              if (entrainement.exercices != null && entrainement.exercices!.isNotEmpty)
                _buildDetailRow('Exercices', entrainement.exercices!),
              if (entrainement.notes != null && entrainement.notes!.isNotEmpty)
                _buildDetailRow('Notes', entrainement.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
