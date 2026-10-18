# V179 • Gleam Atelier & shared competitive cosmetics

## Update both client and server

1. Extract Crossroads_v179_Server.zip. Upload its **contents** to the existing GitHub repository used by the T4 Render service (Dockerfile.network stays at repository root). Keep the existing Render service, database and environment settings.
2. Deploy the latest commit on Render. This build identifies as **V179-preview**, protocol **11**, report schema **3**. Open the service’s `/health`: check build V179-preview and `ranked_cosmetics.ready: true`.
3. Upload Crossroads_v179_Web.zip to the existing itch.io browser-game entry. It has index.html at its root. The updated client keeps the current server URL.
4. For local Godot editing/debug, extract Crossroads_v179_Editable.zip and open Crossroads_Realms_Beyond/project.godot with Godot 4.5.1.

No new database or manual SQL is required. The service automatically adds `crossroads_cosmetic_lifetime` and `crossroads_cosmetic_week` using the existing DATABASE_URL. Keep REPORT_SIGNING_SECRET stable and at least 32 characters, as already required by report/activity setup. Do not clear the database. Existing reports and activity tables are preserved. If rankings are not configured or the database is unavailable, gameplay and local cosmetics remain usable.

## Dedicated Atelier interface

The town’s Gleam Atelier now opens its own gallery with the selected hero’s actual sprite and animated cosmetic preview. All styles, Earned and Competitive are explicit categories. Locked styles can be inspected without equipping. Every style explains its unlock. Town/Lobby preview distinguishes comparative effects, and the interface links to weekly goals and Journey titles/ribbons.

These former weekly-damage effects now have permanent, distinct requirements:

| Style | Requirement |
| --- | --- |
| Wisp Skull | Discover 10 different fish species. |
| Silver Revenant | Reach Ram’s Descent floor 25. |
| Astral Sovereign | Clear Astral Rift and complete Attunement. |

They keep their stable saved cosmetic IDs. Previous weekly damage alone no longer qualifies these styles; eligible players can equip them again. Their appearance is distinct: trailing skull wisp, silver spectral guardians, and an astral orbit.

## New competitive styles

| Style | Current standing | Period |
| --- | --- | --- |
| Vanguard Comets | Top 10 total damage | Monday 00:00 Edmonton to next Monday |
| Leviathan’s Wake | Top 10 heaviest single fish, measured in kg | Same weekly period |
| Eternal Constellation | Top 5 lifetime damage | All time; no weekly score reset |

These are additional appearance effects alongside crowns. They appear only in multiplayer lobbies and the Atelier’s lobby preview, never in town or combat. Eligible players can show/hide each independently. A player must currently hold the required place; falling below the cutoff removes eligibility at the next comparison. Existing weekly activity cosmetics still follow their existing Sunday schedule; damage crowns retain their rolling seven-day rules and power.

Rank comparisons refresh approximately every 45–50 seconds while connected. A server-signed confirmation lasts no longer than 90 seconds; weekly confirmations cannot cross the server’s Monday reset. Expired or offline cached qualifications do not keep displaying an award. New players with zero damage or no weekly catch do not receive places. Ties prefer the first player to reach that score, then a stable profile identifier, keeping strict top-ten/top-five limits.

The comparison uses a portable anonymous profile identifier, so the same downloaded profile on another device remains one entry. Repeated submissions and older copies cannot add the same totals twice: the server retains the highest snapshot for that profile and period. Lifetime damage already in the profile counts; this week’s damage is reconstructed from the existing timestamped crown ledger. Weekly fishing begins with catches recorded in v179; kept and released catches both count, and selling/releasing a fish does not erase the submitted best.

The database stores hashed profile identifiers and scores, not student names. A public named leaderboard and cloud accounts are not part of this release. Solo totals still originate in local saved profiles: this is a server-compared ranking system, **not account-backed anti-cheat verification**. Server-signed awards prevent clients from simply claiming a ranked lobby effect, but accounts and trusted progress verification are needed before treating the rankings as tamper-proof competitive records.

## Validation

- 24 Godot checks: distinct unlocks, persistence, Monday rollover, fish tracking, gallery behaviour, preview-only locks, expiry and portable profile compatibility.
- PostgreSQL-compatible database engine: 12 profiles, score ordering, monotonic updates, stable ties, weekly reset, restart persistence, bad inputs and HTTP/CORS validation.
- Real Node gateway + Godot authority: verified award propagation, forged/expired claims stripped, visibility toggles and match startup.
- Eight-client regression: crown/competition settings, authoritative match start and reconnect.
- Browser rendering: desktop, phone landscape, long Competitive descriptions and the actual eight-player lobby widget, with no script errors.

See validation/v179 and network_tests/v179_* for the retained checks. Database regression requires the optional @electric-sql/pglite test package; production dependencies remain pg and ws.
