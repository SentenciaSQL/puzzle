/// Match-3 rules for Glimmer Grove.
/// Cells are tiles or null. Tile ids stay stable so the board can animate them.
library;

int _seq = 1;

void resetIds([int start = 1]) {
  _seq = start;
}

class Tile {
  Tile({
    required this.id,
    required this.gem,
    this.special,
    this.ice = false,
    this.bombRadius = 1,
    this.lineWidth = 0,
    this.rainbowColor,
  });

  final int id;
  int gem;
  String? special;
  bool ice;
  int bombRadius;
  int lineWidth;
  int? rainbowColor;
  int? spawnFrom;
}

Tile makeTile(int gem, [String? special, bool ice = false]) {
  return Tile(id: _seq++, gem: gem, special: special, ice: ice);
}

String keyOf(int r, int c) => '$r,$c';

(int, int) parseKey(String key) {
  final parts = key.split(',');
  return (int.parse(parts[0]), int.parse(parts[1]));
}

bool inBounds(List<List<Tile?>> grid, int r, int c) {
  return r >= 0 && c >= 0 && r < grid.length && c < grid[0].length;
}

Tile? at(List<List<Tile?>> grid, int r, int c) {
  if (r < 0 || c < 0 || r >= grid.length || c >= grid[0].length) return null;
  return grid[r][c];
}

bool _sameRun(Tile? a, Tile? b) {
  return a != null &&
      b != null &&
      !a.ice &&
      !b.ice &&
      a.special != 'rainbow' &&
      b.special != 'rainbow' &&
      a.gem == b.gem;
}

class MatchGroup {
  MatchGroup({required this.cells, required this.dir, required this.gem})
    : len = cells.length;

  final List<(int, int)> cells;
  final String dir;
  final int len;
  final int gem;
}

class MatchFound {
  MatchFound(this.cells, this.groups);
  final Set<String> cells;
  final List<MatchGroup> groups;
}

MatchFound findMatches(List<List<Tile?>> grid) {
  final rows = grid.length;
  final cols = grid[0].length;
  final cells = <String>{};
  final groups = <MatchGroup>[];

  for (var r = 0; r < rows; r++) {
    var c = 0;
    while (c < cols) {
      final start = grid[r][c];
      if (start == null || start.ice || start.special == 'rainbow') {
        c += 1;
        continue;
      }
      var c2 = c + 1;
      while (c2 < cols && _sameRun(start, grid[r][c2])) {
        c2 += 1;
      }
      if (c2 - c >= 3) {
        final list = <(int, int)>[];
        for (var k = c; k < c2; k++) {
          cells.add(keyOf(r, k));
          list.add((r, k));
        }
        groups.add(MatchGroup(cells: list, dir: 'h', gem: start.gem));
      }
      c = c2;
    }
  }

  for (var c = 0; c < cols; c++) {
    var r = 0;
    while (r < rows) {
      final start = grid[r][c];
      if (start == null || start.ice || start.special == 'rainbow') {
        r += 1;
        continue;
      }
      var r2 = r + 1;
      while (r2 < rows && _sameRun(start, grid[r2][c])) {
        r2 += 1;
      }
      if (r2 - r >= 3) {
        final list = <(int, int)>[];
        for (var k = r; k < r2; k++) {
          cells.add(keyOf(k, c));
          list.add((k, c));
        }
        groups.add(MatchGroup(cells: list, dir: 'v', gem: start.gem));
      }
      r = r2;
    }
  }

  return MatchFound(cells, groups);
}

class _Cluster {
  _Cluster(this.gem);
  final List<MatchGroup> groups = [];
  final Set<String> cells = {};
  final int gem;
}

