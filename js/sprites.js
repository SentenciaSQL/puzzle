export const GEM_COLORS = ["#ffc44d", "#ff6b9d", "#2ec9ae", "#b388ff", "#5eb6ff", "#ff7a45"];

const SIZE = 256;
const atlas = new Map();
const icons = new Map();
let grain = null;
let shadowBlob = null;

function roundPath(ctx, x, y, w, h, r) {
  const radius = Math.max(0, Math.min(r, w / 2, h / 2));
  ctx.beginPath();
  ctx.moveTo(x + radius, y);
  ctx.arcTo(x + w, y, x + w, y + h, radius);
  ctx.arcTo(x + w, y + h, x, y + h, radius);
  ctx.arcTo(x, y + h, x, y, radius);
  ctx.arcTo(x, y, x + w, y, radius);
  ctx.closePath();
}

function gloss(ctx, x, y, rx, ry, rot = -0.7) {
  ctx.save();
  ctx.translate(x, y);
  ctx.rotate(rot);
  const fade = ctx.createLinearGradient(0, -ry, 0, ry);
  fade.addColorStop(0, "rgba(255,255,255,0.92)");
  fade.addColorStop(0.42, "rgba(255,255,255,0.18)");
  fade.addColorStop(1, "rgba(255,255,255,0)");
  ctx.fillStyle = fade;
  ctx.beginPath();
  ctx.ellipse(0, 0, rx, ry, 0, 0, Math.PI * 2);
  ctx.fill();
  ctx.restore();
}

function volumeShade(ctx) {
  const shade = ctx.createLinearGradient(0, 30, 0, 240);
  shade.addColorStop(0, "rgba(255,255,255,0.2)");
  shade.addColorStop(0.42, "rgba(255,255,255,0)");
  shade.addColorStop(1, "rgba(70, 18, 8, 0.3)");
  ctx.fillStyle = shade;
  ctx.fillRect(0, 0, SIZE, SIZE);
}

function paintShape(ctx, trace, fillStyle, detail) {
  ctx.save();
  trace();
  ctx.fillStyle = fillStyle;
  ctx.fill();
  ctx.save();
  trace();
  ctx.clip();
  volumeShade(ctx);
  detail(ctx);
  ctx.restore();
  ctx.lineWidth = 5;
  ctx.strokeStyle = "rgba(255,255,255,0.34)";
  trace();
  ctx.stroke();
  ctx.lineWidth = 8;
  ctx.strokeStyle = "rgba(80, 30, 10, 0.18)";
  ctx.save();
  ctx.translate(0, 3);
  trace();
  ctx.stroke();
  ctx.restore();
  ctx.restore();
}

function radial(ctx, x, y, r0, r1, stops) {
  const paint = ctx.createRadialGradient(x, y, r0, x, y, r1);
  for (const [offset, color] of stops) paint.addColorStop(offset, color);
  return paint;
}

function drawSunberry(ctx) {
  const fill = radial(ctx, 104, 112, 10, 100, [
    [0, "#fff6cf"],
    [0.28, "#ffd15a"],
    [0.68, "#f39a16"],
    [1, "#d86a09"],
  ]);
  paintShape(
    ctx,
    () => ctx.arc(128, 142, 84, 0, Math.PI * 2),
    fill,
    (g) => {
      g.fillStyle = "rgba(196, 92, 8, 0.28)";
      for (const [x, y] of [
        [100, 132],
        [128, 150],
        [154, 128],
        [118, 168],
        [146, 166],
      ]) {
        g.beginPath();
        g.ellipse(x, y, 5, 7, 0.4, 0, Math.PI * 2);
        g.fill();
      }
      gloss(g, 102, 114, 20, 11, -0.55);
    },
  );
  ctx.save();
  ctx.translate(128, 62);
  ctx.rotate(-0.5);
  const leaf = ctx.createLinearGradient(-20, -10, 24, 18);
  leaf.addColorStop(0, "#b6f27a");
  leaf.addColorStop(1, "#2f9a45");
  ctx.fillStyle = leaf;
  ctx.beginPath();
  ctx.moveTo(0, -6);
  ctx.bezierCurveTo(28, -22, 42, 4, 8, 16);
  ctx.bezierCurveTo(-6, 8, -8, 2, 0, -6);
  ctx.fill();
  ctx.strokeStyle = "rgba(20, 90, 30, 0.35)";
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.moveTo(2, 0);
  ctx.lineTo(24, -2);
  ctx.stroke();
  ctx.restore();
  ctx.strokeStyle = "#c47a22";
  ctx.lineWidth = 5;
  ctx.lineCap = "round";
  ctx.beginPath();
  ctx.moveTo(128, 78);
  ctx.lineTo(128, 64);
  ctx.stroke();
}

