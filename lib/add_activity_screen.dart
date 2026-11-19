import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image;

import 'page_intro.dart';

import 'activity_classifier_stub.dart'
    if (dart.library.js_interop) 'activity_classifier_web.dart';

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _capacity = TextEditingController();
  final _price = TextEditingController();
  final _link = TextEditingController();
  static const _maxImageBytes = 10 * 1024 * 1024;
  late final _activity = FirebaseFirestore.instance
      .collection('activities')
      .doc();

  Uint8List? _image;
  String? _imageUrl;
  String? _category;
  String? _error;
  bool _classifying = false;
  bool _saving = false;

  Future<void> _pickImage() => _loadImage(
    () => pickActivityImage(_maxImageBytes),
    'Impossible de lire le fichier. Choisis une image de 10 Mo maximum.',
  );

  Future<void> _useLink() async {
    final uri = Uri.tryParse(_link.text.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      setState(() => _error = 'Colle un lien direct vers une image en HTTPS.');
      return;
    }
    await _loadImage(
      () => downloadActivityImage(uri.toString(), _maxImageBytes),
      'Lien inaccessible. Essaie un lien direct public ou télécharge l’image sur ton PC.',
    );
  }

  Future<void> _loadImage(
    Future<Uint8List?> Function() read,
    String readError,
  ) async {
    if (_classifying || _saving) return;
    setState(() {
      _classifying = true;
      _error = null;
    });
    var failureMessage = readError;
    try {
      final source = await read();
      if (!mounted || source == null) return;
      setState(() {
        _image = null;
        _imageUrl = null;
        _category = null;
      });
      if (source.length > _maxImageBytes) {
        throw const FormatException('Choisis une image de 10 Mo maximum.');
      }
      final decoded = image.decodeImage(source);
      if (decoded == null) {
        throw const FormatException('Image JPEG, PNG ou WebP invalide.');
      }
      final resized = image.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? 640 : null,
        height: decoded.height > decoded.width ? 640 : null,
      );
      final bytes = image.encodeJpg(resized, quality: 80);
      // L’image est stockée dans le document, sous la limite Firestore de 1 Mio.
      if (bytes.length > 650 * 1024) {
        throw const FormatException(
          'Image trop complexe. Choisis une image plus petite.',
        );
      }
      final url = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      if (!mounted) return;
      setState(() => _image = bytes);
      failureMessage = 'Image chargée, mais la catégorie n’a pas pu être calculée. Réessaie.';
      final category = await classifyActivity(url)
          .timeout(const Duration(minutes: 3));
      if (!mounted) return;
      setState(() {
        _imageUrl = url;
        _category = category;
      });
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      debugPrint('Import de l’image impossible : $error');
      if (mounted) {
        setState(() => _error = failureMessage);
      }
    } finally {
      if (mounted) setState(() => _classifying = false);
    }
  }

  Future<void> _save() async {
    if (_saving || _classifying || _category == null || _imageUrl == null) {
      return;
    }
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _activity.set({
        'title': _title.text.trim(),
        'location': _location.text.trim(),
        'maxParticipants': int.parse(_capacity.text),
        'price': int.parse(_price.text),
        'imageUrl': _imageUrl!,
        'category': _category!,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Activité ajoutée.')));
      Navigator.of(context).pop();
    } catch (error) {
      debugPrint('Enregistrement de l’activité impossible : $error');
      if (mounted) {
        setState(() => _error = 'Impossible d’enregistrer l’activité.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int? minimum,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: !_saving,
        decoration: InputDecoration(labelText: label),
        keyboardType: minimum == null ? null : TextInputType.number,
        inputFormatters: minimum == null
            ? null
            : [FilteringTextInputFormatter.digitsOnly],
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Champ obligatoire.';
          }
          if (minimum != null) {
            final number = int.tryParse(value);
            if (number == null || number < minimum || number > 999999999) {
              return 'Saisis un entier entre $minimum et 999999999.';
            }
          }
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _capacity.dispose();
    _price.dispose();
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une activité')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                const PageIntro(
                  icon: Icons.add_photo_alternate_outlined,
                  title: 'Une nouvelle activité.',
                  subtitle: 'Commencez par une image. Sa catégorie sera reconnue automatiquement.',
                ),
                if (_image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.memory(
                      _image!,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                OutlinedButton(
                  onPressed: !kIsWeb || _classifying || _saving
                      ? null
                      : _pickImage,
                  child: const Text('Choisir une image JPEG, PNG ou WebP'),
                ),
                if (kIsWeb) ...[
                  TextField(
                    controller: _link,
                    enabled: !_classifying && !_saving,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Ou colle un lien direct vers une image',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _classifying || _saving ? null : _useLink,
                    child: const Text('Utiliser le lien'),
                  ),
                ],
                if (!kIsWeb)
                  const Text(
                    'Ouvre MIAGED dans le navigateur pour analyser une image.',
                  ),
                if (_classifying) ...[
                  const LinearProgressIndicator(),
                  const Text(
                    'Analyse de l’image… Le premier chargement peut prendre un moment.',
                  ),
                ],
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Catégorie automatique',
                  ),
                  child: Text(_category ?? 'Choisis une image'),
                ),
                const SizedBox(height: 20),
                _field(_title, 'Titre'),
                _field(_location, 'Lieu'),
                _field(_capacity, 'Nombre maximum de personnes', minimum: 1),
                _field(_price, 'Prix (€)', minimum: 0),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ElevatedButton(
                  onPressed: _category == null || _classifying || _saving
                      ? null
                      : _save,
                  child: Text(_saving ? 'Enregistrement…' : 'Valider'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
