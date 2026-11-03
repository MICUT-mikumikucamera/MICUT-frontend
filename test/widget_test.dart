import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micut/core/widgets/micut_button.dart';
import 'package:micut/core/widgets/pose_card.dart';

void main() {
  testWidgets('MiCutButton shows label and handles tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MiCutButton(label: '만들기', onPressed: () => tapped = true),
        ),
      ),
    );
    expect(find.text('만들기'), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    expect(tapped, isTrue);
  });

  testWidgets('PoseCard renders uncollected state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 157,
            height: 215,
            child: PoseCard(number: 4, name: '응원 자세', collected: false),
          ),
        ),
      ),
    );
    expect(find.text('미수집'), findsOneWidget);
    expect(find.text('#004'), findsOneWidget);
  });
}
