# T4.9.1 server hotfix — summon melee contact and damage feedback

Keep the released **T4.9 Web build on itch.io**. This update changes the authoritative server; protocol 3 and the existing client remain compatible. The complete source backup contains the T4.9 client plus the T4.9.1 server changes. This guide supersedes older version guides retained in the project.

## Install the server patch

1. Download `FX_Crossroads_Network_Alpha_T4_9_1_Server_Update.zip`.
2. Extract its contents into your existing local `fx-crossroads-network-alpha` repository ROOT: the folder containing `Dockerfile.network`. Replace the matching paths. Keep the other files and folders; this ZIP is a patch, not a replacement for the whole repository.
3. Commit and push in GitHub Desktop. Deploy the latest commit in Render between matches. The hosting plan and Dockerfile stay the same.
4. Check the service's `/health` page. It must say `ready: true`, `build: "T4.9.1"`, and `protocol: 3`.
5. Reopen the game and create a new room. The game footer and F8 filename remain **T4.9** / `FX_T49_performance.json`; the report's `server_build` should now be **T4.9.1**.

The assistant has not pushed GitHub or deployed this patch. If deployment fails, redeploy the previous successful Render commit. Keep that commit available until testing passes.

## What was reproduced and fixed

The ordinary headbutt already reduced a 38-HP bee drone to 10 HP when its centre was inside the 82 px reach. At a distance of 95 px, the drone's body overlapped that reach but the headbutt did zero damage because this shared strike path treated summoned bodies as points. The regression test reproduced that miss before the fix.

Summons in the shared Morrow/party unit system now expose a conservative 18 px body radius (scaled for enlarged Mosaic units). The shared identity-strike reach check includes that radius. It applies to Ram, Cat and Book strikes and the relevant summoned companions; it does not change player target size, NPC target radii, attack damage, attack angles, AoE rules, projectile geometry or cooldowns.

Successful unlinked summon damage now uses the existing authoritative damage-feedback event. Clients already understand it, so damage numbers and hit contact cues work without a new browser build. Damage is capped at remaining HP; a killing blow reports actual HP removed. Team protection, range, attack cone and line-of-sight rules still apply. The existing Morrow linked-health routing is unchanged.

The tiny decorative bees orbiting the beekeeper's body are cosmetic. Actual summoned drones have health bars and are damageable by opponents.

## Validation

The targeted regression checks cover actual hive casting, ordinary centre hits, body-edge hits, visible feedback events, destruction, distant misses, cone misses, allied protection, obstacle protection and shared Ram/Cat/Book strikes against bee and Mosaic units (six shared cases). The complete existing multiplayer suite also ran against the updated authority. Details and limits are in `NETWORK_T4_9_1_VALIDATION.md`.

The uploaded performance recording came from the beekeeper's client: 121 three-player samples, median 59 FPS, range 30–61 FPS, median 35 ms RTT, maximum 117 ms, zero pending packets throughout, and authority approximately 60 Hz. Sixteen samples were below 50 FPS. This supports improved typical performance but does not prove every client or every attack was smooth. It does not contain enough target-by-target Ram telemetry to prove this edge case explains every reported miss.

## Next playtest

In free-for-all, have the Ram attack the summoned drones with HP bars. With unmodified 28-damage headbutts, a 38-HP drone should drop to 10 HP, then disappear on the second successful hit. Out-of-range or blocked attacks should still miss. Confirm the new damage numbers and keep T4.9 Balanced graphics enabled. If a clear hit still misses, collect the Ram's F8 report as well as the beekeeper's and note whether the target had a health bar.
