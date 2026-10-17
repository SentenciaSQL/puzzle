import { CHAPTERS, LEVELS, gemName, levelById } from "./levels.js";
import { comboLabel, STR } from "./i18n.js";
import { PRODUCTS, coinReward, grant, persist, resetSave, save, todayKey, trySpend } from "./state.js";
import { gemIcon } from "./sprites.js";
import { createGame } from "./game.js";
import { audio } from "./audio.js";

let lang = "en";
let game = null;
let activeLevel = null;
let returnScreen = "menu";
let modalRender = null;
let modalDismiss = true;
let toastTimer = 0;

const $ = (id) => document.getElementById(id);

function t(key) {
  return (STR[lang] && STR[lang][key]) || STR.en[key] || key;
}

function locale() {
  return lang === "es" ? "es" : "en";
}

function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[char]));
}

function playerName() {
  return save.name.trim() || t("keeper");
}

function totalStars() {
  return Object.values(save.levels).reduce((sum, entry) => sum + (entry.stars || 0), 0);
}

let logoSerial = 0;

function logoMarkup() {
  const gradientId = `logoBerry${logoSerial++}`;
  return `
    <div class="logo-lockup">
      <svg class="logo-mark" viewBox="0 0 86 86" aria-hidden="true">
        <ellipse cx="43" cy="72" rx="18" ry="6" fill="rgba(70,30,10,.28)"/>
        <circle cx="43" cy="46" r="24" fill="#ffc44d"/>
        <circle cx="43" cy="46" r="24" fill="url(#${gradientId})"/>
        <ellipse cx="34" cy="38" rx="8" ry="4.5" fill="rgba(255,255,255,.78)" transform="rotate(-24 34 38)"/>
        <path d="M43 24c6-8 16-7 14-1-6 1-10 5-14 1z" fill="#3aaa52"/>
        <defs>
          <radialGradient id="${gradientId}" cx="38%" cy="34%" r="70%">
            <stop offset="0" stop-color="#fff6cf"/>
            <stop offset="50%" stop-color="#ffc44d"/>
            <stop offset="100%" stop-color="#e08614"/>
          </radialGradient>
        </defs>
      </svg>
      <div class="wordmark"><span class="line-a">Glimmer</span><span class="line-b">GROVE</span></div>
    </div>`;
}

function avatarMarkup(id, size = 40) {
  const skins = [
    { bg: "#ffc44d", mark: `<ellipse cx="32" cy="46" rx="8" ry="4" fill="#e07a9a" opacity=".7"/>` },
    { bg: "#2ec9ae", mark: `<path d="M32 12c6-8 14-6 10 0-4 1-7 2-10 0z" fill="#e8ffe8"/>` },
    { bg: "#b388ff", mark: `<path d="M44 18a8 8 0 1 0 0 14 6 6 0 1 1 0-14z" fill="#fff6e8"/>` },
    { bg: "#ff7a45", mark: `<path d="M24 16c2 4 4 4 6 0-2 2-4 2-6 0zm10 0c2 4 4 4 6 0-2 2-4 2-6 0z" fill="#ffe08a"/>` },
  ];
  const skin = skins[id] || skins[0];
  return `<svg viewBox="0 0 64 64" width="${size}" height="${size}" aria-hidden="true"><circle cx="32" cy="32" r="30" fill="${skin.bg}"/>${skin.mark}<circle cx="24" cy="30" r="3.4" fill="#3a2410"/><circle cx="40" cy="30" r="3.4" fill="#3a2410"/><path d="M23 42c3.5 5 14.5 5 18 0" fill="none" stroke="#3a2410" stroke-width="2.6" stroke-linecap="round"/></svg>`;
}

function starRow(count) {
  return [0, 1, 2]
    .map((index) => `<svg viewBox="0 0 32 32"><use href="${index < count ? "#i-star" : "#i-star-dim"}"/></svg>`)
    .join("");
}

function bigStar() {
  return `<svg viewBox="0 0 32 32" width="64" height="64"><use href="#i-star"/></svg>`;
}

