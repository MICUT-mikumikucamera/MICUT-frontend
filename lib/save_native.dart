import 'dart:typed_data';
import 'package:gal/gal.dart';

Future<void> saveImage(Uint8List bytes, String name) =>
    Gal.putImageBytes(bytes, name: name);
