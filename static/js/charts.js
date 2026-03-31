(() => {
  function clamp(n, a, b) {
    return Math.max(a, Math.min(b, n));
  }

  function makeHiDpiCanvas(canvas) {
    const dpr = Math.max(1, Math.floor(window.devicePixelRatio || 1));
    const rect = canvas.getBoundingClientRect();
    const targetW = Math.max(1, Math.floor(rect.width * dpr));
    const targetH = Math.max(1, Math.floor(rect.height * dpr));
    if (canvas.width !== targetW) canvas.width = targetW;
    if (canvas.height !== targetH) canvas.height = targetH;
    const ctx = canvas.getContext("2d");
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    return ctx;
  }

  function drawCardBg(ctx, w, h) {
    ctx.clearRect(0, 0, w, h);
    const g = ctx.createLinearGradient(0, 0, w, h);
    g.addColorStop(0, "rgba(109,193,255,0.08)");
    g.addColorStop(0.5, "rgba(64,255,191,0.05)");
    g.addColorStop(1, "rgba(255,77,125,0.07)");
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, w, h);

    ctx.strokeStyle = "rgba(132,164,255,0.12)";
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.rect(0.5, 0.5, w - 1, h - 1);
    ctx.stroke();
  }

  function barChart(canvas, items, opts) {
    const ctx = makeHiDpiCanvas(canvas);
    const w = canvas.getBoundingClientRect().width;
    const h = canvas.getBoundingClientRect().height;
    drawCardBg(ctx, w, h);

    const pad = 14;
    const top = 18;
    const left = pad;
    const right = pad;
    const bottom = 30;
    const innerW = w - left - right;
    const innerH = h - top - bottom;

    const maxV = Math.max(1, ...items.map((x) => x.v));
    const n = Math.max(1, items.length);
    const gap = 10;
    const barW = clamp((innerW - gap * (n - 1)) / n, 10, 80);

    items.forEach((it, i) => {
      const x = left + i * (barW + gap);
      const t = it.v / maxV;
      const bh = Math.floor(innerH * t);
      const y = top + (innerH - bh);

      const g = ctx.createLinearGradient(0, y, 0, y + bh);
      g.addColorStop(0, it.c1);
      g.addColorStop(1, it.c2);
      ctx.fillStyle = g;
      ctx.fillRect(x, y, barW, bh);

      ctx.fillStyle = "rgba(240,246,255,0.86)";
      ctx.font = "900 12px ui-sans-serif, system-ui, Segoe UI, Roboto, Arial";
      ctx.fillText(String(it.v), x + 6, y - 6);

      ctx.fillStyle = "rgba(196,210,255,0.74)";
      ctx.font = "800 11px ui-sans-serif, system-ui, Segoe UI, Roboto, Arial";
      ctx.fillText(it.k, x + 2, h - 10);
    });

    if (opts && opts.subtitle) {
      ctx.fillStyle = "rgba(196,210,255,0.65)";
      ctx.font = "800 11px ui-sans-serif, system-ui, Segoe UI, Roboto, Arial";
      ctx.fillText(opts.subtitle, left, 14);
    }
  }

  function lineChart(canvas, points, colorA, colorB) {
    const ctx = makeHiDpiCanvas(canvas);
    const w = canvas.getBoundingClientRect().width;
    const h = canvas.getBoundingClientRect().height;
    drawCardBg(ctx, w, h);

    const pad = 14;
    const top = 20;
    const left = pad;
    const right = pad;
    const bottom = 28;
    const innerW = w - left - right;
    const innerH = h - top - bottom;

    const maxV = Math.max(1, ...points.map((p) => p.v));
    const n = Math.max(2, points.length);
    const stepX = innerW / (n - 1);

    ctx.strokeStyle = "rgba(132,164,255,0.10)";
    ctx.lineWidth = 1;
    for (let i = 0; i <= 4; i++) {
      const y = top + (innerH * i) / 4;
      ctx.beginPath();
      ctx.moveTo(left, y);
      ctx.lineTo(left + innerW, y);
      ctx.stroke();
    }

    const toX = (i) => left + i * stepX;
    const toY = (v) => top + (innerH - (innerH * v) / maxV);

    ctx.beginPath();
    points.forEach((p, i) => {
      const x = toX(i);
      const y = toY(p.v);
      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    });
    ctx.lineTo(toX(points.length - 1), top + innerH);
    ctx.lineTo(toX(0), top + innerH);
    ctx.closePath();
    const g = ctx.createLinearGradient(0, top, 0, top + innerH);
    g.addColorStop(0, colorA);
    g.addColorStop(1, "rgba(7,10,18,0.0)");
    ctx.fillStyle = g;
    ctx.fill();

    ctx.beginPath();
    points.forEach((p, i) => {
      const x = toX(i);
      const y = toY(p.v);
      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    });
    ctx.strokeStyle = colorB;
    ctx.lineWidth = 2.5;
    ctx.stroke();

    points.forEach((p, i) => {
      if (i % 3 !== 0 && i !== points.length - 1) return;
      const x = toX(i);
      const y = toY(p.v);
      ctx.fillStyle = "rgba(240,246,255,0.92)";
      ctx.beginPath();
      ctx.arc(x, y, 3.2, 0, Math.PI * 2);
      ctx.fill();
    });

  ctx.fillStyle = "rgba(196,210,255,0.65)";
  ctx.font = "800 11px ui-sans-serif, system-ui, Segoe UI, Roboto, Arial";
  const labelEvery = Math.max(1, Math.floor(points.length / 12));
  for (let i = 0; i < points.length; i++) {
    if (i % labelEvery !== 0 && i !== points.length - 1) continue;
    const label = points[i].t.slice(11, 16);
    ctx.fillText(label, toX(i) - 10, h - 10);
  }
}

  window.SentinelCharts = { barChart, lineChart };
})();