List<_Cluster> _clusterGroups(List<MatchGroup> groups) {
  final parent = <String, String>{};
  String find(String id) {
    parent.putIfAbsent(id, () => id);
    if (parent[id] != id) parent[id] = find(parent[id]!);
    return parent[id]!;
  }

  void union(String a, String b) {
    final pa = find(a);
    final pb = find(b);
    if (pa != pb) parent[pa] = pb;
  }

  for (final group in groups) {
    final first = keyOf(group.cells.first.$1, group.cells.first.$2);
    for (final cell in group.cells) {
      union(first, keyOf(cell.$1, cell.$2));
    }
  }

  final map = <String, _Cluster>{};
  for (final group in groups) {
    final root = find(keyOf(group.cells.first.$1, group.cells.first.$2));
    final cluster = map.putIfAbsent(root, () => _Cluster(group.gem));
    cluster.groups.add(group);
    for (final cell in group.cells) {
      cluster.cells.add(keyOf(cell.$1, cell.$2));
    }
  }
  return map.values.toList();
}

({String special, int gem})? _classifyCluster(_Cluster cluster) {
  var maxLine = 0;
  var maxGroup = cluster.groups.first;
  for (final group in cluster.groups) {
    if (group.len > maxLine) {
      maxLine = group.len;
      maxGroup = group;
    }
  }
  final hasH = cluster.groups.any((group) => group.dir == 'h');
  final hasV = cluster.groups.any((group) => group.dir == 'v');
  String? special;
  if (maxLine >= 5) {
    special = 'rainbow';
  } else if (hasH && hasV && cluster.cells.length >= 5) {
    special = 'bomb';
  } else if (maxLine == 4) {
    special = maxGroup.dir == 'h' ? 'lineH' : 'lineV';
  }
  if (special == null) return null;
  return (special: special, gem: cluster.gem);
}

String _pickCell(_Cluster cluster, List<String> preferKeys) {
  for (final key in preferKeys) {
    if (cluster.cells.contains(key)) return key;
  }
  final counts = <String, int>{};
  for (final group in cluster.groups) {
    for (final cell in group.cells) {
      final key = keyOf(cell.$1, cell.$2);
      counts[key] = (counts[key] ?? 0) + 1;
    }
  }
  String? best;
  var bestN = 0;
  for (final entry in counts.entries) {
    if (entry.value > bestN) {
      best = entry.key;
      bestN = entry.value;
    }
  }
  if (best != null && bestN >= 2) return best;
  final longest = cluster.groups.reduce((a, b) => a.len >= b.len ? a : b);
  final mid = longest.cells[(longest.cells.length - 1) ~/ 2];
  return keyOf(mid.$1, mid.$2);
}

class SpecialPlan {
  SpecialPlan({
    required this.r,
    required this.c,
    required this.gem,
    required this.special,
  });
  final int r;
  final int c;
  final int gem;
  final String special;
}

List<SpecialPlan> planSpecials(
  MatchFound found, [
  List<String> preferKeys = const [],
]) {
  final plans = <SpecialPlan>[];
  for (final cluster in _clusterGroups(found.groups)) {
    final spec = _classifyCluster(cluster);
    if (spec == null) continue;
    final cell = parseKey(_pickCell(cluster, preferKeys));
    plans.add(
      SpecialPlan(r: cell.$1, c: cell.$2, gem: spec.gem, special: spec.special),
    );
  }
  return plans;
}

int _dominantColor(List<List<Tile?>> grid) {
  final counts = <int, int>{};
  for (final row in grid) {
    for (final tile in row) {
      if (tile == null || tile.special == 'rainbow') continue;
      counts[tile.gem] = (counts[tile.gem] ?? 0) + 1;
    }
  }
  var best = 0;
  var bestN = -1;
  for (final entry in counts.entries) {
    if (entry.value > bestN) {
      best = entry.key;
      bestN = entry.value;
    }
  }
  return best;
}

