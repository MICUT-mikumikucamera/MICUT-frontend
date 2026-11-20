# Figma 화면 적용 검증 — 2026-11-06

## 구현 범위

`feat/scaffold-brand` 위에서 사용자 디자인 시스템과 브라우저로 확인한 Figma 176:4374의 촬영 흐름·앱 구조를 적용했다. 공통 테마/CTA/탭바/사진/폴라로이드 카드, 홈·갤러리·상세·컬렉션, 촬영 가이드·카메라·확인·처리·실패·결과를 변경했다. 설정은 공통 테마를 따른다. 수정은 커밋/푸시하지 않았다.

이전 `docs/implementation-plan.md` 1단계 토큰과 2단계 화면 구조 작업은 진행됐다. 3단계 기존 브랜치의 서버·복구·플랫폼 통합은 완료하지 않았다.

## 검증 결과

- Windows Flutter 3.44.4 / Dart 3.12.2. WSL UNC의 테스트 실행 지연을 피하기 위해 Windows 임시 사본에 동일 소스를 동기화해 검증.
- flutter analyze: No issues found.
- flutter test --dart-define=WRITE_PREVIEWS=true: 7 tests passed.
- test/design_layout_test.dart: 홈·빈 갤러리·빈 컬렉션·확인 화면, 320/390px × 텍스트 배율1/1.5, overflow/위젯 예외 없음. 실제 Pretendard 및 MaterialIcons 로드 후 PNG 캡처.
- test/design_tokens_test.dart: 문서의 Semantic/간격/타이포그래피 검증.
- 기존 버튼 탭·미수집 카드 위젯 테스트 유지.
- premium audit strict --no-write: findings 0. 정적 점검이며 실행 시나리오의 대체 근거가 아니다.
- 변경 파일 포맷 및 git diff --check 확인.

## 확인된 제약

- Figma 브라우저 시안은 읽었지만 변수·컴포넌트 원본 export는 확보하지 못했다. Gray/spacing/type은 사용자 수치 그대로, 브랜드색/그라데이션/일부 크기는 명시된 임시값이다.
- 홈 타일 equalizer 이미지와 미획득 포즈 그림을 가져오지 못했다. 임의 그림/사진으로 대체하지 않았다. 임시 타일 배경에서는 대비를 위해 어두운 전경을 사용하며 원본은 밝은 전경이다.
- DungGeunMo 및 신규 컬렉션 획득 연출 미구현. 가짜 획득을 추가하지 않는다.
- 공유는 기존 구현에 실제 기능이 없어 비활성/미노출 상태다. 카드 메모 편집·스토리 화면 역시 신규 구현하지 않았다.
- 실제 카메라/권한/사진첩/서버 통신 및 Android/iOS 빌드는 이번 검증에 포함하지 않았다. 기존 브랜치와의 업로드 계약/EXIF/3:4/작업 복구 차이는 implementation-plan에 기록되어 있다.
- 처리 화면 닫기는 서버 작업을 폐기하지 않는다. 사진은 현재 앱 세션의 로컬 선택 경로로 유지한다. 앱 재시작 복구는 후속 작업이다.
- 결과 저장 재시도는 같은 로컬 GalleryItem을 재사용한다. 사진첩 쓰기 성공 이후 메타데이터 저장 실패 시 사진첩에 중복 쓰지 않도록 화면 상태를 유지한다.

## 2026-11-06 누락 UI 복구 재검증

- 카메라: Figma에서 비율 4:3/1:1/16:9, 타이머 OFF/3/5/7, 플래시 OFF/ON/AUTO 확인. 전후면 전환과 앨범 진입 복구. 실제 API 연결 및 EXIF 보정 후 중앙 크롭 구현.
- 사진 상세/결과: 공유 연결. 웹 다운로드, 네이티브 사진첩 저장 분리.
- 컬렉션/카드: 스토리 보기, 메모 편집과 카드별 저장, 공유 복구. 실제 새로 획득한 알려진 카드에만 획득 오버레이 표시.
- 홈: 빈 최근 사진 영역의 회색 배경 복구. 갤러리 편집 시 탭바 숨김/삭제 영역, 촬영 확인·처리·실패·결과의 흰색 안내 구조 재확인.
- 최종 flutter analyze: No issues found. flutter test: 13 passed (카메라 컨트롤/크롭, 메모 저장, 사진 바이트 전달, 기존 레이아웃/토큰).
- 위의 이전 '공유/메모/스토리/획득 연출 미구현' 기록은 이 변경으로 대체한다. DungGeunMo 원본 폰트, 홈 equalizer/포즈 그림, 원본 브랜드 변수·아이콘 확보는 여전히 미완료다. 완전한 픽셀 일치는 보증하지 않는다.
- lib/browser_preview.dart는 390px 비교용 진입점. 세션 메모리 저장과 성공 FakeJobRepository를 사용한다. 실제 AI 합성/새 카드 지급은 하지 않으며 새로고침하면 임시 사진이 초기화된다.
- 실기기 플래시/전후면 동작과 서버 연동은 별도 검증 필요. 자동 테스트는 카메라 컨트롤러 대역으로 상태 전환을 검증했다.

