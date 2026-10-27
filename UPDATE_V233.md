# Crossroads V233 — Studio tools and Market art refresh

- New pixel drawings default to 80 × 80, matching the refreshed hero frames. Existing drawings keep their dimensions. “Fit to 80 × 80” preserves proportions with nearest-pixel scaling and padding; Undo restores the original size. Terrain tiles retain their 32px default. Object Raster Studio also offers 80px documents.
- Added visible “Copy current picture” / “Paste picture” controls across shared pixel editors, plus Hero Workshop “Copy pose” / “Paste / edit” buttons. The clipboard includes unsaved pixels, survives closing an editor, and creates an independent image. Paste and resizing are undoable. Existing-pose copying is now undoable too. Live collaboration still receives image changes through the existing synchronization path.
- Added “Graphic style explanation” to the Studio hub, hero artwork page, Pixel Studio and Raster Studio. Includes real hero examples, canvas/body sizing, neutral poses, matte shading, coloured contours, palette examples, a copy-to-special-frame walkthrough and a finishing checklist. Available to public creators; no module enrollment required. Existing four hero-body slots and separate Ability Lab effect/charge frames remain compatible.
- Updated Market civilian staff, customers, proprietor and daycare dogs: 13 designs/52 poses, preserving species and identity. Hire-profile coat variations are cached. Portrait sizes adjusted for the new square canvases. Working goods remain separate from people.
- Updated 16 key equipment graphics and added restrained matte shading/coarse raster polish to the existing catalogue icon geometry. Static roof/timber details refreshed while preserving the cutaway shops, product locations and day/night lighting.

## Validation

1,422 focused checks passed, including clipboard persistence, independent paste, Undo,80px conversion and restoration, all 13 animated designs, hire-colour caching, equipment mapping and all 1,195 catalogue icons . 4,258 business simulation assertions and 4,574 shared hero/stat/authority/Cave checks also passed. Native Studio, guide, hiring, Market day/night, daycare and animation previews rendered and inspected. Fixture shutdown/resource warnings remain in the native capture harness; no in-session script errors. Real-device performance and full multiplayer/collaborative playtesting remain for manual verification.

New character/equipment atlases and catalogue icons are cached. No per-frame sprite rasterization or generated-hire recolouring. Business simulation, costs, progression, project validation limits, competitive eligibility, educational access, accounts and backend services remain unchanged. Selected source sheets and prompts are in Editable; generation originals are excluded from runtime packages.

## Installation

Deploy Server Update first, retaining existing environment settings and persistent database storage. Then replace the itch.io Web build. Editable is the matching Godot project. Nothing deployed automatically.
