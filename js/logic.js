/**
 * Pure match-3 rules for Glimmer Grove.
 * Grid cells are tile objects or null. Tiles keep stable ids so the
 * renderer can animate them across cascades.
 */

let seq = 1;

export function resetIds(start = 1) {
  seq = start;
}

export function makeTile(gem, special = null, ice = false) {
  return { id: seq++, gem, special, ice, bombRadius: 1 };
}

export function keyOf(r, c) {
  return `${r},${c}`;
}

export function parseKey(key) {
  const [r, c] = key.split(",").map(Number);
  return [r, c];
}

export function inBounds(grid, r, c) {
  return r >= 0 && c >= 0 && r < grid.length && c < grid[0].length;
}

function sameRun(a, b) {
  return (
    !!a &&
    !!b &&
    !a.ice &&
    !b.ice &&
    a.special !== "rainbow" &&
    b.special !== "rainbow" &&
    a.gem === b.gem
  );
}

export function findMatches(grid) {
  const rows = grid.length;
  const cols = grid[0].length;
  const cells = new Set();
  const groups = [];

  for (let r = 0; r < rows; r++) {
    let c = 0;
    while (c < cols) {
      const start = grid[r][c];
      if (!start || start.ice || start.special === "rainbow") {
        c += 1;
        continue;
      }
      let c2 = c + 1;
      while (c2 < cols && sameRun(start, grid[r][c2])) c2 += 1;
      if (c2 - c >= 3) {
        const list = [];
        for (let k = c; k < c2; k++) {
          cells.add(keyOf(r, k));
          list.push([r, k]);
        }
        groups.push({ cells: list, dir: "h", len: list.length, gem: start.gem });
      }
      c = c2;
    }
  }

  for (let c = 0; c < cols; c++) {
    let r = 0;
    while (r < rows) {
      const start = grid[r][c];
      if (!start || start.ice || start.special === "rainbow") {
        r += 1;
        continue;
      }
      let r2 = r + 1;
      while (r2 < rows && sameRun(start, grid[r2][c])) r2 += 1;
      if (r2 - r >= 3) {
        const list = [];
        for (let k = r; k < r2; k++) {
          cells.add(keyOf(k, c));
          list.push([k, c]);
        }
        groups.push({ cells: list, dir: "v", len: list.length, gem: start.gem });
      }
      r = r2;
    }
  }

  return { cells, groups };
}

function clusterGroups(groups) {
  const parent = new Map();
  const find = (id) => {
    if (!parent.has(id)) parent.set(id, id);
    if (parent.get(id) !== id) parent.set(id, find(parent.get(id)));
    return parent.get(id);
  };
  const union = (a, b) => {
    const pa = find(a);
    const pb = find(b);
    if (pa !== pb) parent.set(pa, pb);
  };

  for (const group of groups) {
    const first = keyOf(group.cells[0][0], group.cells[0][1]);
    for (const [r, c] of group.cells) union(first, keyOf(r, c));
  }

  const map = new Map();
  for (const group of groups) {
    const root = find(keyOf(group.cells[0][0], group.cells[0][1]));
    if (!map.has(root)) map.set(root, { groups: [], cells: new Set(), gem: group.gem });
    const cluster = map.get(root);
    cluster.groups.push(group);
    for (const [r, c] of group.cells) cluster.cells.add(keyOf(r, c));
  }
  return [...map.values()];
}

function classifyCluster(cluster) {
  let maxLine = 0;
  let maxGroup = cluster.groups[0];
  for (const group of cluster.groups) {
    if (group.len > maxLine) {
      maxLine = group.len;
      maxGroup = group;
    }
  }
  const hasH = cluster.groups.some((group) => group.dir === "h");
  const hasV = cluster.groups.some((group) => group.dir === "v");
  let special = null;
  if (maxLine >= 5) special = "rainbow";
  else if (hasH && hasV && cluster.cells.size >= 5) special = "bomb";
  else if (maxLine === 4) special = maxGroup.dir === "h" ? "lineH" : "lineV";
  if (!special) return null;
  return { special, gem: cluster.gem };
}

