# v51 — Dribble basketball gait

Includes every v50 realm overhaul, Pippa and Petalbrook.

Dribble now bounces while moving in town, solo realms and multiplayer. His sprite follows a small ballistic arc, stretches slightly while airborne and squashes on landing; a ground shadow keeps the collision position readable. Stopping finishes the current bounce and settles. Teleports, menus, death and riding the raft reset the gait. Remote players animate from their displayed movement, so stationary teammates do not bounce just because they are remote.

This is visual movement: ground coordinates, hit range, movement speed, wall collision, dodge, Triple Bounce and all attack balance stay consistent. `scripts/basketball_motion.gd` is shared by both game views. No network protocol or Render update is needed.

Export a fresh Web build and replace the itch.io upload. This ZIP is the editable Godot project.
