# Crossroads v178 — rolling crown progression

## Upload order

1. Replace the files in the existing T4 GitHub server repository with the contents of Crossroads_v178_Server.zip. The ZIP contains the complete server tree at its root: upload the extracted files, including the new scripts/crown_view.gd.
2. Deploy that repository to the existing paid Render service. Keep the existing environment variables, reporting keys and database connection.
3. Check `/health`: `ready: true`, `build: V178-preview`, `protocol: 11`, `crown_stages: 18`, `crown_competition: true`.
4. Upload Crossroads_v178_Web.zip as the HTML5 build on your Realms Beyond itch.io playtest page. All six web files are at ZIP root.

This update changes gameplay and requires matching v178 client/server files. Protocol 11 prevents an older server/client from silently missing the new crown rules. The database schema and report schema (3) are unchanged. Client diagnostics, server health and new report/download labels all use V178-preview.

The polished v177.2 single sun/moon intro is retained. Solo gameplay remains local to the device; this update does not add cloud accounts or change profile ownership/storage.

## Crown milestones and bonuses

The first seven thresholds are unchanged: 1,000 / 3,000 / 7,000 / 15,000 / 25,000 / 40,000 / 65,000 damage.

| Crown | Rolling damage | Extra crit chance | Extra crit damage |
|---|---:|---:|---:|
| Celestial I | 100,000 | +2 percentage points | +5 percentage points |
| Celestial II | 120,000 | +2 | +10 |
| Celestial III | 140,000 | +2 | +15 |
| Celestial IV | 160,000 | +2 | +20 |
| Celestial V | 180,000 | +2 | +25 |
| Omnipotent I | 200,000 | +4 | +30 |
| Omnipotent II | 220,000 | +4 | +35 |
| Omnipotent III | 240,000 | +4 | +40 |
| Omnipotent IV | 260,000 | +4 | +45 |
| Omnipotent V | 280,000 | +4 | +50 |
| Beyonder | 300,000 | +6 | +50 |

Damage is shared across heroes on the same player profile and counts across ordinary solo and multiplayer combat. Crowns continue to use a trailing 168-hour window, recorded in minute buckets, rather than a Sunday reset. When damage ages out, the current rank, visible crown and power drop accordingly. Local totals refresh on the existing ten-second crown check.

There is NO permanent equip option. The highest crown is retained as a text achievement record only. It does not restore an expired crown's appearance or power. Choosing a historical style in an edited packet does not equip it.

The current crown appears on the character card, in town/adventures and in the actual T4 party lobby/world. Celestial has five stage gems; Omnipotent has a distinct winged silhouette and orbiting accents; Beyonder has a restrained cosmic ring. Geometry is bounded; no particle textures or full-screen shaders were added.

The Profile character card stays first. Its header shows the current crown; below the card is a graphical Crown Journey panel with current damage, next milestone, progress bar, active power and personal-best record. Records & style also contains the crown panel.

## Combat and competition rules

Crown crit chance adds to hero mastery chance. Crown crit damage adds to the existing extra critical damage after hero-specific mastery modifiers, rather than multiplying the combined bonuses. A critical hit that previously dealt 150% damage deals 200% with the +50-point crown bonus. A hero without mastery can still crit through its crown; at Beyonder this deals 150% base damage on a successful crown crit.

Crown bonuses work through the shared critical-hit path used by all heroes. Rival summons also use that path; their existing owner/team checks prevent own-summon farming.

In the T4 lobby, the host can enable **Competition • crown bonuses OFF for everyone** before Start. The rule is replicated to all players, enforced by the server, cannot be changed by guests or during a match, and survives reconnect. It removes crown power only; existing mastery, hero, item and relic rules are unchanged. Crowns remain visible and valid damage can still earn progress. Training/practice also disables crown power and awards no crown progress.

The server sanitizes reported crown damage, recomputes rank/bonuses and accepts only bounded expiry schedules derived from the local rolling history. Current-match bonuses are based on the launch build; newly earned higher ranks apply when entering the next match. The transmitted expiry schedule can reduce a crown's power/appearance during a live match without waiting for a new client profile offer.

Profiles remain local/importable as before, including mastery. This is not cloud account verification; local save editing is not prevented by this update.

## Damage accounting and saved profiles

Only damage actually removed from a valid hostile target counts. Overkill is capped to remaining health. Training dummies, self-damage, friendly targets and owned/friendly summons award no crown damage. Multiplayer rewards continue to use authoritative cumulative damage and existing idempotent match cursors, avoiding duplicate awards after repeated snapshots or reconnects.

Existing rolling-damage v1 profiles migrate to v2 without changing their buckets. The highest record is initialized from the valid current history available at upgrade; expired historical achievements that were never stored cannot be reconstructed. New highest records survive expiry and profile transfer. Existing hero, fishing, currency, realm and learning data are retained.

## Validation included

- Runtime crown checks: all milestone boundaries, additive bonus math, migration/profile serialization, invalid values, expiry, non-equippable archived records, hostile-target accounting and dedicated-server competition behavior.
- Eight-player WebSocket lobby/start/reconnect: authority and report identity, old-protocol rejection, bounded crown expiry replication and host-only competition controls.
- Mode starts/snapshots: Arena 8, Gate Defence 4, Ram's Descent 4, realm co-op 2 and Battlegrounds 8.
- Real packed browser UI inspection at desktop and landscape phone sizes.
- Complete extracted server import/start/health verification and release ZIP CRC checks.

These are automated local checks, not measurements of school-computer frame rates or school-network latency. Existing classroom playtesting remains useful.
