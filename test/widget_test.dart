import 'package:flutter_test/flutter_test.dart';
import 'package:chmsu_library_app/main.dart';

void main() {
  testWidgets('CHMSU Library login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ChmsuLibraryApp());

    expect(find.text('CHMSU Library'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
