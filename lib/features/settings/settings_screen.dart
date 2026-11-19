import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/micut_icon.dart';
import '../../core/widgets/micut_back_button.dart';
import 'package:flutter/material.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../data/auth/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authOn = ref.watch(authEnabledProvider);
    final canExpire =
        authOn && ref.watch(authRepositoryProvider).canSimulateExpiry;
    return Scaffold(
      appBar: AppBar(
          leading: const MiCutBackButton(),
          leadingWidth: 64,
          title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.only(top: Spacing.pageTop),
        children: [
          ListTile(
            titleTextStyle: MiCutText.label16Semibold,
            minTileHeight: 64,
            contentPadding: EdgeInsets.only(left: 24, right: 17),
            title: Text('이용약관/개인정보 처리방침'),
            trailing: MiCutIcon(Icons.chevron_right),
          ),
          const Divider(indent: 8, endIndent: 8, height: 0),
          ListTile(
            titleTextStyle: MiCutText.label16Semibold,
            minTileHeight: 64,
            contentPadding: EdgeInsets.only(left: 24, right: 17),
            title: Text('알림 설정'),
            trailing: MiCutIcon(Icons.chevron_right),
          ),
          const Divider(indent: 8, endIndent: 8, height: 0),
          ListTile(
            titleTextStyle: MiCutText.label16Semibold,
            minTileHeight: 64,
            contentPadding: EdgeInsets.only(left: 24, right: 17),
            title: Text('저장공간'),
            trailing: MiCutIcon(Icons.chevron_right),
          ),
          if (authOn) ...[
            const Divider(indent: 8, endIndent: 8, height: 0),
            // TODO(디자인): 설정 화면 시안이 없어 로그아웃 위치·문구는 임시다.
            ListTile(
              titleTextStyle: MiCutText.label16Semibold,
              minTileHeight: 64,
              contentPadding: const EdgeInsets.only(left: 24, right: 17),
              title: const Text('로그아웃'),
              onTap: () => ref.read(authControllerProvider.notifier).signOut(),
            ),
          ],
          if (canExpire) ...[
            const Divider(indent: 8, endIndent: 8, height: 0),
            ListTile(
              titleTextStyle: MiCutText.label16Semibold,
              minTileHeight: 64,
              contentPadding: const EdgeInsets.only(left: 24, right: 17),
              title: const Text('세션 만료 화면 보기 (테스트용)'),
              onTap: () =>
                  ref.read(authControllerProvider.notifier).simulateExpiry(),
            ),
          ],
        ],
      ),
    );
  }
}
