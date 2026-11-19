import 'dart:convert';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:micut/data/jobs/api_job_repository.dart';
import 'package:micut/data/jobs/fake_job_repository.dart';
import 'package:micut/data/jobs/job.dart';
import 'package:micut/features/capture/person_picker.dart';

/// 계약 micut_backend_contract_2026-11-18.json 예시 그대로.
Map<String, dynamic> _awaitingJson() => {
      'job_id': 'j_20261119_a1b2c3d4e5f6',
      'photo': '/uploads/j_20261119_a1b2c3d4e5f6.jpg',
      'capture': {'w': 1000, 'h': 1500, 'rotation': 0, 'fx': null},
      'status': 'awaiting_person',
      'attempt': 1,
      'people': {
        'status': 'ok',
        'recommended_person_id': 'p0',
        'people': [
          {
            'person_id': 'p0',
            'bbox_norm': [0.10, 0.15, 0.45, 0.80],
            'eligible': true
          },
          {
            'person_id': 'p1',
            'bbox_norm': [0.75, 0.20, 0.82, 0.30],
            'eligible': false,
            'reason': 'too_small'
          },
        ]
      },
      'result': null,
      'error': null,
      'created_at': '2026-11-19T10:00:00Z',
      'updated_at': '2026-11-19T10:00:05Z',
    };

void main() {
  test('awaiting_person 상태와 people 을 읽는다', () {
    final job = Job.fromJson(_awaitingJson());
    expect(job.status, JobStatus.awaitingPerson);
    expect(job.isTerminal, isFalse);
    expect(job.people!.recommendedPersonId, 'p0');
    expect(job.people!.people, hasLength(2));
    expect(job.people!.people[0].bboxNorm, [0.10, 0.15, 0.45, 0.80]);
    expect(job.people!.people[1].eligible, isFalse);
    expect(job.people!.people[1].reason, 'too_small');
  });

  test('카드 없는 결과(card_id null)는 빈 배열', () {
    final r = JobResult.fromJson({
      'image_url': '/results/x.jpg',
      'tags': ['outdoor', 'sea'],
      'card_ids': <String>[],
      'new_card_ids': <String>[],
    });
    expect(r.cardIds, isEmpty);
    expect(r.newCardIds, isEmpty);
  });

  group('peopleInCrop (bbox 원본 기준 → 크롭 화면 기준)', () {
    // 원본 1000×1500, 가운데 세로 크롭 x 0~1000, y 250~1250 (1:1)
    const crop = CropRegion(x: 0, y: 250, width: 1000, height: 1000);
    DetectedPerson person(String id, List<double> b, {bool eligible = true}) =>
        DetectedPerson(personId: id, bboxNorm: b, eligible: eligible);

    test('크롭 안 사람은 크롭 좌표로 바뀐다', () {
      final r = peopleInCrop([
        person('p0', [0.1, 0.2, 0.5, 0.6])
      ], imageWidth: 1000, imageHeight: 1500, crop: crop);
      expect(r, hasLength(1));
      // y: 300~900px → 크롭 기준 (300-250)/1000=0.05 ~ (900-250)/1000=0.65
      expect(r.single.rect.left, closeTo(0.1, 1e-9));
      expect(r.single.rect.top, closeTo(0.05, 1e-9));
      expect(r.single.rect.right, closeTo(0.5, 1e-9));
      expect(r.single.rect.bottom, closeTo(0.65, 1e-9));
    });

    test('중심이 크롭 밖이면 빠진다 (결과 사진에 안 나옴)', () {
      final r = peopleInCrop([
        person('top', [0.2, 0.0, 0.4, 0.1]), // y 0~150px, 크롭 위
        person('bottom', [0.2, 0.9, 0.4, 1.0]), // y 1350~1500px, 크롭 아래
      ], imageWidth: 1000, imageHeight: 1500, crop: crop);
      expect(r, isEmpty);
    });

    test('일부만 걸친 사람은 중심이 안이면 남고 박스는 잘린다', () {
      final r = peopleInCrop([
        person('p0', [0.1, 0.1, 0.3, 0.4])
      ], imageWidth: 1000, imageHeight: 1500, crop: crop);
      // y 150~600px, 중심 375px → 크롭 안. 위쪽은 250px 에서 잘림.
      expect(r, hasLength(1));
      expect(r.single.rect.top, closeTo(0.0, 1e-9));
      expect(r.single.rect.bottom, closeTo(0.35, 1e-9));
    });

    test('crop 이 없으면 원본 전체 기준', () {
      final r = peopleInCrop([
        person('p0', [0.1, 0.2, 0.5, 0.6])
      ], imageWidth: 1000, imageHeight: 1500);
      final rect = r.single.rect;
      expect([
        rect.left,
        rect.top,
        rect.right,
        rect.bottom
      ], [
        closeTo(0.1, 1e-9),
        closeTo(0.2, 1e-9),
        closeTo(0.5, 1e-9),
        closeTo(0.6, 1e-9)
      ]);
    });
  });

  group('ApiJobRepository.selectPerson', () {
    test('human / solo 본문', () async {
      final bodies = <Map<String, dynamic>>[];
      final repo = ApiJobRepository(
          baseUrl: 'https://api.test',
          client: MockClient((req) async {
            expect(req.url.path, '/api/v1/jobs/j1/person');
            bodies.add(jsonDecode(req.body) as Map<String, dynamic>);
            return http.Response(
                jsonEncode(_awaitingJson()..['status'] = 'processing'), 200);
          }));
      final job = await repo.selectPerson('j1', personId: 'p0');
      await repo.selectPerson('j1');
      expect(job.status, JobStatus.processing);
      expect(bodies[0], {'mode': 'human', 'person_id': 'p0'});
      expect(bodies[1], {'mode': 'solo', 'person_id': null});
    });

    test('409 → notAllowed', () async {
      final repo = ApiJobRepository(
          baseUrl: 'https://api.test',
          client: MockClient((_) async => http.Response(
              jsonEncode({
                'error': {'code': 'PERSON_SELECT_NOT_ALLOWED'}
              }),
              409)));
      await expectLater(
          repo.selectPerson('j1', personId: 'p0'),
          throwsA(isA<PersonSelectException>()
              .having((e) => e.notAllowed, 'notAllowed', isTrue)
              .having((e) => e.code, 'code', 'PERSON_SELECT_NOT_ALLOWED')));
    });
  });

  test('Fake: 사람 인식 → 선택 → 처리 → 완료', () async {
    final repo = FakeJobRepository(
        detectPeople: true, processingDelay: const Duration(milliseconds: 300));
    final created = await repo.createJob(
        XFile.fromData(Uint8List.fromList([255, 216, 255, 217]),
            name: 'c.jpg', mimeType: 'image/jpeg'),
        const CaptureInfo(w: 1, h: 1, rotation: 0));
    final waiting = await repo
        .watch(created.jobId, interval: const Duration(milliseconds: 100))
        .last;
    expect(waiting.status, JobStatus.awaitingPerson);

    await expectLater(repo.selectPerson(created.jobId, personId: 'p1'),
        throwsA(isA<PersonSelectException>()));

    final next = await repo.selectPerson(created.jobId, personId: 'p0');
    expect(next.status, JobStatus.processing);
    await expectLater(repo.selectPerson(created.jobId),
        throwsA(isA<PersonSelectException>()));

    final done = await repo
        .watch(created.jobId, interval: const Duration(milliseconds: 100))
        .last;
    expect(done.status, JobStatus.done);
  });
}
