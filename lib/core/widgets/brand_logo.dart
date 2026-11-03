import 'package:flutter/material.dart';

/// MiCut 워드마크 (Figma 로고 페이지에서 내보낸 PNG, assets/brand).
///
/// 배경에 따라 변형을 고른다:
///  - [BrandLogoVariant.black]  흰 배경 (홈 헤더)
///  - [BrandLogoVariant.cyan]   순흑 배경 (촬영 가이드·처리 중·스플래시) — 로고 원본과 같은 조합
///  - [BrandLogoVariant.white]  어두운 사진 위
///  - [BrandLogoVariant.pink]   흰 배경 포인트 (반전 로고)
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.variant = BrandLogoVariant.black,
    this.height = 22,
  });

  final BrandLogoVariant variant;
  final double height;

  static const _assets = {
    BrandLogoVariant.black: 'assets/brand/logo_wordmark_black.png',
    BrandLogoVariant.cyan: 'assets/brand/logo_wordmark_cyan.png',
    BrandLogoVariant.white: 'assets/brand/logo_wordmark_white.png',
    BrandLogoVariant.pink: 'assets/brand/logo_wordmark_pink.png',
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'MiCut',
      image: true,
      child: Image.asset(
        _assets[variant]!,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

enum BrandLogoVariant { black, cyan, white, pink }
