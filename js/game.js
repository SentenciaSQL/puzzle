import {
  classifySwap,
  createGrid,
  goalsMet,
  keyOf,
  mulberry32,
  prepareRainbowCombo,
  randomPlainSpot,
  resolveActivation,
  reshuffle,
  settle,
  starCount,
  swapTiles,
  upgradeCombo,
} from "./logic.js";
import { GEM_COLORS, paintIce, paintRing, paintTray, sprite, warmShadow } from "./sprites.js";

const easeInOut = (t) => (t < 0.5 ? 2 * t * t : 1 - ((-2 * t + 2) ** 2) / 2);
const easeOutBack = (t) => {
  const c1 = 1.55;
  const c3 = c1 + 1;
  return 1 + c3 * (t - 1) ** 3 + c1 * (t - 1) ** 2;
};
const easeFall = (t) => {
  if (t < 0.84) return (t / 0.84) ** 2;
  const u = (t - 0.84) / 0.16;
  return 1 + Math.sin(u * Math.PI) * 0.05 * (1 - u);
};

export function createGame(canvas, hooks) {
  const ctx = canvas.getContext("2d");
  const game = {
    canvas,
    ctx,
    hooks,
    grid: null,
    level: null,
    pieces: new Map(),
    motions: [],
    particles: [],
    floaters: [],
    fx: [],
    score: 0,
    moves: 0,
    collected: {},
    epoch: 0,
    time: 0,
    busy: false,
    over: null,
    aim: null,
    selected: null,
    hint: null,
    idle: 0,
    layout: null,
    reduced: false,
    visible: false,
    rng: Math.random,
    drag: null,
    shake: 0,
    goalFlags: [],

    load(level, seed = Date.now() % 100000) {
      this.epoch += 1;
      this.motions = [];
      this.particles = [];
      this.floaters = [];
      this.fx = [];
      this.level = level;
      this.rng = mulberry32(seed);
      this.grid = createGrid(level.rows, level.cols, level.types, level.ice, this.rng);
      this.score = 0;
      this.moves = level.moves;
      this.collected = {};
      this.over = null;
      this.aim = null;
      this.selected = null;
      this.hint = null;
      this.idle = 0;
      this.busy = true;
      this.goalFlags = level.goals.map(() => false);
      this.resize();
      this.syncPieces(false);
      this.hooks.onReady?.(this.snapshot());
      const epoch = this.epoch;
      this.intro().then(() => {
        if (epoch === this.epoch) this.busy = false;
      });
    },

    snapshot() {
      return {
        score: this.score,
        moves: this.moves,
        collected: { ...this.collected },
        goals: this.level?.goals || [],
        level: this.level,
        busy: this.busy,
        over: this.over,
        aim: this.aim,
      };
    },

    setReduced(value) {
      this.reduced = value;
    },

    suspend() {
      this.epoch += 1;
      this.motions = [];
      this.busy = false;
      this.drag = null;
      this.aim = null;
      this.visible = false;
    },

    resize() {
      if (!this.grid) return;
      const stage = this.canvas.parentElement.getBoundingClientRect();
      const cols = this.grid[0].length;
      const rows = this.grid.length;
      const frameRatio = 0.18;
      const maxCell = stage.width >= 1100 ? 74 : 86;
      const availW = Math.max(120, stage.width - 4);
      const availH = Math.max(120, stage.height - 4);
      let cell = Math.floor(
        Math.min(availW / (cols + frameRatio * 2), availH / (rows + frameRatio * 2)),
      );
      cell = Math.max(30, Math.min(maxCell, cell));
      const frame = Math.max(12, Math.round(cell * frameRatio));
      const width = cols * cell + frame * 2;
      const height = rows * cell + frame * 2;
      const dpr = Math.min(2, window.devicePixelRatio || 1);
      this.canvas.style.width = `${width}px`;
      this.canvas.style.height = `${height}px`;
      this.canvas.width = Math.round(width * dpr);
      this.canvas.height = Math.round(height * dpr);
      this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      this.layout = { width, height, frame, cell, cols, rows, dpr };
    },

    cellCenter(r, c) {
      const { frame, cell } = this.layout;
      return {
        x: frame + c * cell + cell / 2,
        y: frame + r * cell + cell / 2,
      };
    },

    syncPieces() {
      this.pieces.clear();
      for (let r = 0; r < this.grid.length; r++) {
        for (let c = 0; c < this.grid[0].length; c++) {
          const tile = this.grid[r][c];
          if (!tile) continue;
          this.pieces.set(tile.id, {
            id: tile.id,
            gem: tile.gem,
            special: tile.special,
            ice: tile.ice,
            frost: tile.ice ? 1 : 0,
            r,
            c,
            scale: 1,
            alpha: 1,
          });
        }
      }
    },

    reconcile() {
      const live = new Set();
      for (let r = 0; r < this.grid.length; r++) {
        for (let c = 0; c < this.grid[0].length; c++) {
          const tile = this.grid[r][c];
          if (!tile) continue;
          live.add(tile.id);
          let piece = this.pieces.get(tile.id);
          if (!piece) {
            piece = { id: tile.id, scale: 1, alpha: 1, frost: 0 };
            this.pieces.set(tile.id, piece);
          }
          piece.gem = tile.gem;
          piece.special = tile.special;
          piece.ice = tile.ice;
          piece.r = r;
          piece.c = c;
          piece.scale = 1;
          piece.alpha = 1;
          if (!tile.ice) piece.frost = 0;
        }
      }
      for (const id of [...this.pieces.keys()]) {
        if (!live.has(id)) this.pieces.delete(id);
      }
    },

    motion(duration, update, ease = easeInOut) {
      const epoch = this.epoch;
      const safe = this.reduced ? Math.min(duration, 90) : duration;
      return new Promise((resolve) => {
        this.motions.push({
          start: this.time,
          duration: Math.max(16, safe),
          update,
          ease,
          epoch,
          resolve,
        });
      });
    },

    async intro() {
      const epoch = this.epoch;
      const items = [...this.pieces.values()].map((piece) => {
        const to = piece.r;
        const from = to - 3.1 - (piece.c % 3) * 0.15;
        piece.r = from;
        piece.alpha = 0;
        return { piece, from, to };
      });
      await this.motion(this.reduced ? 90 : 640, (t) => {
        const e = easeFall(t);
        for (const item of items) {
          item.piece.r = item.from + (item.to - item.from) * e;
          item.piece.alpha = Math.min(1, t * 1.4);
        }
      }, (t) => t);
      if (epoch !== this.epoch) return;
      for (const item of items) {
        item.piece.r = item.to;
        item.piece.alpha = 1;
      }
    },

    update(dt) {
      this.time += dt;
      for (let i = this.motions.length - 1; i >= 0; i--) {
        const motion = this.motions[i];
        if (motion.epoch !== this.epoch) {
          this.motions.splice(i, 1);
          motion.resolve();
          continue;
        }
        const t = Math.min(1, (this.time - motion.start) / motion.duration);
        motion.update(motion.ease(t), t);
        if (t >= 1) {
          this.motions.splice(i, 1);
          motion.resolve();
        }
      }
      if (!this.busy && !this.over && !this.aim && this.visible) {
        this.idle += dt;
        if (this.idle > 4800 && !this.hint) this.hint = this.findVisualHint();
      }
      for (let i = this.particles.length - 1; i >= 0; i--) {
        const particle = this.particles[i];
        particle.life -= dt;
        particle.x += particle.vx * dt;
        particle.y += particle.vy * dt;
        particle.vy += particle.g * dt;
        particle.rot += particle.spin * dt;
        if (particle.life <= 0) this.particles.splice(i, 1);
      }
      if (this.particles.length > 220) this.particles.splice(0, this.particles.length - 220);
      for (let i = this.floaters.length - 1; i >= 0; i--) {
        const floater = this.floaters[i];
        floater.life -= dt;
        floater.y -= dt * 0.03;
        if (floater.life <= 0) this.floaters.splice(i, 1);
      }
      for (let i = this.fx.length - 1; i >= 0; i--) {
        this.fx[i].age += dt;
        if (this.fx[i].age >= this.fx[i].life) this.fx.splice(i, 1);
      }
      if (this.shake > 0) this.shake = Math.max(0, this.shake - dt);
    },

    draw() {
      if (!this.visible || !this.layout) return;
      const { ctx, layout } = this;
      ctx.clearRect(0, 0, layout.width, layout.height);
      const shake = this.shake > 0 ? Math.sin(this.time / 18) * 2.2 : 0;
      ctx.save();
      ctx.translate(shake, 0);
      const hints = this.hint ? [{ r: this.hint.r1, c: this.hint.c1 }, { r: this.hint.r2, c: this.hint.c2 }] : [];
      paintTray(ctx, layout, { selected: this.selected, hints, aim: this.aim }, this.time);

      const ordered = [...this.pieces.values()].sort((a, b) => a.r - b.r || a.c - b.c);
      for (const piece of ordered) this.drawPiece(piece);
      this.drawFx();
      for (const particle of this.particles) this.drawParticle(particle);
      for (const floater of this.floaters) this.drawFloater(floater);
      ctx.restore();
    },

    drawPiece(piece) {
      const { x, y } = this.cellCenter(piece.r, piece.c);
      const { ctx, layout } = this;
      const breathe = !this.reduced && !this.busy ? 1 + Math.sin(this.time / 700 + piece.id) * 0.018 : 1;
      const size = layout.cell * 0.8 * piece.scale * breathe;
      ctx.save();
      ctx.globalAlpha = Math.max(0, piece.alpha);
      ctx.drawImage(warmShadow(), x - size * 0.46, y + size * 0.28, size * 0.92, size * 0.36);
      const image = sprite(piece.gem, piece.special);
      ctx.drawImage(image, x - size / 2, y - size / 2, size, size);
      if (piece.ice || piece.frost > 0.02) paintIce(ctx, x, y, size * 0.92, piece.frost ?? 1);
      if (this.selected && this.selected.id === piece.id) paintRing(ctx, x, y, size * 0.58, this.time);
      if (piece.special === "rainbow" && !this.reduced) {
        ctx.strokeStyle = "rgba(255,255,255,0.45)";
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(x, y, size * 0.34, this.time / 400, this.time / 400 + 1.2);
        ctx.stroke();
      }
      ctx.restore();
    },

    drawParticle(particle) {
      const { ctx } = this;
      const alpha = Math.max(0, particle.life / particle.max);
      ctx.save();
      ctx.globalAlpha = alpha;
      ctx.translate(particle.x, particle.y);
      ctx.rotate(particle.rot);
      ctx.fillStyle = particle.color;
      if (particle.kind === "star") {
        ctx.beginPath();
        for (let i = 0; i < 8; i++) {
          const radius = i % 2 === 0 ? particle.size : particle.size * 0.42;
          const angle = (i * Math.PI) / 4;
          const px = Math.cos(angle) * radius;
          const py = Math.sin(angle) * radius;
          if (i === 0) ctx.moveTo(px, py);
          else ctx.lineTo(px, py);
        }
        ctx.fill();
      } else {
        ctx.beginPath();
        ctx.arc(0, 0, particle.size, 0, Math.PI * 2);
        ctx.fill();
      }
      ctx.restore();
    },

    drawFloater(floater) {
      const { ctx } = this;
      ctx.save();
      ctx.globalAlpha = Math.max(0, Math.min(1, floater.life / 280));
      ctx.font = `700 ${Math.round(this.layout.cell * 0.34)}px Fredoka, Nunito, sans-serif`;
      ctx.textAlign = "center";
      ctx.lineWidth = 4;
      ctx.strokeStyle = "rgba(92, 42, 12, 0.45)";
      ctx.fillStyle = "#fff6df";
      ctx.strokeText(floater.text, floater.x, floater.y);
      ctx.fillText(floater.text, floater.x, floater.y);
      ctx.restore();
    },

    drawFx() {
      const { ctx, layout } = this;
      for (const wave of this.fx) {
        const t = wave.age / wave.life;
        const { x, y } = this.cellCenter(wave.r, wave.c);
        ctx.save();
        ctx.globalAlpha = (1 - t) * 0.8;
        ctx.strokeStyle = wave.special === "bomb" ? "#ffe29a" : "#fff4d2";
        ctx.lineWidth = Math.max(2, layout.cell * 0.08 * (1 - t));
        if (wave.special === "lineH") {
          const y0 = layout.frame + wave.r * layout.cell;
          ctx.fillStyle = "rgba(255, 244, 214, 0.38)";
          const thickness = layout.cell * (wave.wide ? 3 : 0.72);
          ctx.fillRect(layout.frame, y0 + layout.cell / 2 - thickness / 2, layout.cols * layout.cell, thickness);
        } else if (wave.special === "lineV") {
          const x0 = layout.frame + wave.c * layout.cell;
          ctx.fillStyle = "rgba(255, 244, 214, 0.38)";
          const thickness = layout.cell * (wave.wide ? 3 : 0.72);
          ctx.fillRect(x0 + layout.cell / 2 - thickness / 2, layout.frame, thickness, layout.rows * layout.cell);
        } else if (wave.special === "bomb") {
          ctx.beginPath();
          ctx.arc(x, y, layout.cell * (0.4 + t * 2.4), 0, Math.PI * 2);
          ctx.stroke();
        } else if (wave.special === "rainbow") {
          ctx.fillStyle = `rgba(255, 220, 255, ${0.18 * (1 - t)})`;
          ctx.fillRect(0, 0, layout.width, layout.height);
        }
        ctx.restore();
      }
    },

    burst(r, c, gem, power = 1) {
      if (this.reduced) return;
      const { x, y } = this.cellCenter(r, c);
      const color = GEM_COLORS[gem] || "#fff";
      const count = Math.round(8 * power);
      for (let i = 0; i < count; i++) {
        const angle = Math.random() * Math.PI * 2;
        const speed = 0.05 + Math.random() * 0.16 * power;
        this.particles.push({
          x,
          y,
          vx: Math.cos(angle) * speed,
          vy: Math.sin(angle) * speed - 0.04,
          g: 0.00035,
          life: 420 + Math.random() * 240,
          max: 660,
          size: 2.2 + Math.random() * 3.2,
          rot: Math.random() * 6,
          spin: (Math.random() - 0.5) * 0.01,
          color,
          kind: Math.random() > 0.55 ? "star" : "dot",
        });
      }
    },

    findVisualHint() {
      const rows = this.grid.length;
      const cols = this.grid[0].length;
      for (let r = 0; r < rows; r++) {
        for (let c = 0; c < cols; c++) {
          for (const [rr, cc] of [
            [r, c + 1],
            [r + 1, c],
          ]) {
            if (rr >= rows || cc >= cols) continue;
            if (classifySwap(this.grid, r, c, rr, cc).kind !== "invalid") {
              return { r1: r, c1: c, r2: rr, c2: cc };
            }
          }
        }
      }
      return null;
    },

    cellAt(event) {
      const rect = this.canvas.getBoundingClientRect();
      const x = ((event.clientX - rect.left) / rect.width) * this.layout.width;
      const y = ((event.clientY - rect.top) / rect.height) * this.layout.height;
      const c = Math.floor((x - this.layout.frame) / this.layout.cell);
      const r = Math.floor((y - this.layout.frame) / this.layout.cell);
      if (r < 0 || c < 0 || r >= this.layout.rows || c >= this.layout.cols) return null;
      return { r, c };
    },

    pointerDown(event) {
      if (!this.visible || this.over) return;
      const cell = this.cellAt(event);
      if (!cell) return;
      if (this.aim === "hammer") {
        if (!this.busy) this.hammerAt(cell.r, cell.c);
        return;
      }
      if (this.busy) return;
      const tile = this.grid[cell.r][cell.c];
      if (!tile) return;
      if (tile.ice) {
        this.wiggle(tile.id);
        this.hooks.sfx?.("invalid");
        return;
      }
      this.hint = null;
      this.idle = 0;
      if (this.selected && !(this.selected.r === cell.r && this.selected.c === cell.c)) {
        const dist = Math.abs(this.selected.r - cell.r) + Math.abs(this.selected.c - cell.c);
        if (dist === 1) {
          const from = this.selected;
          this.selected = null;
          this.trySwap(from.r, from.c, cell.r, cell.c).catch((error) => console.error(error));
          return;
        }
      }
      this.selected = { r: cell.r, c: cell.c, id: tile.id };
      this.drag = {
        r: cell.r,
        c: cell.c,
        x: event.clientX,
        y: event.clientY,
        id: tile.id,
      };
      try {
        this.canvas.setPointerCapture(event.pointerId);
      } catch {
        /* Pointer capture can fail on stale events. */
      }
    },

    pointerMove(event) {
      if (!this.drag || this.busy) return;
      const dx = event.clientX - this.drag.x;
      const dy = event.clientY - this.drag.y;
      if (Math.hypot(dx, dy) < 16) return;
      const horizontal = Math.abs(dx) > Math.abs(dy);
      const fromR = this.drag.r;
      const fromC = this.drag.c;
      let r = fromR;
      let c = fromC;
      if (horizontal) c += dx > 0 ? 1 : -1;
      else r += dy > 0 ? 1 : -1;
      this.drag = null;
      this.selected = null;
      if (r < 0 || c < 0 || r >= this.grid.length || c >= this.grid[0].length) return;
      this.trySwap(fromR, fromC, r, c).catch((error) => console.error(error));
    },

    pointerUp() {
      this.drag = null;
    },

    async wiggle(id) {
      const piece = this.pieces.get(id);
      if (!piece) return;
      const base = piece.c;
      await this.motion(220, (t) => {
        piece.c = base + Math.sin(t * Math.PI * 3) * 0.06 * (1 - t);
      });
      piece.c = base;
    },

    async trySwap(r1, c1, r2, c2) {
      if (this.busy || this.over) return;
      const tileA = this.grid[r1]?.[c1];
      const tileB = this.grid[r2]?.[c2];
      if (!tileA || !tileB) return;
      const verdict = classifySwap(this.grid, r1, c1, r2, c2);
      const epoch = this.epoch;
      this.busy = true;
      this.selected = null;
      this.hint = null;
      try {
        if (verdict.kind === "invalid") {
          await this.nudge(tileA.id, tileB.id);
          this.hooks.sfx?.("invalid");
          if (epoch === this.epoch) this.busy = false;
          return;
        }
        swapTiles(this.grid, r1, c1, r2, c2);
        this.hooks.sfx?.("swap");
        await this.glide(tileA.id, tileB.id, r2, c2, r1, c1);
        if (epoch !== this.epoch) return;
        this.moves -= 1;
        this.emit();
        await this.resolvePair(r1, c1, r2, c2, epoch);
        if (epoch !== this.epoch) return;
        await this.finishTurn(epoch);
      } catch (error) {
        console.error(error);
        if (epoch === this.epoch) this.busy = false;
      }
    },

    async nudge(idA, idB) {
      const a = this.pieces.get(idA);
      const b = this.pieces.get(idB);
      if (!a || !b) return;
      const ar = a.r;
      const ac = a.c;
      const br = b.r;
      const bc = b.c;
      await this.motion(240, (t) => {
        const wave = Math.sin(t * Math.PI);
        a.r = ar + (br - ar) * 0.16 * wave;
        a.c = ac + (bc - ac) * 0.16 * wave;
        b.r = br + (ar - br) * 0.06 * wave;
        b.c = bc + (ac - bc) * 0.06 * wave;
      });
      a.r = ar;
      a.c = ac;
      b.r = br;
      b.c = bc;
    },

    async glide(idA, idB, r2, c2, r1, c1) {
      const a = this.pieces.get(idA);
      const b = this.pieces.get(idB);
      const ar = a.r;
      const ac = a.c;
      const br = b.r;
      const bc = b.c;
      await this.motion(180, (t) => {
        const e = easeInOut(t);
        a.r = ar + (r2 - ar) * e;
        a.c = ac + (c2 - ac) * e;
        b.r = br + (r1 - br) * e;
        b.c = bc + (c1 - bc) * e;
      });
      a.r = r2;
      a.c = c2;
      b.r = r1;
      b.c = c1;
    },

    async resolvePair(r1, c1, r2, c2, epoch) {
      const a = this.grid[r1][c1];
      const b = this.grid[r2][c2];
      let result;
      if (a.special === "rainbow" && b.special === "rainbow") {
        result = resolveActivation(this.grid, [keyOf(r1, c1), keyOf(r2, c2)], this.rng, this.level.types, {
          color: "all",
        });
      } else if (a.special === "rainbow" || b.special === "rainbow") {
        const rainbowPos = a.special === "rainbow" ? [r1, c1] : [r2, c2];
        const other = a.special === "rainbow" ? b : a;
        const origins = prepareRainbowCombo(this.grid, other.gem, other.special);
        origins.push(keyOf(rainbowPos[0], rainbowPos[1]));
        result = resolveActivation(this.grid, origins, this.rng, this.level.types, { color: other.gem });
      } else if (a.special && b.special) {
        upgradeCombo(a, b);
        const pieceA = this.pieces.get(a.id);
        const pieceB = this.pieces.get(b.id);
        if (pieceA) pieceA.special = a.special;
        if (pieceB) pieceB.special = b.special;
        result = resolveActivation(this.grid, [keyOf(r1, c1), keyOf(r2, c2)], this.rng, this.level.types);
      } else {
        result = settle(this.grid, this.rng, this.level.types, [keyOf(r2, c2), keyOf(r1, c1)]);
      }
      await this.playSteps(result, epoch);
    },

    async playSteps(result, epoch) {
      for (const step of result.steps) {
        if (epoch !== this.epoch) return;
        if (step.kind === "clear") await this.animateClear(step, epoch);
        else await this.animateDrop(step, epoch);
      }
      if (epoch === this.epoch) this.reconcile();
    },

    async animateClear(step, epoch) {
      if (step.waves?.length) this.hooks.sfx?.("special");
      else if (step.removed?.length) this.hooks.sfx?.("match", Math.min(5, step.combo));
      if (step.waves?.some((wave) => wave.special === "bomb" || wave.special === "rainbow")) this.shake = 180;

      for (const wave of step.waves || []) {
        this.fx.push({ ...wave, age: 0, life: wave.special === "rainbow" ? 460 : 320, wide: wave.lineWidth > 0 });
      }
      const pieces = [];
      for (const tile of step.removed) {
        const piece = this.pieces.get(tile.id);
        if (piece) pieces.push(piece);
        this.burst(tile.r, tile.c, tile.gem, step.combo >= 3 ? 1.6 : 1);
        this.collectedAdd(tile.gem);
      }
      this.score += step.points;
      const anchor = step.removed[Math.floor(step.removed.length / 2)] || step.removed[0];
      if (anchor && step.points) {
        const { x, y } = this.cellCenter(anchor.r, anchor.c);
        this.floaters.push({ text: `+${step.points}`, x, y: y - 8, life: 760 });
      }
      this.noteGoals();
      this.emit();
      if (step.combo >= 2) this.hooks.onCombo?.(step.combo);

      await this.motion(240, (t) => {
        for (const piece of pieces) {
          if (t < 0.35) piece.scale = 1 + (t / 0.35) * 0.16;
          else piece.scale = 1 - (t - 0.35) / 0.65;
          piece.alpha = t < 0.45 ? 1 : 1 - (t - 0.45) / 0.55;
        }
        for (const ice of step.iceBroken || []) {
          const piece = this.pieces.get(ice.id);
          if (piece) piece.frost = 1 - t;
        }
      });
      if (epoch !== this.epoch) return;
      for (const tile of step.removed) this.pieces.delete(tile.id);
      for (const ice of step.iceBroken || []) {
        const piece = this.pieces.get(ice.id);
        if (piece) {
          piece.ice = false;
          piece.frost = 0;
        }
      }
      for (const born of step.spawned || []) {
        this.pieces.set(born.id, {
          id: born.id,
          gem: born.gem,
          special: born.special,
          ice: false,
          frost: 0,
          r: born.r,
          c: born.c,
          scale: 0.2,
          alpha: 0,
        });
        this.burst(born.r, born.c, born.gem, 1.4);
      }
      if (step.spawned?.length) {
        await this.motion(220, (t) => {
          const e = easeOutBack(t);
          for (const born of step.spawned) {
            const piece = this.pieces.get(born.id);
            if (!piece) continue;
            piece.scale = Math.max(0.2, e);
            piece.alpha = Math.min(1, t * 1.6);
          }
        });
      }
    },

    collectedAdd(gem) {
      if (gem == null || gem < 0) return;
      this.collected[gem] = (this.collected[gem] || 0) + 1;
    },

    noteGoals() {
      this.level.goals.forEach((goal, index) => {
        const done = goalDone(goal, this.score, this.collected);
        if (done && !this.goalFlags[index]) {
          this.goalFlags[index] = true;
          this.hooks.onGoal?.(index);
        }
      });
    },

    async animateDrop(step, epoch, mode = "fall") {
      const movers = [];
      for (const drop of step.drops || []) {
        let piece = this.pieces.get(drop.id);
        if (!piece) {
          piece = {
            id: drop.id,
            gem: drop.gem,
            special: drop.special,
            ice: false,
            frost: 0,
            r: drop.fromR,
            c: drop.fromC,
            scale: drop.spawn ? 0.86 : 1,
            alpha: 1,
          };
          this.pieces.set(drop.id, piece);
        }
        movers.push({
          piece,
          r: piece.r,
          c: piece.c,
          toR: drop.toR,
          toC: drop.toC,
          dist: Math.abs(drop.toR - drop.fromR) + Math.abs(drop.toC - drop.fromC),
        });
      }
      if (!movers.length) return;
      const farthest = Math.max(...movers.map((mover) => mover.dist));
      const duration = mode === "shuffle" ? 420 : Math.min(560, 160 + farthest * 62);
      await this.motion(duration, (t) => {
        const e = mode === "shuffle" ? easeInOut(t) : easeFall(t);
        for (const mover of movers) {
          mover.piece.r = mover.r + (mover.toR - mover.r) * e;
          mover.piece.c = mover.c + (mover.toC - mover.c) * e;
          if (mover.piece.scale < 1) mover.piece.scale = 0.86 + 0.14 * t;
        }
      }, (t) => t);
      if (epoch !== this.epoch) return;
      for (const mover of movers) {
        mover.piece.r = mover.toR;
        mover.piece.c = mover.toC;
      }
    },

    async finishTurn(epoch) {
      if (epoch !== this.epoch) return;
      if (goalsMet(this.level.goals, this.score, this.collected)) {
        await this.bonus(epoch);
        if (epoch !== this.epoch) return;
        this.over = "win";
        const stars = Math.max(1, starCount(this.score, this.level.stars));
        this.busy = false;
        this.hooks.onWin?.({ score: this.score, stars, collected: { ...this.collected } });
        return;
      }
      if (this.moves <= 0) {
        this.over = "lose";
        this.busy = false;
        this.hooks.onLose?.({ score: this.score, collected: { ...this.collected } });
        return;
      }
      if (!this.findVisualHint()) {
        this.hooks.onStatus?.("shuffle");
        await this.doShuffle(epoch);
      }
      if (epoch === this.epoch) this.busy = false;
    },

    async bonus(epoch) {
      this.hooks.onStatus?.("bonus");
      let guard = 0;
      while (this.moves > 0 && guard < 36 && epoch === this.epoch) {
        guard += 1;
        const spot = randomPlainSpot(this.grid, this.rng);
        if (!spot) break;
        const [r, c] = spot;
        const tile = this.grid[r][c];
        const roll = this.rng();
        tile.special = roll < 0.42 ? "lineH" : roll < 0.84 ? "lineV" : "bomb";
        const piece = this.pieces.get(tile.id);
        if (piece) {
          piece.special = tile.special;
          piece.scale = 0.4;
        }
        this.moves -= 1;
        this.emit();
        await this.motion(140, (t) => {
          if (piece) piece.scale = 0.4 + easeOutBack(t) * 0.6;
        });
        if (epoch !== this.epoch) return;
        const result = resolveActivation(this.grid, [keyOf(r, c)], this.rng, this.level.types);
        await this.playSteps(result, epoch);
      }
    },

    async doShuffle(epoch) {
      const drops = reshuffle(this.grid, this.rng);
      this.hooks.sfx?.("whoosh");
      await this.animateDrop({ drops }, epoch, "shuffle");
      if (epoch === this.epoch) this.reconcile();
    },

    arm(kind) {
      if (this.busy || this.over) return false;
      if (kind === "shuffle") {
        this.useShuffle();
        return true;
      }
      this.aim = kind;
      this.selected = null;
      this.hooks.onAim?.(kind);
      return true;
    },

    cancelAim() {
      this.aim = null;
      this.hooks.onAim?.(null);
    },

    async hammerAt(r, c) {
      const tile = this.grid[r]?.[c];
      if (!tile) return;
      const epoch = this.epoch;
      this.aim = null;
      this.hooks.onAim?.(null);
      this.busy = true;
      this.hooks.onConsume?.("hammer");
      this.hooks.sfx?.("hammer");
      const opts = tile.special === "rainbow" ? { color: tile.gem } : {};
      const result = resolveActivation(this.grid, [keyOf(r, c)], this.rng, this.level.types, opts);
      await this.playSteps(result, epoch);
      if (epoch !== this.epoch) return;
      await this.finishTurn(epoch);
    },

    async useShuffle() {
      if (this.busy || this.over) return;
      const epoch = this.epoch;
      this.busy = true;
      this.hooks.onConsume?.("shuffle");
      await this.doShuffle(epoch);
      if (epoch === this.epoch) this.busy = false;
    },

    grantMoves(count) {
      this.moves += count;
      if (this.over === "lose") this.over = null;
      this.busy = false;
      this.emit();
    },

    emit() {
      this.hooks.onChange?.(this.snapshot());
    },
  };

  canvas.addEventListener("pointerdown", (event) => game.pointerDown(event));
  canvas.addEventListener("pointermove", (event) => game.pointerMove(event));
  canvas.addEventListener("pointerup", () => game.pointerUp());
  canvas.addEventListener("pointercancel", () => game.pointerUp());
  return game;
}

function goalDone(goal, score, collected) {
  if (goal.type === "score") return score >= goal.target;
  return (collected[goal.gem] || 0) >= goal.target;
}
