import '../../core/widgets/micut_icon.dart';
import '../../core/widgets/micut_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/photo_placeholder.dart';

// Keep the selected local image visible throughout this in-app capture flow.
// Server upload paths are not public image URLs.
final capturePhotoProvider =
    StateProvider.family<String?, String>((ref, id) => null);

class CaptureView extends StatelessWidget {
  const CaptureView(
      {super.key,
      required this.photoPath,
      required this.message,
      required this.actions,
      required this.onClose,
      this.processing = false,
      this.actionNotice,
      this.topActions = const []});
  final String? photoPath;
  final String message;
  final Widget actions;
  final VoidCallback? onClose;
  final bool processing;
  final List<Widget> topActions;
  final String? actionNotice;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: MiCutColors.background,
        appBar: AppBar(
            toolbarHeight: 43,
            leadingWidth: 64,
            actionsPadding: const EdgeInsets.only(right: 10),
            actions: topActions,
            leading: IconButton(
                tooltip: '닫기',
                padding: EdgeInsets.zero,
                alignment: Alignment.center,
                icon: const MiCutIcon(Icons.close),
                onPressed: onClose)),
        body: LayoutBuilder(
            builder: (context, constraints) => Column(children: [
                  Expanded(
                      child: Stack(fit: StackFit.expand, children: [
                    PhotoPlaceholder(
                        path: photoPath,
                        radius: 0,
                        fit: BoxFit.contain,
                        width: double.infinity),
                    if (processing) ...[
                      const ColoredBox(color: MiCutColors.dim),
                      LayoutBuilder(builder: (context, photoBounds) {
                        final view = View.of(context);
                        final top =
                            view.padding.top / view.devicePixelRatio + 43;
                        final offset = MediaQuery.sizeOf(context).height / 2 -
                            top -
                            photoBounds.maxHeight / 2;
                        return Center(
                            child: Transform.translate(
                                offset: Offset(0, offset),
                                child: const MiCutLoading()));
                      }),
                    ],
                  ])),
                  ConstrainedBox(
                    constraints:
                        BoxConstraints(maxHeight: constraints.maxHeight * .48),
                    child: SingleChildScrollView(
                        child: SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  Spacing.screenH,
                                  Spacing.xl,
                                  Spacing.screenH,
                                  23),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ConstrainedBox(
                                        constraints: BoxConstraints(
                                            minHeight: 27 *
                                                MediaQuery.textScalerOf(context)
                                                    .scale(1)),
                                        child: actionNotice == null
                                            ? Text(message,
                                                textAlign: TextAlign.center,
                                                style: MiCutText.body18Semibold)
                                            : null),
                                    const SizedBox(height: Spacing.xl),
                                    Stack(clipBehavior: Clip.none, children: [
                                      actions,
                                      if (actionNotice != null)
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: Spacing.buttonHeight + 14,
                                          child: Center(
                                              child: DecoratedBox(
                                                  decoration: BoxDecoration(
                                                      color: MiCutColors
                                                          .savedNotice,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8)),
                                                  child: Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                              horizontal: 16,
                                                              vertical: 12),
                                                      child: Text(actionNotice!,
                                                          style: MiCutText
                                                              .detail14Regular
                                                              .copyWith(
                                                                  color: MiCutColors
                                                                      .textInverse))))),
                                        ),
                                    ]),
                                  ]),
                            ))),
                  ),
                ])),
      );
}
