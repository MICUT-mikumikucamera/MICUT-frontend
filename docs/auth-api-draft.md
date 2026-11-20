# 미컷 인증 API 명세 초안

작성일: 2026-11-18 · 상태: 백엔드 협의용 초안 · 대상: Flutter 프런트엔드 / Python FastAPI 백엔드

Google 로그인 후 기존 회원은 홈으로, 신규 회원은 닉네임 입력과 약관 동의를 거쳐 홈으로 이동합니다. 이 문서는 해당 흐름에 필요한 API, 요청·응답, 오류 및 기존 사진 API 변경을 정의합니다. 서버 구현 완료나 합의된 계약을 의미하지 않습니다.

기존 기준: 저장소 루트의 `MiCut BE 앱 연결 API 명세 v0.md` 및 `COLLECTION.md`(2026-11-13, 컬렉션 v0.3). 컬렉션 관련 사항은 더 최신인 v0.3을 우선합니다. COLLECTION.md가 참조하는 백엔드 전체 `docs/API.md`는 이번 작업에서 제공되지 않았으므로 서버 최종 계약과 추가 대조가 필요합니다. 기존 명세의 `/api/v1`, JSON, 한국 시간 ISO 8601 형식을 유지합니다. 기존의 “로그인 없음” 조건은 인증 도입 시 변경됩니다. 닉네임 2~20자는 사용자 확정 요구사항이며, 아래 토큰 수명·닉네임 중복 정책·API 경로는 제안입니다.

## 1. 구현 범위와 합의할 기본값

| 항목 | 초안 기준 |
| --- | --- |
| 로그인 공급자 | Google만 지원. 자체 비밀번호 로그인 없음 |
| 회원 식별 | 내부 `user_id`, Google 계정 연결은 검증된 `sub`로 식별. 이메일 기준 자동 병합 금지 |
| 가입 완료 조건 | Google 검증 + 유효한 닉네임 + 최신 필수 약관 2종 동의 |
| 닉네임 | 사용자에게 보이는 글자 단위 2~20자. 중복 허용 제안; 별도 중복 확인 API 없음 |
| access token | 미컷 API 전용, 유효기간 15분 제안 |
| refresh token | 미컷 세션 전용, 세션 최초 발급부터 최대 30일 제안; 갱신마다 교체 |
| onboarding token | 가입 완료 전용, 10분 제안; 사진 API 접근 불가 |
| 기기별 로그인 | 복수 세션 허용; 로그아웃은 현재 세션만 폐기 |
| 필수 구현 | Google 검증, 가입 완료, 약관 메타데이터, 내 정보, 갱신, 로그아웃, 사진·컬렉션 소유권 검사, 계정별 로컬 자료 분리 |
| 별도 출시 범위 협의 | 탈퇴 API(이 문서에 제안 포함), 기존 회원 약관 재동의, 닉네임 변경, 기존 기기 컬렉션 이전 |

이 초안의 토큰 JSON 전송 방식은 Android/iOS 네이티브 앱 기준입니다. 웹은 현재 UI 미리보기만 있으며, 실제 웹 인증 출시 시 HttpOnly 쿠키 기반 세션과 CSRF/CORS 계약을 별도로 확정합니다. 네이티브 refresh token 계약을 그대로 웹 localStorage에 적용하지 않습니다.

## 2. 공통 규칙

- 기본 경로: `/api/v1`. 서버 주소는 환경별 별도 전달.
- 운영 환경 HTTPS. JSON 요청은 `Content-Type: application/json`.
- 일반 인증: `Authorization: Bearer <access_token>`.
- 가입 인증: `Authorization: Bearer <onboarding_token>`; `/auth/onboarding`에서만 허용.
- access / refresh / onboarding 토큰은 서로 대체할 수 없습니다. Google ID 토큰은 `/auth/google`에서만 교환합니다.
- 인증 성공·오류 및 개인정보 응답에 `Cache-Control: no-store` 적용.
- 시간: 오프셋 포함 ISO 8601, 예시 `2026-11-18T14:00:00+09:00`. `*_expires_in`은 응답 시점 기준 남은 초, 양의 정수입니다.
- ID와 토큰은 불투명 문자열로 취급. 예시 값은 가짜이며 실제 인증에 사용할 수 없습니다.
- 성공 응답은 공통 `data` 래퍼 없이 반환. `204`에는 본문이 없습니다.
- 필수 필드 누락·타입 오류는 `422`. FastAPI 기본 validation 오류도 아래 공통 오류 형태로 변환합니다.
- 요청의 임의 `user_id`나 이메일로 로그인 주체·사진 소유자를 결정하지 않습니다.

### 공통 오류 형식

