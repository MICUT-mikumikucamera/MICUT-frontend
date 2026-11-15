import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../jobs/providers.dart';
import '../local/local_store.dart';
import 'collection.dart';
import 'collection_repository.dart';

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  final store = ref.watch(localStoreProvider);
  if (!kUseRealApi) return LocalCollectionRepository(store);
  return ApiCollectionRepository(
      baseUrl: kApiBaseUrl, deviceId: store.deviceId);
});

/// 컬렉션 화면과 카드 상세가 같이 쓴다.
/// 카드를 새로 얻은 뒤에는 `ref.invalidate(collectionProvider)` 로 새로고침한다.
final collectionProvider = FutureProvider<CollectionSummary>(
  (ref) => ref.watch(collectionRepositoryProvider).fetch(),
);
