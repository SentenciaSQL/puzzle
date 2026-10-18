class Chapter {
  const Chapter({
    required this.id,
    required this.en,
    required this.es,
    required this.blurbEn,
    required this.blurbEs,
  });
  final int id;
  final String en;
  final String es;
  final String blurbEn;
  final String blurbEs;

  String name(String lang) => lang == 'es' ? es : en;
  String blurb(String lang) => lang == 'es' ? blurbEs : blurbEn;
}

const chapters = [
  Chapter(
    id: 0,
    en: 'Sunlit Orchard',
    es: 'Huerto soleado',
    blurbEn: 'Warm fruit and an easy glow.',
    blurbEs: 'Fruta cálida y un brillo fácil.',
  ),
  Chapter(
    id: 1,
    en: 'Moonpetal Garden',
    es: 'Jardín lunapétulo',
    blurbEn: 'Frost creeps between the blossoms.',
    blurbEs: 'La escarcha se cuela entre las flores.',
  ),
  Chapter(
    id: 2,
    en: 'Aurora Canopy',
    es: 'Dosel aurora',
    blurbEn: 'The deep grove keeps its brightest fruit.',
    blurbEs: 'El bosque hondo guarda su fruta más viva.',
  ),
];

const gemNames = [
  ('Sunberries', 'Bayasol'),
  ('Roseplums', 'Ciruelarosa'),
  ('Mintleaves', 'Hojamenta'),
  ('Moonpearls', 'Perlaluna'),
  ('Skydews', 'Rocío'),
  ('Emberfigs', 'Higobrass'),
];

String gemName(int index, String lang) {
  final pair = gemNames[index];
  return lang == 'es' ? pair.$2 : pair.$1;
}

class Goal {
  const Goal.score(this.target) : type = 'score', gem = null;
  const Goal.collect(this.gem, this.target) : type = 'collect';
  final String type;
  final int target;
  final int? gem;
}

class LevelDef {
  const LevelDef({
    required this.id,
    required this.chapter,
    required this.rows,
    required this.cols,
    required this.types,
    required this.moves,
    required this.goals,
    required this.stars,
    this.ice = const [],
  });

  final int id;
  final int chapter;
  final int rows;
  final int cols;
  final int types;
  final int moves;
  final List<Goal> goals;
  final List<int> stars;
  final List<(int, int)> ice;
}

List<(int, int)> iceCorners(int rows, int cols) => [
  (0, 0),
  (0, cols - 1),
  (rows - 1, 0),
  (rows - 1, cols - 1),
];

List<(int, int)> iceCross(int rows, int cols) {
  final r = rows ~/ 2;
  final c = cols ~/ 2;
  return [(r, c), (r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)];
}

List<(int, int)> iceFrame(int rows, int cols) {
  final cells = <(int, int)>[];
  for (var c = 1; c < cols - 1; c += 2) {
    cells.add((0, c));
    cells.add((rows - 1, c));
  }
  for (var r = 1; r < rows - 1; r += 2) {
    cells.add((r, 0));
    cells.add((r, cols - 1));
  }
  return cells;
}

