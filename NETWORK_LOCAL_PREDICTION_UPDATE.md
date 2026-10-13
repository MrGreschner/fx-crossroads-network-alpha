# Local response update

Ram identity strikes are previewed immediately, with server-confirmed duplicates suppressed by action identity. Standard straight primary/secondary projectiles and supported charged projectile releases get local cosmetic previews; seed bursts schedule individual previews at their original intervals. Server-owned seed projectiles now carry stable IDs and action/burst indices. Preview-to-authority handoff preserves the current displayed point and blends small corrections; own shots account for bounded half-RTT latency. Rejected requests cancel their previews. Cosmetics never deal damage.

The authority sends player positions at 0.001-pixel precision rather than rounding to whole pixels. Tiny correction noise is ignored. Cosmetic motion sampling uses the rendered remote position.

Validation: combat/protocol, actual Godot client, delayed/jittered client, gateway, reconnect and 2/4/8-player suite passed. New local_prediction.gd verifies immediate Ram and seed previews, no preview damage, rejection cleanup, no duplicate horn flash, continuous projectile handoff and matching individual seeds. Latency-test movement error was below 0.001 pixels in this local run. This is not an exported school-browser performance guarantee. Unusual hero abilities still need individual prediction/parity testing.

Install: replace alpha source in GitHub Desktop and push; wait for Render redeployment. Open the same updated project in Godot and export a new Web ZIP for the FX Connections Lab itch.io page. Refresh all browser clients after upload. Main v166 is unchanged.
