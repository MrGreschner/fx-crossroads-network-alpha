# Hero library — browsing and student additions

The current roster has 74 heroes, all available from the start. Mastery earns titles and optional techniques rather than access to characters.

## Browse the Character Hall

- Search by name or exact roster number. Clear search to show everyone.
- Filter by Melee, Ranged, Support, Control or Summoner. A hero can have several tags.
- Difficulty describes learning the hero, not its strength.
- Tap the star to favourite a hero. Favourites appear first, preserving roster order inside each group. The hero keeps its full-roster number.
- Select a hero to see a short playstyle summary and four cards: Primary, Secondary, Passive, Special. All four are compact by default. Click or tap a card for the detailed effect and cooldown; click again to close it.
- **Story** explains who the hero is and their background. Mastery choices follow the four normal abilities.
- Continue, Close, Enter or Escape returns to town. Native lists support dragging, scrollbars and the mouse wheel.

## Roster numbers

`content/manifest.json` sets the authored order. `content/hero_numbers.json` assigns that order consecutive display numbers. Harbor Bell is 20 and Polarity is 21. Numbers are labels; profile progress uses internal hero IDs.

When adding or rearranging heroes, regenerate the number mapping in the same order, starting at 1. Do not number by the current filtered/favourite list. Keep internal IDs stable so profiles retain the correct hero progress.

## Add a hero

1. Create `content/characters/<id>.json` with normal abilities, passive, both independent mastery choices and title. Implement new styles in the authoritative combat code.
2. Add idle, walk1, walk2 and attack pixel-art poses under the sprite prefix. Add any extra casting poses and bounded effects needed by the kit.
3. Add the ID once to the manifest and refresh the roster number mapping.
4. Add metadata in `content/hero_library.json`: `role`, `tags`, `difficulty`, `home_realm`, `summary`, `lore`, `passive_brief`.

Keep `summary` to one short gameplay sentence. Keep `lore` to one or two sentences explaining what the character is and where they fit into the world. `passive_brief` is a short effect summary; the hero file's full passive text remains available when its card is expanded.

An ability can optionally have `ui_brief` to override its compact-card summary. Put the complete targeting, duration, damage rules and cooldown explanation in its usual `description`. Changing displayed text does not change its actual mechanic.

Missing metadata receives a fallback so new additions remain selectable. Explicit metadata makes the hero easier to understand. New mechanics also need multiplayer snapshots, touch input and both mastery variants.

Run `python3 tools/release_audit.py` to check roster, art and mastery data. Use `ABILITY_CATALOG.md` for current styles and design requirements. The legacy content-manager installer has an old restricted whitelist; it is not validation for the expanded roster.

## Profiles on school computers

Profiles stay local unless downloaded and moved manually. The main menu offers Upload and Download; both require town. Before leaving a shared computer, download the profile, then Clear profile and confirm. Clearing removes local backups but does not delete downloaded files.

Local saves retain a last-good backup, and imports are checked before replacing current progress. This is portable profile storage, not a cloud account.
