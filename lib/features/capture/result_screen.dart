import '../../core/theme/colors.dart';
import '../../core/widgets/micut_dialog.dart';
import '../../core/widgets/micut_icon.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/photo_bytes.dart';
import '../../core/services/photo_download.dart';
import '../../core/services/photo_share.dart';
import '../../core/widgets/new_collection_overlay.dart';
import '../../data/local/poses.dart';

import '../../app/router.dart';

import '../../core/theme/spacing.dart';

import '../../core/widgets/micut_button.dart';
import 'capture_view.dart';
import '../../data/jobs/job.dart';
import '../../data/jobs/providers.dart';
import '../../data/local/local_store.dart';

/// Figma 06 결과 → 07 저장 완료 (같은 화면, 버튼/토스트만 바뀜)
///
/// 결과 사진과 흰색 안내 영역. 저장 성공 상태는 실제 저장 결과를 따른다.
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
  bool _loadFailed = false;
  GalleryItem? _galleryItem;
  bool _writtenToAlbum = false;
  bool _showSavedBubble = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(jobRepositoryProvider);
      final job = await repo.getJob(widget.jobId);
      if (!mounted) return;
      setState(() {
        _job = job;
        _imagePath = job.result == null
            ? null
            : repo.resolveImageUrl(job.result!.imageUrl);
        _loadFailed = job.result == null;
      });
      await _showNewCollection(job);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _showNewCollection(Job job) async {
    final ids = job.result?.cardIds ?? const <String>[];
    if (ids.isEmpty) return;
    final collected = await ref.read(localStoreProvider).collectedCardIds();
    final newPoses =
        kPoses.where((p) => ids.contains(p.id) && !collected.contains(p.id));
    if (!mounted || newPoses.isEmpty) return;
    final pose = newPoses.first;
    await showDialog<void>(
      context: context,
      barrierColor: MiCutColors.modalDim,
      useSafeArea: false,
      barrierLabel: '컬렉션 안내 닫기',
      builder: (dialogContext) => NewCollectionOverlay(
          number: pose.number,
          name: pose.name,
          imagePath: _imagePath,
          onClose: () => Navigator.of(dialogContext).pop()),
    );
  }

  Future<void> _save() async {
    if (_imagePath == null || _saving || _saved) return;
    setState(() => _saving = true);
    try {
      final store = ref.read(localStoreProvider);
      final bytes = await readPhotoBytes(_imagePath!);
      if (kIsWeb) {
        await downloadPhoto(bytes, 'micut-${widget.jobId}.jpg');
      } else if (!_writtenToAlbum) {
        await Gal.putImageBytes(bytes, name: 'micut-${widget.jobId}');
        _writtenToAlbum = true;
      }
      // Register collection progress only after the save action succeeds.
      final item = _galleryItem ??= await store.addFromBytes(bytes,
          cardIds: _job?.result?.cardIds ?? const []);
      if (!kIsWeb) await store.markSaved(item.id);
      ref.invalidate(galleryProvider);
      ref.invalidate(collectedCardIdsProvider);
      if (!mounted) return;
      setState(() => _saved = true);
      if (!kIsWeb) {
        setState(() => _showSavedBubble = true);
        Future<void>.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showSavedBubble = false);
        });
      }
    } on GalException {
      if (mounted) {
        debugPrint('Photo action state changed.');
      }
    } catch (_) {
      if (mounted) {
        debugPrint('Photo action state changed.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _leave(String route) async {
    if (_saving) return;
    if (!_saved && _imagePath != null) {
      final leave = await showDialog<bool>(
        context: context,
        barrierColor: MiCutColors.modalDim,
        useSafeArea: false,
        builder: (ctx) => MiCutDialog(
            title: '저장하지 않고 나갈까요?',
            message: '사진을 저장하지 않으면 컬렉션에 등록되지 않아요.',
            confirmLabel: '확인',
            danger: true,
            onConfirm: () => Navigator.pop(ctx, true)),
      );
      if (leave != true || !mounted) return;
    }
    if (mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context) => CaptureView(
        photoPath: _imagePath,
        topActions: [
          IconButton(
            tooltip: '사진 공유',
            padding: EdgeInsets.zero,
            alignment: Alignment.center,
            icon: const MiCutIcon(Icons.ios_share_outlined, size: 28),
            onPressed: _imagePath == null
                ? null
                : () => sharePhoto(context, _imagePath!),
          )
        ],
        processing: _imagePath == null && !_loadFailed,
        message: _loadFailed
            ? '네트워크 연결을 확인해 주세요.'
            : _imagePath == null
                ? ''
                : '생성 완료!',
        onClose: _saving ? null : () => _leave(Routes.home),
        actionNotice: _showSavedBubble ? '사진첩에 저장했어요' : null,
        actions: _loadFailed
            ? MiCutButton(
                label: '재시도',
                type: MiCutButtonType.secondary,
                onPressed: () {
                  setState(() => _loadFailed = false);
                  _load();
                })
            : Row(children: [
                Expanded(
                    child: MiCutButton(
                        label: '다시 찍기',
                        type: MiCutButtonType.secondary,
                        onPressed: _saving
                            ? null
                            : () => _leave(Routes.captureCamera))),
                const SizedBox(width: Spacing.md),
                Expanded(
                    child: MiCutButton(
                        label: _saved ? '갤러리 보기' : '저장',
                        loading: _saving,
                        onPressed: _saving || _imagePath == null
                            ? null
                            : _saved
                                ? () => context.go(Routes.gallery)
                                : _save)),
              ]),
      );
}
