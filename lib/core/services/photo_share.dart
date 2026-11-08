import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

/// Opens the platform share UI for the actual photo; never reports a fake success.
Future<void> sharePhoto(BuildContext context, String path,
    {String? text}) async {
  final box = context.findRenderObject();
  final origin = box is RenderBox && box.hasSize
      ? box.localToGlobal(Offset.zero) & box.size
      : const Rect.fromLTWH(0, 0, 1, 1);
  try {
    XFile photo;
    final uri = Uri.tryParse(path);
    if (uri?.scheme == 'data') {
      final data = UriData.parse(path);
      photo = XFile.fromData(data.contentAsBytes(),
          mimeType: data.mimeType, name: 'micut-photo.jpg');
    } else if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      final response = await http.get(uri);
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw StateError('Photo download failed');
      }
      photo = XFile.fromData(response.bodyBytes,
          mimeType: response.headers['content-type']?.split(';').first ??
              'image/jpeg',
          name: 'micut-photo.jpg');
    } else if (path.startsWith('assets/')) {
      final data = await rootBundle.load(path);
      photo = XFile.fromData(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          mimeType: path.endsWith('.png') ? 'image/png' : 'image/jpeg',
          name: path.split('/').last);
    } else {
      photo = XFile(path);
    }
    if (!context.mounted) return;
    await SharePlus.instance.share(ShareParams(
      files: [photo],
      text: text,
      sharePositionOrigin: origin,
      downloadFallbackEnabled: false,
    ));
  } catch (_) {
    if (context.mounted) {
      debugPrint('Photo action state changed.');
    }
  }
}
