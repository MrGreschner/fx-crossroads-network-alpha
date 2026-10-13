# v44 — The school adventures

Three new realms use connected rooms, collision walls, locked doors, stage objectives and shared enchanted-school enemies. The existing 27 heroes, quest expedition and earlier realms remain.

| Realm | Difficulty | Route |
| --- | --- | --- |
| Firstbell Elementary | Easy | Street → halls and two classrooms → unlocked playground and Recess Ringleader → return patrol → giant yellow Last Bus on the starting street |
| Crossbell Middle School | Medium | Street → library, science lab and gym → collect three bell gears → cafeteria and Lunchline Leviathan → rooftop patrol and Bellwork Colossus → street |
| Crossroads High | Hard | Street → Drama, Kitchen and Gym patrols and guardians → upstairs corridor → unlocked Final Exam classroom → street |

Use E or mobile Interact near ordinary doors, bell gears and stair markers. Objective text and the compass guide each stage. Finish the adventure by interacting at the original street return portal after defeating the final boss.

The Last Bus has a large visible body, a slow telegraphed charge and capped waves of melee chalkling passengers. Gravel Skaters throw rocks, then dash through a player's position to an equally distant point beyond it; walls stop their dash. Shared pencils, backpacks, paper sprites and hall-pass sentinels tie the campuses together.

High School's three department bosses are Spotlight Sovereign, Layercake Golem and Iron Barbell. Once their wings and the upstairs patrol are cleared, entering the final classroom randomly chooses one exam for that run:

| Exam | Four attack patterns |
| --- | --- |
| Mathematics | Burning fire fan, crossing flame lines, meteor marks, radial fire volley |
| English | Weaving wind volley, untargetable ghost phase and reappearance blast, dash, travelling gust waves |
| History | Slowing icicle fan, ice field, advancing frost waves, persistent chill aura |
| Science | Poison puddles, advancing reaction blasts, toxic radial volley, culture summons with poison bolts |

The host chooses the exam once and replicates it to teammates. School milestones grant minimum ability levels to every teammate, including support players who have not scored kills. Boss health scales with party size. These milestones do not heal players.

## Installation

Extract this editable project, open `project.godot`, allow Godot to import the assets, then press F5. Export a fresh Web ZIP and upload that exported ZIP to itch.io. This source ZIP is not the Web export. Everyone in a co-op session should use the same build. No Render service change is required.

## Validation

Godot 4.5.1: solo progression and collision tests for all three schools; all four exam attack sets; skater pass-through damage; fire/ice/poison effects; host/guest state replication and remote interactions; co-op ability unlocks. Existing v38–v43 regression suites also passed. School scenes and original pixel assets were rendered and visually checked with the Compatibility renderer.

Physical-phone touch controls and live browser-to-browser networking still need a short playtest after Web export. Local replicated host/guest tests do not establish live WebRTC connectivity or classroom-device performance.

See `SCHOOL_AUTHORING_GUIDE.md` for teaching and extending these adventures.
