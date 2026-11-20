import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<File> _file() async =>
    File('${(await getApplicationSupportDirectory()).path}/appearance.txt');
Future<String?> readAppearance() async {
  final file = await _file();
  return await file.exists() ? file.readAsString() : null;
}

Future<void> writeAppearance(String mode) async {
  final file = await _file();
  await file.parent.create(recursive: true);
  await file.writeAsString(mode, flush: true);
}
