import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../app/router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/micut_button.dart';
import '../../core/widgets/photo_placeholder.dart';
import '../../data/jobs/job.dart';
import '../../data/jobs/providers.dart';
import '../../data/local/local_store.dart';

/// Figma 06 결과 → 07 저장 완료 (같은 화면, 버튼/토스트만 바뀜)
///
/// 다크 월드에서 라이트 월드로 복귀. 사진이 주인공이라 장식은 AI 태그 칩 정도만.
class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key, required this.jobId});
  final String jobId;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  Job? _job;
  String? _imagePath; // 로컬 경로 또는 URL
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(jobRepositoryProvider);
    final job = await repo.getJob(widget.jobId);
    if (!mounted) return;
    setState(() {
      _job = job;
      _imagePath = job.result == null ? null : repo.resolveImageUrl(job.result!.imageUrl);
    });
  }

  /// 결과를 로컬 파일로 확보 (URL이면 내려받기).
  Future<File> _localFile() async {
    final path = _imagePath!;
    if (!path.startsWith('http')) return File(path);
    final res = await http.get(Uri.parse(path));
    final dir = await getTemporaryDirectory();
    final f = File(p.join(dir.path, '${widget.jobId}.jpg'));
    await f.writeAsBytes(res.bodyBytes);
    return f;
  }

  Future<void> _save() async {
    if (_imagePath == null) return;
    setState(() => _saving = true);
    try {
      final f = await _localFile();
      final store = ref.read(localStoreProvider);
      final item = await store.addFromFile(f, cardIds: _job?.result?.cardIds ?? const []);
      await Gal.putImage(item.path);
      await store.markSaved(item.id);
      ref.invalidate(galleryProvider);
      ref.invalidate(collectedCardIdsProvider);
      if (!mounted) return;
      setState(() => _saved = true);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('사진첩에 저장했어요')));
    } on GalException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('사진첩 저장 실패 (${e.type.name})')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('저장하지 못했어요')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = _job?.result?.tags ?? const <String>[];
    final newCards = _job?.result?.cardIds ?? const <String>[];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go(Routes.home),
        ),
        actions: [
          if (_saved)
            IconButton(icon: const Icon(Icons.ios_share), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _imagePath == null
                ? const Center(child: CircularProgressIndicator())
                : PhotoPlaceholder(
                    path: _imagePath,
                    radius: 0,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
          ),
          if (tags.isNotEmpty || newCards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.screenH, Spacing.lg, Spacing.screenH, 0),
              child: Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: [
                  for (final t in tags) _Tag(text: t),
                  for (final c in newCards) _Tag(text: '카드 #$c 획득', accent: true),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.screenH),
              child: Row(
                children: [
                  Expanded(
                    child: MiCutButton(
                      label: '다시 찍기',
                      type: MiCutButtonType.secondary,
                      onPressed: () => context.pushReplacement(Routes.captureCamera),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: _saved
                        ? MiCutButton(
                            label: '갤러리 보기',
                            icon: Icons.photo_library_rounded,
                            onPressed: () => context.go(Routes.gallery),
                          )
                        : MiCutButton(
                            label: '사진첩에 저장',
                            icon: Icons.download_rounded,
                            loading: _saving,
                            onPressed: _imagePath == null ? null : _save,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, this.accent = false});
  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
      decoration: BoxDecoration(
        color: accent ? MiCutColors.secondarySoft : MiCutColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: MiCutText.label.copyWith(
          color: accent ? MiCutColors.onSecondarySoft : MiCutColors.primaryStrong,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