```json
{
  "error": {
    "code": "NICKNAME_INVALID",
    "message": "닉네임은 2~20자로 입력해 주세요.",
    "retryable": false,
    "details": [{"field": "nickname", "reason": "TOO_SHORT"}]
  },
  "request_id": "req_example_001"
}
```

`code`는 프런트 분기용 고정 문자열, `message`는 사용자 안내용입니다. `details`는 배열이며 해당 항목이 없으면 `[]`. `request_id`는 서버 추적 ID입니다. `retryable`은 조건을 수정하지 않고 나중에 재시도할 수 있는 오류인지 나타내며, 자동 재전송 허가를 뜻하지 않습니다. 토큰·인증 헤더·Google ID 토큰·전체 요청 본문은 로그에 기록하지 않습니다.

## 3. API 목록

| 메서드 | 경로 | 인증 | 성공 |
| --- | --- | --- | --- |
| POST | `/auth/google` | Google ID 토큰을 본문으로 전달 | 200 |
| GET | `/legal/documents` | 없음 | 200 |
| POST | `/auth/onboarding` | onboarding token | 201 |
| GET | `/me` | access token | 200 |
| GET | `/collection` | access token (기존 v0.3 기기 인증에서 전환 제안) | 200 |
| POST | `/auth/refresh` | refresh token을 본문으로 전달 | 200 |
| POST | `/auth/logout` | refresh token을 본문으로 전달 | 204 |
| DELETE | `/me` | access token + 최근 Google 재인증 | 202 (출시 범위 협의) |

표의 경로 앞에 `/api/v1`을 붙입니다.

## 4. Google 로그인

`POST /api/v1/auth/google`

```json
{"id_token": "<Google SDK에서 받은 ID token>"}
```

`id_token`: 필수 문자열. Google access token이나 authorization code가 아닙니다. 앱이 전달한 Google 사용자 프로필·이메일·이름은 신원 검증의 근거로 사용하지 않습니다.

