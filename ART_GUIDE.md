# Art guide for FX Crossroads design students

Use Piskel in a browser or Aseprite if your class has it. Work on a transparent canvas, export PNG at original pixel size, and keep the editable source for revisions. The project displays sprites enlarged with nearest-neighbor filtering.

| Asset | Suggested canvas | Deliverables |
| --- | --- | --- |
| Playable hero | 28 × 32 pixels | `<id>_idle.png`, `<id>_walk1.png`, `<id>_walk2.png`, `<id>_attack.png` |
| Enemy | 28 × 28 pixels | The same four poses |
| Boss | 48 × 48 pixels | The same four poses |
| Tree, rock, plant, sign | 32 × 32 pixels, transparent | One PNG and the editable source |
| House | 80 × 72 pixels, transparent | One PNG and the editable source |
| Ground tile | 32 × 32 pixels | A seamless tile PNG and source |

For Grade 10, a small scenery contribution is a useful short project: make a tree, flower, bush, rock, lantern, or sign. Export a transparent PNG, preview it over both light and dark terrain, then have a realm designer place it as a `Sprite2D` in `GroundPaint` for decoration or `Obstacles` for a solid object. For solid objects, set metadata `kind` and `radius` to match an approved game asset; the realm scene stores its texture and collision radius. Keep the original source project out of the playable ZIP.

The four-pose character assignment asks for a still pose, two distinct walking steps, and a readable attack pose. Keep the feet at the same height and silhouette clear when reduced. Existing two-frame characters remain compatible for older projects, but new submissions should use four poses. Faces still point right in the current engine; direction-specific art is optional future work.
