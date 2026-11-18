import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/services/photo_bytes.dart';
import 'data/local/local_store.dart';
import 'data/jobs/fake_job_repository.dart';
import 'data/jobs/providers.dart';

/// Browser entrypoint: session-only storage; real API requires MICUT_REAL_API.
void main() {
  runApp(ProviderScope(overrides: [
    localStoreProvider.overrideWithValue(BrowserPreviewStore()),
    if (!kUseRealApi)
      jobRepositoryProvider.overrideWithValue(FakeJobRepository()),
  ], child: const MiCutApp()));
}

class BrowserPreviewStore extends LocalStore {
  final _items = <GalleryItem>[];
  final _memos = <String, String>{};
  @override
  Future<List<GalleryItem>> loadGallery() async => List.of(_items);
  @override
  Future<GalleryItem> addFromBytes(Uint8List bytes,
      {String? jobId, List<String> cardIds = const []}) async {
    if (bytes.isEmpty) throw ArgumentError('Photo is empty');
    final now = DateTime.now();
    final item = GalleryItem(
        id: now.microsecondsSinceEpoch.toString(),
        path: photoDataUri(bytes),
        createdAt: now,
        jobId: jobId,
        cardIds: cardIds);
    _items.insert(0, item);
    return item;
  }

  /// 브라우저에는 파일 저장소가 없다. 세션 동안만 같은 ID를 쓴다.
  @override
  Future<String> deviceId() async => _sessionDeviceId ??=
      DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  String? _sessionDeviceId;

  @override
  Future<void> markSaved(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) _items[index] = _items[index].copyWith(savedToAlbum: true);
  }

  @override
  Future<void> delete(Iterable<String> ids) async {
    final selected = ids.toSet();
    _items.removeWhere((item) => selected.contains(item.id));
  }

  @override
  Future<String> loadCardMemo(String cardId) async => _memos[cardId] ?? '';
  @override
  Future<void> saveCardMemo(String cardId, String memo) async {
    _memos[cardId] = memo;
  }
}
