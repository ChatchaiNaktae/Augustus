class AchievementInfo {
  final String key;
  final String title;
  final String description;
  final String icon;

  const AchievementInfo({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class PlayerCareerStats {
  int totalDeaths;
  int totalClears;
  int totalPlaytimeSeconds;
  int stagesCreatedCount;
  Map<String, Map<String, dynamic>> stageStats;
  Set<String> unlockedAchievements;

  static const List<AchievementInfo> allAchievements = [
    AchievementInfo(
      key: 'first_splat',
      title: 'First Splat!',
      description: 'Experience your very first brutal death.',
      icon: '🩸',
    ),
    AchievementInfo(
      key: 'blood_donator',
      title: 'Blood Donator',
      description: 'Perish 50 times across any stages.',
      icon: '💉',
    ),
    AchievementInfo(
      key: 'century_of_pain',
      title: 'Centurion of Despair',
      description: 'Die 100 times. A true Masocore gamer!',
      icon: '💀',
    ),
    AchievementInfo(
      key: 'first_clear',
      title: 'Stage Conqueror',
      description: 'Clear any stage to claim victory.',
      icon: '🏆',
    ),
    AchievementInfo(
      key: 'the_guy_ascended',
      title: 'The Guy Ascended',
      description: 'Conquer all 3 canonical main stages.',
      icon: '👑',
    ),
    AchievementInfo(
      key: 'stage_architect',
      title: 'Level Architect',
      description: 'Build and save your first custom stage.',
      icon: '📐',
    ),
    AchievementInfo(
      key: 'untouchable',
      title: 'Untouchable',
      description: 'Complete a stage with zero deaths!',
      icon: '✨',
    ),
  ];

  PlayerCareerStats({
    this.totalDeaths = 0,
    this.totalClears = 0,
    this.totalPlaytimeSeconds = 0,
    this.stagesCreatedCount = 0,
    Map<String, Map<String, dynamic>>? stageStats,
    Set<String>? unlockedAchievements,
  })  : stageStats = stageStats ?? {},
        unlockedAchievements = unlockedAchievements ?? {};

  void recordDeath(String stageKey) {
    totalDeaths++;
    stageStats.putIfAbsent(stageKey, () => {'deaths': 0, 'clears': 0});
    stageStats[stageKey]!['deaths'] = (stageStats[stageKey]!['deaths'] as int? ?? 0) + 1;

    // Check death achievements
    if (totalDeaths >= 1) unlock('first_splat');
    if (totalDeaths >= 50) unlock('blood_donator');
    if (totalDeaths >= 100) unlock('century_of_pain');
  }

  void recordClear(String stageKey, {required int stageDeaths, double? durationSeconds}) {
    totalClears++;
    stageStats.putIfAbsent(stageKey, () => {'deaths': 0, 'clears': 0});
    stageStats[stageKey]!['clears'] = (stageStats[stageKey]!['clears'] as int? ?? 0) + 1;

    unlock('first_clear');
    if (stageDeaths == 0) unlock('untouchable');

    // Check if stages 1, 2, 3 cleared
    final s1 = (stageStats['stage_1']?['clears'] as int? ?? 0) > 0;
    final s2 = (stageStats['stage_2']?['clears'] as int? ?? 0) > 0;
    final s3 = (stageStats['stage_3']?['clears'] as int? ?? 0) > 0;
    if (s1 && s2 && s3) unlock('the_guy_ascended');
  }

  void recordStageCreated() {
    stagesCreatedCount++;
    unlock('stage_architect');
  }

  bool unlock(String key) {
    return unlockedAchievements.add(key);
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDeaths': totalDeaths,
      'totalClears': totalClears,
      'totalPlaytimeSeconds': totalPlaytimeSeconds,
      'stagesCreatedCount': stagesCreatedCount,
      'stageStats': stageStats,
      'unlockedAchievements': unlockedAchievements.toList(),
    };
  }

  factory PlayerCareerStats.fromJson(Map<String, dynamic> json) {
    return PlayerCareerStats(
      totalDeaths: json['totalDeaths'] as int? ?? 0,
      totalClears: json['totalClears'] as int? ?? 0,
      totalPlaytimeSeconds: json['totalPlaytimeSeconds'] as int? ?? 0,
      stagesCreatedCount: json['stagesCreatedCount'] as int? ?? 0,
      stageStats: (json['stageStats'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
          ) ??
          {},
      unlockedAchievements: (json['unlockedAchievements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {},
    );
  }
}
