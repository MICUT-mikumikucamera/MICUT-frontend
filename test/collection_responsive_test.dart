import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micut/core/theme/theme.dart';
import 'package:micut/core/widgets/pose_card.dart';
import 'package:micut/data/local/local_store.dart';
import 'package:micut/features/collection/collection_screen.dart';

void main() {
  testWidgets('collection adds columns at the card width limit on resize',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    tester.view.physicalSize = const Size(375, 900);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          galleryProvider.overrideWith((ref) async => <GalleryItem>[]),
          collectedCardIdsProvider.overrideWith((ref) async => <String>{}),
        ],
        child: MaterialApp(
            theme: buildMiCutTheme(), home: const CollectionScreen())));
    for (final sample in [
      (375.0, 2),
      (455.0, 2),
      (456.0, 3),
      (768.0, 4),
      (1200.0, 6),
      (375.0, 2)
    ]) {
      tester.view.physicalSize = Size(sample.$1, 900);
      await tester.pumpAndSettle();
      final cards = find.byType(PoseCard);
      final firstY = tester.getCenter(cards.first).dy;
      var firstRowCount = 0;
      for (var i = 0; i < cards.evaluate().length; i++) {
        final card = cards.at(i);
        if ((tester.getCenter(card).dy - firstY).abs() < 1) firstRowCount++;
        final size = tester.getSize(card);
        expect(size.width, lessThanOrEqualTo(200.01));
        expect(size.width / size.height, closeTo(160 / 207, .001));
      }
      expect(firstRowCount, sample.$2, reason: 'viewport ${sample.$1}');
      expect(tester.takeException(), isNull);
    }
  });
}