export function boot() {
  if (!localStorage.getItem("glimmer-grove-v1") && window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
    save.reduced = true;
  }
  if (!save.lang) {
    save.lang = (navigator.language || "en").toLowerCase().startsWith("es") ? "es" : "en";
    persist();
  }
  lang = save.lang;
  document.documentElement.lang = lang;
  document.documentElement.dataset.motion = save.reduced ? "reduce" : "full";
  audio.setSfx(save.sfx);
  audio.setMusic(save.music);
  document.querySelectorAll(".logo-slot, #loader-logo").forEach((node) => {
    node.innerHTML = logoMarkup();
  });
  buildFruits();
  applyText();
  refreshWallet(false);
  renderMenuCard();
  const canvas = $("board");
  game = createGame(canvas, {
    onReady: () => renderHud(),
    onChange: () => renderHud(),
    onCombo: (combo) => showCombo(combo),
    onGoal: (index) => pulseGoal(index),
    onWin: (info) => openWin(info),
    onLose: (info) => openLose(info),
    onAim: (kind) => setAim(kind),
    onStatus: (kind) => setStatus(kind),
    onConsume: (kind) => consumeBooster(kind),
    sfx: (name, detail) => audio.play(name, detail),
  });
  game.setReduced(save.reduced);
  bind();
  new ResizeObserver(() => {
    if (game?.grid && game.visible) game.resize();
  }).observe($("board-stage"));
  const started = performance.now();
  const reveal = () => {
    const wait = Math.max(0, 700 - (performance.now() - started));
    setTimeout(() => show("menu"), wait);
  };
  if (document.fonts?.ready) document.fonts.ready.then(reveal);
  else reveal();
  requestAnimationFrame(loop);
  window.__grove = { game, save, show, debugWin, debugLose };
}

function loop(now) {
  const dt = Math.min(34, now - (loop.last || now));
  loop.last = now;
  if (game) {
    game.update(dt);
    game.draw();
  }
  requestAnimationFrame(loop);
}

function bind() {
  document.body.addEventListener("pointerdown", () => audio.unlock(), { passive: true });
  document.body.addEventListener("click", (event) => {
    const button = event.target.closest("[data-action], [data-close], [data-level]");
    if (!button) return;
    if (button.dataset.close) {
      if (modalDismiss) closeModal();
      return;
    }
    if (button.dataset.level) {
      selectLevel(Number(button.dataset.level), button);
      return;
    }
    const action = button.dataset.action;
    if (action) handle(action, button);
  });
  window.addEventListener("keydown", (event) => {
    if (event.key !== "Escape") return;
    if ($("modal").classList.contains("open")) {
      if (modalDismiss) closeModal();
      return;
    }
    if ($("screen-game").classList.contains("active") && game && !game.over) openPause();
  });
}

function handle(action, button) {
  if (action === "play") openLevel(Math.min(save.unlocked, LEVELS.length));
  else if (action === "levels") show("map");
  else if (action === "shop") {
    returnScreen = currentScreen() === "game" ? "game" : returnScreen === "game" ? "game" : currentScreen() === "menu" ? "menu" : currentScreen();
    if (currentScreen() !== "shop") returnScreen = currentScreen() === "game" ? "game" : "menu";
    show("shop");
  } else if (action === "shop-game") {
    if (game?.busy) return;
    returnScreen = "game";
    show("shop");
  } else if (action === "rewards") show("rewards");
  else if (action === "settings") openSettings();
  else if (action === "profile") openProfile();
  else if (action === "menu") show("menu");
  else if (action === "back") show(returnScreen || "menu");
  else if (action === "pause") openPause();
  else if (action === "booster") onBooster(button.dataset.booster);
  else if (action === "claim") claimDaily();
  else if (action === "buy") buyProduct(button.dataset.product, button);
  else if (action === "lang") setLang(button.dataset.lang);
  else if (action === "sfx") toggle("sfx");
  else if (action === "music") toggle("music");
  else if (action === "motion") toggle("reduced");
  else if (action === "how") openHow();
  else if (action === "reset-ask") openReset();
  else if (action === "reset") {
    resetSave();
    lang = save.lang || lang;
    closeModal();
    renderMenuCard();
    refreshWallet(false);
    show("menu");
    toast(t("reset"));
  } else if (action === "save-name") saveProfile();
  else if (action === "avatar") {
    save.avatar = Number(button.dataset.avatar);
    persist();
    paintAvatar();
    document.querySelectorAll(".avatar-pick button").forEach((node) => node.classList.toggle("on", Number(node.dataset.avatar) === save.avatar));
  } else if (action === "intro-start") {
    save.tutorial = true;
    persist();
    closeModal();
  }
  else if (action === "resume") closeModal();
  else if (action === "retry") retryLevel();
  else if (action === "quit") {
    closeModal();
    game.suspend();
    show("map");
  } else if (action === "win-next") {
    closeModal();
    if (activeLevel.id < LEVELS.length) openLevel(activeLevel.id + 1);
    else show("map");
  } else if (action === "win-map" || action === "lose-map") {
    closeModal();
    game.suspend();
    show("map");
  } else if (action === "lose-token") continueMoves("token");
  else if (action === "lose-buy") continueMoves("coins");
}

