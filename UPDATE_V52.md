# v52 — Frostguard skating movement
Frostguard moves in a repeating 0.36-second fast skating slide followed by a 0.24-second stop. The slide travels at 1⅔ of his normal speed, preserving his existing average speed over each cycle. Integration across frame boundaries keeps travel consistent at different frame rates. The cadence continues while input is released, preventing repeated taps from resetting the fast phase.

Town, solo and multiplayer use the same movement. Mobile sticks work too. Existing collision, terrain, status and equipment modifiers remain applied; dodges and forced ability movement keep their own motion. Short ice streaks mark skating and fade during braking. All v51 additions remain included.

Export a fresh Web build for itch.io. No Render service changes are needed.
