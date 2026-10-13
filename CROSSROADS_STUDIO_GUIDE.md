# Crossroads Studio — create, code, test and share (v129)

## Find the Studio

Use **Crossroads Studio** on the main menu or in the Character Hall. In town, the new brick Studio building is east of the Training Yard, on its own terrace before the river bridge. Enter its glowing threshold with E. Inside the small classroom, walk to the ram teacher, press E or use **Talk to the teacher**. He explains the workflow and opens the Studio.

The Studio hub offers two connected tools: **Hero Workshop** and **Ability / Attack Lab**. It pauses the solo world while you create. All 80 official heroes keep their existing art, abilities and roster order.

## Build a complete hero

1. **Concept:** name, author, role, species, lore and design intention. Choose health and speed within the supported limits.
2. **Artwork:** upload PNGs or choose **Edit pixels**. Create Idle, Walk 1, Walk 2 and Attack. Copy an existing pose, mirror it or shift it one pixel; then alter feet, wings or weapon position. The live walk preview alternates the two walking images.
3. **Abilities:** choose a built-in behaviour or a saved **Custom** Lab ability. Tune damage, reach, charge, cooldown and effects. The available fields reflect the selected behaviour.
4. **Passive:** choose from 17 supported options. Aura settings apply to Mending, Shelter and Frost; personal/on-hit bonuses remain personal. Overload uses the configured radius. Read the explanation before enabling an aura.
5. **Mastery:** create alternatives for two different ability slots. Enable them in tests to compare against the original moves.
6. **Start test**, immediately after Mastery: play a synthetic target/combat scenario. Finish, write observations and download Markdown or JSON reports.
7. **Add to Custom Hall:** saves this project as a local playable hero. Character Hall starts with the official roster; toggle **Custom heroes** for your creations. Use them in the training yard or solo realms.

Custom heroes are not available in official multiplayer rooms in this release. Their code and artwork would need a validated multiplayer transfer protocol and balance rules before that is supported. Sharing a file lets another person import and play the creation locally. Importing does not publish it to everyone.

## Pixel and animation editors

The pixel editor provides pencil, eraser, fill, colour picker, a small palette, hex input (`#RRGGBB` or `#RRGGBBAA`, press Enter), undo, mirror, flip and one-pixel shifts. Blank grids are 16, 32 or 64 pixels square. Uploaded PNGs may be up to 256 × 256 and 128 KB each. Transparency is supported; the checkerboard is only an editing background.

**Design lesson** covers silhouette, contrast, colour, emphasis, balance, unity, rhythm, movement and accessibility. Test the artwork at small size. Keep the face and ground contact aligned across poses.

In Ability Lab, **Edit animation** creates up to eight pixel frames. Add/copy a frame, edit it, then watch the live frame preview. Attack frames play at 8 FPS, including on travelling projectiles. Pixels are visual; the chosen behaviour and range/radius define collision. A large drawing does not automatically create a larger hitbox.

## Build an attack step by step

- **Build:** choose Melee, Ranged / projectile, Control / support or Summoning. Choose a behaviour, switch charge on/off and select a charge visual. Ring, growing projectile, orbiting sparks, runes, embers and custom pixel frames are available.
- **Shape:** melee gets reach, arc (360° hits all around) and strike artwork. Ranged gets projectile artwork, straight/lob/homing/return/wave flight, direction or mouse-point destination, aim guide, range, speed, count and spread. Control gets ground placement, radius and duration. Summoning gets six minion looks or a custom PNG, melee/ranged/healing behaviour, health, speed, attack interval and lifetime.
- **Power:** damage, ally healing, life steal and cooldown. Charge strengthens damage, healing and impact radius. Life steal is a percentage of actual damage.
- **Effects:** slow, stun, burn, poison or bleed; duration and damage over time; custom attack frames.

The **Interactive test** switch stops automatic replays. Click the preview to focus it, use WASD or the arrow buttons to move, aim with the mouse and press/release LMB to attack. Touch can aim and hold/release an attack. The green ally tests healing. Switch Interactive off for the automatic charged replay.

In Hero Workshop, each ability has a **Custom abilities** switch. Built-in behaviours and saved Lab abilities have separate selection areas. Custom files keep their artwork, charge frames and all these settings when shared through an ability file or profile ZIP.

