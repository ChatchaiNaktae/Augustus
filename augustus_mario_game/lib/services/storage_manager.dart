import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_customization.dart';
import '../models/custom_stage_data.dart';
import '../models/player_career_stats.dart';

class StorageManager {
  static final StorageManager instance = StorageManager._internal();
  StorageManager._internal();

  static const String _keyCustomization = 'augustus_player_customization';
  static const String _keyCareerStats = 'augustus_career_stats';
  static const String _keyCustomStages = 'augustus_custom_stages';

  SharedPreferences? _prefs;

  PlayerCustomization? _cachedCustomization;
  PlayerCareerStats? _cachedStats;
  List<CustomStageData>? _cachedStages;

  Future<void> init() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (_) {}
    await loadAll();
  }

  Future<void> loadAll() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (_) {}

    // 1. Customization
    final customJson = _prefs?.getString(_keyCustomization);
    if (customJson != null) {
      try {
        _cachedCustomization = PlayerCustomization.fromJson(jsonDecode(customJson));
      } catch (_) {
        _cachedCustomization = PlayerCustomization.defaultTheKid();
      }
    } else {
      _cachedCustomization = PlayerCustomization.defaultTheKid();
    }

    // 2. Career Stats
    final statsJson = _prefs?.getString(_keyCareerStats);
    if (statsJson != null) {
      try {
        _cachedStats = PlayerCareerStats.fromJson(jsonDecode(statsJson));
      } catch (_) {
        _cachedStats = PlayerCareerStats();
      }
    } else {
      _cachedStats = PlayerCareerStats();
    }

    // 3. Custom Stages
    final stagesList = _prefs?.getStringList(_keyCustomStages);
    if (stagesList != null) {
      _cachedStages = [];
      for (final item in stagesList) {
        try {
          final data = CustomStageData.fromJson(jsonDecode(item));
          _cachedStages!.add(data);
        } catch (_) {}
      }
    } else {
      // Seed with parkour template by default so user has an example stage ready
      _cachedStages = [CustomStageData.parkourTemplate()];
      await _persistStages();
    }
  }

  // --- Player Customization ---
  PlayerCustomization getCustomization() {
    return _cachedCustomization ?? PlayerCustomization.defaultTheKid();
  }

  Future<void> saveCustomization(PlayerCustomization customization) async {
    _cachedCustomization = customization;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setString(_keyCustomization, jsonEncode(customization.toJson()));
    } catch (_) {}
  }

  // --- Career Stats ---
  PlayerCareerStats getCareerStats() {
    return _cachedStats ?? PlayerCareerStats();
  }

  Future<void> saveCareerStats(PlayerCareerStats stats) async {
    _cachedStats = stats;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setString(_keyCareerStats, jsonEncode(stats.toJson()));
    } catch (_) {}
  }

  Future<void> recordDeath(String stageKey) async {
    final stats = getCareerStats();
    stats.recordDeath(stageKey);
    await saveCareerStats(stats);
  }

  Future<void> recordClear(String stageKey, {required int stageDeaths, double? durationSeconds}) async {
    final stats = getCareerStats();
    stats.recordClear(stageKey, stageDeaths: stageDeaths, durationSeconds: durationSeconds);
    await saveCareerStats(stats);
  }

  // --- Custom Stages ---
  List<CustomStageData> getAllStages() {
    return _cachedStages != null ? List.unmodifiable(_cachedStages!) : [];
  }

  CustomStageData? getStage(String id) {
    if (_cachedStages == null) return null;
    try {
      return _cachedStages!.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveStage(CustomStageData stage) async {
    _cachedStages ??= [];
    stage.updatedAt = DateTime.now();

    final idx = _cachedStages!.indexWhere((s) => s.id == stage.id);
    if (idx >= 0) {
      _cachedStages![idx] = stage;
    } else {
      _cachedStages!.add(stage);
      final stats = getCareerStats();
      stats.recordStageCreated();
      await saveCareerStats(stats);
    }

    await _persistStages();
  }

  Future<bool> deleteStage(String id) async {
    if (_cachedStages == null) return false;
    final initialCount = _cachedStages!.length;
    _cachedStages!.removeWhere((s) => s.id == id);
    if (_cachedStages!.length != initialCount) {
      await _persistStages();
      return true;
    }
    return false;
  }

  Future<void> _persistStages() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final list = _cachedStages?.map((s) => jsonEncode(s.toJson())).toList() ?? [];
      await _prefs?.setStringList(_keyCustomStages, list);
    } catch (_) {}
  }
}
