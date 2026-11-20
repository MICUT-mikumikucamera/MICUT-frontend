import '../features/capture/capture_crop.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/micut_tab_bar.dart';
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
import '../features/auth/auth_providers.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/onboarding_screens.dart';

/// 경로 이름. 화면에서 문자열을 직접 쓰지 말고 이 상수를 쓴다.
abstract final class Routes {
  static const home = '/';
  static const login = '/login';
  static const onboardingNickname = '/onboarding/nickname';
  static const onboardingTerms = '/onboarding/terms';
  static const sessionExpired = '/session-expired';
  static const gallery = '/gallery';
  static const photoDetail = '/gallery/:id';

  static const collection = '/collection';
  static const cardDetail = '/collection/:id';
  static const cardStory = '/collection/:id/story';

  static const settings = '/settings';

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

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: ref.read(authPreviewProvider) ? Routes.login : Routes.home,
    routes: [
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: Routes.onboardingNickname,
          builder: (_, __) => const NicknameScreen()),
      GoRoute(
          path: Routes.onboardingTerms,
          redirect: (_, __) => ref.read(onboardingNicknameProvider).isEmpty
              ? Routes.onboardingNickname
              : null,
          builder: (_, __) => const TermsScreen()),
      GoRoute(
          path: Routes.sessionExpired,
          builder: (_, __) => const SessionExpiredScreen()),
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
