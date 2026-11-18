(function (g) {
  if (g.IsoCore) return;

  const TW = 100;
  const TH = 50;
  const ZH = 50;

  const FALLBACK = {
    bg: '#0e0f10', surface: '#141516', 'surface-2': '#202122', 'surface-3': '#242526',
    hover: '#333334', border: '#333334', 'border-strong': '#3a3a3a', selection: '#3e3f40',
    'text-strong': '#e2e2e2', text: '#c1c1c1', 'text-2': '#959595', 'text-muted': '#666768',
    accent: '#fe8019', orange: '#fe8019', yellow: '#d79921', green: '#98971a',
    blue: '#458588', aqua: '#689d6a', red: '#cc241d', gray: '#a7a7a7',
  };
  const TONES = ['accent', 'orange', 'yellow', 'green', 'blue', 'aqua', 'red', 'gray', 'text', 'text-2'];

  function palette(el) {
    const cs = el && typeof getComputedStyle === 'function' ? getComputedStyle(el) : null;
    const out = {};
    for (const k in FALLBACK) {
      const v = cs ? cs.getPropertyValue('--' + k).trim() : '';
      out[k] = v || FALLBACK[k];
    }
    return out;
  }

  function tone(pal, name, dflt) {
    return pal[name] || pal[dflt] || pal.accent;
  }

  function project(x, y, z) {
    return [(x - y) * TW / 2, (x + y) * TH / 2 - (z || 0) * ZH];
  }

  const edgeId = (e) => e.id || `${e.from}->${e.to}`;

  function normalize(scene) {
    const s = JSON.parse(JSON.stringify(scene));
    s.nodes = (s.nodes || []).map((n) => ({ z: 0, scale: 1, ...n }));
    s.groups = s.groups || [];
    s.edges = (s.edges || []).map((e) => ({ route: 'xy', ...e, id: edgeId(e) }));
    s.steps = s.steps || [];
    if (!s.grid) {
      let w = 1, h = 1;
      for (const n of s.nodes) { w = Math.max(w, n.at[0] + 1); h = Math.max(h, n.at[1] + 1); }
      for (const gr of s.groups) { w = Math.max(w, gr.to[0] + 1); h = Math.max(h, gr.to[1] + 1); }
      s.grid = { w: w + 1, h: h + 1 };
    }
    return s;
  }

  function validate(scene, icons) {
    const errors = [];
    const warnings = [];
    const ids = new Set();
    const tiles = new Map();
    const nodes = scene.nodes || [];
    for (const n of nodes) {
      if (!n.id) { errors.push('node without id'); continue; }
      if (ids.has(n.id)) errors.push(`duplicate id "${n.id}"`);
      ids.add(n.id);
      if (!Array.isArray(n.at) || n.at.length !== 2 || !n.at.every(Number.isFinite)) {
        errors.push(`node "${n.id}": "at" must be [x, y] numbers`);
        continue;
      }
      if (n.icon && icons && !icons[n.icon]) warnings.push(`node "${n.id}": unknown icon "${n.icon}", drawing a plain block`);
      const key = `${n.at[0]},${n.at[1]},${n.z || 0}`;
      if (tiles.has(key)) warnings.push(`nodes "${tiles.get(key)}" and "${n.id}" share tile ${key}`);
      tiles.set(key, n.id);
      if (n.tone && !TONES.includes(n.tone)) warnings.push(`node "${n.id}": unknown tone "${n.tone}"`);
    }
    for (const gr of scene.groups || []) {
      if (!gr.id) errors.push('group without id');
      else if (ids.has(gr.id)) errors.push(`duplicate id "${gr.id}"`);
      else ids.add(gr.id);
      if (!Array.isArray(gr.from) || !Array.isArray(gr.to)) errors.push(`group "${gr.id}": needs "from" and "to"`);
      else if (gr.from[0] > gr.to[0] || gr.from[1] > gr.to[1]) errors.push(`group "${gr.id}": "from" must be the top-left tile, "to" the bottom-right one`);
    }
    for (const e of scene.edges || []) {
      const id = edgeId(e);
      if (!ids.has(e.from)) errors.push(`edge "${id}": unknown node "${e.from}"`);
      if (!ids.has(e.to)) errors.push(`edge "${id}": unknown node "${e.to}"`);
      if (e.route && !['xy', 'yx', 'straight'].includes(e.route)) errors.push(`edge "${id}": route must be xy, yx or straight`);
      if (ids.has(id) && e.id) errors.push(`duplicate id "${id}"`);
      ids.add(id);
    }
    (scene.steps || []).forEach((st, i) => {
      for (const k of ['show', 'hide', 'active']) {
        for (const ref of st[k] || []) {
          if (!ids.has(ref)) errors.push(`step ${i + 1}: "${k}" references unknown id "${ref}"`);
        }
      }
    });
    return { errors, warnings };
  }

  function route(scene, e) {
    const byId = new Map(scene.nodes.map((n) => [n.id, n]));
    const a = byId.get(e.from);
    const b = byId.get(e.to);
    const ax = a.at[0] + 0.5, ay = a.at[1] + 0.5, bx = b.at[0] + 0.5, by = b.at[1] + 0.5;
    const z = Math.min(a.z || 0, b.z || 0);
    let pts;
    if (e.route === 'straight' || ax === bx || ay === by) pts = [[ax, ay], [bx, by]];
    else if (e.route === 'yx') pts = [[ax, ay], [ax, by], [bx, by]];
    else pts = [[ax, ay], [bx, ay], [bx, by]];
    return { pts, z };
  }

  function stepState(scene, index) {
    const all = new Set([
      ...scene.nodes.map((n) => n.id),
      ...scene.groups.map((gr) => gr.id),
    ]);
    if (!scene.steps.length || index < 0) {
      return { visible: withEdges(scene, all), active: new Set(), caption: '' };
    }
    const visible = new Set();
    for (let i = 0; i <= index; i++) {
      const st = scene.steps[i];
      (st.show || []).forEach((id) => visible.add(id));
      (st.hide || []).forEach((id) => visible.delete(id));
    }
    const st = scene.steps[index];
    return { visible: withEdges(scene, visible), active: new Set(st.active || []), caption: st.caption || '' };
  }

  function withEdges(scene, visible) {
    const out = new Set(visible);
    for (const e of scene.edges) {
      if (visible.has(e.from) && visible.has(e.to) && !visible.has('!' + e.id)) out.add(e.id);
    }
    return out;
  }

  const reducedMotion = () =>
    typeof matchMedia === 'function' && matchMedia('(prefers-reduced-motion: reduce)').matches;

  const CSS = `
.isod{position:relative;display:flex;flex-direction:column;background:var(--surface,#141516);border:1px solid var(--border,#333334);border-radius:var(--radius,10px);overflow:hidden;color:var(--text,#c1c1c1);font-family:'IBM Plex Sans',system-ui,sans-serif}
.isod-view{position:relative;height:var(--isod-h,clamp(320px,62vw,560px))}
.isod-stage{position:absolute;inset:0;touch-action:none;cursor:grab;outline:none}
.isod-stage.isod-drag{cursor:grabbing}
.isod-stage svg,.isod-stage canvas{display:block;width:100%;height:100%}
.isod-title{position:absolute;top:12px;left:14px;font:600 11px/1 'JetBrains Mono',ui-monospace,monospace;letter-spacing:.08em;text-transform:uppercase;color:var(--text-2,#959595);pointer-events:none}
.isod-tools{position:absolute;top:8px;right:8px;display:flex;gap:6px}
.isod button{font:600 12px/1 'JetBrains Mono',ui-monospace,monospace;background:var(--surface-3,#242526);color:var(--text,#c1c1c1);border:1px solid var(--border-strong,#3a3a3a);border-radius:6px;padding:7px 9px;min-width:30px;cursor:pointer}
.isod button:hover{background:var(--hover,#333334);color:var(--text-strong,#e2e2e2)}
.isod button:focus-visible{outline:2px solid var(--accent,#fe8019);outline-offset:1px}
.isod button[aria-pressed=true]{border-color:var(--accent,#fe8019);color:var(--accent,#fe8019)}
.isod button:disabled{opacity:.4;cursor:default}
.isod-attr{position:absolute;bottom:8px;right:12px;font-size:11px;color:var(--text-muted,#666768);pointer-events:none}
.isod-hint{position:absolute;bottom:8px;left:12px;font-size:11px;color:var(--text-muted,#666768);pointer-events:none}
.isod-steps{display:flex;flex-wrap:wrap;align-items:center;gap:8px 10px;padding:10px 12px;border-top:1px solid var(--border,#333334);background:var(--surface-2,#202122)}
.isod-count{font:12px 'JetBrains Mono',ui-monospace,monospace;color:var(--text-2,#959595);font-variant-numeric:tabular-nums}
.isod-caption{flex:1 1 220px;font-size:14px;line-height:1.4;color:var(--text-strong,#e2e2e2)}
.isod-labels{position:absolute;inset:0;pointer-events:none;overflow:hidden}
.isod-label{position:absolute;transform:translate(-50%,0);white-space:nowrap;text-align:center;font-size:12px;line-height:1.25;color:var(--text,#c1c1c1);text-shadow:0 0 3px var(--surface,#141516),0 0 3px var(--surface,#141516);transition:opacity .35s}
.isod-label small{display:block;font-size:11px;color:var(--text-2,#959595)}
.isod-svg .isod-el{transition:opacity .45s ease,transform .45s ease}
.isod-svg .isod-off{opacity:0;transform:translateY(-14px);pointer-events:none}
.isod-svg .isod-pulse{transform-box:fill-box;transform-origin:center;animation:isod-pulse 1.8s ease-out infinite}
@keyframes isod-pulse{from{transform:scale(.55);opacity:.9}to{transform:scale(1.35);opacity:0}}
@media (prefers-reduced-motion:reduce){.isod-svg .isod-el{transition:none}.isod-svg .isod-pulse{animation:none;opacity:.6}}
`;

  function injectCss() {
    if (document.getElementById('isod-css')) return;
    const st = document.createElement('style');
    st.id = 'isod-css';
    st.textContent = CSS;
    document.head.appendChild(st);
  }

  function h(tag, attrs, parent, text) {
    const el = document.createElement(tag);
    for (const k in attrs || {}) el.setAttribute(k, attrs[k]);
    if (text != null) el.textContent = text;
    if (parent) parent.appendChild(el);
    return el;
  }

  // Builds the frame shared by both renderers; zoom/rotate handlers are wired by each renderer.
  function chrome(host, scene, opts) {
    injectCss();
    host.classList.add('isod');
    host.innerHTML = '';
    if (scene.height) host.style.setProperty('--isod-h', typeof scene.height === 'number' ? scene.height + 'px' : scene.height);
    const view = h('div', { class: 'isod-view' }, host);
    const stage = h('div', { class: 'isod-stage', tabindex: '0', 'aria-label': (scene.title || 'Diagram') + ', drag to pan' }, view);
    if (scene.title) h('div', { class: 'isod-title' }, view, scene.title);
    const tools = h('div', { class: 'isod-tools' }, view);
    const btn = (label, title) => h('button', { type: 'button', title, 'aria-label': title }, tools, label);
    const ui = { host, view, stage, tools };
    if (opts.rotate) {
      ui.rotate = btn('3D', 'Free rotation');
      ui.rotate.setAttribute('aria-pressed', 'false');
    }
    ui.zoomOut = btn('−', 'Zoom out');
    ui.zoomIn = btn('+', 'Zoom in');
    ui.reset = btn('↺', 'Reset view');
    if (opts.attribution) h('div', { class: 'isod-attr' }, view, opts.attribution);
    h('div', { class: 'isod-hint' }, view, 'drag to pan · ctrl+scroll to zoom');

    if (scene.steps.length) {
      const bar = h('div', { class: 'isod-steps' }, host);
      ui.prev = h('button', { type: 'button', 'aria-label': 'Previous step' }, bar, '◀');
      ui.play = h('button', { type: 'button', 'aria-label': 'Play steps', 'aria-pressed': 'false' }, bar, '▶');
      ui.next = h('button', { type: 'button', 'aria-label': 'Next step' }, bar, '▶▶');
      ui.count = h('span', { class: 'isod-count' }, bar);
      ui.caption = h('span', { class: 'isod-caption', 'aria-live': 'polite' }, bar);
    }
    return ui;
  }

  function stepper(scene, ui, apply) {
    const n = scene.steps.length;
    let i = n ? Math.max(0, Math.min(n - 1, (scene.startStep || 1) - 1)) : -1;
    let timer = null;
    const render = () => {
      const st = stepState(scene, i);
      apply(st);
      if (!n) return;
      ui.count.textContent = `${i + 1}/${n}`;
      ui.caption.textContent = st.caption;
      ui.prev.disabled = i === 0;
      ui.next.disabled = i === n - 1 && !timer;
    };
    const stop = () => {
      clearInterval(timer);
      timer = null;
      if (ui.play) { ui.play.textContent = '▶'; ui.play.setAttribute('aria-pressed', 'false'); }
    };
    const go = (k) => { i = Math.max(0, Math.min(n - 1, k)); render(); };
    if (n) {
      ui.prev.onclick = () => { stop(); go(i - 1); };
      ui.next.onclick = () => { stop(); go(i + 1); };
      ui.play.onclick = () => {
        if (timer) return stop();
        if (i === n - 1) go(0);
        ui.play.textContent = '❚❚';
        ui.play.setAttribute('aria-pressed', 'true');
        timer = setInterval(() => (i >= n - 1 ? (stop(), render()) : go(i + 1)), scene.stepMs || 2600);
        render();
      };
      ui.stage.addEventListener('keydown', (ev) => {
        if (ev.key === 'ArrowRight') { stop(); go(i + 1); }
        if (ev.key === 'ArrowLeft') { stop(); go(i - 1); }
      });
      if (scene.autoplay) ui.play.onclick();
    }
    render();
    return { go, stop };
  }

  function polyLength(pts) {
    let len = 0;
    for (let k = 1; k < pts.length; k++) len += Math.hypot(pts[k][0] - pts[k - 1][0], pts[k][1] - pts[k - 1][1]);
    return len;
  }

  function pointAt(pts, d) {
    for (let k = 1; k < pts.length; k++) {
      const [x0, y0] = pts[k - 1];
      const [x1, y1] = pts[k];
      const seg = Math.hypot(x1 - x0, y1 - y0);
      if (d <= seg || k === pts.length - 1) {
        const t = seg ? Math.min(1, d / seg) : 0;
        return [x0 + (x1 - x0) * t, y0 + (y1 - y0) * t];
      }
      d -= seg;
    }
    return pts[pts.length - 1];
  }

  g.IsoCore = {
    TW, TH, ZH, TONES, palette, tone, project, normalize, validate, route,
    stepState, reducedMotion, chrome, stepper, polyLength, pointAt, h,
  };
})(typeof window !== 'undefined' ? window : globalThis);
