import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micut/core/theme/appearance.dart';
import 'package:micut/core/theme/theme.dart';
import 'package:micut/core/theme/colors.dart';
import 'package:micut/core/widgets/micut_icon.dart';
import 'package:micut/features/auth/login_screen.dart';
import 'package:micut/features/auth/onboarding_screens.dart';
import 'package:micut/features/gallery/gallery_screen.dart';
import 'package:micut/features/settings/settings_screen.dart';
import 'package:micut/data/local/local_store.dart';

void main() {
  testWidgets('nickname validation keeps input and feedback aligned',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
            theme: buildMiCutTheme(), home: const NicknameScreen())));
    await tester.enterText(find.byType(TextField), '미쿠');
    await tester.pumpAndSettle();
    final field = tester.getRect(find.byType(TextField));
    final helper = tester.getTopLeft(find.text('사용 가능한 닉네임이에요.'));
    expect(helper.dy, closeTo(field.bottom + 8, 1));
    expect(tester.getTopLeft(find.text('2/20')).dy, helper.dy);
    await tester.enterText(find.byType(TextField), '미');
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(TextField)), field);
    expect(tester.getTopLeft(find.text('닉네임은 최소 2자로 설정해 주세요.')), helper);
    expect(tester.getTopLeft(find.text('1/20')).dy, helper.dy);
    expect(tester.widget<Text>(find.text('닉네임은 최소 2자로 설정해 주세요.')).style!.color,
        MiCutColors.textSubtle);
    expect(find.byIcon(Icons.error), findsOneWidget);
  });
  testWidgets('gallery title and edit share the same center', (tester) async {
    await tester.pumpWidget(ProviderScope(
        overrides: [
          galleryProvider.overrideWith((ref) async => <GalleryItem>[]),
        ],
        child: MaterialApp(
            theme: buildMiCutTheme(), home: const GalleryScreen())));
    await tester.pumpAndSettle();
    expect(tester.getCenter(find.text('갤러리')).dy,
        closeTo(tester.getCenter(find.text('편집')).dy, 1));
  });
  testWidgets('settings alignment and appearance selection', (tester) async {
    String? stored;
    final container = ProviderContainer(overrides: [
      appearanceWriterProvider.overrideWithValue((value) async {
        stored = value;
      }),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            theme: buildMiCutTheme(), home: const SettingsScreen())));
    final back =
        find.byWidgetPredicate((w) => w is MiCutIcon && w.asset == 'back');
    expect(tester.getCenter(back).dy,
        closeTo(tester.getCenter(find.text('설정')).dy, 1));
    await tester.tap(find.text('화면 모드'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다크 모드'));
    await tester.pumpAndSettle();
    expect(stored, 'dark');
    expect(container.read(appearanceProvider), ThemeMode.dark);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child:
            MaterialApp(theme: buildMiCutTheme(), home: const LoginScreen())));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey(false)), findsOneWidget);
    await container.read(appearanceProvider.notifier).select(ThemeMode.light);
    await tester.pump();
    expect(find.byKey(const ValueKey(true)), findsOneWidget);
  });
  test('failed preference storage preserves current choice', () async {
    final container = ProviderContainer(overrides: [
      appearanceWriterProvider.overrideWithValue(
          (_) async => throw StateError('storage unavailable')),
    ]);
    addTearDown(container.dispose);
    await expectLater(
        container.read(appearanceProvider.notifier).select(ThemeMode.dark),
        throwsStateError);
    expect(container.read(appearanceProvider), ThemeMode.system);
  });
}
