"""Reapply version 23 character data after running older art/content generators."""
from pathlib import Path
import json
r=Path(__file__).resolve().parents[1]
def update(key,fn):
 p=r/f'content/characters/{key}.json';v=json.loads(p.read_text());fn(v);p.write_text(json.dumps(v,indent=2)+'\n')
update('ferryman',lambda v:v.update(special=dict(name='Silverfall Surge',style='waterfall_wave',damage=48,cooldown=13,radius=230,wave_speed=390,slow_duration=3,slow=.55,knockback=90,color='#91e5ed',description='A rushing waterfall expands around Reed, dealing 48 damage, pushing enemies away and slowing them for 3 seconds.'),passive='River Skipper: each Skipping Stone can bounce once to another nearby enemy.',passive_effect='stone_bounce',secondary={**v['secondary'],'style':'ricochet_projectile','bounce_range':180,'bounce_scale':.65}))
update('dawnblade',lambda v:v.update(passive='Open Wound: Sword Cut causes bleeding for 2 damage per second for 4 seconds. Repeated hits refresh it.',passive_effect='primary_bleed'))
update('stormscribe',lambda v:v['special'].update(travel_speed=420,cast_visual='storm',description='Launch a crackling storm orb at your aim. On landing, lightning bursts across a 155-radius area for 55 damage.'))
update('magnet',lambda v:v.update(passive='Threefold Polarity: keep three magnetic anchors; Live Wire connects all three.',passive_effect='third_anchor',primary={**v['primary'],'description':'Fire a magnetic pin for 18 damage. Anchors last 8 seconds; keep two, or three with your level-five passive.'},special={**v['special'],'description':'Link every owned anchor for 3 seconds. The network deals 9 damage every half-second; crossing wires do not multiply damage. Missing anchors are placed ahead.'}))
update('navigator',lambda v:v.update(passive='Twin Stars: Seeking Orb launches two tracking projectiles.',passive_effect='twin_orbs',secondary={**v['secondary'],'splash_radius':75,'splash_damage':8,'spread':.16}))
update('sunflower',lambda v:v['primary'].update(style='burst_projectile',spread=0,burst_interval=.1,description='Fire four seeds consecutively along your aim in a short burst. Each deals 5 damage; equipment bonuses are divided across the burst.'))
update('goalie',lambda v:v.update(passive='Cold Reprisal: enemies that strike you in melee are slowed for 3 seconds.',passive_effect='slow_thorns',secondary={**v['secondary'],'cooldown':2.2,'reduction':.5}))
v=dict(id='spindle',sprite='spindle',name='Spindle',max_health=105,speed=235,run_cost=0,lore='A carved spinning top whose restless dance keeps forgotten winds alive.',primary=dict(name='Spiral Dart',style='spiral_shot',damage=20,cooldown=.8,range=360,speed=390,curve=1.1,color='#b0e9df',description='Fire a curving spiral dart for 20 damage. Alternate its curve with each shot.'),secondary=dict(name='Orbit Dance',style='orbit_shards',damage=10,cooldown=6,duration=2.4,radius=95,count=3,description='Three shards circle you for 2.4 seconds. Each shard can hit each enemy once for 10 damage.'),special=dict(name='Heart of the Whirl',style='vortex_field',damage=8,cooldown=16,duration=3,radius=200,description='Create a vortex ahead of you for 3 seconds. It pulls and slows enemies, dealing 8 damage every half-second.'),passive='Balanced Spin: Orbit Dance lasts one extra second.',passive_effect='long_orbit')
(r/'content/characters/spindle.json').write_text(json.dumps(v,indent=2)+'\n')
p=r/'content/manifest.json';m=json.loads(p.read_text());
if 'spindle' not in m['characters']:m['characters'].append('spindle')
p.write_text(json.dumps(m,indent=2)+'\n')
