import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../local/local_store.dart';
import '../local/poses.dart';
import 'collection.dart';

/// 컬렉션 조회. 화면은 Api 인지 Local 인지 몰라야 한다.
abstract class CollectionRepository {
  Future<CollectionSummary> fetch();
}

/// 명세 v0.3 `GET /api/v1/collection`. `X-Device-Id` 헤더가 필수다.
class ApiCollectionRepository implements CollectionRepository {
  ApiCollectionRepository({
    required this.baseUrl,
    required this.deviceId,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Future<String> Function() deviceId;
  final http.Client _client;

  @override
  Future<CollectionSummary> fetch() async {
    final res = await _client.get(
      Uri.parse('$baseUrl/api/v1/collection'),
      headers: {'X-Device-Id': await deviceId()},
    );
    if (res.statusCode >= 400) {
      throw HttpException('${res.statusCode} ${res.request?.url}');
    }
    return CollectionSummary.fromJson(
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
  }
}

/// 서버를 못 부를 때. 기기에 저장된 갤러리의 `card_ids` 로 컬렉션을 만든다.
/// 카드 목록과 순서는 [kPoses] 를 쓴다.
class LocalCollectionRepository implements CollectionRepository {
  LocalCollectionRepository(this._store);

  final LocalStore _store;

  @override
  Future<CollectionSummary> fetch() async {
    final items = await _store.loadGallery();
    final byCard = <String, List<CardPhoto>>{};
    // loadGallery 는 최신순이다. 컬렉션은 얻은 순서(오래된 것 먼저)로 보여준다.
    for (final item in items.reversed) {
      for (final id in item.cardIds) {
        (byCard[id] ??= []).add(
          CardPhoto(jobId: item.jobId ?? item.id, acquiredAt: item.createdAt),
        );
      }
    }
    final cards = [
      for (final pose in kPoses)
        CollectionCard(
          id: pose.id,
          no: pose.no,
          name: pose.name,
          photos: byCard[pose.id] ?? const [],
        ),
    ];
    return CollectionSummary(
      acquiredCount: cards.where((c) => c.acquired).length,
      total: cards.length,
      cards: cards,
    );
  }
}
