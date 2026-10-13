# FX Crossroads v97

## Menus

- Profile / Mastery / Town uses the same skin and top alignment as Adventures. It glows only while a hero has usable, unspent mastery points; the Mastery tab highlights that opportunity. Fully allocated points clear the highlight.
- Gather Your Party has a centred Menu button, centred room-code/name input and toggle labels, and inset text in match selectors.
- Choose Realm shows ordinary/summoned enemies first, then a separate gold-bordered Bosses section. Discovered portraits retain names; unknown enemies remain hidden. Difficulty uses green for easy, yellow for medium, orange for challenging/hard, and pink for expert/extreme.

## Arena, journey and town

- Arena start/event notices use a compact panel, fade after five seconds, and no longer leave a permanent black rectangle. Repeated identical network status does not reset the timer.
- A bottom-left Leaderboard button opens/closes current damage, kills, hero KOs and deaths during Arena play, including spectator viewing. The automatic respawn board remains.
- Your Journey Cosmetics has direct Equip title / Equip ribbon buttons, clear locked states, unlock tooltips and a welcome-checklist toggle.
- Elder Ram covers all current modes, public rooms, spectators, AI practice, mastery, food, gardening, profiles, cosmetics and stability options. Teacher access remains available.
- Young Ram and Elder Ram retain their familiar silhouettes with clearer horns, wool, faces and clothing. Young Ram's four poses share the same level of detail.
- The enlarged pond has an irregular shore, swimming fish, lilies and ripples. Its separate walking path and bench clear trees, the north fence and the lowered nearest mountain peak.

## Combat clarity and balance

- Vesper's Starlit Veil lasts four seconds; the alternate Dusk Roost mastery remains separate.
- Crumb Cook's spatula stays within its hit reach; the sector marks the actual close hit area.
- Glimmer Mantis's primary sector and sweeping crescent share the same boundary. Glass Verdict also shows the full width/end caps of its advancing hits.
- Tova's tongue and round tip damage the visible narrow path, including the tip. Waylight Lifeblood replaces the old protection passive: allied heroes within 160 reach heal 2 HP on a successful attack hit, once per 0.75s per hero. Does not trigger from damage-over-time or stack across several Tovas.
- Dust Marshal's Hogtie deals 18 damage after a 0.3s throw, pulls smoothly toward a point 48 away from the Marshal over 0.4s, and stuns for 2 seconds. Walls stop the pull; finishing does not reposition the target again.
- Phoenix Ring leaves a stationary smoke field for 5.5 seconds. Allied heroes inside can dodge 12% of incoming direct hits. Damage-over-time remains effective. The three offensive sweeps keep their existing damage; Ash Nest mastery remains a different special.

## Movement art

Cindervane has wing-up/wing-down walking poses and rising flame wisps. Polarity gains faint moving magnetic arcs. Snowdrift leaves fading meltwater. Stormscribe leaves faint lightning traces. Aurel's existing footprints remain.

All trail styles share a 96-trace cap, expire after 1.6 seconds, skip off-screen drawing, and use no particle nodes or added network packets. Smoke/pull use the existing authoritative combat snapshot.

See RELEASE_CHECKS_V97.md for verification and DEPLOY_V97.md for exporting. This is editable source, not a pre-exported playable Web build.
