import 'dart:io';

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
import '../../core/widgets/photo_placeholder.dart';
import '../../data/jobs/job.dart';
import '../../data/jobs/providers.dart';

/// Figma 04 촬영 확인 — 아직 다크 월드(카메라 흐름 안).
class ConfirmScreen extends ConsumerStatefulWidget {
  const ConfirmScreen({super.key, required this.photo});
  final File photo;

  @override
  ConsumerState<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends ConsumerState<ConfirmScreen> {
  bool _uploading = false;

  Future<void> _create() async {
    setState(() => _uploading = true);
    try {
      final capture = await _captureInfo(widget.photo);
      final job = await ref.read(jobRepositoryProvider).createJob(widget.photo, capture);
      if (!mounted) return;
      context.pushReplacement(Routes.processingOf(job.jobId));
    } on UploadException catch (e) {
      // 업로드 실패는 job 없음 → 메시지만 보여주고 이 화면에 머문다
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('네트워크 오류예요. 다시 시도해주세요')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// 사진 크기/회전. fx(초점거리)는 1차에서 null.
  Future<CaptureInfo> _captureInfo(File f) async {
    final bytes = await f.readAsBytes();
    final img = await decodeImageFromList(bytes);
    return CaptureInfo(w: img.width, h: img.height, rotation: 0, fx: null);
  }

  @override
  Widget build(BuildContext context) {
    return DarkWorld(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
          title: const HudStatus(text: 'PREVIEW', blinking: false),
        ),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: HudCorners(
                  length: 24,
                  child: PhotoPlaceholder(
                    path: widget.photo.path,
                    radius: Spacing.radiusSm,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    dark: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.xl),
            Text('이 사진에 미쿠를 불러올까요?',
                style: MiCutText.h3.copyWith(color: MiCutColors.darkText)),
            const SizedBox(height: Spacing.xxl),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.screenH, 0, Spacing.screenH, Spacing.xl),
                child: Row(
                  children: [
                    Expanded(
                      child: MiCutButton(
                        label: '다시 찍기',
                        type: MiCutButtonType.secondary,
                        onDark: true,
                        onPressed: _uploading ? null : () => context.pop(),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: MiCutButton(
                        label: '만들기',
                        onDark: true,
                        loading: _uploading,
                        onPressed: _create,
                      ),
                    ),
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
