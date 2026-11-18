import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/local_store.dart';
import 'api_job_repository.dart';
import 'fake_job_repository.dart';
import 'job_repository.dart';

/// 서버 주소는 빌드할 때 넣는다.
///
///   flutter build apk --release \
///     --dart-define=API_BASE_URL=https://micut-backend.onrender.com
///
/// 비어 있으면 서버 없이 도는 [FakeJobRepository] 를 쓴다.
/// `MICUT_REAL_API` / `MICUT_API_URL` 은 예전 이름이라 당분간 같이 받는다.
const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
const String _legacyUrl = String.fromEnvironment('MICUT_API_URL',
    defaultValue: 'http://10.0.2.2:8000');
const bool _legacyOn = bool.fromEnvironment('MICUT_REAL_API');

const String kApiBaseUrl =
    _apiBaseUrl != '' ? _apiBaseUrl : (_legacyOn ? _legacyUrl : '');
const bool kUseRealApi = kApiBaseUrl != '';

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  if (!kUseRealApi) return FakeJobRepository(scenario: FakeScenario.random);
  return ApiJobRepository(
    baseUrl: kApiBaseUrl,
    deviceId: ref.watch(localStoreProvider).deviceId,
  );
});
