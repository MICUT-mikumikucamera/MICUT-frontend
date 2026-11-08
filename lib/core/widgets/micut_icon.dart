import 'package:flutter/material.dart';

/// Original Figma icon geometry. Color follows the source's semantic overrides.
class MiCutIcon extends StatelessWidget {
  const MiCutIcon(this.icon, {super.key, this.size, this.color}) : asset = null;
  const MiCutIcon.asset(this.asset, {super.key, this.size, this.color})
      : icon = null;
  final String? asset;
  final IconData? icon;
  final double? size;
  final Color? color;

  static final _assets = <IconData, String>{
    Icons.photo_camera_outlined: 'camera',
    Icons.home_outlined: 'home',
    Icons.home_rounded: 'home',
    Icons.style_outlined: 'collections',
    Icons.view_carousel_outlined: 'collections',
    Icons.settings_outlined: 'setting',
    Icons.help_outline: 'help',
    Icons.close: 'close',
    Icons.photo_library_outlined: 'gallery',
    Icons.photo_library: 'gallery',
    Icons.photo_outlined: 'gallery',
    Icons.download_outlined: 'save',
    Icons.delete_outline: 'delete',
    Icons.ios_share: 'share',
    Icons.ios_share_outlined: 'share',
    Icons.edit_outlined: 'edit',
    Icons.flash_on: 'flash-on',
    Icons.flash_off: 'flash-off',
    Icons.flash_auto: 'flash-auto',
    Icons.timer_outlined: 'timer-0',
    Icons.image_outlined: 'image-empty',
    Icons.check_rounded: 'check',
    Icons.chevron_right: 'arrow-right',
  };

  @override
  Widget build(BuildContext context) {
    final assetName = asset ?? _assets[icon];
    if (assetName == null) return Icon(icon, size: size, color: color);
    final theme = IconTheme.of(context);
    final effectiveColor = color ?? theme.color;
    return ExcludeSemantics(
      child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Image.asset(
            'assets/figma-export/$assetName.png',
            width: size ?? theme.size ?? 24,
            height: size ?? theme.size ?? 24,
            color: effectiveColor?.withValues(
                alpha: (effectiveColor.a) * (theme.opacity ?? 1)),
            colorBlendMode: BlendMode.srcIn,
            filterQuality: FilterQuality.high,
          )),
    );
  }
}
