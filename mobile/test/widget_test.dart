import 'package:flutter_test/flutter_test.dart';
import 'package:club_mobile/main.dart';

void main() {
  testWidgets('App démarre sur l\'écran de connexion', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('MAS DE FÈS'), findsOneWidget);
    expect(find.text('SE CONNECTER'), findsOneWidget);
  });
}
