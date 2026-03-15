import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/app.dart';

void main() {
  testWidgets('app boots to splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('no bs sudoku'), findsOneWidget);
    // Let the splash timer complete to avoid pending timer assertion
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}
