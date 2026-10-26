# Crossroads: Realms Beyond — V221

The intro cast now stands farther up the woodland path. Elder Ram, Young Ram, Bramble and the portal move upward by 60 scene pixels; the cat moves from the creek to the path edge. The portal's energy mask moves with the arch.

Bramble's retreat now ends at the doorway centre, never beyond it. The foreground stone frame occludes the approaching character and Bramble fades as he enters. Young Ram's later entrance remains.

A clearly visible river fish jumps twice during the scene, using a larger, tightly cropped fish sprite, a higher curved leap, a natural tilt, and take-off/landing splashes. The fish disappears beneath the water between leaps. Day/night fish selection remains. Native and web scene timing/layout are updated together; reduced motion avoids the fish rotation and high leap in the web version.

No gameplay, hero/enemy statistics, realm layouts, accounts, saves, keys, records, database or schema changes. All prior V220 enemy artwork and V219 mouse-size changes remain. Data/backend files are byte-compared against V220 except release metadata.

Validation: native scene frames and a fixed-step 7.2-second video reviewed; 180 art/intro checks, 39 simulated DOM/timing checks and five focused fish/path/portal-exit checks pass. Browser timing checks simulate the DOM; actual browser/mobile playback still requires real-device testing. Existing fixtures emit teardown resource warnings.

Deploy Crossroads_v221_Server_Update.zip first, then Crossroads_v221_Web.zip to itch.io. Editable source: Crossroads_v221_Editable.zip. V221_Intro_Preview.mp4 shows the revised scene. No live deployment or database reset performed.