function currentScreen() {
  return document.querySelector(".screen.active")?.id.replace("screen-", "") || "menu";
}

function show(name) {
  if (name === "map") renderMap();
  if (name === "shop") renderShop();
  if (name === "rewards") renderRewards();
  if (name === "menu") renderMenuCard();
  document.querySelectorAll(".screen").forEach((screen) => {
    const on = screen.id === `screen-${name}`;
    screen.classList.toggle("active", on);
    screen.setAttribute("aria-hidden", on ? "false" : "true");
  });
  if (game) {
    game.visible = name === "game";
    if (name === "game") requestAnimationFrame(() => game.resize());
  }
  applyText();
}

function applyText() {
  document.documentElement.lang = lang;
  document.querySelectorAll("[data-i18n]").forEach((node) => {
    node.textContent = t(node.dataset.i18n);
  });
  document.querySelectorAll("[data-i18n-aria]").forEach((node) => {
    node.setAttribute("aria-label", t(node.dataset.i18nAria));
  });
  document.querySelectorAll(".js-name").forEach((node) => {
    node.textContent = playerName();
  });
  paintAvatar();
  if (modalRender) modalRender();
}

function paintAvatar() {
  const slot = $("menu-avatar");
  if (slot) slot.innerHTML = avatarMarkup(save.avatar, 40);
}

function buildFruits() {
  const row = $("menu-fruits");
  row.innerHTML = "";
  for (let gem = 0; gem < 6; gem += 1) {
    const image = document.createElement("img");
    image.src = gemIcon(gem, null, 96);
    image.alt = gemName(gem, lang);
    row.appendChild(image);
  }
}

function refreshWallet(animate = true) {
  document.querySelectorAll(".js-coins").forEach((node) => {
    const next = save.coins;
    const prev = Number(node.dataset.n || 0);
    if (!animate || prev === next) {
      node.textContent = next.toLocaleString(locale());
      node.dataset.n = String(next);
      return;
    }
    const started = performance.now();
    const step = (now) => {
      const progress = Math.min(1, (now - started) / 480);
      const value = Math.round(prev + (next - prev) * (1 - (1 - progress) ** 3));
      node.textContent = value.toLocaleString(locale());
      if (progress < 1) requestAnimationFrame(step);
      else node.dataset.n = String(next);
    };
    requestAnimationFrame(step);
    node.parentElement?.classList.add("bump");
    setTimeout(() => node.parentElement?.classList.remove("bump"), 420);
  });
}

function renderMenuCard() {
  const nextId = Math.min(save.unlocked, LEVELS.length);
  const level = levelById(nextId);
  $("menu-next").textContent = `${CHAPTERS[level.chapter].name[lang]} · ${t("level")} ${level.id}`;
  $("stat-level").textContent = String(nextId);
  $("stat-stars").textContent = String(totalStars());
}

