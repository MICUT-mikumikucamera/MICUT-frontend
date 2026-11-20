import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

Future<Uint8List> readPhotoBytes(String path) async {
  if (path.startsWith('data:')) return Uri.parse(path).data!.contentAsBytes();
  if (path.startsWith('assets/')) {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
  final uri = Uri.tryParse(path);
  if (uri?.scheme == 'http' || uri?.scheme == 'https') {
    final response = await http.get(uri!);
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw StateError('Image download failed (${response.statusCode})');
    }
    return response.bodyBytes;
  }
  return XFile(path).readAsBytes();
}

String photoDataUri(Uint8List bytes, {String mimeType = 'image/jpeg'}) =>
    'data:$mimeType;base64,${base64Encode(bytes)}';
