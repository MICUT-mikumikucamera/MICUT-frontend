import '../../core/widgets/micut_dialog.dart';
import '../../core/widgets/miku_illustration.dart';
import '../../core/widgets/micut_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/micut_button.dart';
import '../../core/widgets/photo_placeholder.dart';
import '../../data/local/local_store.dart';

/// Figma 09 갤러리 / 09-1 빈 상태 / 09-2 편집 / 09-3 삭제 확인
///
/// 선택 표시는 시안, 최종 삭제 행동은 Danger를 사용한다.
final galleryEditingProvider = StateProvider<bool>((ref) => false);

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  bool get _editing => ref.read(galleryEditingProvider);
  final _selected = <String>{};

  void _exitEdit() => setState(() {
        ref.read(galleryEditingProvider.notifier).state = false;
        _selected.clear();
      });

  Future<void> _deleteSelected() async {
    final n = _selected.length;
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: MiCutColors.modalDim,
      useSafeArea: false,
      builder: (ctx) => MiCutDialog(
          padding: 25,
          title: '사진 $n장을 삭제할까요?',
          message: '사진첩에 저장하지 않은 이미지는 사라져요',
          confirmLabel: '삭제',
          danger: true,
          onConfirm: () => Navigator.pop(ctx, true)),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(localStoreProvider).delete(_selected);
      ref.invalidate(galleryProvider);
      ref.invalidate(collectedCardIdsProvider);
      if (mounted) _exitEdit();
    } catch (_) {
      if (mounted) {
        debugPrint('Gallery deletion failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gallery = ref.watch(galleryProvider);
    ref.watch(galleryEditingProvider);

    return Scaffold(
      appBar: AppBar(
        leading: _editing
            ? TextButton(onPressed: _exitEdit, child: const Text('취소'))
            : null,
        leadingWidth: _editing ? 72 : null,
        centerTitle: _editing,
        titleTextStyle: _editing
            ? MiCutText.heading20Semibold
            : MiCutText.heading24Semibold,
        title: Text(_editing ? '${_selected.length}장 선택' : '갤러리'),
        actions: [
          if (!_editing)
            TextButton(
              onPressed: gallery.valueOrNull?.isEmpty ?? true
                  ? null
                  : () => setState(() =>
                      ref.read(galleryEditingProvider.notifier).state = true),
              child: const Text('편집'),
            ),
        ],
      ),
      body: gallery.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const SizedBox.shrink(),
        data: (items) {
          if (items.isEmpty) return const _Empty();
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(
              Spacing.xl,
              Spacing.pageTop,
              Spacing.xl,
              120,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: Spacing.galleryGap,
              crossAxisSpacing: Spacing.galleryGap,
              childAspectRatio: 157 / 200,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final sel = _selected.contains(item.id);
              return GestureDetector(
                onTap: () {
                  if (_editing) {
                    setState(
                      () => sel
                          ? _selected.remove(item.id)
                          : _selected.add(item.id),
                    );
                  } else {
                    context.push(Routes.photoDetailOf(item.id));
                  }
                },
                onLongPress: () => setState(() {
                  ref.read(galleryEditingProvider.notifier).state = true;
                  _selected.add(item.id);
                }),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PhotoPlaceholder(
                        path: item.path, radius: Spacing.photoRadius),
                    if (_editing && sel)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        decoration: BoxDecoration(
                          color: sel
                              ? MiCutColors.primary.withValues(alpha: 0.3)
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(Spacing.photoRadius),
                          border: Border.all(
                            color:
                                sel ? MiCutColors.primary : Colors.transparent,
                            width: 0,
                          ),
                        ),
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.all(Spacing.sm),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sel
                                ? MiCutColors.cyan500
                                : MiCutColors.white.withValues(alpha: 0.7),
                            border: Border.all(
                              color: MiCutColors.white,
                              width: 2,
                            ),
                          ),
                          child: sel
                              ? const MiCutIcon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: MiCutColors.white,
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomSheet: _editing
          ? Container(
              color: MiCutColors.background,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.screenH,
                    Spacing.screenH,
                    Spacing.screenH,
                    Spacing.xxl,
                  ),
                  child: MiCutButton(
                    label: '삭제',
                    height: Spacing.primaryButtonHeight,
                    radius: Spacing.radius20,
                    type: MiCutButtonType.danger,
                    onPressed: _selected.isEmpty ? null : _deleteSelected,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.translate(
          offset: Offset(
              0,
              -(View.of(context).padding.top /
                          View.of(context).devicePixelRatio +
                      51 -
                      (70 +
                          View.of(context).padding.bottom /
                              View.of(context).devicePixelRatio)) /
                  2),
          child: SingleChildScrollView(
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const MikuIllustration(MikuArtwork.empty),
                      const SizedBox(height: Spacing.lg),
                      Text('아직 사진이 없어요', style: MiCutText.heading18Semibold),
                      const SizedBox(height: 36),
                      SizedBox(
                        width: 240,
                        child: MiCutButton(
                          label: '사진 촬영하러 가기',
                          solid: false,
                          height: 48,
                          onPressed: () => context.push(Routes.captureGuide),
                        ),
                      ),
                    ],
                  )))),
    );
  }
}
