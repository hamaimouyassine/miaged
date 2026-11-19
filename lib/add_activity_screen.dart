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
  String? _analysisSource;
  String? _analysisWarning;
  String? _suggestedTitle;
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
        _analysisSource = null;
        _analysisWarning = null;
        _suggestedTitle = null;
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
      // Une miniature limite le temps d’encodage visuel d’Ollama sur CPU.
      final analysisImage = image.copyResize(
        resized,
        width: resized.width >= resized.height ? 320 : null,
        height: resized.height > resized.width ? 320 : null,
      );
      final analysisUrl =
          'data:image/jpeg;base64,${base64Encode(image.encodeJpg(analysisImage, quality: 80))}';
      final analysis = await analyzeActivity(analysisUrl)
          .timeout(const Duration(minutes: 3));
      if (!mounted) return;
      setState(() {
        _imageUrl = url;
        _category = analysis.category;
        _analysisSource = analysis.source;
        _analysisWarning = analysis.warning;
        _suggestedTitle = analysis.title.isEmpty ? null : analysis.title;
        if (_title.text.trim().isEmpty && analysis.title.isNotEmpty) {
          _title.text = analysis.title;
        }
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
    IconData? icon,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: !_saving,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon == null ? null : Icon(icon),
        ),
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

  Widget _section(
    String number,
    String title,
    String subtitle,
    List<Widget> children,
  ) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    number,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _imageSection() {
    final colors = Theme.of(context).colorScheme;
    return _section(
      '1',
      'Image et catégorie',
      'Choisissez une photo de votre activité. La catégorie sera définie automatiquement.',
      [
        Container(
          height: 210,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F6F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCE8E8)),
          ),
          child: _image != null
              ? Image.memory(_image!, fit: BoxFit.contain)
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 42,
                      color: Color(0xFF60898D),
                    ),
                    SizedBox(height: 12),
                    Text('Votre image apparaîtra ici'),
                    SizedBox(height: 6),
                    Text(
                      'JPEG, PNG ou WebP · 10 Mo maximum',
                      style: TextStyle(fontSize: 12, color: Color(0xFF60898D)),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: !kIsWeb || _classifying || _saving ? null : _pickImage,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(
            _image == null ? 'Choisir une image sur mon PC' : 'Changer l’image',
          ),
        ),
        if (kIsWeb) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'ou un lien direct',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _link,
            enabled: !_classifying && !_saving,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Lien de l’image',
              hintText: 'https://exemple.fr/photo.jpg',
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _classifying || _saving ? null : _useLink,
            child: const Text('Utiliser le lien'),
          ),
        ],
        if (!kIsWeb) ...[
          const SizedBox(height: 12),
          const Text(
            'Ouvrez MIAGED dans le navigateur pour analyser une image.',
          ),
        ],
        const SizedBox(height: 24),
        if (_classifying) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
          const Text(
            'Analyse de l’image… Le premier chargement peut prendre un moment.',
          ),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                _category == null
                    ? Icons.auto_awesome_outlined
                    : Icons.check_circle_outline,
                color: colors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catégorie automatique',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _category ?? 'En attente d’une image',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (_analysisSource != null)
                      Text(
                        'Analyse locale · $_analysisSource',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.lock_outline, size: 16),
            ],
          ),
        ),
        if (_analysisWarning != null) ...[
          const SizedBox(height: 12),
          Text(
            _analysisWarning!,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _detailsSection() => _section(
    '2',
    'Informations de l’activité',
    'Renseignez les informations qui seront affichées dans la liste et la fiche.',
    [
      _field(
        _title,
        'Titre',
        icon: Icons.edit_outlined,
        hint: 'Ex. Atelier de peinture',
      ),
      if (_suggestedTitle != null) ...[
        TextButton.icon(
          onPressed: _saving ? null : () => _title.text = _suggestedTitle!,
          icon: const Icon(Icons.auto_awesome, size: 16),
          label: Text(
            'Utiliser le titre proposé : $_suggestedTitle',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 12),
      ],
      _field(
        _location,
        'Lieu',
        icon: Icons.place_outlined,
        hint: 'Ex. Nice centre',
      ),
      _field(
        _capacity,
        'Nombre de personnes maximum',
        minimum: 1,
        icon: Icons.group_outlined,
      ),
      _field(_price, 'Prix (€)', minimum: 0, icon: Icons.euro_outlined),
      const SizedBox(height: 8),
      if (_error != null) ...[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
      ElevatedButton.icon(
        onPressed: _category == null || _classifying || _saving ? null : _save,
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check),
        label: Text(_saving ? 'Enregistrement…' : 'Valider'),
      ),
      if (_category == null) ...[
        const SizedBox(height: 12),
        const Text(
          'Choisissez une image et attendez sa catégorie pour valider.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFF65777B)),
        ),
      ],
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text(
          'Ajouter une activité',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Form(
            key: _form,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PageIntro(
                    icon: Icons.add_photo_alternate_outlined,
                    title: 'Une nouvelle activité.',
                    subtitle: 'Une photo, quelques informations et votre activité est prête.',
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 800) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _imageSection()),
                            const SizedBox(width: 24),
                            Expanded(child: _detailsSection()),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _imageSection(),
                          const SizedBox(height: 24),
                          _detailsSection(),
                        ],
                      );
                    },
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