List<(int, int)> _coverage(
  Tile tile,
  int r,
  int c,
  int rows,
  int cols,
  List<List<Tile?>> grid,
  Object? colorOverride,
) {
  final all = <(int, int)>[];
  if (tile.special == 'lineH') {
    final width = tile.lineWidth;
    for (var rr = r - width; rr <= r + width; rr++) {
      if (rr < 0 || rr >= rows) continue;
      for (var cc = 0; cc < cols; cc++) {
        all.add((rr, cc));
      }
    }
    return all;
  }
  if (tile.special == 'lineV') {
    final width = tile.lineWidth;
    for (var cc = c - width; cc <= c + width; cc++) {
      if (cc < 0 || cc >= cols) continue;
      for (var rr = 0; rr < rows; rr++) {
        all.add((rr, cc));
      }
    }
    return all;
  }
  if (tile.special == 'bomb') {
    final rad = tile.bombRadius;
    for (var rr = r - rad; rr <= r + rad; rr++) {
      for (var cc = c - rad; cc <= c + rad; cc++) {
        if (rr >= 0 && cc >= 0 && rr < rows && cc < cols) all.add((rr, cc));
      }
    }
    return all;
  }
  if (tile.special == 'rainbow') {
    if (colorOverride == 'all') {
      for (var rr = 0; rr < rows; rr++) {
        for (var cc = 0; cc < cols; cc++) {
          all.add((rr, cc));
        }
      }
      return all;
    }
    final color = colorOverride is int
        ? colorOverride
        : (tile.rainbowColor ?? _dominantColor(grid));
    for (var rr = 0; rr < rows; rr++) {
      for (var cc = 0; cc < cols; cc++) {
        final other = grid[rr][cc];
        if (other == null) continue;
        if (other.special == 'rainbow' || other.gem == color) all.add((rr, cc));
      }
    }
    if (all.isEmpty) all.add((r, c));
    return all;
  }
  return [(r, c)];
}

class Wave {
  Wave({
    required this.special,
    required this.r,
    required this.c,
    required this.gem,
    required this.wide,
  });
  final String special;
  final int r;
  final int c;
  final int gem;
  final bool wide;
}

class ActivateResult {
  ActivateResult(this.cells, this.waves);
  final Set<String> cells;
  final List<Wave> waves;
}

class ActivateOpts {
  const ActivateOpts({this.color});
  final Object? color;
}

ActivateResult activate(
  List<List<Tile?>> grid,
  List<String> originKeys, [
  ActivateOpts opts = const ActivateOpts(),
]) {
  final rows = grid.length;
  final cols = grid[0].length;
  final cells = <String>{};
  final waves = <Wave>[];
  final seen = <String>{};
  final queue = [...originKeys];

  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    if (seen.contains(current)) continue;
    seen.add(current);
    final parsed = parseKey(current);
    final r = parsed.$1;
    final c = parsed.$2;
    final tile = at(grid, r, c);
    if (tile == null) {
      cells.add(current);
      continue;
    }
    final area = _coverage(tile, r, c, rows, cols, grid, opts.color);
    if (tile.special != null) {
      waves.add(
        Wave(
          special: tile.special!,
          r: r,
          c: c,
          gem: tile.gem,
          wide: tile.lineWidth > 0 || tile.bombRadius > 1,
        ),
      );
    }
    for (final cell in area) {
      final next = keyOf(cell.$1, cell.$2);
      cells.add(next);
      final other = at(grid, cell.$1, cell.$2);
      if (other?.special != null && !seen.contains(next)) queue.add(next);
    }
  }

  return ActivateResult(cells, waves);
}

int scoreValue(int removedCount, List<Wave> waves, int combo, int iceCount) {
  var score = removedCount * 50 * combo + iceCount * 40 * combo;
  for (final wave in waves) {
    if (wave.special == 'lineH' || wave.special == 'lineV') {
      score += 140 * combo;
    } else if (wave.special == 'bomb') {
      score += 280 * combo;
    } else if (wave.special == 'rainbow') {
      score += 460 * combo;
    }
  }
  return score;
}

void _tally(Map<int, int> collected, List<RemovedTile> removed) {
  for (final tile in removed) {
    if (tile.gem < 0) continue;
    collected[tile.gem] = (collected[tile.gem] ?? 0) + 1;
  }
}

class RemovedTile {
  RemovedTile({
    required this.id,
    required this.gem,
    required this.special,
    required this.ice,
    required this.r,
    required this.c,
  });
  final int id;
  final int gem;
  final String? special;
  final bool ice;
  final int r;
  final int c;
}

class IceBreak {
  IceBreak({required this.id, required this.r, required this.c});
  final int id;
  final int r;
  final int c;
}

class SpawnedTile {
  SpawnedTile({
    required this.id,
    required this.gem,
    required this.special,
    required this.r,
    required this.c,
  });
  final int id;
  final int gem;
  final String? special;
  final int r;
  final int c;
}

