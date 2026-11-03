import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api.dart';
import 'theme.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key, required this.demo});
  final bool demo;
  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  List<CameraDescription> _cameras = [];
  int _lens = 0, _countdown = 0, _generation = 0;
  bool _busy = false,
      _timerOn = false,
      _ready = false,
      _foreground = true,
      _picking = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recoverPicker();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _start();
    });
  }

  Future<void> _recoverPicker() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final response = await ImagePicker().retrieveLostData();
      if (!mounted) return;
      if (response.files?.isNotEmpty == true) await _use(response.files!.first);
    } catch (_) {
      if (mounted) setState(() => _error = '이전 사진을 복구하지 못했어요. 다시 선택해 주세요.');
    }
  }

  Future<void> _start() async {
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _error = null;
      _ready = true;
    });
    CameraController? next;
    try {
      await _camera?.dispose();
      _camera = null;
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw const ApiFailure('사용할 수 있는 카메라가 없어요. 앨범에서 사진을 선택해 주세요.');
      }
      if (!mounted || generation != _generation) return;
      next = CameraController(
        _cameras[_lens % _cameras.length],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await next.initialize();
      if (!mounted || generation != _generation || !_foreground) {
        await next.dispose();
        return;
      }
      _camera = next;
    } catch (_) {
      await next?.dispose();
      if (mounted && generation == _generation) {
        _error = '카메라를 열 수 없어요. 설정에서 카메라 권한을 허용하거나 앨범에서 사진을 선택해 주세요.';
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground && _camera != null) {
      final old = _camera;
      _camera = null;
      old?.dispose();
      if (mounted) setState(() {});
    } else if (_foreground &&
        _ready &&
        !_busy &&
        !_picking &&
        _camera == null) {
      _start();
    }
  }

  Future<void> _use(XFile file, {bool camera = false}) async {
    final bytes = await file.readAsBytes();
    final capture = await compute(
      camera ? Capture.fromCameraBytes : Capture.fromBytes,
      bytes,
    );
    if (mounted) Navigator.pop(context, capture);
  }

  Future<void> _pick() async {
    _picking = true;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file != null) await _use(file);
    } catch (e) {
      if (mounted) {
        _error = e is ApiFailure
            ? e.message
            : '사진을 불러오지 못했어요. 사진 접근 권한을 확인해 주세요.';
      }
    } finally {
      _picking = false;
      if (mounted) {
        setState(() {
          _busy = false;
        });
        if (_foreground && _ready && _camera == null) unawaited(_start());
      }
    }
  }

  Future<void> _take() async {
    if (_camera?.value.isInitialized != true || _busy) return;
    setState(() => _busy = true);
    try {
      if (_timerOn) {
        for (var i = 3; i > 0; i--) {
          if (!mounted || _camera == null) return;
          setState(() => _countdown = i);
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
      if (!mounted || _camera == null) return;
      setState(() => _countdown = 0);
      await _use(await _camera!.takePicture(), camera: true);
    } catch (_) {
      if (mounted) _error = '촬영하지 못했어요. 카메라를 다시 열어 주세요.';
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _countdown = 0;
        });
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ink,
    appBar: AppBar(
      backgroundColor: ink,
      foregroundColor: Colors.white,
      leading: IconButton(
        tooltip: '닫기',
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close),
      ),
      actions: [
        IconButton(
          tooltip: '카메라 전환',
          onPressed: _busy || _cameras.length < 2
              ? null
              : () {
                  _lens++;
                  _start();
                },
          icon: const Icon(Icons.cameraswitch_outlined),
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Center(
                child: AspectRatio(
                  aspectRatio: Capture.cameraAspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_camera?.value.isInitialized == true)
                        ClipRect(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _camera!.value.previewSize!.height,
                              height: _camera!.value.previewSize!.width,
                              child: CameraPreview(_camera!),
                            ),
                          ),
                        )
                      else
                        ColoredBox(
                          color: const Color(0xFF393939),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    _error ?? '',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (!_busy)
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: _start,
                                      child: Text(
                                        _ready ? '카메라 다시 열기' : '카메라 열기',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (_camera?.value.isInitialized == true)
                        const IgnorePointer(
                          child: CustomPaint(painter: _GridPainter()),
                        ),
                      if (_countdown > 0)
                        Center(
                          child: Text(
                            '$_countdown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 80,
                            ),
                          ),
                        ),
                      if (_busy && _countdown == 0)
                        const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      if (_camera?.value.isInitialized == true)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 24,
                          child: Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: const Text(
                              '사람과 발이 함께 보이도록 찍어 주세요',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _cameraAction(
                  _timerOn ? Icons.timer : Icons.timer_outlined,
                  _timerOn ? '3초' : '타이머',
                  _busy ? null : () => setState(() => _timerOn = !_timerOn),
                ),
                Semantics(
                  button: true,
                  label: '사진 촬영',
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(5),
                        shape: const CircleBorder(),
                        side: const BorderSide(color: Colors.white, width: 2),
                      ),
                      onPressed: _busy || _camera?.value.isInitialized != true
                          ? null
                          : _take,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _camera?.value.isInitialized == true
                              ? Colors.white
                              : Colors.white38,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                _cameraAction(
                  Icons.photo_library_outlined,
                  '앨범',
                  _busy ? null : _pick,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Widget _cameraAction(IconData icon, String label, VoidCallback? action) =>
      TextButton(
        onPressed: action,
        style: TextButton.styleFrom(foregroundColor: Colors.white),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
}

class _GridPainter extends CustomPainter {
  const _GridPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 0.5;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(size.width * i / 3, 0),
        Offset(size.width * i / 3, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, size.height * i / 3),
        Offset(size.width, size.height * i / 3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
