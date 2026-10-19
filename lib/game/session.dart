import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'levels.dart';
import 'logic.dart';

class Piece {
  Piece({required this.id, required this.gem, this.special, this.ice = false})
    : frost = ice ? 1 : 0;

  final int id;
  int gem;
  String? special;
  bool ice;
  double frost;
  double r = 0;
  double c = 0;
  double scale = 1;
  double alpha = 1;
}

class Spark {
  Spark({
    required this.r,
    required this.c,
    required this.vr,
    required this.vc,
    required this.gem,
    required this.life,
    required this.size,
  });
  double r;
  double c;
  double vr;
  double vc;
  final int gem;
  double life;
  double age = 0;
  final double size;
}

class Floater {
  Floater({required this.text, required this.r, required this.c});
  final String text;
  final double r;
  final double c;
  double age = 0;
  final double life = 760;
}

class RingFx {
  RingFx({
    required this.r,
    required this.c,
    required this.special,
    required this.wide,
    required this.life,
  });
  final double r;
  final double c;
  final String special;
  final bool wide;
  double age = 0;
  final double life;
}

class GroveSession extends ChangeNotifier {
  GroveSession({
    required this.level,
    required this.reduced,
    this.onWin,
    this.onLose,
    this.onConsume,
    this.onSound,
  });

  final LevelDef level;
  final bool reduced;
  final void Function(int score, int stars, Map<int, int> collected)? onWin;
  final void Function(int score)? onLose;
  final void Function(String kind)? onConsume;
  final void Function(String name)? onSound;

  late List<List<Tile?>> grid;
  final pieces = <int, Piece>{};
  final sparks = <Spark>[];
  final floaters = <Floater>[];
  final rings = <RingFx>[];
  final collected = <int, int>{};
  final goalFlags = <bool>[];

  int score = 0;
  double shownScore = 0;
  int moves = 0;
  int epoch = 0;
  bool busy = false;
  String? over;
  String? aim;
  (int, int)? selected;
  Hint? hint;
  String? comboLabel;
  double comboAge = 0;
  double shake = 0;
  double idle = 0;
  bool _alive = true;

  double _now = 0;
  double _lastTick = 0;
  VoidCallback? _resume;

  double get clock => _now;

  late double Function() rng;

  void tick(Duration elapsed) {
    if (!_alive) return;
    final ms = elapsed.inMicroseconds / 1000.0;
    final dt = math.max(0, ms - _lastTick).toDouble();
    _lastTick = ms;
    _now += dt;
    if ((score - shownScore).abs() < 0.6) {
      shownScore = score.toDouble();
    } else {
      shownScore += (score - shownScore) * math.min(1, dt / 90);
    }
    shake = math.max(0, shake - dt);
    comboAge += dt;
    if (comboAge > 900) comboLabel = null;
    for (final spark in sparks) {
      spark.age += dt;
      spark.r += spark.vr * dt / 1000;
      spark.c += spark.vc * dt / 1000;
      spark.vr *= 0.98;
      spark.vc += dt / 900;
    }
    sparks.removeWhere((spark) => spark.age >= spark.life);
    if (sparks.length > 220) sparks.removeRange(0, sparks.length - 220);
    for (final floater in floaters) {
      floater.age += dt;
    }
    floaters.removeWhere((floater) => floater.age >= floater.life);
    for (final ring in rings) {
      ring.age += dt;
    }
    rings.removeWhere((ring) => ring.age >= ring.life);
    if (!busy && over == null) {
      idle += dt;
      if (idle > 4800 && hint == null) hint = findHint(grid);
    }
    final resume = _resume;
    _resume = null;
    resume?.call();
    notifyListeners();
  }

  Future<void> _motion(double duration, void Function(double t) update) async {
    final stamp = epoch;
    final safe = reduced ? math.min(duration, 80) : duration;
    final start = _now;
    while (_alive && epoch == stamp && _now - start < safe) {
      update(((_now - start) / safe).clamp(0.0, 1.0));
      notifyListeners();
      await _next();
    }
    if (!_alive || epoch != stamp) return;
    update(1);
    notifyListeners();
  }

  Future<void> _next() {
    if (!_alive) return Future.value();
    final completer = Completer<void>();
    _resume = () {
      if (!completer.isCompleted) completer.complete();
    };
    return completer.future;
  }

