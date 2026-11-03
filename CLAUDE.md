# MiCut Frontend — AI 작업 지침

이 파일은 AI(Claude, Cursor 등)가 이 레포를 수정할 때 따라야 하는 규칙이다. 사람도 같은 규칙을 따른다.

## 프로젝트 한 줄 요약
사용자가 사진을 찍으면 서버가 장면을 분석해 미쿠를 합성한 결과를 돌려주는 Flutter 앱. 로그인 없음. 갤러리/컬렉션은 기기 로컬 저장.

## 기술 스택 (바꾸지 말 것)
- Flutter (stable), Dart 3.4+
- 상태 관리: `flutter_riverpod` 하나만 쓴다. Provider/Bloc/GetX 추가 금지.
- 라우팅: `go_router`. 경로 정의는 `lib/app/router.dart` 한 곳에만.
- HTTP: `http` 패키지. dio 추가 금지.
- 디자인 토큰: `lib/core/theme/` 의 상수만 사용. 색상/간격/글꼴 크기를 코드에 직접 쓰지 않는다 (`Color(0xFF...)`, `SizedBox(height: 13)` 금지).

## 디자인 시스템 (Figma 로고 페이지 + 무드보드 기준, docs/design-notes.md 에 근거)
앱은 **두 개의 세계**로 나뉜다. 화면을 만들 때 어느 세계인지부터 정한다.

| | 라이트 월드 | 다크 월드 |
|---|---|---|
| 화면 | 홈, 갤러리, 컬렉션, 결과, 실패, 설정 | 촬영 가이드, 카메라, 촬영 확인, 처리 중, 스플래시 |
| 배경 | `MiCutColors.background` (흰색) | `MiCutColors.darkBg` (로고의 순흑) |
| 주색 | `primary` = cyan400 `#06B6D4` | `hud` = 일렉트릭 시안 `#00FAFC` (로고 원색) |
| 포인트 | `secondary` = pink300 (컬렉션·배지·삭제) | 사용 안 함 |
| 로고 | `BrandLogo(variant: black)` | `BrandLogo(variant: cyan)` |
| 감싸기 | 없음 | `DarkWorld(child: Scaffold(...))` |
| 모티프 | 민트 그라데이션, 뷰파인더 코너 | HUD 코너·AF 박스·REC 점·마이크로 텍스트 (`hud_frame.dart`) |

규칙:
- **시안 위에 흰 글자 금지** (대비 2.4). Primary 버튼은 시안 배경 + `ink` 글자. 근거 수치는 `colors.dart` 주석.
- 일렉트릭 시안(`brandCyan`/`hud`)은 다크 월드·아이콘·스플래시에만. 라이트 UI에서는 Tailwind cyan 스케일.
- 핑크는 "변화를 주는" 포인트: 컬렉션, NEW 배지, 카드 번호, 삭제(danger). 주 행동 버튼에 쓰지 않는다.
- 다크 월드 버튼은 `MiCutButton(onDark: true)`.
- 글꼴은 Pretendard(assets/fonts). 로고 워드마크는 글꼴이 아니라 이미지.
- 미쿠 실루엣·캐릭터 그림은 코드로 그리지 않는다. 필요하면 디자인팀이 준 에셋만 쓴다.

## 폴더 구조
```
lib/
  main.dart                 진입점. ProviderScope + MiCutApp만.
  app/
    app.dart                MaterialApp.router + 테마
    router.dart             모든 경로. 탭 3개(home/gallery/capture) + capture 스택 + 상세 화면
  core/
    theme/                  colors(토큰·그라데이션·그림자), spacing, typography, theme(라이트/다크)
    widgets/                MiCutButton, MiCutTabBar, PhotoPlaceholder, PoseCard, BrandLogo, HudCorners/HudFocusBox/HudStatus, DarkWorld
  data/
    jobs/                   서버 job 계약. Job 모델, JobRepository 인터페이스, Fake/Api 구현
    local/                  로컬 갤러리/컬렉션 저장소
  features/
    home/  capture/  gallery/  collection/  settings/
      각 화면은 `*_screen.dart` 파일 하나. 로직은 화면 밖(provider/repository)에 둔다.
```

