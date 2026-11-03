# MiCut BE 앱 연결 API 명세 v0

Nov 1, 2026 · @윤종욱

## 1. 백엔드 스택과 명세 공유 방식

백엔드는 **Python + FastAPI**로 개발하고, Flutter와는 **HTTP + JSON**으로만 주고받아요.

| 시점 | 명세 보는 곳 |
| --- | --- |
| 지금 | 이 문서 + BE 레포 `contracts/v0` 브랜치의 `contracts/examples/` (응답 예시 JSON, 가짜 데이터로 바로 사용 가능) |
| 서버 주소 공유 전 | `openapi.json` 파일 공유 → editor.swagger.io에 붙여 넣으면 Swagger 화면으로 확인 |
| 서버가 올라간 뒤 | `서버주소/docs`의 Swagger가 최종 기준. 거기서 API를 직접 호출해 볼 수 있음 |

## 2. 기본 흐름과 공통 규칙

앱은 사진을 보내 `job_id`를 받고, 그 번호로 상태를 반복 조회해 결과를 받아요.

1. 사진 전송 → `job_id` 받기
2. `job_id`로 1\~2초마다 상태 조회 (폴링)
3. `done` → 결과 이미지 다운로드 / `failed` → 재시도 또는 다시 찍기

**공통**

- 응답은 모두 JSON
- `image_url`은 경로만 줘요 → 앱에서 서버 주소를 앞에 붙여서 사용
- 시간은 한국 시간 ISO 형식 (`2026-11-05T14:00:00+09:00`)
- 로그인 없음
- `job_id`는 랜덤 값이에요 (예: `j_20261105_a1b2c3d4e5f6`). 형식에 의존하지 말고 문자열 그대로 쓰시면 돼요.

## 3. API

### ① 사진 접수

`POST /api/v1/jobs` · `multipart/form-data`

| 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| photo | 파일 | O | 촬영한 사진 |
| w | int | O | 사진 가로 픽셀 |
| h | int | O | 사진 세로 픽셀 |
| rotation | int | O | 회전 각도 (예: 90) |
| fx | float | X | 카메라 초점거리, 모르면 안 보내도 됨 |

응답 `201`

```json
{
  "job_id": "j_20261105_a1b2c3d4e5f6",
  "photo": "/uploads/j_20261105_a1b2c3d4e5f6.jpg",
  "capture": { "w": 3024, "h": 4032, "rotation": 90, "fx": null },
  "status": "pending",
  "attempt": 1,
  "result": null,
  "error": null,
  "created_at": "2026-11-05T14:00:00+09:00",
  "updated_at": "2026-11-05T14:00:00+09:00"
}
```

### ② 상태 조회

`GET /api/v1/jobs/{job_id}`

응답 모양은 ①과 같아요. AI가 실패해도 조회 자체는 성공이라 `200`이고, 성공·실패는 `status`로 판단해 주세요.

| status | 화면 | 채워지는 필드 |
| --- | --- | --- |
| pending | 처리 중 | - |
| processing | 처리 중 | - |
| done | 결과 화면 | result |
| failed | 실패 안내 | error |

done일 때

```json
"result": { "image_url": "/results/j_20261105_a1b2c3d4e5f6.jpg", "tags": ["outdoor", "day"], "card_ids": [] }
```

- `tags`: AI가 분류한 장면 태그 (목록은 아직 미정)
- `card_ids`: 획득한 카드 (v0에서는 빈 배열)

failed일 때

```json
"error": { "code": "AI_TIMEOUT", "message": "처리가 오래 걸렸어요", "retryable": true }
```

### ③ 재시도

`POST /api/v1/jobs/{job_id}/retry` · 바디 없음

- `failed`이면서 `retryable: true`인 작업만 가능해요.
- 같은 `job_id`가 다시 `pending`이 되고 `attempt`가 +1 돼요. 이후 다시 상태 조회하면 돼요.

### ④ 재시도 안 함

`POST /api/v1/jobs/{job_id}/discard` · 바디 없음

- 실패 화면에서 사용자가 재시도 대신 **다시 찍기 / 닫기**를 누르면 호출해 주세요.
- 응답 `204` (본문 없음)
- 호출하면 그 작업의 `error.retryable`이 `false`로 바뀌고, 이후 재시도할 수 없어요.

### ⑤ 결과 이미지

`GET {서버주소}{image_url}` → 이미지 파일

### ⑥ 서버 확인

`GET /health` → `{"status": "ok"}`

## 4. 에러 처리와 사진 보관

실패는 항상 같은 모양이고, 화면은 `retryable`로 나눠요 (`true` 재시도 버튼, `false` 다시 찍기 안내). `message`는 사용자에게 그대로 보여 줘도 돼요.

```json
{ "status": "failed", "error": { "code": "UPLOAD_TOO_LARGE", "message": "사진 용량이 너무 커요", "retryable": false } }
```

| code | 상황 | retryable | 화면 |
| --- | --- | --- | --- |
| UPLOAD\_INVALID\_FORMAT | 지원하지 않는 사진 형식 | false | 다시 찍기 |
| UPLOAD\_TOO\_LARGE | 용량 초과 | false | 다시 찍기 |
| PERSON\_NOT\_FOUND | 사람 인식 실패 | false | 다시 찍기 |
| FOOT\_LOW\_CONFIDENCE | 발이 잘 안 보임 | false | 다시 찍기 |
| AI\_TIMEOUT | 처리 시간 초과 | true | 재시도 |
| RENDER\_FAILED | 렌더링 실패 | true | 재시도 |
| INTERNAL\_ERROR | 기타 서버 오류 | true | 재시도 |

**사진 보관**

- 원본 사진은 합성이 끝나거나, 재시도하지 않기로 하면 서버에서 삭제돼요. 그래서 응답의 `photo`는 앱에서 쓰지 말아 주세요.
- 재시도 가능한 실패를 discard 없이 그냥 두면, 24시간 뒤 서버가 자동으로 discard 처리해요. 그 뒤에는 재시도할 수 없어요.
- 결과 이미지는 서버에 남아 있어서 `image_url`로 다시 받을 수 있어요.

## 5. FE 확인 요청과 확정 전 항목

**FE에 확인 부탁드릴 것**

- [ ] `w`, `h`를 파일에 저장된 그대로의 크기(회전 적용 전 기준)로 보내 주실 수 있는지
- [ ] 폴링 간격 1\~2초 괜찮은지
- [ ] 에러별 화면이 "재시도 / 다시 찍기" 두 가지로 충분한지
- [ ] 실패 화면에서 다시 찍기 / 닫기를 누를 때 discard 호출이 가능한지
- [ ] 이 외에 화면에 필요한 정보가 있는지

**아직 확정 전 (BE 내부 확인 중)**

- 서버 주소 (폰에서 접속할 주소는 추후 공유)
- 허용 사진 형식·최대 용량, 세부 HTTP 상태 코드
- 없는 작업 조회, 재시도 불가 작업에 retry 요청 등 일부 에러 코드 추가 여부
- AI 연결 전까지는 서버에서 `done`·`failed`가 나오지 않아요. 그 화면은 `contracts/examples/job_done.json`, `job_failed.json`을 가짜 데이터로 써서 만들어 주세요.
