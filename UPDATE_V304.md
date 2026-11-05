# Crossroads V304 Performance

This release targets multiplayer Cave Descent, arena floor rendering, and browser software graphics.

- Cave Descent indexes enemy positions once per snapshot, draws the repeating floor in one submission, and skips effect geometry beyond the visible area. Reduced effects keep wave warnings and the expanding ring while trimming decorative flecks.
- Arena floor chunks batch tiles by texture atlas and layer, including the Crossroads Coliseum path overlay.
- Auto graphics lowers internal resolution to 60% when the browser identifies a known software renderer. Full retains native resolution. Reports identify the build, renderer fallback, effects detail, pre-poll state age, and server measurement time so future reports can be compared to Render metrics.

The packed native fixture simulated three player slots for 240 steps on Cave Descent floor 59 with 23 enemies and checked snapshot serialization. A separate 48-enemy lookup benchmark took about 73% less time. Seven native OpenGL floor comparisons matched V303 pixel for pixel at 1280 × 720. Arena floor commands fell from 384 to 6 on three maps and from 403 to 9 in Crossroads Coliseum. These are controlled tests. The next validation is a three-browser school-device run with all players casting in Cave Descent, with client frame time, RTT and server simulation time captured together. Broad texture loading changes and new attack animations are outside this pass.

## Install

Use the matching V304 Server Update for Render, retaining the existing environment and database. Then upload the intact V304 Web ZIP to the itch.io HTML game page and select the browser play option. The game pack is split into small verified data files inside the ZIP. Preview a test match on the updated client and server before classroom play.

## Recover the editable source

Overlay all four V278 Editable parts, then the final V293 RecoveryDelta, then the V304 RecoveryPatch. The V304 patch includes the cumulative changes from V294 through V304. Start from a clean recovery folder. Keep the V303 packages available for rollback.
