# v132 validation

- Godot 4.5.1 headless editor import / parse passed.
- Focused checks passed: Sunday boundaries; 10k/20k/30k thresholds; weekly expiration; permanent Easter Egg after all four expert badges; protected Game Dev/Playtest damage; profile validation; cosmetic picker input blocking; schema validation and capture/apply for all four labs; invalid drafts retain the last valid copy.
- Actual local WebSocket test with two Godot clients passed: shared hero and observer lock, pencil handoff, reverse edits, identical ability/enemy/behaviour copies, portable export dialog, disconnect recovery and remaining editor promotion.
- All 46 room-service tests passed, including two-seat limits, cached joins, writer enforcement, request/pass, stale and invalid transfer rejection, payload limits and disconnection cleanup.
- v131 polish, v130 Game Dev and v130 Classroom/examples regressions passed.
- Rendered 1280×720 visual review: cosmetic picker, Playtest blue border, Partner Up dialog. Corrected the partner dialog's initial hidden-layout height and reserved a bottom toolbar area in all four labs during collaboration.
- All 80 official hero entries and existing official content/artwork retained. ZIP CRC, extraction and previous payload retention verified.

These are local tests. No claim is made that the live Render deployment or every school device has been tested. Weekly cosmetics use the local clock. Partner editing is one writer at a time and does not merge simultaneous changes.
