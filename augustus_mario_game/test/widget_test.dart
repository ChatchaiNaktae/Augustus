import 'package:flutter_test/flutter_test.dart';
import 'package:augustus_mario_game/main.dart';

void main() {
  testWidgets('App smoke test loads MainMenuScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const IWBTGApp());
    expect(find.text('START GAME'), findsOneWidget);
    expect(find.text('SELECT STAGE'), findsOneWidget);
  });
}
