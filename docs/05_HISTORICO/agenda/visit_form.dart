// lib/modules/agenda/widgets/visit_form.dart
import 'package:flutter/material.dart';
import '../models/visit.dart';

class VisitForm extends StatefulWidget {
  final Visit? initialVisit;
  final ValueChanged<Visit> onSave;
  
  const VisitForm({
    super.key,
    this.initialVisit,
    required this.onSave,
  });

  @override
  State<VisitForm> createState() => _VisitFormState();
}

class _VisitFormState extends State<VisitForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _clientController;
  late TextEditingController _farmController;
  late TextEditingController _locationController;
  late TextEditingController _objectiveController;

  @override
  void initState() {
    super.initState();
    _clientController = TextEditingController(
      text: widget.initialVisit?.clientName ?? '',
    );
    _farmController = TextEditingController(
      text: widget.initialVisit?.farmName ?? '',
    );
    _locationController = TextEditingController(
      text: widget.initialVisit?.location ?? '',
    );
    _objectiveController = TextEditingController(
      text: widget.initialVisit?.objective ?? '',
    );
  }

  @override
  void dispose() {
    _clientController.dispose();
    _farmController.dispose();
    _locationController.dispose();
    _objectiveController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final visit = widget.initialVisit?.copyWith(
        clientName: _clientController.text,
        farmName: _farmController.text,
        location: _locationController.text,
        objective: _objectiveController.text,
      ) ?? Visit(
        date: DateTime.now(),
        clientName: _clientController.text,
        farmName: _farmController.text,
        location: _locationController.text,
        objective: _objectiveController.text,
      );
      
      widget.onSave(visit);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.initialVisit == null ? 'Nova Visita' : 'Editar Visita',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 24),
            
            TextFormField(
              controller: _clientController,
              decoration: InputDecoration(
                labelText: 'Nome do Cliente',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            TextFormField(
              controller: _farmController,
              decoration: InputDecoration(
                labelText: 'Fazenda',
                prefixIcon: Icon(Icons.agriculture),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Localização',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            TextFormField(
              controller: _objectiveController,
              decoration: InputDecoration(
                labelText: 'Objetivo da Visita',
                prefixIcon: Icon(Icons.flag),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    child: Text('Salvar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
