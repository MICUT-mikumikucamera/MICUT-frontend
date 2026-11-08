import 'dart:io';

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Figma `PhotoPlaceholder`. 경로가 있으면 실제 이미지를, 없으면 자리 표시용 Semantic 배경을 그린다.
/// [path]는 로컬 파일 경로, 네트워크 URL, 또는 `assets/` 로 시작하는 에셋 경로.
class PhotoPlaceholder extends StatefulWidget {
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
  State<PhotoPlaceholder> createState() => _PhotoPlaceholderState();
}

class _PhotoPlaceholderState extends State<PhotoPlaceholder> {
  ImageProvider? _image;
  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(PhotoPlaceholder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _resolve();
  }

  void _resolve() {
    final p = widget.path;
    _image = p == null || p.isEmpty
        ? null
        : p.startsWith('data:')
            ? MemoryImage(Uri.parse(p).data!.contentAsBytes())
            : p.startsWith('http') || p.startsWith('blob:')
                ? NetworkImage(p)
                : p.startsWith('assets/')
                    ? AssetImage(p)
                    : FileImage(File(p));
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: _image == null
              ? const ColoredBox(color: MiCutColors.bgPlaceholder)
              : Image(
                  image: _image!,
                  fit: widget.fit,
                  gaplessPlayback: true,
                  errorBuilder: _error)));
  Widget _error(BuildContext _, Object __, StackTrace? ___) =>
      const ColoredBox(color: MiCutColors.bgPlaceholder);
}
