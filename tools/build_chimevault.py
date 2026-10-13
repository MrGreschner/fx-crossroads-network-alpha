"""Original Chimevault sprites and editable realm data. Does not overwrite student assets."""
from pathlib import Path
from PIL import Image,ImageDraw
import json
R=Path(__file__).resolve().parents[1]
def save(kind,key,value):(R/f'content/{kind}/{key}.json').write_text(json.dumps(value,indent=2)+'\n')
for key,hp,speed,damage in [('tuning_wraith',95,92,19),('resonance_beetle',110,92,22),('gongbreaker',1100,35,45),('silence_regent',2400,48,36)]:
 save('enemies',key,dict(id=key,name=key.replace('_',' ').title(),sprite=key,health=hp,speed=speed,damage=damage,behaviour='chase',aggro_range=650,expansion_only=True))
 for n,pose in enumerate(['idle','walk1','walk2','attack']):
  im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);shift=[0,1,-1,0][n];ink='#101b27'
  if key=='tuning_wraith':
   d.polygon([(19,12),(31,6),(44,15),(41,32),(49,52),(35,48),(28,57),(21,46),(13,52),(20,29)],fill=ink)
   d.polygon([(21,14),(32,10),(40,17),(37,33),(44,47),(35,44),(28,51),(23,41),(18,46),(24,27)],fill='#477e87')
   d.ellipse((24,17,37,31),fill='#152532');d.rectangle((25,22,29,24),fill='#a1fff1');d.rectangle((33,22,36,24),fill='#a1fff1')
   d.rectangle((47,15,50,47),fill='#d9bd78');d.rectangle((43,8,46,23),fill='#95eae0');d.rectangle((51,8,54,23),fill='#95eae0');d.rectangle((43,22,54,26),fill='#d9bd78')
   for y in [35,40]:d.line((24,y,37,y-3),fill='#78bdc3',width=2)
  elif key=='resonance_beetle':
   for y in [23,34,43]:
    d.line((20,y,10,y+5+shift),fill=ink,width=5);d.line((44,y,54,y+5-shift),fill=ink,width=5)
   d.ellipse((16,14,47,52),fill=ink);d.ellipse((20,17,43,48),fill='#b37c43');d.line((32,20,32,46),fill='#e8c68b',width=3)
   for x in [24,38]:d.rectangle((x,24,x+3,41),fill='#f1d19a')
   d.ellipse((23,8,40,21),fill='#314a51');d.rectangle((26,13,29,15),fill='#82f4e0');d.rectangle((35,13,38,15),fill='#82f4e0')
  elif key=='gongbreaker':
   d.rectangle((15,46,26,60),fill=ink);d.rectangle((37,46,48,60),fill=ink)
   d.rectangle((17,48,25,57+shift),fill='#75887f');d.rectangle((39,48,47,57-shift),fill='#75887f')
   d.polygon([(17,13),(47,13),(52,44),(44,51),(20,51),(12,44)],fill=ink)
   d.polygon([(20,16),(44,16),(48,42),(41,47),(23,47),(17,41)],fill='#7e8d77')
   d.ellipse((21,23,43,46),fill='#bd995a',outline='#e3c77f',width=3);d.ellipse((28,28,36,38),fill='#354d4b')
   d.rectangle((21,3,44,17),fill=ink);d.rectangle((24,6,41,16),fill='#688b85');d.rectangle((27,11,31,13),fill='#d0f8dd');d.rectangle((35,11,39,13),fill='#d0f8dd')
   d.rectangle((2,23,13,42),fill='#50716a');d.rectangle((49,23,59,38),fill='#50716a');d.rectangle((50,35,61,51),fill='#d1ad65');d.line((18,17,25,23),fill='#d6e1b2',width=2)
  else:
   d.polygon([(12,52),(19,20),(45,20),(53,52),(43,59),(21,59)],fill=ink)
   d.polygon([(17,49),(23,22),(41,22),(48,49),(40,53),(24,53)],fill='#796080')
   d.ellipse((19,19,45,48),fill='#ae8eab',outline='#e9c7bb',width=3);d.ellipse((25,26,39,40),fill='#1c2835')
   d.polygon([(18,19),(13,7),(26,12),(32,3),(38,12),(51,7),(46,20)],fill='#ceae72',outline=ink)
   d.rectangle((27,30,30,33),fill='#97f5e7');d.rectangle((35,30,38,33),fill='#97f5e7')
   d.line((8,28,17,34),fill='#99dcd3',width=3);d.line((47,34,57,28),fill='#99dcd3',width=3)
  if pose=='attack':
   d.arc((3,3,60,60),20,150,fill='#bafaf0',width=2);d.arc((6,6,57,57),200,330,fill='#e9c985',width=2)
  im.save(R/f'assets/{key}_{pose}.png')
save('regions','chimevault',dict(id='chimevault',name='The Chimevault',size=[9000,2400],terrain='ash',scene='res://scenes/realms/chimevault.tscn',boss_sprite='silence_regent',boss_health=2400,xp_per_level=4,expansion='chimevault',difficulty_label='Expert expedition: three maze floors, slow heavy guardians and the Silence Regent',description='A buried cathedral of cracked bells. Find the lift on each winding floor while battling travelling sound waves and explosive resonance mines. Every floor must be cleared before the lift opens.'))
lines=['[gd_scene format=3]','[node name="Chimevault" type="Node2D"]','[node name="GroundPaint" type="Node2D" parent="."]','[node name="Obstacles" type="Node2D" parent="."]','[node name="Enemies" type="Node2D" parent="."]','[node name="Decorations" type="Node2D" parent="."]','[node name="Buildings" type="Node2D" parent="."]','[node name="Points" type="Node2D" parent="."]']
for key,x,y in [('Spawn',340,340),('ReturnGate',340,340),('Merchant',340,340),('Boss',8340,1800)]:lines.extend([f'[node name="{key}" type="Marker2D" parent="Points"]',f'position = Vector2({x},{y})'])
(R/'scenes/realms/chimevault.tscn').write_text('\n\n'.join(lines)+'\n')
f=R/'content/manifest.json';m=json.loads(f.read_text())
for key in ['tuning_wraith','resonance_beetle','gongbreaker','silence_regent']:
 if key not in m['enemies']:m['enemies'].append(key)
if 'chimevault' not in m['regions']:m['regions'].insert(m['regions'].index('shattered_oath'),'chimevault')
f.write_text(json.dumps(m,indent=2)+'\n')
