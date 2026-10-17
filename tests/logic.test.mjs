import test from "node:test";
import assert from "node:assert/strict";
import {
  activate,
  applyClear,
  classifySwap,
  collapseFill,
  createGrid,
  findHint,
  findMatches,
  goalsMet,
  makeTile,
  mulberry32,
  planSpecials,
  resetIds,
  resolveActivation,
  reshuffle,
  settle,
  starCount,
  upgradeCombo,
} from "../js/logic.js";

function gridFrom(rows) {
  return rows.map((row) => row.map((gem) => (gem == null ? null : makeTile(gem))));
}

test("detects horizontal and vertical runs of three", () => {
  resetIds();
  const grid = gridFrom([
    [0, 0, 0, 1],
    [1, 2, 1, 2],
    [2, 1, 2, 0],
    [0, 1, 0, 1],
  ]);
  const found = findMatches(grid);
  assert.equal(found.cells.size, 3);
  assert.equal(found.groups.length, 1);
  assert.equal(found.groups[0].dir, "h");

  const vertical = gridFrom([
    [0, 1],
    [0, 2],
    [0, 1],
  ]);
  const v = findMatches(vertical);
  assert.equal(v.groups[0].dir, "v");
  assert.equal(v.cells.size, 3);
});

test("ice and short runs do not match", () => {
  resetIds();
  const grid = gridFrom([
    [0, 0, 1],
    [1, 2, 0],
    [2, 1, 2],
  ]);
  grid[0][1].ice = true;
  assert.equal(findMatches(grid).cells.size, 0);
});

test("plans stripe, rainbow, and bloom bomb", () => {
  resetIds();
  const line = gridFrom([[0, 0, 0, 0, 1]]);
  const stripe = planSpecials(findMatches(line), ["0,1"]);
  assert.equal(stripe.length, 1);
  assert.equal(stripe[0].special, "lineH");
  assert.equal(stripe[0].c, 1);

  const rainbow = gridFrom([[2, 2, 2, 2, 2]]);
  assert.equal(planSpecials(findMatches(rainbow))[0].special, "rainbow");

  const corner = gridFrom([
    [3, 3, 3],
    [3, 1, 2],
    [3, 2, 1],
  ]);
  const bomb = planSpecials(findMatches(corner));
  assert.equal(bomb.length, 1);
  assert.equal(bomb[0].special, "bomb");
  assert.equal(bomb[0].r, 0);
  assert.equal(bomb[0].c, 0);
});

test("gravity packs a column and spawns into holes", () => {
  resetIds();
  const grid = [
    [makeTile(0), makeTile(1)],
    [makeTile(2), null],
    [null, makeTile(3)],
  ];
  const drops = collapseFill(grid, () => 0, 4);
  assert.equal(grid[2][0].gem, 2);
  assert.equal(grid[1][0].gem, 0);
  assert.ok(grid[0][0]);
  assert.equal(grid[2][1].gem, 3);
  assert.equal(drops.filter((drop) => drop.spawn).length, 2);
});

test("ice stays rooted and blocks the fall", () => {
  resetIds();
  const grid = [[makeTile(0)], [makeTile(1, null, true)], [null]];
  collapseFill(grid, () => 0, 3);
  assert.equal(grid[1][0].ice, true);
  assert.equal(grid[1][0].gem, 1);
  assert.ok(grid[2][0]);
  assert.notEqual(grid[2][0].id, grid[0][0].id);
});

test("settle clears a match, rewards a stripe, and refills", () => {
  resetIds();
  const grid = gridFrom([
    [0, 0, 0, 0, 1],
    [1, 2, 1, 2, 0],
    [2, 1, 2, 0, 1],
    [0, 2, 0, 1, 2],
    [1, 0, 1, 2, 0],
  ]);
  const result = settle(grid, mulberry32(3), 4, ["0,2"]);
  assert.ok(result.score > 0);
  assert.ok(result.collected[0] >= 4);
  const specials = grid.flat().filter((tile) => tile?.special);
  assert.ok(specials.some((tile) => tile.special === "lineH" || tile.special === "lineV" || tile.special === "bomb" || tile.special === "rainbow"));
  assert.equal(findMatches(grid).cells.size, 0);
});