const levels = <LevelDef>[
  LevelDef(
    id: 1,
    chapter: 0,
    rows: 6,
    cols: 6,
    types: 4,
    moves: 22,
    goals: [Goal.score(1200)],
    stars: [1200, 2200, 3400],
  ),
  LevelDef(
    id: 2,
    chapter: 0,
    rows: 6,
    cols: 6,
    types: 4,
    moves: 20,
    goals: [Goal.collect(0, 16)],
    stars: [900, 1700, 2700],
  ),
  LevelDef(
    id: 3,
    chapter: 0,
    rows: 6,
    cols: 6,
    types: 4,
    moves: 22,
    goals: [Goal.collect(1, 14), Goal.collect(2, 14)],
    stars: [1100, 2000, 3100],
  ),
  LevelDef(
    id: 4,
    chapter: 0,
    rows: 6,
    cols: 6,
    types: 5,
    moves: 22,
    goals: [Goal.score(1800)],
    stars: [1800, 3000, 4400],
  ),
  LevelDef(
    id: 5,
    chapter: 0,
    rows: 7,
    cols: 7,
    types: 4,
    moves: 24,
    goals: [Goal.score(2400)],
    stars: [2400, 3800, 5400],
    ice: [(0, 0), (0, 6), (6, 0), (6, 6)],
  ),
  LevelDef(
    id: 6,
    chapter: 0,
    rows: 7,
    cols: 7,
    types: 5,
    moves: 22,
    goals: [Goal.collect(3, 18)],
    stars: [1400, 2500, 3800],
    ice: [(1, 1), (1, 5), (5, 1), (5, 5)],
  ),
  LevelDef(
    id: 7,
    chapter: 0,
    rows: 7,
    cols: 7,
    types: 5,
    moves: 24,
    goals: [Goal.score(2600), Goal.collect(0, 12)],
    stars: [2600, 4000, 5600],
    ice: [(3, 3), (2, 3), (4, 3), (3, 2), (3, 4)],
  ),
  LevelDef(
    id: 8,
    chapter: 0,
    rows: 7,
    cols: 7,
    types: 5,
    moves: 22,
    goals: [Goal.score(3200)],
    stars: [3200, 4800, 6600],
  ),
  LevelDef(
    id: 9,
    chapter: 1,
    rows: 7,
    cols: 7,
    types: 5,
    moves: 24,
    goals: [Goal.collect(4, 16), Goal.collect(1, 16)],
    stars: [1600, 2800, 4200],
  ),
  LevelDef(
    id: 10,
    chapter: 1,
    rows: 7,
    cols: 8,
    types: 5,
    moves: 24,
    goals: [Goal.score(3400)],
    stars: [3400, 5000, 7000],
    ice: [(0, 0), (0, 7), (6, 0), (6, 7)],
  ),
  LevelDef(
    id: 11,
    chapter: 1,
    rows: 8,
    cols: 7,
    types: 5,
    moves: 25,
    goals: [Goal.collect(2, 22)],
    stars: [1800, 3200, 4800],
    ice: [(0, 3), (2, 3), (4, 3), (6, 3)],
  ),
  LevelDef(
    id: 12,
    chapter: 1,
    rows: 7,
    cols: 7,
    types: 6,
    moves: 24,
    goals: [Goal.score(3000), Goal.collect(5, 12)],
    stars: [3000, 4600, 6400],
  ),
  LevelDef(
    id: 13,
    chapter: 1,
    rows: 8,
    cols: 7,
    types: 5,
    moves: 26,
    goals: [Goal.score(4200)],
    stars: [4200, 6000, 8200],
    ice: [(4, 3), (3, 3), (5, 3), (4, 2), (4, 4)],
  ),
  LevelDef(
    id: 14,
    chapter: 1,
    rows: 8,
    cols: 7,
    types: 6,
    moves: 24,
    goals: [Goal.collect(0, 16), Goal.collect(3, 16)],
    stars: [2000, 3400, 5000],
    ice: [(0, 0), (0, 6), (7, 0), (7, 6), (3, 2), (3, 4)],
  ),
  LevelDef(
    id: 15,
    chapter: 1,
    rows: 8,
    cols: 8,
    types: 5,
    moves: 26,
    goals: [Goal.score(4800)],
    stars: [4800, 6800, 9000],
  ),
  LevelDef(
    id: 16,
    chapter: 1,
    rows: 8,
    cols: 7,
    types: 6,
    moves: 25,
    goals: [Goal.score(3600), Goal.collect(4, 14)],
    stars: [3600, 5400, 7400],
    ice: [(1, 1), (1, 5), (3, 3), (5, 1), (5, 5), (6, 3)],
  ),
  LevelDef(
    id: 17,
    chapter: 2,
    rows: 8,
    cols: 7,
    types: 6,
    moves: 26,
    goals: [Goal.collect(5, 20)],
    stars: [2200, 3800, 5600],
  ),
  LevelDef(
    id: 18,
    chapter: 2,
    rows: 8,
    cols: 8,
    types: 5,
    moves: 26,
    goals: [Goal.score(5200)],
    stars: [5200, 7400, 9800],
    ice: [(4, 4), (3, 4), (5, 4), (4, 3), (4, 5)],
  ),
  LevelDef(
    id: 19,
    chapter: 2,
    rows: 8,
    cols: 7,
    types: 6,
    moves: 26,
    goals: [Goal.collect(1, 18), Goal.collect(2, 18)],
    stars: [2400, 4000, 5800],
    ice: [(0, 0), (0, 6), (7, 0), (7, 6)],
  ),
  LevelDef(
    id: 20,
    chapter: 2,
    rows: 8,
    cols: 8,
    types: 6,
    moves: 28,
    goals: [Goal.score(5600)],
    stars: [5600, 8000, 10800],
  ),
  LevelDef(
    id: 21,
    chapter: 2,
    rows: 8,
    cols: 8,
    types: 6,
    moves: 26,
    goals: [Goal.score(4000), Goal.collect(0, 14)],
    stars: [4000, 6000, 8400],
    ice: [(0, 3), (0, 4), (3, 0), (4, 0), (7, 3), (7, 4), (3, 7), (4, 7)],
  ),
  LevelDef(
    id: 22,
    chapter: 2,
    rows: 8,
    cols: 8,
    types: 6,
    moves: 28,
    goals: [Goal.collect(3, 16), Goal.collect(5, 16)],
    stars: [2600, 4400, 6400],
  ),
  LevelDef(
    id: 23,
    chapter: 2,
    rows: 8,
    cols: 8,
    types: 6,
    moves: 28,
    goals: [Goal.score(6400)],
    stars: [6400, 9000, 12000],
  ),
  LevelDef(
    id: 24,
    chapter: 2,
    rows: 8,
    cols: 8,
    types: 6,
    moves: 30,
    goals: [Goal.score(5000), Goal.collect(4, 16), Goal.collect(2, 16)],
    stars: [5000, 7600, 10400],
    ice: [(1, 1), (1, 6), (2, 3), (2, 4), (5, 3), (5, 4), (6, 1), (6, 6)],
  ),
];

