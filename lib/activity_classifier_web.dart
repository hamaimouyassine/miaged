import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:convert';

import 'activity_analysis.dart';

@JS('miagedPickActivityImage')
external JSPromise<JSUint8Array?> _pick(JSNumber maxBytes);

Future<Uint8List?> pickActivityImage(int maxBytes) async {
  final bytes = await _pick(maxBytes.toJS).toDart;
  return bytes?.toDart;
}

@JS('miagedDownloadActivityImage')
external JSPromise<JSUint8Array> _download(JSString url, JSNumber maxBytes);

Future<Uint8List> downloadActivityImage(String url, int maxBytes) async {
  final bytes = await _download(url.toJS, maxBytes.toJS).toDart;
  return bytes.toDart;
}

@JS('miagedAnalyzeActivity')
external JSPromise<JSString> _analyze(JSString imageUrl);

Future<ActivityAnalysis> analyzeActivity(String imageUrl) async {
  final result = await _analyze(imageUrl.toJS).toDart;
  return ActivityAnalysis.fromJson(
    jsonDecode(result.toDart) as Map<String, dynamic>,
  );
}