function pickCell(cluster, preferKeys) {
  for (const key of preferKeys) {
    if (cluster.cells.has(key)) return key;
  }
  const counts = new Map();
  for (const group of cluster.groups) {
    for (const [r, c] of group.cells) {
      const key = keyOf(r, c);
      counts.set(key, (counts.get(key) || 0) + 1);
    }
  }
  let best = null;
  let bestN = 0;
  for (const [key, count] of counts) {
    if (count > bestN) {
      best = key;
      bestN = count;
    }
  }
  if (best && bestN >= 2) return best;
  const longest = cluster.groups.reduce((a, b) => (a.len >= b.len ? a : b));
  const mid = longest.cells[Math.floor((longest.cells.length - 1) / 2)];
  return keyOf(mid[0], mid[1]);
}

export function planSpecials(found, preferKeys = []) {
  const plans = [];
  for (const cluster of clusterGroups(found.groups)) {
    const spec = classifyCluster(cluster);
    if (!spec) continue;
    const [r, c] = parseKey(pickCell(cluster, preferKeys));
    plans.push({ r, c, gem: spec.gem, special: spec.special });
  }
  return plans;
}

function dominantColor(grid) {
  const counts = new Map();
  for (const row of grid) {
    for (const tile of row) {
      if (!tile || tile.special === "rainbow") continue;
      counts.set(tile.gem, (counts.get(tile.gem) || 0) + 1);
    }
  }
  let best = 0;
  let bestN = -1;
  for (const [gem, count] of counts) {
    if (count > bestN) {
      best = gem;
      bestN = count;
    }
  }
  return best;
}

function coverage(tile, r, c, rows, cols, grid, colorOverride) {
  const all = [];
  if (tile.special === "lineH") {
    const width = tile.lineWidth || 0;
    for (let rr = r - width; rr <= r + width; rr++) {
      if (rr < 0 || rr >= rows) continue;
      for (let cc = 0; cc < cols; cc++) all.push([rr, cc]);
    }
    return all;
  }
  if (tile.special === "lineV") {
    const width = tile.lineWidth || 0;
    for (let cc = c - width; cc <= c + width; cc++) {
      if (cc < 0 || cc >= cols) continue;
      for (let rr = 0; rr < rows; rr++) all.push([rr, cc]);
    }
    return all;
  }
  if (tile.special === "bomb") {
    const rad = tile.bombRadius || 1;
    for (let rr = r - rad; rr <= r + rad; rr++) {
      for (let cc = c - rad; cc <= c + rad; cc++) {
        if (rr >= 0 && cc >= 0 && rr < rows && cc < cols) all.push([rr, cc]);
      }
    }
    return all;
  }
  if (tile.special === "rainbow") {
    if (colorOverride === "all") {
      for (let rr = 0; rr < rows; rr++) {
        for (let cc = 0; cc < cols; cc++) all.push([rr, cc]);
      }
      return all;
    }
    const color = colorOverride ?? tile.rainbowColor ?? dominantColor(grid);
    for (let rr = 0; rr < rows; rr++) {
      for (let cc = 0; cc < cols; cc++) {
        const other = grid[rr][cc];
        if (!other) continue;
        if (other.special === "rainbow" || other.gem === color) all.push([rr, cc]);
      }
    }
    if (!all.length) all.push([r, c]);
    return all;
  }
  return [[r, c]];
}

export function activate(grid, originKeys, opts = {}) {
  const rows = grid.length;
  const cols = grid[0].length;
  const cells = new Set();
  const waves = [];
  const seen = new Set();
  const queue = [...originKeys];

  while (queue.length) {
    const current = queue.shift();
    if (seen.has(current)) continue;
    seen.add(current);
    const [r, c] = parseKey(current);
    const tile = grid[r]?.[c];
    if (!tile) {
      cells.add(current);
      continue;
    }
    const area = coverage(tile, r, c, rows, cols, grid, opts.color);
    if (tile.special) {
      waves.push({
        special: tile.special,
        r,
        c,
        gem: tile.gem,
        wide: (tile.lineWidth || 0) > 0 || (tile.bombRadius || 1) > 1,
      });
    }
    for (const [rr, cc] of area) {
      const next = keyOf(rr, cc);
      cells.add(next);
      const other = grid[rr][cc];
      if (other?.special && !seen.has(next)) queue.push(next);
    }
  }

  return { cells, waves };
}