class ClearApplied {
  ClearApplied(this.removed, this.iceBroken, this.spawnedTiles);
  final List<RemovedTile> removed;
  final List<IceBreak> iceBroken;
  final List<SpawnedTile> spawnedTiles;
}

const _neighbors = [(1, 0), (-1, 0), (0, 1), (0, -1)];

ClearApplied applyClear(
  List<List<Tile?>> grid,
  Set<String> cellKeys, [
  List<SpecialPlan> spawned = const [],
]) {
  final removed = <RemovedTile>[];
  final iceBroken = <IceBreak>[];
  final seenIce = <String>{};

  for (final key in cellKeys) {
    final parsed = parseKey(key);
    final tile = at(grid, parsed.$1, parsed.$2);
    if (tile == null) continue;
    removed.add(
      RemovedTile(
        id: tile.id,
        gem: tile.gem,
        special: tile.special,
        ice: tile.ice,
        r: parsed.$1,
        c: parsed.$2,
      ),
    );
    for (final delta in _neighbors) {
      final rr = parsed.$1 + delta.$1;
      final cc = parsed.$2 + delta.$2;
      if (!inBounds(grid, rr, cc)) continue;
      final nextKey = keyOf(rr, cc);
      final neighbor = grid[rr][cc];
      if (neighbor != null &&
          neighbor.ice &&
          !cellKeys.contains(nextKey) &&
          !seenIce.contains(nextKey)) {
        seenIce.add(nextKey);
        iceBroken.add(IceBreak(id: neighbor.id, r: rr, c: cc));
      }
    }
  }

  for (final key in cellKeys) {
    final parsed = parseKey(key);
    if (inBounds(grid, parsed.$1, parsed.$2)) grid[parsed.$1][parsed.$2] = null;
  }
  for (final broken in iceBroken) {
    grid[broken.r][broken.c]!.ice = false;
  }

  final spawnedTiles = <SpawnedTile>[];
  for (final plan in spawned) {
    if (!inBounds(grid, plan.r, plan.c)) continue;
    final tile = makeTile(plan.gem, plan.special, false);
    if (plan.special == 'rainbow') tile.rainbowColor = plan.gem;
    grid[plan.r][plan.c] = tile;
    spawnedTiles.add(
      SpawnedTile(
        id: tile.id,
        gem: tile.gem,
        special: tile.special,
        r: plan.r,
        c: plan.c,
      ),
    );
  }

  return ClearApplied(removed, iceBroken, spawnedTiles);
}

class Drop {
  Drop({
    required this.id,
    required this.gem,
    required this.special,
    required this.ice,
    required this.fromR,
    required this.fromC,
    required this.toR,
    required this.toC,
    required this.spawn,
  });

  final int id;
  final int gem;
  final String? special;
  final bool ice;
  final int fromR;
  final int fromC;
  final int toR;
  final int toC;
  final bool spawn;
}

class _Pos {
  _Pos(this.r, this.c, this.gem, this.special, this.ice);
  final int r;
  final int c;
  final int gem;
  final String? special;
  final bool ice;
}

