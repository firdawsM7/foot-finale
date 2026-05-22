import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/theme_mode_toggle.dart';

class MatchsScreen extends StatefulWidget {
  const MatchsScreen({super.key});

  @override
  State<MatchsScreen> createState() => _MatchsScreenState();
}

class _MatchsScreenState extends State<MatchsScreen> {
  List<Match> _matchs = [];
  List<Equipe> _equipes = [];
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
      final matchs = await ApiService.getAllMatchs('ADMIN');
      final equipes = await ApiService.getAllEquipes('ADMIN');
      setState(() {
        _matchs = matchs;
        _equipes = equipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showMatchForm({Match? match}) {
    showDialog(
      context: context,
      builder: (context) => MatchFormDialog(
        match: match,
        equipes: _equipes,
        onSave: () async {
          await _loadData();
        },
      ),
    );
  }

  Future<void> _deleteMatch(Match match) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le match'),
        content: Text('Êtes-vous sûr de vouloir supprimer ce match contre ${match.adversaire} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteMatch(match.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match supprimé avec succès')),
        );
        await _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Matchs'),
        actions: AppBarActions.withTheme(
          extra: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showMatchForm(),
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

    if (_matchs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stadium, size: 80, color: AppTheme.masYellow),
            SizedBox(height: 16),
            Text('Aucun match planifié', style: TextStyle(fontSize: 18, color: Colors.white70)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _matchs.length,
        itemBuilder: (context, index) {
          final match = _matchs[index];
          return _buildMatchCard(match);
        },
      ),
    );
  }

  Widget _buildMatchCard(Match match) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final date = DateTime.parse(match.dateHeure);

    Color statusColor;
    switch (match.statut) {
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
                Expanded(
                  child: Text(
                    'VS ${match.adversaire}',
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
                    match.statut,
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
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(match.lieu),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.category, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Type: ${match.type}'),
              ],
            ),
            if (match.scoreEquipe != null && match.scoreAdversaire != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.masYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${match.scoreEquipe}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('VS', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ),
                    Text(
                      '${match.scoreAdversaire}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showMatchForm(match: match),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteMatch(match),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MatchFormDialog extends StatefulWidget {
  final Match? match;
  final List<Equipe> equipes;
  final VoidCallback onSave;

  const MatchFormDialog({
    super.key,
    this.match,
    required this.equipes,
    required this.onSave,
  });

  @override
  State<MatchFormDialog> createState() => _MatchFormDialogState();
}

class _MatchFormDialogState extends State<MatchFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late int? _selectedEquipeId;
  late TextEditingController _adversaireController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late TextEditingController _lieuController;
  late String _selectedType;
  late TextEditingController _scoreEquipeController;
  late TextEditingController _scoreAdversaireController;
  late String _selectedStatut;
  late TextEditingController _notesController;
  late TextEditingController _compositionController;

  @override
  void initState() {
    super.initState();
    _selectedEquipeId = widget.match?.equipeId;
    _adversaireController = TextEditingController(text: widget.match?.adversaire ?? '');
    final date = widget.match?.dateHeure != null ? DateTime.parse(widget.match!.dateHeure) : DateTime.now().add(const Duration(days: 1));
    _selectedDate = date;
    _selectedTime = TimeOfDay.fromDateTime(date);
    _lieuController = TextEditingController(text: widget.match?.lieu ?? '');
    _selectedType = widget.match?.type ?? 'AMICAL';
    _scoreEquipeController = TextEditingController(text: widget.match?.scoreEquipe?.toString() ?? '');
    _scoreAdversaireController = TextEditingController(text: widget.match?.scoreAdversaire?.toString() ?? '');
    _selectedStatut = widget.match?.statut ?? 'PLANIFIE';
    _notesController = TextEditingController(text: widget.match?.notes ?? '');
    _compositionController = TextEditingController(text: widget.match?.composition ?? '');
  }

  @override
  void dispose() {
    _adversaireController.dispose();
    _lieuController.dispose();
    _scoreEquipeController.dispose();
    _scoreAdversaireController.dispose();
    _notesController.dispose();
    _compositionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveMatch() async {
    if (!_formKey.currentState!.validate()) return;

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final matchData = {
      'equipe': {'id': _selectedEquipeId},
      'adversaire': _adversaireController.text,
      'dateHeure': dateTime.toIso8601String(),
      'lieu': _lieuController.text,
      'type': _selectedType,
      'statut': _selectedStatut,
      'notes': _notesController.text.isEmpty ? null : _notesController.text,
      'composition': _compositionController.text.isEmpty ? null : _compositionController.text,
    };

    if (_scoreEquipeController.text.isNotEmpty) {
      matchData['scoreEquipe'] = int.parse(_scoreEquipeController.text);
    }
    if (_scoreAdversaireController.text.isNotEmpty) {
      matchData['scoreAdversaire'] = int.parse(_scoreAdversaireController.text);
    }

    try {
      if (widget.match == null) {
        await ApiService.createMatch(matchData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match créé avec succès')),
        );
      } else {
        await ApiService.updateMatch(widget.match!.id!, matchData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match modifié avec succès')),
        );
      }
      widget.onSave();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.match == null ? 'Créer un match' : 'Modifier le match'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _selectedEquipeId,
                  decoration: const InputDecoration(labelText: 'Équipe'),
                  items: widget.equipes.map((equipe) {
                    return DropdownMenuItem(
                      initialValue: equipe.id,
                      child: Text(equipe.nom),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedEquipeId = value;
                    });
                  },
                  validator: (value) => value == null ? 'Sélectionnez une équipe' : null,
                ),
                TextFormField(
                  controller: _adversaireController,
                  decoration: const InputDecoration(labelText: 'Adversaire'),
                  validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _selectTime,
                        icon: const Icon(Icons.access_time),
                        label: Text(_selectedTime.format(context)),
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _lieuController,
                  decoration: const InputDecoration(labelText: 'Lieu'),
                  validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['CHAMPIONNAT', 'COUPE', 'AMICAL', 'TOURNOI'].map((type) {
                    return DropdownMenuItem(initialValue: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatut,
                  decoration: const InputDecoration(labelText: 'Statut'),
                  items: ['PLANIFIE', 'EN_COURS', 'TERMINE', 'ANNULE'].map((statut) {
                    return DropdownMenuItem(initialValue: statut, child: Text(statut));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatut = value!;
                    });
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _scoreEquipeController,
                        decoration: const InputDecoration(labelText: 'Score Équipe'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _scoreAdversaireController,
                        decoration: const InputDecoration(labelText: 'Score Adversaire'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
                TextFormField(
                  controller: _compositionController,
                  decoration: const InputDecoration(labelText: 'Composition'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saveMatch,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