function drawRoseplum(ctx) {
  const fill = radial(ctx, 108, 108, 8, 110, [
    [0, "#ffe4ef"],
    [0.35, "#ff8eb6"],
    [0.72, "#f24b86"],
    [1, "#c81d62"],
  ]);
  const trace = () => {
    ctx.beginPath();
    ctx.moveTo(128, 206);
    ctx.bezierCurveTo(128, 206, 46, 150, 46, 104);
    ctx.bezierCurveTo(46, 70, 74, 52, 102, 68);
    ctx.bezierCurveTo(114, 40, 142, 40, 154, 68);
    ctx.bezierCurveTo(182, 52, 210, 70, 210, 104);
    ctx.bezierCurveTo(210, 150, 128, 206, 128, 206);
    ctx.closePath();
  };
  paintShape(ctx, trace, fill, (g) => {
    gloss(g, 96, 96, 26, 14, -0.9);
    g.fillStyle = "rgba(255,255,255,0.28)";
    g.beginPath();
    g.ellipse(150, 118, 10, 16, 0.6, 0, Math.PI * 2);
    g.fill();
  });
}

function drawMintleaf(ctx) {
  const fill = radial(ctx, 110, 120, 8, 120, [
    [0, "#f3fff8"],
    [0.34, "#7ef0d4"],
    [0.7, "#1fbfa2"],
    [1, "#0c7d6c"],
  ]);
  const trace = () => {
    ctx.beginPath();
    ctx.moveTo(128, 36);
    ctx.bezierCurveTo(206, 78, 196, 176, 128, 224);
    ctx.bezierCurveTo(60, 176, 50, 78, 128, 36);
    ctx.closePath();
  };
  paintShape(ctx, trace, fill, (g) => {
    g.strokeStyle = "rgba(255,255,255,0.55)";
    g.lineWidth = 3;
    g.lineCap = "round";
    g.beginPath();
    g.moveTo(128, 58);
    g.quadraticCurveTo(124, 130, 128, 200);
    g.stroke();
    g.strokeStyle = "rgba(10, 90, 70, 0.25)";
    g.lineWidth = 2;
    for (const y of [96, 126, 156]) {
      g.beginPath();
      g.moveTo(128, y);
      g.quadraticCurveTo(150, y - 8, 168, y - 18);
      g.moveTo(128, y);
      g.quadraticCurveTo(106, y - 8, 88, y - 18);
      g.stroke();
    }
    gloss(g, 104, 96, 22, 12, -0.6);
    g.fillStyle = "rgba(255,255,255,0.75)";
    g.beginPath();
    g.ellipse(154, 150, 7, 10, 0.4, 0, Math.PI * 2);
    g.fill();
  });
}

function drawMoonpearl(ctx) {
  const fill = radial(ctx, 108, 112, 8, 96, [
    [0, "#fff8ff"],
    [0.3, "#e4d2ff"],
    [0.66, "#a478f0"],
    [1, "#6840c8"],
  ]);
  paintShape(
    ctx,
    () => ctx.arc(128, 136, 84, 0, Math.PI * 2),
    fill,
    (g) => {
      g.fillStyle = "rgba(92, 48, 170, 0.28)";
      g.beginPath();
      g.arc(156, 124, 48, 0, Math.PI * 2);
      g.fill();
      g.fillStyle = "rgba(255,255,255,0.16)";
      g.beginPath();
      g.arc(108, 150, 34, 0, Math.PI * 2);
      g.fill();
      gloss(g, 102, 104, 26, 14, -0.8);
      g.fillStyle = "#fff7c8";
      star(g, 168, 92, 8, 5);
      g.fill();
    },
  );
}