  void load() {
    epoch += 1;
    rng = mulberry32(DateTime.now().millisecondsSinceEpoch & 0x7fffffff);
    grid = createGrid(level.rows, level.cols, level.types, level.ice, rng);
    pieces.clear();
    sparks.clear();
    floaters.clear();
    rings.clear();
    collected.clear();
    goalFlags
      ..clear()
      ..addAll(List.filled(level.goals.length, false));
    score = 0;
    shownScore = 0;
    moves = level.moves;
    busy = true;
    over = null;
    aim = null;
    selected = null;
    hint = null;
    comboLabel = null;
    for (var r = 0; r < grid.length; r++) {
      for (var c = 0; c < grid[0].length; c++) {
        final tile = grid[r][c];
        if (tile == null) continue;
        final piece = Piece(
          id: tile.id,
          gem: tile.gem,
          special: tile.special,
          ice: tile.ice,
        );
        piece.r = r - 3.1 - (c % 3) * 0.15;
        piece.c = c.toDouble();
        pieces[tile.id] = piece;
      }
    }
    notifyListeners();
    _intro();
  }

  Future<void> _intro() async {
    final stamp = epoch;
    final movers = pieces.values.toList();
    await _motion(reduced ? 80 : 520, (t) {
      final e = _easeOut(t);
      for (final piece in movers) {
        final tileR = _rowOf(piece.id);
        if (tileR == null) continue;
        final from = tileR - 3.1 - (piece.c.round() % 3) * 0.15;
        piece.r = from + (tileR - from) * e;
      }
    });
    if (stamp != epoch) return;
    reconcile();
    busy = false;
    notifyListeners();
  }

  double? _rowOf(int id) {
    for (var r = 0; r < grid.length; r++) {
      for (var c = 0; c < grid[0].length; c++) {
        if (grid[r][c]?.id == id) return r.toDouble();
      }
    }
    return null;
  }

  void select(int r, int c) {
    if (busy || over != null) return;
    idle = 0;
    hint = null;
    if (aim == 'hammer') {
      hammerAt(r, c);
      return;
    }
    final tile = at(grid, r, c);
    if (tile == null) return;
    final current = selected;
    if (current == null) {
      if (!tile.ice) selected = (r, c);
      notifyListeners();
      return;
    }
    if (current.$1 == r && current.$2 == c) {
      selected = null;
      notifyListeners();
      return;
    }
    if ((current.$1 - r).abs() + (current.$2 - c).abs() == 1) {
      final from = current;
      selected = null;
      trySwap(from.$1, from.$2, r, c);
      return;
    }
    selected = tile.ice ? null : (r, c);
    notifyListeners();
  }

  void dragSwap(int r1, int c1, int r2, int c2) {
    if (busy || over != null || aim != null) return;
    selected = null;
    trySwap(r1, c1, r2, c2);
  }

  Future<void> trySwap(int r1, int c1, int r2, int c2) async {
    if (busy || over != null) return;
    final tileA = at(grid, r1, c1);
    final tileB = at(grid, r2, c2);
    if (tileA == null || tileB == null) return;
    final verdict = classifySwap(grid, r1, c1, r2, c2);
    final stamp = epoch;
    busy = true;
    selected = null;
    hint = null;
    idle = 0;
    try {
      if (verdict.kind == 'invalid') {
        await _nudge(tileA.id, tileB.id);
        onSound?.call('invalid');
        if (stamp == epoch) {
          busy = false;
          notifyListeners();
        }
        return;
      }
      swapTiles(grid, r1, c1, r2, c2);
      onSound?.call('swap');
      await _glide(tileA.id, tileB.id, r2, c2, r1, c1);
      if (stamp != epoch) return;
      moves -= 1;
      notifyListeners();
      await _resolvePair(r1, c1, r2, c2, stamp);
      if (stamp != epoch) return;
      await _finishTurn(stamp);
    } catch (error, stack) {
      debugPrint('swap failed: $error\n$stack');
      if (stamp == epoch) busy = false;
    }
  }

  Future<void> _nudge(int idA, int idB) async {
    final a = pieces[idA];
    final b = pieces[idB];
    if (a == null || b == null) return;
    final ar = a.r, ac = a.c, br = b.r, bc = b.c;
    await _motion(240, (t) {
      final wave = math.sin(t * math.pi);
      a.r = ar + (br - ar) * 0.16 * wave;
      a.c = ac + (bc - ac) * 0.16 * wave;
      b.r = br + (ar - br) * 0.06 * wave;
      b.c = bc + (ac - bc) * 0.06 * wave;
    });
    a.r = ar;
    a.c = ac;
    b.r = br;
    b.c = bc;
  }

