# V206 — Neutral front-facing hero movement

Young Ram, Crossroads Cat and Living Book now use front-facing idle and two front-facing movement images, matching the rest of the roster. Moving left, right, up, down or diagonally uses exactly the same artwork and cycle. All direction tracking, turning and horizontal sprite mirroring added in V205 has been removed.

The approved colours and character identities are retained: navy Young Ram, charcoal cat with purple scarf, and plum/gold Living Book. Each hero still uses one primary image and one image for each secondary/special ability. Elder Ram keeps his approved green appearance. The title and Studio introductions, menu portraits and standard asset paths use the corrected neutral sprites too.

No changes to controls, camera behavior, movement speed, hitboxes, attack timing, damage, ability effects or cooldowns. No account, save, database or secret migration.

## Validation

Godot 4.5.1 checks cover the six-pose setup, distinct two-frame movement, identical cached sprite selection in every movement direction, ability cues and multiplayer state round trips, and accepted solo/arcade abilities. Modified game/intro scripts are compiled and the actual native game is visually checked. Official character definitions and backend behavior are compared with V205. PCK hashes and ZIP CRCs are verified.

Real-device/browser playtesting remains. Nothing has been deployed automatically.

## Files and deployment

Use these V206 files instead of V205. Editable ZIP is the full Godot project. Update Render with the server package first, preserving the current database, persistent data, environment variables and keys. Then upload the web ZIP to itch.io and hard-refresh the browser.

Test walking in all four directions and diagonally with Ram, Cat and Book, then each ability. Walking should never turn or flip the sprite.

## Art sources

The built-in image generation tool edited only the three neutral pose sets. Original transparent sheets are retained as assets/core204/<hero>_neutral_source.png. The prompt set is tools/core204/neutral206_prompts.json; slicing metadata is assets/core204/neutral206.json; the repeatable extraction script is tools/prepare_neutral206_art.py. Cropping/resizing preserves generated pixels and alpha. Original V204 ability artwork remains in use.