List<Drop> collapseFill(
  List<List<Tile?>> grid, [
  double Function()? rng,
  int types = 6,
]) {
  final random = rng ?? _mathRandom;
  final rows = grid.length;
  final cols = grid[0].length;
  final before = <int, _Pos>{};
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      final tile = grid[r][c];
      if (tile != null) {
        before[tile.id] = _Pos(r, c, tile.gem, tile.special, tile.ice);
      }
    }
  }

  for (var c = 0; c < cols; c++) {
    var write = rows - 1;
    while (write >= 0) {
      final occupant = grid[write][c];
      if (occupant != null && occupant.ice) {
        write -= 1;
        continue;
      }

      var read = write;
      final segment = <Tile>[];
      while (read >= 0 && grid[read][c]?.ice != true) {
        final tile = grid[read][c];
        if (tile != null) segment.add(tile);
        grid[read][c] = null;
        read -= 1;
      }

      for (var i = 0; i < segment.length; i++) {
        grid[write - i][c] = segment[i];
      }

      final segTop = read + 1;
      final emptyCount = write - read - segment.length;
      for (var i = 0; i < emptyCount; i++) {
        final toR = write - segment.length - i;
        final tile = makeTile((random() * types).floor(), null, false);
        grid[toR][c] = tile;
        tile.spawnFrom = segTop - 1 - i;
      }

      write = read;
    }
  }

  final drops = <Drop>[];
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      final tile = grid[r][c];
      if (tile == null) continue;
      final prev = before[tile.id];
      if (prev == null) {
        final fromR = tile.spawnFrom ?? -1;
        tile.spawnFrom = null;
        drops.add(
          Drop(
            id: tile.id,
            gem: tile.gem,
            special: tile.special,
            ice: tile.ice,
            fromR: fromR,
            fromC: c,
            toR: r,
            toC: c,
            spawn: true,
          ),
        );
      } else if (prev.r != r || prev.c != c) {
        drops.add(
          Drop(
            id: tile.id,
            gem: tile.gem,
            special: tile.special,
            ice: tile.ice,
            fromR: prev.r,
            fromC: prev.c,
            toR: r,
            toC: c,
            spawn: false,
          ),
        );
      } else {
        tile.spawnFrom = null;
      }
    }
  }
  return drops;
}

double _mathRandom() => DateTime.now().microsecond / 1000000;

class SettleStep {
  SettleStep.clear({
    required this.removed,
    required this.spawned,
    required this.iceBroken,
    required this.points,
    required this.combo,
    required this.waves,
  }) : kind = 'clear',
       drops = const [];

  SettleStep.drop(this.drops)
    : kind = 'drop',
      removed = const [],
      spawned = const [],
      iceBroken = const [],
      points = 0,
      combo = 0,
      waves = const [];

  final String kind;
  final List<RemovedTile> removed;
  final List<SpawnedTile> spawned;
  final List<IceBreak> iceBroken;
  final int points;
  final int combo;
  final List<Wave> waves;
  final List<Drop> drops;
}

class SettleResult {
  SettleResult(this.steps, this.score, this.collected);
  final List<SettleStep> steps;
  final int score;
  final Map<int, int> collected;
}

int _adjacentIce(List<List<Tile?>> grid, Set<String> cells) {
  final uniqueIce = <String>{};
  for (final key in cells) {
    final parsed = parseKey(key);
    for (final delta in _neighbors) {
      final rr = parsed.$1 + delta.$1;
      final cc = parsed.$2 + delta.$2;
      final neighbor = at(grid, rr, cc);
      final neighborKey = keyOf(rr, cc);
      if (neighbor != null && neighbor.ice && !cells.contains(neighborKey)) {
        uniqueIce.add(neighborKey);
      }
    }
  }
  return uniqueIce.length;
}

SettleResult settle(
  List<List<Tile?>> grid, [
  double Function()? rng,
  int types = 6,
  List<String> preferKeys = const [],
  int startCombo = 0,
]) {
  final random = rng ?? _mathRandom;
  final steps = <SettleStep>[];
  final collected = <int, int>{};
  var score = 0;
  var combo = startCombo;
  var prefer = preferKeys;
  var guard = 0;

  while (guard < 40) {
    guard += 1;
    final found = findMatches(grid);
    if (found.cells.isEmpty) break;
    combo += 1;
    final spawnedPlan = planSpecials(found, prefer);
    prefer = const [];

    final origins = <String>[];
    for (final key in found.cells) {
      final parsed = parseKey(key);
      if (at(grid, parsed.$1, parsed.$2)?.special != null) origins.add(key);
    }

    final act = origins.isNotEmpty
        ? activate(grid, origins)
        : ActivateResult({...found.cells}, []);
    for (final key in found.cells) {
      act.cells.add(key);
    }

    final iceCount = _adjacentIce(grid, act.cells);
    final points = scoreValue(act.cells.length, act.waves, combo, iceCount);
    final applied = applyClear(grid, act.cells, spawnedPlan);
    _tally(collected, applied.removed);
    final drops = collapseFill(grid, random, types);
    steps.add(
      SettleStep.clear(
        removed: applied.removed,
        spawned: applied.spawnedTiles,
        iceBroken: applied.iceBroken,
        points: points,
        combo: combo,
        waves: act.waves,
      ),
    );
    steps.add(SettleStep.drop(drops));
    score += points;
  }

  return SettleResult(steps, score, collected);
}

