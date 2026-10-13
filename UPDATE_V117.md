# v117 — Charge, aim and release

## Hero changes

| Hero | Change |
| --- | --- |
| Living Book | Flying Pages alternates nearest-target pages with a rotation through the other visible enemies in range. Intended targets are retained while alive and visible; pages can retarget if needed. The original firing rate and damage per page remain. |
| Fairway Ranger | Hold secondary for a visible backswing. Marker moves from 85 to 330 reach over 1.4s; aim controls direction. Release lobs the chip. Initial explosion deals 28–42; existing six 4-damage fragments remain. |
| Star Navigator | Hold secondary up to 1.4s for a larger seeking missile, 27–44.6 direct damage and a larger splash. Twin Stars still sends two missiles. |
| Diamond Scout | Tap primary for 22 damage. Hold up to 1.1s for up to 40.7 damage and 1105 projectile speed; release to pitch. |
| Stormscribe | Primary grows in size and damage over 1.2s (19–34.2). Hold Space to target Thunderfall; release to cast, with its existing damage. |
| Vesper | Comet Seal is summoned from the sky. Hold secondary up to 1.5s; release at the marker for 32–56 damage and an 85–119 blast radius. Quick Comet mastery still speeds its fall and narrows the blast. |
| Alderjaw | Charged Tail Slap increases push from 80 to 160 and stun from 1.2 to about 2s. Charge caps at 1.3s. Damage scales from 26 to 31.2. |
| Mara Dawnblade | Tap primary for a quick 28-damage sword cut. Hold 1s for up to 46.2 and 70 knockback. Unlocked bleed still works. |
| Caelum Mirrorwright | Silver Shatter replaces Prism Fold: three piercing mirror shards in a broad fan, 12–19.2 damage each with up to 1.2s charge. Clear Sight adds slow; Twin Self echoes the fan at 60% damage. |
| Twisterspell | Tornado stride has a gentler +20% speed boost, slight direction sway and swallows nearby hostile projectiles. Melee and area attacks can still hurt it. |

## Controls and aiming

- Charged casts fire on release. Taps fire base attacks. Longer holds stop increasing strength at the cap.
- Power-up and landing previews are visible only during the held action. Ground impact warnings can remain while a launched projectile is in flight.
- Frostguard's lobbed special also aims while Space is held and launches on release.
- Nullweaver's special preview is visible while Space is held; its free placement and 180-degree rotation are retained.
- Existing channel attacks keep their own input rules. Mastery replacement attacks retain their authored styles.
- Opening a menu, losing focus, death, stun or changing hero cancels a held charge. Charges time out after 8s without firing.
- Mouse, keyboard and touch share the controller. Touch aim uses the right stick; keep the ability button held to charge and release to send it.
- Multiplayer uses reliable begin/release controls, bounded aim updates, host-measured charge duration and existing cooldown acknowledgements. Client-supplied power values are ignored. No extra server state is required.

## Documentation and verification

The character cards and Ability Design Catalogue describe the new controls. No heroes or saved profiles are removed.

Automated Godot scene tests passed for tap/full-charge damage and speed, growth in projectile collision size, chip landing distances/fragments, sky comet, Thunderfall placement, knockback/stun, Mara bleed, copied mirror fan, cooldowns, menu/focus/stun cancellation, touch and Space releases, book target distribution, projectile clearing and host/guest message handling. v113–v116 regression checks passed. Rendered screenshots were inspected for idle/charging chip markers and comet flight. ZIP integrity and full extraction are verified during packaging.

Physical phone play and a live two-computer school network match still need a smoke test; automated packet tests do not reproduce real network latency or browser GPU conditions.

## Deploy

1. Extract this editable project ZIP and open its `project.godot` in Godot.
2. Re-export Web using the existing preset; replace the complete itch.io Web upload.
3. Rebuild the Windows download using the included build instructions/workflow and replace its complete download archive.
4. Refresh both multiplayer clients so everyone uses v117.
5. No Render file, command or setting changes are needed.

This ZIP contains the editable source, not a compiled Windows player or Web export.
