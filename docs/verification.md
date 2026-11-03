# Verification — 2026-11-03

- Flutter 3.44.4 / Dart 3.12.2, Windows local validation copy of this source.
- `flutter analyze`: no issues.
- `flutter test`: all 10 tests passed.
- `flutter build web --no-wasm-dry-run`: passed.
- `dart format lib test`: passed.
- Premium static UI audit: 0 findings (`premium-audit.json`).
- DESIGN.md lint: 0 errors; 2 orphan-token warnings because documentation's muted/border colors are consumed by Dart theme rather than component YAML references.
- Impeccable mechanical detector: no findings; Dart coverage is limited, so this does not replace runtime inspection.
- Browser inspected: home, camera entry, sample photo confirmation, processing, done, gallery, collection. Layout follows the anonymously viewable Figma wireframe. Exact Figma variable/font inspection was unavailable.
- Widget flows at 390×844 and 320×640: empty states, collection, sample upload → done, failed → retry → done, gallery selection → confirmed deletion. No layout exceptions.
- API tests: all backend fixture states; multipart field/file content; EXIF normalization; HTTP 200 domain failure; empty 204 discard; structured HTTP errors; retry identity/attempt; persistence; serial polling and offline recovery.
- Reviewed and fixed: camera permission/lifecycle busy lock, ambiguous retry response recovery, blocking startup network request.

## Remaining device/server checks

No backend URL was supplied; the live server and real AI pipeline have not been exercised. No phone was connected. Camera permission/revocation, native gallery save and OS sharing need a real Android/iOS device. iOS compilation requires macOS/Xcode. Android SDK is installed but some licenses are unaccepted (`flutter doctor -v`); no license acceptance or APK build was performed.

The project lives on WSL. Windows Flutter's native hook locks time out on this UNC mount, so verification was run against an identical local Windows copy. Use a Linux Flutter SDK inside WSL, or a local Windows checkout with Windows Flutter. Do not mix a Windows Flutter SDK and WSL UNC native hook builds.

2026-11-03 correction: removed UI additions not in Figma (demo badge/action, decorative sample icons/copy, collection locks/status notices, duplicate loading copy and added result heading). Re-ran analyzer (no issues), all 10 tests and web build successfully. Test samples now enter through model fixtures, not a product demo button.

Capture ratio correction: centered camera JPEG crop follows EXIF orientation and shares 3:4 aspect with preview/confirmation; album ratio unchanged. Analyzer passed; all 13 tests passed, including landscape/portrait/square inputs, encoded upload dimensions, EXIF-before-crop, rendered confirmation dimensions and simulated Android system-back returning home.