  Future<void> _glide(int idA, int idB, int r2, int c2, int r1, int c1) async {
    final a = pieces[idA];
    final b = pieces[idB];
    if (a == null || b == null) return;
    final ar = a.r, ac = a.c, br = b.r, bc = b.c;
    await _motion(180, (t) {
      final e = _easeInOut(t);
      a.r = ar + (r2 - ar) * e;
      a.c = ac + (c2 - ac) * e;
      b.r = br + (r1 - br) * e;
      b.c = bc + (c1 - bc) * e;
    });
    a.r = r2.toDouble();
    a.c = c2.toDouble();
    b.r = r1.toDouble();
    b.c = c1.toDouble();
  }

  Future<void> _resolvePair(int r1, int c1, int r2, int c2, int stamp) async {
    final a = grid[r1][c1]!;
    final b = grid[r2][c2]!;
    late SettleResult result;
    if (a.special == 'rainbow' && b.special == 'rainbow') {
      result = resolveActivation(
        grid,
        [keyOf(r1, c1), keyOf(r2, c2)],
        rng,
        level.types,
        const ActivateOpts(color: 'all'),
      );
    } else if (a.special == 'rainbow' || b.special == 'rainbow') {
      final rainbowPos = a.special == 'rainbow' ? (r1, c1) : (r2, c2);
      final other = a.special == 'rainbow' ? b : a;
      final origins = prepareRainbowCombo(grid, other.gem, other.special)
        ..add(keyOf(rainbowPos.$1, rainbowPos.$2));
      _syncSpecials();
      result = resolveActivation(
        grid,
        origins,
        rng,
        level.types,
        ActivateOpts(color: other.gem),
      );
    } else if (a.special != null && b.special != null) {
      upgradeCombo(a, b);
      _syncSpecials();
      await _motion(120, (t) {
        for (final id in [a.id, b.id]) {
          final piece = pieces[id];
          if (piece != null) piece.scale = 1 + math.sin(t * math.pi) * 0.18;
        }
      });
      result = resolveActivation(
        grid,
        [keyOf(r1, c1), keyOf(r2, c2)],
        rng,
        level.types,
      );
    } else {
      result = settle(grid, rng, level.types, [keyOf(r2, c2), keyOf(r1, c1)]);
    }
    await _playSteps(result, stamp);
  }

  void _syncSpecials() {
    for (final row in grid) {
      for (final tile in row) {
        if (tile == null) continue;
        final piece = pieces[tile.id];
        if (piece == null) continue;
        piece.special = tile.special;
        piece.gem = tile.gem;
      }
    }
  }

  Future<void> _playSteps(SettleResult result, int stamp) async {
    for (final step in result.steps) {
      if (stamp != epoch) return;
      if (step.kind == 'clear') {
        await _animateClear(step, stamp);
      } else {
        await _animateDrop(step, stamp);
      }
    }
    if (stamp == epoch) reconcile();
  }

  Future<void> _animateClear(SettleStep step, int stamp) async {
    if (step.waves.isNotEmpty) {
      onSound?.call('special');
    } else if (step.removed.isNotEmpty) {
      onSound?.call('match');
    }
    if (step.waves.any(
      (wave) => wave.special == 'bomb' || wave.special == 'rainbow',
    )) {
      shake = 180;
    }
    if (!reduced) {
      for (final wave in step.waves) {
        rings.add(
          RingFx(
            r: wave.r.toDouble(),
            c: wave.c.toDouble(),
            special: wave.special,
            wide: wave.wide,
            life: wave.special == 'rainbow' ? 460 : 320,
          ),
        );
      }
    }
    final fading = <Piece>[];
    for (final tile in step.removed) {
      final piece = pieces[tile.id];
      if (piece != null) fading.add(piece);
      _burst(
        tile.r.toDouble(),
        tile.c.toDouble(),
        tile.gem,
        step.combo >= 3 ? 16 : 10,
      );
      if (tile.gem >= 0) collected[tile.gem] = (collected[tile.gem] ?? 0) + 1;
    }
    score += step.points;
    if (step.removed.isNotEmpty && step.points > 0) {
      final anchor = step.removed[step.removed.length ~/ 2];
      floaters.add(
        Floater(
          text: '+${step.points}',
          r: anchor.r.toDouble(),
          c: anchor.c.toDouble(),
        ),
      );
    }
    _noteGoals();
    if (step.combo >= 2) {
      comboLabel = _comboName(step.combo);
      comboAge = 0;
    }
    notifyListeners();
    await _motion(240, (t) {
      for (final piece in fading) {
        if (t < 0.35) {
          piece.scale = 1 + (t / 0.35) * 0.16;
        } else {
          piece.scale = 1 - (t - 0.35) / 0.65;
        }
        piece.alpha = t < 0.45 ? 1 : 1 - (t - 0.45) / 0.55;
      }
      for (final ice in step.iceBroken) {
        final piece = pieces[ice.id];
        if (piece != null) piece.frost = 1 - t;
      }
    });
    if (stamp != epoch) return;
    for (final tile in step.removed) {
      pieces.remove(tile.id);
    }
    for (final ice in step.iceBroken) {
      final piece = pieces[ice.id];
      if (piece != null) {
        piece.ice = false;
        piece.frost = 0;
      }
    }
    for (final born in step.spawned) {
      final piece = Piece(id: born.id, gem: born.gem, special: born.special)
        ..r = born.r.toDouble()
        ..c = born.c.toDouble()
        ..scale = 0.2
        ..alpha = 0;
      pieces[born.id] = piece;
      _burst(born.r.toDouble(), born.c.toDouble(), born.gem, 12);
    }
    if (step.spawned.isNotEmpty) {
      await _motion(220, (t) {
        final e = _easeOutBack(t);
        for (final born in step.spawned) {
          final piece = pieces[born.id];
          if (piece == null) continue;
          piece.scale = math.max(0.2, e);
          piece.alpha = math.min(1, t * 1.6);
        }
      });
    }
  }

