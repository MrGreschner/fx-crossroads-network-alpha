# Add a student-made playable book

This project includes a **working example** at `examples/book_student_submission.zip`. Try it on a copy of the game first. Installing content changes the files in that game folder; an exported game or a previously shared ZIP does not change automatically.

## Ask the student for these three files

1. `content/characters/book.json` — name, unique `id` (`book`), `sprite` prefix (`book`), `run_cost` (0–100), health, speed, ability stats, and a supported passive. The example uses melee Paper Cut, area spin Flying Pages, beam Spellbeam, and the quick-primary passive. Students can start from the example JSON or copy `content/characters/cat.json` and change the fields.
2. `assets/book_0.png` — the first animation frame, transparent PNG.
3. `assets/book_1.png` — the second animation frame, transparent PNG.

Piskel or Aseprite works for drawing the two frames. Aim for about 28×32 pixels per frame; the content checker accepts 8–128 pixels on each side. The two files should depict the same character in slightly different walking poses, with a transparent background and a readable silhouette. Students can submit the three files inside one ZIP, with **exactly those internal paths** and no enclosing project folder. `examples/book_student_submission.zip` shows the layout.

## Install and test

1. Make a copy of the `growing_world` project folder for testing. The supplied example installs a character named `book`, so do not install it twice in the same copy.
2. In a terminal opened **inside that copied project folder**, run `python tools/content_manager.py --install examples/book_student_submission.zip`. On Windows, `py -3` can replace `python`. The checker requires Pillow: if it says Pillow is missing, run `python -m pip install Pillow` (or `py -3 -m pip install Pillow`). No Python installation is required to play the game.
3. Look for `Installed 3 files; registry updated.` The installer copies the JSON and PNGs into the right folders and adds `book` to `content/manifest.json`. If it reports an existing file, ask for a new unique ID and sprite prefix rather than overwriting another student's work.
4. Open `project.godot` in Godot 4, press F5, walk to the Character Hall, and press E. The new book appears in the numbered menu. Select it: the town avatar becomes the book. Enter a realm and test both attack buttons, the level-5 passive, the level-6 special, health, and balance. Check both frames while moving.
5. Copy the tested project back to your master version and export/share an updated build. Students playing an older build will not see the new character. The local save stores records and runs; it does not install content.

No change to `scripts/game.gd` is needed for these supported styles: `melee`, `projectile`, `charge`, `spin` for primary or secondary; `stomp`, `beam`, `stealth` for special; and `heal_on_kill` or `quick_primary` for passive. If the student wants a new effect such as summoning minions or reflecting projectiles, that ability needs a code addition and teacher review before the JSON alone can use it.
