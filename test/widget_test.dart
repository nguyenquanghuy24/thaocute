import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos/main.dart';

void main() {
  testWidgets('renders restaurant login screen', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('restaurant_pos'), findsOneWidget);
    expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
  });
}
