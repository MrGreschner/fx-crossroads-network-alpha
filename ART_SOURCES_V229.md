# V229 — alignment correction to existing creature artwork

No new character designs or painted pixels. Uses the selected ImageGen artwork credited in ART_SOURCES_V220.md, ART_SOURCES_V227.md and ART_SOURCES_V228.md.

63 creatures / 252 idle, movement A, movement B and attack poses audited. Original 64px normalized originals stay in assets/enemy220, enemy227 and enemy228. assets/enemy229 holds technically registered 80px canvases. Padding and integer translation preserve every existing opaque pixel, without filtering, repainting or cropping. Renderer compensation cancels padding exactly. Only Hollow Warlock receives an intentional 20% enlargement.

The anatomical registration and per-creature translations are documented in assets/enemy229/manifest229.json and tools/enemy_walk_registration229.json. The transform can be reproduced with tools/align_enemy_frames229.py. Native imported PNG aliases and their generated Godot textures are included for solo, co-op and legacy loading paths.
