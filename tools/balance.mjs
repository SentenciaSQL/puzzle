import {
  classifySwap,
  createGrid,
  goalsMet,
  keyOf,
  mergeCollected,
  mulberry32,
  prepareRainbowCombo,
  resolveActivation,
  settle,
  swapTiles,
  upgradeCombo,
} from "../js/logic.js";
import { LEVELS } from "../js/levels.js";

function clone(grid) {
  return grid.map((row) => row.map((tile) => (tile ? { ...tile } : null)));
}

function listMoves(grid) {
  const moves = [];
  for (let r = 0; r < grid.length; r++) {
    for (let c = 0; c < grid[0].length; c++) {
      for (const [rr, cc] of [
        [r, c + 1],
        [r + 1, c],
      ]) {
        if (rr >= grid.length || cc >= grid[0].length) continue;
        if (classifySwap(grid, r, c, rr, cc).kind !== "invalid") moves.push([r, c, rr, cc]);
      }
    }
  }
  return moves;
}

function applyMove(grid, move, types, rng) {
  const [r1, c1, r2, c2] = move;
  swapTiles(grid, r1, c1, r2, c2);
  const a = grid[r1][c1];
  const b = grid[r2][c2];
  if (a.special === "rainbow" && b.special === "rainbow") {
    return resolveActivation(grid, [keyOf(r1, c1), keyOf(r2, c2)], rng, types, { color: "all" });
  }
  if (a.special === "rainbow" || b.special === "rainbow") {
    const rainbowPos = a.special === "rainbow" ? [r1, c1] : [r2, c2];
    const other = a.special === "rainbow" ? b : a;
    const origins = prepareRainbowCombo(grid, other.gem, other.special);
    origins.push(keyOf(rainbowPos[0], rainbowPos[1]));
    return resolveActivation(grid, origins, rng, types, { color: other.gem });
  }
  if (a.special && b.special) {
    upgradeCombo(a, b);
    return resolveActivation(grid, [keyOf(r1, c1), keyOf(r2, c2)], rng, types);
  }
  return settle(grid, rng, types, [keyOf(r2, c2), keyOf(r1, c1)]);
}

function utility(level, score, collected) {
  let value = score * 0.02;
  for (const goal of level.goals) {
    if (goal.type === "score") value += Math.min(score, goal.target) / goal.target;
    else value += Math.min(collected[goal.gem] || 0, goal.target) / goal.target;
  }
  return value;
}

const trials = Number(process.argv[2] || 8);
for (const level of LEVELS) {
  let wins = 0;
  for (let trial = 0; trial < trials; trial++) {
    const rng = mulberry32(4000 + level.id * 80 + trial);
    const grid = createGrid(level.rows, level.cols, level.types, level.ice, rng);
    let score = 0;
    const collected = {};
    let moves = level.moves;
    let guard = 0;
    while (moves > 0 && !goalsMet(level.goals, score, collected) && guard < 80) {
      guard += 1;
      const options = listMoves(grid);
      if (!options.length) break;
      const sample = options.length > 14 ? options.slice().sort(() => rng() - 0.5).slice(0, 14) : options;
      let best = sample[0];
      let bestU = -Infinity;
      for (const move of sample) {
        const copy = clone(grid);
        const result = applyMove(copy, move, level.types, mulberry32(trial + 3));
        const next = { ...collected };
        mergeCollected(next, result.collected);
        const value = utility(level, score + result.score, next);
        if (value > bestU) {
          bestU = value;
          best = move;
        }
      }
      const result = applyMove(grid, best, level.types, rng);
      score += result.score;
      mergeCollected(collected, result.collected);
      moves -= 1;
    }
    if (goalsMet(level.goals, score, collected)) wins += 1;
  }
  console.log(`L${String(level.id).padStart(2, " ")} ${wins}/${trials}`);
}
