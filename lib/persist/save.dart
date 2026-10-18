import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LevelProgress {
  const LevelProgress(this.stars, this.best);
  final int stars;
  final int best;
}

class Product {
  const Product(this.id, this.cost, this.grant);
  final String id;
  final int cost;
  final Map<String, int> grant;
}

const products = [
  Product('hammer', 120, {'hammer': 1}),
  Product('shuffle', 90, {'shuffle': 1}),
  Product('extra', 160, {'extra': 1}),
  Product('basket', 280, {'hammer': 3, 'shuffle': 1}),
];

int coinReward(int stars, bool firstClear) {
  const table = [0, 35, 70, 110];
  return table[stars.clamp(0, 3)] + (firstClear ? 45 : 0);
}

class GroveSave extends ChangeNotifier {
  static const _key = 'glimmer-grove-v1';

  String name = '';
  int avatar = 0;
  int coins = 250;
  int hammer = 2;
  int shuffleBooster = 1;
  int extra = 1;
  int unlocked = 1;
  bool sfx = true;
  bool music = true;
  bool reduced = false;
  String lang = 'en';
  String daily = '';
  bool tutorial = false;
  final levels = <int, LevelProgress>{};

  int get totalStars =>
      levels.values.fold(0, (sum, level) => sum + level.stars);

  bool get dailyReady => daily != _today();

  static Future<GroveSave> open() async {
    final save = GroveSave();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      final code = PlatformDispatcher.instance.locale.languageCode
          .toLowerCase();
      save.lang = code.startsWith('es') ? 'es' : 'en';
      await save.persist();
      return save;
    }
    try {
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      save.name = parsed['name'] as String? ?? '';
      save.avatar = parsed['avatar'] as int? ?? 0;
      save.coins = parsed['coins'] as int? ?? 250;
      final boosters = parsed['boosters'] as Map<String, dynamic>? ?? {};
      save.hammer = boosters['hammer'] as int? ?? 2;
      save.shuffleBooster = boosters['shuffle'] as int? ?? 1;
      save.extra = boosters['extra'] as int? ?? 1;
      save.unlocked = parsed['unlocked'] as int? ?? 1;
      save.sfx = parsed['sfx'] as bool? ?? true;
      save.music = parsed['music'] as bool? ?? true;
      save.reduced = parsed['reduced'] as bool? ?? false;
      save.lang = parsed['lang'] as String? ?? 'en';
      save.daily = parsed['daily'] as String? ?? '';
      save.tutorial = parsed['tutorial'] as bool? ?? false;
      final stored = parsed['levels'] as Map<String, dynamic>? ?? {};
      for (final entry in stored.entries) {
        final body = entry.value as Map<String, dynamic>;
        save.levels[int.parse(entry.key)] = LevelProgress(
          body['stars'] as int? ?? 0,
          body['best'] as int? ?? 0,
        );
      }
    } catch (error) {
      debugPrint('save reset: $error');
    }
    return save;
  }

  void commit() {
    persist();
    notifyListeners();
  }

  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'name': name,
        'avatar': avatar,
        'coins': coins,
        'boosters': {
          'hammer': hammer,
          'shuffle': shuffleBooster,
          'extra': extra,
        },
        'unlocked': unlocked,
        'sfx': sfx,
        'music': music,
        'reduced': reduced,
        'lang': lang,
        'daily': daily,
        'tutorial': tutorial,
        'levels': {
          for (final entry in levels.entries)
            '${entry.key}': {
              'stars': entry.value.stars,
              'best': entry.value.best,
            },
        },
      }),
    );
  }

  int finishLevel(int id, int stars, int score) {
    final prev = levels[id];
    final first = (prev?.stars ?? 0) == 0;
    final reward = coinReward(stars, first);
    levels[id] = LevelProgress(
      stars > (prev?.stars ?? 0) ? stars : (prev?.stars ?? 0),
      score > (prev?.best ?? 0) ? score : (prev?.best ?? 0),
    );
    if (id >= unlocked && id < 24) unlocked = id + 1;
    coins += reward;
    persist();
    notifyListeners();
    return reward;
  }

  bool spend(int cost) {
    if (coins < cost) return false;
    coins -= cost;
    persist();
    notifyListeners();
    return true;
  }

  void grant(Map<String, int> items, {int coinsAdded = 0}) {
    coins += coinsAdded;
    hammer += items['hammer'] ?? 0;
    shuffleBooster += items['shuffle'] ?? 0;
    extra += items['extra'] ?? 0;
    persist();
    notifyListeners();
  }

  void consume(String kind) {
    if (kind == 'hammer' && hammer > 0) hammer -= 1;
    if (kind == 'shuffle' && shuffleBooster > 0) shuffleBooster -= 1;
    if (kind == 'extra' && extra > 0) extra -= 1;
    persist();
    notifyListeners();
  }

  void claimDaily() {
    if (!dailyReady) return;
    daily = _today();
    grant({'hammer': 1}, coinsAdded: 100);
  }

  void reset() {
    final kept = lang;
    name = '';
    avatar = 0;
    coins = 250;
    hammer = 2;
    shuffleBooster = 1;
    extra = 1;
    unlocked = 1;
    sfx = true;
    music = true;
    reduced = false;
    lang = kept;
    daily = '';
    tutorial = false;
    levels.clear();
    persist();
    notifyListeners();
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
