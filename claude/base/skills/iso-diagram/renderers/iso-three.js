import * as THREE from 'https://cdn.jsdelivr.net/npm/three@0.170.0/build/three.module.js';

const C = window.IsoCore;
const ISO_AZ = Math.PI / 4;
// 30 degrees gives the 2:1 dimetric look the isopacks icons are drawn for, not true isometric.
const ISO_EL = Math.PI / 6;
const W = (x, y, z) => new THREE.Vector3(x, z, y);

function loadTexture(url, px) {
  return new Promise((resolve) => {
    const img = new Image();
    img.onload = () => {
      const aspect = (img.naturalHeight || 1) / (img.naturalWidth || 1);
      const cv = document.createElement('canvas');
      cv.width = px;
      cv.height = Math.max(1, Math.round(px * aspect));
      cv.getContext('2d').drawImage(img, 0, 0, cv.width, cv.height);
      const tex = new THREE.CanvasTexture(cv);
      tex.colorSpace = THREE.SRGBColorSpace;
      tex.anisotropy = 4;
      resolve(tex);
    };
    img.onerror = () => resolve(null);
    img.src = url;
  });
}

function textTexture(text, color, font) {
  const cv = document.createElement('canvas');
  const ctx = cv.getContext('2d');
  ctx.font = font;
  const w = Math.ceil(ctx.measureText(text).width) + 8;
  cv.width = w;
  cv.height = 64;
  ctx.font = font;
  ctx.fillStyle = color;
  ctx.textBaseline = 'middle';
  ctx.fillText(text, 4, 32);
  const tex = new THREE.CanvasTexture(cv);
  tex.colorSpace = THREE.SRGBColorSpace;
  return { tex, aspect: w / 64 };
}

function flat(mesh) {
  mesh.rotation.x = -Math.PI / 2;
  return mesh;
}

