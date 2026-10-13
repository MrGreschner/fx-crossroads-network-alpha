# Grow the quest world

Wayfarer Wilds is a quest expedition, separate from the realm portal. Walk east past the Training Yard to the forest sign. Continue solo with any hero, or open a co-op room and host/join as usual. Co-op supports 2–4 heroes.

Speak to Edda and Orrin in Willowrest. Their quests open Sable's quest. Use E / touch Interact to talk, collect objects, activate mechanisms, and use dungeon entrances. Q / Journal opens the quest list; Up / Down scrolls when more quests are added. The map shows villagers (gold), dungeon entrances (blue), and objectives (green). The arrow points toward the next objective or its dungeon entrance. The resting spring in the village restores 4 HP per second while no enemies are nearby.

## What saves

Progress is saved at acceptance, collection, stage transitions, and turn-in. Solo progress belongs to this browser/computer. Co-op uses the host's separate campaign save; both players can advance shared objectives and each receives turn-in gold. Guest progress does not overwrite their solo campaign. In-progress battle encounters respawn after re-entering; collected objectives and completed quests remain recorded. Returned quests do not pay out twice. The forest entrance offers a fresh solo expedition if you want to replay. Returning to the waystone before finishing saves your progress; after all quests it finishes the expedition.

## Add a quest without changing GDScript

1. Open `content/quests/wayfarer.json` and append a quest to `quests`.
2. Give it a permanent, unique `id`. Set `npc` to an NPC's `id`. An NPC can offer more than one quest; active quests are offered first, and completed ones are skipped.
3. Add a `title`, `offer`, `reward_gold`, `requires`, and ordered `stages`. `requires` holds quest IDs that must be complete. Use `[]` for no prerequisite.
4. Choose supported stage types below. Positions are world coordinates. Surface is above y=6500; use established dungeon rooms for underground objectives. Use the Godot access check when authoring a new position.
5. Test the journey, including returning to its giver. Run `python3 tools/validate_quests.py` from the project folder to catch missing IDs, invalid stage types, unknown enemies, and prerequisite cycles.

| Stage type | Purpose | Required content |
| --- | --- | --- |
| `collect` | Recover one or several guarded objects | `targets`: unique `id`, `name`, `pos`; optional `encounters` |
| `switches` | Activate seals or mechanisms | Same targets; optional encounters |
| `visit` | Interact at a destination | One or more targets |
| `clear` | Defeat a particular encounter | Nonempty `encounters`; other patrol enemies do not count |
| `report` | Speak to the quest giver and earn the reward | Final stage; no targets required |

Encounter records use an existing enemy `type`, a `pos`, and optionally `hp`. The host scales HP for the party. Enemies at an objective must be cleared before interacting. For now quest encounters use `boss: false`; a large guardian can use a high-HP custom enemy such as `rootbound_keeper`, keeping regular realm completion logic out of the quest chain.

Example: append this record after the original three quests:

```json
{
  "id": "willowrest_harvest",
  "title": "The First Harvest",
  "npc": "orrin",
  "requires": ["mill"],
  "offer": "The mill is working again. Bring in the first harvest from our field.",
  "reward_gold": 18,
  "stages": [
    {
      "type": "collect",
      "text": "Collect Willowrest's harvest",
      "targets": [{"id": "harvest", "name": "Harvest basket", "pos": [2240, 2310]}]
    },
    {"type": "report", "text": "Bring the harvest to Orrin"}
  ]
}
```

Add villagers to `npcs` with a unique `id`, `name`, `pos`, and `sprite`. The sprite loads `assets/<sprite>.png`; the existing Edda image is the fallback. Existing villagers can offer new stories too.

Add a dungeon entrance to `routes` with `name`, `pos` (surface), and `end` (dungeon). A return entrance is generated automatically; arrivals are 100 units south of the paired entrance, so leave that ground clear.

## Keep it expandable

Keep quest IDs and target IDs stable when editing an existing campaign so saved progress remains meaningful. Append quests rather than inserting stages into a quest students already completed. `version` is the save-format version; keep it at 1 for ordinary content additions. New quest IDs are added to old saves automatically. Hero levels are capped at 10 as more quests are added.

Different campaigns can have different JSON files through the region's `quest_campaign` field and an entry in `manifest.quest_regions`. They appear in the co-op selector, separately from `manifest.regions`. A genuinely new map still requires authored terrain: the first expedition's surface, rivers, collision, scenery and dungeon geometry live in `scripts/quest_world.gd`. Adding new objective types (escort, crafting, dialogue branches) also requires extending the shared controller. This first version supplies reusable objectives and save/sync support rather than claiming those future systems already exist.

Suggested student roles: writers create NPC dialogue and quest chains; Design students make NPC, environment and enemy assets; CS students extend objective types or geographic maps. Give each contribution a stable ID so separate additions can coexist.

## v57: Eastern expansion
The campaign now has five quests. `summit_bell` follows `waylights`; `skyworks` follows `mill`. Surface bounds are 16000 by 6500, with underground rooms below. The eastern mountain switchbacks and Skyworks causeways are defined in `scripts/quest_highlands.gd`; floor rectangles are shared by collision and scenery. Update that geometry before placing objectives outside the existing routes. `summit_golem` uses a 0.9-second, fixed-position slam warning; the host replicates that warning separately from quest state. Keep save version 1 when appending compatible quest content.
