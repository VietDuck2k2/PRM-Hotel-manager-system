import 'package:flutter_test/flutter_test.dart';
import 'package:final_prm_project/main.dart';

void main() {
  testWidgets('HMS app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HmsApp());
    // Verify the login screen loads.
    expect(find.text('Hotel Management System'), findsOneWidget);
  });
}
