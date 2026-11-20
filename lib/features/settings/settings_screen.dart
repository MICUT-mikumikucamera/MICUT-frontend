import '../../core/widgets/micut_icon.dart';
import '../../core/widgets/micut_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/appearance.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(
            leading: const MiCutBackButton(),
            leadingWidth: 64,
            title: const Text('설정')),
        body: ListView(
          padding: const EdgeInsets.only(top: Spacing.pageTop),
          children: [
            ListTile(
              minTileHeight: 64,
              contentPadding: const EdgeInsets.only(left: 24, right: 17),
              title: Text('화면 모드', style: MiCutText.label16Semibold),
              subtitle: Text(appearanceLabel(ref.watch(appearanceProvider))),
              trailing: const MiCutIcon(Icons.chevron_right),
              onTap: () async {
                final selected = await showDialog<ThemeMode>(
                    context: context,
                    builder: (dialogContext) => SimpleDialog(
                          title: const Text('화면 모드'),
                          children: [
                            for (final mode in ThemeMode.values)
                              SimpleDialogOption(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, mode),
                                child: Row(children: [
                                  Expanded(child: Text(appearanceLabel(mode))),
                                  if (ref.read(appearanceProvider) == mode)
                                    const MiCutIcon.asset('check', size: 20),
                                ]),
                              ),
                          ],
                        ));
                if (selected == null || !context.mounted) return;
                try {
                  await ref.read(appearanceProvider.notifier).select(selected);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('화면 모드를 저장하지 못했어요. 다시 시도해 주세요.')));
                  }
                }
              },
            ),
            const Divider(indent: 8, endIndent: 8, height: 0),
            ListTile(
              titleTextStyle: MiCutText.label16Semibold,
              minTileHeight: 64,
              contentPadding: const EdgeInsets.only(left: 24, right: 17),
              title: const Text('이용약관/개인정보 처리방침'),
              trailing: const MiCutIcon(Icons.chevron_right),
            ),
            const Divider(indent: 8, endIndent: 8, height: 0),
            ListTile(
              titleTextStyle: MiCutText.label16Semibold,
              minTileHeight: 64,
              contentPadding: const EdgeInsets.only(left: 24, right: 17),
              title: const Text('알림 설정'),
              trailing: const MiCutIcon(Icons.chevron_right),
            ),
            const Divider(indent: 8, endIndent: 8, height: 0),
            ListTile(
              titleTextStyle: MiCutText.label16Semibold,
              minTileHeight: 64,
              contentPadding: const EdgeInsets.only(left: 24, right: 17),
              title: const Text('저장공간'),
              trailing: const MiCutIcon(Icons.chevron_right),
            ),
          ],
        ),
      );
}