## Ability Lab and learning code

The Lab places GUI controls, editable code and a live graphical replay beside one another. Changing a numeric GUI value updates its `let` declaration. Editing valid code updates the runtime values. Invalid code shows a line-specific error; the last valid attack remains the preview. **Replay** demonstrates a fully charged cast and repeats every five seconds.

Save with **Save to Workshop** to add the ability to the Hero Workshop's Custom dropdown. **Download ability** exports a portable `.ability.json`; import it through Hero Workshop's **Open project** to add it to another device's library.

The language is **Crossroads Script**, a small educational language. It is not unrestricted GDScript or JavaScript. It supports:

```text
# Variables describe the attack.
let damage = 18
let range = 320
let count = 3
let charge = 1

# Loops repeat actions. index begins at zero.
repeat count
  emit projectile angle index * 16 - 16
end

# Logic adds a close pulse at nearly full charge.
if charged
  emit pulse
end
```

Declarations: damage, heal, range, radius, speed, count, duration, cooldown, charge and angle. Angle expressions support numbers, `index`, arithmetic and parentheses. Blocks are `repeat count`, `repeat 1–5`, `if charged` (at least 75%) and `if targets` (living target within 600 units); each closes with `end`. Use the `angle` variable in a per-action expression, such as `emit projectile angle angle + index * 12`, to offset its direction.

Actions: `projectile`, `homing`, `boomerang`, `beam`, `pulse`, `melee`, `field`, `heal`, `summon`, `dash`, `chain`, `lob`. Fields apply poison; heal emits a healing pulse. Commands can be combined, with limits of three nested blocks, 24 emit statements and 32 expanded actions per cast. Physics caps: 60 projectiles, 16 fields, five minions, 40 short effects. The parser does not allow file, network, operating-system or arbitrary engine calls.

The **CS lesson** explains variables, logic, loops, arrays, dictionaries, structure, validation and repeatable testing. GUI on-hit effect settings remain outside the textual program. Code and values together form the saved ability.

## Built-in attack behaviours

| Group | Choices |
|---|---|
| Close combat | Directional sweep, radial shockwave, dash strike, draining strike |
| Projectiles | Straight, fan, seeking, returning, burst, radial volley |
| Area and control | Beam, chain, lobbed blast, mine, flame cone, slow field, pulling vortex, poison field, teleport burst |
| Support | Healing pulse, healing field, temporary protection |
| Summoning | Temporary fighting allies, capped at five |
| Custom | Ability Lab programs combining supported actions |

Status effects are slow, stun, burn, poison and bleed. Damage-over-time values are per second. The synthetic arena stores one damage-over-time slot per target; real solo realms use the game's status system. Minions expire and can take damage. Burst uses a tightly spaced line of launched projectiles; it is not a delayed firing queue.

Passives: none, life on hit, faster primary, defence, regeneration, speed, burn/poison/slow on hit, critical chance, thorns, resilience, protective aura, healing aura, frost aura, periodic overload and longer-lived summons. Resilience concerns incoming hostile statuses in real realms; synthetic attackers do not currently inflict those statuses. Shelter protects the hero and nearby summoned allies in solo play when aura is enabled.

## Files, shared computers and submissions

**Download profile** now creates `crossroads-player.zip`. Its root contains `profile.json` and a readme, with:

- `heroes/`: one self-contained `.hero.json` per saved custom hero, including artwork, code, alternatives and reports.
- `abilities/`: one `.ability.json` per saved Lab attack, including its animation.
- `studio/draft.hero.json`: the current Hero Workshop draft.

Upload the entire ZIP in the main menu to restore progress and Studio creations. Existing old JSON player profiles still import; because they contain no Studio library, importing them replaces the local Studio library with an empty one. The import preview explains the replacement and shows creation counts. Download your current ZIP first.

To submit a weekly hero, extract your player ZIP and send the relevant file in `heroes/` plus a test report. A friend can import that JSON through Studio and click **Add to Custom Hall**. You may also add valid hero JSON files inside the ZIP's `heroes/` folder, then re-ZIP with `profile.json` at the root and upload. No script files inside a ZIP are executed or extracted to arbitrary paths.