function renderMap() {
  const host = $("map-scroll");
  let chapter = -1;
  const pieces = [];
  LEVELS.forEach((level, index) => {
    if (level.chapter !== chapter) {
      chapter = level.chapter;
      const info = CHAPTERS[chapter];
      pieces.push(`<div class="chapter-sign"><strong>${escapeHtml(info.name[lang])}</strong><span>${escapeHtml(info.blurb[lang])}</span></div>`);
    }
    const side = ["mid", "left", "mid", "right"][index % 4];
    const unlocked = level.id <= save.unlocked;
    const record = save.levels[level.id];
    const current = level.id === save.unlocked;
    pieces.push(`
      <div class="node-wrap ${side}">
        <div class="node-col">
          <button type="button" class="level-node ${unlocked ? "" : "locked"} ${current ? "current" : ""}" data-level="${level.id}" aria-label="${t("level")} ${level.id}">
            ${unlocked ? level.id : `<svg width="22" height="22"><use href="#i-lock"/></svg>`}
          </button>
          <div class="stars-mini">${unlocked ? starRow(record?.stars || 0) : ""}</div>
        </div>
      </div>`);
  });
  host.innerHTML = pieces.join("");
  const currentNode = host.querySelector(".level-node.current");
  if (currentNode) currentNode.scrollIntoView({ block: "center" });
}

function selectLevel(id, button) {
  if (id > save.unlocked) {
    button.classList.add("shake");
    audio.play("invalid");
    setTimeout(() => button.classList.remove("shake"), 360);
    return;
  }
  openLevel(id);
}

function openLevel(id) {
  activeLevel = levelById(id);
  show("game");
  game.visible = true;
  requestAnimationFrame(() => {
    game.load(activeLevel, (Date.now() + id * 17) % 100000);
    openIntro();
  });
}

function retryLevel() {
  closeModal();
  if (activeLevel) openLevel(activeLevel.id);
}

function renderHud() {
  if (!game?.level) return;
  const status = game.snapshot();
  const score = status.score.toLocaleString(locale());
  $("score-value").textContent = score;
  $("score-mobile").textContent = score;
  $("moves-value").textContent = String(status.moves);
  $("moves-orb").classList.toggle("low", status.moves > 0 && status.moves <= 5);
  $("game-level").textContent = `${t("level")} ${status.level.id}`;
  $("game-chapter").textContent = CHAPTERS[status.level.chapter].name[lang];
  $("goal-list").innerHTML = status.goals
    .map((goal, index) => {
      const done = goalComplete(goal, status.score, status.collected);
      if (goal.type === "score") {
        const have = Math.min(status.score, goal.target);
        return `<div class="goal-chip ${done ? "done" : ""}" data-goal="${index}"><span class="star-badge"><svg width="28" height="28"><use href="#i-star"/></svg></span><span><small>${t("scoreGoal")}</small><strong>${have.toLocaleString(locale())}/${goal.target.toLocaleString(locale())}</strong></span></div>`;
      }
      const have = Math.min(goal.target, status.collected[goal.gem] || 0);
      return `<div class="goal-chip ${done ? "done" : ""}" data-goal="${index}"><img src="${gemIcon(goal.gem, null, 72)}" alt=""><span><small>${escapeHtml(gemName(goal.gem, lang))}</small><strong>${have}/${goal.target}</strong></span></div>`;
    })
    .join("");
  const max = status.level.stars[2] || 1;
  $("star-fill").style.width = `${Math.max(0, Math.min(1, status.score / max)) * 100}%`;
  $("star-track").querySelectorAll(".mark").forEach((mark, index) => {
    mark.style.left = `${(status.level.stars[index] / max) * 100}%`;
    mark.classList.toggle("lit", status.score >= status.level.stars[index]);
  });
  renderBoosters();
}

function goalComplete(goal, score, collected) {
  if (goal.type === "score") return score >= goal.target;
  return (collected[goal.gem] || 0) >= goal.target;
}

function renderBoosters() {
  const aim = game?.aim;
  const items = [
    ["hammer", "i-hammer", t("hammer")],
    ["shuffle", "i-shuffle", t("shuffle")],
    ["extra", "i-plus", t("extra")],
  ];
  $("booster-row").innerHTML = items
    .map(
      ([id, icon, label]) => `
      <button type="button" class="booster ${save.boosters[id] ? "" : "is-empty"} ${aim === id ? "is-armed" : ""}" data-action="booster" data-booster="${id}">
        <span class="count">${save.boosters[id]}</span>
        <svg viewBox="0 0 32 32"><use href="#${icon}"/></svg>
        <small>${label}</small>
      </button>`,
    )
    .join("");
}

