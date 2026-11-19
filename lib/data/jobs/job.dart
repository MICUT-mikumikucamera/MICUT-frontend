/// 백엔드 `contracts/` 와 1:1로 맞춘 모델.
/// 필드를 바꾸면 MICUT-backend/contracts/examples/*.json 도 같이 바꿔야 한다.
library;

enum JobStatus {
  pending('pending'),

  /// AI가 사람을 1명 이상 찾아서 사용자 선택을 기다리는 중 (계약 2026-11-18).
  /// [Job.people] 이 채워져 있고, `POST /jobs/{id}/person` 으로 넘어간다.
  awaitingPerson('awaiting_person'),
  processing('processing'),
  done('done'),
  failed('failed');

  const JobStatus(this.wire);

  /// 서버가 쓰는 문자열.
  final String wire;

  static JobStatus parse(String s) =>
      JobStatus.values.firstWhere((e) => e.wire == s);
}

/// AI people.json 의 사람 한 명.
class DetectedPerson {
  const DetectedPerson({
    required this.personId,
    required this.bboxNorm,
    required this.eligible,
    this.reason,
  });

  final String personId;

  /// [왼쪽, 위, 오른쪽, 아래]. **접수 때 보낸 원본 사진 전체** 크기 대비 0~1.
  /// AI 는 원본 전체를 분석하고 crop 은 쓰지 않는다(성진님 확인 2026-11-19).
  /// 화면에는 `peopleInCrop` 으로 크롭 기준으로 바꿔 그린다.
  final List<double> bboxNorm;

  /// false 면 고를 수 없다 (예: `too_small`).
  final bool eligible;
  final String? reason;

  factory DetectedPerson.fromJson(Map<String, dynamic> j) => DetectedPerson(
        personId: j['person_id'] as String,
        bboxNorm: (j['bbox_norm'] as List)
            .map((v) => (v as num).toDouble())
            .toList(growable: false),
        eligible: j['eligible'] as bool,
        reason: j['reason'] as String?,
      );
}

/// `GET /jobs/{id}` 의 `people` — AI people.json 을 그대로 전달받는다.
class PeopleDetection {
  const PeopleDetection({
    required this.status,
    this.recommendedPersonId,
    this.people = const [],
  });

  final String status;
  final String? recommendedPersonId;
  final List<DetectedPerson> people;

  factory PeopleDetection.fromJson(Map<String, dynamic> j) => PeopleDetection(
        status: j['status'] as String,
        recommendedPersonId: j['recommended_person_id'] as String?,
        people: ((j['people'] as List?) ?? const [])
            .map((p) => DetectedPerson.fromJson(p as Map<String, dynamic>))
            .toList(growable: false),
      );
}

/// error_codes.json 의 fe_action
enum FeAction { retake, retry }

class JobError {
  const JobError({
    required this.code,
    required this.message,
    required this.retryable,
  });

  final String code;
  final String message;
  final bool retryable;

  /// retryable 이면 retry, 아니면 retake. 서버가 fe_action 을 보내주면 그걸 우선.
  FeAction get feAction => retryable ? FeAction.retry : FeAction.retake;

  factory JobError.fromJson(Map<String, dynamic> j) => JobError(
        code: j['code'] as String,
        message: j['message'] as String,
        retryable: j['retryable'] as bool,
      );
}

class JobResult {
  const JobResult({
    required this.imageUrl,
    this.tags = const [],
    this.cardIds = const [],
    this.newCardIds = const [],
  });

  final String imageUrl;
  final List<String> tags;

  /// 이 사진으로 얻은 카드 id. AI가 고른 포즈로 정해진다.
  /// 컬렉션에 없는 포즈(곡 포즈 MV*, 사람 따라하기)면 빈 배열 — 카드 없음.
  final List<String> cardIds;

  /// [cardIds] 중 이 기기가 **처음** 얻은 카드. 비어 있지 않으면 신규 획득 팝업을 띄운다.
  /// 접수 때 `X-Device-Id` 를 안 보냈으면 항상 비어 있다.
  final List<String> newCardIds;

