import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';
import 'capture_screen.dart';
import 'model.dart';
import 'theme.dart';
import 'save_native.dart' if (dart.library.js_interop) 'save_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final model = AppModel(
    JobsApi(
      baseUrl: const String.fromEnvironment('API_BASE_URL'),
      demoFailure: const bool.fromEnvironment('DEMO_FAILURE'),
    ),
    await SharedPreferences.getInstance(),
  );
  runApp(MiCutApp(model: model));
  unawaited(model.initialize());
}

class MiCutApp extends StatelessWidget {
  const MiCutApp({super.key, required this.model});
  final AppModel model;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MiCut',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    locale: const Locale('ko'),
    supportedLocales: const [Locale('ko')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (context, child) => ColoredBox(
      color: paper,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: child!,
        ),
      ),
    ),
    home: HomeScreen(model: model),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.model});
  final AppModel model;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _tab = 0;
  AppModel get model => widget.model;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      model.setForeground(state == AppLifecycleState.resumed);
  Future<void> _capture() async {
    if (!model.hasWork && model.capture == null) {
      final photo = await Navigator.push<Capture>(
        context,
        MaterialPageRoute(builder: (_) => CaptureScreen(demo: model.api.demo)),
      );
      if (photo == null || !mounted) return;
      model.setCapture(photo);
    }
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkflowScreen(model: model, onGallery: _gallery),
        ),
      );
    }
  }

  void _gallery() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => GalleryScreen(model: model, onCapture: _capture),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: Text(
          _tab == 0 ? 'MiCut' : '컬렉션',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      body: _tab == 2
          ? const CollectionView()
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                _HomeTile(
                  icon: Icons.circle,
                  title: '촬영하기',
                  subtitle: '미쿠와 사진을 찍어보세요',
                  large: true,
                  onTap: _capture,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HomeTile(
                        icon: Icons.rounded_corner,
                        title: '갤러리',
                        subtitle: '함께한 추억 보기',
                        onTap: _gallery,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HomeTile(
                        icon: Icons.rounded_corner,
                        title: '컬렉션',
                        subtitle: '포즈 수집하기',
                        onTap: () => setState(() => _tab = 2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '최근 사진',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: _gallery,
                      child: const Text(
                        '전체 보기 ›',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                if (model.photos.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    decoration: BoxDecoration(
                      color: paper,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        const Text('아직 사진이 없어요'),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _capture,
                          child: const Text('사진 촬영하러 가기'),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: model.photos.take(10).length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) => SizedBox(
                        width: 110,
                        child: _PhotoTile(
                          model: model,
                          photo: model.photos[index],
                          onTap: () =>
                              openPhoto(context, model, model.photos[index]),
                        ),
                      ),
                    ),
                  ),
                if (model.error != null && !model.hasWork)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Notice(
                      model.error!,
                      action: model.job == null
                          ? null
                          : TextButton(
                              onPressed: model.busy ? null : model.refresh,
                              child: const Text('상태 다시 확인'),
                            ),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: line)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _nav(
                Icons.home_filled,
                '홈',
                _tab == 0,
                () => setState(() => _tab = 0),
              ),
              _nav(
                Icons.camera_alt_outlined,
                '촬영',
                false,
                _capture,
                camera: true,
              ),
              _nav(
                Icons.view_week_rounded,
                '컬렉션',
                _tab == 2,
                () => setState(() => _tab = 2),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _nav(
    IconData icon,
    String name,
    bool selected,
    VoidCallback onTap, {
    bool camera = false,
  }) => Semantics(
    selected: selected,
    child: TextButton(
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: camera ? ink : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: camera
                  ? Colors.white
                  : selected
                  ? ink
                  : muted,
              size: 23,
            ),
          ),
          Text(
            name,
            style: TextStyle(
              color: selected || camera ? ink : muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),
  );
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.large = false,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool large;
  @override
  Widget build(BuildContext context) => Material(
    color: paper,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: large ? 44 : 8),
            if (large)
              Icon(icon, size: 44, color: ink)
            else
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFCCCCCC),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: large ? 23 : 17,
              ),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
          ],
        ),
      ),
    ),
  );
}

class WorkflowScreen extends StatefulWidget {
  const WorkflowScreen({
    super.key,
    required this.model,
    required this.onGallery,
  });
  final VoidCallback onGallery;
  final AppModel model;
  @override
  State<WorkflowScreen> createState() => _WorkflowScreenState();
}