function onBooster(id) {
  if (!game || game.over) return;
  if (game.aim === id) {
    game.cancelAim();
    return;
  }
  if ((save.boosters[id] || 0) <= 0) {
    toast(t("need"));
    return;
  }
  if (game.busy && id !== "extra") return;
  if (id === "extra") {
    save.boosters.extra -= 1;
    persist();
    game.grantMoves(5);
    renderBoosters();
    refreshWallet(false);
    audio.play("special");
    return;
  }
  game.arm(id);
}

function consumeBooster(id) {
  if ((save.boosters[id] || 0) <= 0) return;
  save.boosters[id] -= 1;
  persist();
  renderBoosters();
}

function showCombo(combo) {
  const banner = $("combo-banner");
  banner.textContent = comboLabel(combo, lang);
  banner.classList.remove("show");
  void banner.offsetWidth;
  banner.classList.add("show");
}

function setStatus(kind) {
  const banner = $("status-banner");
  banner.textContent = kind === "shuffle" ? t("shuffling") : t("aurora");
  banner.classList.add("show");
  clearTimeout(banner._timer);
  banner._timer = setTimeout(() => banner.classList.remove("show"), 1200);
}

function setAim(kind) {
  const banner = $("status-banner");
  if (kind === "hammer") {
    banner.textContent = t("aimHammer");
    banner.classList.add("show");
  } else banner.classList.remove("show");
  renderBoosters();
}

function pulseGoal(index) {
  const chip = document.querySelector(`[data-goal="${index}"]`);
  if (!chip) return;
  chip.classList.add("pop", "done");
  audio.play("coin");
}

function openIntro() {
  const level = activeLevel;
  const record = save.levels[level.id];
  const goals = level.goals
    .map((goal) => {
      if (goal.type === "score") {
        return `<div class="goal-chip"><span class="star-badge"><svg width="28" height="28"><use href="#i-star"/></svg></span><span><small>${t("scoreGoal")}</small><strong>${goal.target.toLocaleString(locale())}</strong></span></div>`;
      }
      return `<div class="goal-chip"><img src="${gemIcon(goal.gem, null, 72)}" alt=""><span><small>${escapeHtml(gemName(goal.gem, lang))}</small><strong>${goal.target}</strong></span></div>`;
    })
    .join("");
  openModal(
    () => {
      $("modal-body").innerHTML = `
        <p class="sub">${escapeHtml(CHAPTERS[level.chapter].name[lang])}</p>
        <h2 id="modal-title">${t("level")} ${level.id}</h2>
        <div class="intro-goals">${goals}</div>
        <p class="sub">${t("moves")}: <strong>${level.moves}</strong>${record ? ` · ${t("best")} ${record.best.toLocaleString(locale())}` : ""}</p>
        ${level.id === 1 && !save.tutorial ? `<p class="sub">${t("tutorial")}</p>` : ""}
        ${level.ice.length ? `<p class="sub">${t("iceTip")}</p>` : ""}
        <button class="btn btn-primary" type="button" data-action="intro-start" style="width:100%">${t("start")}</button>`;
    },
    false,
  );
}

function openPause() {
  openModal(() => {
    $("modal-body").innerHTML = `
      <h2 id="modal-title">${t("pause")}</h2>
      <p class="sub">${t("level")} ${activeLevel?.id || ""}</p>
      <div class="btn-row" style="flex-direction:column">
        <button class="btn btn-primary" type="button" data-action="resume">${t("resume")}</button>
        <button class="btn btn-glass" type="button" data-action="retry">${t("retry")}</button>
        <button class="btn btn-ghost" type="button" data-action="quit">${t("map")}</button>
      </div>`;
  }, true);
}

