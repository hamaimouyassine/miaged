import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'page_intro.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _saving = false;
  String? _error;

  Future<void> _register() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final login = _login.text.trim();
    final password = _password.text;
    try {
      final database = FirebaseFirestore.instance;
      final users = database.collection('users');
      // Vérifie également les comptes créés avant l’ajout de l’inscription.
      final existing = await users
          .where('login', isEqualTo: login)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw const FormatException('Ce login est déjà utilisé.');
      }
      // Deux inscriptions simultanées du même login visent le même document.
      final account = users.doc(
        'login_${base64Url.encode(utf8.encode(login))}',
      );
      await database.runTransaction((transaction) async {
        final snapshot = await transaction.get(account);
        if (snapshot.exists) {
          throw const FormatException('Ce login est déjà utilisé.');
        }
        transaction.set(account, {
          'login': login,
          'password': password,
          'birthday': '',
          'address': '',
          'postalCode': '',
          'city': '',
        });
      });
      if (!mounted) return;
      Navigator.of(context).pop(login);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      debugPrint('Inscription impossible : $error');
      if (mounted) {
        setState(() => _error = 'Impossible de créer le compte. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PageIntro(
                    icon: Icons.person_add_outlined,
                    title: 'Créez votre compte.',
                    subtitle: 'Vos informations personnelles pourront être complétées dans votre profil.',
                  ),
                  TextFormField(
                    controller: _login,
                    enabled: !_saving,
                    maxLength: 80,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newUsername],
                    decoration: const InputDecoration(labelText: 'Login'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Saisissez un login.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    enabled: !_saving,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Saisissez un mot de passe.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmation,
                    enabled: !_saving,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    onFieldSubmitted: (_) => _register(),
                    decoration: const InputDecoration(
                      labelText: 'Confirmer le password',
                    ),
                    validator: (value) =>
                        value != _password.text ||
                            value == null ||
                            value.isEmpty
                        ? 'Les mots de passe doivent être identiques.'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ElevatedButton(
                    onPressed: _saving ? null : _register,
                    child: Text(
                      _saving ? 'Création en cours…' : 'Créer mon compte',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
