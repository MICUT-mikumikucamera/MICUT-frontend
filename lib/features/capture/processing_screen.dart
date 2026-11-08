import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../core/widgets/micut_button.dart';
import '../../data/jobs/job.dart';
import '../../data/jobs/providers.dart';
import 'capture_view.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key, required this.jobId});
  final String jobId;
  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  StreamSubscription<Job>? _sub;
  bool _connectionFailed = false;

  @override
  void initState() {
    super.initState();
    _watch();
  }

  void _watch() {
    _sub?.cancel();
    setState(() => _connectionFailed = false);
    _sub = ref.read(jobRepositoryProvider).watch(widget.jobId).listen((job) {
      if (!mounted) return;
      if (job.status == JobStatus.done) {
        context.pushReplacement(Routes.resultOf(job.jobId));
      } else if (job.status == JobStatus.failed) {
        context.pushReplacement(Routes.failedOf(job.jobId));
      }
    }, onError: (_) {
      if (mounted) setState(() => _connectionFailed = true);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _close() async {
    await _sub?.cancel();
    // Closing the waiting view is not a supported server cancellation operation.
    if (mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) => CaptureView(
        photoPath: ref.watch(capturePhotoProvider(widget.jobId)),
        processing: !_connectionFailed,
        message: _connectionFailed ? '네트워크 연결을 확인해 주세요.' : '미쿠 사진을 만드는 중...',
        onClose: _close,
        actions: FractionallySizedBox(
            widthFactor: .5,
            child: MiCutButton(
              label: _connectionFailed ? '재시도' : '취소',
              type: MiCutButtonType.secondary,
              onPressed: _connectionFailed ? _watch : _close,
            )),
      );
}
