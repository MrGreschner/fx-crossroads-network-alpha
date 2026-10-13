import json,re
from pathlib import Path
p=Path(__file__).resolve().parents[1];c=p/'content';enemies=set(json.loads((c/'manifest.json').read_text())['enemies']);out={}
def collect(value,result):
 if isinstance(value,dict):
  for v in value.values():collect(v,result)
 elif isinstance(value,list):
  for v in value:collect(v,result)
 elif isinstance(value,str) and value in enemies and value not in result:result.append(value)
for f in (c/'regions').glob('*.json'):
 region=json.loads(f.read_text());rid=region['id'];result=[];collect(region,result)
 for directory in ['campaigns','schools','quests','worlds']:
  for jf in (c/directory).glob('*.json'):
   if jf.stem==rid or jf.stem.startswith(rid+'_'):collect(json.loads(jf.read_text()),result)
 for v in region.values():
  if isinstance(v,str) and v.startswith('res://') and v.endswith('.json'):
   jf=p/v[6:]
   if jf.exists():collect(json.loads(jf.read_text()),result)
 sf=p/region.get('scene','')[6:]
 if sf.is_file():
  for kind in re.findall(r'metadata/(?:type|enemy_type|enemy_id|kind) = "([^"]+)"',sf.read_text()):
   if kind in enemies and kind not in result:result.append(kind)
 boss=region.get('boss_sprite','bramble_boss') if rid not in ['town','practice','first_steps'] else ''
 if boss and boss not in result:result.append(boss if boss in enemies else 'boss:'+boss)
 mapping={'confluence':'confluence_world.gd','shattered_oath':'realm_trials.gd','moonburrow':'hollow_world.gd','chimevault':'chimevault.gd','moonveil':'moonveil_world.gd','clockwork_orchard':'clockwork_world.gd','astral_rift':'astral_world.gd'}
 if rid in mapping:
  source=p/'scripts'/mapping[rid]
  if source.exists():
   for kind in re.findall(r'"([a-z_]+)"',source.read_text()):
    if kind in enemies and kind not in result:result.append(kind)
 out[rid]=result
(c/'encounter_rosters.json').write_text(json.dumps(out,indent=2)+'\n')
print('Realm encounter rosters',len(out), 'Honeyglass',out.get('honeyglass'))

# Separate discovered bosses from ordinary and summoned enemies in the catalogue.
bosses={}
def boss_names(value,result):
 if isinstance(value,dict):
  for key,v in value.items():
   if key in ['boss','boss_type','boss_sprite'] and isinstance(v,str):
    kind=v if v in enemies else 'boss:'+v
    if kind not in result:result.append(kind)
   else:boss_names(v,result)
 elif isinstance(value,list):
  for v in value:boss_names(v,result)
for f in (c/'regions').glob('*.json'):
 region=json.loads(f.read_text());rid=region['id'];result=[];boss_names(region,result)
 for directory in ['campaigns','schools','quests']:
  for jf in (c/directory).glob('*.json'):
   if jf.stem==rid or jf.stem.startswith(rid+'_'):boss_names(json.loads(jf.read_text()),result)
 for key in region.values():
  if isinstance(key,str) and key.startswith('res://') and key.endswith('.json'):
   jf=p/key[6:]
   if jf.exists():boss_names(json.loads(jf.read_text()),result)
 for extra in {'shattered_oath':['gilded_usurper'],'chimevault':['gongbreaker','silence_regent'],'high_school':['exam_math','exam_english','exam_history','exam_science']}.get(rid,[]):
  if extra not in result:result.append(extra)
 bosses[rid]=result
(c/'encounter_bosses.json').write_text(json.dumps(bosses,indent=2)+'\n')
