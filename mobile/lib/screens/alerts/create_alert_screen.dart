import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/themed_app_bar.dart';
import '../../models/injury_suspension.dart';
import '../../providers/alert_provider.dart';

class CreateAlertScreen extends StatefulWidget {
  final int playerId;
  final String playerName;

  const CreateAlertScreen({
    super.key,
    required this.playerId,
    required this.playerName,
  });

  @override
  _CreateAlertScreenState createState() => _CreateAlertScreenState();
}

class _CreateAlertScreenState extends State<CreateAlertScreen> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'INJURY';
  String _severity = 'MEDIUM';
  String _description = '';
  DateTime _startDate = DateTime.now();
  DateTime? _estimatedEndDate;
  String _restrictions = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ThemedAppBar(
        title: Text('Nouvelle alerte - ${widget.playerName}'),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.getGradient(context)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(value: 'INJURY', child: Text('Blessure')),
                        DropdownMenuItem(value: 'SUSPENSION', child: Text('Suspension')),
                      ],
                      onChanged: (value) => setState(() => _type = value!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _severity,
                      decoration: const InputDecoration(labelText: 'Gravité'),
                      items: const [
                        DropdownMenuItem(value: 'LOW', child: Text('Faible')),
                        DropdownMenuItem(value: 'MEDIUM', child: Text('Moyenne')),
                        DropdownMenuItem(value: 'HIGH', child: Text('Élevée')),
                      ],
                      onChanged: (value) => setState(() => _severity = value!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Requis' : null,
                      onSaved: (value) => _description = value ?? '',
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Date de début'),
                      subtitle: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) setState(() => _startDate = date);
                      },
                    ),
                    ListTile(
                      title: const Text('Date de fin estimée'),
                      subtitle: Text(_estimatedEndDate != null
                          ? '${_estimatedEndDate!.day}/${_estimatedEndDate!.month}/${_estimatedEndDate!.year}'
                          : 'Non définie'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _estimatedEndDate ?? _startDate.add(const Duration(days: 7)),
                          firstDate: _startDate,
                          lastDate: DateTime(2030),
                        );
                        if (date != null) setState(() => _estimatedEndDate = date);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Restrictions',
                        hintText: 'Ex: Pas de contact, repos complet...',
                      ),
                      maxLines: 2,
                      onSaved: (value) => _restrictions = value ?? '',
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.masYellow,
                        foregroundColor: AppTheme.masBlack,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Créer l\'alerte', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final alert = InjurySuspension(
        playerId: widget.playerId,
        playerName: widget.playerName,
        type: _type,
        severity: _severity,
        description: _description,
        startDate: _startDate,
        estimatedEndDate: _estimatedEndDate,
        status: 'ACTIVE',
        restrictions: _restrictions,
      );

      final success = await Provider.of<AlertProvider>(context, listen: false)
          .createAlert(widget.playerId, alert);

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerte créée avec succès')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la création')),
        );
      }
    }
  }
}
