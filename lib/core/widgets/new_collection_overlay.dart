import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'pose_card.dart';

class NewCollectionOverlay extends StatelessWidget {
  const NewCollectionOverlay(
      {super.key,
      required this.number,
      required this.name,
      required this.imagePath,
      required this.onClose});
  final int number;
  final String name;
  final String? imagePath;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: LayoutBuilder(builder: (context, constraints) {
          final scale = (constraints.maxWidth / 375).clamp(0.0, 1.0);
          return Stack(children: [
            Positioned(
                top: constraints.maxHeight * 130 / 812,
                left: 0,
                right: 0,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Material(
                      color: MiCutColors.bgInverse,
                      child: Padding(
                          padding: EdgeInsets.all(10 * scale),
                          child: Text('신규 컬렉션 획득!',
                              style: MiCutText.display.copyWith(
                                  fontSize: 36 * scale,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'DungGeunMo',
                                  color: MiCutColors.cyan200)))),
                  SizedBox(height: 15 * scale),
                  Transform.rotate(
                      angle: 3 * 3.141592653589793 / 180,
                      child: SizedBox(
                          width: 327 * scale,
                          height: 424 * scale,
                          child: PoseCard(
                              number: number,
                              name: name,
                              imagePath: imagePath,
                              onTap: onClose))),
                ]))
          ]);
        }),
      );
}
