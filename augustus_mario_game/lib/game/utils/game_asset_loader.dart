import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/services.dart';

class GameAssetLoader {
  static final Map<String, Sprite?> _spriteCache = {};

  /// Loads an optional sprite from `assets/images/$relativePath`.
  /// If the image asset does not exist in the bundle, returns `null` safely
  /// so components can gracefully fall back to procedural Canvas rendering.
  static Future<Sprite?> loadOptionalSprite(String relativePath) async {
    if (_spriteCache.containsKey(relativePath)) {
      return _spriteCache[relativePath];
    }

    try {
      // Check if file is bundled in the app assets
      await rootBundle.load('assets/images/$relativePath');
      final image = await Flame.images.load(relativePath);
      final sprite = Sprite(image);
      _spriteCache[relativePath] = sprite;
      return sprite;
    } catch (_) {
      // File not present in assets yet -> return null for graceful fallback
      _spriteCache[relativePath] = null;
      return null;
    }
  }

  /// Clears cache (useful for testing or hot-reload asset updates)
  static void clearCache() {
    _spriteCache.clear();
  }
}
