import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'photo_placeholder.dart';

/// White polaroid shell. Missing pose artwork remains a plain placeholder.
class PoseCard extends StatelessWidget {
  const PoseCard(
      {super.key,
      required this.number,
      required this.name,
      this.imagePath,
      this.collected = true,
      this.isNew = false,
      this.onTap});
  final int number;
  final String name;
  final String? imagePath;
  final bool collected, isNew;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final scale = constraints.maxWidth / 327;
        return Material(
            color: MiCutColors.bgDefault,
            borderRadius: BorderRadius.circular(20 * scale),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
                onTap: onTap,
                child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        16 * scale, 16 * scale, 16 * scale, 20 * scale),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: SizedBox(
                                  width: double.infinity,
                                  child: collected
                                      ? PhotoPlaceholder(
                                          path: imagePath, radius: 20 * scale)
                                      : ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20 * scale),
                                          child: Image.asset(
                                              'assets/figma-export/pose-locked.png',
                                              fit: BoxFit.cover)))),
                          SizedBox(height: 8 * scale),
                          Text('#${number.toString().padLeft(3, '0')}',
                              style: MiCutText.cardBody.copyWith(
                                  fontSize: 13 * scale,
                                  height: 18 / 13,
                                  color: MiCutColors.textDefault)),
                          SizedBox(height: 8 * scale),
                          Text(collected ? name : '???',
                              style: MiCutText.heading24Semibold
                                  .copyWith(fontSize: 24 * scale),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ]))));
      });
}
