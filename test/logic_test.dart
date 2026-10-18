import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_grove/game/logic.dart';

List<List<Tile?>> gridFrom(List<List<int?>> rows) {
  return rows
      .map(
        (row) => row.map((gem) => gem == null ? null : makeTile(gem)).toList(),
      )
      .toList();
}

void main() {
  test('detects horizontal and vertical runs of three', () {
    resetIds();
    final grid = gridFrom([
      [0, 0, 0, 1],
      [1, 2, 1, 2],
      [2, 1, 2, 0],
      [0, 1, 0, 1],
    ]);
    final found = findMatches(grid);
    expect(found.cells.length, 3);
    expect(found.groups.length, 1);
    expect(found.groups.first.dir, 'h');

    final vertical = gridFrom([
      [0, 1],
      [0, 2],
      [0, 1],
    ]);
    final v = findMatches(vertical);
    expect(v.groups.first.dir, 'v');
    expect(v.cells.length, 3);
  });

  test('ice and short runs do not match', () {
    resetIds();
    final grid = gridFrom([
      [0, 0, 1],
      [1, 2, 0],
      [2, 1, 2],
    ]);
    grid[0][1]!.ice = true;
    expect(findMatches(grid).cells.length, 0);
  });

  test('plans stripe, rainbow, and bloom bomb', () {
    resetIds();
    final line = gridFrom([
      [0, 0, 0, 0, 1],
    ]);
    final stripe = planSpecials(findMatches(line), ['0,1']);
    expect(stripe.length, 1);
    expect(stripe.first.special, 'lineH');
    expect(stripe.first.c, 1);

    final rainbow = gridFrom([
      [2, 2, 2, 2, 2],
    ]);
    expect(planSpecials(findMatches(rainbow)).first.special, 'rainbow');

    final corner = gridFrom([
      [3, 3, 3],
      [3, 1, 2],
      [3, 2, 1],
    ]);
    final bomb = planSpecials(findMatches(corner));
    expect(bomb.length, 1);
    expect(bomb.first.special, 'bomb');
    expect(bomb.first.r, 0);
    expect(bomb.first.c, 0);
  });

  test('gravity packs a column and spawns into holes', () {
    resetIds();
    final grid = <List<Tile?>>[
      <Tile?>[makeTile(0), makeTile(1)],
      <Tile?>[makeTile(2), null],
      <Tile?>[null, makeTile(3)],
    ];
    final drops = collapseFill(grid, () => 0, 4);
    expect(grid[2][0]!.gem, 2);
    expect(grid[1][0]!.gem, 0);
    expect(grid[0][0], isNotNull);
    expect(grid[2][1]!.gem, 3);
    expect(drops.where((drop) => drop.spawn).length, 2);
  });

  test('ice stays rooted and blocks the fall', () {
    resetIds();
    final grid = <List<Tile?>>[
      <Tile?>[makeTile(0)],
      <Tile?>[makeTile(1, null, true)],
      <Tile?>[null],
    ];
    collapseFill(grid, () => 0, 3);
    expect(grid[1][0]!.ice, isTrue);
    expect(grid[1][0]!.gem, 1);
    expect(grid[2][0], isNotNull);
    expect(grid[2][0]!.id, isNot(grid[0][0]!.id));
  });

  test('settle clears a match, rewards a stripe, and refills', () {
    resetIds();
    final grid = gridFrom([
      [0, 0, 0, 0, 1],
      [1, 2, 1, 2, 0],
      [2, 1, 2, 0, 1],
      [0, 2, 0, 1, 2],
      [1, 0, 1, 2, 0],
    ]);
    final result = settle(grid, mulberry32(3), 4, ['0,2']);
    expect(result.score, greaterThan(0));
    expect(result.collected[0]! >= 4, isTrue);
    final specials = grid
        .expand((row) => row)
        .where((tile) => tile?.special != null);
    expect(
      specials.any(
        (tile) =>
            tile!.special == 'lineH' ||
            tile.special == 'lineV' ||
            tile.special == 'bomb' ||
            tile.special == 'rainbow',
      ),
      isTrue,
    );
    expect(findMatches(grid).cells.length, 0);
  });

  test('adjacent ice breaks when a match clears beside it', () {
    resetIds();
    final grid = gridFrom([
      [0, 0, 0, 1],
      [1, 2, 1, 2],
      [2, 1, 2, 0],
    ]);
    grid[1][0]!.ice = true;
    final found = findMatches(grid);
    final applied = applyClear(grid, found.cells, []);
    expect(applied.iceBroken.any((ice) => ice.r == 1 && ice.c == 0), isTrue);
    expect(grid[1][0]!.ice, isFalse);
  });

  test('stripe activation clears the row and chains', () {
    resetIds();
    final grid = gridFrom([
      [1, 1, 1, 2, 3],
      [0, 2, 3, 0, 1],
      [2, 3, 0, 1, 2],
    ]);
    grid[0][0]!.special = 'lineH';
    final act = activate(grid, ['0,0']);
    expect(act.cells.contains('0,4'), isTrue);
    expect(act.waves.first.special, 'lineH');
  });

  test('swap classification and hints', () {
    resetIds();
    final grid = gridFrom([
      [1, 0, 0, 2],
      [0, 2, 3, 1],
      [2, 3, 1, 2],
      [3, 1, 2, 3],
    ]);
    expect(classifySwap(grid, 1, 0, 0, 0).kind, 'match');
    expect(classifySwap(grid, 2, 2, 2, 3).kind, 'invalid');
    grid[1][1]!.ice = true;
    expect(classifySwap(grid, 1, 1, 1, 2).kind, 'invalid');
    expect(findHint(grid), isNotNull);
  });

  test('rainbow activation collects a single color', () {
    resetIds();
    final grid = gridFrom([
      [0, 1, 0, 1],
      [1, 0, 2, 3],
      [2, 3, 0, 1],
      [3, 1, 2, 0],
    ]);
    grid[0][0]!.special = 'rainbow';
    final doomed = grid
        .expand((row) => row)
        .where((tile) => tile != null && tile.gem == 1)
        .map((tile) => tile!.id)
        .toSet();
    final result = resolveActivation(
      grid,
      ['0,0'],
      mulberry32(1),
      4,
      const ActivateOpts(color: 1),
    );
    expect(result.collected[1]! >= doomed.length, isTrue);
    expect(
      grid
          .expand((row) => row)
          .any((tile) => tile != null && doomed.contains(tile.id)),
      isFalse,
    );
  });

  test('fresh boards have no matches and at least one move', () {
    resetIds();
    for (var seed = 1; seed <= 25; seed++) {
      final grid = createGrid(8, 7, 5, [
        (0, 0),
        (2, 3),
        (4, 1),
      ], mulberry32(seed));
      expect(findMatches(grid).cells.length, 0);
      expect(findHint(grid), isNotNull);
      expect(grid[0][0]!.ice, isTrue);
    }
  });

  test('reshuffle keeps ice rooted and restores a playable board', () {
    resetIds();
    final grid = createGrid(6, 6, 4, [(1, 1)], mulberry32(9));
    final iceId = grid[1][1]!.id;
    final drops = reshuffle(grid, mulberry32(4));
    expect(grid[1][1]!.id, iceId);
    expect(grid[1][1]!.ice, isTrue);
    expect(findMatches(grid).cells.length, 0);
    expect(findHint(grid), isNotNull);
    expect(drops, isA<List<Drop>>());
  });

  test('bomb plus stripe upgrades into a wide cross', () {
    resetIds();
    final a = makeTile(0, 'bomb');
    final b = makeTile(1, 'lineH');
    upgradeCombo(a, b);
    expect(b.lineWidth, 1);
    expect(a.special, 'lineV');
    expect(a.lineWidth, 1);
  });

  test('goals and stars', () {
    expect(
      goalsMet([(type: 'score', target: 100, gem: null)], 100, {}),
      isTrue,
    );
    expect(
      goalsMet([(type: 'collect', target: 5, gem: 2)], 0, {2: 4}),
      isFalse,
    );
    expect(starCount(2600, [1000, 2000, 3000]), 2);
    expect(starCount(400, [1000, 2000, 3000]), 0);
  });
}
