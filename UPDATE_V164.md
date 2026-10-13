# v164 — Mobile controls and gameplay polish

- Closing overlays now invalidates the mobile layout and rebuilds gameplay buttons without needing a screen rotation. Sticks and held actions are released on transitions. Native Studio, Profile and fishing pages suppress the underlying combat controls.
- Elder Ram chat/password fields use a real browser text input on touch devices, allowing the browser to open its keyboard directly from a tap. The Web preset also enables Godot’s experimental virtual keyboard. Native desktop retains ordinary LineEdit. Input is temporary and password entry is masked.
- Aquarium directional touch controls are larger and have a nearby Talk / E action; the top Talk to Marina button also remains available.
- A landed catch shows typical median weight and an estimated size percentile derived from the actual ordinary/trophy weight distribution. This is separate from species rarity and personal records.
- Aquarium fish scale with caught length, within safe tank bounds.
- Replaced the garden farmer’s primitive shapes with an editable, detailed ox farmer SVG: clear horns, muzzle, straw hat, apron, boots and hoe, plus subtle motion.
- Gathering and Brewing navigation no longer includes the unrelated Challenges tab.
- Hero Workshop tools use consistent button styling. Playtest comes before the last Finalize & Play button.
- Hearth Herald Lantern Light no longer heals its caster. It heals other allies for 1 HP per 0.5s (previously 2), with cone and wall checks. Damage remains 6 per 0.5s.

This release retains v163’s gentler Grove and all earlier content. It does not include the planned dedicated-server multiplayer overhaul.
