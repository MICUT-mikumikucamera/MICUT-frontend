import 'package:flutter/material.dart';

/// 디자인팀 SD 미쿠 일러스트 (Figma 디자인 페이지 `일러스트` 섹션, 2026-11-17).
/// 캐릭터는 코드로 그리지 않고 이 에셋만 쓴다.
enum MikuIllust {
  /// 미쿠_로딩 — 04 처리 중
  loading('miku-loading'),

  /// 미쿠_촬영/신규 컬렉션 획득 — 08 홈 촬영 타일, 05-1 신규 컬렉션
  cheer('miku-cheer'),

  /// 미쿠_세션 만료/결과 없음 — 01 촬영 가이드, 09-1 갤러리 빈 상태
  empty('miku-empty'),

  /// 미쿠_컬렉션 — 08 홈 컬렉션 타일
  collection('miku-collection');

  const MikuIllust(this.assetName);
  final String assetName;
  String get path => 'assets/figma-export/$assetName.png';
}

/// 정사각형 일러스트. 장식이라 스크린리더에서는 숨긴다.
class MikuIllustImage extends StatelessWidget {
  const MikuIllustImage(this.illust, {super.key, required this.size});
  final MikuIllust illust;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Image.asset(illust.path,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium),
      );
}