서버는 공식 라이브러리로 서명, `aud`(서버에 설정한 허용 Client ID), `iss`, `exp`를 검증하고 `sub`를 계정 연결 키로 사용합니다. 운영·개발 클라이언트 허용 목록을 분리하고 요청 본문의 임의 Client ID를 신뢰하지 않습니다. 이메일은 검증된 토큰의 부가 정보이며 누락 시 null을 허용합니다. [Google 서버 검증 지침](https://developers.google.com/identity/gsi/web/guides/verify-google-id-token)

### 기존 회원 응답 200

```json
{
  "status": "authenticated",
  "user": {
    "user_id": "u_example_001",
    "nickname": "미쿠팬",
    "email": "tester@example.com",
    "created_at": "2026-11-18T14:00:00+09:00"
  },
  "session": {
    "token_type": "Bearer",
    "access_token": "<micut_access_token>",
    "access_expires_in": 900,
    "refresh_token": "<micut_refresh_token>",
    "refresh_expires_in": 2592000
  }
}
```

### 신규 회원 응답 200

```json
{
  "status": "onboarding_required",
  "onboarding_token": "<micut_onboarding_token>",
  "onboarding_expires_in": 600
}
```

두 응답은 `status`로 구분되는 상호 배타적인 형태입니다. 신규 회원 응답에는 `user`와 `session`을 포함하지 않습니다. 정식 회원 생성은 가입 완료 트랜잭션에서 수행합니다. Google 로그인을 다시 하면 새 가입 토큰을 발급할 수 있지만 같은 `sub`에 정식 회원을 중복 생성하지 않습니다.

오류: `401 GOOGLE_TOKEN_INVALID`, `403 ACCOUNT_DISABLED`, `503 IDENTITY_PROVIDER_UNAVAILABLE`, `429 RATE_LIMITED`. Google 키 조회 장애를 잘못된 사용자 토큰으로 취급하지 않습니다. Google 계정 선택 취소는 SDK 단계에서 처리하며 이 API를 호출하지 않습니다.

## 5. 약관 메타데이터 조회

`GET /api/v1/legal/documents` · 요청 본문 없음

```json
{
  "documents": [
    {
      "type": "terms_of_service",
      "version": "2026-11-18",
      "title": "이용약관",
      "required": true,
      "url": "https://example.com/terms/2026-11-18",
      "effective_at": "2026-11-18T00:00:00+09:00"
    },
    {
      "type": "privacy_policy",
      "version": "2026-11-18",
      "title": "개인정보 처리방침",
      "required": true,
      "url": "https://example.com/privacy/2026-11-18",
      "effective_at": "2026-11-18T00:00:00+09:00"
    }
  ]
}
```

`type`은 위 2개 enum, `version`은 비교·저장용 불투명 문자열입니다. 각 type은 한 번씩 반환합니다. URL은 로그인 없이 열리는 실제 HTTPS 문서이며 예시 주소를 운영에 사용하지 않습니다. 동일 버전의 본문을 변경하지 않고 동의 당시 버전을 보존합니다. 문서 미설정 상태에서는 가입을 열지 않으며 `503 LEGAL_DOCUMENTS_UNAVAILABLE`을 반환합니다.

현재 앱은 약관 URL을 환경 설정으로 받지만, 실제 연결 시 이 API의 URL·버전을 기준으로 화면과 가입 요청을 맞추는 프런트 수정이 필요합니다. 필수 항목의 법적 성격·문구는 운영 정책 확정 대상이며 이 API가 법적 충분성을 보장하지 않습니다.

## 6. 가입 완료

`POST /api/v1/auth/onboarding`

```http
Authorization: Bearer <onboarding_token>
Content-Type: application/json
```

```json
{
  "nickname": "미쿠팬",
  "consents": [
    {"type": "terms_of_service", "version": "2026-11-18", "accepted": true},
    {"type": "privacy_policy", "version": "2026-11-18", "accepted": true}
  ]
}
```

| 필드 | 형식·조건 |
| --- | --- |
| nickname | 필수 문자열. 아래 검증 규칙 적용 |
| consents | 필수 배열. 현재 필수 2개 type이 각각 한 번씩 존재 |
| type | `/legal/documents`의 enum |
| version | 현재 적용 버전과 정확히 동일 |
| accepted | JSON boolean `true`. 문자열 `"true"`는 불가 |

서버 시각으로 동의 일시를 기록합니다. 클라이언트의 동의 시각은 받지 않습니다. 사용자 생성·Google 연결·동의 이력 기록·가입 토큰 소비를 하나의 트랜잭션으로 처리하고 `(provider, sub)`에 고유 제약을 둡니다. 가입 토큰이 만료되거나 검증에 실패하면 아무 데이터도 부분 생성하지 않습니다.

성공 `201`: 4절 기존 회원 응답과 동일한 `status`, `user`, `session` 구조. `user.nickname`은 저장된 최종 값입니다.

가입 토큰은 1회 사용합니다. 성공 후 동일 토큰 재전송은 `409 ONBOARDING_ALREADY_COMPLETED`이며 새 세션을 재발급하지 않습니다. 응답 유실 시 프런트는 Google 로그인을 다시 진행하여 기존 회원 세션을 얻습니다. 동시 가입 요청도 정식 회원 1명만 생성합니다.

오류: `401 ONBOARDING_TOKEN_EXPIRED`, `401 ONBOARDING_TOKEN_INVALID`, `409 ONBOARDING_ALREADY_COMPLETED`, `409 LEGAL_VERSION_CHANGED`, `422 REQUIRED_CONSENT_MISSING`, `422 NICKNAME_INVALID`, `422 VALIDATION_ERROR`.

약관 버전 변경 시 약관 API를 다시 조회하고 기존 체크를 해제한 뒤 재동의합니다. 입력한 닉네임은 유지합니다.

### 닉네임 검증

- 확정 길이: 2~20 extended grapheme clusters. Python `len()`이나 UTF-16 코드 단위 길이로 세지 않습니다. Flutter `characters`와 동일 입력 표본을 비교합니다.
- 입력을 자동 trim·절단·유니코드 정규화하지 않고 받은 값을 검증·저장하는 초안입니다. 정규화 도입 시 양쪽을 함께 변경합니다.
- 공백과 이모지 불가. 현재 프런트의 정확한 호환 기준은 `lib/features/auth/nickname_rules.dart`입니다. 그 외 문자(예: 한글·영문·숫자·일반 기호)를 새로 제한하지 않습니다.
- 프런트는 whitespace 정규식 및 U+200B/U+200C/U+200D/U+FEFF를 금지합니다. 서버의 whitespace 정의가 다를 수 있으므로 공통 테스트 표본을 합의합니다.
- 현재 프런트가 금지하는 추가 코드포인트: U+1F000–1FAFF, U+2600–27BF, U+2300–23FF, U+2B00–2BFF, U+FE0F, U+20E3, U+00A9, U+00AE, U+203C, U+2049, U+2122, U+2139, U+3030, U+303D, U+3297, U+3299. 이는 포괄적인 Unicode emoji 표준 구현이 아니라 현재 앱과의 호환 규칙입니다. 변경 시 프런트도 동시에 수정합니다.
- `details[].reason`: `TOO_SHORT`, `TOO_LONG`, `DISALLOWED_CHARACTER`.
- 예: `미쿠` 통과, `가` 실패, `가` 20개 통과, 21개 실패, `미 쿠` 실패, `미쿠😀` 실패, 결합 문자 `éé`는 2자로 통과.

## 7. 내 정보 조회

`GET /api/v1/me` · access token 필요 · 요청 본문 없음

성공 `200`:

```json
{
  "user_id": "u_example_001",
  "nickname": "미쿠팬",
  "email": "tester@example.com",
  "created_at": "2026-11-18T14:00:00+09:00"
}
```

`email`만 null 허용. 나머지는 필수 문자열입니다. 앱 재실행 후 저장된 세션 복원·홈 진입 확인에 사용합니다. 가입 미완료 토큰으로 조회하면 `401 ACCESS_TOKEN_INVALID`입니다. 닉네임 변경 API는 이번 필수 범위에 포함하지 않습니다.

## 8. 세션 갱신

`POST /api/v1/auth/refresh` · access token 불필요

```json
{"refresh_token": "<current_micut_refresh_token>"}
```

성공 `200`:

```json
{
  "session": {
    "token_type": "Bearer",
    "access_token": "<new_micut_access_token>",
    "access_expires_in": 900,
    "refresh_token": "<new_micut_refresh_token>",
    "refresh_expires_in": 2500000
  }
}
```

`refresh_expires_in`은 최초 세션의 30일 절대 만료까지 남은 시간입니다. 갱신할 때마다 30일을 다시 시작하지 않습니다. 기존 refresh token 소비와 새 토큰 발급은 원자적으로 수행하고 서버에는 원문 대신 해시를 저장합니다.

교체된 토큰 재사용을 감지하면 그 세션의 토큰 계열을 모두 폐기하고 `401 REFRESH_TOKEN_REUSED`를 반환합니다. 클라이언트는 갱신을 동시에 여러 번 호출하지 않고 한 요청으로 합쳐 처리합니다. 갱신 응답 유실 시 사용했던 토큰을 무한 재전송하지 않고 재로그인으로 복구합니다. 회전·재사용 탐지 설계 참고: [RFC 9700 4.14](https://www.rfc-editor.org/rfc/rfc9700.html#section-4.14).

오류: `401 REFRESH_TOKEN_INVALID`, `401 REFRESH_TOKEN_EXPIRED`, `401 REFRESH_TOKEN_REUSED`, `401 SESSION_REVOKED`, `403 ACCOUNT_DISABLED`.

## 9. 로그아웃

`POST /api/v1/auth/logout` · access token이 만료되어도 호출 가능

```json
{"refresh_token": "<current_micut_refresh_token>"}
```

성공 `204`: 현재 refresh token이 속한 세션 전체 폐기. 같은 요청 반복이나 이미 폐기된/알 수 없는 토큰도 `204`; 본문 누락·타입 오류는 `422`. 다른 기기의 세션은 유지합니다.

서버는 보호 API마다 세션 폐기·사용자 상태를 확인하여 기존 access token도 즉시 차단합니다. JWT 서명과 만료만 검사하는 방식은 이 계약을 충족하지 않습니다. 프런트는 로그아웃 시 로컬 토큰을 삭제합니다. 네트워크 오류로 서버 폐기가 완료되지 않았다면 원격 세션까지 종료했다고 표시하지 않습니다.

## 10. 회원 탈퇴 제안

현재 화면 구현 범위 밖이지만 출시 전 지원 여부를 확정합니다.

`DELETE /api/v1/me` · access token 필요

```json
{"google_id_token": "<방금 재인증해서 받은 Google ID token>"}
```

서버는 Google 토큰 검증 후 현재 회원의 `sub`와 일치하는지 확인하고, `iat`가 최근 5분 이내인지 확인합니다(허용 clock skew 60초 제안). 다른 계정이면 `403 REAUTH_ACCOUNT_MISMATCH`, 오래된 토큰이면 `401 REAUTH_REQUIRED`.

성공 `202`:

```json
{"status": "deletion_pending", "requested_at": "2026-11-18T14:00:00+09:00"}
```

삭제 작업을 안정적으로 등록한 뒤 반환하며 계정 접근과 모든 세션은 즉시 차단합니다. 서버 사진·결과·job·프로필·컬렉션 획득 이력 삭제 범위, 완료 기한, 보존 예외, 재가입 정책은 운영자와 확정해야 합니다. 응답은 삭제 접수이며 즉시 물리 삭제 완료를 뜻하지 않습니다. 로컬 저장 사진은 서버가 삭제할 수 없으므로 프런트가 별도 처리합니다.

## 11. 오류와 화면 동작

| HTTP | code | 프런트 처리 |
| --- | --- | --- |
| 400 | MALFORMED_JSON | 요청 형식 오류 안내·개발 로그 확인 |
| 401 | GOOGLE_TOKEN_INVALID | Google 로그인 다시 시도 |
| 401 | ACCESS_TOKEN_EXPIRED | 갱신 1회 시도 후 원래 조회 재시도 |
| 401 | ACCESS_TOKEN_INVALID / AUTH_REQUIRED | 로컬 인증 정리 후 로그인 |
| 401 | ONBOARDING_TOKEN_EXPIRED / ONBOARDING_TOKEN_INVALID | 가입 토큰 정리 후 Google 로그인 |
| 401 | REFRESH_TOKEN_INVALID / REFRESH_TOKEN_EXPIRED / REFRESH_TOKEN_REUSED / SESSION_REVOKED | 토큰 정리 후 세션 만료 화면, 버튼으로 로그인 |
| 403 | ACCOUNT_DISABLED | 접근 차단 안내, 무한 재로그인 금지 |
| 404 | RESOURCE_NOT_FOUND | 없는 자료와 타인 소유 자료를 동일하게 처리 |
| 409 | LEGAL_VERSION_CHANGED | 최신 약관 조회·체크 해제·재동의 |
| 409 | ONBOARDING_ALREADY_COMPLETED | Google 로그인으로 세션 재취득 |
| 422 | NICKNAME_INVALID | 닉네임 입력 아래 오류 |
| 422 | REQUIRED_CONSENT_MISSING | 약관 동의 상태 확인 |
| 422 | VALIDATION_ERROR | details의 필드별 오류 표시 |
| 429 | RATE_LIMITED | Retry-After 초 이후 재시도 가능 안내 |
| 503 | IDENTITY_PROVIDER_UNAVAILABLE / LEGAL_DOCUMENTS_UNAVAILABLE | 잠시 후 재시도 안내 |
| 500 | INTERNAL_ERROR | request_id 기록, 일반 오류 안내 |

`retryable=true`: 429, 503, 500. 나머지는 false. 로그인 취소, 오프라인, 일반 네트워크 오류를 세션 만료로 오인하지 않습니다. 자동 갱신은 갱신 API 자체에 다시 적용하지 않습니다. 인증 실패 응답은 가능한 한 업무 처리 전에 반환합니다.

## 12. 사진·컬렉션 API의 인증 전환

### 12.1 v0.3 현재 계약과 인증 도입 후 제안

`COLLECTION.md`(2026-11-13, v0.3)에 따르면 서버는 이미 **기기별 카드 획득 기록**을 저장합니다. 사진 파일과 메모는 기기에 저장합니다. 따라서 컬렉션 전체가 로컬 데이터라는 기존 초안 설명을 아래와 같이 정정합니다.

| 구분 | 현재 v0.3 | 인증 도입 후 제안 |
| --- | --- | --- |
| 소유자 기준 | `X-Device-Id` | 검증된 access token의 `user_id` |
| 사진 접수 | 기기 헤더 선택. 없으면 카드만 결정하고 컬렉션 기록 안 함 | access token 필수. 계정 컬렉션에 기록 |
| 컬렉션 조회 | 기기 헤더 필수 | access token 필수. 해당 계정의 기록만 조회 |
| 최초 획득 판정 | 해당 기기에서 처음 획득 | 해당 계정에서 처음 획득 |
| 서버 보관 | 카드별 `job_id`, `acquired_at` | 동일 구조를 계정별로 관리 |
| 로컬 보관 | 결과 이미지와 `job_id`, 메모 | `user_id`별로 분리한 이미지·job 매핑·메모 |

인증 전환 후 `X-Device-Id`는 사용자 인증·소유권 증명이 아닙니다. 인증 헤더와 함께 오더라도 계정 선택이나 기록 합치기에 사용하지 않고, 본 초안에서는 무시합니다. 유효한 기기 ID를 보내도 access token이 없으면 `401 AUTH_REQUIRED`, 잘못된 토큰이면 `401 ACCESS_TOKEN_INVALID`입니다. 기기 방식으로 자동 fallback하지 않습니다.

기존 v0.3의 `X-Device-Id` 누락/형식 오류 `422 INVALID_REQUEST`는 **기존 기기 기반 경로**의 계약입니다. 인증 전환 후에는 기기 헤더를 요구하지 않습니다. 본문 검증 `422`와 인증 실패 `401`을 구분합니다. 기존 앱의 무인증 동작 보장은 v0.3에만 해당하며, 동일 `/api/v1` 경로의 인증 필수화는 호환성이 깨지는 변경입니다. 배포 전에 최소 앱 버전·전환 일정을 합의해야 합니다. 구버전 지원이 필요하면 별도 레거시 경로/버전과 종료 시점을 정의하고, 계정 데이터와 분리합니다.

### 12.2 계정 컬렉션 조회

`GET /api/v1/collection` · access token 필수 · 요청 본문 없음

```http
Authorization: Bearer <access_token>
```

응답 `200`: v0.3의 필드명과 정렬을 유지합니다. 다음은 카드 12장을 모두 포함한 예시입니다.

```json
{
  "acquired_count": 1,
  "total": 12,
  "cards": [
    {"id": "gyaru_peace", "no": 1, "name": "갸루 피스", "photos": []},
    {"id": "v_sign", "no": 2, "name": "브이", "photos": [
      {"job_id": "j_example_001", "acquired_at": "2026-11-18T14:00:00+09:00"}
    ]},
    {"id": "half_heart", "no": 3, "name": "반하트", "photos": []},
    {"id": "full_heart", "no": 4, "name": "완전 하트", "photos": []},
    {"id": "wave", "no": 5, "name": "손 인사", "photos": []},
    {"id": "miku_arms", "no": 6, "name": "미쿠 양팔", "photos": []},
    {"id": "kiss", "no": 7, "name": "뽀뽀", "photos": []},
    {"id": "cheek_poke", "no": 8, "name": "볼콕", "photos": []},
    {"id": "flower_pose", "no": 9, "name": "꽃받침", "photos": []},
    {"id": "gdg_pose", "no": 10, "name": "GDG 포즈", "photos": []},
    {"id": "alien_fingers", "no": 11, "name": "손가락으로 외계인 따라하기", "photos": []},
    {"id": "leek", "no": 12, "name": "대파 들기", "photos": []}
  ]
}
```

- `acquired_count`: `photos`가 비어 있지 않은 카드 종류 수. 사진 수가 아닙니다. `total`은 현재 12.
- `cards`: `no` 오름차순. 잠긴 카드도 이름이 오며 앱은 `???`로 표시합니다.
- `photos`: 획득 시각 오름차순. 같은 시각에는 `job_id` 순으로 고정하는 것을 제안합니다.
- `photos[].job_id`: 로컬 사진을 찾는 연결 키. `acquired_at`은 서버 획득 시각입니다.
- 이미지 URL·메모는 응답에 추가하지 않습니다. 별도 클라우드 사진·메모 동기화 계약을 의미하지 않습니다.
- 오류: `401 AUTH_REQUIRED / ACCESS_TOKEN_INVALID / ACCESS_TOKEN_EXPIRED / SESSION_REVOKED`, `403 ACCOUNT_DISABLED`. onboarding token은 허용하지 않습니다.

### 12.3 카드 획득과 최초 획득 판정

`POST /api/v1/jobs`에서 인증된 계정 소유자를 고정하고, 이후 작업이 `done`이 될 때 **서버가** 카드 결정과 계정 컬렉션 기록을 수행합니다. 클라이언트에서 획득 등록 API를 따로 호출하지 않습니다. 로그아웃·계정 전환 중 작업이 완료되어도 접수 당시 소유자에게 기록합니다.

상태 조회 `GET /api/v1/jobs/{job_id}`의 `done` 응답 중 `result` 예시:

```json
{
  "image_url": "/results/j_example_001-1.png",
  "tags": [],
  "card_ids": ["v_sign"],
  "new_card_ids": ["v_sign"]
}
```

- `card_ids`: 해당 사진으로 얻은 카드. 현재는 1장이나 배열 형태 유지.
- `new_card_ids`: 해당 job이 완료될 때 **계정 전체 기준** 최초 획득한 카드만 포함. 같은 계정의 다른 기기에서 이미 얻었다면 `[]`.
- 같은 카드의 추가 획득은 `photos`에 기록하고 `acquired_count`는 증가시키지 않습니다. 최초 획득 판정·기록을 원자적으로 처리하여 동시 job 2개가 같은 카드를 최초 획득했다고 중복 반환하지 않게 합니다.
- 제안 고유 제약: 카드 획득 상태 `(user_id, card_id)`, 사진별 획득 이력 `(user_id, card_id, job_id)`. worker 재실행·완료 이벤트 중복 처리에도 중복 이력이 생기지 않아야 합니다.
- 저장된 job의 `new_card_ids`는 이후 폴링 때 다시 계산하거나 비우지 않습니다. 팝업 표시 여부는 앱이 `(user_id, job_id)`별로 관리해 반복 폴링·재접속 시 중복 표시하지 않습니다. 기기 간 팝업 확인 동기화는 이번 범위 밖입니다.
- retry 끝에 `done`이 되면 그때 획득하며, 실패·discard만으로 획득하지 않습니다. 기존 retry/discard 조건과 multipart `photo/w/h/rotation/fx/crop`은 유지합니다.
- 2026-11-13 이전에 완료된 job의 두 배열이 비어 있는 v0.3 이력은 그대로 유지합니다. 임의로 과거 획득을 재생성하지 않습니다.
- 현재 카드 선택은 서버 무작위 방식입니다. 인증 도입이 포즈 인식 구현을 뜻하지 않으며, 추후 포즈 기반으로 바뀌어도 응답 구조는 유지합니다.

### 12.4 기존 기기 기록 이전 정책

**초안 기본 제안: 기존 기기 컬렉션을 로그인 계정으로 자동 이전하지 않습니다.** 기존 서버 기록을 즉시 삭제하지 않고 별도 보존하며 보존 기한은 운영 정책으로 확정합니다. 새 계정의 컬렉션은 새로 시작하고, 기존 계정은 자신의 기록을 그대로 조회합니다. 이는 확정된 제품 정책이 아니며 인증 배포 전에 이전 필요 여부를 반드시 결정해야 합니다.

현재 `X-Device-Id`는 클라이언트가 만든 1~64자 식별 문자열(영문·숫자·`-`·`_`)입니다. 그 값을 알고 있다는 사실만으로 기록 소유권을 입증할 수 없으므로 로그인/가입 본문에 `device_id`를 넣는 것만으로 귀속시키지 않습니다. 가입 성공 시 몰래 병합하지도 않습니다.

기록 이전을 지원하기로 결정하면 **별도 이전 계약**에 다음을 정의한 뒤 구현합니다. 이번 초안에 실행 가능한 이전 API를 임의로 추가하지 않습니다.

- 구 설치의 소유권을 확인할 수단과 사용자에게 이전 대상 계정을 확인시키는 흐름. 기존 ID만 남은 설치에서 입증할 수 없는 기록은 자동 이전하지 않음.
- 같은 기기 기록을 다른 계정에 중복 귀속하지 않는 1회 처리, 중복 요청·중단 후 재개 규칙.
- 서버 카드 이력뿐 아니라 연결된 job·이미지 접근 권한까지 함께 이전. 접근 권한 없는 job을 계정 컬렉션에 연결하지 않음.
- 대상 계정의 기존 기록과 병합 시 `(card_id, job_id)` 중복 제거·원래 획득 시각 보존·진행도 재계산. 이관만으로 신규 획득 팝업을 만들거나 과거 job의 `new_card_ids`를 다시 생성하지 않음.
- 이전 중인 pending/processing job 처리와 동시 완료 충돌 정책.
- 로컬 이미지·메모의 계정 귀속은 별도 처리. 서버 기록 이전 성공이 사진 파일·메모 복원 성공을 의미하지 않음.

### 12.5 사진 접근과 로컬 데이터

- `GET /api/v1/jobs/{job_id}`, `/retry`, `/discard`는 소유자만 허용. 타인 job과 없는 job은 동일한 `404 RESOURCE_NOT_FOUND`.
- `/uploads/...`, `/results/...`는 인증 헤더를 받는 보호 다운로드로 제안하며 프런트 이미지 로더 수정이 필요합니다. 공개 CDN을 쓰면 제한 수명의 서명 URL 계약을 함께 정의합니다. 경로를 안다는 이유로 공개 접근을 허용하지 않습니다.
- `/health`, 약관 메타데이터, 약관 공개 페이지는 인증 불필요.
- 같은 계정으로 다른 기기에 로그인하면 서버 컬렉션 진행도·획득 이력은 같지만, 결과 이미지와 메모는 그 기기에 없을 수 있습니다. 로컬 파일 부재를 미획득으로 판단하거나 서버 컬렉션을 삭제하지 않습니다. 앱은 사진 미보유 상태를 표시해야 하며, 서버 파일 보관·재다운로드 보장은 별도 합의입니다.
- 로컬 파일·메모·캐시는 최소 `(user_id, job_id)`로 구분합니다. 계정 전환·로그아웃 시 이전 계정 자료를 새 계정 화면에 노출하지 않고, 늦게 도착한 이전 계정 요청 응답도 새 계정 캐시에 쓰지 않습니다. 미귀속 과거 로컬 자료 역시 자동 귀속하지 않습니다.
- 로그아웃은 서버 컬렉션을 지우지 않습니다. 탈퇴 처리에는 계정별 카드 획득 상태·사진 연결 이력과 관련 job의 삭제 정책을 포함합니다. 로컬 사진·메모의 보존/삭제는 사용자 안내와 함께 별도 결정합니다.

업로드·retry 같은 변경 요청은 응답 유실 후 무조건 재전송하면 중복 작업이 발생할 수 있습니다. 완료 이벤트의 중복 방지와 사진 접수 API 자체의 멱등성은 별개입니다. 실제 재시도 전략은 jobs 계약과 함께 확정합니다.


## 13. 프런트 연결 작업

현재 `AuthGateway`는 인터페이스만 있고 실제 구현은 없습니다. UI 미리보기는 인증·세션을 저장하지 않습니다.

1. Google SDK 설정 후 ID token을 `/auth/google`로 교환.
2. `authenticated`는 안전한 세션 저장 후 홈, `onboarding_required`는 가입 토큰을 메모리에 보관하고 닉네임 화면.
3. 약관 API에서 URL·버전을 받아 전체보기 및 가입 요청에 사용. 현재 boolean-only `completeOnboarding` 구현에 버전 전달/보관 추가.
4. 네이티브 refresh token은 플랫폼 보안 저장소에 보관. access token은 메모리 사용을 기본으로 하고 재실행 시 refresh로 복원.
5. 공통 HTTP 인증 처리와 갱신 동시 호출 방지 추가. 기존 jobs 요청·컬렉션 조회·이미지 다운로드에 적용. 인증 전환 후 소유권 기준으로 X-Device-Id를 사용하지 않음.
6. 컬렉션 진행도·획득 이력은 서버 응답을 기준으로 표시. 사진·메모는 계정별 로컬 매핑으로 조회하고 파일 없는 상태를 처리. 신규 획득 팝업은 서버 new_card_ids를 사용하고 계정/job별 중복 표시 방지.
7. 갱신 불가 시 기존 세션 만료 화면 연결. 미리보기 플래그를 실제 인증의 우회 수단으로 사용하지 않음.

## 14. 백엔드 전달·완료 확인 항목

백엔드에서 확정해 전달할 것:

- 이 초안에 대한 경로·필드·닉네임 중복·토큰 수명 변경 의견.
- 개발/운영 API 주소, 허용 Google Client ID 목록과 환경 분리 방식.
- 실제 약관 2종 URL, 버전, 발효 시각.
- OpenAPI JSON 또는 개발 서버 `/docs`, 각 성공 분기와 오류 예시.
- 네이티브 우선 여부, 실제 웹 인증 포함 여부, 탈퇴 범위와 데이터 보존·삭제 정책.
- 기존 기기 기반 사진·컬렉션 API의 인증 필수화 일정, 구버전 지원 여부 및 프런트 동시 배포 계획.
- 기존 기기 기록의 이전 지원 여부·소유권 입증·보존 기한, 계정별 사진·메모 분리 및 사진 미보유 상태 처리.
- 서버 컬렉션과 연결된 이미지의 보관·재다운로드 범위. 전체 docs/API.md 또는 최신 OpenAPI와의 최종 대조.

수용 테스트:

- 정상 Google 신규/기존 계정 분기, 잘못된 서명·aud·iss·만료 거부, 이메일이 아닌 sub로 식별.
- 가입 전 토큰의 사진 API 접근 차단, 같은 계정 동시 가입에도 회원 1명만 생성.
- 닉네임 1/2/20/21자, 공백·이모지·결합 문자 경계, 동의 누락·중복·구버전 거부.
- access 만료 후 갱신, refresh 회전·재사용 감지·만료·동시 호출, 응답 유실 후 재로그인 복구.
- 로그아웃 후 기존 access/refresh 모두 차단, 다른 기기 세션 유지.
- 다른 계정의 job·컬렉션·이미지 접근 및 retry/discard 차단. X-Device-Id만으로 인증 우회 불가.
- 같은 계정의 두 기기에서 컬렉션 진행도 일치, 같은 카드 동시 획득 시 신규 판정 1회, worker/폴링 중복에 이력·팝업 중복 없음.
- 다른 기기 로그인 시 로컬 사진·메모 부재 처리, 계정 전환 시 캐시와 늦은 응답 분리, 과거 기기 기록 자동 병합 없음.
- 이전 지원 시 소유권 검증·중복 이전 차단·job 권한 일관성·진행 중 작업 충돌 처리 검증.
- 인증 공급자 장애와 사용자 토큰 오류 구분, 429 Retry-After, 토큰 미로깅.
- 탈퇴 포함 시 최근 재인증·본인 일치·전 세션 폐기·삭제 작업 완료 검증.

인증 API 구현·연동은 아직 수행하지 않았습니다. Google OAuth 설정과 실제 약관 URL 준비도 별도로 필요합니다.