export function mount(host, rawScene, icons, opts) {
  opts = opts || {};
  icons = icons || {};
  const scene = C.normalize(rawScene);
  const ui = C.chrome(host, scene, { rotate: true, attribution: opts.attribution });
  const pal = C.palette(host);
  const still = C.reducedMotion();
  const col = (c) => new THREE.Color(c);

  const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.setClearColor(0x000000, 0);
  ui.stage.appendChild(renderer.domElement);
  const labelLayer = C.h('div', { class: 'isod-labels' }, ui.view);

  const world = new THREE.Scene();
  const camera = new THREE.OrthographicCamera(-1, 1, 1, -1, -200, 400);
  const target = W(scene.grid.w / 2, scene.grid.h / 2, 0);
  const view = { az: ISO_AZ, el: ISO_EL, zoom: 1, half: 5 };

  // Everything is painter-ordered with depthTest off, like the SVG renderer; renderOrder is the depth.
  const mat = (o) => new THREE.MeshBasicMaterial({ transparent: true, depthTest: false, depthWrite: false, ...o });
  const fades = [];
  const fader = (key, obj, mats) => { fades.push({ key, obj, mats: mats.map((m) => [m, m.opacity]), a: 1, t: 1 }); };

  if (scene.gridLines !== false) {
    const { w, h } = scene.grid;
    const pts = [];
    for (let x = 0; x <= w; x++) pts.push(W(x, 0, 0), W(x, h, 0));
    for (let y = 0; y <= h; y++) pts.push(W(0, y, 0), W(w, y, 0));
    const lines = new THREE.LineSegments(
      new THREE.BufferGeometry().setFromPoints(pts),
      new THREE.LineBasicMaterial({ color: col(pal.border), transparent: true, opacity: 0.45, depthTest: false }),
    );
    lines.renderOrder = 0;
    world.add(lines);
  }

  for (const gr of scene.groups) {
    const [x0, y0] = gr.from;
    const x1 = gr.to[0] + 1, y1 = gr.to[1] + 1;
    const c = C.tone(pal, gr.tone, 'blue');
    const obj = new THREE.Group();
    const fill = mat({ color: col(c), opacity: 0.07 });
    const plane = flat(new THREE.Mesh(new THREE.PlaneGeometry(x1 - x0, y1 - y0), fill));
    plane.position.copy(W((x0 + x1) / 2, (y0 + y1) / 2, 0.001));
    plane.renderOrder = 1;
    const edgeMat = new THREE.LineBasicMaterial({ color: col(c), transparent: true, opacity: 0.7, depthTest: false });
    const loop = new THREE.LineLoop(new THREE.BufferGeometry().setFromPoints([W(x0, y0, 0), W(x1, y0, 0), W(x1, y1, 0), W(x0, y1, 0)]), edgeMat);
    loop.renderOrder = 2;
    obj.add(plane, loop);
    const mats = [fill, edgeMat];
    if (gr.label) {
      const { tex, aspect } = textTexture(gr.label.toUpperCase(), c, "700 44px 'JetBrains Mono', ui-monospace, monospace");
      const lm = mat({ map: tex, opacity: 1 });
      const hgt = 0.42;
      const lbl = flat(new THREE.Mesh(new THREE.PlaneGeometry(hgt * aspect, hgt), lm));
      lbl.position.copy(W(x0 + 0.15 + (hgt * aspect) / 2, y0 + 0.3, 0.002));
      lbl.renderOrder = 2;
      obj.add(lbl);
      mats.push(lm);
    }
    world.add(obj);
    fader(gr.id, obj, mats);
  }

  const edges = [];
  for (const e of scene.edges) {
    const { pts, z } = C.route(scene, e);
    const obj = new THREE.Group();
    const base = e.tone ? C.tone(pal, e.tone) : pal['text-muted'];
    const m = mat({ color: col(base), opacity: 1 });
    const width = 0.05;
    const dashed = e.style === 'dashed';
    for (let k = 1; k < pts.length; k++) {
      const [ax, ay] = pts[k - 1];
      const [bx, by] = pts[k];
      const len = Math.hypot(bx - ax, by - ay);
      const ang = Math.atan2(by - ay, bx - ax);
      const pieces = dashed ? Math.max(1, Math.floor(len / 0.22)) : 1;
      const pl = dashed ? 0.12 : len;
      for (let p = 0; p < pieces; p++) {
        const t = dashed ? (p * 0.22 + 0.06) / len : 0.5;
        const seg = flat(new THREE.Mesh(new THREE.PlaneGeometry(pl, width), m));
        seg.rotation.z = -ang;
        seg.position.copy(W(ax + (bx - ax) * t, ay + (by - ay) * t, z + 0.003));
        seg.renderOrder = 3;
        obj.add(seg);
      }
    }
    world.add(obj);
    fader(e.id, obj, [m]);

    const cfg = e.packets || {};
    const pc = C.tone(pal, cfg.tone, 'accent');
    const len = C.polyLength(pts);
    const speed = (cfg.speed || 140) / 70;
    const dur = len / speed;
    const every = cfg.every || 1.1;
    const count = Math.max(1, Math.min(12, Math.floor(dur / every) || 1));
    const packets = [];
    const pGroup = new THREE.Group();
    pGroup.visible = false;
    const core = mat({ color: col(pc), opacity: 1 });
    const glow = mat({ color: col(pc), opacity: 0.25 });
    for (let k = 0; k < count; k++) {
      const p = new THREE.Group();
      const a = new THREE.Mesh(new THREE.SphereGeometry(0.06, 16, 12), core);
      const b = new THREE.Mesh(new THREE.SphereGeometry(0.12, 16, 12), glow);
      a.renderOrder = 5;
      b.renderOrder = 4;
      p.add(b, a);
      pGroup.add(p);
      packets.push({ obj: p, offset: k * every });
    }
    world.add(pGroup);
    edges.push({ edge: e, id: e.id, pts, z, mat: m, base, packets, pGroup, dur, reverse: !!cfg.reverse });
  }

  const nodes = [];
  const sideA = col(pal.surface), sideB = col(pal['surface-2']), topC = col(pal['surface-3']);
  for (const n of scene.nodes) {
    const [x, y] = n.at;
    const z = n.z;
    const icon = icons[n.icon];
    const c = C.tone(pal, n.tone, 'accent');
    const obj = new THREE.Group();
    const mats = [];
    const center = W(x + 0.5, y + 0.5, z);

    const ringMat = mat({ color: col(c), opacity: 0 });
    const ring = flat(new THREE.Mesh(new THREE.RingGeometry(0.56, 0.61, 48), ringMat));
    ring.position.copy(center).y += 0.004;
    obj.add(ring);
    let pulse = null;
    if (n.pulse && !still) {
      const pm = mat({ color: col(c), opacity: 0.8 });
      pulse = flat(new THREE.Mesh(new THREE.RingGeometry(0.42, 0.47, 48), pm));
      pulse.position.copy(center).y += 0.005;
      obj.add(pulse);
      mats.push(pm);
    }

    const parts = [];
    if (icon && icon.iso) {
      const w = Math.SQRT2 * 0.8 * n.scale;
      const h = w * (icon.h / icon.w);
      const sm = new THREE.SpriteMaterial({ transparent: true, depthTest: false, depthWrite: false, opacity: 1 });
      const sp = new THREE.Sprite(sm);
      sp.scale.set(w, h, 1);
      sp.center.set(0.5, w / 4 / h);
      sp.position.copy(center);
      loadTexture(icon.url, 256).then((t) => { if (t) { sm.map = t; sm.needsUpdate = true; } });
      obj.add(sp);
      parts.push(sp);
      mats.push(sm);
    } else {
      const faces = [sideA, sideA, topC, topC, sideB, sideB].map((cc) => mat({ color: cc, opacity: 1 }));
      const box = new THREE.Mesh(new THREE.BoxGeometry(0.76, 0.3, 0.76), faces);
      faces.forEach((f) => { f.side = THREE.FrontSide; });
      box.position.copy(center).y += 0.15;
      obj.add(box);
      parts.push(box);
      mats.push(...faces);
      if (icon) {
        const im = mat({ opacity: 1 });
        const a = icon.h / icon.w;
        const s = 0.56;
        const ic = flat(new THREE.Mesh(new THREE.PlaneGeometry(a > 1 ? s / a : s, a > 1 ? s : s * a), im));
        ic.position.copy(center).y += 0.301;
        loadTexture(icon.url, 256).then((t) => { if (t) { im.map = t; im.needsUpdate = true; } });
        obj.add(ic);
        parts.push(ic);
        mats.push(im);
      } else {
        const em = new THREE.LineBasicMaterial({ color: col(c), transparent: true, depthTest: false });
        const outline = new THREE.LineLoop(new THREE.BufferGeometry().setFromPoints([
          W(x + 0.12, y + 0.12, z + 0.3), W(x + 0.88, y + 0.12, z + 0.3), W(x + 0.88, y + 0.88, z + 0.3), W(x + 0.12, y + 0.88, z + 0.3),
        ]), em);
        obj.add(outline);
        parts.push(outline);
        mats.push(em);
      }
    }
    world.add(obj);
    fader(n.id, obj, mats);

    let label = null;
    if (n.label) {
      label = C.h('div', { class: 'isod-label' }, labelLayer, n.label);
      if (n.sub) C.h('small', {}, label, n.sub);
    }
    nodes.push({ n, obj, parts, ring, ringMat, pulse, label, anchor: W(x + 1, y + 1, z), center });
  }

  const sortNodes = () => {
    const dir = new THREE.Vector3();
    camera.getWorldDirection(dir);
    const ranked = nodes.map((nd) => ({ nd, d: nd.center.dot(dir) })).sort((a, b) => b.d - a.d);
    ranked.forEach(({ nd }, i) => {
      nd.obj.renderOrder = 0;
      nd.ring.renderOrder = 6;
      if (nd.pulse) nd.pulse.renderOrder = 6;
      nd.parts.forEach((p, k) => { p.renderOrder = 10 + i * 3 + k; });
    });
  };

  const placeCamera = () => {
    const off = new THREE.Vector3(
      Math.cos(view.el) * Math.cos(view.az),
      Math.sin(view.el),
      Math.cos(view.el) * Math.sin(view.az),
    ).multiplyScalar(100);
    camera.position.copy(target).add(off);
    camera.up.set(0, 1, 0);
    camera.lookAt(target);
    const r = ui.stage.getBoundingClientRect();
    const aspect = r.width / Math.max(1, r.height);
    const hh = view.half / view.zoom;
    camera.left = -hh * aspect;
    camera.right = hh * aspect;
    camera.top = hh;
    camera.bottom = -hh;
    camera.updateProjectionMatrix();
    camera.updateMatrixWorld();
    sortNodes();
    dirty = true;
  };

  const fit = () => {
    view.az = ISO_AZ;
    view.el = ISO_EL;
    view.zoom = 1;
    target.copy(W(scene.grid.w / 2, scene.grid.h / 2, 0));
    view.half = 5;
    placeCamera();
    const box = new THREE.Box3().setFromObject(world);
    const pts = [];
    for (const x of [box.min.x, box.max.x]) for (const y of [box.min.y, Math.max(box.max.y, 1.2)]) for (const z of [box.min.z, box.max.z]) pts.push(new THREE.Vector3(x, y, z));
    const inv = camera.matrixWorldInverse;
    let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
    for (const p of pts) {
      const q = p.clone().applyMatrix4(inv);
      minX = Math.min(minX, q.x); maxX = Math.max(maxX, q.x);
      minY = Math.min(minY, q.y); maxY = Math.max(maxY, q.y);
    }
    const right = new THREE.Vector3().setFromMatrixColumn(camera.matrixWorld, 0);
    const up = new THREE.Vector3().setFromMatrixColumn(camera.matrixWorld, 1);
    target.addScaledVector(right, (minX + maxX) / 2).addScaledVector(up, (minY + maxY) / 2);
    const r = ui.stage.getBoundingClientRect();
    const aspect = r.width / Math.max(1, r.height);
    view.half = Math.max((maxY - minY) / 2, (maxX - minX) / 2 / aspect) * 1.12 + 0.3;
    placeCamera();
  };

  const resize = () => {
    const r = ui.stage.getBoundingClientRect();
    if (!r.width || !r.height) return;
    renderer.setSize(r.width, r.height, false);
    placeCamera();
  };

  let rotating = false;
  ui.rotate.onclick = () => {
    rotating = !rotating;
    ui.rotate.setAttribute('aria-pressed', String(rotating));
    if (!rotating) { view.az = ISO_AZ; view.el = ISO_EL; placeCamera(); }
  };
  ui.zoomIn.onclick = () => { view.zoom = Math.min(6, view.zoom * 1.25); placeCamera(); };
  ui.zoomOut.onclick = () => { view.zoom = Math.max(0.3, view.zoom / 1.25); placeCamera(); };
  ui.reset.onclick = () => {
    rotating = false;
    ui.rotate.setAttribute('aria-pressed', 'false');
    fit();
  };
  ui.stage.addEventListener('wheel', (ev) => {
    if (!ev.ctrlKey && !ev.metaKey) return;
    ev.preventDefault();
    view.zoom = Math.min(6, Math.max(0.3, view.zoom * Math.exp(-ev.deltaY * 0.0025)));
    placeCamera();
  }, { passive: false });
  let drag = null;
  ui.stage.addEventListener('pointerdown', (ev) => {
    if (ev.button !== 0 && ev.button !== 2) return;
    drag = { x: ev.clientX, y: ev.clientY, rot: rotating && ev.button === 0 && !ev.shiftKey };
    ui.stage.setPointerCapture(ev.pointerId);
    ui.stage.classList.add('isod-drag');
  });
  ui.stage.addEventListener('contextmenu', (ev) => ev.preventDefault());
  ui.stage.addEventListener('pointermove', (ev) => {
    if (!drag) return;
    const dx = ev.clientX - drag.x, dy = ev.clientY - drag.y;
    drag.x = ev.clientX;
    drag.y = ev.clientY;
    if (drag.rot) {
      view.az += dx * 0.008;
      view.el = Math.min(1.45, Math.max(0.12, view.el + dy * 0.006));
    } else {
      const per = (2 * view.half / view.zoom) / Math.max(1, ui.stage.clientHeight);
      const right = new THREE.Vector3().setFromMatrixColumn(camera.matrixWorld, 0);
      const up = new THREE.Vector3().setFromMatrixColumn(camera.matrixWorld, 1);
      target.addScaledVector(right, -dx * per).addScaledVector(up, dy * per);
    }
    placeCamera();
  });
  const end = () => { drag = null; ui.stage.classList.remove('isod-drag'); };
  ui.stage.addEventListener('pointerup', end);
  ui.stage.addEventListener('pointercancel', end);

  let state = null;
  const update = (st) => {
    const first = !state;
    state = st;
    for (const f of fades) {
      f.t = st.visible.has(f.key) ? 1 : 0;
      if (first) f.a = f.t;
    }
    for (const ed of edges) {
      const on = st.active.has(ed.id);
      ed.mat.color.set(on ? pal.accent : ed.base);
      const show = !still && st.visible.has(ed.id) && (on || (ed.edge.packets && (!st.active.size || ed.edge.packets.always)));
      ed.pGroup.visible = !!show;
    }
    for (const nd of nodes) nd.active = st.active.has(nd.n.id);
    dirty = true;
  };

  let dirty = true;
  let running = true;
  let last = performance.now();
  let clock = 0;
  const tmp = new THREE.Vector3();
  const frame = (now) => {
    if (!running) return;
    const dt = Math.max(0, Math.min(0.1, (now - last) / 1000));
    last = now;
    clock += dt;
    let moving = !still;
    for (const f of fades) {
      if (Math.abs(f.a - f.t) > 0.001) {
        f.a += (f.t - f.a) * Math.min(1, dt * 7);
        if (Math.abs(f.a - f.t) < 0.01) f.a = f.t;
        moving = true;
      }
      f.obj.visible = f.a > 0.01;
      for (const [m, o] of f.mats) m.opacity = o * f.a;
      f.obj.position.y = (1 - f.a) * 0.35;
    }
    for (const nd of nodes) {
      const fa = fades.find((f) => f.obj === nd.obj).a;
      nd.ringMat.opacity = nd.active ? 0.9 * fa : 0;
      if (nd.pulse) {
        const t = (clock % 1.8) / 1.8;
        nd.pulse.scale.setScalar(0.55 + t * 0.85);
        nd.pulse.material.opacity = (1 - t) * 0.85 * fa;
      }
      if (nd.label) {
        tmp.copy(nd.anchor).setY(nd.anchor.y + nd.obj.position.y).project(camera);
        const r = ui.stage.clientWidth, hh = ui.stage.clientHeight;
        nd.label.style.left = ((tmp.x + 1) / 2 * r).toFixed(1) + 'px';
        nd.label.style.top = ((1 - tmp.y) / 2 * hh + 6).toFixed(1) + 'px';
        nd.label.style.opacity = fa.toFixed(2);
        nd.label.style.display = fa > 0.01 ? '' : 'none';
      }
    }
    for (const ed of edges) {
      if (!ed.pGroup.visible) continue;
      const len = C.polyLength(ed.pts);
      for (const p of ed.packets) {
        let t = ((clock + p.offset) % ed.dur) / ed.dur;
        if (ed.reverse) t = 1 - t;
        const [x, y] = C.pointAt(ed.pts, t * len);
        p.obj.position.copy(W(x, y, ed.z + 0.09));
      }
    }
    if (moving || dirty) {
      renderer.render(world, camera);
      dirty = false;
    }
    requestAnimationFrame(frame);
  };

  const io = new IntersectionObserver(([en]) => {
    const vis = en.isIntersecting;
    if (vis && !running) { running = true; last = performance.now(); requestAnimationFrame(frame); }
    if (!vis) running = false;
  });
  io.observe(host);
  new ResizeObserver(resize).observe(ui.stage);

  resize();
  fit();
  const steps = C.stepper(scene, ui, update);
  requestAnimationFrame(frame);
  return { renderer, steps, fit, get state() { return state; } };
}

window.IsoThree = { mount };
