import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/theme_mode_toggle.dart';

class EntrainementsScreen extends StatefulWidget {
  const EntrainementsScreen({super.key});

  @override
  State<EntrainementsScreen> createState() => _EntrainementsScreenState();
}

class _EntrainementsScreenState extends State<EntrainementsScreen> {
  List<Entrainement> _entrainements = [];
  List<Equipe> _equipes = [];
  List<User> _encadrants = [];
  bool _isLoading = true;
  String _error = '';
  String _userRole = '';
  int? _userId;

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
      final role = user?.role ?? '';
      final userId = user?.id;

      // Load entrainements based on role
      List<Entrainement> entrainements;
      if (role == 'ENCADRANT' && userId != null) {
        // For encadrant, load only their assigned sessions
        entrainements = await ApiService.getAllEntrainements(role, encadrantId: userId);
      } else {
        // For admin and others, load all
        entrainements = await ApiService.getAllEntrainements(role);
      }
      
      final equipes = await ApiService.getAllEquipes(role);
      
      // Load encadrants only for admin
      List<User> encadrants = [];
      if (role == 'ADMIN') {
        final users = await ApiService.getAllUsers();
        encadrants = users.where((u) => u.role == 'ENCADRANT').toList();
      }
      
      setState(() {
        _entrainements = entrainements;
        _equipes = equipes;
        _encadrants = encadrants;
        _userRole = role;
        _userId = userId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showEntrainementForm({Entrainement? entrainement}) {
    showDialog(
      context: context,
      builder: (context) => EntrainementFormDialog(
        entrainement: entrainement,
        equipes: _equipes,
        encadrants: _encadrants,
        onSave: () async {
          await _loadData();
        },
      ),
    );
  }

  Future<void> _deleteEntrainement(Entrainement entrainement) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'entraînement'),
        content: Text('Êtes-vous sûr de vouloir supprimer cet entraînement du ${DateFormat('dd/MM/yyyy').format(DateTime.parse(entrainement.dateHeure))} ?'),
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
        await ApiService.deleteEntrainement(entrainement.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entraînement supprimé avec succès')),
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
        title: const Text('Gestion des Entraînements'),
        actions: AppBarActions.withTheme(
          extra: [
            if (_userRole == 'ADMIN')
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showEntrainementForm(),
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

    if (_entrainements.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 80, color: AppTheme.masYellow),
            SizedBox(height: 16),
            Text('Aucun entraînement planifié', style: TextStyle(fontSize: 18, color: Colors.white70)),
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
            // Only show edit and delete buttons for ADMIN
            if (_userRole == 'ADMIN') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEntrainementForm(entrainement: entrainement),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteEntrainement(entrainement),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EntrainementFormDialog extends StatefulWidget {
  final Entrainement? entrainement;
  final List<Equipe> equipes;
  final List<User> encadrants;
  final VoidCallback onSave;

  const EntrainementFormDialog({
    super.key,
    this.entrainement,
    required this.equipes,
    required this.encadrants,
    required this.onSave,
  });

  @override
  State<EntrainementFormDialog> createState() => _EntrainementFormDialogState();
}

class _EntrainementFormDialogState extends State<EntrainementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late int? _selectedEquipeId;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late TextEditingController _lieuController;
  late TextEditingController _dureeController;
  late TextEditingController _objectifController;
  late TextEditingController _exercicesController;
  late int? _selectedEncadrantId;
  late String _selectedStatut;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _selectedEquipeId = widget.entrainement?.equipeId;
    final date = widget.entrainement?.dateHeure != null ? DateTime.parse(widget.entrainement!.dateHeure) : DateTime.now().add(const Duration(days: 1));
    _selectedDate = date;
    _selectedTime = TimeOfDay.fromDateTime(date);
    _lieuController = TextEditingController(text: widget.entrainement?.lieu ?? '');
    _dureeController = TextEditingController(text: widget.entrainement?.duree?.toString() ?? '');
    _objectifController = TextEditingController(text: widget.entrainement?.objectif ?? '');
    _exercicesController = TextEditingController(text: widget.entrainement?.exercices ?? '');
    _selectedEncadrantId = widget.entrainement?.encadrantId;
    _selectedStatut = widget.entrainement?.statut ?? 'PLANIFIE';
    _notesController = TextEditingController(text: widget.entrainement?.notes ?? '');
  }

  @override
  void dispose() {
    _lieuController.dispose();
    _dureeController.dispose();
    _objectifController.dispose();
    _exercicesController.dispose();
    _notesController.dispose();
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

  Future<void> _saveEntrainement() async {
    if (!_formKey.currentState!.validate()) return;

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final entrainementData = {
      'equipe': {'id': _selectedEquipeId},
      'dateHeure': dateTime.toIso8601String(),
      'lieu': _lieuController.text,
      'statut': _selectedStatut,
    };

    if (_dureeController.text.isNotEmpty) {
      final dureeValue = int.tryParse(_dureeController.text);
      if (dureeValue != null && dureeValue > 0) {
        entrainementData['duree'] = dureeValue;
      }
    }
    if (_objectifController.text.isNotEmpty) {
      entrainementData['objectif'] = _objectifController.text;
    }
    if (_exercicesController.text.isNotEmpty) {
      entrainementData['exercices'] = _exercicesController.text;
    }
    if (_selectedEncadrantId != null) {
      entrainementData['encadrant'] = {'id': _selectedEncadrantId};
    }
    if (_notesController.text.isNotEmpty) {
      entrainementData['notes'] = _notesController.text;
    }

    try {
      if (widget.entrainement == null) {
        await ApiService.createEntrainement(entrainementData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entraînement créé avec succès')),
        );
      } else {
        await ApiService.updateEntrainement(widget.entrainement!.id!, entrainementData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entraînement modifié avec succès')),
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
      title: Text(widget.entrainement == null ? 'Créer un entraînement' : 'Modifier l\'entraînement'),
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
                TextFormField(
                  controller: _dureeController,
                  decoration: const InputDecoration(labelText: 'Durée (minutes)'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _objectifController,
                  decoration: const InputDecoration(labelText: 'Objectif'),
                  maxLines: 2,
                ),
                TextFormField(
                  controller: _exercicesController,
                  decoration: const InputDecoration(labelText: 'Exercices'),
                  maxLines: 3,
                ),
                if (widget.encadrants.isNotEmpty)
                  DropdownButtonFormField<int>(
                    initialValue: _selectedEncadrantId,
                    decoration: const InputDecoration(labelText: 'Encadrant'),
                    items: [
                      const DropdownMenuItem<int>(
                        initialValue: null,
                        child: Text('Aucun'),
                      ),
                      ...widget.encadrants.map((encadrant) {
                        return DropdownMenuItem(
                          initialValue: encadrant.id,
                          child: Text('${encadrant.prenom} ${encadrant.nom}'),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedEncadrantId = value;
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
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
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
          onPressed: _saveEntrainement,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
