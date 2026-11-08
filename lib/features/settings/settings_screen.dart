import '../../core/widgets/micut_icon.dart';
import '../../core/widgets/micut_back_button.dart';
import 'package:flutter/material.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
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
          ],
        ),
      );
}
