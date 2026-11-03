/// 백엔드 `contracts/` 와 1:1로 맞춘 모델.
/// 필드를 바꾸면 MICUT-backend/contracts/examples/*.json 도 같이 바꿔야 한다.
library;

enum JobStatus {
  pending,
  processing,
  done,
  failed;

  static JobStatus parse(String s) =>
      JobStatus.values.firstWhere((e) => e.name == s);
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
  });

  final String imageUrl;
  final List<String> tags;
  final List<String> cardIds;

  factory JobResult.fromJson(Map<String, dynamic> j) => JobResult(
        imageUrl: j['image_url'] as String,
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        cardIds: (j['card_ids'] as List?)?.cast<String>() ?? const [],
      );
}

class CaptureInfo {
  const CaptureInfo({
    required this.w,
    required this.h,
    required this.rotation,
    this.fx,
  });

  final int w;
  final int h;
  final int rotation;
  final double? fx;

  Map<String, dynamic> toJson() =>
      {'w': w, 'h': h, 'rotation': rotation, 'fx': fx};

  factory CaptureInfo.fromJson(Map<String, dynamic> j) => CaptureInfo(
        w: j['w'] as int,
        h: j['h'] as int,
        rotation: j['rotation'] as int,
        fx: (j['fx'] as num?)?.toDouble(),
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
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTerminal =>
      status == JobStatus.done || status == JobStatus.failed;

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
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );

  Job copyWith({
    JobStatus? status,
    int? attempt,
    JobResult? result,
    JobError? error,
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
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// 업로드 자체가 실패하면 job 없이 이 예외를 던진다 (status.json 규칙).
class UploadException implements Exception {
  const UploadException(this.error);
  final JobError error;
  @override
  String toString() => 'UploadException(${error.code})';
}
