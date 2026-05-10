import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subscription_saver_copilot/main.dart';

void main() {
  testWidgets('renders dashboard headline', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const SaverApp());
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Subscription Saver Copilot'), findsOneWidget);
    expect(find.text('Track subscriptions and get reminded before they renew.'), findsOneWidget);
  });
}
