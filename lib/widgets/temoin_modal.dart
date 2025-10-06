import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/accident_models.dart';

class TemoinModal extends StatefulWidget {
  const TemoinModal({super.key});

  @override
  State<TemoinModal> createState() => _TemoinModalState();
}

class _TemoinModalState extends State<TemoinModal> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _temoignageController = TextEditingController();
  LienAccident _lien = LienAccident.temoinDirect;

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    _ageController.dispose();
    _temoignageController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(
        context,
        Temoin(
          nom: _nomController.text.trim(),
          telephone: _telephoneController.text.trim(),
          age: int.parse(_ageController.text),
          lienAvecAccident: _lien,
          temoignage: _temoignageController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text(
        'Ajouter un témoin',
        style: theme.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nom complet *',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                validator: (v) => v?.trim().isEmpty == true ? 'Nom requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telephoneController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Téléphone *',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v?.trim().isEmpty == true ? 'Téléphone requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Âge *',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v?.trim().isEmpty == true) return 'Âge requis';
                  final age = int.tryParse(v!);
                  if (age == null || age < 1 || age > 120) {
                    return 'Âge invalide (1-120)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<LienAccident>(
                value: _lien,
                style: const TextStyle(color: Colors.white),
                dropdownColor: theme.scaffoldBackgroundColor,
                decoration: const InputDecoration(
                  labelText: 'Lien avec l\'accident',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                items: LienAccident.values.map((lien) =>
                  DropdownMenuItem(
                    value: lien,
                    child: Text(
                      lien.label,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ).toList(),
                onChanged: (v) => setState(() => _lien = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _temoignageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Témoignage (optionnel)',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
