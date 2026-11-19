import 'package:cross_file/cross_file.dart';

import 'job.dart';

/// 서버와의 모든 통신은 이 인터페이스를 통한다.
/// 화면은 Fake 인지 Api 인지 몰라야 한다.
abstract class JobRepository {
  /// 사진 업로드 → job 생성. 업로드 실패는 [UploadException].
  Future<Job> createJob(XFile photo, CaptureInfo capture);

  /// 상태 조회.
  Future<Job> getJob(String jobId);

  /// retryable 실패를 다시 돌린다. status → pending, attempt +1.
  Future<Job> retry(String jobId);

  /// [JobStatus.awaitingPerson] 에서 미쿠가 따라할 사람을 고른다.
  /// [personId] 가 있으면 `mode: human`, null 이면 `mode: solo`(따라하지 않기).
  /// 성공하면 processing 으로 바뀐 Job. 거절되면 [PersonSelectException].
  Future<Job> selectPerson(String jobId, {String? personId});

  /// 실패 화면에서 재시도 대신 닫기/다시 찍기. 원본 삭제, retryable → false.
  Future<void> discard(String jobId);

  /// 결과 이미지 전체 URL. 상대 경로(/results/...)를 절대 URL로.
  String resolveImageUrl(String path);

  /// 완료/실패/사람 선택 대기까지 폴링. [interval] 마다 getJob.
  /// awaiting_person 에서 멈추므로, 선택 후에는 다시 watch 한다.
  Stream<Job> watch(String jobId,
      {Duration interval = const Duration(seconds: 2)}) async* {
    while (true) {
      final job = await getJob(jobId);
      yield job;
      if (job.isTerminal || job.status == JobStatus.awaitingPerson) return;
      await Future<void>.delayed(interval);
    }
  }
}