class _WorkflowScreenState extends State<WorkflowScreen> {
  bool _saving = false, _saved = false, _allowPop = false;
  String? _saveError;
  AppModel get model => widget.model;
  Future<void> _close() async {
    if (model.busy && model.job == null) return;
    if (model.job?.status == 'failed' || model.job?.status == 'done') {
      await model.leaveResult();
      if (model.hasWork || model.error != null) return;
    } else if (model.job == null) {
      model.clearCapture();
    }
    if (!mounted) return;
    setState(() => _allowPop = true);
    Navigator.pop(context);
  }

  Future<void> _save() async {
    if (_saving || model.job?.imagePath == null) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      if (model.api.demo) {
        throw const ApiFailure('체험 모드의 예시 이미지는 사진첩에 저장하지 않아요.');
      }
      await saveImage(
        await model.api.imageBytes(model.job!.imagePath!),
        'micut_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (mounted) setState(() => _saved = true);
    } catch (e) {
      if (mounted) {
        setState(
          () => _saveError = e is ApiFailure
              ? e.message
              : '사진을 저장하지 못했어요. 사진첩 접근 권한을 확인해 주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _gallery() async {
    final callback = widget.onGallery;
    await _close();
    if (_allowPop) callback();
  }

  Future<void> _retake() async {
    if (model.busy) return;
    if (model.job != null) {
      await model.leaveResult();
      if (model.hasWork || model.error != null) return;
    } else {
      model.clearCapture();
    }
    if (!mounted) return;
    final capture = await Navigator.push<Capture>(
      context,
      MaterialPageRoute(builder: (_) => CaptureScreen(demo: model.api.demo)),
    );
    if (!mounted) return;
    if (capture == null) {
      await _close();
      return;
    }
    setState(() {
      _saved = false;
      _saveError = null;
    });
    model.setCapture(capture);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final job = model.job;
      final processing = job?.active == true;
      final failed = job?.status == 'failed';
      final done = job?.status == 'done';
      final busy = model.busy || _saving;
      return PopScope(
        canPop: _allowPop,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) unawaited(_close());
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: '닫기',
              onPressed: busy && !processing ? null : _close,
              icon: const Icon(Icons.close),
            ),
            actions: [
              if (done)
                IconButton(
                  tooltip: '공유',
                  onPressed: busy || model.api.demo
                      ? null
                      : () => sharePhoto(context, model, job!.imagePath!),
                  icon: const Icon(Icons.ios_share_outlined),
                ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: model.capture == null
                          ? Capture.cameraAspectRatio
                          : model.capture!.w / model.capture!.h,
                      child: Container(
                        color: line,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (done)
                              ResultImage(
                                model: model,
                                path: job!.imagePath!,
                                demo: model.api.demo,
                              )
                            else if (model.capture == null ||
                                model.capture!.sample)
                              const SampleImage()
                            else
                              Image.memory(
                                model.capture!.bytes,
                                fit: BoxFit.contain,
                                semanticLabel: '선택한 사진',
                              ),
                            if (processing || failed)
                              ColoredBox(
                                color: processing
                                    ? Colors.black45
                                    : Colors.black54,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(28),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (processing)
                                          const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        else
                                          const Icon(
                                            Icons.error_outline,
                                            color: Colors.white,
                                            size: 42,
                                          ),
                                        if (!processing)
                                          const SizedBox(height: 20),
                                        if (!processing)
                                          Text(
                                            job!.errorMessage,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              height: 1.6,
                                              fontSize: 16,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Flexible(
                  flex: 0,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * .43,
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (model.error != null) ...[
                              Notice(
                                model.error!,
                                action: model.job == null
                                    ? null
                                    : TextButton(
                                        onPressed: model.busy
                                            ? null
                                            : model.refresh,
                                        child: const Text('상태 다시 확인'),
                                      ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (_saveError != null) ...[
                              Notice(_saveError!),
                              const SizedBox(height: 12),
                            ],
                            if (processing) ...[
                              const Text(
                                '미쿠 사진을 만드는 중이에요',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: _close,
                                child: const Text('취소'),
                              ),
                            ] else if (failed) ...[
                              Text(
                                job!.retryable
                                    ? '같은 사진으로 다시 시도할 수 있어요.'
                                    : '다른 사진으로 다시 찍어 주세요.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: muted),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: busy ? null : _retake,
                                      child: const Text('다시 찍기'),
                                    ),
                                  ),
                                  if (job.retryable) ...[
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: busy ? null : model.retry,
                                        child: Text(busy ? '재시도 중…' : '재시도'),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ] else if (done) ...[
                              if (_saved)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    kIsWeb ? '다운로드를 시작했어요' : '사진첩에 저장했어요',
                                  ),
                                ),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: busy ? null : _retake,
                                      child: const Text('다시 찍기'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: busy
                                          ? null
                                          : _saved || model.api.demo
                                          ? _gallery
                                          : _save,
                                      child: Text(
                                        _saving
                                            ? '저장 중…'
                                            : _saved || model.api.demo
                                            ? '갤러리 보기'
                                            : '사진첩에 저장',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              const Text(
                                '이 사진에 미쿠를 불러올까요?',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: busy ? null : _retake,
                                      child: const Text('다시 찍기'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: busy ? null : model.create,
                                      child: Text(busy ? '사진 보내는 중…' : '만들기'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class ResultImage extends StatefulWidget {
  const ResultImage({
    super.key,
    required this.model,
    required this.path,
    required this.demo,
    this.fit = BoxFit.contain,
  });
  final AppModel model;
  final String path;
  final bool demo;
  final BoxFit fit;
  @override
  State<ResultImage> createState() => _ResultImageState();
}

class _ResultImageState extends State<ResultImage> {
  int _retry = 0;
  @override
  Widget build(BuildContext context) {
    if (widget.demo) return const SampleImage(result: true);
    return Image.network(
      widget.model.api.endpoint(widget.path).toString(),
      key: ValueKey(_retry),
      fit: widget.fit,
      semanticLabel: '미쿠와 함께 촬영한 사진',
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator()),
      errorBuilder: (context, error, stack) => Center(
        child: TextButton.icon(
          onPressed: () {
            NetworkImage(
              widget.model.api.endpoint(widget.path).toString(),
            ).evict();
            setState(() => _retry++);
          },
          icon: const Icon(Icons.refresh),
          label: const Text('이미지 다시 불러오기'),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.model,
    required this.photo,
    required this.onTap,
    this.selected = false,
    this.editing = false,
  });
  final AppModel model;
  final PhotoEntry photo;
  final VoidCallback onTap;
  final bool selected, editing;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '${photo.date.month}월 ${photo.date.day}일 사진',
    child: Material(
      color: paper,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ResultImage(
              model: model,
              path: photo.path,
              demo: photo.demo,
              fit: BoxFit.cover,
            ),
            if (selected)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  border: Border.all(color: ink, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            if (editing)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? ink : muted,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

void openPhoto(BuildContext context, AppModel model, PhotoEntry photo) =>
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoDetail(model: model, photo: photo),
      ),
    );

Future<bool> confirmDelete(BuildContext context, int count) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('사진 $count장을 삭제할까요?'),
        content: const Text('이 앱의 갤러리에서 삭제돼요.\n사진첩에 저장한 사진은 남아 있어요.'),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    ) ??
    false;

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({
    super.key,
    required this.model,
    required this.onCapture,
  });
  final AppModel model;
  final VoidCallback onCapture;
  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _editing = false, _deleting = false;
  final Set<String> _selected = {};
  String? _error;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: Text(_editing ? '${_selected.length}장 선택' : '갤러리'),
        leading: _editing
            ? TextButton(
                onPressed: _deleting
                    ? null
                    : () => setState(() {
                        _editing = false;
                        _selected.clear();
                      }),
                child: const Text('취소'),
              )
            : null,
        actions: [
          if (!_editing && widget.model.photos.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _editing = true),
              child: const Text('편집'),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null) Notice(_error!),
          Expanded(
            child: widget.model.photos.isEmpty
                ? EmptyView(
                    title: '아직 사진이 없어요',
                    message: '',
                    action: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onCapture();
                      },
                      child: const Text('사진 촬영하러 가기'),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: widget.model.photos.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: .78,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemBuilder: (context, index) {
                      final photo = widget.model.photos[index];
                      return _PhotoTile(
                        model: widget.model,
                        photo: photo,
                        selected: _selected.contains(photo.id),
                        editing: _editing,
                        onTap: () {
                          if (_deleting) return;
                          if (_editing) {
                            setState(() {
                              if (!_selected.add(photo.id)) {
                                _selected.remove(photo.id);
                              }
                            });
                          } else {
                            openPhoto(context, widget.model, photo);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _editing
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: FilledButton(
                  onPressed: _selected.isEmpty || _deleting
                      ? null
                      : () async {
                          if (!await confirmDelete(context, _selected.length) ||
                              !mounted) {
                            return;
                          }
                          setState(() {
                            _deleting = true;
                            _error = null;
                          });
                          try {
                            await widget.model.deletePhotos(_selected);
                            if (mounted) {
                              setState(() {
                                _selected.clear();
                                _editing = false;
                              });
                            }
                          } catch (_) {
                            if (mounted) {
                              setState(() => _error = '삭제하지 못했어요. 다시 시도해 주세요.');
                            }
                          } finally {
                            if (mounted) setState(() => _deleting = false);
                          }
                        },
                  child: Text(_deleting ? '삭제 중…' : '삭제'),
                ),
              ),
            )
          : null,
    ),
  );
}

Future<void> sharePhoto(
  BuildContext context,
  AppModel model,
  String path,
) async {
  try {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? const Rect.fromLTWH(0, 0, 1, 1)
        : box.localToGlobal(Offset.zero) & box.size;
    final bytes = await model.api.imageBytes(path);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(bytes, mimeType: 'image/jpeg', name: 'micut.jpg'),
        ],
        fileNameOverrides: ['micut.jpg'],
        sharePositionOrigin: origin,
      ),
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('공유하지 못했어요. 다시 시도해 주세요.')));
    }
  }
}

class PhotoDetail extends StatefulWidget {
  const PhotoDetail({super.key, required this.model, required this.photo});
  final AppModel model;
  final PhotoEntry photo;
  @override
  State<PhotoDetail> createState() => _PhotoDetailState();
}

class _PhotoDetailState extends State<PhotoDetail> {
  bool _busy = false;
  String? _error;
  Future<void> _act(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(() => _error = '작업을 완료하지 못했어요. 연결과 사진첩 권한을 확인해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: SizedBox.expand(
              child: ResultImage(
                model: widget.model,
                path: widget.photo.path,
                demo: widget.photo.demo,
              ),
            ),
          ),
        ),
        if (_error != null) Notice(_error!),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _action(
                  Icons.ios_share,
                  '공유',
                  widget.photo.demo
                      ? null
                      : () => _act(
                          () => sharePhoto(
                            context,
                            widget.model,
                            widget.photo.path,
                          ),
                        ),
                ),
                _action(
                  Icons.download_outlined,
                  '사진첩에 저장',
                  widget.photo.demo
                      ? null
                      : () => _act(() async {
                          await saveImage(
                            await widget.model.api.imageBytes(
                              widget.photo.path,
                            ),
                            'micut_${DateTime.now().millisecondsSinceEpoch}',
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  kIsWeb ? '사진 다운로드를 시작했어요' : '사진첩에 저장했어요',
                                ),
                              ),
                            );
                          }
                        }),
                ),
                _action(
                  Icons.delete_outline,
                  '삭제',
                  () => _act(() async {
                    if (await confirmDelete(context, 1)) {
                      await widget.model.deletePhotos({widget.photo.id});
                      if (context.mounted) Navigator.pop(context);
                    }
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  Widget _action(IconData icon, String name, VoidCallback? action) =>
      TextButton(
        onPressed: _busy ? null : action,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(height: 6),
            Text(name, style: const TextStyle(fontSize: 11)),
          ],
        ),
      );
}

const poseNames = ['브이', '하트', '꽃받침', '뒷짐 자세'];

class CollectionView extends StatelessWidget {
  const CollectionView({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: poseNames.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: .72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) => Material(
          color: paper,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PoseDetail(index: index)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: line,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '#${(index + 1).toString().padLeft(3, '0')}',
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                  Text(
                    poseNames[index],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class PoseDetail extends StatelessWidget {
  const PoseDetail({super.key, required this.index});
  final int index;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AspectRatio(
          aspectRatio: .9,
          child: Container(
            decoration: BoxDecoration(
              color: paper,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('포즈 이미지', style: TextStyle(color: muted)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '#${(index + 1).toString().padLeft(3, '0')}',
          style: const TextStyle(color: muted),
        ),
        const SizedBox(height: 6),
        Text(
          poseNames[index],
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        const Text('날짜', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('—', style: TextStyle(color: muted)),
      ],
    ),
  );
}
