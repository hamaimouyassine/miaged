import 'dart:js_interop';
import 'dart:typed_data';

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

@JS('miagedClassifyActivity')
external JSPromise<JSString> _classify(JSString imageUrl);

Future<String> classifyActivity(String imageUrl) async {
  final category = await _classify(imageUrl.toJS).toDart;
  return category.toDart;
}
