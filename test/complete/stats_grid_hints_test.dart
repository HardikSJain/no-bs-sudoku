import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/theme/app_theme.dart';
import 'package:no_bs_sudoku/features/complete/widgets/stats_grid.dart';

/// The solved screen does not measure you against a limit you do not have.
///
/// It read "HINTS 0/3" on every puzzle. There were three hints once; there
/// have been unlimited ones for several releases, priced by how far each is
/// pushed rather than counted. A denominator that no longer exists reads as a
/// budget you overspent.
void main() {
  Future<void> pump(WidgetTester tester, int hints) => tester.pumpWidget(
        MaterialApp(
          theme: appTheme(),
          home: Scaffold(
            body: StatsGrid(time: '04:33', hints: hints, mistakes: 0),
          ),
        ),
      );

  testWidgets('no denominator, whatever the count', (tester) async {
    for (final hints in [0, 1, 4, 12]) {
      await pump(tester, hints);
      await tester.pumpAndSettle();
      expect(find.textContaining('/3'), findsNothing,
          reason: 'at $hints hints there is still no limit of three');
      expect(find.text('$hints'), findsWidgets);
    }
  });

  testWidgets('and it says what happened in words', (tester) async {
    await pump(tester, 0);
    await tester.pumpAndSettle();
    expect(find.text('none used'), findsOneWidget);

    await pump(tester, 1);
    await tester.pumpAndSettle();
    expect(find.text('one taken'), findsOneWidget);

    await pump(tester, 3);
    await tester.pumpAndSettle();
    expect(find.text('3 taken'), findsOneWidget);
  });
}