export function scoreValue(removedCount, waves, combo, iceCount) {
  let score = removedCount * 50 * combo + iceCount * 40 * combo;
  for (const wave of waves) {
    if (wave.special === "lineH" || wave.special === "lineV") score += 140 * combo;
    else if (wave.special === "bomb") score += 280 * combo;
    else if (wave.special === "rainbow") score += 460 * combo;
  }
  return score;
}

function tally(collected, removed) {
  for (const tile of removed) {
    if (tile.gem == null || tile.gem < 0) continue;
    collected[tile.gem] = (collected[tile.gem] || 0) + 1;
  }
}

export function applyClear(grid, cellKeys, spawned = []) {
  const removed = [];
  const iceBroken = [];
  const rows = grid.length;
  const cols = grid[0].length;
  const neighbors = [
    [1, 0],
    [-1, 0],
    [0, 1],
    [0, -1],
  ];
  const seenIce = new Set();

  for (const key of cellKeys) {
    const [r, c] = parseKey(key);
    const tile = grid[r]?.[c];
    if (!tile) continue;
    removed.push({ id: tile.id, gem: tile.gem, special: tile.special, ice: tile.ice, r, c });
    for (const [dr, dc] of neighbors) {
      const rr = r + dr;
      const cc = c + dc;
      if (!inBounds(grid, rr, cc)) continue;
      const nextKey = keyOf(rr, cc);
      const neighbor = grid[rr][cc];
      if (neighbor?.ice && !cellKeys.has(nextKey) && !seenIce.has(nextKey)) {
        seenIce.add(nextKey);
        iceBroken.push({ id: neighbor.id, r: rr, c: cc });
      }
    }
  }

  for (const key of cellKeys) {
    const [r, c] = parseKey(key);
    if (inBounds(grid, r, c)) grid[r][c] = null;
  }
  for (const broken of iceBroken) grid[broken.r][broken.c].ice = false;

  const spawnedTiles = [];
  for (const plan of spawned) {
    if (!inBounds(grid, plan.r, plan.c)) continue;
    const tile = makeTile(plan.gem, plan.special, false);
    if (plan.special === "rainbow") tile.rainbowColor = plan.gem;
    grid[plan.r][plan.c] = tile;
    spawnedTiles.push({
      id: tile.id,
      gem: tile.gem,
      special: tile.special,
      ice: false,
      r: plan.r,
      c: plan.c,
    });
  }

  return { removed, iceBroken, spawnedTiles };
}

export function collapseFill(grid, rng = Math.random, types = 6) {
  const rows = grid.length;
  const cols = grid[0].length;
  const before = new Map();
  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      const tile = grid[r][c];
      if (tile) before.set(tile.id, { r, c, gem: tile.gem, special: tile.special, ice: tile.ice });
    }
  }

  for (let c = 0; c < cols; c++) {
    let write = rows - 1;
    while (write >= 0) {
      const occupant = grid[write][c];
      if (occupant?.ice) {
        write -= 1;
        continue;
      }

      let read = write;
      const segment = [];
      while (read >= 0 && !(grid[read][c]?.ice)) {
        if (grid[read][c]) segment.push(grid[read][c]);
        grid[read][c] = null;
        read -= 1;
      }

      for (let i = 0; i < segment.length; i++) grid[write - i][c] = segment[i];

      const segTop = read + 1;
      const emptyCount = write - read - segment.length;
      for (let i = 0; i < emptyCount; i++) {
        const toR = write - segment.length - i;
        const tile = makeTile(Math.floor(rng() * types), null, false);
        grid[toR][c] = tile;
        tile._spawnFrom = segTop - 1 - i;
      }

      write = read;
    }
  }

  const drops = [];
  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      const tile = grid[r][c];
      if (!tile) continue;
      const prev = before.get(tile.id);
      if (!prev) {
        const fromR = tile._spawnFrom ?? -1;
        delete tile._spawnFrom;
        drops.push({
          id: tile.id,
          gem: tile.gem,
          special: tile.special,
          ice: tile.ice,
          fromR,
          fromC: c,
          toR: r,
          toC: c,
          spawn: true,
        });
      } else if (prev.r !== r || prev.c !== c) {
        drops.push({
          id: tile.id,
          gem: tile.gem,
          special: tile.special,
          ice: tile.ice,
          fromR: prev.r,
          fromC: prev.c,
          toR: r,
          toC: c,
          spawn: false,
        });
      } else {
        delete tile._spawnFrom;
      }
    }
  }
  return drops;
}