## 2026-11-06 사용자 요청: 임의 UI 철회
- 웹 다운로드 안내 토스트와 다운로드 전용 레이블 제거. 저장 버튼은 기존 디자인 명칭 유지.
- 임의 공유/저장/삭제/메모/카메라 오류 문구와 카메라 재시도 패널 제거. 실패 시 성공 상태를 만들지 않으며 개발 로그만 기록.
- 미확인 획득 안내 보조 문구, 메모 글자 수 제한/카운터, 고정 390px/회색 배경 장식 제거.
- 하드웨어 미지원 시 비활성 상태와 요청된 촬영 컨트롤 유지. 지원 안 함 툴팁 문구는 제거.
- 기능용 세션 저장 및 웹 파일 저장 처리는 유지. 임의 시각 요소를 추가하는 근거로 삼지 않음.
- flutter analyze: No issues found; flutter test: 13 passed.

## 2026-11-06 원본 차이 후속 수정
- 촬영 가이드 닫기 제거, 권한거부 전용 원본 모달 복구(native 실제 앱 설정, web 확인 비활성).
- 미저장 결과 종료 모달 복구. 사진첩 쓰기 성공 후 갤러리 등록. 저장 완료 안내는 버튼 위 검정 말풍선(native만).
- 설정 원본 3개 행만 유지. 가짜 링크/버전/데이터 삭제 제거. 목적지 미확인이라 새 화면/동작 없음.
- 카드 상세 추가 fullscreen/미확인 메모 편집창 제거. 메모 편집 비활성. 스토리 cover, 진행선, 오른쪽 하단 액션.
- 홈 흰색 전경 복구. 미확인 로딩실패 안내·placeholder 글자/아이콘 제거. 컬렉션 진행도 명칭 수정. 미확인 포즈명은 ???로 유지.
- DungGeunMo 제작자 공식 TTF 확보 및 등록: https://cactus.tistory.com/193 (public domain).
- flutter analyze: No issues found; flutter test: 15 passed.
- 미완료: Figma 원본 로고/이퀄라이저/미수집 실루엣/아이콘 export 접근 거부. 대체 그림 제작하지 않음. 정확한 브랜드 변수·치수·카드 회전값도 확인 전 변경하지 않음. 카드 목록 전체 및 ID 매핑은 기획 자료 확인 필요.
- 실제 AI 처리 없는 브라우저 미리보기 환경은 유지. 원본 데이터/설정 목적지/메모 편집 상세 미확인 상태를 구현 완료로 취급하지 않음.