function drawSkydew(ctx) {
  const fill = radial(ctx, 108, 120, 8, 110, [
    [0, "#f4fbff"],
    [0.32, "#8fd4ff"],
    [0.7, "#3c93f2"],
    [1, "#1d5ec4"],
  ]);
  const trace = () => {
    ctx.beginPath();
    ctx.moveTo(128, 34);
    ctx.bezierCurveTo(196, 92, 198, 168, 128, 222);
    ctx.bezierCurveTo(58, 168, 60, 92, 128, 34);
    ctx.closePath();
  };
  paintShape(ctx, trace, fill, (g) => {
    g.strokeStyle = "rgba(255,255,255,0.4)";
    g.lineWidth = 3;
    g.beginPath();
    g.moveTo(128, 70);
    g.lineTo(168, 132);
    g.lineTo(128, 132);
    g.lineTo(96, 168);
    g.stroke();
    gloss(g, 108, 96, 20, 12, -0.7);
    g.fillStyle = "rgba(255,255,255,0.55)";
    g.beginPath();
    g.ellipse(146, 154, 8, 14, 0.5, 0, Math.PI * 2);
    g.fill();
  });
}

function drawEmberfig(ctx) {
  const fill = radial(ctx, 110, 110, 8, 120, [
    [0, "#fff1df"],
    [0.28, "#ffb07a"],
    [0.62, "#ff6a3d"],
    [1, "#d33a18"],
  ]);
  const trace = () => {
    ctx.beginPath();
    ctx.moveTo(128, 34);
    ctx.lineTo(214, 128);
    ctx.lineTo(128, 226);
    ctx.lineTo(42, 128);
    ctx.closePath();
  };
  paintShape(ctx, trace, fill, (g) => {
    g.fillStyle = "rgba(255,255,255,0.28)";
    g.beginPath();
    g.moveTo(128, 52);
    g.lineTo(188, 128);
    g.lineTo(128, 128);
    g.closePath();
    g.fill();
    g.fillStyle = "rgba(160, 30, 8, 0.18)";
    g.beginPath();
    g.moveTo(128, 128);
    g.lineTo(196, 128);
    g.lineTo(128, 206);
    g.closePath();
    g.fill();
    g.strokeStyle = "rgba(255,255,255,0.45)";
    g.lineWidth = 3;
    g.beginPath();
    g.moveTo(128, 58);
    g.lineTo(128, 198);
    g.moveTo(64, 128);
    g.lineTo(196, 128);
    g.stroke();
    gloss(g, 108, 96, 18, 10, -0.8);
  });
}

function star(ctx, x, y, outer, inner) {
  ctx.beginPath();
  for (let i = 0; i < 8; i++) {
    const radius = i % 2 === 0 ? outer : inner;
    const angle = -Math.PI / 2 + (i * Math.PI) / 4;
    const px = x + Math.cos(angle) * radius;
    const py = y + Math.sin(angle) * radius;
    if (i === 0) ctx.moveTo(px, py);
    else ctx.lineTo(px, py);
  }
  ctx.closePath();
}

function clipGem(ctx, gem) {
  if (gem === 0) ctx.arc(128, 142, 84, 0, Math.PI * 2);
  else if (gem === 1) {
    ctx.moveTo(128, 206);
    ctx.bezierCurveTo(128, 206, 46, 150, 46, 104);
    ctx.bezierCurveTo(46, 70, 74, 52, 102, 68);
    ctx.bezierCurveTo(114, 40, 142, 40, 154, 68);
    ctx.bezierCurveTo(182, 52, 210, 70, 210, 104);
    ctx.bezierCurveTo(210, 150, 128, 206, 128, 206);
  } else if (gem === 2) {
    ctx.moveTo(128, 36);
    ctx.bezierCurveTo(206, 78, 196, 176, 128, 224);
    ctx.bezierCurveTo(60, 176, 50, 78, 128, 36);
  } else if (gem === 3) ctx.arc(128, 136, 84, 0, Math.PI * 2);
  else if (gem === 4) {
    ctx.moveTo(128, 34);
    ctx.bezierCurveTo(196, 92, 198, 168, 128, 222);
    ctx.bezierCurveTo(58, 168, 60, 92, 128, 34);
  } else {
    ctx.moveTo(128, 34);
    ctx.lineTo(214, 128);
    ctx.lineTo(128, 226);
    ctx.lineTo(42, 128);
    ctx.closePath();
  }
}