export function settle(grid, rng = Math.random, types = 6, preferKeys = [], startCombo = 0) {
  const steps = [];
  const collected = {};
  let score = 0;
  let combo = startCombo;
  let guard = 0;

  while (guard < 40) {
    guard += 1;
    const found = findMatches(grid);
    if (!found.cells.size) break;
    combo += 1;
    const spawnedPlan = planSpecials(found, preferKeys);
    preferKeys = [];

    const origins = [];
    for (const key of found.cells) {
      const [r, c] = parseKey(key);
      if (grid[r][c]?.special) origins.push(key);
    }

    const act = origins.length
      ? activate(grid, origins)
      : { cells: new Set(found.cells), waves: [] };
    for (const key of found.cells) act.cells.add(key);

    const uniqueIce = new Set();
    for (const key of act.cells) {
      const [r, c] = parseKey(key);
      for (const [dr, dc] of [
        [1, 0],
        [-1, 0],
        [0, 1],
        [0, -1],
      ]) {
        const rr = r + dr;
        const cc = c + dc;
        const neighbor = grid[rr]?.[cc];
        const neighborKey = keyOf(rr, cc);
        if (neighbor?.ice && !act.cells.has(neighborKey)) uniqueIce.add(neighborKey);
      }
    }

    const points = scoreValue(act.cells.size, act.waves, combo, uniqueIce.size);
    const applied = applyClear(grid, act.cells, spawnedPlan);
    tally(collected, applied.removed);
    const drops = collapseFill(grid, rng, types);
    steps.push({
      kind: "clear",
      removed: applied.removed,
      spawned: applied.spawnedTiles,
      iceBroken: applied.iceBroken,
      points,
      combo,
      waves: act.waves,
    });
    steps.push({ kind: "drop", drops });
    score += points;
  }

  return { steps, score, collected };
}

export function resolveActivation(grid, originKeys, rng = Math.random, types = 6, opts = {}) {
  const steps = [];
  const collected = {};
  let score = 0;
  const act = activate(grid, originKeys, opts);
  for (const key of originKeys) act.cells.add(key);

  const uniqueIce = new Set();
  for (const key of act.cells) {
    const [r, c] = parseKey(key);
    for (const [dr, dc] of [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1],
    ]) {
      const rr = r + dr;
      const cc = c + dc;
      const neighbor = grid[rr]?.[cc];
      const neighborKey = keyOf(rr, cc);
      if (neighbor?.ice && !act.cells.has(neighborKey)) uniqueIce.add(neighborKey);
    }
  }

  const points = scoreValue([...act.cells].filter((key) => {
    const [r, c] = parseKey(key);
    return !!grid[r]?.[c];
  }).length, act.waves, 1, uniqueIce.size);

  const applied = applyClear(grid, act.cells, []);
  tally(collected, applied.removed);
  const drops = collapseFill(grid, rng, types);
  steps.push({
    kind: "clear",
    removed: applied.removed,
    spawned: applied.spawnedTiles,
    iceBroken: applied.iceBroken,
    points,
    combo: 1,
    waves: act.waves,
  });
  steps.push({ kind: "drop", drops });
  score += points;

  const tail = settle(grid, rng, types, [], 1);
  score += tail.score;
  for (const [gem, count] of Object.entries(tail.collected)) {
    collected[gem] = (collected[gem] || 0) + count;
  }
  steps.push(...tail.steps);
  return { steps, score, collected };
}

