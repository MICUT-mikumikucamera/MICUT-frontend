import '../../core/widgets/micut_icon.dart';
import '../../core/widgets/micut_dialog.dart';
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/dark_world.dart';
import 'capture_crop.dart';
import 'capture_option_picker.dart';

enum CaptureRatio {
  portrait('4:3', 3 / 4),
  square('1:1', 1),
  tall('16:9', 9 / 16);

  const CaptureRatio(this.label, this.value);
  final String label;
  final double value;
}

CameraController _makeController(CameraDescription description) =>
    CameraController(description, ResolutionPreset.high, enableAudio: false);

class CameraScreen extends StatefulWidget {
  const CameraScreen(
      {super.key,
      this.cameraLoader = availableCameras,
      this.controllerFactory = _makeController});
  final Future<List<CameraDescription>> Function() cameraLoader;
  final CameraController Function(CameraDescription) controllerFactory;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  CameraDescription? _selected;
  Future<void> _cameraTask = Future.value();
  int _generation = 0;
  bool _active = true;
  bool _changing = true;
  bool _busy = false;
  bool _permissionDialogOpen = false;
  bool _flashSupported = true;
  FlashMode _flash = FlashMode.off;
  CaptureRatio _ratio = CaptureRatio.portrait;
  int _timerSec = 0;
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _openCamera();
  }

  bool _current(int generation) =>
      mounted && _active && generation == _generation;

  Future<void> _openCamera([CameraDescription? requested]) {
    final generation = ++_generation;
    setState(() {
      _changing = true;
    });
    _cameraTask = _cameraTask.then((_) async {
      if (!_current(generation)) return;
      CameraController? candidate;
      try {
        final previous = _controller;
        setState(() => _controller = null);
        await previous?.dispose();
        if (!_current(generation)) return;
        if (_cameras.isEmpty) _cameras = await widget.cameraLoader();
        if (!_current(generation)) return;
        if (_cameras.isEmpty) {
          throw CameraException('NoCamera', '사용할 수 있는 카메라가 없어요');
        }
        final selected = requested ??
            _selected ??
            _cameras.firstWhere(
                (camera) => camera.lensDirection == CameraLensDirection.back,
                orElse: () => _cameras.first);
        candidate = widget.controllerFactory(selected);
        await candidate.initialize();
        if (!_current(generation)) {
          await candidate.dispose();
          return;
        }
        var flashSupported = true;
        var appliedFlash = _flash;
        try {
          await candidate.setFlashMode(appliedFlash);
        } on CameraException {
          appliedFlash = FlashMode.off;
          try {
            await candidate.setFlashMode(FlashMode.off);
          } on CameraException {
            /* Browser/front lenses can have no flash API. */
          }
          flashSupported = false;
        }
        if (!_current(generation)) {
          await candidate.dispose();
          return;
        }
        setState(() {
          _controller = candidate;
          _selected = selected;
          _flash = appliedFlash;
          _flashSupported = flashSupported;
          _changing = false;
        });
      } catch (error) {
        await candidate?.dispose();
        if (!_current(generation)) return;
        setState(() => _changing = false);
        final permissionDenied = error is CameraException &&
            (error.code.startsWith('CameraAccessDenied') ||
                error.code == 'CameraAccessRestricted');
        if (permissionDenied) unawaited(_showPermissionDialog());
      }
    });
    return _cameraTask;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _active = false;
      ++_generation;
      final controller = _controller;
      setState(() {
        _controller = null;
        _busy = false;
        _countdown = 0;
      });
      _cameraTask = _cameraTask.then((_) async {
        await controller?.dispose();
      });
    } else if (state == AppLifecycleState.resumed && !_active) {
      _active = true;
      _openCamera(_selected);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _active = false;
    ++_generation;
    final controller = _controller;
    _cameraTask.then((_) async {
      await controller?.dispose();
    });
    super.dispose();
  }

  Future<void> _showPermissionDialog() async {
    if (!mounted || _permissionDialogOpen) return;
    _permissionDialogOpen = true;
    try {
      await showDialog<void>(
        context: context,
        barrierColor: MiCutColors.modalDim,
        useSafeArea: false,
        builder: (dialogContext) => MiCutDialog(
          title: '권한 확인',
          message: '카메라 권한을 확인해 주세요. 확인 클릭시 설정 화면으로 이동합니다.',
          confirmLabel: '확인',
          onConfirm: kIsWeb
              ? null
              : () async {
                  final opened = await openAppSettings();
                  if (opened && dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
        ),
      );
    } finally {
      _permissionDialogOpen = false;
    }
  }

  void _notice(String message) {
    debugPrint(message);
  }

  Future<void> _setFlash(FlashMode next) async {
    final controller = _controller;
    if (controller == null || _busy || _changing) return;
    final generation = _generation;
    setState(() => _busy = true);
    try {
      await controller.setFlashMode(next);
      if (_current(generation)) setState(() => _flash = next);
    } on CameraException {
      if (_current(generation)) _notice('이 카메라는 선택한 플래시 모드를 지원하지 않아요.');
    } finally {
      if (_current(generation)) setState(() => _busy = false);
    }
  }

  CameraDescription? get _opposite {
    final direction = _selected?.lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    for (final camera in _cameras) {
      if (camera.lensDirection == direction) return camera;
    }
    // External webcams can expose multiple cameras without front/back metadata.
    for (final camera in _cameras) {
      if (camera.name != _selected?.name) return camera;
    }
    return null;
  }

  Future<void> _shoot() async {
    final controller = _controller;
    if (controller == null || _busy || _changing) return;
    final generation = _generation;
    final ratio = _ratio.value;
    setState(() => _busy = true);
    try {
      for (var seconds = _timerSec; seconds > 0; seconds--) {
        setState(() => _countdown = seconds);
        await Future<void>.delayed(const Duration(seconds: 1));
        if (!_current(generation)) return;
      }
      setState(() => _countdown = 0);
      final original = await controller.takePicture();
      final originalBytes = await original.readAsBytes();
      final draft =
          await compute(prepareCaptureRequest, (originalBytes, ratio));
      if (!mounted || !_current(generation)) return;
      await context.push(Routes.captureConfirm, extra: draft);
    } catch (_) {
      if (_current(generation)) _notice('사진을 촬영하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (_current(generation)) {
        setState(() {
          _busy = false;
          _countdown = 0;
        });
      }
    }
  }

  Future<void> _pickFromAlbum() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final photo = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (photo == null || !mounted) return;
      final draft = await compute(
          prepareCaptureRequest, (await photo.readAsBytes(), null));
      if (!mounted) return;
      await context.push(Routes.captureConfirm, extra: draft);
    } catch (_) {
      _notice('앨범을 열지 못했어요. 권한을 확인해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    final enabled = !_busy && !_changing;
    final flashLabel = switch (_flash) {
      FlashMode.auto => '자동',
      FlashMode.always => '켜기',
      _ => '끄기'
    };
    return DarkWorld(
        child: Scaffold(
      backgroundColor: MiCutColors.black,
      body: SafeArea(
          child: Column(children: [
        SizedBox(
            height: 45,
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                          tooltip: '닫기',
                          alignment: Alignment.center,
                          padding: EdgeInsets.zero,
                          icon: const MiCutIcon(Icons.close),
                          onPressed: () => context.pop()),
                      IconButton(
                          tooltip: '촬영 안내',
                          alignment: Alignment.center,
                          padding: EdgeInsets.zero,
                          icon: const MiCutIcon(Icons.help_outline),
                          onPressed: () => context.push(Routes.captureGuide)),
                    ]))),
        Expanded(child: LayoutBuilder(builder: (context, constraints) {
          final width = (constraints.maxHeight * _ratio.value)
              .clamp(0.0, constraints.maxWidth);
          return Center(
              child: SizedBox(
                  width: width,
                  height: width / _ratio.value,
                  child: Stack(fit: StackFit.expand, children: [
                    if (ready)
                      ClipRect(
                          child: FittedBox(
                              fit: BoxFit.cover, child: _preview(controller)))
                    else
                      ColoredBox(
                          color: MiCutColors.darkSurface,
                          child: Center(
                              child: _changing
                                  ? const CircularProgressIndicator()
                                  : const SizedBox.shrink())),
                    Positioned.fill(
                      child: CaptureOptionsRail(groups: [
                        CaptureOptionGroup(
                          id: 'flash',
                          tooltip: '플래시 $flashLabel',
                          selectedIndex: [
                            FlashMode.off,
                            FlashMode.always,
                            FlashMode.auto
                          ].indexOf(_flash),
                          enabled: ready && enabled && _flashSupported,
                          options: const [
                            CaptureOption(asset: 'flash-off', label: '플래시 끄기'),
                            CaptureOption(asset: 'flash-on', label: '플래시 켜기'),
                            CaptureOption(asset: 'flash-auto', label: '플래시 자동'),
                          ],
                          onSelected: (i) => _setFlash([
                            FlashMode.off,
                            FlashMode.always,
                            FlashMode.auto
                          ][i]),
                        ),
                        CaptureOptionGroup(
                          id: 'timer',
                          tooltip:
                              _timerSec == 0 ? '타이머 끄기' : '타이머 $_timerSec초',
                          selectedIndex: [0, 3, 5, 7].indexOf(_timerSec),
                          enabled: enabled,
                          options: const [
                            CaptureOption(asset: 'timer-0', label: '타이머 끄기'),
                            CaptureOption(asset: 'timer-3', label: '타이머 3초'),
                            CaptureOption(asset: 'timer-5', label: '타이머 5초'),
                            CaptureOption(asset: 'timer-7', label: '타이머 7초'),
                          ],
                          onSelected: (i) =>
                              setState(() => _timerSec = [0, 3, 5, 7][i]),
                        ),
                        CaptureOptionGroup(
                          id: 'ratio',
                          edgePadding: 4,
                          tooltip: '사진 비율 ${_ratio.label}',
                          selectedIndex: _ratio.index,
                          enabled: enabled,
                          options: [
                            for (final ratio in CaptureRatio.values)
                              CaptureOption(
                                  asset: 'ratio-${ratio.name}',
                                  label: '사진 비율 ${ratio.label}')
                          ],
                          onSelected: (i) =>
                              setState(() => _ratio = CaptureRatio.values[i]),
                        ),
                      ]),
                    ),
                    if (_countdown > 0)
                      Center(
                          child: Text('$_countdown',
                              style: MiCutText.display
                                  .copyWith(color: MiCutColors.textInverse))),
                  ])));
        })),
        SizedBox(
            height: 146,
            child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.screenH, vertical: 26),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                          tooltip: '앨범',
                          icon: const MiCutIcon(Icons.photo_outlined),
                          onPressed: _busy ? null : _pickFromAlbum),
                      _Shutter(enabled: ready && enabled, onTap: _shoot),
                      IconButton(
                          tooltip: '전후면 카메라 전환',
                          icon: const MiCutIcon(Icons.cameraswitch_outlined),
                          onPressed: ready && enabled && _opposite != null
                              ? () => _openCamera(_opposite)
                              : null),
                    ]))),
      ])),
    ));
  }

  Widget _preview(CameraController controller) {
    final value = controller.value;
    final orientation =
        value.lockedCaptureOrientation ?? value.deviceOrientation;
    final landscape = orientation == DeviceOrientation.landscapeLeft ||
        orientation == DeviceOrientation.landscapeRight;
    final size = value.previewSize!;
    return SizedBox(
        width: landscape ? size.width : size.height,
        height: landscape ? size.height : size.width,
        child: CameraPreview(controller));
  }
}

class _Shutter extends StatelessWidget {
  const _Shutter({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      enabled: enabled,
      label: '촬영',
      child: SizedBox(
          width: Spacing.shutter,
          height: Spacing.shutter,
          child: Material(
              color: enabled ? MiCutColors.white : MiCutColors.gray400,
              shape: const CircleBorder(
                  side: BorderSide(color: MiCutColors.cyan300, width: 4)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: enabled ? onTap : null))));
}
