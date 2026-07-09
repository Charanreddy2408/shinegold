import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shine_gold/app.dart';

void main() {
  testWidgets('App loads welcome screen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ShineGoldApp()),
    );
    await tester.pump();
    expect(find.text('ORGANIC AGRO INVENTION'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
