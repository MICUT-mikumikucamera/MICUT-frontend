/// 컬렉션 모델. 백엔드 명세 v0.3 `GET /api/v1/collection` 응답과 1:1.
library;

/// 카드 한 장을 얻은 사진 하나.
///
/// 서버는 이미지 주소를 주지 않는다. [jobId] 로 기기에 저장된 결과 사진을 찾는다.
class CardPhoto {
  const CardPhoto({required this.jobId, required this.acquiredAt});

  final String jobId;
  final DateTime acquiredAt;

  factory CardPhoto.fromJson(Map<String, dynamic> j) => CardPhoto(
        jobId: j['job_id'] as String,
        acquiredAt: DateTime.parse(j['acquired_at'] as String),
      );
}

class CollectionCard {
  const CollectionCard({
    required this.id,
    required this.no,
    required this.name,
    this.photos = const [],
  });

  final String id;

  /// 화면의 `#001` 번호.
  final int no;

  /// 못 얻은 카드에도 이름은 온다. 화면에서는 `???` 로 가린다.
  final String name;

  /// 얻은 순서(오래된 것 먼저). 비어 있으면 아직 못 얻은 카드.
  final List<CardPhoto> photos;

  bool get acquired => photos.isNotEmpty;

  factory CollectionCard.fromJson(Map<String, dynamic> j) => CollectionCard(
        id: j['id'] as String,
        no: j['no'] as int,
        name: j['name'] as String,
        photos: ((j['photos'] as List?) ?? const [])
            .map((e) => CardPhoto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CollectionSummary {
  const CollectionSummary({
    required this.acquiredCount,
    required this.total,
    required this.cards,
  });

  /// 진행도의 분자.
  final int acquiredCount;

  /// 진행도의 분모 (12).
  final int total;

  /// `no` 순서.
  final List<CollectionCard> cards;

  CollectionCard? card(String id) =>
      cards.where((c) => c.id == id).firstOrNull;

  factory CollectionSummary.fromJson(Map<String, dynamic> j) =>
      CollectionSummary(
        acquiredCount: j['acquired_count'] as int,
        total: j['total'] as int,
        cards: ((j['cards'] as List?) ?? const [])
            .map((e) => CollectionCard.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
