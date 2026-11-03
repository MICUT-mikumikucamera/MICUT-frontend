import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Figma `TabBar`. 홈 · 촬영(가운데 큰 버튼) · 갤러리.
/// 촬영은 탭이 아니라 액션이라서 [onCapture]로 분리한다.
///
/// 가운데 버튼은 로고(순흑 + 일렉트릭 시안)의 축소판: ink 원 + brandCyan 아이콘 + 시안 글로우.
class MiCutTabBar extends StatelessWidget {
  const MiCutTabBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCapture,
  });

  /// 0 = 홈, 1 = 갤러리
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      height: Spacing.tabBarHeight + bottom,
      padding: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: MiCutColors.background,
        border: Border(top: BorderSide(color: MiCutColors.border)),
      ),
      child: Row(
        children: [
          _TabItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: '홈',
            selected: currentIndex == 0,
            onTap: () => onTabSelected(0),
          ),
          Expanded(
            child: Center(
              child: Semantics(
                button: true,
                label: '촬영하기',
                child: GestureDetector(
                  onTap: onCapture,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: MiCutColors.ink,
                      shape: BoxShape.circle,
                      boxShadow: MiCutShadows.glowCyan,
                    ),
                    child: const Icon(
                      Icons.photo_camera_rounded,
                      color: MiCutColors.brandCyan,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _TabItem(
            icon: Icons.photo_library_outlined,
            activeIcon: Icons.photo_library_rounded,
            label: '갤러리',
            selected: currentIndex == 1,
            onTap: () => onTabSelected(1),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? MiCutColors.primaryStrong : MiCutColors.textHint;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: color),
            const SizedBox(height: Spacing.xs),
            Text(
              label,
              style: MiCutText.label.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