function openWin(info) {
  const id = activeLevel.id;
  const previous = save.levels[id];
  const first = !previous;
  const stars = info.stars;
  const coins = coinReward(stars, first);
  save.levels[id] = { stars: Math.max(stars, previous?.stars || 0), best: Math.max(info.score, previous?.best || 0) };
  if (id >= save.unlocked && id < LEVELS.length) save.unlocked = id + 1;
  if (id === LEVELS.length) save.unlocked = LEVELS.length;
  save.coins += coins;
  persist();
  audio.play("win");
  refreshWallet(true);
  renderMenuCard();
  const chapterEnd = id === 8 || id === 16 || id === 24;
  const nextLabel = id < LEVELS.length ? t("next") : t("done");
  openModal(() => {
    $("modal-card").classList.add("win");
    $("modal-body").innerHTML = `
      <div class="rays" aria-hidden="true"></div>
      <div class="win-stars">
        ${[1, 2, 3].map((n) => `<div class="win-star ${n <= stars ? "earned" : ""}" style="animation-delay:${n * 140}ms">${bigStar()}</div>`).join("")}
      </div>
      <h2 id="modal-title">${t("winTitle")}</h2>
      <p class="sub">${chapterEnd ? t("chapterDone") : t("winSub")}</p>
      <div class="score-hero">${info.score.toLocaleString(locale())}</div>
      <div class="reward-pills">
        <span><svg width="22" height="22"><use href="#i-coin"/></svg> +${coins}</span>
        ${first ? `<span>${t("first")}</span>` : ""}
      </div>
      <div class="btn-row" style="flex-direction:column">
        <button class="btn btn-primary" type="button" data-action="win-next">${nextLabel}</button>
        <button class="btn btn-glass" type="button" data-action="retry">${t("retry")}</button>
        <button class="btn btn-ghost" type="button" data-action="win-map">${t("map")}</button>
      </div>`;
    burstConfetti($("modal-card"));
  }, false);
}

function openLose(info) {
  audio.play("lose");
  const goals = activeLevel.goals
    .map((goal) => {
      const have = goal.type === "score" ? info.score : info.collected[goal.gem] || 0;
      const pct = Math.max(0, Math.min(100, (have / goal.target) * 100));
      const label = goal.type === "score" ? t("scoreGoal") : gemName(goal.gem, lang);
      return `<div class="goal-meter"><div class="label"><span>${escapeHtml(label)}</span><span>${Math.min(have, goal.target)}/${goal.target}</span></div><div class="bar"><i style="width:${pct}%"></i></div></div>`;
    })
    .join("");
  const token = save.boosters.extra > 0;
  const afford = save.coins >= 160;
  openModal(() => {
    $("modal-card").classList.add("lose");
    $("modal-body").innerHTML = `
      <div class="dim-orb" aria-hidden="true"></div>
      <h2 id="modal-title">${t("loseTitle")}</h2>
      <p class="sub">${t("loseSub")}</p>
      ${goals}
      <div class="btn-row" style="flex-direction:column;margin-top:12px">
        ${token ? `<button class="btn btn-primary" type="button" data-action="lose-token">${t("continueCost")}</button>` : ""}
        <button class="btn ${token ? "btn-glass" : "btn-primary"} ${afford ? "" : "is-broke"}" type="button" data-action="lose-buy" ${afford ? "" : "disabled"}>${afford ? t("buyMoves") : t("need")}</button>
        <button class="btn btn-glass" type="button" data-action="retry">${t("retry")}</button>
        <button class="btn btn-ghost" type="button" data-action="lose-map">${t("map")}</button>
      </div>`;
  }, false);
}

function continueMoves(via) {
  if (via === "token") {
    if (save.boosters.extra <= 0) return;
    save.boosters.extra -= 1;
    persist();
  } else if (!trySpend(160)) {
    toast(t("need"));
    return;
  }
  closeModal();
  game.grantMoves(5);
  renderBoosters();
  refreshWallet(true);
  audio.play("special");
}

function renderShop() {
  $("shop-grid").innerHTML = PRODUCTS.map((product) => {
    const broke = save.coins < product.cost;
    const ownedBits = Object.entries(product.grant)
      .map(([key, count]) => `${t(key === "extra" ? "extra" : key)} ×${save.boosters[key] || 0}`)
      .join(" · ");
    return `
      <article class="product panel" data-product-card="${product.id}">
        <div class="product-art">${productArt(product.art)}</div>
        <div>
          <h3>${t(product.id === "basket" ? "basket" : product.id === "extra" ? "extra" : product.id)}</h3>
          <p>${t(product.id === "basket" ? "basketDesc" : `${product.id}Desc`)}</p>
          <div style="display:flex;align-items:center;justify-content:space-between;gap:8px;flex-wrap:wrap">
            <span class="price"><svg width="22" height="22"><use href="#i-coin"/></svg> ${product.cost}</span>
            <button class="btn ${broke ? "btn-glass is-broke" : "btn-primary"}" type="button" data-action="buy" data-product="${product.id}">${broke ? t("need") : t("buy")}</button>
          </div>
          <div class="owned-note">${ownedBits}</div>
        </div>
      </article>`;
  }).join("");
}