function drawStripe(ctx, gem, vertical) {
  ctx.save();
  ctx.beginPath();
  clipGem(ctx, gem);
  ctx.clip();
  ctx.translate(128, 136);
  if (vertical) ctx.rotate(Math.PI / 2);
  const band = ctx.createLinearGradient(-28, 0, 28, 0);
  band.addColorStop(0, "rgba(255,255,255,0)");
  band.addColorStop(0.35, "rgba(255,255,255,0.15)");
  band.addColorStop(0.5, "rgba(255,255,255,0.85)");
  band.addColorStop(0.65, "rgba(255,255,255,0.15)");
  band.addColorStop(1, "rgba(255,255,255,0)");
  ctx.fillStyle = band;
  ctx.fillRect(-30, -130, 60, 260);
  ctx.strokeStyle = "rgba(255,255,255,0.95)";
  ctx.lineWidth = 4;
  ctx.lineCap = "round";
  ctx.lineJoin = "round";
  for (const y of [-70, -10, 50]) {
    ctx.beginPath();
    ctx.moveTo(-16, y);
    ctx.lineTo(0, y + 14);
    ctx.lineTo(16, y);
    ctx.stroke();
  }
  ctx.restore();
}

function drawBombMark(ctx) {
  ctx.save();
  ctx.translate(128, 136);
  ctx.strokeStyle = "rgba(255, 226, 140, 0.95)";
  ctx.lineWidth = 8;
  ctx.beginPath();
  ctx.arc(0, 0, 78, 0, Math.PI * 2);
  ctx.stroke();
  ctx.strokeStyle = "rgba(255,255,255,0.85)";
  ctx.lineWidth = 3;
  ctx.beginPath();
  ctx.arc(0, 0, 68, 0, Math.PI * 2);
  ctx.stroke();
  for (let i = 0; i < 6; i++) {
    const angle = (i / 6) * Math.PI * 2 - Math.PI / 2;
    ctx.fillStyle = i % 2 ? "#fff4c4" : "#ffe08a";
    star(ctx, Math.cos(angle) * 78, Math.sin(angle) * 78, 8, 4);
    ctx.fill();
  }
  ctx.fillStyle = "#fff8dc";
  star(ctx, 0, 0, 16, 7);
  ctx.fill();
  ctx.restore();
}

function drawRainbow(ctx) {
  const colors = ["#ff5d73", "#ff9f1c", "#ffe66d", "#2ec4b6", "#4cc9f0", "#7b6cff", "#ff6bb5"];
  ctx.save();
  ctx.beginPath();
  ctx.arc(128, 132, 90, 0, Math.PI * 2);
  ctx.clip();
  for (let i = 0; i < colors.length; i++) {
    ctx.beginPath();
    ctx.moveTo(128, 132);
    ctx.arc(128, 132, 96, (i / colors.length) * Math.PI * 2 - Math.PI / 2, ((i + 1) / colors.length) * Math.PI * 2 - Math.PI / 2);
    ctx.closePath();
    ctx.fillStyle = colors[i];
    ctx.fill();
  }
  const core = ctx.createRadialGradient(112, 112, 8, 128, 132, 78);
  core.addColorStop(0, "rgba(255,255,255,0.95)");
  core.addColorStop(0.45, "rgba(255,255,255,0.35)");
  core.addColorStop(1, "rgba(255,255,255,0)");
  ctx.fillStyle = core;
  ctx.fillRect(0, 0, SIZE, SIZE);
  gloss(ctx, 104, 100, 30, 16, -0.8);
  ctx.restore();
  ctx.beginPath();
  ctx.arc(128, 132, 90, 0, Math.PI * 2);
  ctx.lineWidth = 6;
  ctx.strokeStyle = "rgba(255,255,255,0.7)";
  ctx.stroke();
  ctx.fillStyle = "#fff";
  star(ctx, 176, 86, 10, 5);
  ctx.fill();
  star(ctx, 78, 168, 7, 3);
  ctx.fill();
}

const DRAW = [drawSunberry, drawRoseplum, drawMintleaf, drawMoonpearl, drawSkydew, drawEmberfig];

function renderSprite(gem, special) {
  const canvas = document.createElement("canvas");
  canvas.width = SIZE;
  canvas.height = SIZE;
  const ctx = canvas.getContext("2d");
  if (special === "rainbow") drawRainbow(ctx);
  else {
    DRAW[gem](ctx);
    if (special === "lineH") drawStripe(ctx, gem, false);
    if (special === "lineV") drawStripe(ctx, gem, true);
    if (special === "bomb") drawBombMark(ctx);
  }
  return canvas;
}

