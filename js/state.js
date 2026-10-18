const KEY = "glimmer-grove-v1";

const DEFAULTS = {
  name: "",
  avatar: 0,
  coins: 250,
  boosters: { hammer: 2, shuffle: 1, extra: 1 },
  levels: {},
  unlocked: 1,
  sfx: true,
  music: true,
  reduced: false,
  lang: null,
  daily: "",
  tutorial: false,
};

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

export const save = load();

function load() {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return clone(DEFAULTS);
    const parsed = JSON.parse(raw);
    return {
      ...clone(DEFAULTS),
      ...parsed,
      boosters: { ...DEFAULTS.boosters, ...(parsed.boosters || {}) },
      levels: parsed.levels || {},
    };
  } catch {
    return clone(DEFAULTS);
  }
}

export function persist() {
  try {
    localStorage.setItem(KEY, JSON.stringify(save));
  } catch {
    /* Private mode can block storage; the session still plays. */
  }
}

export function todayKey() {
  const now = new Date();
  return `${now.getFullYear()}-${now.getMonth() + 1}-${now.getDate()}`;
}

export function resetSave() {
  const fresh = clone(DEFAULTS);
  fresh.lang = save.lang;
  Object.keys(save).forEach((key) => delete save[key]);
  Object.assign(save, fresh);
  persist();
}

export const PRODUCTS = [
  {
    id: "hammer",
    cost: 120,
    grant: { hammer: 1 },
    art: "hammer",
  },
  {
    id: "shuffle",
    cost: 90,
    grant: { shuffle: 1 },
    art: "shuffle",
  },
  {
    id: "extra",
    cost: 160,
    grant: { extra: 1 },
    art: "extra",
  },
  {
    id: "basket",
    cost: 280,
    grant: { hammer: 3, shuffle: 1 },
    art: "basket",
  },
];

export function coinReward(stars, firstClear) {
  const table = [0, 35, 70, 110];
  return table[stars] + (firstClear ? 45 : 0);
}

export function trySpend(cost) {
  if (save.coins < cost) return false;
  save.coins -= cost;
  persist();
  return true;
}

export function grant(items, coins = 0) {
  save.coins += coins;
  for (const [key, count] of Object.entries(items)) {
    save.boosters[key] = (save.boosters[key] || 0) + count;
  }
  persist();
}
