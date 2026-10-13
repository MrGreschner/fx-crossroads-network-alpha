from pathlib import Path
import json
from PIL import Image,ImageDraw
p=Path(__file__).resolve().parents[1]
def atk(name,style,damage,cd,text,**kw):return dict(name=name,style=style,damage=damage,cooldown=cd,description=text,**kw)
heroes=[
dict(id='cloudloom',name='Cloudloom',sprite='cloudloom',max_health=110,speed=235,run_cost=0,lore='A wandering weather-weaver who stitches stray clouds into rain and safe winds.',primary=atk('Pocket Rain','pocket_rain',8,.85,'Send a small cloud forward; it pauses, then releases three aimed raindrops for 8 damage each.',range=400),secondary=atk('Tailwind Seam','tailwind_seam',7,9,'Weave a 400-unit wind lane for 4 seconds. Allies crossing it gain 30% speed; enemies take 7 damage each second.',range=400),special=atk('Thunder Procession','thunder_procession',28,18,'Three storm clouds travel forward in sequence. Each strikes each enemy once for 28 damage with visible lightning.',range=480),passive='Gentle Draft: Tailwind Seam also heals allies in its lane for 2 HP each second.',passive_effect='gentle_draft'),
dict(id='cairnheart',name='Cairnheart',sprite='cairnheart',max_health=145,speed=210,run_cost=0,lore='A badger stonecarver who carries the patient strength of the old hill roads.',primary=atk('Fault Steps','fault_steps',24,.8,'Raise three successive stone faults ahead. Each enemy can take 24 damage only once per cast.',range=175),secondary=atk('Stone Hoist','stone_hoist',36,7,'Lift the nearest aimed enemy within 220, briefly stunning it. After 1.2 seconds the cairn collapses for 36 damage within 85.',range=220),special=atk('Rolling Rampart','rolling_rampart',62,18,'Send a 240-unit-wide rampart forward. It hits each enemy once for 62 damage and pushes them back. Walls stop it.',range=340),passive='Bedrock: each foe hit by Fault Steps grants 5% damage reduction for 3 seconds, up to 20% per cast.',passive_effect='bedrock'),
dict(id='dustdevil',name='Dustdevil',sprite='dustdevil',max_health=125,speed=225,run_cost=0,lore='An enchanted brass vacuum from the town workshops. No stray spark escapes its spotless patrol.',primary=atk('Intake','vacuum_intake',12,.7,'Hold primary for a close intake: 12 damage every 0.7 seconds and a 1-second slow. Within the first 0.4 seconds it can catch one hostile projectile. Release to fire it where you aim for 36–60 damage. Stored shots release automatically after 6 seconds.',range=82),secondary=atk('Brush Crush','brush_crush',38,3.5,'Swing the brush across a close 110-degree arc, dealing 38 damage within 100 units.',range=100),special=atk('Grand Draw','grand_draw',0,16,'Channel a visible 320-unit vacuum cone for 2.5 seconds, pulling enemies towards the nozzle for a follow-up Brush Crush. Walls stop pulling; bosses are pulled less.',range=320),passive='Deep Filter: returned captured shots deal 8 additional damage.',passive_effect='deep_filter')
]
for h in heroes:
 (p/f'content/characters/{h["id"]}.json').write_text(json.dumps(h,indent=2)+'\n')
 for n,pose in enumerate(['idle','walk1','walk2','attack']):
  im=Image.new('RGBA',(32,40));d=ImageDraw.Draw(im);b=[0,-1,1,0][n];ink='#34434a'
  d.ellipse((5,34,28,39),fill='#263e3d')
  if h['id']=='cloudloom':
   d.polygon([(8,18+b),(24,18+b),(28,34),(4,34)],fill='#719fb1',outline=ink)
   d.polygon([(12,19+b),(19,19+b),(23,33),(8,33)],fill='#b3d1d2')
   d.rectangle((10,8+b,22,20+b),fill='#dec3a0',outline=ink)
   d.rectangle((10,7+b,22,11+b),fill='#e2dfcb');d.rectangle((9,10+b,11,18+b),fill='#e2dfcb')
   d.rectangle((13,13+b,14,14+b),fill=ink);d.rectangle((19,13+b,20,14+b),fill=ink)
   d.polygon([(6,8+b),(17,1+b),(26,8+b)],fill='#66889c',outline=ink)
   d.line((25,31,28,10+b),fill='#9e8866',width=2)
   for x,y in [(25,9),(29,9),(27,6)]:d.ellipse((x-3,y-2+b,x+2,y+3+b),fill='#e1e9da')
   d.rectangle((8,35,12,37),fill=ink);d.rectangle((20,35,24,37),fill=ink)
   if pose=='attack':d.line((19,20,26,17),fill='#dec3a0',width=3)
  elif h['id']=='cairnheart':
   d.rectangle((7,20+b,25,32),fill='#788c74',outline=ink)
   d.ellipse((6,5+b,25,22+b),fill='#b3ac9e',outline=ink)
   for x in [7,23]:d.ellipse((x-3,3+b,x+2,9+b),fill='#777776',outline=ink)
   d.polygon([(9,8+b),(12,9+b),(14,19+b),(10,18+b)],fill='#48505a')
   d.polygon([(20,8+b),(23,8+b),(21,18+b),(17,19+b)],fill='#48505a')
   for x in [11,20]:d.point((x,12+b),fill='#f1dc9d')
   d.rectangle((13,18+b,18,20+b),fill=ink)
   d.rectangle((6,30,12,37-n%2),fill='#66625a');d.rectangle((21,30,26,37+n%2),fill='#66625a')
   d.line((7,23,3,29+b),fill='#b3ac9e',width=3);d.line((25,23,29,29+b),fill='#b3ac9e',width=3)
   d.polygon([(1,24+b),(5,21+b),(9,24+b),(7,31+b),(2,31+b)],fill='#8d9a9b',outline=ink)
   if pose=='attack':d.line((23,22,29,18),fill='#b3ac9e',width=3)
  else:
   d.ellipse((7,30,13,38),fill=ink);d.ellipse((22,30,28,38),fill=ink)
   d.rounded_rectangle((7,14+b,26,33+b),radius=3,fill='#bb9a61',outline=ink)
   d.rectangle((10,17+b,23,24+b),fill='#718e8b',outline=ink)
   for x in [13,20]:d.rectangle((x,19+b,x+1,21+b),fill='#f4e3ae')
   d.arc((10,4+b,26,22+b),180,355,fill='#6b6d65',width=3)
   d.line((9,25+b,3,29+b),fill='#6b6d65',width=4)
   d.rectangle((0,28+b,8,33+b),fill='#8e9b91',outline=ink)
   d.rectangle((9,26+b,24,29+b),fill='#8a714e')
   if pose=='attack':d.rectangle((1,29+b,6,30+b),fill='#bee3df')
  im.save(p/f'assets/{h["id"]}_{pose}.png')
f=p/'content/manifest.json';d=json.loads(f.read_text())
for h in heroes:
 if h['id'] not in d['characters']:d['characters'].append(h['id'])
f.write_text(json.dumps(d,indent=2)+'\n')
f=p/'scripts/journey.gd';s=f.read_text().replace('for n in game.manifest.get("regions",[]).size():','for n in mini(5,game.manifest.get("regions",[]).size()):',1).replace('Vector2(700+n*52,1050)','Vector2(730+n*68,1180)',1).replace('Vector2(690,1085)','Vector2(700,1225)',1);f.write_text(s)
