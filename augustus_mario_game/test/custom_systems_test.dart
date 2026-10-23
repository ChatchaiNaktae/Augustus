import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:augustus_mario_game/models/player_customization.dart';
import 'package:augustus_mario_game/models/custom_stage_data.dart';
import 'package:augustus_mario_game/models/player_career_stats.dart';
import 'package:augustus_mario_game/services/storage_manager.dart';
import 'package:augustus_mario_game/screens/character_editor_screen.dart';
import 'package:augustus_mario_game/screens/stage_editor_screen.dart';
import 'package:augustus_mario_game/screens/career_stats_screen.dart';
import 'package:augustus_mario_game/screens/select_custom_stage_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PlayerCustomization Model Tests', () {
    test('Default The Kid customization values are accurate', () {
      final defaultKid = PlayerCustomization.defaultTheKid();
      expect(defaultKid.hairStyle, equals(HairStyle.classic));
      expect(defaultKid.hatType, equals(HatType.cap));
      expect(defaultKid.capeEnabled, isTrue);
      expect(defaultKid.shirtColor, equals(0xFF81A1C1));
      expect(defaultKid.pantsColor, equals(0xFF3B4252));
    });

    test('PlayerCustomization JSON serialization and deserialization', () {
      final custom = PlayerCustomization(
        hairStyle: HairStyle.spiky,
        hairColor: 0xFFFF0000,
        skinColor: 0xFFA3BE8C,
        shirtColor: 0xFF00FF00,
        pantsColor: 0xFF0000FF,
        hatType: HatType.crown,
        hatColor: 0xFFEBCB8B,
        capeEnabled: false,
        capeColor: 0xFFFFFFFF,
        shoesColor: 0xFF000000,
      );

      final json = custom.toJson();
      final revived = PlayerCustomization.fromJson(json);

      expect(revived.hairStyle, equals(HairStyle.spiky));
      expect(revived.hatType, equals(HatType.crown));
      expect(revived.capeEnabled, isFalse);
      expect(revived.skinColor, equals(0xFFA3BE8C));
    });

    test('Randomize produces valid PlayerCustomization instance', () {
      final rand1 = PlayerCustomization.randomize();
      expect(rand1.hairStyle, isIn(HairStyle.values));
      expect(rand1.hatType, isIn(HatType.values));
    });
  });

  group('CustomStageData Model & Export/Import Tests', () {
    test('Blank template initializes with ground and goal portal', () {
      final blank = CustomStageData.blankTemplate(title: 'Test Stage');
      expect(blank.title, equals('Test Stage'));
      expect(blank.elements.any((e) => e.type == StageElementType.platform), isTrue);
      expect(blank.elements.any((e) => e.type == StageElementType.goal), isTrue);
    });

    test('Export to AGY code and Import from AGY code', () {
      final stage = CustomStageData.parkourTemplate();
      final code = stage.exportCode();

      expect(code.startsWith('AGY:'), isTrue);

      final imported = CustomStageData.importCode(code);
      expect(imported, isNotNull);
      expect(imported!.title, equals(stage.title));
      expect(imported.elements.length, equals(stage.elements.length));
    });
  });

  group('PlayerCareerStats Model & Achievements Tests', () {
    test('Career stats correctly records deaths and unlocks First Splat', () {
      final stats = PlayerCareerStats();
      expect(stats.totalDeaths, equals(0));
      expect(stats.unlockedAchievements.contains('first_splat'), isFalse);

      stats.recordDeath('stage_1');
      expect(stats.totalDeaths, equals(1));
      expect(stats.unlockedAchievements.contains('first_splat'), isTrue);
    });

    test('Clearing with zero deaths unlocks Untouchable', () {
      final stats = PlayerCareerStats();
      stats.recordClear('stage_1', stageDeaths: 0);

      expect(stats.totalClears, equals(1));
      expect(stats.unlockedAchievements.contains('first_clear'), isTrue);
      expect(stats.unlockedAchievements.contains('untouchable'), isTrue);
    });
  });

  group('StorageManager Integration Tests', () {
    test('StorageManager saves and loads customization', () async {
      await StorageManager.instance.init();

      final custom = PlayerCustomization.defaultTheKid().copyWith(
        hairStyle: HairStyle.ponytail,
      );
      await StorageManager.instance.saveCustomization(custom);

      final retrieved = StorageManager.instance.getCustomization();
      expect(retrieved.hairStyle, equals(HairStyle.ponytail));
    });

    test('StorageManager saves and retrieves custom stages', () async {
      await StorageManager.instance.init();

      final stage = CustomStageData.blankTemplate(title: 'Persisted Stage');
      await StorageManager.instance.saveStage(stage);

      final allStages = StorageManager.instance.getAllStages();
      expect(allStages.any((s) => s.id == stage.id), isTrue);
    });
  });

  group('UI Screens Widget Tests', () {
    testWidgets('CharacterEditorScreen renders without overflow', (tester) async {
      await StorageManager.instance.init();
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(home: CharacterEditorScreen()),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('CHARACTER CUSTOMIZER'), findsOneWidget);
      expect(find.text('SAVE & APPLY'), findsOneWidget);
      expect(find.text('RANDOM'), findsOneWidget);
    });

    testWidgets('StageEditorScreen renders toolbar, canvas and panels without overflow', (tester) async {
      await StorageManager.instance.init();
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(home: StageEditorScreen()),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('PLAYTEST'), findsOneWidget);
      expect(find.text('SAVE'), findsOneWidget);
      expect(find.text('Select'), findsOneWidget);
      expect(find.text('Move'), findsOneWidget);
      expect(find.text('Scale'), findsOneWidget);
      expect(find.text('Rotate'), findsOneWidget);
    });

    testWidgets('CareerStatsScreen renders stats and trophies without overflow', (tester) async {
      await StorageManager.instance.init();
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(home: CareerStatsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('CAREER STATS & TROPHIES'), findsOneWidget);
      expect(find.text('MASOCORE TROPHY CABINET'), findsOneWidget);
      expect(find.text('TOTAL DEATHS'), findsOneWidget);
    });

    testWidgets('SelectCustomStageScreen renders stage list and actions', (tester) async {
      await StorageManager.instance.init();
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(home: SelectCustomStageScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('CUSTOM STAGES'), findsOneWidget);
      expect(find.text('CREATE NEW'), findsOneWidget);
      expect(find.text('IMPORT'), findsOneWidget);
    });
  });
}
