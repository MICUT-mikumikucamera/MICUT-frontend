import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'micut_icon.dart';

class MiCutTabBar extends StatelessWidget {
  const MiCutTabBar(
      {super.key,
      required this.currentIndex,
      required this.onTabSelected,
      required this.onCapture});
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Material(
      color: MiCutColors.bgDefault,
      child: SizedBox(
        height: 70 + bottomInset,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _item(
              MiCutIcon.asset('home',
                  size: 24,
                  color: currentIndex == 0
                      ? MiCutColors.iconSelected
                      : MiCutColors.iconSubtle),
              '홈',
              currentIndex == 0,
              () => onTabSelected(0),
              bottomInset),
          _item(
              Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                      gradient: MiCutGradients.capture, shape: BoxShape.circle),
                  child: const MiCutIcon.asset('camera',
                      size: 24, color: MiCutColors.iconInverse)),
              '촬영',
              false,
              onCapture,
              bottomInset),
          _item(
              MiCutIcon.asset('gallery',
                  size: 24,
                  color: currentIndex == 1
                      ? MiCutColors.iconSelected
                      : MiCutColors.iconSubtle),
              '갤러리',
              currentIndex == 1,
              () => onTabSelected(1),
              bottomInset),
        ]),
      ),
    );
  }

  Widget _item(Widget icon, String label, bool selected, VoidCallback onTap,
          double bottomInset) =>
      Expanded(
        child: Semantics(
          label: label,
          selected: selected,
          button: true,
          child: InkWell(
            onTap: onTap,
            overlayColor: const WidgetStatePropertyAll(MiCutColors.bgSubtle),
            child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Center(child: icon)),
          ),
        ),
      );
}
