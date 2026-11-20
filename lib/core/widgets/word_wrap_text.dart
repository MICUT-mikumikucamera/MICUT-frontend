import 'package:flutter/material.dart';

/// Keep Korean words together while allowing lines to break at spaces.
class WordWrapText extends StatelessWidget {
  const WordWrapText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final display = text.replaceAllMapped(
        RegExp(r'\S+'), (match) => match[0]!.characters.join('\u2060'));
    return Text(display, style: style, semanticsLabel: text);
  }
}
