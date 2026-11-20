import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micut/core/services/photo_bytes.dart';
import 'package:micut/data/jobs/fake_job_repository.dart';
import 'package:micut/data/jobs/job.dart';

void main() {
  test('byte-only captures survive preview jobs without invented awards',
      () async {
    final bytes = Uint8List.fromList([255, 216, 255, 217]);
    final repo =
        FakeJobRepository(processingDelay: const Duration(milliseconds: 850));
    final created = await repo.createJob(
        XFile.fromData(bytes, name: 'capture.jpg', mimeType: 'image/jpeg'),
        const CaptureInfo(w: 1, h: 1, rotation: 0, fx: null));
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final job = await repo.getJob(created.jobId);
    expect(job.status, JobStatus.done);
    expect(job.result!.cardIds, isEmpty);
    final result = repo.resolveImageUrl(job.result!.imageUrl);
    expect(result, startsWith('data:image/jpeg;base64,'));
    expect(await readPhotoBytes(result), bytes);
  });
}
