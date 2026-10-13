"""Generate the academy heroes using the project's procedural pixel-art system."""
from pathlib import Path
import json
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
HEROES={
'baseball':{'id':'baseball','name':'Diamond Scout','sprite':'baseball','max_health':110,'speed':240,'run_cost':0,
'primary':{'name':'Pitch','style':'projectile','damage':22,'cooldown':0.65,'range':400,'speed':650,'color':'#f4ebda'},
'secondary':{'name':'Bat Sweep','style':'melee','damage':42,'cooldown':2.8,'range':105,'arc_degrees':95,'visual':'swing','color':'#dfb978'},
'special':{'name':'Triple Play','style':'projectile','damage':22,'cooldown':10.0,'range':440,'speed':720,'count':3,'spread':0.18,'color':'#f8e0b1'},
'passive':'Batting Practice: Bat Sweep cooldown is reduced by 20%.','passive_effect':'quick_secondary'},
'golfer':{'id':'golfer','name':'Fairway Ranger','sprite':'golfer','max_health':100,'speed':225,'run_cost':0,
'primary':{'name':'Fairway Drive','style':'projectile','damage':30,'cooldown':1.0,'range':560,'speed':520,'color':'#eff5de'},
'secondary':{'name':'Chip Shot','style':'target_aoe','damage':24,'cooldown':4.0,'range':330,'blast_radius':80,'travel_speed':380,'color':'#bde79d'},
'special':{'name':'Course Ricochet','style':'chain','damage':34,'cooldown':12.0,'range':440,'jump_range':180,'jumps':3,'color':'#cfe8a0'},
'passive':'Calm Focus: recover 4 health after defeating an enemy.','passive_effect':'heal_on_kill'}
}
for ident,data in HEROES.items():
 (ROOT/f'content/characters/{ident}.json').write_text(json.dumps(data,indent=2)+'\n')
 for frame,pose in enumerate(['idle','walk1','walk2','attack']):
  im=Image.new('RGBA',(48,48));d=ImageDraw.Draw(im)
  bob=1 if frame==1 else -1 if frame==2 else 0
  skin='#d6b48a';outline='#223544';boots='#273b46'
  d.ellipse((10,42,36,46),fill='#263d3860')
  if ident=='baseball':
   # White baseball uniform, navy cap, stitched ball, bat and leather glove.
   d.rectangle((14,19+bob,33,36+bob),fill='#e8e6d4',outline=outline,width=2)
   d.line((23,22+bob,23,35+bob),fill='#8094a0',width=1)
   d.rectangle((14,34+bob,33,37+bob),fill='#354c76')
   d.rectangle((15,36,21,43+(frame==1)),fill='#e1ddcc');d.rectangle((27,36,33,43+(frame==2)),fill='#e1ddcc')
   d.rectangle((14,43,22,45),fill=boots);d.rectangle((27,43,35,45),fill=boots)
   d.rectangle((16,8+bob,31,20+bob),fill=skin,outline=outline)
   d.rectangle((14,5+bob,32,11+bob),fill='#345781');d.rectangle((29,10+bob,38,12+bob),fill='#284666')
   d.rectangle((20,6+bob,22,9+bob),fill='#e8c478')
   d.rectangle((19,14+bob,21,15+bob),fill=outline);d.rectangle((27,14+bob,29,15+bob),fill=outline)
   d.rectangle((9,22+bob,14,29+bob),fill=skin);d.ellipse((5,24+bob,14,34+bob),fill='#a57c4d',outline='#684e37',width=2)
   if pose=='attack':
    d.line((31,25,43,20),fill=skin,width=5);d.ellipse((40,15,46,21),fill='#f5efdf');d.line((42,16,44,20),fill='#bc5d56',width=1)
    d.line((15,27,5,15),fill='#bc975c',width=3)
   else:
    d.rectangle((33,21+bob,37,29+bob),fill=skin);d.line((36,29+bob,42,8+bob),fill='#cba66b',width=3)
  else:
   # Green polo, visor, patterned trousers and an unmistakable golf club.
   d.rectangle((13,20+bob,32,34+bob),fill='#467c63',outline=outline,width=2)
   d.polygon([(15,21+bob),(23,28+bob),(30,21+bob)],fill='#e8eed7')
   d.rectangle((15,34,22,43),fill='#bfb6a0');d.rectangle((26,34,33,43),fill='#bfb6a0')
   for x in [17,20,28,31]:d.line((x,35,x,42),fill='#7a8879')
   d.line((15,38,33,38),fill='#778376')
   d.rectangle((14,43,23,45),fill=boots);d.rectangle((26,43,35,45),fill=boots)
   d.rectangle((15,8+bob,30,20+bob),fill=skin,outline=outline)
   d.rectangle((14,5+bob,30,10+bob),fill='#e6edd4');d.rectangle((27,10+bob,37,12+bob),fill='#f6f4e4')
   d.rectangle((18,14+bob,20,15+bob),fill=outline);d.rectangle((26,14+bob,28,15+bob),fill=outline)
   d.rectangle((7,26+bob,12,39+bob),fill='#475374',outline=outline)
   if pose=='attack':
    d.line((30,25,37,30),fill=skin,width=4);d.line((36,29,44,13),fill='#b8c9cd',width=2);d.rectangle((40,10,46,14),fill='#d9e5df')
   else:
    d.rectangle((32,23+bob,36,29+bob),fill=skin);d.line((35,27+bob,40,42),fill='#b8c9cd',width=2);d.rectangle((37,41,44,44),fill='#d9e5df')
   d.ellipse((38,36,42,40),fill='#f3f5df')
  im.save(ROOT/f'assets/{ident}_{pose}.png')
  if frame<2:im.save(ROOT/f'assets/{ident}_{frame}.png')
p=ROOT/'content/manifest.json';m=json.loads(p.read_text())
for ident in HEROES:
 if ident not in m['characters']:m['characters'].append(ident)
p.write_text(json.dumps(m,indent=2)+'\n')
