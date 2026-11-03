import 'dart:convert';
import 'dart:io';

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
    this.cardIds = const [],
    this.savedToAlbum = false,
  });

  final String id;
  final String path;
  final DateTime createdAt;
  final List<String> cardIds;
  final bool savedToAlbum;

  GalleryItem copyWith({bool? savedToAlbum}) => GalleryItem(
        id: id,
        path: path,
        createdAt: createdAt,
        cardIds: cardIds,
        savedToAlbum: savedToAlbum ?? this.savedToAlbum,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'created_at': createdAt.toIso8601String(),
        'card_ids': cardIds,
        'saved_to_album': savedToAlbum,
      };

  factory GalleryItem.fromJson(Map<String, dynamic> j) => GalleryItem(
        id: j['id'] as String,
        path: j['path'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
        cardIds: (j['card_ids'] as List?)?.cast<String>() ?? const [],
        savedToAlbum: j['saved_to_album'] as bool? ?? false,
      );
}

/// 파일 기반 로컬 저장소. 1차 구현에서는 JSON 파일 하나면 충분하다.
class LocalStore {
  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory(p.join(base.path, 'micut'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<File> _index() async => File(p.join((await _dir()).path, 'gallery.json'));

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
  Future<GalleryItem> addFromFile(File src, {List<String> cardIds = const []}) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final dst = File(p.join((await _dir()).path, '$id.jpg'));
    await src.copy(dst.path);
    final item = GalleryItem(
      id: id,
      path: dst.path,
      createdAt: DateTime.now(),
      cardIds: cardIds,
    );
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