function productArt(kind) {
  if (kind === "hammer") return `<svg width="56" height="56" viewBox="0 0 32 32"><use href="#i-hammer"/></svg>`;
  if (kind === "shuffle") return `<svg width="56" height="56" viewBox="0 0 32 32"><use href="#i-shuffle"/></svg>`;
  if (kind === "extra") return `<svg width="56" height="56" viewBox="0 0 32 32"><use href="#i-plus"/></svg>`;
  return `<svg width="56" height="56" viewBox="0 0 32 32"><use href="#i-gift"/></svg>`;
}

function buyProduct(id, button) {
  const product = PRODUCTS.find((entry) => entry.id === id);
  if (!product) return;
  if (!trySpend(product.cost)) {
    button.closest(".product")?.classList.add("shake");
    toast(t("need"));
    audio.play("invalid");
    setTimeout(() => button.closest(".product")?.classList.remove("shake"), 360);
    return;
  }
  grant(product.grant, 0);
  audio.play("coin");
  toast(t("bought"));
  renderShop();
  refreshWallet(true);
  renderBoosters();
}

function renderRewards() {
  const ready = save.daily !== todayKey();
  $("chest").classList.toggle("open", !ready);
  $("chest-copy").textContent = ready ? t("giftGot") : t("tomorrow");
  const claim = $("btn-claim");
  claim.textContent = ready ? t("claim") : t("claimed");
  claim.disabled = !ready;
  const cleared = Object.keys(save.levels).length;
  $("album-stats").innerHTML = `
    <div class="stat"><b>${cleared}</b><span>${t("levels")}</span></div>
    <div class="stat"><b>${totalStars()}</b><span>${t("stars")}</span></div>
    <div class="stat"><b>${save.coins}</b><span>${t("coins")}</span></div>`;
}

function claimDaily() {
  if (save.daily === todayKey()) return;
  save.daily = todayKey();
  grant({ hammer: 1 }, 100);
  audio.play("win");
  toast(t("giftGot"));
  renderRewards();
  refreshWallet(true);
  renderBoosters();
}

function openSettings() {
  openModal(() => {
    $("modal-body").innerHTML = `
      <h2 id="modal-title">${t("settings")}</h2>
      <div class="toggle-list">
        ${switchRow("music", t("music"), save.music)}
        ${switchRow("sfx", t("sound"), save.sfx)}
        ${switchRow("motion", t("motion"), save.reduced)}
      </div>
      <div class="sub" style="text-align:left">${t("language")}</div>
      <div class="lang-switch">
        <button class="btn ${lang === "en" ? "btn-primary" : "btn-glass"}" type="button" data-action="lang" data-lang="en">English</button>
        <button class="btn ${lang === "es" ? "btn-primary" : "btn-glass"}" type="button" data-action="lang" data-lang="es">Español</button>
      </div>
      <div class="btn-row" style="flex-direction:column">
        <button class="btn btn-glass" type="button" data-action="how">${t("how")}</button>
        <button class="btn btn-ghost" type="button" data-action="reset-ask">${t("reset")}</button>
      </div>`;
  }, true);
}

function switchRow(action, label, on) {
  return `<div class="toggle"><span>${label}</span><button class="switch ${on ? "on" : ""}" type="button" data-action="${action}" aria-pressed="${on}"><i></i></button></div>`;
}

function toggle(key) {
  if (key === "reduced") {
    save.reduced = !save.reduced;
    document.documentElement.dataset.motion = save.reduced ? "reduce" : "full";
    game?.setReduced(save.reduced);
  } else if (key === "sfx") {
    save.sfx = !save.sfx;
    audio.setSfx(save.sfx);
  } else if (key === "music") {
    save.music = !save.music;
    audio.setMusic(save.music);
    if (save.music) audio.unlock();
  }
  persist();
  if (modalRender) modalRender();
}

function setLang(next) {
  lang = next;
  save.lang = next;
  persist();
  document.documentElement.lang = lang;
  buildFruits();
  applyText();
  renderMenuCard();
  if (game?.level) renderHud();
  if ($("screen-map").classList.contains("active")) renderMap();
  if ($("screen-shop").classList.contains("active")) renderShop();
  if ($("screen-rewards").classList.contains("active")) renderRewards();
}

