# Scene format

```json
{
  "title": "Request flow",
  "description": "Lede under the page heading (page mode only).",
  "pageTitle": "Request flow",
  "eyebrow": "Diagram",
  "renderer": "svg",
  "grid": { "w": 12, "h": 8 },
  "height": 520,
  "gridLines": true,
  "stepMs": 2600,
  "autoplay": false,
  "startStep": 1,
  "nodes": [],
  "groups": [],
  "edges": [],
  "steps": []
}
```

| Field | Default | Meaning |
| --- | --- | --- |
| `title` | `"Diagram"` | Shown in the diagram corner and as page heading |
| `renderer` | `svg` | `svg` or `three`; `--renderer` overrides |
| `grid` | bounds + 1 | Tiles drawn as the floor grid |
| `height` | `clamp(320px, 62vw, 560px)` | Number (px) or CSS length |
| `gridLines` | `true` | Faint floor grid |
| `stepMs` | `2600` | Autoplay interval |
| `startStep` | `1` | Step shown on load (1-based) |

Coordinates are tiles: `x` grows to the screen's right-down, `y` to the left-down, `z` is height
in tiles. A node at `[x, y]` occupies the tile from `(x, y)` to `(x+1, y+1)`.

## nodes

```json
{ "id": "db", "icon": "aws-rds", "at": [9, 2], "z": 0, "label": "Postgres", "sub": "Multi-AZ",
  "tone": "accent", "pulse": true, "scale": 1 }
```

- `icon`: isopacks id (see `icons.md`). Missing/unknown → plain plinth outlined in `tone`.
- `sub`: second, dimmer label line.
- `pulse`: ring that keeps expanding under the node (use for "this one is busy/active").
- `scale`: only affects isometric (isoflow) icons.

## groups

```json
{ "id": "vpc", "label": "VPC 10.0.0.0/16", "from": [3, 1], "to": [10, 5], "tone": "blue", "style": "dashed" }
```

Inclusive tiles. Label is drawn flat on the floor at the top corner. Groups have ids so steps can
reveal them.

## edges

```json
{ "id": "optional", "from": "api", "to": "db", "route": "xy", "style": "dashed", "label": "SQL",
  "tone": "gray", "packets": { "every": 1.1, "speed": 140, "tone": "accent", "reverse": false, "always": false } }
```

- id defaults to `"from->to"`; give an explicit `id` when two edges share endpoints.
- `route`: `xy` (along x first, then y), `yx`, or `straight` (diagonal allowed). Same row/column
  is always straight.
- `packets`: dots travelling `from` → `to` (`reverse` flips). `every` seconds apart, `speed` in
  SVG units/s (one tile ≈ 70).
- Edges are drawn on the floor, under every node.

## steps

```json
{ "show": ["svc", "pod1"], "hide": ["old"], "active": ["ing->svc", "svc"], "caption": "Text for this step." }
```

- Visibility is cumulative from step 1 to the current one. Anything never shown stays hidden,
  so with steps every element must appear in some `show` (groups included).
- An edge shows when both its nodes are visible.
- `active` ids (nodes or edges) are highlighted only in that step; active edges run packets.
- Controls: ◀ ▶ ▶▶ buttons, ←/→ keys when the diagram has focus.
