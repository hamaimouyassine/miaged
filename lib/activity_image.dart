import 'dart:typed_data';

import 'package:flutter/material.dart';

ImageProvider activityImage(String url) {
  try {
    final data = Uri.tryParse(url)?.data;
    if (data != null) {
      return MemoryImage(Uint8List.fromList(data.contentAsBytes()));
    }
  } on FormatException {
    // Les données invalides seront affichées par le errorBuilder de l’image.
    return MemoryImage(Uint8List(0));
  }
  return NetworkImage(
    url,
    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
  );
}