function openHow() {
  openModal(() => {
    $("modal-body").innerHTML = `
      <h2 id="modal-title">${t("how")}</h2>
      <div class="how-step"><img src="${gemIcon(0, null, 96)}" alt=""><p>${t("how1")}</p></div>
      <div class="how-step"><img src="${gemIcon(1, "lineH", 96)}" alt=""><p>${t("how2")}</p></div>
      <div class="how-step"><img src="${gemIcon(4, "bomb", 96)}" alt=""><p>${t("how3")}</p></div>
      <p class="sub">${t("iceTip")}</p>
      <button class="btn btn-primary" type="button" data-action="settings" style="width:100%">${t("back")}</button>`;
  }, true);
}

function openReset() {
  openModal(() => {
    $("modal-body").innerHTML = `
      <h2 id="modal-title">${t("reset")}</h2>
      <p class="sub">${t("resetAsk")}</p>
      <div class="btn-row">
        <button class="btn btn-glass" type="button" data-action="settings">${t("cancel")}</button>
        <button class="btn btn-primary" type="button" data-action="reset">${t("confirm")}</button>
      </div>`;
  }, true);
}

function openProfile() {
  openModal(() => {
    $("modal-body").innerHTML = `
      <h2 id="modal-title">${t("profile")}</h2>
      <div class="sub">${t("avatar")}</div>
      <div class="avatar-pick">
        ${[0, 1, 2, 3]
          .map(
            (id) => `<button type="button" class="${id === save.avatar ? "on" : ""}" data-action="avatar" data-avatar="${id}">${avatarMarkup(id, 56)}</button>`,
          )
          .join("")}
      </div>
      <label class="sub" for="name-input">${t("yourName")}</label>
      <input id="name-input" class="name-field" maxlength="14" value="${escapeHtml(save.name)}" placeholder="${escapeHtml(t("keeper"))}" />
      <button class="btn btn-primary" type="button" data-action="save-name" style="width:100%">${t("saveName")}</button>`;
    setTimeout(() => $("name-input")?.focus(), 40);
  }, true);
}

function saveProfile() {
  const input = $("name-input");
  save.name = (input?.value || "").trim().slice(0, 14);
  persist();
  applyText();
  closeModal();
}

function openModal(render, dismiss) {
  modalDismiss = dismiss;
  modalRender = render;
  $("modal-card").classList.remove("win", "lose");
  $("modal-card").querySelectorAll(".confetti").forEach((node) => node.remove());
  $("modal").hidden = false;
  $("modal").classList.add("open");
  document.querySelector(".modal-x").hidden = !dismiss;
  render();
}

function closeModal() {
  $("modal").classList.remove("open");
  $("modal").hidden = true;
  modalRender = null;
  $("modal-card").classList.remove("win", "lose");
}

function toast(message) {
  const node = $("toast");
  node.textContent = message;
  node.classList.add("show");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => node.classList.remove("show"), 1800);
}

function burstConfetti(host) {
  host.querySelectorAll(".confetti").forEach((node) => node.remove());
  const colors = ["#ffc44d", "#ff6b9d", "#2ec9ae", "#b388ff", "#5eb6ff", "#ff7a45", "#fff6e8"];
  for (let i = 0; i < 26; i += 1) {
    const bit = document.createElement("i");
    bit.className = "confetti";
    bit.style.left = `${6 + Math.random() * 88}%`;
    bit.style.background = colors[i % colors.length];
    bit.style.animationDelay = `${Math.random() * 0.25}s`;
    bit.style.animationDuration = `${1.5 + Math.random() * 1.3}s`;
    host.appendChild(bit);
  }
}

function debugWin() {
  activeLevel = levelById(3);
  show("game");
  game.visible = true;
  if (!game.level) game.load(activeLevel, 7);
  openWin({ score: 4680, stars: 3, collected: { 0: 18 } });
}

function debugLose() {
  activeLevel = levelById(6);
  show("game");
  game.visible = true;
  if (!game.level) game.load(activeLevel, 11);
  openLose({ score: 980, collected: { 3: 7 } });
}