## 2026-11-06 브라우저 원본 다운로드와 적용
- Figma 정식 브라우저 메뉴에서 원본 .fig(36,905,536bytes), 60쪽 PDF, node206:7934 로고4x PNG 다운로드 성공. 원본은 상위 figma-source에 보관. .fig의 3,615노드와 원본 이미지 압축을 해제해 비교.
- 홈 배경2종과 미수집 포즈 그림은 PDF의 독립 그래픽 페이지에서 렌더링. 화면 캡처를 UI 전체 배경으로 사용하는 방식은 적용하지 않음.
- 홈 문구/180·160px 타일/최근 사진 간격, 50px 원형 촬영 탭, CTA1·CTA2 크기·반경·글자·단색/그라데이션, danger색, 촬영 안내 간격, 사진 fill, 컬렉션 카드 비율과±2도 회전, 상세 사진 크기 조정.
- Windows 임시 검증 사본: flutter analyze --no-pub 문제0개; flutter test --no-pub --dart-define=WRITE_PREVIEWS=true 15개 통과. 320/390px, 글자1/1.5배, 가이드·홈·갤러리·컬렉션·촬영확인·사진상세·카드상세 검사.
- flutter build web -t lib/browser_preview.dart --no-pub 성공. 기존 CupertinoIcons 폰트 참조 경고는 남지만 빌드 실패는 없음.
- 실제 브라우저375×812에서 홈→컬렉션→홈→갤러리→촬영안내 전환과 에셋 로딩 확인, 오류 로그 없음. 임시 브라우저 닫고 viewport 복원.
- premium strict 정적 검사0건, Impeccable detector0건. Flutter에는 정적 웹 검사 결과만으로 시각 일치를 보증하지 않음.
- 전체 픽셀 일치 완료는 아님: 촬영 플래시·타이머·비율 및 일부 보조 Material 아이콘, 세부 화면별 여백은 후속 원본 대조가 필요. 실제 카메라·사진첩 권한·백엔드 실기기 검증은 수행하지 않음. 기존 사용자 변경은 유지하며 커밋/푸시하지 않음.

- 추가 적용: 정식 브라우저 PNG export로 공통 아이콘 11종을 확보해 홈·탭·갤러리·컬렉션·상세·설정에 연결. 컬렉션 하단 그라데이션과 촬영 안내 배경도 원본에 맞춤. 아이콘 교체 후 analyze 0건 및 테스트 15개 재통과.
- 플래시 개별/묶음 export는 다운로드 이벤트 없이 반복 타임아웃. 해당 촬영 상태 표시는 기존 구현 유지. 편집 권한 확대나 접근 우회는 수행하지 않음.

## 2026-11-08 user correction verification

- Changes: centered headers/icon feedback/camera actions; equal tab interaction bounds; horizontal flash/timer/ratio pickers; contain fitting for capture flow; full-field upload plus crop coordinates.
- Windows verification mirror: C:/Users/poplo/AppData/Local/Temp/micut-browser-export-verify (Flutter cannot run directly from the WSL UNC working directory).
- flutter analyze --no-pub: no issues.
- flutter test --no-pub: 30 passed, including original image field preservation, EXIF orientation, multipart crop transport, portrait/landscape/square fitting, equal tab bounds, camera menu selection and Escape.
- Premium strict static audit: 0 findings. Scoped git diff --check (lib/test/docs/DESIGN.md, CRLF accepted): clean. Existing Android CRLF findings are outside this change.
- Browser and real camera verification intentionally left to the user. Backend implementation is not part of this change; see capture-original-contract.md.
- Home background generator: successfully regenerated both original-art LINEAR_DODGE backgrounds twice; SHA-256 hashes unchanged across runs. Browser visual comparison remains user-owned.
- Final flutter build web -t lib/browser_preview.dart --no-pub: succeeded (137.8s). Existing local server http://127.0.0.1:8876/ returns HTTP 200 and serves this build. Existing optional CupertinoIcons font warning remains; application uses original exported icons and MaterialIcons fallback.

## 2026-11-08 vertical camera options

- CaptureOptionsRail replaces the horizontal text popup with a centered vertical icon list. Visual background width24px / black60%; hit areas48px; selected cyan200.
- Opening: sibling fade-out → trigger travel → menu reveal. Closing reverses those stages. Reduced-motion setting skips animation.
- flutter analyze --no-pub: no issues. Focused animation/camera/layout suite: 11 tests passed, including geometry/color, selection callback timing, outside/Escape/system-back dismissal and reduced motion.
- Browser inspection remains intentionally omitted at the user's request.
- Final web preview build succeeded (44.0s, --no-wasm-dry-run); static premium audit 0 findings; scoped diff whitespace check passed.

## 2026-11-18 Figma refresh

