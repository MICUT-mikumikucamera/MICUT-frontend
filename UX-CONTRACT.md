# MiCut UX contract
Business source: [API v0](docs/api-v0.md). Visual source: [DESIGN.md](DESIGN.md).

| Capability | Canonical owner | Source of truth | Allowed variants | Verification |
|---|---|---|---|---|
| Navigation | HomeScreen + Material Navigator | Figma | home / capture / collection | app_test.dart |
| Async job | AppModel | API v0 | pending / processing / done / failed | api_test.dart |
| Toast | ScaffoldMessenger / appTheme | DESIGN.md | save / share failure | manual runtime |
| Dialog | confirmDelete / AlertDialog | local gallery policy | single / selection | widget tests |
| Images | ResultImage | API image_url | thumbnail / detail | manual runtime |
| Storage | AppModel + SharedPreferences | local records only | demo / per-server | api_test.dart |

Upload is explicit. Polling is serial, 1.5s after previous completion, suspended in background and stopped on terminal status or network failure. Recovery checks the same job, never resubmits a photo automatically. Result addresses stay within the configured origin. On failure, retry requires retryable=true; closing/discard must succeed before abandoning the failed job. Active jobs can be left and resumed; no unsupported cancellation claim.

Gallery deletion confirms count and scope: local records, not server or OS photo library. Empty gallery has a capture action. Selection is retained on deletion errors. Save errors remain visible and successful gallery persistence is pessimistic. Mock responses are development-only configuration, documented outside the product UI. Gray placeholders match Figma; sample save/share are disabled.

Korean locale and native Material semantics. Icons have labels, dialog focus begins on cancel, safe-area actions stay reachable, long feedback can scroll. No custom date/select/search/table capability is needed for this v0.



Camera framing: centered 3:4 preview and encoded capture share Capture.cameraAspectRatio. Apply EXIF orientation before cropping. Album images retain their aspect ratio. Confirmation uses an AspectRatio frame without stretching. System Back in pre-upload confirmation clears the capture and returns home; Retake opens the camera.
