import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'add_activity_screen.dart';
import 'page_intro.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onSignOut;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.onSignOut,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final _user = FirebaseFirestore.instance
      .collection('users')
      .doc(widget.userId);
  late final _profile = _user.get();
  final _formKey = GlobalKey<FormState>();
  final _changes = <String, String>{};
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    final form = _formKey.currentState!;
    if (!form.validate()) return;

    _changes.clear();
    form.save();
    setState(() => _saving = true);
    String message;
    try {
      await _user.update(_changes);
      message = 'Profil enregistré.';
    } catch (error) {
      debugPrint('Enregistrement du profil impossible : $error');
      message = 'Impossible d’enregistrer le profil.';
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _field(
    Map<String, dynamic> data,
    String name,
    String label, {
    bool password = false,
    bool digitsOnly = false,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: data[name]?.toString() ?? '',
        enabled: !_saving,
        obscureText: password,
        autocorrect: !password,
        enableSuggestions: !password,
        keyboardType: digitsOnly ? TextInputType.number : null,
        inputFormatters: digitsOnly
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: (value) {
          if (password && (value == null || value.isEmpty)) {
            return 'Saisissez un mot de passe.';
          }
          if (name == 'birthday' && value != null && value.trim().isNotEmpty) {
            final parts = value.trim().split('/');
            final day = parts.length == 3 ? int.tryParse(parts[0]) : null;
            final month = parts.length == 3 ? int.tryParse(parts[1]) : null;
            final year = parts.length == 3 ? int.tryParse(parts[2]) : null;
            if (day == null ||
                month == null ||
                year == null ||
                year < 1 ||
                year > DateTime.now().year ||
                day < 1 ||
                day > 31 ||
                month < 1 ||
                month > 12) {
              return 'Saisissez une date au format JJ/MM/AAAA.';
            }
            final date = DateTime(year, month, day);
            if (date.day != day ||
                date.month != month ||
                date.year != year ||
                date.isAfter(DateTime.now())) {
              return 'Saisissez une date de naissance valide.';
            }
          }
          if (digitsOnly &&
              value != null &&
              value.isNotEmpty &&
              !RegExp(r'^[0-9]+$').hasMatch(value)) {
            return 'Saisissez uniquement des chiffres.';
          }
          return null;
        },
        onSaved: (value) =>
            _changes[name] = password ? value ?? '' : value?.trim() ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data?.data();

        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              const PageIntro(
                icon: Icons.person_outline,
                title: 'Mon profil',
                subtitle: 'Retrouvez vos informations et mettez-les à jour.',
              ),
              const SizedBox(height: 16),
              if (data == null)
                const Text('Impossible de charger le profil.')
              else ...[
                TextFormField(
                  initialValue: data['login']?.toString() ?? widget.userId,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Login',
                    suffixIcon: Icon(Icons.lock_outline, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                _field(data, 'password', 'Mot de passe', password: true),
                _field(data, 'birthday', 'Anniversaire', hint: 'JJ/MM/AAAA'),
                _field(data, 'address', 'Adresse'),
                _field(data, 'postalCode', 'Code postal', digitsOnly: true),
                _field(data, 'city', 'Ville'),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Enregistrement…' : 'Valider'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const AddActivityScreen(),
                          ),
                        ),
                  child: const Text('Ajouter une activité'),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton(
                onPressed: _saving ? null : widget.onSignOut,
                child: const Text('Se déconnecter'),
              ),
            ],
          ),
        );
      },
    );
  }
}