export function sprite(gem, special) {
  const key = special === "rainbow" ? "rainbow" : `${gem}:${special || "none"}`;
  if (!atlas.has(key)) atlas.set(key, renderSprite(special === "rainbow" ? 0 : gem, special || "none"));
  return atlas.get(key);
}

export function gemIcon(gem, special = null, px = 72) {
  const key = `${gem}:${special || "none"}:${px}`;
  if (icons.has(key)) return icons.get(key);
  const canvas = document.createElement("canvas");
  canvas.width = px;
  canvas.height = px;
  const ctx = canvas.getContext("2d");
  ctx.drawImage(sprite(gem, special), 0, 0, px, px);
  const url = canvas.toDataURL("image/png");
  icons.set(key, url);
  return url;
}

export function warmShadow() {
  if (shadowBlob) return shadowBlob;
  const canvas = document.createElement("canvas");
  canvas.width = 128;
  canvas.height = 64;
  const ctx = canvas.getContext("2d");
  const paint = ctx.createRadialGradient(64, 32, 4, 64, 32, 58);
  paint.addColorStop(0, "rgba(70, 28, 12, 0.45)");
  paint.addColorStop(1, "rgba(70, 28, 12, 0)");
  ctx.fillStyle = paint;
  ctx.beginPath();
  ctx.ellipse(64, 32, 58, 24, 0, 0, Math.PI * 2);
  ctx.fill();
  shadowBlob = canvas;
  return canvas;
}

function grainCanvas() {
  if (grain) return grain;
  const canvas = document.createElement("canvas");
  canvas.width = 160;
  canvas.height = 160;
  const ctx = canvas.getContext("2d");
  const image = ctx.createImageData(160, 160);
  for (let i = 0; i < image.data.length; i += 4) {
    const value = 120 + Math.random() * 80;
    image.data[i] = value;
    image.data[i + 1] = value * 0.78;
    image.data[i + 2] = value * 0.42;
    image.data[i + 3] = Math.random() * 50;
  }
  ctx.putImageData(image, 0, 0);
  grain = canvas;
  return canvas;
}

export function paintTray(ctx, layout, state, time) {
  const { width, height, frame, cell, cols, rows } = layout;
  const radius = Math.max(18, cell * 0.34);

  roundPath(ctx, 0.5, 0.5, width - 1, height - 1, radius);
  const wood = ctx.createLinearGradient(0, 0, 0, height);
  wood.addColorStop(0, "#d39a58");
  wood.addColorStop(0.18, "#b8743a");
  wood.addColorStop(0.55, "#8d4e24");
  wood.addColorStop(1, "#6b3918");
  ctx.fillStyle = wood;
  ctx.fill();

  ctx.save();
  roundPath(ctx, 0, 0, width, height, radius);
  ctx.clip();
  ctx.globalAlpha = 0.28;
  ctx.drawImage(grainCanvas(), 0, 0, width, height);
  ctx.globalAlpha = 1;
  const sheen = ctx.createLinearGradient(0, 0, 0, frame);
  sheen.addColorStop(0, "rgba(255,236,196,0.45)");
  sheen.addColorStop(1, "rgba(255,236,196,0)");
  ctx.fillStyle = sheen;
  ctx.fillRect(0, 0, width, frame + 6);
  ctx.restore();

  ctx.save();
  roundPath(ctx, 3, 3, width - 6, height - 6, radius - 2);
  ctx.strokeStyle = "rgba(255, 220, 160, 0.55)";
  ctx.lineWidth = 2;
  ctx.stroke();
  roundPath(ctx, 7, 7, width - 14, height - 14, radius - 6);
  ctx.strokeStyle = "rgba(90, 40, 12, 0.35)";
  ctx.stroke();
  ctx.restore();

  const gap = Math.max(3, cell * 0.075);
  const wellRadius = Math.max(8, cell * 0.22);
  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      const x = frame + c * cell + gap;
      const y = frame + r * cell + gap;
      const size = cell - gap * 2;
      const selected = state.selected && state.selected.r === r && state.selected.c === c;
      const hinted = state.hints?.some((hint) => hint.r === r && hint.c === c);
      roundPath(ctx, x, y, size, size, wellRadius);
      const well = ctx.createLinearGradient(x, y, x, y + size);
      if (selected) {
        well.addColorStop(0, "#a56b3c");
        well.addColorStop(1, "#6e3d1c");
      } else {
        well.addColorStop(0, "#7a4624");
        well.addColorStop(1, "#4c2812");
      }
      ctx.fillStyle = well;
      ctx.fill();
      ctx.save();
      roundPath(ctx, x, y, size, size, wellRadius);
      ctx.clip();
      const inset = ctx.createLinearGradient(x, y, x, y + size);
      inset.addColorStop(0, "rgba(40, 16, 4, 0.4)");
      inset.addColorStop(0.18, "rgba(40, 16, 4, 0)");
      inset.addColorStop(1, "rgba(255, 214, 160, 0.08)");
      ctx.fillStyle = inset;
      ctx.fillRect(x, y, size, size);
      ctx.restore();

      if (hinted) {
        const pulse = 0.35 + Math.sin(time / 280) * 0.2;
        ctx.save();
        roundPath(ctx, x + 2, y + 2, size - 4, size - 4, wellRadius - 2);
        ctx.strokeStyle = `rgba(255, 214, 120, ${0.45 + pulse})`;
        ctx.lineWidth = 2.5;
        ctx.stroke();
        ctx.restore();
      }
      if (selected) {
        ctx.save();
        roundPath(ctx, x + 1.5, y + 1.5, size - 3, size - 3, wellRadius - 1);
        ctx.strokeStyle = "rgba(255, 226, 150, 0.95)";
        ctx.lineWidth = 2.5;
        ctx.stroke();
        ctx.restore();
      }
    }
  }

  ctx.save();
  roundPath(ctx, 1, 1, width - 2, height - 2, radius);
  ctx.strokeStyle = "rgba(255, 236, 205, 0.7)";
  ctx.lineWidth = 2;
  ctx.stroke();
  ctx.restore();

  drawRivets(ctx, width, height, radius);
}

