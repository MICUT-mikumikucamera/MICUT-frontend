import 'package:flutter/material.dart';

enum MikuArtwork { loading, capture, empty, collection }

/// Original artwork from the November 18 Figma export, never a screen capture.
class MikuIllustration extends StatelessWidget {
  const MikuIllustration(this.artwork, {super.key, this.size = 205});
  final MikuArtwork artwork;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/figma-export/miku-${artwork == MikuArtwork.capture ? 'cheer' : artwork.name}.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      );
}
