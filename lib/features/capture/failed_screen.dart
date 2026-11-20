import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../core/widgets/micut_button.dart';
import '../../data/jobs/job.dart';
import '../../data/jobs/providers.dart';
import 'capture_view.dart';

class FailedScreen extends ConsumerStatefulWidget {
  const FailedScreen({super.key, required this.jobId});
  final String jobId;
  @override
  ConsumerState<FailedScreen> createState() => _FailedScreenState();
}

class _FailedScreenState extends ConsumerState<FailedScreen> {
  Job? _job;
  bool _busy = false;
  bool _loadFailed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    try {
      final job = await ref.read(jobRepositoryProvider).getJob(widget.jobId);
      if (mounted) setState(() => _job = job);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(jobRepositoryProvider).retry(widget.jobId);
      if (mounted) context.pushReplacement(Routes.processingOf(widget.jobId));
    } catch (_) {
      if (mounted) {
        setState(() => _loadFailed = true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(jobRepositoryProvider).discard(widget.jobId);
      if (!mounted) return;
      context.go(Routes.home);
    } catch (_) {
      if (mounted) {
        setState(() => _loadFailed = true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final retryable = _job?.error?.retryable ?? false;
    return CaptureView(
      photoPath: ref.watch(capturePhotoProvider(widget.jobId)),
      message: _loadFailed ? '네트워크 연결을 확인해 주세요.' : '처리에 실패했어요. 다시 시도해 주세요.',
      onClose: _busy ? null : _leave,
      actions: FractionallySizedBox(
          widthFactor: .5,
          child: MiCutButton(
            label: '재시도',
            type: MiCutButtonType.secondary,
            loading: _busy,
            onPressed: _busy
                ? null
                : _loadFailed
                    ? _load
                    : _job == null
                        ? null
                        : retryable
                            ? _retry
                            : null,
          )),
    );
  }
}