SettleResult resolveActivation(
  List<List<Tile?>> grid,
  List<String> originKeys, [
  double Function()? rng,
  int types = 6,
  ActivateOpts opts = const ActivateOpts(),
]) {
  final random = rng ?? _mathRandom;
  final steps = <SettleStep>[];
  final collected = <int, int>{};
  var score = 0;
  final act = activate(grid, originKeys, opts);
  for (final key in originKeys) {
    act.cells.add(key);
  }

  final iceCount = _adjacentIce(grid, act.cells);
  final occupied = act.cells.where((key) {
    final parsed = parseKey(key);
    return at(grid, parsed.$1, parsed.$2) != null;
  }).length;
  final points = scoreValue(occupied, act.waves, 1, iceCount);
  final applied = applyClear(grid, act.cells, const []);
  _tally(collected, applied.removed);
  final drops = collapseFill(grid, random, types);
  steps.add(
    SettleStep.clear(
      removed: applied.removed,
      spawned: applied.spawnedTiles,
      iceBroken: applied.iceBroken,
      points: points,
      combo: 1,
      waves: act.waves,
    ),
  );
  steps.add(SettleStep.drop(drops));
  score += points;

  final tail = settle(grid, random, types, const [], 1);
  score += tail.score;
  mergeCollected(collected, tail.collected);
  steps.addAll(tail.steps);
  return SettleResult(steps, score, collected);
}

bool wouldMatch(List<List<Tile?>> grid, int r, int c, int gem) {
  final left1 = at(grid, r, c - 1);
  final left2 = at(grid, r, c - 2);
  if (left1 != null &&
      left2 != null &&
      !left1.ice &&
      !left2.ice &&
      left1.special != 'rainbow' &&
      left2.special != 'rainbow' &&
      left1.gem == gem &&
      left2.gem == gem) {
    return true;
  }
  final up1 = at(grid, r - 1, c);
  final up2 = at(grid, r - 2, c);
  if (up1 != null &&
      up2 != null &&
      !up1.ice &&
      !up2.ice &&
      up1.special != 'rainbow' &&
      up2.special != 'rainbow' &&
      up1.gem == gem &&
      up2.gem == gem) {
    return true;
  }
  return false;
}

List<List<Tile?>> createGrid(
  int rows,
  int cols,
  int types, [
  List<(int, int)> iceList = const [],
  double Function()? rng,
]) {
  final random = rng ?? _mathRandom;
  final ice = iceList.map((cell) => keyOf(cell.$1, cell.$2)).toSet();
  List<List<Tile?>>? grid;
  for (var attempt = 0; attempt < 40; attempt++) {
    grid = List.generate(rows, (_) => List<Tile?>.filled(cols, null));
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final frozen = ice.contains(keyOf(r, c));
        var gem = 0;
        for (var guard = 0; guard < 24; guard++) {
          gem = (random() * types).floor();
          if (frozen || !wouldMatch(grid, r, c, gem)) break;
        }
        grid[r][c] = makeTile(gem, null, frozen);
      }
    }
    if (findMatches(grid).cells.isEmpty && findHint(grid) != null) return grid;
  }
  return grid!;
}

void swapTiles(List<List<Tile?>> grid, int r1, int c1, int r2, int c2) {
  final tmp = grid[r1][c1];
  grid[r1][c1] = grid[r2][c2];
  grid[r2][c2] = tmp;
}

class SwapVerdict {
  const SwapVerdict({
    required this.kind,
    this.color,
    this.otherSpecial,
    this.rainbowKey,
    this.otherKey,
  });
  final String kind;
  final int? color;
  final String? otherSpecial;
  final String? rainbowKey;
  final String? otherKey;
}

