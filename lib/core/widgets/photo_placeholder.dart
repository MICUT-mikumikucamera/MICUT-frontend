import 'dart:io';

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Figma `PhotoPlaceholder`. 경로가 있으면 실제 이미지를, 없으면 민트 박스를 그린다.
/// [path]는 로컬 파일 경로, 네트워크 URL, 또는 `assets/` 로 시작하는 에셋 경로.
class PhotoPlaceholder extends StatelessWidget {
  const PhotoPlaceholder({
    super.key,
    this.path,
    this.width,
    this.height,
    this.radius = Spacing.radiusSm,
    this.fit = BoxFit.cover,
    this.label = '사진',
    this.dark = false,
  });

  final String? path;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;
  final String label;

  /// 다크 월드(카메라/처리 중)에서 쓰면 어두운 박스.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    Widget child;
    final p = path;
    if (p == null || p.isEmpty) {
      child = ColoredBox(
        color: dark ? MiCutColors.darkSurface : MiCutColors.placeholder,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.image_outlined,
                size: 20,
                color: dark ? MiCutColors.hudDim : MiCutColors.cyan300,
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                label,
                style: MiCutText.label.copyWith(
                  color: dark ? MiCutColors.darkTextDim : MiCutColors.onPlaceholder,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (p.startsWith('http')) {
      child = Image.network(p, fit: fit, errorBuilder: _error);
    } else if (p.startsWith('assets/')) {
      child = Image.asset(p, fit: fit, errorBuilder: _error);
    } else {
      child = Image.file(File(p), fit: fit, errorBuilder: _error);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: width, height: height, child: child),
    );
  }

  Widget _error(BuildContext _, Object __, StackTrace? ___) => const ColoredBox(
        color: MiCutColors.placeholder,
        child: Center(
          child: Icon(Icons.broken_image_outlined, color: MiCutColors.cyan300),
        ),
      );
}
