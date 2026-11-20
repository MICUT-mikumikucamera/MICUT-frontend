import 'package:web/web.dart' as web;

Future<String?> readAppearance() async =>
    web.window.localStorage.getItem('micut.appearance');
Future<void> writeAppearance(String mode) async =>
    web.window.localStorage.setItem('micut.appearance', mode);
