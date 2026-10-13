from pathlib import Path
import json
p=Path(__file__).resolve().parents[1]
def attack(name,style,damage,cooldown,reach,description,brief):return dict(name=name,style=style,damage=damage,cooldown=cooldown,range=reach,description=description,ui_brief=brief)
h=dict(id='hearth_herald',sprite='hearth_herald',name='Hearth Herald',max_health=130,speed=220,run_cost=0,lore='An armadillo firekeeper from Ember Quarry carries the first coal of her village in a brass lantern. Her shell shelters travellers; her songs lend their weapons a little borrowed warmth.',primary=attack('Lantern Tap','hearth_tap',18,.65,95,'Sweep the brass lantern through a short forward arc for 18 melee damage. The visible golden swing marks its reach.','Melee sweep • 18 damage • 95 reach'),secondary=attack('Kindle Arms','hearth_kindle',0,12,220,'Enchant yourself and friendly heroes within 220 reach for 5 seconds: +8% attack damage. Direct hits apply burn for 2 damage per second for 3 seconds, at most once per target per second per attacker. Does not stack with another Kindle Arms.','Ally buff • +8% damage • attacks apply burn'),special=attack('Homefire Beacon','hearth_beacon',0,24,280,'Plant a hearth banner at the aimed safe spot for 6 seconds. Allies within 180 reach heal 4 HP per second. The beacon catches up to 6 hostile projectiles entering its circle; friendly shots pass through. One beacon per caster.','Placed sanctuary • healing • catches 6 enemy shots'),passive='Shared Hearth: you and friendly heroes within 170 reach gain 10% damage reduction while near the firekeeper. Multiple Shared Hearth auras do not stack; walls block the aura.',passive_effect='shared_hearth')
base=json.loads((p/'content/characters/little_menace.json').read_text())['mastery']
h['mastery']={k:v for k,v in base.items() if k.endswith('requirements') or k=='crit_milestones'}
h['mastery'].update(title='Keeper of the First Flame',technique=dict(name='Restorative Chorus',ability='secondary',description='Replace burning weapon enchantment with life-on-hit: retain +8% damage, but direct hits heal the attacker for 3 HP at most once per target per second. No added burn.',attack=attack('Restorative Chorus','hearth_march',0,12,220,'Enchant nearby allies for 5s: +8% damage and 3 HP recovered on direct hits, once per target per second. Replaces added burning damage.','Ally buff • +8% damage • life on hit')),final_technique=dict(name='Open Hearth',ability='special',description='Replace projectile catching with stronger healing: 7 HP per second for six seconds within the same banner circle. Enemy shots pass through.',attack=attack('Open Hearth','hearth_mend',0,24,280,'Place a banner for 6 seconds. Nearby allies recover 7 HP per second; it cannot catch projectiles.','Placed sanctuary • stronger healing • no shot shield')))
(p/'content/characters/hearth_herald.json').write_text(json.dumps(h,indent=2)+'\n')
f=p/'content/manifest.json';m=json.loads(f.read_text());
if h['id'] not in m['characters']:m['characters'].append(h['id'])
f.write_text(json.dumps(m,indent=2)+'\n');(p/'content/hero_numbers.json').write_text(json.dumps({id:n+1 for n,id in enumerate(m['characters'])},indent=2)+'\n')
f=p/'content/hero_library.json';lib=json.loads(f.read_text());lib[h['id']]=dict(role='Support',tags=['Support','Melee'],difficulty='Some practice',home_realm='quarry',summary='Enchant ally attacks with fire, share protective warmth and plant a healing banner.',lore=h['lore'],passive_brief='Nearby allies • 10% damage reduction • 170 reach');f.write_text(json.dumps(lib,indent=2)+'\n')
# Original code-native vector artwork. Four distinct poses, converted by Godot to runtime PNGs.
for pose in ['idle','walk1','walk2','attack']:
 step=2 if pose=='walk1' else -2 if pose=='walk2' else 0
 arm=4 if pose=='attack' else 0
 svg=f'''<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
 <g stroke="#293741" stroke-width="2" stroke-linejoin="round">
 <path d="M19 41 Q6 42 7 53 Q15 59 28 52" fill="#a87c5a"/><path d="M10 47 L17 46 M12 52 L21 49" fill="none" stroke="#ddba88"/>
 <path d="M40 25 Q58 29 54 48 L42 54 L33 38 Z" fill="#9c6c4c"/><path d="M43 29 L52 34 M42 35 L53 40 M42 42 L49 47" stroke="#d9ad76" fill="none"/>
 <path d="M23 45 L22 {58+step} L30 {58+step} L32 46 M35 45 L35 {58-step} L44 {58-step} L42 44" fill="#596779"/>
 <path d="M20 {57+step} L30 {57+step} L30 {61+step} L18 {61+step} Z M34 {57-step} L44 {57-step} L47 {61-step} L34 {61-step} Z" fill="#6d4d3c"/>
 <path d="M22 27 Q15 38 18 49 L44 49 Q48 39 41 28 Z" fill="#487977"/>
 <path d="M22 29 L31 40 L41 28 L42 37 L32 45 L22 37 Z" fill="#e0b875"/>
 <path d="M22 42 L42 42 L43 47 L21 47 Z" fill="#9c5945"/>
 <ellipse cx="32" cy="20" rx="13" ry="13" fill="#c39b76"/>
 <path d="M21 14 L21 3 Q28 3 27 14 M36 11 L38 2 Q46 2 42 17" fill="#ac805e"/>
 <path d="M21 22 Q14 27 20 31 L33 31 Q39 29 37 24" fill="#dabb94"/>
 <path d="M18 27 L23 27 L22 30 L18 30 Z" fill="#39434a" stroke="none"/>
 <path d="M29 18 L31 18 L31 22 L29 22 Z M38 18 L40 18 L40 22 L38 22 Z" fill="#293741" stroke="none"/>
 <path d="M20 15 Q29 11 43 14" stroke="#c86d4c" stroke-width="4" fill="none"/>
 <path d="M21 32 L{12-arm} 36 L{11-arm} 42 L23 39" fill="#487977"/>
 <circle cx="{12-arm}" cy="42" r="4" fill="#cba37d"/>
 <path d="M42 31 L49 38 L46 42 L39 36" fill="#487977"/><circle cx="47" cy="41" r="4" fill="#cba37d"/>
 <path d="M{8-arm} 42 Q{8-arm} 36 {16-arm} 39" stroke="#e5c185" fill="none"/>
 <path d="M{5-arm} 44 L{17-arm} 44 L{19-arm} 55 L{4-arm} 55 Z" fill="#d99d54"/>
 <path d="M{8-arm} 45 L{14-arm} 45 L{15-arm} 52 L{7-arm} 52 Z" fill="#ffdf90" stroke-width="1"/>
 <path d="M{10-arm} 51 Q{7-arm} 48 {11-arm} 46 Q{15-arm} 50 {10-arm} 51" fill="#ef8545" stroke="none"/>
 </g></svg>'''
 (p/'assets'/f'hearth_herald_{pose}.svg').write_text(svg)
