# V242 validation

| Check | Result |
|---|---|
| Source runtime | 233 focused checks, zero failures |
| Patched Web PCK runtime | Same 233 checks, zero failures |
| V241/V242 world contract | All 4,752 sampled collision/approach results identical, with earned projects both absent and built |
| Entrance access | All 24 recorded entrance/interaction anchors remain walkable |
| Source preservation | 7,217 existing functions and 1,301 constants unchanged; edited functions limited to drawing, light placement and facade texture setup |
| Protected resources | All 477 checked content, scene, V240/V241 artwork and route resources byte-identical |
| Server | Fresh Godot import and dedicated-server script compilation passed |
| Actual render paths | Shared sprite interception, new market/post/marina-fittings caches, conditional projects and fitted glass all exercised |
| Visual review | All 24 facades in day and night, plus unbuilt projects, in native Godot 4.5.1 compatibility rendering; repeated against packaged Web resources |
| Runtime resource budget | 8 MiB facade atlas + 2 MiB compact glass atlas + 3.61 MiB replacement architecture caches; no original large source images loaded |
| Package resources | Every edited production resource matches Editable, Server Update and patched Web PCK; original untouched PCK resources retained |
| Deployment | None performed; no database migration or reset |

The tests ran with isolated local fixtures. Both original and new contracts use identical anchors, sprite envelopes, service points, roads and collision probes. Nonvisual collision, economy, progression, curriculum, NPC identity/schedule and route functions were not edited.

Glass emission is restricted to annotated glass-coloured pixels; opaque masonry, frames and mullions are excluded. Every new local window/lantern light is anchored to an actual emissive pixel. Atlas geometry, mask containment and repeated GPU texture reuse are checked. Earned buildings and their lights remain hidden before construction.

Visual previews use the actual game renderer with software OpenGL, not mockups. Earned buildings are enabled only in the preview fixture so every completed facade can be inspected. The separate unbuilt view confirms construction-site behavior. Both native source and packaged-resource runs finish with the pre-existing ObjectDB/three-resource fixture teardown notices; no in-session script errors occurred.

Browser-runtime installation failed in this environment, so no browser or school-computer performance claim is made. Real school-device/browser playtesting remains outstanding. The Web PCK itself was parsed, rebuilt, round-trip verified and tested using the native compatibility renderer.

ZIP CRC, duplicate-path, version, browser fileSizes and archive resource parity checks are recorded in RELEASE_INTEGRITY_V242.json. Install Server Update first, then Web.
