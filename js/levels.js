export const CHAPTERS = [
  {
    id: 0,
    name: { en: "Sunlit Orchard", es: "Huerto soleado" },
    blurb: {
      en: "Warm fruit and an easy glow.",
      es: "Fruta cálida y un brillo fácil.",
    },
  },
  {
    id: 1,
    name: { en: "Moonpetal Garden", es: "Jardín lunapétulo" },
    blurb: {
      en: "Frost creeps between the blossoms.",
      es: "La escarcha se cuela entre las flores.",
    },
  },
  {
    id: 2,
    name: { en: "Aurora Canopy", es: "Dosel aurora" },
    blurb: {
      en: "The deep grove keeps its brightest fruit.",
      es: "El bosque hondo guarda su fruta más viva.",
    },
  },
];

const GEM_NAMES = [
  { en: "Sunberries", es: "Bayasol" },
  { en: "Roseplums", es: "Ciruelarosa" },
  { en: "Mintleaves", es: "Hojamenta" },
  { en: "Moonpearls", es: "Perlaluna" },
  { en: "Skydews", es: "Rocío" },
  { en: "Emberfigs", es: "Higobrass" },
];

export function gemName(index, lang) {
  return GEM_NAMES[index][lang] || GEM_NAMES[index].en;
}

export const GEM_COUNT = GEM_NAMES.length;

function iceCorners(rows, cols) {
  return [
    [0, 0],
    [0, cols - 1],
    [rows - 1, 0],
    [rows - 1, cols - 1],
  ];
}

function iceCross(rows, cols) {
  const r = Math.floor(rows / 2);
  const c = Math.floor(cols / 2);
  return [
    [r, c],
    [r - 1, c],
    [r + 1, c],
    [r, c - 1],
    [r, c + 1],
  ];
}

function iceFrame(rows, cols) {
  const cells = [];
  for (let c = 1; c < cols - 1; c += 2) {
    cells.push([0, c], [rows - 1, c]);
  }
  for (let r = 1; r < rows - 1; r += 2) {
    cells.push([r, 0], [r, cols - 1]);
  }
  return cells;
}

function level(partial) {
  return {
    rows: 7,
    cols: 7,
    types: 5,
    ice: [],
    ...partial,
  };
}

