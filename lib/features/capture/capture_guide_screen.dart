import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/dark_world.dart';
import '../../core/widgets/micut_button.dart';

class CaptureGuideScreen extends StatelessWidget {
  const CaptureGuideScreen({super.key});
  static const guideText = '사람이 없는 장소를 찍어주세요';

  @override
  Widget build(BuildContext context) => DarkWorld(
          child: Scaffold(
        backgroundColor: MiCutColors.guideBackground,
        body: SafeArea(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.screenH),
          child: Column(children: [
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.only(top: Spacing.s6),
                    child: Center(
                        child: SingleChildScrollView(
                            child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                            width: 260,
                            height: 230,
                            child:
                                Stack(alignment: Alignment.center, children: [
                              Container(
                                  width: 200,
                                  height: 230,
                                  decoration: BoxDecoration(
                                      color: MiCutColors.gray600,
                                      borderRadius: BorderRadius.circular(
                                          Spacing.photoRadius),
                                      border: Border.all(
                                          color: MiCutColors.cyan100,
                                          width: 1.5))),
                              Positioned(
                                  left: 0,
                                  right: 0,
                                  top: 180,
                                  child: Container(
                                      height: 2, color: MiCutColors.cyan100)),
                            ])),
                        const SizedBox(height: 50),
                        Text(guideText,
                            textAlign: TextAlign.center,
                            style: MiCutText.body20Semibold
                                .copyWith(color: MiCutColors.darkText)),
                      ],
                    ))))),
            MiCutButton(
                label: '확인',
                height: Spacing.primaryButtonHeight,
                radius: Spacing.radius20,
                solid: false,
                onPressed: () => context.pushReplacement(Routes.captureCamera)),
            const SizedBox(height: 17),
          ]),
        )),
      ));
}
