# V246 validation

* 7,117 source and 7,117 packaged checks passed: town/crops 5,506; items 734; streets 606; shops 233; loadout 15; healing 23.
* All seven days × 21 resident schedules: 882 sampled states, 759 moving route segments, zero unreachable destinations. Affected visiting residents stay at least 64 pixels apart. Cottage visitors clear the Academy roof. New seating clears street routes.
* All 80 crops × four stages: frame presence, dimensions, atlas bounds, early/fruiting/ripe selection and tint checked. Full crop/economy/save/network authority data remain byte-identical to V245.
* 16 native runtime captures: six changed town views by day/night, plus four pages covering every crop's four stages. 13 Chromium/WebGL2 review captures plus the unmodified production main menu. Browser script errors: zero. Production Web opening completed.
* Server imported and compiled. V245's inherited ObjectDB/three-resource cleanup warning occurs at native QA shutdown; no script errors occurred.
* Production resources are byte-identical across Editable, Server Update and Web PCK. Every unrelated V245 exported resource is retained byte-identically. QA fixtures add scripts only; all production resources match the shipped build.

## Paired rendering measurements

Godot 4.5.1 Compatibility, Mesa llvmpipe software renderer, 1280×720. Baseline and candidate run sequentially after other rendering jobs finish. Main gameplay simulation is paused; UI and redraws continue. 40 warm-up + 80 measured frames per view; values below are medians. These diagnose rendering costs and do not predict physical school computers.

| View | V245 draw calls | V246 draw calls | V245 CPU ms | V246 CPU ms |
|---|---:|---:|---:|---:|
| Civic / Day | 345 | 320 | 23.97 | 33.42 |
| Mountain / Day | 203 | 207 | 21.98 | 25.05 |
| Cottage / Day | 171 | 178 | 18.88 | 32.55 |
| Academy / Day | 121 | 134 | 15.57 | 16.17 |
| Wayfarers / Day | 202 | 215 | 27.24 | 20.51 |
| Seedhouse / Day | 169 | 182 | 34.16 | 15.76 |
| Civic / Night | 435 | 413 | 83.94 | 124.01 |
| Mountain / Night | 252 | 244 | 70.23 | 17.48 |
| Cottage / Night | 211 | 194 | 36.07 | 127.47 |
| Academy / Night | 149 | 150 | 28.73 | 28.89 |
| Wayfarers / Night | 237 | 253 | 37.38 | 49.00 |
| Seedhouse / Night | 207 | 223 | 31.18 | 23.45 |

## Limits

No deployment, physical school-computer benchmark or live account/multiplayer backend test. Browser review uses an isolated static local fixture. Production PCK SHA-256: `3495df1051f74b5d97a82a249d89ebad6f5b52337f87014f2a33b91bee5675ae`.
