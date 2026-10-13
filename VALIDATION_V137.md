# v137 validation

Completed in Godot 4.5.1:

- 35 focused checks: BandLab-style 44.1 kHz stereo WAV preparation, effect size/duration, music validation, corrupt/long audio rejection, startup SVGs, Music Studio UI, realm audition, bounded library, player ZIP roundtrip and temporary Game Dev storage.
- 11 music transport checks: host metadata, audio outside snapshots, paced reconstruction, host-only authority, ordering/size rejection, channel buffering and cleanup.
- Regression checks: v136 Media/audio 38, v124 profile ZIP 12, v135 timed Media/commerce 29, v131 Studio polish 96. All passed without script errors.
- Native rendered views inspected: Media shortcut guide, Studio hub, Music Studio upload/editor and scrolled action controls.
- Entire source ZIP extracted into a new project with no .godot cache. Fresh editor import and focused tests passed with no missing art or script errors.
- Source archive CRC and full extraction passed; all previous v136 payload paths and all 80 official hero definitions retained.

Transport tests use a deterministic peer-channel harness. Actual school-browser file pickers, real two-device WebRTC transfer, Windows export and itch.io Web export require on-device deployment checks. Matching export templates are not installed in this workspace; no compiled export is included.
