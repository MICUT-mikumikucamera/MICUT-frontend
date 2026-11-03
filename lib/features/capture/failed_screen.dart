import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/micut_button.dart';
import '../../data/jobs/job.dart';
import '../../data/jobs/providers.dart';

/// 05-F 처리 실패 (와이어프레임 없음 — 디자인 요청 중).
/// 라이트 월드로 돌아와서 "카메라 모드가 끝났다"는 걸 색으로도 알린다. 실패 표시는 Secondary(핑크).
///
/// error.retryable 에 따라 버튼이 달라진다:
///   retryable  → [다시 찍기] [다시 시도]
///   !retryable → [다시 찍기]
/// 재시도 없이 나가면 discard 호출 (계약 규칙).
class FailedScreen extends ConsumerStatefulWidget {
  const FailedScreen({super.key, required this.jobId});
  final String jobId;

  @override
  ConsumerState<FailedScreen> createState() => _FailedScreenState();
}

class _FailedScreenState extends ConsumerState<FailedScreen> {
  Job? _job;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ref.read(jobRepositoryProvider).getJob(widget.jobId).then((j) {
      if (mounted) setState(() => _job = j);
    });
  }

  Future<void> _retry() async {
    setState(() => _busy = true);
    try {
      await ref.read(jobRepositoryProvider).retry(widget.jobId);
      if (mounted) context.pushReplacement(Routes.processingOf(widget.jobId));
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('다시 시도하지 못했어요')));
      }
    }
  }

  Future<void> _retake() async {
    await ref.read(jobRepositoryProvider).discard(widget.jobId);
    if (mounted) context.pushReplacement(Routes.captureCamera);
  }

  Future<void> _close() async {
    await ref.read(jobRepositoryProvider).discard(widget.jobId);
    if (mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final err = _job?.error;
    final retryable = err?.retryable ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _close),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.screenH),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: MiCutColors.secondarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 44, color: MiCutColors.secondary),
            ),
            const SizedBox(height: Spacing.xl),
            Text(
              err?.message ?? '문제가 생겼어요',
              textAlign: TextAlign.center,
              style: MiCutText.h3,
            ),
            if (err != null) ...[
              const SizedBox(height: Spacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
                decoration: BoxDecoration(
                  color: MiCutColors.surface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(err.code, style: MiCutText.label),
              ),
            ],
            const Spacer(),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: Spacing.xl),
                child: Row(
                  children: [
                    Expanded(
                      child: MiCutButton(
                        label: '다시 찍기',
                        type: retryable
                            ? MiCutButtonType.secondary
                            : MiCutButtonType.primary,
                        onPressed: _busy ? null : _retake,
                      ),
                    ),
                    if (retryable) ...[
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: MiCutButton(
                          label: '다시 시도',
                          loading: _busy,
                          onPressed: _retry,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
