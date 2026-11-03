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
/// 선택 표시는 Primary(시안 원 + 검정 체크), 삭제는 danger(핑크).
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  bool _editing = false;
  final _selected = <String>{};

  void _exitEdit() => setState(() {
        _editing = false;
        _selected.clear();
      });

  Future<void> _deleteSelected() async {
    final n = _selected.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('사진 $n장을 삭제할까요?'),
        content: const Text('사진첩에 저장하지 않은 이미지는 사라져요'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: MiCutColors.danger),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(localStoreProvider).delete(_selected);
    ref.invalidate(galleryProvider);
    ref.invalidate(collectedCardIdsProvider);
    _exitEdit();
  }

  @override
  Widget build(BuildContext context) {
    final gallery = ref.watch(galleryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: _editing
            ? TextButton(onPressed: _exitEdit, child: const Text('취소'))
            : null,
        leadingWidth: _editing ? 72 : null,
        title: Text(_editing ? '${_selected.length}장 선택' : '갤러리'),
        actions: [
          if (!_editing)
            TextButton(
              onPressed: gallery.valueOrNull?.isEmpty ?? true
                  ? null
                  : () => setState(() => _editing = true),
              child: const Text('편집'),
            ),
        ],
      ),
      body: gallery.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러오지 못했어요', style: MiCutText.body)),
        data: (items) {
          if (items.isEmpty) return const _Empty();
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(Spacing.screenH, Spacing.lg, Spacing.screenH, 120),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: Spacing.md,
              crossAxisSpacing: Spacing.md,
              childAspectRatio: 157 / 200,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final sel = _selected.contains(item.id);
              return GestureDetector(
                onTap: () {
                  if (_editing) {
                    setState(() => sel ? _selected.remove(item.id) : _selected.add(item.id));
                  } else {
                    context.push(Routes.photoDetailOf(item.id));
                  }
                },
                onLongPress: () => setState(() {
                  _editing = true;
                  _selected.add(item.id);
                }),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PhotoPlaceholder(path: item.path, radius: Spacing.radiusMd),
                    if (!_editing && !item.savedToAlbum)
                      const Positioned(
                        top: Spacing.sm,
                        left: Spacing.sm,
                        child: _UnsavedDot(),
                      ),
                    if (_editing)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        decoration: BoxDecoration(
                          color: sel ? MiCutColors.dim : Colors.transparent,
                          borderRadius: BorderRadius.circular(Spacing.radiusMd),
                          border: Border.all(
                            color: sel ? MiCutColors.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.all(Spacing.sm),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sel ? MiCutColors.primary : MiCutColors.white.withValues(alpha: 0.7),
                            border: Border.all(color: sel ? MiCutColors.primary : MiCutColors.gray200),
                          ),
                          child: sel
                              ? const Icon(Icons.check_rounded, size: 16, color: MiCutColors.ink)
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
                  padding: const EdgeInsets.all(Spacing.screenH),
                  child: MiCutButton(
                    label: '삭제',
                    type: MiCutButtonType.danger,
                    icon: Icons.delete_outline_rounded,
                    onPressed: _selected.isEmpty ? null : _deleteSelected,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

/// 사진첩에 아직 저장하지 않은 사진 표시 (삭제하면 사라진다는 경고의 근거).
class _UnsavedDot extends StatelessWidget {
  const _UnsavedDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: MiCutColors.ink.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('미저장',
          style: MiCutText.label.copyWith(color: MiCutColors.white, fontSize: 10)),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: MiCutColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.image_outlined, size: 40, color: MiCutColors.primaryStrong),
          ),
          const SizedBox(height: Spacing.lg),
          Text('아직 사진이 없어요', style: MiCutText.h3),
          const SizedBox(height: Spacing.xl),
          SizedBox(
            width: 220,
            child: MiCutButton(
              label: '사진 촬영하러 가기',
              onPressed: () => context.push(Routes.captureGuide),
            ),
          ),
        ],
      ),
    );
  }
}
