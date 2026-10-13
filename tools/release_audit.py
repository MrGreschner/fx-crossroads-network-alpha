"""Check the expanded roster without the legacy installer's attack whitelist."""
from pathlib import Path
import json
import struct
import sys
root = Path(__file__).resolve().parents[1]
errors = []
def check(ok, message):
    if not ok:
        errors.append(message)
manifest = json.loads((root / 'content/manifest.json').read_text())
ids = manifest['characters']
check(len(ids) == len(set(ids)), 'Duplicate hero IDs in manifest')
metadata = json.loads((root / 'content/hero_library.json').read_text())
for hero_id in ids:
    hero = json.loads((root / f'content/characters/{hero_id}.json').read_text())
    check(hero.get('id') == hero_id, f'{hero_id}: filename/ID mismatch')
    check(hero.get('run_cost', 0) == 0, f'{hero_id}: hero access must remain free')
    mastery = hero.get('mastery', {})
    techniques = [mastery.get('technique', {}), mastery.get('final_technique', {})]
    slots = [t.get('ability') for t in techniques]
    check(all(s in ['primary', 'secondary', 'special'] for s in slots) and slots[0] != slots[1], f'{hero_id}: mastery choices must change different slots')
    for slot in ['primary', 'secondary', 'special']:
        ability = hero.get(slot, {})
        check(bool(ability.get('name')) and bool(ability.get('style')), f'{hero_id}: incomplete {slot}')
        check(float(ability.get('cooldown', 0)) > 0, f'{hero_id}: invalid {slot} cooldown')
    sprite = hero.get('sprite', hero_id)
    for pose in ['idle', 'walk1', 'walk2', 'attack']:
        path = root / f'assets/{sprite}_{pose}.png'
        check(path.is_file(), f'{hero_id}: missing {pose} art')
        if path.is_file():
            data = path.read_bytes()
            check(data[:8] == b'\x89PNG\r\n\x1a\n', f'{path.name}: invalid PNG')
            if len(data) >= 24:
                width, height = struct.unpack('>II', data[16:24])
                check(8 <= width <= 128 and 8 <= height <= 128, f'{path.name}: unexpected sprite size')
# Missing metadata has a runtime fallback; report it without blocking future additions.
entries = metadata.get('heroes', metadata)
if isinstance(entries, list):
    covered = {entry.get('id') for entry in entries}
else:
    covered = set(entries)
missing = set(ids) - covered
if missing:
    print('Metadata fallback used for:', ', '.join(sorted(missing)))
for error in errors:
    print('ERROR:', error)
print(f'Roster audit: {len(ids)} heroes, {len(errors)} errors')
sys.exit(bool(errors))
