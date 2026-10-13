# Encounter journal authoring

The native realm menu reads content/encounter_rosters.json, then adds encounters recorded in the current profile. Unknown entries stay question marks. Enemy definitions supply names and sprite prefixes; bespoke boss sprites use a boss: prefix key when no enemy definition exists.

Run python3 tools/build_encounter_rosters.py after editing region/campaign/school/quest content. The generator scans registered enemy ids in referenced JSON, scene metadata and explicitly mapped script-driven worlds. For a new script-driven realm, add its source to the mapping or author its roster directly. Do not list enemies that cannot occur in that realm.

Solo and co-op discovery require a living enemy within 600 world units and a clear path. Co-op checks happen on each player's client; damage remains host-authoritative. Every 0.4 seconds is sufficient for discovery, avoiding a per-frame scan. Unknown enemy portraits are not an alternative to readable combat warnings.

The encounters dictionary is included in portable profiles. Test a new profile, reveal one enemy, export/import, then confirm its portrait remains revealed only for that realm. Keep new records bounded and keep enemy ids stable.
