import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/widgets/remote_controls/components/touchpad.dart';

void main() {
  late List<Offset> moves;
  late int clicks;

  Widget wrap({double unitsPerPixel = 4}) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(
        width: 300,
        height: 200,
        child: Touchpad(
          unitsPerPixel: unitsPerPixel,
          onMove: (dx, dy) => moves.add(Offset(dx.toDouble(), dy.toDouble())),
          onClick: () => clicks++,
        ),
      ),
    ),
  );

  double totalX() => moves.fold<double>(0, (sum, move) => sum + move.dx);
  double totalY() => moves.fold<double>(0, (sum, move) => sum + move.dy);

  setUp(() {
    moves = [];
    clicks = 0;
  });

  // The pad's own slop handling is Flutter's: the first ~18 logical pixels
  // of a pan belong to the gesture arena. Clear them, then measure only the
  // pixels the Touchpad actually sees.
  Future<void> swipe(
    WidgetTester tester, {
    required List<Offset> steps,
    double unitsPerPixel = 4,
  }) async {
    await tester.pumpWidget(wrap(unitsPerPixel: unitsPerPixel));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Touchpad)),
    );
    await gesture.moveBy(const Offset(0, 40));
    moves.clear();
    for (final step in steps) {
      await gesture.moveBy(step);
    }
    await gesture.up();
    await tester.pump();
  }

  group('Touchpad', () {
    testWidgets('a tap clicks without moving the cursor', (tester) async {
      await tester.pumpWidget(wrap());

      await tester.tap(find.byType(Touchpad));
      await tester.pump();

      expect(clicks, 1);
      expect(moves, isEmpty);
    });

    testWidgets('a swipe moves the cursor in pointer units', (tester) async {
      // Four steps of 30x10: 120x40 logical pixels, 30x10 pointer units at
      // four pixels per unit.
      await swipe(
        tester,
        steps: const [
          Offset(30, 10),
          Offset(30, 10),
          Offset(30, 10),
          Offset(30, 10),
        ],
      );

      expect(totalX(), 30);
      expect(totalY(), 10);
      // The TV takes whole units only.
      for (final move in moves) {
        expect(move.dx, move.dx.roundToDouble());
        expect(move.dy, move.dy.roundToDouble());
      }
      expect(clicks, 0);
    });

    testWidgets('one slow gesture accumulates sub-unit steps', (tester) async {
      // Three pixels per event is 0.75 of a unit: nothing on its own, six
      // units after eight events.
      await swipe(
        tester,
        steps: const [
          Offset(3, 0),
          Offset(3, 0),
          Offset(3, 0),
          Offset(3, 0),
          Offset(3, 0),
          Offset(3, 0),
          Offset(3, 0),
          Offset(3, 0),
        ],
      );

      expect(totalX(), 6);
      expect(totalY(), 0);
    });

    testWidgets('units per pixel is configurable', (tester) async {
      await swipe(
        tester,
        unitsPerPixel: 2,
        steps: const [Offset(40, 0), Offset(40, 0), Offset(40, 0)],
      );

      expect(totalX(), 60);
    });

    testWidgets('exposes a semantics label and hint', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap());

      expect(find.bySemanticsLabel(RegExp('Touchpad|Тачпад')), findsOneWidget);
      expect(find.textContaining(RegExp('Swipe|Свайп')), findsOneWidget);
      handle.dispose();
    });
  });
}
