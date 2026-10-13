# FX Crossroads v87 — A complete session flow

Full editable project, including all earlier v86 content. All 60 heroes remain unlocked. No deployment has been performed.

## Hero hall and artwork

- Original roster numbers appear beside heroes and in the selected portrait heading. Filtering and favourites do not renumber heroes. Searching an exact number finds that hero.
- Recess Warden is now an owl, with four matching poses. Its first technique is **Owl Eyes**, replacing Snack Break: two opposite 270-range energy beams for 2 seconds. Aim rotates both beams. Each foe takes at most 5 damage every 0.25 seconds, for 40 total per cast; walls stop the beams. Cooldown 11 seconds. The trade-off is losing the healing/cleansing mat. The normal kit and final technique remain.
- Crossroads Teacher's glasses have been removed from every pose.
- **Tide Keeper** and **Spark Keeper** replace the Foundry pair's display names. Both are otters wearing matching copper-trimmed engineer uniforms, with water/electric accents. Their linked abilities, co-op unlock condition and internal IDs remain unchanged, so mastery carries over.
- Defeat results say **Adventure over — you were defeated**. Victory still says Victory.

## Level-up flow

Large clickable cards replace the paragraph-based solo selection. Keyboard numbers still work. Green means health or passive, red means damage, blue means movement or secondary cooldown, purple means special cooldown. Stat cards show +25 HP, +4 damage and +20 speed. Unlock levels have a clear Continue button; level 8 and 10 choices show their actual upgrade values.

Multiplayer has large clickable level 8/10 choices using the existing authoritative J/K selection path. Other level gains use a short notification rather than pausing a live match. Multiplayer's existing automatic level rewards have not been converted into new stat choices.

## Main and pause menus

After the two-second intro: **Resume, Upload profile, Download profile, New player, Clear profile from this device**.

- Resume returns to the current session; new players then receive the existing introduction.
- Upload/download use the existing portable profile format and are restricted to town at both menu and save-system entry points. Profiles store progression, not unfinished battles.
- New player and Clear share an explicit confirmation describing what will be removed and recommending a download first. They erase local progress and its backup/temporary copies, reset the selected hero, and return to a fresh main menu. Downloaded files remain available to restore later.
- Double-tap Escape within 450 milliseconds to open pause/navigation. A visible Menu button provides the same access on touch devices. A single Escape retains existing close/back actions and never quits the application.
- Pause offers Resume, Exit to town and Main menu. Solo gameplay pauses behind it; live multiplayer continues. Leaving a hosted match disconnects the party, as explained in the menu. Opening Main menu during a run does not allow profile transfer until returning to town.

## Publication

Deploy the included **room_service 21** code to Render; existing URL, environment values and start command remain unchanged. Export fresh Web and Windows builds from this source, then upload those exported builds to itch.io. Do not upload this editable-source ZIP as the browser build. Existing profiles are compatible.

See RELEASE_CHECKS_V87.md for validation. Physical mobile/browser-hosted behaviour needs a final short check on your devices; local native renders and automated gameplay tests do not replace that check.