test("adjacent ice breaks when a match clears beside it", () => {
  resetIds();
  const grid = gridFrom([
    [0, 0, 0, 1],
    [1, 2, 1, 2],
    [2, 1, 2, 0],
  ]);
  grid[1][0].ice = true;
  const found = findMatches(grid);
  const applied = applyClear(grid, found.cells, []);
  assert.ok(applied.iceBroken.some((ice) => ice.r === 1 && ice.c === 0));
  assert.equal(grid[1][0].ice, false);
});

test("stripe activation clears the row and chains", () => {
  resetIds();
  const grid = gridFrom([
    [1, 1, 1, 2, 3],
    [0, 2, 3, 0, 1],
    [2, 3, 0, 1, 2],
  ]);
  grid[0][0].special = "lineH";
  const act = activate(grid, ["0,0"]);
  assert.ok(act.cells.has("0,4"));
  assert.equal(act.waves[0].special, "lineH");
});

test("swap classification and hints", () => {
  resetIds();
  const grid = gridFrom([
    [1, 0, 0, 2],
    [0, 2, 3, 1],
    [2, 3, 1, 2],
    [3, 1, 2, 3],
  ]);
  assert.equal(classifySwap(grid, 1, 0, 0, 0).kind, "match");
  assert.equal(classifySwap(grid, 2, 2, 2, 3).kind, "invalid");
  grid[1][1].ice = true;
  assert.equal(classifySwap(grid, 1, 1, 1, 2).kind, "invalid");
  const hint = findHint(grid);
  assert.ok(hint);
});

test("rainbow activation collects a single color", () => {
  resetIds();
  const grid = gridFrom([
    [0, 1, 0, 1],
    [1, 0, 2, 3],
    [2, 3, 0, 1],
    [3, 1, 2, 0],
  ]);
  grid[0][0].special = "rainbow";
  const doomed = new Set(grid.flat().filter((tile) => tile && tile.gem === 1).map((tile) => tile.id));
  const result = resolveActivation(grid, ["0,0"], mulberry32(1), 4, { color: 1 });
  assert.ok(result.collected[1] >= doomed.size);
  assert.equal(grid.flat().some((tile) => tile && doomed.has(tile.id)), false);
});

test("fresh boards have no matches and at least one move", () => {
  resetIds();
  for (let seed = 1; seed <= 25; seed++) {
    const grid = createGrid(8, 7, 5, [[0, 0], [2, 3], [4, 1]], mulberry32(seed));
    assert.equal(findMatches(grid).cells.size, 0);
    assert.ok(findHint(grid));
    assert.equal(grid[0][0].ice, true);
  }
});

test("reshuffle keeps ice rooted and restores a playable board", () => {
  resetIds();
  const grid = createGrid(6, 6, 4, [[1, 1]], mulberry32(9));
  const iceId = grid[1][1].id;
  const drops = reshuffle(grid, mulberry32(4));
  assert.equal(grid[1][1].id, iceId);
  assert.equal(grid[1][1].ice, true);
  assert.equal(findMatches(grid).cells.size, 0);
  assert.ok(findHint(grid));
  assert.ok(Array.isArray(drops));
});

test("bomb plus stripe upgrades into a wide cross", () => {
  resetIds();
  const a = makeTile(0, "bomb");
  const b = makeTile(1, "lineH");
  upgradeCombo(a, b);
  assert.equal(b.lineWidth, 1);
  assert.equal(a.special, "lineV");
  assert.equal(a.lineWidth, 1);
});

test("goals and stars", () => {
  assert.equal(goalsMet([{ type: "score", target: 100 }], 100, {}), true);
  assert.equal(goalsMet([{ type: "collect", gem: 2, target: 5 }], 0, { 2: 4 }), false);
  assert.equal(starCount(2600, [1000, 2000, 3000]), 2);
  assert.equal(starCount(400, [1000, 2000, 3000]), 0);
});