export const LEVELS = [
  level({
    id: 1,
    chapter: 0,
    rows: 6,
    cols: 6,
    types: 4,
    moves: 22,
    goals: [{ type: "score", target: 1200 }],
    stars: [1200, 2200, 3400],
  }),
  level({
    id: 2,
    chapter: 0,
    rows: 6,
    cols: 6,
    types: 4,
    moves: 20,
    goals: [{ type: "collect", gem: 0, target: 16 }],
    stars: [900, 1700, 2700],
  }),
  level({
    id: 3,
    chapter: 0,
    rows: 6,
    cols: 6,
    types: 4,
    moves: 22,
    goals: [
      { type: "collect", gem: 1, target: 14 },
      { type: "collect", gem: 2, target: 14 },
    ],
    stars: [1100, 2000, 3100],
  }),
  level({
    id: 4,
    chapter: 0,
    rows: 6,
    cols: 6,
    types: 5,
    moves: 22,
    goals: [{ type: "score", target: 1800 }],
    stars: [1800, 3000, 4400],
  }),
  level({
    id: 5,
    chapter: 0,
    rows: 7,
    cols: 7,
    types: 4,
    moves: 24,
    goals: [{ type: "score", target: 2400 }],
    stars: [2400, 3800, 5400],
    ice: iceCorners(7, 7),
  }),
  level({
    id: 6,
    chapter: 0,
    rows: 7,
    cols: 7,
    types: 5,
    moves: 22,
    goals: [{ type: "collect", gem: 3, target: 18 }],
    stars: [1400, 2500, 3800],
    ice: [
      [1, 1],
      [1, 5],
      [5, 1],
      [5, 5],
    ],
  }),
  level({
    id: 7,
    chapter: 0,
    rows: 7,
    cols: 7,
    types: 5,
    moves: 24,
    goals: [
      { type: "score", target: 2600 },
      { type: "collect", gem: 0, target: 12 },
    ],
    stars: [2600, 4000, 5600],
    ice: iceCross(7, 7),
  }),
  level({
    id: 8,
    chapter: 0,
    rows: 7,
    cols: 7,
    types: 5,
    moves: 22,
    goals: [{ type: "score", target: 3200 }],
    stars: [3200, 4800, 6600],
    ice: iceFrame(7, 7),
  }),
  level({
    id: 9,
    chapter: 1,
    rows: 7,
    cols: 7,
    types: 5,
    moves: 24,
    goals: [
      { type: "collect", gem: 4, target: 16 },
      { type: "collect", gem: 1, target: 16 },
    ],
    stars: [1600, 2800, 4200],
  }),
  level({
    id: 10,
    chapter: 1,
    rows: 7,
    cols: 8,
    types: 5,
    moves: 24,
    goals: [{ type: "score", target: 3400 }],
    stars: [3400, 5000, 7000],
    ice: iceCorners(7, 8),
  }),
  level({
    id: 11,
    chapter: 1,
    rows: 8,
    cols: 7,
    types: 5,
    moves: 25,
    goals: [{ type: "collect", gem: 2, target: 22 }],
    stars: [1800, 3200, 4800],
    ice: [
      [0, 3],
      [2, 3],
      [4, 3],
      [6, 3],
    ],
  }),
  level({
    id: 12,
    chapter: 1,
    rows: 7,
    cols: 7,
    types: 6,
    moves: 24,
    goals: [
      { type: "score", target: 3000 },
      { type: "collect", gem: 5, target: 12 },
    ],
    stars: [3000, 4600, 6400],
  }),
  level({
    id: 13,
    chapter: 1,
    rows: 8,
    cols: 7,
    types: 5,
    moves: 26,
    goals: [{ type: "score", target: 4200 }],
    stars: [4200, 6000, 8200],
    ice: iceCross(8, 7),
  }),
  level({
    id: 14,
    chapter: 1,
    rows: 8,
    cols: 7,
    types: 6,
    moves: 24,
    goals: [
      { type: "collect", gem: 0, target: 16 },
      { type: "collect", gem: 3, target: 16 },
    ],
    stars: [2000, 3400, 5000],
    ice: iceCorners(8, 7).concat([
      [3, 2],
      [3, 4],
    ]),
  }),
  level({
    id: 15,
    chapter: 1,
    rows: 8,
    cols: 8,
    types: 5,
    moves: 26,
    goals: [{ type: "score", target: 4800 }],
    stars: [4800, 6800, 9000],
    ice: iceFrame(8, 8),
  }),
  level({
    id: 16,
    chapter: 1,
    rows: 8,
    cols: 7,
    types: 6,
    moves: 25,
    goals: [
      { type: "score", target: 3600 },
      { type: "collect", gem: 4, target: 14 },
    ],
    stars: [3600, 5400, 7400],
    ice: [
      [1, 1],
      [1, 5],
      [3, 3],
      [5, 1],
      [5, 5],
      [6, 3],
    ],
  }),
  level({
    id: 17,
    chapter: 2,
    rows: 8,
    cols: 7,
    types: 6,
    moves: 26,
    goals: [{ type: "collect", gem: 5, target: 20 }],
    stars: [2200, 3800, 5600],
  }),
  level({
    id: 18,
    chapter: 2,
    rows: 8,
    cols: 8,
    types: 5,
    moves: 26,
    goals: [{ type: "score", target: 5200 }],
    stars: [5200, 7400, 9800],
    ice: iceCross(8, 8),
  }),
  level({
    id: 19,
    chapter: 2,
    rows: 8,
    cols: 7,
    types: 6,
    moves: 26,
    goals: [
      { type: "collect", gem: 1, target: 18 },
      { type: "collect", gem: 2, target: 18 },
    ],
    stars: [2400, 4000, 5800],
    ice: iceCorners(8, 7),
  }),
  level({
    id: 20,
    chapter: 2,
    rows: 8,
    cols: 8,
    types: 6,
    moves: 28,
    goals: [{ type: "score", target: 5600 }],
    stars: [5600, 8000, 10800],
    ice: iceFrame(8, 8),
  }),
  level({
    id: 21,
    chapter: 2,
    rows: 8,
    cols: 8,
    types: 6,
    moves: 26,
    goals: [
      { type: "score", target: 4000 },
      { type: "collect", gem: 0, target: 14 },
    ],
    stars: [4000, 6000, 8400],
    ice: [
      [0, 3],
      [0, 4],
      [3, 0],
      [4, 0],
      [7, 3],
      [7, 4],
      [3, 7],
      [4, 7],
    ],
  }),
  level({
    id: 22,
    chapter: 2,
    rows: 8,
    cols: 8,
    types: 6,
    moves: 28,
    goals: [
      { type: "collect", gem: 3, target: 16 },
      { type: "collect", gem: 5, target: 16 },
    ],
    stars: [2600, 4400, 6400],
    ice: iceCross(8, 8).concat(iceCorners(8, 8)),
  }),
  level({
    id: 23,
    chapter: 2,
    rows: 8,
    cols: 8,
    types: 6,
    moves: 28,
    goals: [{ type: "score", target: 6400 }],
    stars: [6400, 9000, 12000],
    ice: iceFrame(8, 8),
  }),
  level({
    id: 24,
    chapter: 2,
    rows: 8,
    cols: 8,
    types: 6,
    moves: 30,
    goals: [
      { type: "score", target: 5000 },
      { type: "collect", gem: 4, target: 16 },
      { type: "collect", gem: 2, target: 16 },
    ],
    stars: [5000, 7600, 10400],
    ice: [
      [1, 1],
      [1, 6],
      [2, 3],
      [2, 4],
      [5, 3],
      [5, 4],
      [6, 1],
      [6, 6],
    ],
  }),
];

export function levelById(id) {
  return LEVELS.find((entry) => entry.id === id) || LEVELS[0];
}
