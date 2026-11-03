import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/dark_world.dart';
import '../../core/widgets/hud_frame.dart';
import '../../core/widgets/micut_button.dart';
import '../../data/jobs/job.dart';
import '../../data/jobs/providers.dart';

/// Figma 05 처리 중. job을 폴링하다가 done → 06, failed → 05-F 로 이동.
///
/// 다크 월드. 로고 페이지의 "AF Focus Box"가 숨 쉬듯 커졌다 작아지며
/// "장면을 읽고 → 미쿠를 그리는" 상태를 HUD 마이크로 텍스트로 보여준다.
///
/// TODO(디자인 피드백): 대기 중 미쿠 예시 이미지 캐러셀. 처리 시간 확정 후 [_Examples] 자리에 넣는다.
class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key, required this.jobId});
  final String jobId;

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription<Job>? _sub;
  JobStatus _status = JobStatus.pending;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _sub = ref.read(jobRepositoryProvider).watch(widget.jobId).listen(
      (job) {
        if (!mounted) return;
        setState(() => _status = job.status);
        if (job.status == JobStatus.done) {
          context.pushReplacement(Routes.resultOf(job.jobId));
        } else if (job.status == JobStatus.failed) {
          context.pushReplacement(Routes.failedOf(job.jobId));
        }
      },
      onError: (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('연결이 끊겼어요. 잠시 후 다시 시도해주세요')));
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    await _sub?.cancel();
    await ref.read(jobRepositoryProvider).discard(widget.jobId);
    if (mounted) context.go(Routes.home);
  }

  String get _hudText => switch (_status) {
        JobStatus.pending => 'UPLOADING',
        JobStatus.processing => 'ANALYZING SCENE',
        JobStatus.done => 'DONE',
        JobStatus.failed => 'FAILED',
      };

  @override
  Widget build(BuildContext context) {
    return DarkWorld(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: Spacing.lg),
              HudStatus(text: _hudText),
              const Spacer(),

              // 숨 쉬는 AF 포커스 박스
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) {
                  final t = Curves.easeInOut.transform(_pulse.value);
                  return Transform.scale(scale: 0.92 + 0.08 * t, child: child);
                },
                child: const HudFocusBox(size: 200, label: 'AF · MIKU'),
              ),
              const SizedBox(height: Spacing.xxl),
              SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: MiCutColors.hudFaint,
                  ),
                ),
              ),

              const Spacer(),
              Text('미쿠 사진을 만드는 중이에요',
                  style: MiCutText.h2.copyWith(color: MiCutColors.darkText)),
              const SizedBox(height: Spacing.sm),
              Text(
                _status == JobStatus.pending ? '사진을 보내고 있어요' : '장면을 읽고 미쿠를 그리고 있어요',
                style: MiCutText.caption.copyWith(color: MiCutColors.darkTextDim),
              ),
              const SizedBox(height: Spacing.xxl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.screenH),
                child: SizedBox(
                  width: 157,
                  child: MiCutButton(
                    label: '취소',
                    type: MiCutButtonType.secondary,
                    onDark: true,
                    onPressed: _cancel,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
