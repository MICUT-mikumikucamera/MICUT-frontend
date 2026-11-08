import 'capture_crop.dart';
import '../../core/services/photo_bytes.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

import '../../core/theme/spacing.dart';

import '../../core/widgets/micut_button.dart';
import 'capture_view.dart';
import '../../data/jobs/job.dart';
import '../../data/jobs/providers.dart';

/// 사진 확인: 원본 사진과 흰색 안내 영역.
class ConfirmScreen extends ConsumerStatefulWidget {
  const ConfirmScreen({super.key, required this.draft});
  final CaptureDraft draft;

  @override
  ConsumerState<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends ConsumerState<ConfirmScreen> {
  bool _uploading = false;
  String? _preview;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      final bytes = widget.draft.previewBytes;
      if (mounted) setState(() => _preview = photoDataUri(bytes));
    } catch (_) {
      if (mounted) {
        debugPrint('Photo preview could not load');
      }
    }
  }

  Future<void> _create() async {
    if (_uploading) return;
    setState(() {
      _uploading = true;
      _errorMessage = null;
    });
    try {
      final capture = widget.draft.capture;
      final job = await ref
          .read(jobRepositoryProvider)
          .createJob(widget.draft.original, capture);
      final preview = _preview ?? photoDataUri(widget.draft.previewBytes);
      if (!mounted) return;
      ref.read(capturePhotoProvider(job.jobId).notifier).state = preview;
      context.pushReplacement(Routes.processingOf(job.jobId));
    } on UploadException {
      // 업로드 실패는 job 없음 → 메시지만 보여주고 이 화면에 머문다
      if (mounted) {
        setState(() => _errorMessage = '처리에 실패했어요. 다시 시도해 주세요.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = '네트워크 연결을 확인해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) => CaptureView(
        photoPath: _preview,
        message: _errorMessage ?? '이 사진에 미쿠를 불러올까요?',
        onClose: _uploading ? null : () => context.pop(),
        actions: Row(children: [
          Expanded(
              child: MiCutButton(
                  label: '다시 찍기',
                  type: MiCutButtonType.secondary,
                  onPressed: _uploading ? null : () => context.pop())),
          const SizedBox(width: Spacing.md),
          Expanded(
              child: MiCutButton(
                  label: _errorMessage == null ? '확인' : '재시도',
                  loading: _uploading,
                  onPressed: _uploading ? null : _create)),
        ]),
      );
}
