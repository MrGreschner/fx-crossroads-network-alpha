# T4.9.1 server hotfix validation

## Reproduction

A three-hero authoritative arena fixture invokes the actual beekeeper secondary ability and creates its two 38-HP drones. An ordinary Ram hit inside reach works before the fix. Repositioning one drone centre to 95 px in front of the Ram yields HP 38 and no damage feedback under the prior code, despite the drone body overlapping the 82 px strike reach.

After the fix, the same edge hit yields HP 10 and one damage event. The follow-up hit destroys the drone and reports only its remaining HP as damage. The fixture then checks range, cone, team and obstacle exclusions. Shared Ram, Cat and Book identity strikes are checked against bee and Mosaic summons, six combinations total.

The initial one-frame fixture cleanup emitted resource-leak warnings; waiting four process frames after freeing the game resolved them. The release regression log has no script errors or resource errors.

## Scope

Only four server runtime paths are in the patch:

- `scripts/morrow_combat.gd`: summoned actor radius and authoritative feedback for unlinked unit damage.
- `scripts/v46_heroes.gd`: shared identity-strike reach uses the actor radius, preserving existing NPC fallback.
- `network/server.gd`: welcome build label T4.9.1.
- `network_service/gateway.mjs`: health build label T4.9.1.

The full source also updates the regression test, test runner and expected server labels. Released T4.9 Web bytes are not modified or re-exported. No further Render plan purchase is needed.

## Checks

The final suite includes the new `summon_melee.gd` regression and all existing combat, prediction, interpolation, collision, projectile ownership, timing, idle actor, local view, Twister view, build consistency, Phoenix view, effect anchors, snapshot coalescing, prepared movement, jitter, roster smoke, connections, actual Godot client, latency, gateway, two-client views, short 2/4/8-player load and reconnect checks. See `network_tests/t491-suite-summary.txt` for the final result.

This server patch does not alter renderer code. No new browser rendering performance certification is claimed. The uploaded F8 file is beekeeper-perspective aggregate telemetry; it cannot reconstruct every Ram attack or establish which exact symptom the user saw.
