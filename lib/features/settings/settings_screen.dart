import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../data/local/local_store.dart';

/// 설정 (와이어프레임 없음). 로그인 없음 → 약관/개인정보/버전/데이터 삭제만.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // TODO: 실제 문서 URL로 교체
  static final _termsUrl = Uri.parse('https://example.com/terms');
  static final _privacyUrl = Uri.parse('https://example.com/privacy');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('이용약관'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => launchUrl(_termsUrl),
          ),
          ListTile(
            title: const Text('개인정보처리방침'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => launchUrl(_privacyUrl),
          ),
          const Divider(color: MiCutColors.border),
          FutureBuilder(
            future: PackageInfo.fromPlatform(),
            builder: (_, snap) => ListTile(
              title: const Text('앱 버전'),
              trailing: Text(
                snap.data?.version ?? '-',
                style: MiCutText.caption,
              ),
            ),
          ),
          ListTile(
            title: const Text('앱 데이터 삭제'),
            subtitle: Text('갤러리와 컬렉션 기록을 지워요', style: MiCutText.caption),
            onTap: () => _confirmClear(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('앱 데이터를 삭제할까요?'),
        content: const Text('사진첩에 저장하지 않은 이미지는 사라져요'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;
    final store = ref.read(localStoreProvider);
    final items = await store.loadGallery();
    await store.delete(items.map((e) => e.id));
    ref.invalidate(galleryProvider);
    ref.invalidate(collectedCardIdsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('삭제했어요')));
    }
  }
}
