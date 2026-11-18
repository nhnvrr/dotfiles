(function (g) {
  if (g.IsoSVG) return;
  const C = g.IsoCore;
  const NS = 'http://www.w3.org/2000/svg';
  let uid = 0;

  function s(tag, attrs, parent, text) {
    const el = document.createElementNS(NS, tag);
    for (const k in attrs || {}) if (attrs[k] != null) el.setAttribute(k, attrs[k]);
    if (text != null) el.textContent = text;
    if (parent) parent.appendChild(el);
    return el;
  }

  const P = (x, y, z) => C.project(x, y, z);
  const pt = (p) => p[0].toFixed(1) + ',' + p[1].toFixed(1);
  // Maps the ground plane onto screen; one plane unit is TW/2 = 50 grid units per tile.
  const plane = (x, y, z) => {
    const [px, py] = P(x, y, z);
    return `matrix(1 .5 -1 .5 ${px.toFixed(1)} ${py.toFixed(1)})`;
  };

  function mount(host, rawScene, icons, opts) {
    opts = opts || {};
    icons = icons || {};
    const scene = C.normalize(rawScene);
    const ui = C.chrome(host, scene, { rotate: false, attribution: opts.attribution });
    const pal = C.palette(host);
    const still = C.reducedMotion();
    const id = 'isod' + ++uid;

    const svg = s('svg', { class: 'isod-svg', role: 'img', 'aria-label': scene.title || 'Diagram', preserveAspectRatio: 'xMidYMid meet' }, ui.stage);
    const root = s('g', {}, svg);
    const layer = (name) => s('g', { class: 'isod-' + name }, root);
    const Lgrid = layer('grid');
    const Lgroups = layer('groups');
    const Ledges = layer('edges');
    const Lpackets = layer('packets');
    const Lnodes = layer('nodes');
    const Llabels = layer('labels');
    const els = new Map();
    const reg = (key, el) => { el.classList.add('isod-el'); (els.get(key) || els.set(key, []).get(key)).push(el); return el; };

    if (scene.gridLines !== false) {
      const { w, h } = scene.grid;
      let d = '';
      for (let x = 0; x <= w; x++) d += `M${pt(P(x, 0))}L${pt(P(x, h))}`;
      for (let y = 0; y <= h; y++) d += `M${pt(P(0, y))}L${pt(P(w, y))}`;
      s('path', { d, stroke: pal.border, 'stroke-width': 1, opacity: 0.45, fill: 'none' }, Lgrid);
    }

    for (const gr of scene.groups) {
      const [x0, y0] = gr.from;
      const x1 = gr.to[0] + 1, y1 = gr.to[1] + 1;
      const col = C.tone(pal, gr.tone, 'blue');
      const gEl = reg(gr.id, s('g', {}, Lgroups));
      s('polygon', {
        points: [P(x0, y0), P(x1, y0), P(x1, y1), P(x0, y1)].map(pt).join(' '),
        fill: col, 'fill-opacity': 0.07, stroke: col, 'stroke-opacity': 0.7, 'stroke-width': 1.5,
        'stroke-dasharray': gr.style === 'dashed' ? '6 5' : null,
      }, gEl);
      if (gr.label) {
        s('text', {
          transform: plane(x0, y0, 0), x: 10, y: 18, fill: col,
          'font-family': "'JetBrains Mono',ui-monospace,monospace", 'font-size': 13, 'font-weight': 600,
          'letter-spacing': '.06em',
        }, gEl, gr.label.toUpperCase());
      }
    }

    const nodeById = new Map(scene.nodes.map((n) => [n.id, n]));
    const edgeEls = new Map();
    for (const e of scene.edges) {
      const { pts, z } = C.route(scene, e);
      const scr = pts.map(([x, y]) => P(x, y, z));
      const d = 'M' + scr.map(pt).join('L');
      const pathId = `${id}-e-${edgeEls.size}`;
      const gEl = reg(e.id, s('g', {}, Ledges));
      const base = C.tone(pal, e.tone, 'border-strong');
      const path = s('path', {
        id: pathId, d, fill: 'none', stroke: e.tone ? base : pal['text-muted'], 'stroke-width': 2.5,
        'stroke-linecap': 'round', 'stroke-linejoin': 'round',
        'stroke-dasharray': e.style === 'dashed' ? '7 6' : null,
      }, gEl);
      if (e.label) {
        const mid = C.pointAt(scr, C.polyLength(scr) / 2);
        s('text', {
          x: mid[0], y: mid[1] - 8, 'text-anchor': 'middle', fill: pal['text-2'], 'font-size': 11,
          'font-family': "'JetBrains Mono',ui-monospace,monospace",
          stroke: pal.surface, 'stroke-width': 4, 'paint-order': 'stroke',
        }, gEl, e.label);
      }
      let packets = null;
      if (!still) {
        packets = s('g', { style: 'display:none' }, Lpackets);
        const cfg = e.packets || {};
        const col = C.tone(pal, cfg.tone, 'accent');
        const len = C.polyLength(scr);
        const dur = len / (cfg.speed || 140);
        const every = cfg.every || 1.1;
        const count = Math.max(1, Math.min(12, Math.floor(dur / every) || 1));
        for (let k = 0; k < count; k++) {
          const dot = s('g', {}, packets);
          s('circle', { r: 8, fill: col, opacity: 0.22 }, dot);
          s('circle', { r: 4.5, fill: col }, dot);
          const anim = s('animateMotion', {
            dur: dur.toFixed(2) + 's', repeatCount: 'indefinite', begin: (-k * every).toFixed(2) + 's',
            keyPoints: cfg.reverse ? '1;0' : '0;1', keyTimes: '0;1', calcMode: 'linear',
          }, dot);
          s('mpath', { href: '#' + pathId }, anim);
        }
      }
      edgeEls.set(e.id, { edge: e, path, packets, base: e.tone ? base : pal['text-muted'] });
    }

    const order = scene.nodes.slice().sort((a, b) => (a.at[0] + a.at[1]) - (b.at[0] + b.at[1]) || a.z - b.z);
    const nodeEls = new Map();
    for (const n of order) {
      const [x, y] = n.at;
      const z = n.z;
      const icon = icons[n.icon];
      const gEl = reg(n.id, s('g', {}, Lnodes));
      const [cx, cy] = P(x + 0.5, y + 0.5, z);
      const col = C.tone(pal, n.tone, 'accent');

      const ring = s('ellipse', { cx, cy, rx: 36, ry: 18, fill: 'none', stroke: col, 'stroke-width': 2, opacity: 0 }, gEl);
      if (n.pulse && !still) {
        s('ellipse', { cx, cy, rx: 40, ry: 20, fill: 'none', stroke: col, 'stroke-width': 2, class: 'isod-pulse' }, gEl);
      }

      let bottom;
      if (icon && icon.iso) {
        const w = C.TW * 0.8 * n.scale;
        const h = w * (icon.h / icon.w);
        bottom = cy + w / 4;
        s('image', { href: icon.url, x: cx - w / 2, y: bottom - h, width: w, height: h }, gEl);
      } else {
        const ph = 0.3;
        const a = 0.12, b = 0.88;
        const top = [P(x + a, y + a, z + ph), P(x + b, y + a, z + ph), P(x + b, y + b, z + ph), P(x + a, y + b, z + ph)];
        const bot = [P(x + b, y + a, z), P(x + b, y + b, z), P(x + a, y + b, z)];
        s('polygon', { points: [top[1], top[2], bot[1], bot[0]].map(pt).join(' '), fill: pal.surface }, gEl);
        s('polygon', { points: [top[3], top[2], bot[1], bot[2]].map(pt).join(' '), fill: pal['surface-2'] }, gEl);
        s('polygon', { points: top.map(pt).join(' '), fill: pal['surface-3'], stroke: icon ? pal['border-strong'] : col, 'stroke-width': 1 }, gEl);
        const side = (b - a) * 50;
        const inner = side * 0.74;
        if (icon) {
          s('image', {
            href: icon.url, transform: plane(x + a, y + a, z + ph),
            x: (side - inner) / 2, y: (side - inner) / 2, width: inner, height: inner,
            preserveAspectRatio: 'xMidYMid meet',
          }, gEl);
        }
        bottom = P(x + b, y + b, z)[1];
      }

      if (n.label) {
        const t = s('text', {
          x: cx, y: bottom + 16, 'text-anchor': 'middle', fill: pal.text, 'font-size': 12.5,
          stroke: pal.surface, 'stroke-width': 4, 'paint-order': 'stroke',
        }, reg(n.id, s('g', {}, Llabels)), n.label);
        if (n.sub) s('tspan', { x: cx, dy: 15, fill: pal['text-2'], 'font-size': 11 }, t, n.sub);
      }
      nodeEls.set(n.id, { ring });
    }

    let vb0, vb;
    const fit = () => {
      const bb = root.getBBox();
      const pad = 36;
      vb0 = { x: bb.x - pad, y: bb.y - pad - 20, w: bb.width + pad * 2, h: bb.height + pad * 2 + 20 };
      vb = { ...vb0 };
      apply();
    };
    const apply = () => svg.setAttribute('viewBox', `${vb.x} ${vb.y} ${vb.w} ${vb.h}`);
    const unitPerPx = () => Math.max(vb.w / svg.clientWidth, vb.h / svg.clientHeight) || 1;
    const zoom = (f, cxPx, cyPx) => {
      const r = svg.getBoundingClientRect();
      const u = unitPerPx();
      const mx = vb.x + vb.w / 2 + ((cxPx == null ? r.width / 2 : cxPx) - r.width / 2) * u;
      const my = vb.y + vb.h / 2 + ((cyPx == null ? r.height / 2 : cyPx) - r.height / 2) * u;
      const nw = Math.min(vb0.w * 4, Math.max(vb0.w / 6, vb.w / f));
      const k = nw / vb.w;
      vb = { x: mx - (mx - vb.x) * k, y: my - (my - vb.y) * k, w: vb.w * k, h: vb.h * k };
      apply();
    };

    ui.zoomIn.onclick = () => zoom(1.25);
    ui.zoomOut.onclick = () => zoom(0.8);
    ui.reset.onclick = () => { vb = { ...vb0 }; apply(); };
    ui.stage.addEventListener('wheel', (ev) => {
      if (!ev.ctrlKey && !ev.metaKey) return;
      ev.preventDefault();
      const r = svg.getBoundingClientRect();
      zoom(Math.exp(-ev.deltaY * 0.0025), ev.clientX - r.left, ev.clientY - r.top);
    }, { passive: false });
    let drag = null;
    ui.stage.addEventListener('pointerdown', (ev) => {
      if (ev.button !== 0) return;
      drag = { x: ev.clientX, y: ev.clientY, vb: { ...vb } };
      ui.stage.setPointerCapture(ev.pointerId);
      ui.stage.classList.add('isod-drag');
    });
    ui.stage.addEventListener('pointermove', (ev) => {
      if (!drag) return;
      const u = unitPerPx();
      vb = { ...drag.vb, x: drag.vb.x - (ev.clientX - drag.x) * u, y: drag.vb.y - (ev.clientY - drag.y) * u };
      apply();
    });
    const end = () => { drag = null; ui.stage.classList.remove('isod-drag'); };
    ui.stage.addEventListener('pointerup', end);
    ui.stage.addEventListener('pointercancel', end);

    const update = (st) => {
      for (const [key, list] of els) for (const el of list) el.classList.toggle('isod-off', !st.visible.has(key));
      for (const [eid, ee] of edgeEls) {
        const on = st.active.has(eid);
        ee.path.setAttribute('stroke', on ? pal.accent : ee.base);
        ee.path.setAttribute('stroke-width', on ? 3.5 : 2.5);
        if (ee.packets) {
          const show = st.visible.has(eid) && (on || (ee.edge.packets && !st.active.size) || (ee.edge.packets && ee.edge.packets.always));
          ee.packets.style.display = show ? '' : 'none';
        }
      }
      for (const [nid, ne] of nodeEls) ne.ring.setAttribute('opacity', st.active.has(nid) ? 0.9 : 0);
    };

    const steps = C.stepper(scene, ui, update);
    requestAnimationFrame(fit);
    return { svg, steps, fit };
  }

  g.IsoSVG = { mount };
})(typeof window !== 'undefined' ? window : globalThis);
