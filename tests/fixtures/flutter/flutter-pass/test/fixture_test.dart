import 'package:fixture/fixture.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('greets', (tester) async {
    await tester.pumpWidget(const Greeting(name: 'Ada'));
    expect(find.text('Hello, Ada'), findsOneWidget);
  });
}
