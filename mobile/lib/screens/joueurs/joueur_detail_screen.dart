import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/themed_app_bar.dart';
import '../../models/models.dart';
import '../../models/player_technical_note.dart';
import '../../providers/auth_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/alert_provider.dart';
import '../../models/injury_suspension.dart';
import '../alerts/create_alert_screen.dart';

class JoueurDetailScreen extends StatefulWidget {
  final dynamic item;

  const JoueurDetailScreen({super.key, required this.item});

  @override
  _JoueurDetailScreenState createState() => _JoueurDetailScreenState();
}

class _JoueurDetailScreenState extends State<JoueurDetailScreen> {
  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Only load player notes and alerts for Joueur objects (not User objects)
    if (widget.item is Joueur && 
        (authProvider.user?.role == 'ENCADRANT' || authProvider.user?.role == 'ADMIN')) {
      Provider.of<PlayerProvider>(context, listen: false).loadPlayerNotes(widget.item.id!);
      Provider.of<AlertProvider>(context, listen: false).loadPlayerAlerts(widget.item.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isCoach = authProvider.user?.role == 'ENCADRANT' || authProvider.user?.role == 'ADMIN';
    final isJoueur = widget.item is Joueur;
    final showCoachTabs = isCoach && isJoueur;

    return DefaultTabController(
      length: showCoachTabs ? 3 : 1,
      child: Scaffold(
        appBar: ThemedAppBar(
          title: Text(widget.item is User
              ? '${widget.item.prenom} ${widget.item.nom}'
              : '${widget.item.prenom} ${widget.item.nom}'),
          bottom: TabBar(
            labelColor: AppTheme.masYellow,
            unselectedLabelColor: Colors.white70,
            indicatorColor: AppTheme.masYellow,
            tabs: [
              const Tab(text: 'Informations'),
              if (showCoachTabs) ...[
                const Tab(text: 'Technique'),
                const Tab(text: 'Alertes'),
              ],
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInfoTab(),
            if (showCoachTabs) ...[
              _buildTechnicalTab(),
              _buildAlertsTab(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.getGradient(context)),
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.white.withOpacity(0.05) 
            : Colors.black.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.item is User
                ? [
                    _buildInfoRow('Rôle', widget.item.role),
                    _buildInfoRow('Email', widget.item.email),
                    _buildInfoRow('Téléphone', widget.item.telephone ?? 'N/A'),
                    _buildInfoRow('Adresse', widget.item.adresse ?? 'N/A'),
                    _buildInfoRow('Date de naissance', widget.item.dateNaissance ?? 'N/A'),
                    _buildInfoRow('Statut', widget.item.actif ? 'Actif' : 'Inactif'),
                    _buildInfoRow('Date d\'inscription', widget.item.dateInscription ?? 'N/A'),
                  ]
                : [
                    _buildInfoRow('Poste', widget.item.poste),
                    _buildInfoRow('Numéro', widget.item.numeroMaillot?.toString() ?? 'N/A'),
                    _buildInfoRow('Date de naissance', widget.item.dateNaissance ?? 'N/A'),
                    _buildInfoRow('Nationalité', widget.item.nationalite ?? 'N/A'),
                    _buildInfoRow('Taille', widget.item.taille != null ? '${widget.item.taille} cm' : 'N/A'),
                    _buildInfoRow('Poids', widget.item.poids != null ? '${widget.item.poids} kg' : 'N/A'),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTechnicalTab() {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        if (playerProvider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.masYellow));
        }

        return Container(
          decoration: BoxDecoration(gradient: AppTheme.getGradient(context)),
          child: Column(
            children: [
              Expanded(
                child: playerProvider.notes.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune note technique',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: playerProvider.notes.length,
                        itemBuilder: (context, index) {
                          final note = playerProvider.notes[index];
                          return _buildNoteCard(note);
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateNoteDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une note'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.masYellow,
                    foregroundColor: AppTheme.masBlack,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoteCard(PlayerTechnicalNote note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Par ${note.encadrantName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            _buildRatingRow('Technique', note.technicalRating),
            _buildRatingRow('Tactique', note.tacticalRating),
            _buildRatingRow('Physique', note.physicalRating),
            const SizedBox(height: 8),
            if (note.strengths.isNotEmpty) ...[
              const Text('Forces:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(note.strengths),
              const SizedBox(height: 8),
            ],
            if (note.weaknesses.isNotEmpty) ...[
              const Text('Faiblesses:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(note.weaknesses),
              const SizedBox(height: 8),
            ],
            if (note.observation.isNotEmpty) ...[
              const Text('Observations:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(note.observation),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(String label, int rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            child: Row(
              children: List.generate(10, (index) {
                return Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: AppTheme.masYellow,
                  size: 20,
                );
              }),
            ),
          ),
          Text('$rating/10'),
        ],
      ),
    );
  }

  void _showCreateNoteDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    int technicalRating = 5;
    int tacticalRating = 5;
    int physicalRating = 5;
    String strengths = '';
    String weaknesses = '';
    String observation = '';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nouvelle note technique'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSlider('Technique', technicalRating, (value) {
                  setState(() => technicalRating = value.round());
                }),
                _buildSlider('Tactique', tacticalRating, (value) {
                  setState(() => tacticalRating = value.round());
                }),
                _buildSlider('Physique', physicalRating, (value) {
                  setState(() => physicalRating = value.round());
                }),
                TextField(
                  decoration: const InputDecoration(labelText: 'Forces'),
                  maxLines: 2,
                  onChanged: (value) => strengths = value,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Faiblesses'),
                  maxLines: 2,
                  onChanged: (value) => weaknesses = value,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Observations (confidentiel)'),
                  maxLines: 3,
                  onChanged: (value) => observation = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final note = PlayerTechnicalNote(
                  playerId: widget.item.id!,
                  encadrantId: user.id!,
                  encadrantName: '${user.prenom} ${user.nom}',
                  technicalRating: technicalRating,
                  tacticalRating: tacticalRating,
                  physicalRating: physicalRating,
                  strengths: strengths,
                  weaknesses: weaknesses,
                  observation: observation,
                );

                final success = await Provider.of<PlayerProvider>(context, listen: false)
                    .createNote(widget.item.id!, note);

                Navigator.pop(dialogContext);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note créée avec succès')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.masYellow,
                foregroundColor: AppTheme.masBlack,
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsTab() {
    return Consumer<AlertProvider>(
      builder: (context, alertProvider, child) {
        if (alertProvider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.masYellow));
        }

        return Container(
          decoration: BoxDecoration(gradient: AppTheme.getGradient(context)),
          child: Column(
            children: [
              Expanded(
                child: alertProvider.alerts.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune alerte active',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: alertProvider.alerts.length,
                        itemBuilder: (context, index) {
                          final alert = alertProvider.alerts[index];
                          return _buildAlertCard(alert);
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateAlertScreen(
                          playerId: widget.item.id!,
                          playerName: '${widget.item.prenom} ${widget.item.nom}',
                        ),
                      ),
                    ).then((_) {
                      Provider.of<AlertProvider>(context, listen: false)
                          .loadPlayerAlerts(widget.item.id!);
                    });
                  },
                  icon: const Icon(Icons.add_alert),
                  label: const Text('Nouvelle alerte'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.masYellow,
                    foregroundColor: AppTheme.masBlack,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertCard(InjurySuspension alert) {
    Color severityColor;
    switch (alert.severity) {
      case 'HIGH':
        severityColor = Colors.red;
        break;
      case 'MEDIUM':
        severityColor = Colors.orange;
        break;
      default:
        severityColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        leading: Icon(
          alert.type == 'INJURY' ? Icons.healing : Icons.block,
          color: severityColor,
          size: 32,
        ),
        title: Text(
          alert.type == 'INJURY' ? 'Blessure' : 'Suspension',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.description),
            const SizedBox(height: 4),
            Text(
              'Du ${alert.startDate.day}/${alert.startDate.month}/${alert.startDate.year}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: severityColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            alert.severity,
            style: TextStyle(color: severityColor, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(String label, int value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value/10'),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          activeColor: AppTheme.masYellow,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
