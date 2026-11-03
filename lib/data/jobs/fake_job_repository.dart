import 'dart:io';
import 'dart:math';

import 'job.dart';
import 'job_repository.dart';

/// 서버 없이 전체 흐름을 돌리기 위한 가짜 구현.
/// 백엔드 contracts/examples/*.json 과 같은 모양으로 응답한다.
///
/// [scenario] 로 결과를 고정할 수 있다:
///  - [FakeScenario.success]  : pending → processing → done
///  - [FakeScenario.retryable]: AI_TIMEOUT (재시도 가능)
///  - [FakeScenario.retake]   : PERSON_NOT_FOUND (다시 찍기)
///  - [FakeScenario.random]   : 위 셋 중 랜덤
class FakeJobRepository extends JobRepository {
  FakeJobRepository({
    this.scenario = FakeScenario.success,
    this.processingDelay = const Duration(seconds: 3),
  });

  final FakeScenario scenario;
  final Duration processingDelay;

  final _jobs = <String, Job>{};
  final _photos = <String, File>{};
  final _rand = Random();

  @override
  Future<Job> createJob(File photo, CaptureInfo capture) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    final id = 'j_${_date(now)}_${_randomHex(12)}';
    final job = Job(
      jobId: id,
      photo: '/uploads/$id.jpg',
      capture: capture,
      status: JobStatus.pending,
      attempt: 1,
      createdAt: now,
      updatedAt: now,
    );
    _jobs[id] = job;
    _photos[id] = photo;
    _schedule(id);
    return job;
  }

  @override
  Future<Job> getJob(String jobId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final job = _jobs[jobId];
    if (job == null) throw StateError('unknown job $jobId');
    return job;
  }

  @override
  Future<Job> retry(String jobId) async {
    final job = await getJob(jobId);
    if (job.status != JobStatus.failed || job.error?.retryable != true) {
      throw StateError('job $jobId is not retryable');
    }
    final next = job.copyWith(
      status: JobStatus.pending,
      attempt: job.attempt + 1,
      clearError: true,
      updatedAt: DateTime.now(),
    );
    _jobs[jobId] = next;
    _schedule(jobId, forceSuccess: true);
    return next;
  }

  @override
  Future<void> discard(String jobId) async {
    final job = _jobs[jobId];
    if (job == null) return;
    _photos.remove(jobId);
    if (job.error != null) {
      _jobs[jobId] = job.copyWith(
        error: JobError(
          code: job.error!.code,
          message: job.error!.message,
          retryable: false,
        ),
      );
    }
  }

  /// Fake 는 원본 파일 경로를 그대로 돌려준다 (합성 전 사진이 결과로 보임).
  /// 실제 합성 느낌을 내려면 assets/samples/ 에 샘플을 넣고 여기서 바꿔치기.
  @override
  String resolveImageUrl(String path) {
    final id = path.split('/').last.split('.').first;
    return _photos[id]?.path ?? path;
  }

  void _schedule(String id, {bool forceSuccess = false}) {
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      final j = _jobs[id];
      if (j == null) return;
      _jobs[id] = j.copyWith(
          status: JobStatus.processing, updatedAt: DateTime.now());
    });
    Future<void>.delayed(processingDelay, () {
      final j = _jobs[id];
      if (j == null) return;
      final s = forceSuccess ? FakeScenario.success : _resolve();
      _jobs[id] = switch (s) {
        FakeScenario.success || FakeScenario.random => j.copyWith(
            status: JobStatus.done,
            result: JobResult(
              imageUrl: '/results/$id.jpg',
              tags: const ['indoor', 'day'],
              cardIds: const ['001'],
            ),
            updatedAt: DateTime.now(),
          ),
        FakeScenario.retryable => j.copyWith(
            status: JobStatus.failed,
            error: const JobError(
              code: 'AI_TIMEOUT',
              message: '처리가 오래 걸렸어요',
              retryable: true,
            ),
            updatedAt: DateTime.now(),
          ),
        FakeScenario.retake => j.copyWith(
            status: JobStatus.failed,
            error: const JobError(
              code: 'PERSON_NOT_FOUND',
              message: '사진에서 사람을 찾지 못했어요. 전신이 나오게 다시 찍어주세요',
              retryable: false,
            ),
            updatedAt: DateTime.now(),
          ),
      };
    });
  }

  FakeScenario _resolve() {
    if (scenario != FakeScenario.random) return scenario;
    const pool = [
      FakeScenario.success,
      FakeScenario.success,
      FakeScenario.retryable,
      FakeScenario.retake,
    ];
    return pool[_rand.nextInt(pool.length)];
  }

  String _date(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  String _randomHex(int n) {
    const chars = '0123456789abcdef';
    return List.generate(n, (_) => chars[_rand.nextInt(16)]).join();
  }
}

enum FakeScenario { success, retryable, retake, random }
