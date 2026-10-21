# Crossroads: Realms Beyond v198.2

Built on the approved v198.1 pixel update. v199 is not included.

## Art
- Rune Duelist: slim teal duelist, one-sided cape, runes and inscribed sword.
- Dustdevil: enchanted brass workshop vacuum, wheels, ribbed hose, intake sparks.
- Merrymask: carved wooden theatre puppet, jointed limbs, asymmetric stage costume, crossed strings and understudy mask.
- Six transparent 64×64 poses each, editable through tools/build_pixel_198_2.py.
- The eight accepted v198.1 heroes and all other hero artwork are unchanged.

## Moving primary attacks
- Cairnheart: the first fault erupts immediately. Each later eruption starts from his current position, along the original aim. Rocks already erupted remain planted. Each enemy takes damage only once per cast.
- Backbeat and Harbor Bell: primary sound rings follow their moving owner. Both graphics and authoritative damage use the moving centre. Hits are bounded to one per enemy per ring. Other sound-wave abilities retain their original ground origin.
- Hearthwarden: hammer graphics follow his body. The opening hit remains immediate; the short 0.18-second active swing can catch enemies as he moves, once per enemy. The 22/22/33 combo, cooldown and third-hit knockback remain.
- Attached graphics use predicted local positions and buffered remote positions in multiplayer. Dead casters stop further attached attack damage.

## Deployment — manual
1. Update the existing Render service/repository using Crossroads_v198_2_Server_Update.zip. This is a complete runtime archive, not an incremental patch. Extract its contents into the existing project root; do not create an extra nested project folder. Keep Dockerfile.network as the Dockerfile path.
2. Keep the existing Render database, persistent disk, environment values, account data and keys. No database migration or save reset is required. Do not create a replacement database or delete existing data.
3. After the server is healthy, upload Crossroads_v198_2_Web.zip to the existing itch.io HTML5 game.
4. Refresh clients so server and clients use build V198.2-moving-primaries, protocol 11. Mixed old/new clients should be refreshed.

Crossroads_v198_2_Editable.zip contains the full editable Godot project, art generators, QA and release notes. It excludes generated caches and secrets.

## Validation
- 80 targeted checks: moving attacks, immediate faults, planted rocks, once-per-target damage, original combo damage, expiry/death, JSON snapshot positions, predicted/buffered graphics and all 18 new art poses.
- Solo primary checks and existing combat/protocol, 80-hero effect attachment and saved-build consistency checks.
- Existing Shatterfloor objective/AI regression: 32 checks, seven bots, three rounds.
- Packaged runtime checked after rebuilding, including edited scripts and added art.
- No live deployment performed. Real-device playtesting remains: test held movement in several directions while clicking primary, in solo practice and two-player arena; check artwork in hero cards, selection and gameplay.
