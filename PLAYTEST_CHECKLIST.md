# v76 release playtest

Automated checks run with Godot 4.5.1 and the local Node room service. These device checks complement them.

1. **New player:** fresh test profile → title → first nine heroes. Try movement, primary, secondary, dodge and special across three waves and the mini-boss. Escape/Skip must return to town with supplies intact. Reload must not force a repeat. Existing profiles should continue normally.
2. **Mobile:** Safari landscape and rotation, touch hero selection, scrollable Adventures/Realms/results, stick resets when closing a menu, and mute. Switch heroes in the usual hall too. Inspect both short and long hero names.
3. **Readability:** ordinary boss, Astral Rift, schools, North Gate and lobbed enemy attacks. Verify warning shapes, impact timing, visible heroes underneath effects, and distinct status markers. Healing circles use a plus.
4. **Rewards:** clear a realm near a mastery/badge/project threshold. Inspect its result card and mastery button. Replay for a personal best. Tutorial must not award clears/damage mastery. Approach residents after a genuine quest, co-op clear or gate achievement.
5. **Recovery:** two matching v76 clients, v13 room service. Interrupt a guest and then host network briefly; keep both processes open. Verify battle pause and same health/floor/match on return. Test longer than 45 seconds and explicit leave. Do not confuse recovery of a live process with restoration of a crashed host.
6. **Arena:** FFA/2v2, no-items and random-hero rules, contributions, return to party, next match, and no outcome for a disconnected match. Profiles and techniques must remain assigned to the correct hero.
7. **Performance:** play a long Defence or Descent session on a school PC; download diagnostics if freezing occurs. Confirm the mute button covers victory and Chimehouse audio. Test browser and built Windows edition if available.

Export Web into a fresh empty folder; ZIP the exported files with `index.html` at the root. Keep this editable project separate. Record mode, host/guest, party size, hero, realm, action and diagnostic report for a bug report.

## v77 parties and arenas
- Change heroes after joining a lobby; confirm both players see the new walking hero and the selected build is used at Start.
- Public browser empty state, room selection/refresh, full/private/running room exclusion.
- Every map in FFA and 2v2, Opening Act both settings, no-items and random heroes. Confirm both clients see the same hazards.
- Invite a friend into a running Defence/Descent session; approve/decline and test 30-second expiry. New arrival is Lv1; host progress is unchanged. Offline solo remains playable without invites.
- Signed mastery sliders using touch and keyboard, point refunds/budget, export/import.
- Die with several heroes and walk in all directions after healer respawn.
