import 'dart:typed_data';

import 'activity_analysis.dart';

Future<Uint8List?> pickActivityImage(int maxBytes) async {
  throw UnsupportedError('La sélection est disponible dans le navigateur.');
}

Future<ActivityAnalysis> analyzeActivity(String imageUrl) async {
  throw UnsupportedError(
    'La classification est disponible dans le navigateur.',
  );
}

Future<Uint8List> downloadActivityImage(String url, int maxBytes) async {
  throw UnsupportedError(
    'L’import par lien est disponible dans le navigateur.',
  );
}
