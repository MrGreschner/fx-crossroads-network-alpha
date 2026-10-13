from pathlib import Path
import json
from PIL import Image,ImageDraw
p=Path(__file__).resolve().parents[1]
def attack(name,style,dmg,cd,r,desc,**extra):return dict(name=name,style=style,damage=dmg,cooldown=cd,range=r,description=desc,**extra)
primary=attack('Pocket Twister','twister_charge',3,.55,350,'Hold LMB to grow a funnel; release to cast. Charge caps at 1.6s: 3–6 damage every 0.5s, 25–45 reach radius. Lasts 4.2s; at most four funnels. All slow 30%; full charge gently pulls nearby foes. Funnels drift and curve, stopping at walls.',radius=25,max_funnels=4)
secondary=attack('Whirlaway','twister_stride',7,9,48,'Become a controllable tornado for 3 seconds: +55% movement speed, 7 damage every 0.5s to nearby enemies, slowing them 30%. No invulnerability.',duration=3)
special=attack('Hail, Please!','twister_hail',16,23,210,'Stand still and channel for 2 seconds, then summon 12 hailstones over 3.6 seconds around the casting spot. Each warned landing deals 16 damage and stuns foes for 0.6s. Ice never hits allies.',charge_time=2)
h=dict(id='twisterspell',sprite='twisterspell',name='Twisterspell',max_health=110,speed=220,run_cost=0,lore='A cheerful weather apprentice who collects river mist in her hat. She tends Crossroads’ new Mistglass Spire, turning unruly breezes into carefully bottled spells.',primary=primary,secondary=secondary,special=special,passive='Patient Forecast: your drifting primary funnels linger one extra second. Their damage and maximum count stay the same.',passive_effect='weather_patience')
h['mastery']=dict(title='Keeper of the Turning Sky',technique=dict(name='Wide Forecast',ability='primary',description='Trade four compact funnels for two wider ones: less damage per tick, better coverage.',attack=attack('Wide Forecast','twister_charge',2.5,.75,350,'Charge and release wider, lighter funnels: 2.5–5 damage per 0.5s, 36–65 radius. Only two may exist. Full charge gently pulls foes.',radius=36,max_funnels=2)),final_technique=dict(name='Sleet Stitch',ability='special',description='Trade random surrounding hail and brief stuns for a directed line of heavier ice and longer slows.',attack=attack('Sleet Stitch','twister_sleet',20,23,310,'Channel in place for 1 second, then stitch 12 warned icy landings along the aimed corridor. Each deals 20 damage and slows 45% for 3 seconds; no stun.',charge_time=1)),technique_requirements=dict(clears=3,distinct_realms=2,damage=10000),title_requirements=dict(clears=6,distinct_realms=3,damage=20000),final_requirements=dict(clears=12,distinct_realms=6,damage=85000),crit_milestones=[dict(clears=n*3,chance=.02*n,bonus=.2*n) for n in range(1,4)])
# v112 balance and lightning passive override before writing generated content.
h['primary'].update(damage=6,radius=36,description='Hold and release: 6–14.4 damage per 0.5s, 36–61 radius. Full charge strongly pulls foes. Up to four funnels last 4.2s.')
h['passive']='Storm Circuit: three funnels link lightning for 8 damage and 0.35s stun every 1.25s; full-charge funnels also zap for 10 damage every 1.5s. One shock per target per caster per second.'
h['passive_effect']='weather_circuit'
h['mastery']['technique']['attack'].update(damage=5,radius=48,description='Up to two wider funnels: 5–12 damage per 0.5s, 48–82 radius. Full charge strongly pulls; direct lightning remains, but no three-funnel circuit.')
h['mastery']['technique']['description']='Two wider, lighter funnels replace four. Full-charge direct lightning remains; three-funnel links are unavailable.'
(p/'content/characters/twisterspell.json').write_text(json.dumps(h,indent=2)+'\n')
m=json.loads((p/'content/manifest.json').read_text());m['characters'].append('twisterspell') if 'twisterspell' not in m['characters'] else None;(p/'content/manifest.json').write_text(json.dumps(m,indent=2)+'\n')
(p/'content/hero_numbers.json').write_text(json.dumps({id:n+1 for n,id in enumerate(m['characters'])},indent=2)+'\n')
lib=json.loads((p/'content/hero_library.json').read_text());lib['twisterspell']=dict(role='Control',tags=['Ranged','Control'],difficulty='Technical',home_realm='silverfall',summary='Charge drifting tornadoes, ride the wind and warn foes with falling hail.',lore=h['lore'],passive_brief=h['passive']);(p/'content/hero_library.json').write_text(json.dumps(lib,indent=2)+'\n')
for pose in ['idle','walk1','walk2','attack']:
 im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);dy=-1 if pose=='walk1' else 1 if pose=='walk2' else 0
 def box(x,y,w,h,c):d.rectangle((x,y+dy,x+w-1,y+dy+h-1),fill=c)
 def poly(points,c):d.polygon([(x,y+dy) for x,y in points],fill=c)
 def oval(x,y,w,h,c):d.ellipse((x,y+dy,x+w-1,y+dy+h-1),fill=c)
 dark='#283d52';hair='#cab8ed';robe='#559ca4'
 box(21,49,7,9,dark);box(37,49,7,9,dark);box(18 if pose=='walk1' else 20,56,12,4,'#d0d3ee');box(36 if pose=='walk2' else 37,56,12,4,'#d0d3ee')
 poly([(21,28),(43,28),(49,51),(16,51)],dark);poly([(22,31),(41,31),(46,48),(19,48)],robe);box(21,46,23,3,'#d6d3ef');box(30,31,5,15,'#cedce6')
 oval(18,12,29,28,hair);box(17,26,8,21,hair);box(40,25,8,22,hair);box(19,32,3,11,'#e7d2f4');box(43,32,3,10,'#e7d2f4')
 oval(23,17,19,20,'#f1d1b6');box(26,25,3,4,dark);box(36,25,3,4,dark);box(28,33,8,2,'#ab6f83');box(24,30,3,2,'#e4a1ad');box(38,30,3,2,'#e4a1ad')
 poly([(14,18),(28,5),(35,2),(46,18)],dark);poly([(18,16),(29,7),(35,5),(42,16)],'#7883bc');box(12,17,38,4,'#98b8ce');box(24,13,19,4,'#cbd8ee');oval(32,12,5,5,'#f9e2a3')
 poly([(20,34),(12,39),(14,45),(24,39)],'#7eaeb5');box(12,41,7,4,'#f1d1b6');poly([(44,34),(50,39),(51,44),(43,40)],robe);box(48,40,6,5,'#f1d1b6')
 box(52,24,3,32,'#b09ab9');oval(47,18,13,13,'#d4edf0');d.arc((45,13+dy,60,27+dy),30,310,fill='#8db3d6',width=2);box(51,20,4,7,'#92c5d8')
 if pose=='attack':
  for n in range(4):d.arc((2+n,24+dy+n*4,20-n,32+dy+n*4),0,300,fill='#b4e2eb',width=2)
 im.save(p/'assets'/f'twisterspell_{pose}.png')
 for alias in (['twisterspell','twisterspell_0'] if pose=='idle' else ['twisterspell_1'] if pose=='walk1' else ['twisterspell_2'] if pose=='walk2' else []):im.save(p/'assets'/f'{alias}.png')
