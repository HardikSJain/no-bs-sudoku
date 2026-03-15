import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/app.dart';

void main() {
  testWidgets('app boots to splash then navigates to home', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pump();

    // Splash-only element present, home-only element absent
    expect(find.text('just sudoku.'), findsOneWidget);
    expect(find.text('new game'), findsNothing);

    // Advance past the splash delay (1.6s) and let navigation settle
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Now on home screen
    expect(find.text('new game'), findsOneWidget);
  });
}
