import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

String? base64Worker(Uint8List bytes) {
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    // 🔥 resize SEKALI (tidak loop)
    final resized = img.copyResize(
      decoded,
      width: 200, // adjust sesuai cell
      interpolation: img.Interpolation.average,
    );

    final jpg = img.encodeJpg(resized, quality: 70);
    final b64 = base64Encode(jpg);

    return b64.length <= 32000 ? b64 : null;
  } catch (_) {
    return null;
  }
}

Future<String?> shrinkToBase64(Uint8List bytes) {
  return compute(base64Worker, bytes);
}

Uint8List readFileBytes(String path) {
  return File(path).readAsBytesSync();
}