  factory JobResult.fromJson(Map<String, dynamic> j) => JobResult(
        imageUrl: j['image_url'] as String,
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        cardIds: (j['card_ids'] as List?)?.cast<String>() ?? const [],
        newCardIds: (j['new_card_ids'] as List?)?.cast<String>() ?? const [],
      );
}

class CropRegion {
  const CropRegion(
      {required this.x,
      required this.y,
      required this.width,
      required this.height});
  final int x, y, width, height;
  Map<String, dynamic> toJson() =>
      {'x': x, 'y': y, 'width': width, 'height': height};
  factory CropRegion.fromJson(Map<String, dynamic> j) => CropRegion(
      x: j['x'] as int,
      y: j['y'] as int,
      width: j['width'] as int,
      height: j['height'] as int);
}

class CaptureInfo {
  const CaptureInfo({
    required this.w,
    required this.h,
    required this.rotation,
    this.fx,
    this.crop,
  });

  final int w;
  final int h;
  final int rotation;
  final double? fx;
  final CropRegion? crop;

  Map<String, dynamic> toJson() => {
        'w': w,
        'h': h,
        'rotation': rotation,
        'fx': fx,
        if (crop != null) 'crop': crop!.toJson()
      };

  factory CaptureInfo.fromJson(Map<String, dynamic> j) => CaptureInfo(
        w: j['w'] as int,
        h: j['h'] as int,
        rotation: j['rotation'] as int,
        fx: (j['fx'] as num?)?.toDouble(),
        crop: j['crop'] == null
            ? null
            : CropRegion.fromJson(j['crop'] as Map<String, dynamic>),
      );
}

class Job {
  const Job({
    required this.jobId,
    required this.photo,
    required this.capture,
    required this.status,
    required this.attempt,
    this.result,
    this.error,
    this.people,
    required this.createdAt,
    required this.updatedAt,
  });

  final String jobId;
  final String photo;
  final CaptureInfo capture;
  final JobStatus status;
  final int attempt;
  final JobResult? result;
  final JobError? error;

  /// [JobStatus.awaitingPerson] 일 때 AI가 찾은 사람들.
  final PeopleDetection? people;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTerminal => status == JobStatus.done || status == JobStatus.failed;

  factory Job.fromJson(Map<String, dynamic> j) => Job(
        jobId: j['job_id'] as String,
        photo: j['photo'] as String,
        capture: CaptureInfo.fromJson(j['capture'] as Map<String, dynamic>),
        status: JobStatus.parse(j['status'] as String),
        attempt: j['attempt'] as int,
        result: j['result'] == null
            ? null
            : JobResult.fromJson(j['result'] as Map<String, dynamic>),
        error: j['error'] == null
            ? null
            : JobError.fromJson(j['error'] as Map<String, dynamic>),
        people: j['people'] == null
            ? null
            : PeopleDetection.fromJson(j['people'] as Map<String, dynamic>),
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );

  Job copyWith({
    JobStatus? status,
    int? attempt,
    JobResult? result,
    JobError? error,
    PeopleDetection? people,
    bool clearResult = false,
    bool clearError = false,
    DateTime? updatedAt,
  }) =>
      Job(
        jobId: jobId,
        photo: photo,
        capture: capture,
        status: status ?? this.status,
        attempt: attempt ?? this.attempt,
        result: clearResult ? null : (result ?? this.result),
        error: clearError ? null : (error ?? this.error),
        people: people ?? this.people,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// 사람 선택 요청이 거절됨. 409 = 선택할 수 없는 상태(`PERSON_SELECT_NOT_ALLOWED`),
/// 422 = 없는 person_id 이거나 eligible=false (`INVALID_REQUEST`).
class PersonSelectException implements Exception {
  const PersonSelectException(this.statusCode, [this.code]);
  final int statusCode;
  final String? code;
  bool get notAllowed => statusCode == 409;
  @override
  String toString() => 'PersonSelectException($statusCode, $code)';
}

/// 업로드 자체가 실패하면 job 없이 이 예외를 던진다 (status.json 규칙).
class UploadException implements Exception {
  const UploadException(this.error);
  final JobError error;
  @override
  String toString() => 'UploadException(${error.code})';
}