## 화면 ↔ Figma 매핑
Figma 와이어프레임: https://www.figma.com/design/gaEquzyI3Y2S9lGKfjgaRR/%EB%AF%B8%EC%BB%B7?node-id=33-2

| 번호 | 화면 | 파일 |
|---|---|---|
| 01 | 촬영 가이드 | features/capture/capture_guide_screen.dart |
| 02 | 촬영 | features/capture/camera_screen.dart |
| 03 | 사진 선택 | features/capture/pick_photo_screen.dart (image_picker 호출, 별도 화면 없음) |
| 04 | 촬영 확인 | features/capture/confirm_screen.dart |
| 05 | 처리 중 | features/capture/processing_screen.dart |
| 05-F | 처리 실패 (와이어프레임 없음) | features/capture/failed_screen.dart |
| 06 | 결과 | features/capture/result_screen.dart |
| 07 | 저장 완료 | result_screen 내 토스트 + 버튼 상태 변경 |
| 08 | 홈 | features/home/home_screen.dart |
| 09 | 갤러리 (탭) | features/gallery/gallery_screen.dart |
| 09-2/3 | 갤러리 편집/삭제 | gallery_screen 내 편집 모드 |
| 10 | 사진 상세 | features/gallery/photo_detail_screen.dart |
| 11 | 컬렉션 (홈 타일에서 진입) | features/collection/collection_screen.dart |
| 12 | 카드 상세 | features/collection/card_detail_screen.dart |
| — | 설정 (와이어프레임 없음) | features/settings/settings_screen.dart |
| 12-1 | 스토리형 보기 | **1차 범위 제외** |

## 탭 구조 (확정)
하단 탭 3개: 홈 · 촬영(가운데 큰 버튼, 탭이 아니라 capture 스택 push) · 갤러리.
컬렉션은 홈의 전체 너비 타일에서 진입하는 하위 화면.

## 서버 계약 (백엔드 레포 contracts/ 기준)
- 상태: `pending → processing → done | failed`, `failed → pending` (재시도)
- `Job` 모델 필드는 `lib/data/jobs/job.dart` 와 백엔드 `contracts/examples/*.json` 을 항상 일치시킨다.
- 에러 처리: `error.retryable` 과 `fe_action` (`retake` | `retry`) 으로 실패 화면 버튼을 결정한다.
- 실패 화면에서 재시도 대신 닫기/다시 찍기를 누르면 `discard` 를 호출한다.
- 서버가 없을 때는 `FakeJobRepository` 를 쓴다. 실제 연결은 `ApiJobRepository` 로 교체. 전환은 `lib/data/jobs/providers.dart` 의 한 줄.

## 작업 규칙
1. 한 번에 화면 하나만 만든다. 만든 뒤 `flutter analyze` 가 0 issue여야 한다.
2. 새 패키지 추가 전에 이 파일에 이유를 적고 추가한다.
3. 위젯 중첩이 4단 이상 깊어지면 private 위젯 클래스로 뽑는다.
4. 문구는 Figma 와이어프레임의 문구를 그대로 쓴다. 바꿔야 하면 디자인팀 확인.
5. 카메라/갤러리 권한 거부, 네트워크 오류는 반드시 처리한다 (토스트나 다이얼로그).
6. 커밋 메시지: `feat:`, `fix:`, `chore:`, `docs:` 접두사. 한국어 OK.

## 1차(11/5) 범위
와이어프레임 수준으로 끝까지 동작하는 흐름. Fake 서버로 촬영→처리→결과→저장→갤러리까지. 디자인 적용, 12-1 스토리, 실제 서버 연결은 그 다음.
