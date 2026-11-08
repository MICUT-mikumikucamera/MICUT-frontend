import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'photo_bytes.dart';

/// Starts a browser download; browsers do not report whether the user kept it.
Future<void> downloadPhoto(Uint8List bytes, String name) async {
  final anchor = web.HTMLAnchorElement()
    ..href = photoDataUri(bytes)
    ..download = name;
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
}
