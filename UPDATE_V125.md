# v125 — Studio animation editor stability

Fixed saving an attack animation frame after its parent window was closed. The animation window now hides during pixel editing and returns on cancel; saving is safe even if the window was removed. Includes the full v124 Studio implementation. Official heroes and attacks are unchanged.

Re-export the Web ZIP and Windows build in Godot. Upload the Web export to itch.io, not this editable source ZIP. No room service or Render changes.

Validation: five animation lifecycle checks and the complete 98-check Studio suite passed without script errors.