SwapVerdict classifySwap(
  List<List<Tile?>> grid,
  int r1,
  int c1,
  int r2,
  int c2,
) {
  final a = at(grid, r1, c1);
  final b = at(grid, r2, c2);
  if (a == null || b == null || a.ice || b.ice) {
    return const SwapVerdict(kind: 'invalid');
  }
  final adjacent = (r1 - r2).abs() + (c1 - c2).abs() == 1;
  if (!adjacent) return const SwapVerdict(kind: 'invalid');

  if (a.special == 'rainbow' && b.special == 'rainbow') {
    return const SwapVerdict(kind: 'rainbow-all');
  }
  if (a.special == 'rainbow' || b.special == 'rainbow') {
    final rainbowIsA = a.special == 'rainbow';
    final other = rainbowIsA ? b : a;
    return SwapVerdict(
      kind: 'rainbow',
      color: other.gem,
      otherSpecial: other.special,
      rainbowKey: keyOf(rainbowIsA ? r1 : r2, rainbowIsA ? c1 : c2),
      otherKey: keyOf(rainbowIsA ? r2 : r1, rainbowIsA ? c2 : c1),
    );
  }
  if (a.special != null && b.special != null) {
    return const SwapVerdict(kind: 'combo');
  }

  swapTiles(grid, r1, c1, r2, c2);
  final found = findMatches(grid);
  swapTiles(grid, r1, c1, r2, c2);
  if (found.cells.isNotEmpty) return const SwapVerdict(kind: 'match');
  return const SwapVerdict(kind: 'invalid');
}

class Hint {
  const Hint(this.r1, this.c1, this.r2, this.c2);
  final int r1;
  final int c1;
  final int r2;
  final int c2;
}

Hint? findHint(List<List<Tile?>> grid) {
  final rows = grid.length;
  final cols = grid[0].length;
  const dirs = [(0, 1), (1, 0)];
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      for (final dir in dirs) {
        final rr = r + dir.$1;
        final cc = c + dir.$2;
        if (rr >= rows || cc >= cols) continue;
        if (classifySwap(grid, r, c, rr, cc).kind != 'invalid') {
          return Hint(r, c, rr, cc);
        }
      }
    }
  }
  return null;
}

List<String> prepareRainbowCombo(
  List<List<Tile?>> grid,
  int color,
  String? otherSpecial,
) {
  final origins = <String>[];
  var flip = false;
  for (var r = 0; r < grid.length; r++) {
    for (var c = 0; c < grid[0].length; c++) {
      final tile = grid[r][c];
      if (tile == null || tile.special == 'rainbow' || tile.gem != color) {
        continue;
      }
      if (otherSpecial == 'bomb') {
        tile.special = 'bomb';
        tile.bombRadius = 1;
      } else if (otherSpecial == 'lineH' || otherSpecial == 'lineV') {
        tile.special = flip ? 'lineV' : 'lineH';
        flip = !flip;
      }
      if (tile.special != null) origins.add(keyOf(r, c));
    }
  }
  return origins;
}

Map<int, ({int r, int c})> capturePositions(List<List<Tile?>> grid) {
  final map = <int, ({int r, int c})>{};
  for (var r = 0; r < grid.length; r++) {
    for (var c = 0; c < grid[0].length; c++) {
      final tile = grid[r][c];
      if (tile != null) map[tile.id] = (r: r, c: c);
    }
  }
  return map;
}

List<Drop> reshuffleMoves(
  List<List<Tile?>> grid,
  Map<int, ({int r, int c})> beforePositions,
) {
  final drops = <Drop>[];
  for (var r = 0; r < grid.length; r++) {
    for (var c = 0; c < grid[0].length; c++) {
      final tile = grid[r][c];
      if (tile == null || tile.ice) continue;
      final prev = beforePositions[tile.id];
      if (prev == null || prev.r != r || prev.c != c) {
        drops.add(
          Drop(
            id: tile.id,
            gem: tile.gem,
            special: tile.special,
            ice: false,
            fromR: prev?.r ?? r,
            fromC: prev?.c ?? c,
            toR: r,
            toC: c,
            spawn: false,
          ),
        );
      }
    }
  }
  return drops;
}

