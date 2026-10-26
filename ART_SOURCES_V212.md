# V212 modest hero polish

Art generated with the built-in image-generation tool using existing hero images and the supplied V211 gameplay-scale board as style references. The original sheets are retained in assets/hero212/<hero>_source.png; extracted80×80runtime frames and crop/scale metadata are in the same folder. tools/prepare_hero212_art.py reproduces the extraction with Pillow and NumPy.

This batch includes the15heroes from the supplied roster images, plus the requested Lyra and Diamond Scout corrections. It retains species, lore, palette and equipment. Lyra has an explicit outfit/personality revision: navy cropped top, modest midriff, existing skirt/boots, more assured expression. Diamond Scout keeps his dark olive-tan complexion and baseball uniform with a smaller head relative to his torso.

No purchased assets were introduced. Runtime uses cached small PNG frames; the full-resolution source sheets are not included in the web pack or server runtime assets. Existing movement, damage, cooldowns, account/save/database logic and network protocol remain unchanged.

## Batch identities and abilities

### Sunpetal

A sunlit garden guardian who followed a lost dawn to the Crossroads.

Primary: Bullet Seed. Secondary: Kindle Bloom. Special: Solarbeam.

### Snowdrift

An abandoned snow sculpture determined to see every season. Moves with a gentle icy glide: acceleration, gradual turns and a short coast when released.

Primary: Snowball. Secondary: Ice Chill. Special: Rolling Snowball.

### Veyra Spellthief

An exile of Ebonwake who stole the Citadel’s forbidden ledger and learned to turn cruel magic against its masters.

Primary: Echo Brand. Secondary: Spell Snare. Special: Soul Ledger.

### Backbeat

A forgotten marching drum with a heartbeat loud enough to wake a realm.

Primary: Sound Wave. Secondary: Triple Tempo. Special: Big Bang.

### Harbor Bell

A penguin harbour guide who turns dangerous ground into safe crossings. Modest damage is balanced by carefully placed rescue buoys and moving projectile cover.

Primary: Harbor Note. Secondary: Rescue Buoy. Special: Safe Passage.

### Polarity

A living horseshoe magnet drawn to the strange forces between realms.

Primary: Anchor Pin. Secondary: Attraction. Special: Live Wire.

### Pippa Fernwhisker

A red panda ribbon-weaver from Petalbrook Canopy. Pippa leaves warm tea for lost travelers and weaves living fern ribbons to protect her woodland home.

Primary: Ribbon Stitch. Secondary: Fern Double. Special: Maypole Waltz.

### Spindle

A carved spinning top whose restless dance keeps forgotten winds alive.

Primary: Spiral Dart. Secondary: Orbit Dance. Special: Heart of the Whirl.

### Patch

A forgotten arcade controller awakened by Crossroads magic. Never travels without a player two.

Primary: D-Pad Volley. Secondary: Reset Pulse. Special: Player Two.

### Bracken of Moonburrow

A fox sapper from Moonburrow Hollow, guarding the moonstone warrens from unstable mines and the restless Warren King.

Primary: Moonstone Mines. Secondary: Burrow Bloom. Special: Foxfire Escape.

### Prism Mage

A human prism mage who guards Moonveil’s mirrors from the jealous Marquis.

Primary: Prism Lance. Secondary: Prism Unfurl. Special: Moonlit Procession.

### Aurel

A copper-scaled star dragon, small enough to fit through a town gate and old enough to remember when the sky was closer.

Primary: Starfire Breath. Secondary: Wingbeat. Special: Skyfall Constellation.

### Rune Duelist

A human swordsman who stitches glowing runes into every step of a duel.

Primary: Inscribed Cut. Secondary: Runestep. Special: Sigil Court.

### Garrick Runebearer

A wandering male rune smith with a weathered beard and a hammer inscribed with three old promises: courage, swiftness and shelter.

Primary: Rune Hammer. Secondary: Threefold Oath. Special: Triune Verdict.

### Nera Lockstep

A lantern courier from Brasslock Borough who unlocks impossible routes with enchanted keys and a ghostly last tram.

Primary: Corkscrew Key. Secondary: Latchline. Special: Midnight Express.

### Lyra Galeweaver

A bright-eyed weather mage who bottles river mist and wears a storm in her hat. Lyra keeps the Mistglass Spire breezy, insists every forecast needs a little charm, and has never admitted that her best spell began as a sneeze.

Primary: Pocket Twister. Secondary: Whirlaway. Special: Galeforce.

### Diamond Scout

Preserve the established baseball player design.

Primary: Pitch. Secondary: Bat Sweep. Special: Triple Play.
