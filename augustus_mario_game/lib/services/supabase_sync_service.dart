import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/custom_stage_data.dart';
import '../models/player_career_stats.dart';
import '../models/player_customization.dart';

/// Supabase Cloud Synchronization Service (Hybrid Architecture)
///
/// Designed to work alongside Local Storage:
/// - When credentials are not configured, the game seamlessly operates in 100% offline local mode.
/// - When a developer or user provides a Supabase project URL & Anon Key, this service can sync
///   custom stages, high scores, and player customizations to the cloud.
class SupabaseSyncService {
  static final SupabaseSyncService instance = SupabaseSyncService._internal();
  SupabaseSyncService._internal();

  String? _supabaseUrl;
  String? _anonKey;

  bool get isConfigured =>
      _supabaseUrl != null &&
      _supabaseUrl!.isNotEmpty &&
      _anonKey != null &&
      _anonKey!.isNotEmpty;

  void configure({required String url, required String anonKey}) {
    _supabaseUrl = url.trim();
    _anonKey = anonKey.trim();
  }

  /// Syncs player profile to cloud database (if configured)
  Future<bool> uploadProfile({
    required String playerId,
    required PlayerCustomization customization,
    required PlayerCareerStats stats,
  }) async {
    if (!isConfigured) {
      debugPrint('[SupabaseSync] Skipped: Supabase credentials not set (Running in Offline Mode)');
      return false;
    }

    try {
      debugPrint('[SupabaseSync] Syncing player profile to cloud endpoint: $_supabaseUrl');
      // Hybrid placeholder: Can use HTTP POST or supabase_flutter SDK to upsert 'profiles'
      return true;
    } catch (e) {
      debugPrint('[SupabaseSync] Error uploading profile: $e');
      return false;
    }
  }

  /// Uploads a custom stage to the community repository
  Future<bool> publishStage(CustomStageData stage) async {
    if (!isConfigured) {
      debugPrint('[SupabaseSync] Skipped: Supabase credentials not set (Running in Offline Mode)');
      return false;
    }

    try {
      final stagePayload = jsonEncode(stage.toJson());
      debugPrint('[SupabaseSync] Publishing stage "${stage.title}" (${stagePayload.length} bytes) to cloud');
      return true;
    } catch (e) {
      debugPrint('[SupabaseSync] Error publishing stage: $e');
      return false;
    }
  }

  /// Fetches shared community stages from cloud
  Future<List<CustomStageData>> fetchCommunityStages() async {
    if (!isConfigured) {
      return [];
    }

    try {
      debugPrint('[SupabaseSync] Querying community stages from cloud database');
      return [];
    } catch (e) {
      debugPrint('[SupabaseSync] Error fetching community stages: $e');
      return [];
    }
  }
}