export function wouldMatch(grid, r, c, gem) {
  const left1 = grid[r]?.[c - 1];
  const left2 = grid[r]?.[c - 2];
  if (
    left1 &&
    left2 &&
    !left1.ice &&
    !left2.ice &&
    left1.special !== "rainbow" &&
    left2.special !== "rainbow" &&
    left1.gem === gem &&
    left2.gem === gem
  ) {
    return true;
  }
  const up1 = grid[r - 1]?.[c];
  const up2 = grid[r - 2]?.[c];
  if (
    up1 &&
    up2 &&
    !up1.ice &&
    !up2.ice &&
    up1.special !== "rainbow" &&
    up2.special !== "rainbow" &&
    up1.gem === gem &&
    up2.gem === gem
  ) {
    return true;
  }
  return false;
}

export function createGrid(rows, cols, types, iceList = [], rng = Math.random) {
  const ice = new Set(iceList.map(([r, c]) => keyOf(r, c)));
  let grid = null;
  for (let attempt = 0; attempt < 40; attempt++) {
    grid = Array.from({ length: rows }, () => Array(cols).fill(null));
    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        const frozen = ice.has(keyOf(r, c));
        let gem = 0;
        for (let guard = 0; guard < 24; guard++) {
          gem = Math.floor(rng() * types);
          if (frozen || !wouldMatch(grid, r, c, gem)) break;
        }
        grid[r][c] = makeTile(gem, null, frozen);
      }
    }
    if (!findMatches(grid).cells.size && findHint(grid)) return grid;
  }
  return grid;
}

export function swapTiles(grid, r1, c1, r2, c2) {
  const tmp = grid[r1][c1];
  grid[r1][c1] = grid[r2][c2];
  grid[r2][c2] = tmp;
}

export function classifySwap(grid, r1, c1, r2, c2) {
  const a = grid[r1]?.[c1];
  const b = grid[r2]?.[c2];
  if (!a || !b || a.ice || b.ice) return { kind: "invalid" };
  const adjacent = Math.abs(r1 - r2) + Math.abs(c1 - c2) === 1;
  if (!adjacent) return { kind: "invalid" };

  if (a.special === "rainbow" && b.special === "rainbow") return { kind: "rainbow-all" };
  if (a.special === "rainbow" || b.special === "rainbow") {
    const rainbowIsA = a.special === "rainbow";
    const other = rainbowIsA ? b : a;
    return {
      kind: "rainbow",
      color: other.gem,
      otherSpecial: other.special,
      rainbowKey: keyOf(rainbowIsA ? r1 : r2, rainbowIsA ? c1 : c2),
      otherKey: keyOf(rainbowIsA ? r2 : r1, rainbowIsA ? c2 : c1),
    };
  }
  if (a.special && b.special) return { kind: "combo" };

  swapTiles(grid, r1, c1, r2, c2);
  const found = findMatches(grid);
  swapTiles(grid, r1, c1, r2, c2);
  if (found.cells.size) return { kind: "match" };
  return { kind: "invalid" };
}

export function findHint(grid) {
  const rows = grid.length;
  const cols = grid[0].length;
  const dirs = [
    [0, 1],
    [1, 0],
  ];
  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      for (const [dr, dc] of dirs) {
        const rr = r + dr;
        const cc = c + dc;
        if (rr >= rows || cc >= cols) continue;
        const kind = classifySwap(grid, r, c, rr, cc).kind;
        if (kind !== "invalid") return { r1: r, c1: c, r2: rr, c2: cc };
      }
    }
  }
  return null;
}

export function prepareRainbowCombo(grid, color, otherSpecial) {
  const origins = [];
  let flip = false;
  for (let r = 0; r < grid.length; r++) {
    for (let c = 0; c < grid[0].length; c++) {
      const tile = grid[r][c];
      if (!tile || tile.special === "rainbow" || tile.gem !== color) continue;
      if (otherSpecial === "bomb") {
        tile.special = "bomb";
        tile.bombRadius = 1;
      } else if (otherSpecial === "lineH" || otherSpecial === "lineV") {
        tile.special = flip ? "lineV" : "lineH";
        flip = !flip;
      }
      if (tile.special) origins.push(keyOf(r, c));
    }
  }
  return origins;
}

