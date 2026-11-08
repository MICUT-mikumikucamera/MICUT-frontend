import '../../core/widgets/micut_icon.dart';
import '../../core/widgets/micut_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/photo_share.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/photo_placeholder.dart';
import '../../data/local/local_store.dart';
import '../../data/local/poses.dart';

/// Figma card detail and full-photo story presentation share the same real data.
class CardDetailScreen extends ConsumerStatefulWidget {
  const CardDetailScreen({super.key, required this.id, this.story = false});
  final String id;
  final bool story;

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  PageController? _pageController;
  PageController get _pages => _pageController!;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width;
    final fraction = widget.story ? 1.0 : (width - 68) / (width - 20);
    if (_pageController?.viewportFraction != fraction) {
      _pageController?.dispose();
      _pageController =
          PageController(initialPage: _index, viewportFraction: fraction);
    }
  }

  int _index = 0;
  bool _sharing = false;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _share(GalleryItem photo, String name) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    await sharePhoto(context, photo.path, text: name);
    if (mounted) setState(() => _sharing = false);
  }

  @override
  Widget build(BuildContext context) {
    final pose = kPoses.where((p) => p.id == widget.id).firstOrNull;
    final gallery = ref.watch(galleryProvider);
    final memo = ref.watch(cardMemoProvider(widget.id));
    final photos = (gallery.valueOrNull ?? const <GalleryItem>[])
        .where((g) => g.cardIds.contains(widget.id))
        .toList();
    final current =
        photos.isEmpty ? null : photos[_index.clamp(0, photos.length - 1)];
    if (pose == null) {
      return Scaffold(
          appBar: AppBar(
        leading: const MiCutBackButton(),
        leadingWidth: 64,
      ));
    }
    if (gallery.isLoading) {
      return Scaffold(
          appBar: AppBar(
            leading: const MiCutBackButton(),
            leadingWidth: 64,
          ),
          body: const Center(child: CircularProgressIndicator()));
    }
    if (gallery.hasError) {
      return Scaffold(
          appBar: AppBar(
        leading: const MiCutBackButton(),
        leadingWidth: 64,
      ));
    }

    Widget actions({bool inverse = false}) => Row(
            mainAxisAlignment:
                inverse ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              IconButton(
                  tooltip: '메모 편집',
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  constraints:
                      const BoxConstraints.tightFor(width: 44, height: 44),
                  icon: const MiCutIcon(Icons.edit_outlined),
                  color: inverse
                      ? MiCutColors.iconInverse
                      : MiCutColors.iconDefault,
                  onPressed: null),
              IconButton(
                  tooltip: '공유',
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  constraints:
                      const BoxConstraints.tightFor(width: 44, height: 44),
                  icon: const MiCutIcon(Icons.ios_share),
                  color: inverse
                      ? MiCutColors.iconInverse
                      : MiCutColors.iconDefault,
                  onPressed: current == null || _sharing
                      ? null
                      : () => _share(current, pose.name)),
            ]);
    Widget photoPages({bool fullscreen = false}) => PageView.builder(
        controller: _pages,
        padEnds: false,
        onPageChanged: (i) => setState(() => _index = i),
        itemCount: photos.isEmpty ? 1 : photos.length,
        itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.only(right: fullscreen ? 0 : Spacing.md),
              child: PhotoPlaceholder(
                  path: photos.isEmpty ? null : photos[i].path,
                  width: double.infinity,
                  radius: fullscreen ? 0 : Spacing.radius20,
                  fit: BoxFit.cover),
            ));
    Widget memoText({bool inverse = false}) {
      if (memo.hasError) {
        return const SizedBox.shrink();
      }
      return Text(
          memo.isLoading
              ? ''
              : memo.valueOrNull?.isNotEmpty == true
                  ? memo.requireValue
                  : inverse
                      ? '이 사진에 남긴 메모가 표시돼요'
                      : '메모를 입력해주세요.',
          style: (inverse ? MiCutText.body16Regular : MiCutText.cardBody)
              .copyWith(
                  color: inverse
                      ? MiCutColors.textInverse
                      : MiCutColors.textDefault));
    }

    if (widget.story) {
      return Scaffold(
          backgroundColor: MiCutColors.bgInverse,
          body: Stack(fit: StackFit.expand, children: [
            photoPages(fullscreen: true),
            const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 193.264,
                child: IgnorePointer(
                    child: DecoratedBox(
                        decoration:
                            BoxDecoration(gradient: MiCutGradients.storyTop)))),
            const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 320,
                child: IgnorePointer(
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: MiCutGradients.storyBottom)))),
            SafeArea(
                child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: Spacing.screenH),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: Spacing.s10),
                          Row(children: [
                            for (var i = 0;
                                i < (photos.isEmpty ? 1 : photos.length);
                                i++) ...[
                              if (i > 0) const SizedBox(width: Spacing.xs),
                              Expanded(
                                  child: LinearProgressIndicator(
                                      value: i <= _index && photos.isNotEmpty
                                          ? 1
                                          : 0,
                                      minHeight: 3,
                                      borderRadius: BorderRadius.circular(2),
                                      color: MiCutColors.white,
                                      backgroundColor: MiCutColors.white
                                          .withValues(alpha: .35))),
                            ]
                          ]),
                          const SizedBox(height: Spacing.lg),
                          SizedBox(
                              height: 40,
                              child: Stack(children: [
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: IconButton.filled(
                                        constraints:
                                            const BoxConstraints.tightFor(
                                                width: 40, height: 40),
                                        style: IconButton.styleFrom(
                                            backgroundColor: MiCutColors.black
                                                .withValues(alpha: .45)),
                                        tooltip: '닫기',
                                        onPressed: () => context.pop(),
                                        icon: const MiCutIcon(Icons.close,
                                            color: MiCutColors.iconInverse))),
                                Center(
                                    child: Text(
                                        current == null
                                            ? '-'
                                            : _storyDate(current.createdAt),
                                        style: MiCutText.cardBody.copyWith(
                                            color: MiCutColors.textInverse))),
                              ])),
                          const Spacer(),
                          Padding(
                              padding: const EdgeInsets.all(Spacing.s10),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(pose.name,
                                        style: MiCutText.display.copyWith(
                                            color: MiCutColors.textInverse)),
                                    const SizedBox(height: Spacing.s6),
                                    ConstrainedBox(
                                        constraints: BoxConstraints(
                                            maxHeight:
                                                MediaQuery.sizeOf(context)
                                                        .height *
                                                    .2),
                                        child: SingleChildScrollView(
                                            child: memoText(inverse: true))),
                                  ])),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton.filled(
                                    tooltip: '메모 편집',
                                    onPressed: null,
                                    style: IconButton.styleFrom(
                                        backgroundColor: MiCutColors.black
                                            .withValues(alpha: .45),
                                        disabledBackgroundColor: MiCutColors
                                            .black
                                            .withValues(alpha: .45)),
                                    icon: const MiCutIcon(Icons.edit_outlined,
                                        color: MiCutColors.iconInverse)),
                                const SizedBox(width: Spacing.md),
                                IconButton.filled(
                                    tooltip: '공유',
                                    onPressed: current == null || _sharing
                                        ? null
                                        : () => _share(current, pose.name),
                                    style: IconButton.styleFrom(
                                        backgroundColor: MiCutColors.black
                                            .withValues(alpha: .45)),
                                    icon: const MiCutIcon(Icons.ios_share,
                                        color: MiCutColors.iconInverse)),
                              ]),
                        ]))),
          ]));
    }
    return Scaffold(
        appBar: AppBar(
            leading: const MiCutBackButton(),
            leadingWidth: 64,
            title: Text(pose.name)),
        body: ListView(
            padding: const EdgeInsets.only(
                top: Spacing.pageTop, bottom: Spacing.xxl),
            children: [
              SizedBox(
                  height: MediaQuery.sizeOf(context).width * 400 / 375,
                  child: Padding(
                      padding: const EdgeInsets.only(left: Spacing.screenH),
                      child: photoPages())),
              const SizedBox(height: Spacing.xl),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Spacing.screenH),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            height: 24,
                            child:
                                OverflowBox(maxHeight: 44, child: actions())),
                        const SizedBox(height: Spacing.xxl),
                        SizedBox(
                            height: 25,
                            child: Text('날짜', style: MiCutText.cardLabel)),
                        const SizedBox(height: Spacing.md),
                        Text(current == null ? '-' : _fmt(current.createdAt),
                            style: MiCutText.cardBody),
                        const SizedBox(height: Spacing.xl),
                        SizedBox(
                            height: 25,
                            child: Text('메모', style: MiCutText.cardLabel)),
                        const SizedBox(height: Spacing.md),
                        memoText(),
                      ])),
            ]));
  }

  String _storyDate(DateTime d) =>
      '${d.year}년 ${d.month.toString().padLeft(2, '0')}월 ${d.day.toString().padLeft(2, '0')}일';

  String _fmt(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}