Limits: 20 local custom heroes, 40 saved abilities, 2 MB per project, 24 MB player ZIP expanded data. Use small pixel art; keep an external archive of older projects. New Game clears the device's player progress, saved Studio library and local drafts after the existing confirmation. Game Dev mode still cannot download or overwrite a player profile; individual workshop projects remain separate educational work.

The main menu's Continue button now appears first with a gold border. New Game stays green. Studio and Lab drafts remain local to this device; always download before leaving a shared computer.

## Suggested classroom task

Create one hero with a clear trade-off and an attack containing a loop and a condition. Draw four coherent poses and at least two attack frames. Predict what a variable change will do. Compare the base and altered attack in the same test scenario, record evidence and explain improvements using three design principles. Swap the project with a classmate and reproduce a test. Submit the hero JSON, report and reflection; local reports are editable evidence, not authenticated grades.

## Deployment

Re-export Web in Godot and replace the playable itch.io ZIP. For Windows, rebuild and replace the Windows download too. This delivery is the editable source project, not a pre-exported browser or Windows build. For v129, deploy the room-service files described in DEPLOY_V129.md. Commands and environment variables stay the same; the room protocol is now 29.

## Developer extension points

`workshop_project.gd` validates project schema 1/2. `studio_script.gd` parses bounded instructions. `workshop_arena.gd` implements the shared simulation. `studio_live.gd` bridges to solo actors through stable UIDs and terrain checks. `studio_lab.gd`, `studio_pixel_editor.gd` and `studio_pixel_canvas.gd` provide creation tools. `studio_library.gd` stores local content, and `studio_bundle.gd` validates and transfers ZIPs. `studio_classroom.gd` is Mr. G's small map; `studio_town.gd` supplies its building and entry.


## v126 classroom assignment board and teaching notes

Open Mr. G’s classroom from the Studio hub or enter the Studio building in town. The assignment board on the right wall opens with E nearby; the header also has an Assignment board button. Pick from six project briefs covering playtesting, heroes/enemies, behaviour, realms, video and audio. Each explains a process, what to submit and how to check your work. Your teacher can change the briefs in content/studio/assignments.json.

Design and CS lessons are now topic-based pages with scrollable cards. The animation editor displays thumbnails and a live 8 FPS preview, with scrolling for longer frame lists. Escape closes a teaching page or cancels pixel editing. These pages provide guidance; they do not submit work to a teacher or automatically grade it.


### Rebuilding versus editing code

Changing attack family or behaviour generates a fresh program. **Rebuild code from these choices** also replaces hand-edited instructions; use it deliberately. Numeric controls update their matching `let` declarations. Artwork, aiming and minion settings remain attached to the ability. Unsupported instructions and out-of-range values cannot run.

The Lab additionally supports `healing_field`, `slow_field`, `burn_field`, `stun_field`, `buff_field`, `vortex`, `mine`, `protect`, `siphon` and `burst`. Keep instructions small, test one change at a time and explain the result in your test report.

### More passive choices

There are now 37 passive choices, including finishers, stationary or moving attack bonuses, charged attacks, low-health protection, kill healing/cooldowns, healing bonuses, minion health/speed/damage/protection/healing, fifth-cast damage, timed healing and retaliation statuses. Aura radius affects the supported Mending, Frost, Shelter, Radiance and Overload area effects; personal bonuses remain personal. Custom heroes still test in solo/training, not competitive multiplayer.


## Enemy and Behaviour Labs

Open the Studio hub to build an enemy or its decision program. Enemy Lab combines two abilities, four artwork poses and a behaviour. Save reusable flight behaviours for Ability Lab; save enemy behaviours for Enemy Lab. Battle Test lets you fight one to four copies and record evidence without changing player scores.

Advanced code Level 1 is editable; Level 2 explains methods and physics; Level 3 shows classes and object references. The latter two display real runtime source, rather than executing unrestricted student scripts. Use the controls or editable instruction code to change gameplay.

Download individual JSON projects to share heroes, abilities, behaviours or enemies. Download your player ZIP to back up saved libraries and unfinished hero/enemy/behaviour drafts. New game clears the local creations as well as progress.


