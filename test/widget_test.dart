import 'package:flutter_test/flutter_test.dart';
import 'package:ai_chat_app/main.dart';

void main() {
  testWidgets('App builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const NexusApp());
    expect(find.byType(NexusApp), findsOneWidget);
  });
}