  Future<void> _animateDrop(
    SettleStep step,
    int stamp, {
    bool shuffle = false,
  }) async {
    final movers =
        <
          ({
            Piece piece,
            double r,
            double c,
            double toR,
            double toC,
            double dist,
          })
        >[];
    for (final drop in step.drops) {
      var piece = pieces[drop.id];
      if (piece == null) {
        piece = Piece(id: drop.id, gem: drop.gem, special: drop.special)
          ..r = drop.fromR.toDouble()
          ..c = drop.fromC.toDouble()
          ..scale = drop.spawn ? 0.86 : 1;
        pieces[drop.id] = piece;
      }
      movers.add((
        piece: piece,
        r: piece.r,
        c: piece.c,
        toR: drop.toR.toDouble(),
        toC: drop.toC.toDouble(),
        dist:
            (drop.toR - drop.fromR).abs() +
            (drop.toC - drop.fromC).abs().toDouble(),
      ));
    }
    if (movers.isEmpty) return;
    final farthest = movers.map((mover) => mover.dist).reduce(math.max);
    final duration = shuffle ? 420.0 : math.min(560.0, 160 + farthest * 62);
    await _motion(duration, (t) {
      final e = shuffle ? _easeInOut(t) : _easeFall(t);
      for (final mover in movers) {
        mover.piece.r = mover.r + (mover.toR - mover.r) * e;
        mover.piece.c = mover.c + (mover.toC - mover.c) * e;
        if (mover.piece.scale < 1) mover.piece.scale = 0.86 + 0.14 * t;
      }
    });
    if (stamp != epoch) return;
    for (final mover in movers) {
      mover.piece.r = mover.toR;
      mover.piece.c = mover.toC;
    }
  }

  Future<void> _finishTurn(int stamp) async {
    if (stamp != epoch) return;
    if (_goalsDone()) {
      await _bonus(stamp);
      if (stamp != epoch) return;
      over = 'win';
      busy = false;
      final stars = math.max(1, starCount(score, level.stars));
      onSound?.call('win');
      onWin?.call(score, stars, Map<int, int>.from(collected));
      notifyListeners();
      return;
    }
    if (moves <= 0) {
      over = 'lose';
      busy = false;
      onSound?.call('lose');
      onLose?.call(score);
      notifyListeners();
      return;
    }
    if (findHint(grid) == null) {
      await _doShuffle(stamp);
    }
    if (stamp == epoch) {
      busy = false;
      notifyListeners();
    }
  }

  bool _goalsDone() {
    return goalsMet(
      [
        for (final goal in level.goals)
          (type: goal.type, target: goal.target, gem: goal.gem),
      ],
      score,
      collected,
    );
  }

  void _noteGoals() {
    for (var i = 0; i < level.goals.length; i++) {
      final goal = level.goals[i];
      final done = goal.type == 'score'
          ? score >= goal.target
          : (collected[goal.gem] ?? 0) >= goal.target;
      if (done && i < goalFlags.length && !goalFlags[i]) goalFlags[i] = true;
    }
  }

