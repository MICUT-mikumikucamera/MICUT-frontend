import '../../core/widgets/micut_dialog.dart';
import '../../core/widgets/micut_icon.dart';
import '../../core/widgets/micut_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/services/photo_share.dart';
import '../../core/services/photo_bytes.dart';
import '../../core/services/photo_download.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/photo_placeholder.dart';
import '../../data/local/local_store.dart';

/// Figma 10 사진 상세
class PhotoDetailScreen extends ConsumerWidget {
  const PhotoDetailScreen({super.key, required this.id});
  final String id;

  String _date(DateTime d) =>
      '${d.year}년 ${d.month.toString().padLeft(2, '0')}월 ${d.day.toString().padLeft(2, '0')}일';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref
        .watch(galleryProvider)
        .valueOrNull
        ?.where((e) => e.id == id)
        .firstOrNull;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const MiCutBackButton(),
          leadingWidth: 64,
        ),
      );
    }

    Future<void> save() async {
      try {
        if (kIsWeb) {
          final bytes = await readPhotoBytes(item.path);
          if (!context.mounted) return;
          await downloadPhoto(bytes, 'micut-${item.id}.jpg');
          if (context.mounted) {
            debugPrint('Photo action state changed.');
          }
          return;
        }
        await Gal.putImage(item.path);
        await ref.read(localStoreProvider).markSaved(item.id);
        ref.invalidate(galleryProvider);
        if (context.mounted) {
          debugPrint('Photo saved to album.');
        }
      } on GalException {
        if (context.mounted) {
          debugPrint('Photo action state changed.');
        }
      } catch (_) {
        if (context.mounted) {
          debugPrint('Photo action state changed.');
        }
      }
    }

    Future<void> delete() async {
      final ok = await showDialog<bool>(
        context: context,
        barrierColor: MiCutColors.modalDim,
        useSafeArea: false,
        builder: (ctx) => MiCutDialog(
            padding: 25,
            title: '사진 1장을 삭제할까요?',
            message: '사진첩에 저장하지 않은 이미지는 사라져요',
            confirmLabel: '삭제',
            danger: true,
            onConfirm: () => Navigator.pop(ctx, true)),
      );
      if (ok != true || !context.mounted) return;
      try {
        await ref.read(localStoreProvider).delete([item.id]);
        ref.invalidate(galleryProvider);
        ref.invalidate(collectedCardIdsProvider);
        if (context.mounted) context.pop();
      } catch (_) {
        if (context.mounted) {
          debugPrint('Photo action state changed.');
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
          leading: const MiCutBackButton(),
          leadingWidth: 64,
          title: Text(_date(item.createdAt))),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: PhotoPlaceholder(
                  path: item.path, radius: 0, fit: BoxFit.cover),
            ),
          ),
          Container(
            color: MiCutColors.bgDefault,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 120,
                child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        _Action(
                          icon: Icons.ios_share,
                          label: '공유',
                          onTap: () => sharePhoto(context, item.path),
                        ),
                        _Action(
                          icon: Icons.download_outlined,
                          label: '사진첩에 저장',
                          onTap: save,
                        ),
                        _Action(
                          icon: Icons.delete_outline,
                          label: '삭제',
                          onTap: delete,
                        ),
                      ],
                    )),
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
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        onTap == null ? MiCutColors.textHint : MiCutColors.textPrimary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MiCutIcon(icon, color: color),
            const SizedBox(height: Spacing.s6),
            Text(label, style: MiCutText.label12Medium.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
