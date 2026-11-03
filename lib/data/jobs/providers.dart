import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_job_repository.dart';
import 'fake_job_repository.dart';
import 'job_repository.dart';

/// 서버 연결 스위치.
///
///   기본                                → FakeJobRepository (서버 없이 동작)
///   flutter run --dart-define=MICUT_REAL_API=true --dart-define=MICUT_API_URL=http://... → ApiJobRepository
///
/// 에뮬레이터에서 PC의 localhost 는 10.0.2.2.
const bool kUseRealApi = bool.fromEnvironment('MICUT_REAL_API');
const String kApiBaseUrl =
    String.fromEnvironment('MICUT_API_URL', defaultValue: 'http://10.0.2.2:8000');

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  if (kUseRealApi) return ApiJobRepository(baseUrl: kApiBaseUrl);
  return FakeJobRepository(scenario: FakeScenario.random);
});