LevelDef levelById(int id) =>
    levels.firstWhere((level) => level.id == id, orElse: () => levels.first);

LevelDef groveLevel(int id) => groveLevels.firstWhere(
  (level) => level.id == id,
  orElse: () => groveLevels.first,
);

// Frames are computed so they stay aligned with the JS level data.
final List<LevelDef> groveLevels = _withFrames();

List<LevelDef> _withFrames() {
  LevelDef frame(int id) {
    final level = levelById(id);
    return LevelDef(
      id: level.id,
      chapter: level.chapter,
      rows: level.rows,
      cols: level.cols,
      types: level.types,
      moves: level.moves,
      goals: level.goals,
      stars: level.stars,
      ice: iceFrame(level.rows, level.cols),
    );
  }

  LevelDef crossAndCorners(int id) {
    final level = levelById(id);
    return LevelDef(
      id: level.id,
      chapter: level.chapter,
      rows: level.rows,
      cols: level.cols,
      types: level.types,
      moves: level.moves,
      goals: level.goals,
      stars: level.stars,
      ice: [
        ...iceCross(level.rows, level.cols),
        ...iceCorners(level.rows, level.cols),
      ],
    );
  }

  return [
    for (final level in levels)
      if (level.id == 8 || level.id == 15 || level.id == 20 || level.id == 23)
        frame(level.id)
      else if (level.id == 22)
        crossAndCorners(level.id)
      else
        level,
  ];
}
