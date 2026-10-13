from pathlib import Path
from PIL import Image,ImageDraw
import json
R=Path(__file__).resolve().parents[1]
hero=dict(id='patch',name='Patch',sprite='patch',max_health=110,speed=240,run_cost=0,lore='A forgotten arcade controller awakened by Crossroads magic. Never travels without a player two.',primary=dict(name='D-Pad Volley',style='cross_shot',damage=14,cooldown=.8,range=340,speed=400,color='#84e1dd',description='Fire four bolts in a cross: one toward your aim, one behind and one to each side. Each deals 14 damage.'),secondary=dict(name='Reset Pulse',style='pulse_wave',damage=18,cooldown=6,radius=135,clear_projectiles=True,color='#b9a7ec',description='Send a short expanding pulse for 18 damage and erase hostile projectiles within 135 units.'),special=dict(name='Player Two',style='summon',damage=10,cooldown=18,duration=9,count=2,minion_speed=255,minion_sprite='bit_buddy',color='#84e1dd',description='Summon two Bit Buddies for 9 seconds. Each follows you, chases nearby enemies and deals 10 damage per hit.'),passive='Extra Credits: Bit Buddies stay for two additional seconds.',passive_effect='long_buddies')
(R/'content/characters/patch.json').write_text(json.dumps(hero,indent=2)+'\n')
p=R/'content/manifest.json';m=json.loads(p.read_text())
if 'patch' not in m['characters']:m['characters'].append('patch')
p.write_text(json.dumps(m,indent=2)+'\n')
for key in ['patch','bit_buddy']:
 for n,pose in enumerate(['idle','walk1','walk2','attack']):
  im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);ink='#27364d';b=[0,1,-1,0][n]
  if key=='patch':
   d.line((32,18+b,32,7,44,4,49,10),fill='#849cab',width=3)
   d.polygon([(10,20+b),(23,16+b),(41,16+b),(54,20+b),(61,42+b),(55,52+b),(46,49+b),(40,39+b),(24,39+b),(18,49+b),(9,52+b),(3,42+b)],fill='#7797a8',outline=ink)
   d.rectangle((10,26+b,24,31+b),fill=ink);d.rectangle((15,21+b,19,36+b),fill=ink)
   for x,y,c in [(45,24,'#f0c96d'),(52,31,'#ef8d94'),(38,31,'#8ee5d8'),(45,38,'#bca4ef')]:d.ellipse((x-3,y-3+b,x+3,y+3+b),fill=c,outline=ink)
   d.rectangle((28,22+b,36,30+b),fill='#bdf4e7');d.point((30,25+b),fill=ink);d.point((34,25+b),fill=ink);d.line((29,33+b,35,33+b),fill=ink,width=2)
   d.rectangle((18,46,24,57+n%2),fill=ink);d.rectangle((40,46,46,57-n%2),fill=ink)
   if pose=='attack':d.line((5,17,0,9),fill='#9cf5e3',width=3);d.line((59,17,63,9),fill='#9cf5e3',width=3)
  else:
   d.rectangle((20,38,26,53+b),fill=ink);d.rectangle((38,38,44,53-b),fill=ink);d.rectangle((14,13+b,50,42+b),fill='#698b99',outline=ink,width=2);d.rectangle((19,19+b,45,33+b),fill='#b0eddb',outline=ink)
   d.rectangle((24,24+b,27,27+b),fill=ink);d.rectangle((37,24+b,40,27+b),fill=ink);d.line((28,7,35,7,35,13),fill=ink,width=2);d.ellipse((25,3,31,9),fill='#f5cc71')
   d.line((14,29,7,40+b),fill=ink,width=4);d.line((50,29,57,40-b),fill=ink,width=4)
  im.save(R/f'assets/{key}_{pose}.png')
  if n<2:im.save(R/f'assets/{key}_{n}.png')
  if n==0:im.save(R/f'assets/{key}.png')
