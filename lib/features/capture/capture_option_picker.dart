import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/micut_icon.dart';

class CaptureOption {
  const CaptureOption({required this.asset, required this.label});
  final String asset, label;
}

class CaptureOptionGroup {
  const CaptureOptionGroup(
      {required this.id,
      required this.tooltip,
      required this.selectedIndex,
      required this.enabled,
      required this.options,
      required this.onSelected,
      this.edgePadding = 0});
  final String id, tooltip;
  final double edgePadding;
  final int selectedIndex;
  final bool enabled;
  final List<CaptureOption> options;
  final ValueChanged<int> onSelected;
}

/// One shared rail coordinates the trigger and menu, without a popup route.
class CaptureOptionsRail extends StatefulWidget {
  const CaptureOptionsRail({super.key, required this.groups});
  final List<CaptureOptionGroup> groups;
  @override
  State<CaptureOptionsRail> createState() => _CaptureOptionsRailState();
}

class _CaptureOptionsRailState extends State<CaptureOptionsRail>
    with SingleTickerProviderStateMixin {
  static const double targetSize = 48,
      menuRowHeight = 40,
      menuWidth = 40,
      iconSize = 24,
      left = 8;
  late final AnimationController _motion = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));
  final _focus = FocusNode();
  int? _active;
  int? _chosen;
  bool _closing = false;

  @override
  void dispose() {
    _motion.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _open(int index) {
    if (_active != null || !widget.groups[index].enabled) return;
    setState(() {
      _active = index;
      _chosen = null;
    });
    _focus.requestFocus();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.value = 1;
    } else {
      _motion.forward();
    }
  }

  Future<void> _close([int? selected]) async {
    if (_active == null || _closing) return;
    final group = widget.groups[_active!];
    setState(() {
      _chosen = selected;
      _closing = true;
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.value = 0;
    } else {
      try {
        await _motion.reverse().orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _active = null;
      _chosen = null;
      _closing = false;
    });
    if (selected != null && group.enabled) group.onSelected(selected);
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: _active == null,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _close();
        },
        child: Focus(
          focusNode: _focus,
          onKeyEvent: (_, event) {
            if (_active != null &&
                event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape) {
              _close();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: LayoutBuilder(
              builder: (context, constraints) => AnimatedBuilder(
                    animation: _motion,
                    builder: (context, _) {
                      final value = _motion.value;
                      final others = 1 - const Interval(0, .2).transform(value);
                      final travel =
                          const Interval(.2, .65, curve: Curves.easeInOutCubic)
                              .transform(value);
                      final menu = const Interval(.65, 1, curve: Curves.easeOut)
                          .transform(value);
                      final railTop = (constraints.maxHeight -
                              widget.groups.length * targetSize) /
                          2;
                      final active = _active;
                      final group =
                          active == null ? null : widget.groups[active];
                      final selected =
                          group == null ? 0 : (_chosen ?? group.selectedIndex);
                      final menuTop = group == null
                          ? 0.0
                          : (constraints.maxHeight -
                                  (group.options.length * menuRowHeight +
                                      2 * group.edgePadding)) /
                              2;
                      return Stack(clipBehavior: Clip.none, children: [
                        if (active != null)
                          Positioned.fill(
                              child: GestureDetector(
                                  key:
                                      const ValueKey('capture-options-dismiss'),
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _close)),
                        for (var i = 0; i < widget.groups.length; i++)
                          if (i != active)
                            Positioned(
                                left: left,
                                top: railTop + i * targetSize,
                                child: IgnorePointer(
                                    ignoring: active != null,
                                    child: ExcludeSemantics(
                                        excluding: active != null,
                                        child: Opacity(
                                          opacity: active == null ? 1 : others,
                                          child: _button(
                                              key: ValueKey(
                                                  'trigger-${widget.groups[i].id}'),
                                              asset: widget
                                                  .groups[i]
                                                  .options[widget
                                                      .groups[i].selectedIndex]
                                                  .asset,
                                              label: widget.groups[i].tooltip,
                                              enabled: widget.groups[i].enabled,
                                              canFocus: active == null,
                                              onTap: () => _open(i)),
                                        )))),
                        if (group != null) ...[
                          Positioned(
                              left: left + (targetSize - menuWidth) / 2,
                              top: menuTop,
                              child: IgnorePointer(
                                  child: Opacity(
                                opacity: menu,
                                child: Container(
                                    key: const ValueKey(
                                        'capture-options-background'),
                                    width: menuWidth,
                                    height:
                                        (group.options.length * menuRowHeight +
                                            2 * group.edgePadding),
                                    decoration: BoxDecoration(
                                        color: const Color(0x99000000),
                                        borderRadius: BorderRadius.circular(
                                            menuWidth / 2))),
                              ))),
                          for (var i = 0; i < group.options.length; i++)
                            if (i != selected)
                              Positioned(
                                  left: left,
                                  top: menuTop +
                                      group.edgePadding +
                                      i * menuRowHeight,
                                  child: IgnorePointer(
                                      ignoring: _closing || value < 1,
                                      child: ExcludeSemantics(
                                          excluding: _closing || value < 1,
                                          child: Opacity(
                                            opacity: menu,
                                            child: _button(
                                                key: ValueKey(
                                                    'option-${group.id}-$i'),
                                                height: menuRowHeight,
                                                asset: group.options[i].asset,
                                                label: group.options[i].label,
                                                canFocus:
                                                    !_closing && value == 1,
                                                onTap: () => _close(i)),
                                          )))),
                          Positioned(
                              left: left,
                              top: lerpDouble(
                                  railTop + active! * targetSize,
                                  menuTop +
                                      group.edgePadding +
                                      selected * menuRowHeight,
                                  travel)!,
                              child: KeyedSubtree(
                                key: const ValueKey('moving-camera-option'),
                                child: _button(
                                    key: ValueKey(
                                        'option-${group.id}-$selected'),
                                    height: lerpDouble(
                                        targetSize, menuRowHeight, travel)!,
                                    asset: group.options[selected].asset,
                                    label: group.options[selected].label,
                                    selected: true,
                                    enabled: !_closing && value == 1,
                                    // This icon is not dimmed during its travel.
                                    dimDisabled: false,
                                    onTap: _close),
                              )),
                        ],
                      ]);
                    },
                  )),
        ),
      );

  Widget _button(
          {required Key key,
          required String asset,
          required String label,
          required VoidCallback onTap,
          bool enabled = true,
          bool selected = false,
          bool dimDisabled = true,
          bool canFocus = true,
          double height = targetSize}) =>
      ExcludeFocus(
          excluding: !canFocus,
          child: Semantics(
              selected: selected,
              button: true,
              child: SizedBox(
                width: targetSize,
                height: height,
                child: IconButton(
                  key: key,
                  tooltip: label,
                  padding: EdgeInsets.zero,
                  alignment: Alignment.center,
                  onPressed: enabled ? onTap : null,
                  icon: MiCutIcon.asset(asset,
                      size: iconSize,
                      color: selected
                          ? MiCutColors.cyan200
                          : (!enabled && dimDisabled
                              ? MiCutColors.gray500
                              : MiCutColors.textInverse)),
                ),
              )));
}
