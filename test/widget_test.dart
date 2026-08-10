import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bajatzu/app.dart';
import 'package:bajatzu/shared/widgets/logo.dart';

void main() {
  testWidgets('App boots to splash', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BajatzuApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(BrandLogo), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();
  });
}