- Browser-exported latest Figma was compared with the saved 2026-11-06 document using normalized image hashes. Runtime assets are original standalone Figma exports.
- flutter test --no-pub --dart-define=WRITE_PREVIEWS=true: 45 passed. Includes 2/20 grapheme boundaries, rejected whitespace/emoji, IME composition, consent gating, nickname retention on back, auth failure recovery, no fake production login, 320/390px layouts at 2x text with keyboard, reduced motion, collection auto-close/manual-close/disposal.
- Final flutter analyze --no-pub: no issues. Final changes after the full suite only added const annotations and equivalent braces.
- flutter build web -t lib/browser_preview.dart --no-pub --no-wasm-dry-run: succeeded (30.7s). Temporary verification mirror needed flutter create . --platforms web --no-pub because the repository has no web host scaffolding. Generated host files were confined to the mirror. Existing optional CupertinoIcons font warning remains.
- Strict premium audit: 0 findings. DESIGN.md lint: 0 errors, 1 warning because the existing prose document has no YAML frontmatter.
- Widget-rendered home/login/terms screenshots were inspected; no app browser verification was performed, honoring the user's existing preference.
- Verification mirror: C:/Users/poplo/AppData/Local/Temp/micut-20261118-verify. Screenshots: build/design-previews. Real Google authentication, session expiry integration and legal content are pending OAuth settings, an agreed authentication/signup/profile/session API contract, and actual terms/privacy URLs. Preview never persists authentication or consent.

## 2026-11-19 authentication design preview

- Browser preview defaults to the UI-only login flow unless real API mode is selected; explicit MICUT_AUTH_PREVIEW overrides this default. Legal full-view actions show an in-app placeholder document screen in preview and preserve consent state on return.
- Focused figma_refresh_test.dart: 11 passed, including both legal preview pages and consent preservation. Changed-file dart analyze: no issues. Full flutter analyze stalled and was stopped; no full-analysis success is claimed.
- Web build succeeded (35.2s). Existing optional CupertinoIcons font warning remains. Strict static audit: 0 findings. DESIGN.md lint: 0 errors, existing missing-YAML warning.
- No Google authentication, published legal content, or stored consent added. Browser visual review remains user-owned.

## 2026-11-19 device appearance correction

- Login uses platform brightness from first render and responds to system changes. Removed timed dark-to-light transition.
- Changed-file static analysis: no issues. Focused authentication suite: 12 passed, including light/dark initial appearance, persistence after two seconds and live preference change.
- Web preview rebuilt successfully (27.5s) in the directory served on port 8877. Existing optional CupertinoIcons warning remains. Browser visual inspection is left to the user.

## 2026-11-19 responsive copy, all-consent and card artwork

- Changed-file static analysis: no issues. Combined auth/layout suite: 15 passed. Checks Korean word line boxes at multiple widths/text scales, all-consent toggle and individual synchronization, and home artwork containment/text separation at 320/390px and enlarged text.
- Widget-rendered home/nickname images inspected. Original miku-capture asset contains full artwork; negative layout offsets caused clipping. No browser visual review performed.

## 2026-11-19 source alignment restoration

- Compared decoded Figma nodes 402:2542, 402:1274, 402:2500 and check component 402:3006 with runtime. Restored rounded terms rows, right-side check, inline full-view link, title breaks and source spacing; all-consent stays as an explicit user addition below the original rows.
- Restored login typography/spacing. Home artwork now uses the maximum size allowed by card height and measured readable text width.
- Changed-file analysis: no issues. Auth/layout suite: 15 passed across narrow widths and enlarged text. Inspected widget-rendered terms and home images. Browser visual review remains user-owned.

## 2026-11-20 alignment and login appearance verification

- Whole suite: 51 passed before final processing/popup position refinements. After those refinements, source-state/auth/capture-fit suite: 20 passed. Final nickname counter visibility adjustment: alignment/auth/layout suite 19 passed.
- Added measured checks for stable nickname input/feedback rectangles, gray validation text, gallery title/edit vertical centers, settings back/title centers, source processing y406, popup title y140 and result close/share centers.
- Appearance tests cover selection persistence writer, immediate login variant change and storage failure preserving the previous choice. Native persistence uses existing path_provider and web uses existing web package; real-device storage was not exercised.
- Changed-file Dart analysis: no issues. Full-folder analysis was stopped after stalling; no full-folder result claimed. Strict static audit and final build results recorded by tool output. Existing optional CupertinoIcons warning remains.
- Widget images inspected for settings, result, empty gallery and nickname. Browser visual verification remains user-owned. Review used the saved 2026-11-18 Figma source, not a newly downloaded revision.

- Follow-up nickname correction: 17 focused tests passed, including exact helper/counter top alignment at input bottom + 8px for valid and invalid values. Kept label and below-line counter as requested; no unrelated layout changes.
