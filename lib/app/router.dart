import '../features/capture/capture_crop.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/micut_tab_bar.dart';
import '../data/auth/auth.dart';
import '../data/auth/providers.dart';
import '../features/auth/boot_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/nickname_screen.dart';
import '../features/auth/session_expired_screen.dart';
import '../features/auth/terms_screen.dart';
import '../features/capture/camera_screen.dart';
import '../features/capture/capture_guide_screen.dart';
import '../features/capture/confirm_screen.dart';
import '../features/capture/failed_screen.dart';
import '../features/capture/processing_screen.dart';
import '../features/capture/result_screen.dart';
import '../features/collection/card_detail_screen.dart';
import '../features/collection/collection_screen.dart';
import '../features/gallery/gallery_screen.dart';
import '../features/gallery/photo_detail_screen.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';

/// 경로 이름. 화면에서 문자열을 직접 쓰지 말고 이 상수를 쓴다.
abstract final class Routes {
  static const home = '/';
  static const gallery = '/gallery';
  static const photoDetail = '/gallery/:id';

  static const collection = '/collection';
  static const cardDetail = '/collection/:id';
  static const cardStory = '/collection/:id/story';

  static const settings = '/settings';

  // 로그인 단계 (AUTH_ENABLED 일 때만 쓰인다). 어느 화면이 열릴지는 redirect 가 정한다.
  static const boot = '/boot';
  static const login = '/login';
  static const loginNickname = '/login/nickname';
  static const loginTerms = '/login/terms';
  static const loginExpired = '/login/expired';

  // 촬영 스택 (탭바 없음)
  static const captureGuide = '/capture';
  static const captureCamera = '/capture/camera';
  static const captureConfirm = '/capture/confirm';
  static const captureProcessing = '/capture/processing/:jobId';
  static const captureFailed = '/capture/failed/:jobId';
  static const captureResult = '/capture/result/:jobId';

  static String photoDetailOf(String id) => '/gallery/$id';
  static String cardDetailOf(String id) => '/collection/$id';
  static String cardStoryOf(String id) => '/collection/$id/story';
  static String processingOf(String jobId) => '/capture/processing/$jobId';
  static String failedOf(String jobId) => '/capture/failed/$jobId';
  static String resultOf(String jobId) => '/capture/result/$jobId';
}

final _rootKey = GlobalKey<NavigatorState>();

/// 로그인 단계에 맞는 화면으로 보낸다. 이미 맞는 화면이면 null.
///
/// 단계마다 열려 있는 화면:
///  - signedOut 로그인 / needsNickname 닉네임
///  - needsTerms 약관 (닉네임으로 되돌아가 고칠 수 있다)
///  - sessionExpired 세션 만료 / signedIn 로그인 화면 밖 전부
String? authRedirect(AsyncValue<AuthStatus> auth, String location) {
  if (auth.isLoading) return location == Routes.boot ? null : Routes.boot;
  final status = auth.valueOrNull ?? AuthStatus.signedOut;
  if (status == AuthStatus.signedIn) {
    final inLogin =
        location == Routes.boot || location.startsWith(Routes.login);
    return inLogin ? Routes.home : null;
  }
  final (allowed, target) = switch (status) {
    AuthStatus.needsNickname => ({Routes.loginNickname}, Routes.loginNickname),
    AuthStatus.needsTerms => (
        {Routes.loginTerms, Routes.loginNickname},
        Routes.loginTerms
      ),
    AuthStatus.sessionExpired => ({Routes.loginExpired}, Routes.loginExpired),
    _ => ({Routes.login}, Routes.login),
  };
  return allowed.contains(location) ? null : target;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authOn = ref.watch(authEnabledProvider);
  // routerProvider 를 다시 만들면 화면 스택이 날아가므로 auth 는 watch 하지 않고
  // refreshListenable 로만 알려, 같은 GoRouter 가 redirect 를 다시 돌게 한다.
  final authChanged = ValueNotifier<int>(0);
  ref.onDispose(authChanged.dispose);
  if (authOn) {
    ref.listen(authControllerProvider, (_, __) => authChanged.value++);
  }

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: authOn ? Routes.boot : Routes.home,
    refreshListenable: authChanged,
    redirect: authOn
        ? (context, state) => authRedirect(
            ref.read(authControllerProvider), state.matchedLocation)
        : null,
    routes: [
      GoRoute(
        path: Routes.boot,
        builder: (_, __) => const BootScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.loginNickname,
        builder: (_, __) => const NicknameScreen(),
      ),
      GoRoute(
        path: Routes.loginTerms,
        builder: (_, __) => const TermsScreen(),
      ),
      GoRoute(
        path: Routes.loginExpired,
        builder: (_, __) => const SessionExpiredScreen(),
      ),
      // 탭 3개: 홈 · (촬영 버튼) · 갤러리
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _TabShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.home,
              builder: (_, __) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.gallery,
              builder: (_, __) => const GalleryScreen(),
            ),
          ]),
        ],
      ),

      // 탭바 없는 전체 화면들 (root navigator)
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: Routes.photoDetail,
        builder: (_, s) => PhotoDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: Routes.collection,
        builder: (_, __) => const CollectionScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: Routes.cardDetail,
        builder: (_, s) => CardDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: Routes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),

      GoRoute(
        parentNavigatorKey: _rootKey,
        path: Routes.cardStory,
        builder: (_, s) =>
            CardDetailScreen(id: s.pathParameters['id']!, story: true),
      ),
      // 촬영 스택
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: Routes.captureGuide,
        builder: (_, __) => const CaptureGuideScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: Routes.captureCamera,
        builder: (_, __) => const CameraScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: Routes.captureConfirm,
        builder: (_, s) => ConfirmScreen(draft: s.extra! as CaptureDraft),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: Routes.captureProcessing,
        builder: (_, s) => ProcessingScreen(jobId: s.pathParameters['jobId']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: Routes.captureFailed,
        builder: (_, s) => FailedScreen(jobId: s.pathParameters['jobId']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: Routes.captureResult,
        builder: (_, s) => ResultScreen(jobId: s.pathParameters['jobId']!),
      ),
    ],
  );
});

class _TabShell extends ConsumerWidget {
  const _TabShell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: shell.currentIndex == 1 &&
              ref.watch(galleryEditingProvider)
          ? null
          : MiCutTabBar(
              currentIndex: shell.currentIndex,
              onTabSelected: (i) =>
                  shell.goBranch(i, initialLocation: i == shell.currentIndex),
              onCapture: () => context.push(Routes.captureGuide),
            ),
    );
  }
}