  Future<void> _bonus(int stamp) async {
    var guard = 0;
    while (moves > 0 && guard < 36 && stamp == epoch) {
      guard += 1;
      final spot = randomPlainSpot(grid, rng);
      if (spot == null) break;
      final tile = grid[spot.$1][spot.$2]!;
      final roll = rng();
      tile.special = roll < 0.42
          ? 'lineH'
          : roll < 0.84
          ? 'lineV'
          : 'bomb';
      final piece = pieces[tile.id];
      if (piece != null) {
        piece.special = tile.special;
        piece.scale = 0.4;
      }
      moves -= 1;
      notifyListeners();
      await _motion(140, (t) {
        if (piece != null) piece.scale = 0.4 + _easeOutBack(t) * 0.6;
      });
      if (stamp != epoch) return;
      final result = resolveActivation(
        grid,
        [keyOf(spot.$1, spot.$2)],
        rng,
        level.types,
      );
      await _playSteps(result, stamp);
    }
  }

  Future<void> _doShuffle(int stamp) async {
    final drops = reshuffle(grid, rng);
    onSound?.call('whoosh');
    await _animateDrop(SettleStep.drop(drops), stamp, shuffle: true);
    if (stamp == epoch) reconcile();
  }

  bool arm(String kind) {
    if (busy || over != null) return false;
    if (kind == 'shuffle') {
      useShuffle();
      return true;
    }
    aim = kind;
    selected = null;
    notifyListeners();
    return true;
  }

  void cancelAim() {
    aim = null;
    notifyListeners();
  }

  Future<void> hammerAt(int r, int c) async {
    final tile = at(grid, r, c);
    if (tile == null || busy || over != null) return;
    final stamp = epoch;
    aim = null;
    busy = true;
    onConsume?.call('hammer');
    onSound?.call('hammer');
    final opts = tile.special == 'rainbow'
        ? ActivateOpts(color: tile.gem)
        : const ActivateOpts();
    final result = resolveActivation(
      grid,
      [keyOf(r, c)],
      rng,
      level.types,
      opts,
    );
    await _playSteps(result, stamp);
    if (stamp != epoch) return;
    await _finishTurn(stamp);
  }

  Future<void> useShuffle() async {
    if (busy || over != null) return;
    final stamp = epoch;
    busy = true;
    onConsume?.call('shuffle');
    await _doShuffle(stamp);
    if (stamp == epoch) {
      busy = false;
      notifyListeners();
    }
  }

  void grantMoves(int count) {
    moves += count;
    if (over == 'lose') over = null;
    busy = false;
    notifyListeners();
  }

  void reconcile() {
    final live = <int>{};
    for (var r = 0; r < grid.length; r++) {
      for (var c = 0; c < grid[0].length; c++) {
        final tile = grid[r][c];
        if (tile == null) continue;
        live.add(tile.id);
        final piece = pieces.putIfAbsent(
          tile.id,
          () => Piece(
            id: tile.id,
            gem: tile.gem,
            special: tile.special,
            ice: tile.ice,
          ),
        );
        piece.gem = tile.gem;
        piece.special = tile.special;
        piece.ice = tile.ice;
        piece.r = r.toDouble();
        piece.c = c.toDouble();
        piece.scale = 1;
        piece.alpha = 1;
        if (!tile.ice) piece.frost = 0;
      }
    }
    pieces.removeWhere((id, _) => !live.contains(id));
  }

  void _burst(double r, double c, int gem, int count) {
    if (reduced) return;
    final random = math.Random(gem * 17 + count + sparks.length);
    for (var i = 0; i < count; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final speed = 0.8 + random.nextDouble() * 2.4;
      sparks.add(
        Spark(
          r: r + 0.5,
          c: c + 0.5,
          vr: math.sin(angle) * speed,
          vc: math.cos(angle) * speed,
          gem: gem,
          life: 420 + random.nextDouble() * 280,
          size: 0.08 + random.nextDouble() * 0.12,
        ),
      );
    }
  }

  String _comboName(int combo) {
    if (combo >= 5) return 'aurora';
    if (combo == 4) return 'divine';
    if (combo == 3) return 'sweet';
    return 'nice';
  }

  @override
  void dispose() {
    _alive = false;
    epoch += 1;
    final resume = _resume;
    _resume = null;
    resume?.call();
    super.dispose();
  }
}

double _easeInOut(double t) =>
    t < 0.5 ? 2 * t * t : 1 - math.pow(-2 * t + 2, 2) / 2;

double _easeOut(double t) => 1 - math.pow(1 - t, 3).toDouble();

double _easeFall(double t) {
  const c1 = 1.4;
  const c3 = c1 + 1;
  return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2);
}

double _easeOutBack(double t) {
  const c1 = 1.70158;
  const c3 = c1 + 1;
  return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2);
}
