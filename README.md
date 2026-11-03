# MiCut frontend

Flutter로 구현한 미컷 카메라 앱. Figma의 홈, 촬영, 확인, 처리 중, 결과, 갤러리, 편집/삭제, 사진 상세, 컬렉션/카드 상세 구성을 따릅니다.

## 실행

Flutter 3.44.4 / Dart 3.12.2 기준입니다.

```sh
flutter pub get
flutter run
# 브라우저에서 UI 확인
flutter run -d chrome
# 재시도 가능한 AI 실패 → 재시도 → 성공 체험
flutter run --dart-define=DEMO_FAILURE=true
# 실제 백엔드 연결 (주소는 팀에서 공유받은 값으로 교체)
flutter run --dart-define=API_BASE_URL=https://your-api.example
```

`API_BASE_URL`이 없으면 개발용 mock 응답을 사용합니다. 제품 화면에는 개발용 배지나 체험 버튼을 넣지 않습니다. 테스트는 모델에 예시 사진을 직접 주입합니다. 백엔드 `contracts/v0`의 실제 예시 JSON으로 동작하며 합성 이미지를 만들거나 실제 사진을 업로드하지 않습니다. mock 결과는 Figma의 회색 이미지 자리로 표시되고 사진첩 저장/공유는 제공하지 않습니다.

## API 연결

- `POST /api/v1/jobs`: JPEG multipart `photo`, 실제 파일의 `w`, `h`, `rotation`. `fx`는 생략합니다.
- EXIF 회전·반전을 먼저 반영한 JPEG로 정규화하므로 전송 파일은 항상 `rotation=0`입니다. 원본 파일을 수정하지 않습니다. HEIC처럼 현재 디코더가 지원하지 않는 입력은 JPEG/PNG 선택 안내를 표시합니다.
- `GET /api/v1/jobs/{job_id}`: 이전 응답을 받은 후 1.5초 뒤 조회. `done`/`failed`에서 중단하고, 연결 실패 시 수동 상태 재확인을 제공합니다.
- 앱 비활성화 시 폴링을 멈추고 복귀 시 다시 조회합니다. 작업 ID를 기기에 보관해 앱 재시작 후 상태를 복구합니다.
- `failed && error.retryable`인 경우만 retry. 실패에서 닫기/다시 찍기는 discard 성공 후 진행합니다. discard 실패 시 오류와 작업을 유지합니다.
- 진행 중 취소 API가 없으므로 Figma의 **취소**는 현재 결과 대기 화면을 닫습니다. 서버 작업은 계속되며 촬영 진입에서 같은 작업을 다시 확인합니다.
- 상대 `image_url`을 설정한 서버 origin 기준으로 해석합니다. 서버의 원본 `photo` 경로는 화면에서 사용하지 않습니다.
- 자동 업로드 재시도는 하지 않습니다. 업로드 응답 유실 시 서버에 생성된 작업을 찾는 API/멱등성 키가 없다는 계약상의 제약이 있습니다.
- `/health`는 앱 실행의 선행 조건으로 사용하지 않습니다.

원본 명세: [docs/api-v0.md](docs/api-v0.md). 예시 출처: [MICUT-backend contracts/v0](https://github.com/MICUT-mikumikucamera/MICUT-backend/tree/contracts/v0/contracts/examples).

## 저장·권한

- 갤러리는 이 기기의 생성 결과 주소/날짜를 기록합니다. 사진 파일의 별도 오프라인 캐시는 없으며 서버 이미지 보관에 의존합니다.
- 사진첩 저장은 명시적인 저장 동작에서만 실행됩니다. Android/iOS 권한 설명을 포함했습니다. 웹은 다운로드를 시작합니다.
- 갤러리 삭제는 앱의 로컬 기록만 제거하며 서버 이미지나 OS 사진첩 파일을 삭제하지 않습니다.
- 서버 주소별로 갤러리/작업 기록을 구분합니다. 체험 기록도 실제 서버 기록과 분리합니다.
- 카메라 오디오/마이크를 사용하지 않습니다. 권한 거절 시 앨범 선택 및 재시도 안내가 제공됩니다.
- 모바일 실서버는 HTTPS 사용이 기본입니다. 로컬 HTTP 서버를 쓰려면 팀의 개발 호스트에 한정된 Android network security / iOS ATS 설정이 필요합니다. 전체 cleartext 허용은 켜지 않았습니다.
- 웹 API 연결 시 백엔드 CORS 허용이 필요합니다. 브라우저 카메라는 HTTPS 또는 localhost에서 동작합니다.

## v0 범위

컬렉션은 Figma에 나온 네 가지 포즈의 **미획득 미리보기**입니다. `card_ids=[]`이고 카드 상세 데이터/수정 API가 없으므로 카드 지급, 메모 편집, 스토리 공유를 만들어내지 않습니다. 실제 카드 데이터가 확정되면 연결해야 합니다. Figma는 와이어프레임이며 최종 포즈 이미지/브랜드 자산은 포함되어 있지 않았습니다.

## 검증

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --no-wasm-dry-run
```

Android 카메라/권한/사진첩/공유는 실제 폰에서, iOS 빌드와 권한은 macOS/Xcode 및 실제 기기에서 별도로 검증해야 합니다. 앱 ID와 배포 서명은 개발용 기본값입니다.

Windows Flutter를 WSL UNC 경로에서 실행하면 native hook 파일 잠금이 실패할 수 있습니다. WSL에서는 Linux Flutter SDK를, Windows에서는 로컬 체크아웃을 사용해 주세요. 검증 결과와 남은 기기 확인 사항은 [docs/verification.md](docs/verification.md)에 기록했습니다.


카메라 촬영은 미리보기와 동일한 중앙 3:4 영역으로 JPEG를 크롭하며, 확인 화면과 업로드에도 같은 파일을 사용합니다. 앨범에서 가져온 사진은 원래 비율을 유지합니다. 촬영 확인 화면의 시스템 뒤로가기/닫기는 홈으로 돌아가며, 다시 찍기는 카메라를 엽니다.
