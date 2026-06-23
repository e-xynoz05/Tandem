import 'package:flutter_test/flutter_test.dart';
import 'package:tandem/app.dart';

void main() {
  testWidgets('TandemApp renders successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const TandemApp());
    expect(find.text('Tandem'), findsOneWidget);
  });
}
