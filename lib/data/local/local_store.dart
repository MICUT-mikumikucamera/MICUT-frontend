import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 앱 내부 갤러리 항목. 결과 이미지를 앱 문서 폴더에 복사해 보관한다.
/// (사진첩 저장은 별도 액션. 09-3 "사진첩에 저장하지 않은 이미지는 사라져요")
class GalleryItem {
  const GalleryItem({
    required this.id,
    required this.path,
    required this.createdAt,
    this.jobId,
    this.cardIds = const [],
    this.savedToAlbum = false,
  });

  final String id;
  final String path;
  final DateTime createdAt;

  /// 이 사진을 만든 서버 작업 id. 컬렉션 응답의 `photos[].job_id` 와 맞춰
  /// 카드 상세에서 사진을 찾을 때 쓴다. 예전에 저장한 사진은 null 이다.
  final String? jobId;
  final List<String> cardIds;
  final bool savedToAlbum;

  GalleryItem copyWith({bool? savedToAlbum}) => GalleryItem(
        id: id,
        path: path,
        createdAt: createdAt,
        jobId: jobId,
        cardIds: cardIds,
        savedToAlbum: savedToAlbum ?? this.savedToAlbum,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'created_at': createdAt.toIso8601String(),
        if (jobId != null) 'job_id': jobId,
        'card_ids': cardIds,
        'saved_to_album': savedToAlbum,
      };

  factory GalleryItem.fromJson(Map<String, dynamic> j) => GalleryItem(
        id: j['id'] as String,
        path: j['path'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
        jobId: j['job_id'] as String?,
        cardIds: (j['card_ids'] as List?)?.cast<String>() ?? const [],
        savedToAlbum: j['saved_to_album'] as bool? ?? false,
      );
}

/// 파일 기반 로컬 저장소. 1차 구현에서는 JSON 파일 하나면 충분하다.
class LocalStore {
  LocalStore({Directory? directory}) : _directory = directory;
  final Directory? _directory;
  Future<Directory> _dir() async {
    final base = _directory ?? await getApplicationDocumentsDirectory();
    final d = Directory(p.join(base.path, 'micut'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<File> _index() async =>
      File(p.join((await _dir()).path, 'gallery.json'));

  Future<List<GalleryItem>> loadGallery() async {
    final f = await _index();
    if (!await f.exists()) return const [];
    final list = jsonDecode(await f.readAsString()) as List;
    return list
        .map((e) => GalleryItem.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _saveGallery(List<GalleryItem> items) async {
    final f = await _index();
    await f.writeAsString(jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  /// 결과 이미지(로컬 파일 경로 또는 URL)를 앱 폴더로 복사해 갤러리에 추가.
  Future<GalleryItem> addFromFile(File src,
          {String? jobId, List<String> cardIds = const []}) async =>
      addFromBytes(await src.readAsBytes(), jobId: jobId, cardIds: cardIds);

  Future<GalleryItem> addFromBytes(Uint8List bytes,
      {String? jobId, List<String> cardIds = const []}) async {
    if (bytes.isEmpty) throw ArgumentError('Photo is empty');
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final dst = File(p.join((await _dir()).path, '$id.jpg'));
    await dst.writeAsBytes(bytes, flush: true);
    final item = GalleryItem(
        id: id,
        path: dst.path,
        createdAt: DateTime.now(),
        jobId: jobId,
        cardIds: cardIds);
    final items = await loadGallery();
    await _saveGallery([item, ...items]);
    return item;
  }

  Future<void> markSaved(String id) async {
    final items = await loadGallery();
    await _saveGallery([
      for (final i in items) i.id == id ? i.copyWith(savedToAlbum: true) : i,
    ]);
  }

  Future<void> delete(Iterable<String> ids) async {
    final set = ids.toSet();
    final items = await loadGallery();
    for (final i in items.where((i) => set.contains(i.id))) {
      final f = File(i.path);
      if (await f.exists()) await f.delete();
    }
    await _saveGallery(items.where((i) => !set.contains(i.id)).toList());
  }

  Future<String> loadCardMemo(String cardId) async {
    final file = File(p.join((await _dir()).path, 'card-memos.json'));
    if (!await file.exists()) return '';
    final values =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return values[cardId] as String? ?? '';
  }

  Future<void> saveCardMemo(String cardId, String memo) async {
    final file = File(p.join((await _dir()).path, 'card-memos.json'));
    final values = await file.exists()
        ? jsonDecode(await file.readAsString()) as Map<String, dynamic>
        : <String, dynamic>{};
    values[cardId] = memo;
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(values), flush: true);
    await temporary.rename(file.path);
  }

  /// 기기 구분용 ID. 명세 v0.3 의 `X-Device-Id` 헤더에 쓴다.
  ///
  /// 처음 부를 때 만들어 파일에 저장하고 그 뒤로는 같은 값을 돌려준다.
  /// 앱을 지우면 새로 만들어지므로 컬렉션도 처음부터 시작한다.
  /// 형식: 영문 소문자·숫자 32자 (명세는 1~64자, 영문·숫자·`-`·`_` 허용).
  Future<String> deviceId() async {
    final cached = _deviceId;
    if (cached != null) return cached;
    final file = File(p.join((await _dir()).path, 'device-id.txt'));
    if (await file.exists()) {
      final saved = (await file.readAsString()).trim();
      if (saved.isNotEmpty) return _deviceId = saved;
    }
    final random = Random.secure();
    final created =
        List.generate(32, (_) => '0123456789abcdef'[random.nextInt(16)]).join();
    await file.writeAsString(created, flush: true);
    return _deviceId = created;
  }

  String? _deviceId;

  /// Fake 로그인 상태. 실제 로그인은 서버가 세션을 들고 있으므로 Fake 에서만 쓴다.
  Future<Map<String, dynamic>?> loadAuthState() async {
    final file = File(p.join((await _dir()).path, 'auth.json'));
    if (!await file.exists()) return null;
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  }

  Future<void> saveAuthState(Map<String, dynamic> state) async {
    final file = File(p.join((await _dir()).path, 'auth.json'));
    await file.writeAsString(jsonEncode(state), flush: true);
  }

  /// 수집한 카드 ID 집합 (갤러리 항목의 card_ids 합집합).
  Future<Set<String>> collectedCardIds() async {
    final items = await loadGallery();
    return {for (final i in items) ...i.cardIds};
  }
}

final localStoreProvider = Provider<LocalStore>((_) => LocalStore());

/// 갤러리 목록. 변경 후 `ref.invalidate(galleryProvider)` 로 새로고침.
final galleryProvider = FutureProvider<List<GalleryItem>>(
  (ref) => ref.watch(localStoreProvider).loadGallery(),
);

final collectedCardIdsProvider = FutureProvider<Set<String>>(
  (ref) => ref.watch(localStoreProvider).collectedCardIds(),
);

final cardMemoProvider = FutureProvider.family<String, String>(
  (ref, id) => ref.watch(localStoreProvider).loadCardMemo(id),
);
