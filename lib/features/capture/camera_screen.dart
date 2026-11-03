import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/dark_world.dart';
import '../../core/widgets/hud_frame.dart';
import 'capture_guide_screen.dart';

/// Figma 02 촬영 + 03 사진 선택(앨범 버튼 → image_picker)
///
/// 다크 월드. 프리뷰 위에 로고의 뷰파인더 코너 HUD, 안내 바는 시안 면 + 검정 글자,
/// 셔터는 흰 원 + 시안 링.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  String? _error;
  bool _busy = false;
  int _timerSec = 0; // 0 / 3 / 10
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() => _error = '사용할 수 있는 카메라가 없어요');
        return;
      }
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      final c = CameraController(back, ResolutionPreset.high, enableAudio: false);
      await c.initialize();
      if (!mounted) return;
      setState(() => _controller = c);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.code == 'CameraAccessDenied'
          ? '카메라 권한이 필요해요. 설정에서 허용해주세요.'
          : '카메라를 열지 못했어요 (${e.code})');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      c.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _init();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _shoot() async {
    final c = _controller;
    if (c == null || _busy) return;
    setState(() => _busy = true);
    try {
      for (var s = _timerSec; s > 0; s--) {
        setState(() => _countdown = s);
        await Future<void>.delayed(const Duration(seconds: 1));
        if (!mounted) return;
      }
      setState(() => _countdown = 0);
      final x = await c.takePicture();
      if (!mounted) return;
      context.push(Routes.captureConfirm, extra: File(x.path));
    } on CameraException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('촬영 실패 (${e.code})')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFromAlbum() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x == null || !mounted) return;
    context.push(Routes.captureConfirm, extra: File(x.path));
  }

  void _cycleTimer() =>
      setState(() => _timerSec = switch (_timerSec) { 0 => 3, 3 => 10, _ => 0 });

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final ready = c != null && c.value.isInitialized;

    return DarkWorld(
      child: Scaffold(
        backgroundColor: MiCutColors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 프리뷰
            if (ready)
              Center(child: CameraPreview(c))
            else
              Center(
                child: _error == null
                    ? const CircularProgressIndicator()
                    : Padding(
                        padding: const EdgeInsets.all(Spacing.xl),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: MiCutText.body.copyWith(color: MiCutColors.darkText),
                        ),
                      ),
              ),

            // 뷰파인더 코너 HUD (로고 페이지 "HUD / 2 Viewfinder Corners")
            if (ready)
              const IgnorePointer(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(Spacing.lg, 96, Spacing.lg, 230),
                  child: HudCorners(length: 28, thickness: 2),
                ),
              ),

            // 타이머 카운트다운
            if (_countdown > 0)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$_countdown',
                        style: MiCutText.display.copyWith(
                          color: MiCutColors.hud,
                          fontSize: 88,
                          shadows: const [Shadow(color: MiCutColors.hud, blurRadius: 24)],
                        )),
                    Text('T-MINUS', style: MiCutText.hud),
                  ],
                ),
              ),

            SafeArea(
              child: Column(
                children: [
                  // 상단 바
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => context.pop(),
                        ),
                        const HudStatus(text: 'REC', blinking: true),
                        IconButton(
                          icon: const Icon(Icons.help_outline),
                          onPressed: () => context.push(Routes.captureGuide),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // 안내 바: 시안 면 + 검정 글자 (브랜드 조합, 대비 ≥ 15)
                  Container(
                    width: double.infinity,
                    color: MiCutColors.hud,
                    padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                    child: Text(
                      CaptureGuideScreen.guideText,
                      textAlign: TextAlign.center,
                      style: MiCutText.bodyBold.copyWith(color: MiCutColors.ink),
                    ),
                  ),

                  // 컨트롤 영역
                  Container(
                    height: 170,
                    color: MiCutColors.ink,
                    padding: const EdgeInsets.symmetric(horizontal: 42),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Side(
                          label: _timerSec == 0 ? '타이머' : '${_timerSec}s',
                          icon: Icons.timer_outlined,
                          active: _timerSec != 0,
                          onTap: _cycleTimer,
                        ),
                        _Shutter(enabled: ready && !_busy, onTap: _shoot),
                        _Side(
                          label: '앨범',
                          icon: Icons.photo_outlined,
                          onTap: _pickFromAlbum,
                          square: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Shutter extends StatelessWidget {
  const _Shutter({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '촬영',
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.4,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: Spacing.shutter,
            height: Spacing.shutter,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: MiCutColors.white,
              boxShadow: MiCutShadows.glowHud,
            ),
            child: Center(
              child: Container(
                width: Spacing.shutter - 12,
                height: Spacing.shutter - 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: MiCutColors.hud, width: 3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({
    required this.label,
    required this.icon,
    required this.onTap,
    this.square = false,
    this.active = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool square;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final fg = active ? MiCutColors.ink : MiCutColors.hud;
    final bg = active ? MiCutColors.hud : MiCutColors.darkSurfaceHi;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              shape: square ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: square ? BorderRadius.circular(Spacing.radiusSm) : null,
            ),
            child: Icon(icon, color: fg, size: 20),
          ),
          const SizedBox(height: Spacing.xs),
          Text(label, style: MiCutText.label.copyWith(color: MiCutColors.darkTextDim)),
        ],
      ),
    );
  }
}
