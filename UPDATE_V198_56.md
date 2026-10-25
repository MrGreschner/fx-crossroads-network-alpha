# Crossroads V198.56 — Open Ocean

- Ocean expanded from 14,000 × 10,000 to 28,000 × 20,000: exactly four times the area. Coastal fishing and the sheltered home harbour remain accessible; lake dimensions are unchanged.
- Night Island uses a deterministic nightly location across a broad deep-water search area instead of cycling through six sites. It remains hidden on the chart until discovered that night. No arbitrary discovery timer.
- Seven current belts and additional submerged wreck/reef landmarks extend across offshore waters. Fixed rocks scaled to match the larger area.
- Drifting logs, broken spars and floating cargo now have matching visible shapes and damaging collision. Debris moves and rotates slowly; only a bounded local field (at most 25 pieces) is generated. No full-ocean debris simulation. The harbour and island shores remain clear.
- Large waves are stronger, broader, faster and longer-lived. Medium-wave force is unchanged. A controlled 60 Hz simulation measured about 2.1 times the former sailing displacement and 3.4 times the former anchored displacement. Anchors retain their protective reduction; the home harbour remains sheltered.
- Boat movement sweeps through obstacles to avoid tunnelling during strong pushes. Anchored boats also take impact damage if a wave/debris pushes a hazard into them. Impact cooldown prevents per-frame damage.
- Camera/map bounds and client/server voyage validation support the larger area. Map current arrows stay bounded. The existing night darkness and return-alive reward rules remain.
- Includes V198.55 safe-harbour storage management, V198.54 river and fishing-platform fixes, and previous teacher/records work. No database migration or changes to keys, accounts or saves.

Validation: 1,592 native checks including 365 nightly locations, bounded moving debris, swept hits/misses, damage cooldown, stronger measured wave displacement, sheltered harbour, unchanged lake, extended camera/save bounds, full-storage legendary landing and no duplicate rewards. Day/night debris and chart visuals reviewed. Production pack round-trip/source parity and ZIP integrity verified. Real-device balance/playtesting remains.

Manual deployment: Render first, then itch.io. Preserve database, environment, persistent storage and keys. Nothing deployed live. Finish any active voyage before refreshing to install: unbanked voyage cargo is session-only.
