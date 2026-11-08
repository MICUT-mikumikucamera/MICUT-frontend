# MiCut UX contract
Business source: [API v0](docs/api-v0.md). Visual source: [DESIGN.md](DESIGN.md).

| Capability | Canonical owner | Source of truth | Allowed variants | Verification |
|---|---|---|---|---|
| Navigation | HomeScreen + GoRouter | Figma | home / capture / collection | design_layout_test.dart |
| Async job | JobRepository / Riverpod | API v0 + capture-original-contract.md | pending / processing / done / failed | capture_original_test.dart |
| Toast | ScaffoldMessenger / buildMiCutTheme | DESIGN.md | save / share failure | manual runtime |
| Dialog | MiCutDialog / screen actions | local gallery policy | single / selection | widget tests |
| Images | PhotoPlaceholder / CaptureView | API image_url | thumbnail / detail | manual runtime |
| Storage | LocalStore / BrowserPreviewStore | local records only | demo / per-server | capture_original_test.dart |

Upload is explicit. Polling is serial, 1.5s after previous completion, suspended in background and stopped on terminal status or network failure. Recovery checks the same job, never resubmits a photo automatically. Result addresses stay within the configured origin. On failure, retry requires retryable=true; closing/discard must succeed before abandoning the failed job. Active jobs can be left and resumed; no unsupported cancellation claim.

Gallery deletion confirms count and scope: local records, not server or OS photo library. Empty gallery has a capture action. Selection is retained on deletion errors. Save errors remain visible and successful gallery persistence is pessimistic. Mock responses are development-only configuration, documented outside the product UI. Gray placeholders match Figma; sample save/share are disabled.

Korean locale and native Material semantics. Icons have labels, dialog focus begins on cancel, safe-area actions stay reachable, long feedback can scroll. Camera options use CaptureOptionsRail with keyboard/back dismissal; date/search/table capabilities are not used.



Camera framing: selected centered crop is displayed with contain fitting. Direction-normalized full-field JPEG and crop coordinates are uploaded separately; see docs/capture-original-contract.md. Album input defaults to the full frame.

## 2차 구현 검증 범위
위의 기존 서버 운영 정책은 유지합니다. 구현 구조가 Riverpod/GoRouter로 변경되었으며 활성 job의 앱 재시작 복구 등 기존 정책 전체의 동등성은 아직 검증하지 않았습니다. 이번 자동 검증은 원본·크롭 전송, 카메라 제어, 로컬 파일 보관, 화면 상태와 반응형 레이아웃을 대상으로 합니다. 브라우저 저장소는 세션 전용이며 실제 서버 연동과 기기 권한 확인은 별도입니다.