function drawRivets(ctx, width, height, radius) {
  const points = [
    [radius * 0.72, radius * 0.72],
    [width - radius * 0.72, radius * 0.72],
    [radius * 0.72, height - radius * 0.72],
    [width - radius * 0.72, height - radius * 0.72],
  ];
  for (const [x, y] of points) {
    const paint = ctx.createRadialGradient(x - 2, y - 2, 1, x, y, 7);
    paint.addColorStop(0, "#fff1c4");
    paint.addColorStop(0.5, "#e2b15a");
    paint.addColorStop(1, "#8a5a20");
    ctx.fillStyle = paint;
    ctx.beginPath();
    ctx.arc(x, y, 6, 0, Math.PI * 2);
    ctx.fill();
  }
}

export function paintIce(ctx, x, y, size, frost = 1) {
  ctx.save();
  ctx.globalAlpha = 0.92 * frost;
  const radius = size * 0.28;
  roundPath(ctx, x - size / 2, y - size / 2, size, size, radius);
  const glass = ctx.createLinearGradient(x - size / 2, y - size / 2, x + size / 2, y + size / 2);
  glass.addColorStop(0, "rgba(255,255,255,0.5)");
  glass.addColorStop(0.45, "rgba(214, 238, 255, 0.16)");
  glass.addColorStop(1, "rgba(186, 220, 245, 0.28)");
  ctx.fillStyle = glass;
  ctx.fill();
  ctx.strokeStyle = "rgba(255,255,255,0.9)";
  ctx.lineWidth = Math.max(1.5, size * 0.035);
  ctx.stroke();
  ctx.strokeStyle = "rgba(120, 170, 210, 0.45)";
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.moveTo(x - size * 0.22, y - size * 0.05);
  ctx.lineTo(x + size * 0.02, y + size * 0.08);
  ctx.lineTo(x + size * 0.2, y - size * 0.12);
  ctx.stroke();
  ctx.fillStyle = "rgba(255,255,255,0.85)";
  ctx.beginPath();
  ctx.ellipse(x - size * 0.18, y - size * 0.22, size * 0.12, size * 0.06, -0.6, 0, Math.PI * 2);
  ctx.fill();
  ctx.restore();
}

export function paintRing(ctx, x, y, radius, time) {
  ctx.save();
  ctx.translate(x, y);
  ctx.rotate(time / 900);
  ctx.strokeStyle = "rgba(255, 228, 150, 0.95)";
  ctx.lineWidth = Math.max(2, radius * 0.06);
  ctx.setLineDash([radius * 0.34, radius * 0.18]);
  ctx.beginPath();
  ctx.arc(0, 0, radius, 0, Math.PI * 2);
  ctx.stroke();
  ctx.restore();
}
