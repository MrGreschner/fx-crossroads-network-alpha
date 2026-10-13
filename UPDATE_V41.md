# v41 — Polarity attack clarity

Attraction no longer draws a large circle around the hero. Each active anchor flashes and draws inward energy streaks. Affected enemies have a brief travelling-energy tether to the exact anchor pulling and damaging them. Without anchors, the existing hero-position fallback uses the same directional effect. Damage, range, cooldown and slowing remain unchanged. Effects synchronize through existing multiplayer snapshots.

Validation: Godot import and focused checks for anchor positions, affected-target tether, unchanged damage, snapshot inclusion and effect expiry passed. Includes all v40 content. Export Web and upload to itch.io as usual; no Render changes.
