import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/photo_placeholder.dart';
import '../../data/local/local_store.dart';

/// Figma 10 사진 상세
class PhotoDetailScreen extends ConsumerWidget {
  const PhotoDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(galleryProvider).valueOrNull?.where((e) => e.id == id).firstOrNull;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('사진을 찾을 수 없어요', style: MiCutText.body)),
      );
    }

    Future<void> save() async {
      try {
        await Gal.putImage(item.path);
        await ref.read(localStoreProvider).markSaved(item.id);
        ref.invalidate(galleryProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('사진첩에 저장했어요')));
        }
      } on GalException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('저장하지 못했어요 (${e.type.name})')));
        }
      }
    }

    Future<void> delete() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('사진 1장을 삭제할까요?'),
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
      await ref.read(localStoreProvider).delete([item.id]);
      ref.invalidate(galleryProvider);
      ref.invalidate(collectedCardIdsProvider);
      if (context.mounted) context.pop();
    }

    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: PhotoPlaceholder(path: item.path, radius: 0, fit: BoxFit.contain),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: MiCutColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 90,
                child: Row(
                  children: [
                    _Action(
                      icon: Icons.ios_share,
                      label: '공유',
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('공유는 다음 단계에서'))),
                    ),
                    _Action(
                      icon: item.savedToAlbum ? Icons.check_circle_rounded : Icons.download_outlined,
                      label: item.savedToAlbum ? '저장됨' : '사진첩에 저장',
                      onTap: item.savedToAlbum ? null : save,
                      done: item.savedToAlbum,
                    ),
                    _Action(
                      icon: Icons.delete_outline,
                      label: '삭제',
                      onTap: delete,
                      danger: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    this.onTap,
    this.danger = false,
    this.done = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final color = done
        ? MiCutColors.primaryStrong
        : onTap == null
            ? MiCutColors.textHint
            : danger
                ? MiCutColors.danger
                : MiCutColors.textPrimary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: Spacing.xs),
            Text(label, style: MiCutText.label.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
