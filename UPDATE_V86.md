# FX Crossroads v86 — The sixty-hero release

Complete editable source, including all v84/v85 changes. Nothing has been deployed automatically. All **60 heroes** remain free and immediately selectable.

## Hero hall

A new scrollable hall provides search, play-style filters, difficulty filters, pinned favourites, portraits and mastery progress on every row. The selected hero has a separate scrolling information panel with its home, abilities and mastery choices. Favourites are included in profile export/import. The existing nine-hero introduction remains available.

Support was the smallest main role before this update (6 support, 15 melee, 35 ranged). The new roster has 7 primary support, 17 melee and 36 ranged heroes; secondary tags also expose hybrid supports and control kits.

## Four new heroes

- **Briar Skipper — Whispering Grove:** a hare firing bouncing acorns. Kick airborne acorns into larger blasts and vault across a delayed acorn trail. Each acorn has a hit cap; the leap is visible and collision-aware. Mastery offers longer, weaker acorns or a chestnut fan instead of the kick.
- **Recess Warden — Firstbell Elementary:** a capybara support guardian. Whistle shots protect nearby allies; lunch mats heal and cleanse; a moving cone patrol pushes foes and intercepts projectiles. Mastery offers a wider, weaker lunch mat or a stationary protective shelter.
- **Crimson Votary:** a human fighter who pays health for crescent attacks, builds a capped debt reserve and spends it on returning blades. The defensive covenant can earn limited healing through successful melee hits. Health expenditure cannot kill the hero or farm mastery damage. Mastery offers a ranged blood spear or a delayed blossom instead of returning blades.
- **Crossroads Teacher — hero 60:** a professional ram. Advanced Knowledge combines a 14-damage notebook strike with an 11-damage chalk shot. Hold Classroom Management for up to 2.5 seconds to pull enemies, suppress their attacks, damage them every half-second and catch hostile projectiles; move at 45% speed. Release to deal 16 damage, push enemies away and destroy the captured shots. Master Key uses two visible doors to teleport to a safe aimed destination, heal 12 and grant 20% protection for 2 seconds. Mastery offers a larger but weaker classroom or a return-ticket teleport with less healing.

Each has four original pixel-art poses, descriptions, a mastery title, two independent alternatives and normal critical-hit progression. See the two mastery catalogues for complete trade-offs.

## Release safeguards

- Last-good local profile backup and temporary-file writes; malformed imports are rejected before changing progress.
- Common projectile interception now includes the new kits and Foundry custom projectiles.
- Multiplayer snapshots carry the new abilities; remote leaps avoid per-frame teleport messages.
- Bounded effect collections, ally-only healing, per-target damage limits and hold-time fail-safes.
- A roster audit checks manifest IDs, free access, four art poses and independent mastery slots; metadata has a fallback for future heroes.

## Before publishing

1. Deploy the included `room_service` code to Render. It is **service/protocol 20**; use the same existing URL, environment settings and start command. Different game protocols cannot join the same room.
2. Export a fresh Web build from Godot and upload the exported Web ZIP to itch.io. This editable-source ZIP itself is not the browser build.
3. Export the Windows build using the included workflow/script if offering the downloadable edition.
4. Keep students' exported profiles. Existing profiles remain compatible; no progress reset is required.

Automated solo and host/guest checks cover the new kits, menu filtering, favourites, import validation and backup recovery. Native rendered previews were inspected. Physical phone behaviour and a live Render/itch.io deployment still need a short check on your devices. Browser graphics-context loss remains hardware/browser-dependent; this update does not promise to eliminate it.
