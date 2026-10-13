"""Validate registered quest campaign references before opening Godot."""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT / 'content/manifest.json').read_text())
errors = []
for region_id in manifest.get('quest_regions', []):
    region = json.loads((ROOT / f'content/regions/{region_id}.json').read_text())
    campaign = json.loads((ROOT / region['quest_campaign'].removeprefix('res://')).read_text())
    quests = campaign['quests']
    ids = [q['id'] for q in quests]
    npcs = [npc['id'] for npc in campaign['npcs']]
    if len(set(ids)) != len(ids) or len(set(npcs)) != len(npcs):
        errors.append(f'{region_id}: duplicate quest or NPC ID')
    def point_ok(value):
        return isinstance(value, list) and len(value) == 2 and all(isinstance(v, (int, float)) for v in value) and all(0 <= v < region['size'][n] for n, v in enumerate(value))
    for q in quests:
        if q['npc'] not in npcs: errors.append(f'{q["id"]}: unknown NPC')
        if not q.get('stages') or q['stages'][-1]['type'] != 'report': errors.append(f'{q["id"]}: needs final report stage')
        for dep in q.get('requires', []):
            if dep not in ids: errors.append(f'{q["id"]}: unknown prerequisite {dep}')
        for stage in q.get('stages', []):
            if stage['type'] not in {'collect','switches','visit','clear','report'}: errors.append(f'{q["id"]}: unsupported stage type')
            if stage['type'] in {'collect','switches','visit'} and not stage.get('targets'): errors.append(f'{q["id"]}: missing targets')
            if stage['type'] == 'clear' and not stage.get('encounters'): errors.append(f'{q["id"]}: empty clear encounter')
            target_ids = [t['id'] for t in stage.get('targets', [])]
            if len(set(target_ids)) != len(target_ids): errors.append(f'{q["id"]}: duplicate target ID')
            for obj in stage.get('targets', []) + stage.get('encounters', []):
                if not point_ok(obj.get('pos')): errors.append(f'{q["id"]}: invalid position')
            for foe in stage.get('encounters', []):
                if foe['type'] not in manifest['enemies']: errors.append(f'{q["id"]}: unknown enemy')
    by_id = {q['id']: q for q in quests}
    def visit(key, trail):
        if key in trail:
            errors.append(f'{region_id}: prerequisite cycle {trail + [key]}'); return
        for dep in by_id.get(key, {}).get('requires', []): visit(dep, trail + [key])
    for key in ids: visit(key, [])
print('\n'.join(errors) if errors else 'Quest campaigns valid')
raise SystemExit(bool(errors))