## Enemy Lab in v129

Four artwork poses appear before Decisions. Choose Attack, Keep distance, Charge & flee, Sentry, Ambusher or Support patrol. The decision code remains editable in Behaviour Lab. Presets are editable starting points; choose attack reach and cooldowns that suit the movement.

Choose one, two or three attack slots. Each has a live preview, a pattern selector, an Edit attack & animation button and a saved custom-ability selector. Patterns include melee, projectiles, buffs/healing, control and summoning. Disabled slots do not execute. Enemy files still carry artwork, behaviour, attacks and reports together. Older two-attack files open normally.

The Studio entrance is now southwest of town, to the left of Squirrel Post, with a connecting path and clearance below the mine.


# v130 — Game Dev tools and classroom demonstrations

## Learn from examples
Each of the four Studio labs has five curated examples: Hero, Ability, Enemy and Behaviour. A fresh lab draft starts with a randomly selected example. Existing work takes priority. Use **Load an example** to explore another, or **Clear / Start fresh** to replace only the current draft; saved projects stay in your library. Export projects to share with classmates.

Ability Lab now includes **Before / After**: run the original and edited attack against matching targets, compare damage, hits and healing, and pin the current version as a new baseline.

## Game Dev desk
Tell Elder Ram `gameDev`, then enter `R4ms!`. Press backtick (`) to open the desk. The wings have been replaced by a halo and subtle ground shimmer.

- Random Heroes changes other human players while preserving their health percentage; Game Devs are excluded.
- Time Slow lasts 16 seconds. Other players and the world slow; Game Dev movement and core casts remain responsive.
- Summon places 1–9 enemies from the catalogue.
- Arcane Volley launches 40 staggered missiles at your selected area, each dealing 3 base damage with a brief stun.
- Blink, Rally, Projectile Sweep and Spotlight help you move, reset battles, clear projectiles and point things out.

Using these powers marks the match as a test session. It cannot award competitive results or player progression. Game Dev profiles cannot be exported as player progress. Leave the test session to resume normal play.

## Classroom Broadcast — 31 student seats
1. In Game Dev mode open the desk and choose **Host • Classroom Broadcast**.
2. Share the displayed classroom code. Students choose **Watch class** on the main menu, enter their name and code, and join.
3. Press Start. Students' local game pauses and they see your FX Crossroads screen, including the Studio and its menus. The teacher occupies a separate chair, leaving all 31 student seats available.
4. Students can Leave at any time. Ending the broadcast or losing the teacher connection restores their own game controls.

This is a compressed, view-only broadcast at **up to 2 frames per second**, reduced on a slow host. It shares only the game canvas, without sound, desktop, webcam or microphone. Browser-native upload/download dialogs are not part of the shared image. Use it for explaining code and designs; fast motion is intentionally limited. Check it on your school network before a full-class lesson.


## Field Research and daily demonstrations (v131)

Type `playtest` to Elder Ram to start student observation mode; F8 opens checkpoints, FPS information and the playtest notebook. No mastery or player progress is saved during the session. Exit Research restores the saved profile; notebook reports remain separate. Daily challenge buttons now launch the relevant activity, and the west-side Studio has a separate connected street. See UPDATE_V131.md for details.


## Partner Up (v132)

Studio's Partner up button creates an invite-only two-person session. Share its SP code. One student holds the pencil; the other sees the same draft and requests control. Pass pencil commits the current valid draft before handing over. Both students can Download shared; exported hero, ability, enemy and behaviour files use their existing portable formats. Save important drafts before joining. Saved libraries are preserved. The updated Render service is required. See UPDATE_V132.md.

Field Research is now **Playtest Mode**, with a blue border. Type `playtest` to Elder Ram; normal combat and protected profiles remain the same.


## Sound and media evidence
Ability Lab’s Sound tab accepts short original WAV/MP3 effects and eight examples, with level/pitch controls. Save the ability/hero to carry audio in your exports. See MEDIA_AUDIO_TEACHING_GUIDE.md. Media mode (say media to Elder Ram) offers optional framing guides, clean photos and a captioned portfolio. Use OBS for video and FL Studio for scoring.
