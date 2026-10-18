# Crossroads: Realms Beyond — v180

This update expands long-term fishing, Deepwell mining and Overcharged rewards, fixes school entries and adds town crown controls. It retains the existing profile save location, service URLs, currencies and T4 protocol 11.

## Upload order

1. Back up the current player profile and keep the previous web build.
2. Upload the **contents** of `Crossroads_v180_Server.zip` to the existing T4 GitHub repository root. Keep `Dockerfile.network` at the repository root; do not put the whole upload inside a new enclosing folder.
3. Let Render deploy that commit (or manually deploy its latest commit). Use the existing service, database, `DATABASE_URL` and `REPORT_SIGNING_SECRET` values.
4. Open the service's `/health` page. It must report `V180-preview`, protocol `11`, and ready `true`. A successful GitHub upload alone does not confirm a successful Render deployment.
5. Replace the itch.io HTML game upload with `Crossroads_v180_Web.zip`. Its `index.html` is at the ZIP root. Let existing sessions finish, then reload all clients before comparing the expanded daily rotation.

No database reset, new database, renamed service, account migration or additional environment variables are required. Newly added relic effects need the v180 authority, so deploy game and server together. This package has been tested locally; it does not deploy your hosted service automatically.

## Cosmetic milestones

| Style | Requirement |
| --- | --- |
| Wisp Skull | Discover 50 fishing species |
| Silver Revenant | Clear Ram's Descent floor 50 |
| Bronze / Silver / Golden Laurel | 15 / 30 / 50 Challenge Lodge medal points |
| Echo of the Four Paths | All four Expert realm badges; renamed from Easter Egg |
| Astral Sovereign | Astral Rift badge plus completed Attunement |

Existing records determine eligibility. A selected Wisp, Revenant or Laurel below its new threshold stays in the save but its effect is hidden until earned again. Previously earned relic items, fish, equipment and currencies are retained.

The Atelier includes Damage Crown with a live hero preview, rank requirements and a Show/Hide crown in town control. This is independent of other cosmetic selection. It does not disable crown gameplay bonuses or hide the crown in multiplayer lobbies. Crowns remain hidden during combat, use rolling seven-day damage, and cannot equip expired historical ranks.

## Fishing progression

- Level cap **80**; **60 perks** across Rodcraft, Netcraft, Basketcraft, Watersense, Trailcraft and Stewardship.
- Each specialization has ten connected nodes and two later forks. Switch specializations using the named branch controls, then scroll its tree. Cards have opaque backgrounds and connectors stop at card edges.
- Earn one point every three levels through level 78: **26 points total**, so all 60 perks cannot be learned. A full ten-node branch plus another full branch still leaves six points for a third.
- Existing XP thresholds through level 40, learned talents and equipment are preserved. Level 40 takes 181,207 cumulative XP; level 80 takes 4,284,067. Later levels rise steeply. These are balancing targets, not a claim that every player will take a specific number of hours.
- Rod/net specializations extend timing, bite chance, XP and modest rarity weights; Basketcraft can place a fifth basket in a different hole and reach a 13-minute fill time.
- Trailcraft expands the base 50-fish bag to 100 when fully invested, improves fish-sale prices and conserves bait. Stewardship adds modest XP, crafting, timing and trophy benefits.
- Existing conditions, real-time windows and level-one access to rod species remain. Base rarity bonus stays capped at 10%; method perks are modest additions. Bite chance caps at 98%, bait retention at 55%, and timing reductions are bounded.
- Resets still cost 500 Glimmers initially, +250 per reset up to 2,500, refund points without resetting XP or equipment, and require collecting/retrieving placed baskets first.
- New fishing appearance milestones at levels 60 and 80. Newly claiming Riverkeeper's Covenant now requires **level 80 and 50 species**. Existing claimed Covenants remain owned.
- Kept fish detail buttons and clickable tank inspections from v179.1 remain available. Weight-based tank scaling is unchanged.

## Deepwell: Lanternrail Underworks

The mine now supports **40 shafts**, **40 building levels**, mine level 100 and four additional deep milestones. Crews, currencies and portable saves carry forward. The old eight-building save is accepted and the four new building levels initialize at zero.

| Shaft | New underground building | Effect per level |
| --- | --- | --- |
| 22 | Underground Rail Depot | +4% lift capacity |
| 26 | Deepcrew Refuge | -2% air demand, capped at 30% |
| 30 | Prismatic Sorting Hall | +5% gem recovery |
| 36 | Bedrock Enginehouse | +3% digging output |

The new Underworks tab shows a lit underground operation, moving ram workers and rail cart, unlock conditions, upgrade costs and build times. Deep expansion needs stronger mine levels, forged construction bars, underground infrastructure and later Descent milestones (20, 35 and ultimately 50). Starting shaft 21, construction takes real hours, increasing with depth. Offline production remains capped at 24 hours and pauses when storage is full. Nothing converts Mine Gold into combat currency or bypasses resource costs.

## Three more Overcharged destinations, nine families

The eight-day rotation adds Silverfall Reach, Clockwork Orchard and Astral Rift. Normal realm access and Attunement still apply. Entry costs, chance-based drops and per-realm pity remain: no new relic startup grants.

| Realm | Relic | Effect |
| --- | --- | --- |
| Silverfall Reach | Ferryman's Oath | Dodge grants 6–9 shield HP for 4s, 10s cooldown. **Reed additionally heals 3 HP**. |
| Silverfall Reach | Undertow Seal | Hit slows target 25% for 0.8–1.1s, 7s cooldown. |
| Silverfall Reach | Tideheart Vessel | Healing food empowers next hit within 4s by 8–12%, 10s cooldown. |
| Clockwork Orchard | Stormscribe's Lost Folio | Every sixth hit echoes 8–12 damage, 6s cooldown. **Stormscribe arcs half the echo to up to two nearby foes**. |
| Clockwork Orchard | Orchard Flywheel | +3–5% attack damage while above 80% health. |
| Clockwork Orchard | Secondhand Aegis | First hit after 8s without incoming damage is reduced 10–14%. |
| Astral Rift | Echo of the Rift | Hit echoes 6–9 damage against the target, 10s cooldown. |
| Astral Rift | Gravity Anchor | Dodge primes next hit within 4s to slow 40% for 0.8–1.2s, 10s cooldown. |
| Astral Rift | Eventide Heart | Kill heals 3–5 HP, 12s cooldown. |

All nine work with all heroes. Hero bonuses are additional synergies tied to established lore. Echoes are queued and cannot recursively trigger relic effects; shields do not accumulate. The existing shared Stormglass drop remains possible, and Conclave encounters can roll the expanded realm families.

## Fixes and validation

- All three school scenes now use campaign-matched entry/return coordinates. Solo movement and two-player authority movement are checked from actual scene spawns.
- Leaving a realm through its entrance is recorded as an unsuccessful return, grants no clear/relic reward and returns to the town portal. Defeat returns to a movable healer entrance.
- Cosmetic ranking HTTP failures/invalid bodies use a graceful unavailable state without an unnecessary JSON parse error.
- Client/server and report build labels now agree on V180-preview. Save schemas and protocol 11 remain stable.

Validation results are included under `validation/v180`. Local socket checks cover eight-player Arena and Battlegrounds, four-player Gate Defence and Descent, two-player co-op, reconnects and signed ranking effects. These do not replace Monday's real school-device/network playtest or guarantee a frame rate on every device. Progression pacing should be reviewed using actual play reports.