List<Drop> reshuffle(List<List<Tile?>> grid, [double Function()? rng]) {
  final random = rng ?? _mathRandom;
  final before = capturePositions(grid);
  final spots = <(int, int)>[];
  final pool = <Tile>[];
  for (var r = 0; r < grid.length; r++) {
    for (var c = 0; c < grid[0].length; c++) {
      final tile = grid[r][c];
      if (tile != null && !tile.ice) {
        spots.add((r, c));
        pool.add(tile);
        grid[r][c] = null;
      }
    }
  }

  void place(List<Tile> order) {
    for (var index = 0; index < spots.length; index++) {
      final spot = spots[index];
      grid[spot.$1][spot.$2] = order[index];
    }
  }

  List<Tile> shuffle(List<Tile> list) {
    final order = [...list];
    for (var i = order.length - 1; i > 0; i--) {
      final j = (random() * (i + 1)).floor();
      final tmp = order[i];
      order[i] = order[j];
      order[j] = tmp;
    }
    return order;
  }

  var last = [...pool];
  for (var attempt = 0; attempt < 50; attempt++) {
    last = shuffle(pool);
    place(last);
    if (findMatches(grid).cells.isEmpty && findHint(grid) != null) break;
  }
  return reshuffleMoves(grid, before);
}

void upgradeCombo(Tile a, Tile b) {
  bool line(Tile tile) => tile.special == 'lineH' || tile.special == 'lineV';
  if (a.special == 'bomb' && b.special == 'bomb') {
    a.bombRadius = 2;
    b.bombRadius = 2;
    return;
  }
  if ((a.special == 'bomb' && line(b)) || (b.special == 'bomb' && line(a))) {
    final stripe = line(a) ? a : b;
    final bomb = a.special == 'bomb' ? a : b;
    stripe.lineWidth = 1;
    bomb.special = stripe.special == 'lineH' ? 'lineV' : 'lineH';
    bomb.lineWidth = 1;
  }
}

bool goalsMet(
  List<({String type, int target, int? gem})> goals,
  int score,
  Map<int, int> collected,
) {
  for (final goal in goals) {
    if (goal.type == 'score') {
      if (score < goal.target) return false;
    } else if (goal.type == 'collect') {
      if ((collected[goal.gem] ?? 0) < goal.target) return false;
    } else {
      return false;
    }
  }
  return true;
}

int starCount(int score, List<int> stars) {
  var count = 0;
  if (score >= stars[0]) count = 1;
  if (score >= stars[1]) count = 2;
  if (score >= stars[2]) count = 3;
  return count;
}

Map<int, int> mergeCollected(Map<int, int> target, Map<int, int> extra) {
  for (final entry in extra.entries) {
    target[entry.key] = (target[entry.key] ?? 0) + entry.value;
  }
  return target;
}

(int, int)? randomPlainSpot(List<List<Tile?>> grid, [double Function()? rng]) {
  final random = rng ?? _mathRandom;
  final spots = <(int, int)>[];
  for (var r = 0; r < grid.length; r++) {
    for (var c = 0; c < grid[0].length; c++) {
      final tile = grid[r][c];
      if (tile != null && !tile.ice && tile.special == null) spots.add((r, c));
    }
  }
  if (spots.isEmpty) return null;
  return spots[(random() * spots.length).floor()];
}

int _s32(int n) {
  n &= 0xFFFFFFFF;
  if (n >= 0x80000000) return n - 0x100000000;
  return n;
}

int _u32(int n) => n & 0xFFFFFFFF;

int _imul(int a, int b) => _s32(_s32(a) * _s32(b));

double Function() mulberry32(int seed) {
  var a = _s32(seed);
  return () {
    a = _s32(a);
    a = _s32(a + 0x6D2B79F5);
    final mixed = _s32(a) ^ (_u32(a) >> 15);
    var t = _imul(mixed, _s32(1 | a));
    final mixed2 = _s32(t) ^ (_u32(t) >> 7);
    t = _s32(_s32(t + _imul(mixed2, _s32(61 | t))) ^ _s32(t));
    final out = _s32(t) ^ (_u32(t) >> 14);
    return (out & 0xFFFFFFFF) / 4294967296.0;
  };
}
