# MiCut Frontend

장면을 이해해 미쿠를 자동 배치하는 카메라 앱의 Flutter 클라이언트.

## 처음 받았을 때

```bash
# 1. 플랫폼 폴더 생성 (android/ 등). lib/ 는 건드리지 않음
flutter create . --platforms android --org com.micut --project-name micut

# 2. 패키지 설치
flutter pub get

# 3. 실행 (폰 연결 또는 에뮬레이터)
flutter run

# 레이아웃만 빠르게 볼 때 (카메라/저장은 동작 안 함)
flutter run -d chrome
```

버전 충돌이 나면 `flutter pub upgrade --major-versions` 한 번 돌리면 됩니다.

### Android 권한
`flutter create` 후 `android/app/src/main/AndroidManifest.xml` 의 `<manifest>` 바로 안에 추가:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />
```

`android/app/build.gradle(.kts)` 의 `minSdk` 는 24 이상.

### 앱 아이콘 · 스플래시 (한 번만)
```bash
dart run flutter_launcher_icons        # 시안 배경 + 검정 M (Figma "MiCut Icon M")
dart run flutter_native_splash:create  # 순흑 배경 + 시안 워드마크
```

## 디자인
토큰은 `lib/core/theme/`, 적용 근거와 화면별 결정은 [docs/design-notes.md](./docs/design-notes.md).
라이트 월드(흰 배경 + Cyan/Pink)와 다크 월드(순흑 + #00FAFC) 두 테마가 있고, 카메라 흐름은 `DarkWorld`로 감쌉니다.

## 구조와 규칙
[CLAUDE.md](./CLAUDE.md) 참고. AI에게 작업을 시킬 때도 이 파일이 지침입니다.

## 서버 연결
기본은 `FakeJobRepository` (서버 없이 동작). 백엔드가 올라오면
`lib/data/jobs/providers.dart` 에서 `ApiJobRepository` 로 바꾸고 `baseUrl` 을 넣으면 됩니다.

## APK
```bash
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```
