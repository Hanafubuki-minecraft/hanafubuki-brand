// Падающие лепестки сакуры на canvas.
// Форма лепестка — та же, что в логотипе (src/logo.svg, <path id="petal">).
const PETAL = new Path2D(
  'M0,0 C-24,-10 -44,-46 -38,-76 C-35,-93 -20,-104 -9,-99 L0,-86 L9,-99 C20,-104 35,-93 38,-76 C44,-46 24,-10 0,0 Z',
);
const COLORS = ['#F7A1C0', '#FFE1EC', '#E4628F', '#F7A1C0'];

interface Petal {
  x: number; y: number; s: number; r: number; spin: number;
  vy: number; vx: number; phase: number; sway: number; flip: number; color: string; alpha: number;
}

export function startPetals(canvas: HTMLCanvasElement) {
  const ctx = canvas.getContext('2d');
  if (!ctx) return;

  const nav = navigator as Navigator & { deviceMemory?: number };
  const weak = (nav.hardwareConcurrency ?? 8) <= 4 || (nav.deviceMemory ?? 8) <= 4;
  const motion = window.matchMedia('(prefers-reduced-motion: reduce)');

  let w = 0, h = 0, dpr = 1;
  let petals: Petal[] = [];
  let raf = 0, last = 0;
  let visible = true;

  const rand = (a: number, b: number) => a + Math.random() * (b - a);

  const make = (anywhere: boolean): Petal => ({
    x: rand(-0.1, 1.05) * w,
    y: anywhere ? rand(0, h) : rand(-60, -20),
    s: rand(0.07, 0.16) * (w < 600 ? 0.85 : 1),
    r: rand(0, Math.PI * 2),
    spin: rand(-0.6, 0.6),
    vy: rand(18, 42),
    vx: rand(6, 22),
    phase: rand(0, Math.PI * 2),
    sway: rand(0.6, 1.4),
    flip: rand(0, Math.PI * 2),
    color: COLORS[(Math.random() * COLORS.length) | 0],
    alpha: rand(0.45, 0.9),
  });

  const resize = () => {
    const rect = canvas.getBoundingClientRect();
    w = rect.width; h = rect.height;
    dpr = Math.min(window.devicePixelRatio || 1, weak ? 1.5 : 2);
    canvas.width = Math.round(w * dpr);
    canvas.height = Math.round(h * dpr);
    // Меньше лепестков на маленьких экранах и слабых устройствах.
    let n = Math.round((w * h) / 26000);
    n = Math.max(10, Math.min(n, 48));
    if (weak) n = Math.round(n * 0.5);
    if (motion.matches) n = Math.round(n * 0.6);
    petals = Array.from({ length: n }, () => make(true));
    if (motion.matches) draw();
  };

  const draw = () => {
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, w, h);
    for (const p of petals) {
      ctx.save();
      ctx.translate(p.x, p.y);
      ctx.rotate(p.r);
      // Лепесток «кувыркается»: сжимаем по одной оси.
      ctx.scale(p.s * (0.35 + 0.65 * Math.abs(Math.cos(p.flip))), p.s);
      ctx.globalAlpha = p.alpha;
      ctx.fillStyle = p.color;
      ctx.fill(PETAL);
      ctx.restore();
    }
  };

  const step = (t: number) => {
    const dt = Math.min((t - last) / 1000, 0.05);
    last = t;
    for (let i = 0; i < petals.length; i++) {
      const p = petals[i];
      p.phase += dt * p.sway;
      p.flip += dt * p.sway * 1.6;
      p.r += dt * p.spin;
      p.x += (p.vx + Math.sin(p.phase) * 14) * dt;
      p.y += p.vy * dt;
      if (p.y > h + 30 || p.x > w + 40) petals[i] = make(false);
    }
    draw();
    raf = requestAnimationFrame(step);
  };

  const sync = () => {
    cancelAnimationFrame(raf);
    raf = 0;
    if (motion.matches) { draw(); return; }
    if (visible && !document.hidden) {
      last = performance.now();
      raf = requestAnimationFrame(step);
    }
  };

  new ResizeObserver(() => { resize(); sync(); }).observe(canvas);
  new IntersectionObserver(([e]) => { visible = e.isIntersecting; sync(); }).observe(canvas);
  document.addEventListener('visibilitychange', sync);
  motion.addEventListener?.('change', () => { resize(); sync(); });
}
