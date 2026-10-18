const NOTES = [293.66, 349.23, 392, 440, 523.25, 587.33];
const MELODY = [0, 2, 4, 2, 3, 4, 5, 3, 2, 1, 0, 2, 4, 3, 2, 0];

export const audio = {
  ctx: null,
  master: null,
  musicGain: null,
  sfxGain: null,
  sfxOn: true,
  musicOn: true,
  started: false,
  timer: 0,
  step: 0,

  unlock() {
    const Ctx = window.AudioContext || window.webkitAudioContext;
    if (!Ctx) return;
    if (!this.ctx) {
      this.ctx = new Ctx();
      this.master = this.ctx.createGain();
      this.master.gain.value = 0.9;
      this.master.connect(this.ctx.destination);
      this.sfxGain = this.ctx.createGain();
      this.sfxGain.gain.value = 0.8;
      this.sfxGain.connect(this.master);
      this.musicGain = this.ctx.createGain();
      this.musicGain.gain.value = 0.0;
      this.musicGain.connect(this.master);
      this.pad();
    }
    if (this.ctx.state === "suspended") this.ctx.resume();
    this.started = true;
    this.applyMusic();
  },

  setSfx(on) {
    this.sfxOn = on;
  },

  setMusic(on) {
    this.musicOn = on;
    this.applyMusic();
  },

  applyMusic() {
    if (!this.musicGain || !this.ctx) return;
    const target = this.musicOn && this.started ? 0.22 : 0;
    this.musicGain.gain.cancelScheduledValues(this.ctx.currentTime);
    this.musicGain.gain.linearRampToValueAtTime(target, this.ctx.currentTime + 0.3);
    if (this.musicOn && this.started && !this.timer) this.schedule();
    if (!this.musicOn && this.timer) {
      clearInterval(this.timer);
      this.timer = 0;
    }
  },

  pad() {
    const now = this.ctx.currentTime;
    for (const freq of [146.83, 220, 293.66]) {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      const filter = this.ctx.createBiquadFilter();
      osc.type = "sine";
      osc.frequency.value = freq;
      filter.type = "lowpass";
      filter.frequency.value = 640;
      gain.gain.value = 0.045;
      osc.connect(filter);
      filter.connect(gain);
      gain.connect(this.musicGain);
      osc.start(now);
    }
  },

  schedule() {
    if (this.timer || !this.ctx) return;
    this.timer = setInterval(() => this.pluck(), 420);
  },

  pluck() {
    if (!this.ctx || !this.musicOn) return;
    const freq = NOTES[MELODY[this.step % MELODY.length]];
    this.step += 1;
    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = "triangle";
    osc.frequency.value = freq;
    gain.gain.setValueAtTime(0.0001, now);
    gain.gain.exponentialRampToValueAtTime(0.06, now + 0.03);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.38);
    osc.connect(gain);
    gain.connect(this.musicGain);
    osc.start(now);
    osc.stop(now + 0.4);
  },

  tone(freq, dur, type, gainValue, slide) {
    if (!this.ctx || !this.sfxOn) return;
    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(freq, now);
    if (slide) osc.frequency.exponentialRampToValueAtTime(Math.max(40, slide), now + dur);
    gain.gain.setValueAtTime(0.0001, now);
    gain.gain.exponentialRampToValueAtTime(gainValue, now + 0.012);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + dur);
    osc.connect(gain);
    gain.connect(this.sfxGain);
    osc.start(now);
    osc.stop(now + dur + 0.02);
  },

  play(name, detail = 0) {
    if (!this.sfxOn) return;
    this.unlock();
    if (name === "tap") this.tone(620, 0.06, "sine", 0.05, 880);
    else if (name === "swap") this.tone(420, 0.07, "triangle", 0.06, 560);
    else if (name === "invalid") this.tone(180, 0.12, "sine", 0.05, 120);
    else if (name === "match") {
      const freq = NOTES[Math.min(NOTES.length - 1, 1 + detail)];
      this.tone(freq, 0.12, "triangle", 0.07, freq * 1.25);
      this.tone(freq * 2, 0.1, "sine", 0.03);
    } else if (name === "special") {
      this.tone(523, 0.14, "triangle", 0.07, 880);
      this.tone(784, 0.18, "sine", 0.04, 1174);
    } else if (name === "coin") {
      this.tone(880, 0.08, "sine", 0.05, 1320);
      setTimeout(() => this.tone(1174, 0.1, "sine", 0.04), 70);
    } else if (name === "win") {
      [523, 659, 784, 1046].forEach((freq, index) => {
        setTimeout(() => this.tone(freq, 0.18, "triangle", 0.06), index * 110);
      });
    } else if (name === "lose") {
      this.tone(392, 0.2, "sine", 0.05, 262);
      setTimeout(() => this.tone(311, 0.28, "triangle", 0.04, 196), 140);
    } else if (name === "hammer") this.tone(240, 0.1, "square", 0.03, 140);
    else if (name === "whoosh") this.tone(500, 0.16, "sine", 0.04, 180);
  },
};