export function reshuffle(grid, rng = Math.random) {
  const before = capturePositions(grid);
  const spots = [];
  const pool = [];
  for (let r = 0; r < grid.length; r++) {
    for (let c = 0; c < grid[0].length; c++) {
      const tile = grid[r][c];
      if (tile && !tile.ice) {
        spots.push([r, c]);
        pool.push(tile);
        grid[r][c] = null;
      }
    }
  }

  const place = (order) => {
    spots.forEach(([r, c], index) => {
      grid[r][c] = order[index];
    });
  };

  const shuffle = (list) => {
    const order = list.slice();
    for (let i = order.length - 1; i > 0; i--) {
      const j = Math.floor(rng() * (i + 1));
      [order[i], order[j]] = [order[j], order[i]];
    }
    return order;
  };

  let last = pool.slice();
  for (let attempt = 0; attempt < 50; attempt++) {
    last = shuffle(pool);
    place(last);
    if (!findMatches(grid).cells.size && findHint(grid)) break;
  }
  return reshuffleMoves(grid, before);
}

export function upgradeCombo(a, b) {
  const line = (tile) => tile.special === "lineH" || tile.special === "lineV";
  if (a.special === "bomb" && b.special === "bomb") {
    a.bombRadius = 2;
    b.bombRadius = 2;
    return;
  }
  if ((a.special === "bomb" && line(b)) || (b.special === "bomb" && line(a))) {
    const stripe = line(a) ? a : b;
    const bomb = a.special === "bomb" ? a : b;
    stripe.lineWidth = 1;
    bomb.special = stripe.special === "lineH" ? "lineV" : "lineH";
    bomb.lineWidth = 1;
  }
}

export function reshuffleMoves(grid, beforePositions) {
  const drops = [];
  for (let r = 0; r < grid.length; r++) {
    for (let c = 0; c < grid[0].length; c++) {
      const tile = grid[r][c];
      if (!tile || tile.ice) continue;
      const prev = beforePositions.get(tile.id);
      if (!prev || prev.r !== r || prev.c !== c) {
        drops.push({
          id: tile.id,
          gem: tile.gem,
          special: tile.special,
          ice: false,
          fromR: prev ? prev.r : r,
          fromC: prev ? prev.c : c,
          toR: r,
          toC: c,
          spawn: false,
        });
      }
    }
  }
  return drops;
}

export function capturePositions(grid) {
  const map = new Map();
  for (let r = 0; r < grid.length; r++) {
    for (let c = 0; c < grid[0].length; c++) {
      const tile = grid[r][c];
      if (tile) map.set(tile.id, { r, c });
    }
  }
  return map;
}

export function goalsMet(goals, score, collected) {
  return goals.every((goal) => {
    if (goal.type === "score") return score >= goal.target;
    if (goal.type === "collect") return (collected[goal.gem] || 0) >= goal.target;
    return false;
  });
}

export function starCount(score, stars) {
  let count = 0;
  if (score >= stars[0]) count = 1;
  if (score >= stars[1]) count = 2;
  if (score >= stars[2]) count = 3;
  return count;
}

export function mergeCollected(target, extra) {
  for (const [gem, count] of Object.entries(extra)) {
    const index = Number(gem);
    target[index] = (target[index] || 0) + count;
  }
  return target;
}

export function randomPlainSpot(grid, rng = Math.random) {
  const spots = [];
  for (let r = 0; r < grid.length; r++) {
    for (let c = 0; c < grid[0].length; c++) {
      const tile = grid[r][c];
      if (tile && !tile.ice && !tile.special) spots.push([r, c]);
    }
  }
  if (!spots.length) return null;
  return spots[Math.floor(rng() * spots.length)];
}

export function mulberry32(seed) {
  let a = seed >>> 0;
  return () => {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
