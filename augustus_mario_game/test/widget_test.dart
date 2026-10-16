import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:augustus_mario_game/main.dart';
import 'package:augustus_mario_game/game/iwbtg_game.dart';
import 'package:augustus_mario_game/game/ui/virtual_controls.dart';

void main() {
  testWidgets('App smoke test loads MainMenuScreen without overflow', (WidgetTester tester) async {
    await tester.pumpWidget(const IWBTGApp());
    expect(find.text('START GAME'), findsOneWidget);
    expect(find.text('SELECT STAGE'), findsOneWidget);
    expect(find.text('HOW TO PLAY'), findsOneWidget);
    expect(find.text('ABOUT / ผู้จัดทำ'), findsOneWidget);
  });

  testWidgets('VirtualControlsOverlay resets input state on player respawn', (WidgetTester tester) async {
    final game = IWBTGGame(initialStage: 1);
    await game.onLoad();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              VirtualControlsOverlay(game: game),
            ],
          ),
        ),
      ),
    );

    // Simulate pressing right arrow
    final rightButtonFinder = find.byIcon(Icons.arrow_forward_ios_rounded);
    expect(rightButtonFinder, findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(rightButtonFinder));
    await tester.pump();

    // Movement input should be 1.0
    expect(game.player?.moveInput, equals(1.0));

    // Player respawns while touch is held or after death
    game.respawnPlayer();
    await tester.pump();

    // Input should be reset to 0.0 to prevent stuck running
    expect(game.player?.moveInput, equals(0.0));

    await gesture.up();
  });
}
