"""Original Vesper and Astral Rift assets/data. Leaves student content intact."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,random,math
R=Path(__file__).resolve().parents[1]
def data(kind,key,value):(R/f'content/{kind}/{key}.json').write_text(json.dumps(value,indent=2)+'\n')
data('characters','vesper',dict(id='vesper',name='Vesper',sprite='vesper',max_health=100,speed=245,run_cost=0,lore='A bat courier who carries lost stars between broken observatories.',primary=dict(name='Orbitblade',style='return_disc',damage=16,cooldown=1.1,range=220,speed=380,color='#94eafa'),secondary=dict(name='Comet Seal',style='target_aoe',damage=32,cooldown=5,range=300,blast_radius=85,color='#bcb0ff'),special=dict(name='Starlit Veil',style='block',damage=0,cooldown=12,duration=2,reduction=.6,color='#9bdeee'),passive='Night Rhythm: secondary cooldown is 20% shorter.',passive_effect='quick_secondary'))
for key,hp,speed,dmg,attack in [('rift_weaver',90,65,9,'portals'),('prism_kite',72,90,9,'beam'),('comet_urchin',96,80,12,'charge'),('eclipse_engine',1000,50,26,'eclipse')]:
 data('enemies',key,dict(id=key,name=key.replace('_',' ').title(),sprite=key,health=hp,speed=speed,damage=dmg,behaviour='chase',custom_attack=attack,aggro_range=500,expansion_only=True))
for key in ['vesper','rift_weaver','prism_kite','comet_urchin','eclipse_engine']:
 for n,pose in enumerate(['idle','walk1','walk2','attack']):
  im=Image.new('RGBA',(48,48));d=ImageDraw.Draw(im);b=[0,1,-1,0][n];ink='#1d263d';d.ellipse((7,40,42,46),fill='#12203555')
  if key=='vesper':
   d.polygon([(19,24),(3,17+b),(5,36),(13,30),(19,40)],fill='#655c91',outline=ink);d.polygon([(30,24),(45,17-b),(43,36),(36,30),(30,40)],fill='#655c91',outline=ink)
   d.polygon([(16,22),(31,22),(35,42),(12,42)],fill='#42899d',outline=ink);d.line((20,25,29,36),fill='#e1cf94',width=3)
   d.polygon([(12,14),(11,1),(21,9),(29,9),(39,1),(35,15)],fill='#a09abd',outline=ink);d.ellipse((13,9+b,35,28+b),fill='#b4aac4',outline=ink)
   d.rectangle((18,16+b,20,18+b),fill=ink);d.rectangle((29,16+b,31,18+b),fill=ink);d.polygon([(22,21),(26,21),(24,24)],fill=ink)
   d.rectangle((17,39,22,45),fill='#454565');d.rectangle((27,39,32,45),fill='#454565')
   d.arc((33,25,47,39),30,310,fill='#bde9e5',width=3)
  elif key=='rift_weaver':
   for x,y in [(2,10),(2,30),(6,43),(46,10),(46,30),(41,43)]:d.line((24,25,x,y+b),fill='#928ac7',width=3)
   d.ellipse((13,13+b,36,38+b),fill='#504571',outline=ink,width=2);d.ellipse((18,18+b,31,31+b),fill='#a4cae6');d.ellipse((21,20+b,28,29+b),fill='#292f53')
   d.rectangle((17,11,20,15),fill='#ecd68b');d.rectangle((28,11,31,15),fill='#ecd68b')
  elif key=='prism_kite':
   d.polygon([(24,2),(43,22+b),(24,41),(5,22-b)],fill='#6fb4cd',outline=ink,width=2);d.polygon([(24,8),(35,22),(24,34),(13,22)],fill='#cde5d6',outline='#797fb5');d.line((24,7,24,36),fill='#f4f0cd',width=2);d.line((24,39,32,46,40,40),fill='#aa9be0',width=2)
  elif key=='comet_urchin':
   for k in range(9):
    a=math.tau*k/9;d.line((24,24,24+int(math.cos(a)*22),24+int(math.sin(a)*22)),fill='#d5bd83',width=3)
   d.ellipse((11,11+b,37,37+b),fill='#646886',outline=ink,width=2);d.polygon([(24,14),(18,25),(24,23),(20,33),(32,21),(26,23)],fill='#abdfe9')
  else:
   d.ellipse((3,3,45,45),fill='#313b58',outline='#ba9cd7',width=4);d.ellipse((10,10,38,38),fill='#101b2c',outline='#92ced6',width=3)
   d.pieslice((13,13,35,35),70,310,fill='#d5cb8c');d.ellipse((21,12,38,32),fill='#101b2c')
   for x,y in [(24,1),(24,46),(1,24),(46,24)]:d.rectangle((x-2,y-2,x+2,y+2),fill='#d9d0a8')
  im.save(R/f'assets/{key}_{pose}.png')
  if n<2:im.save(R/f'assets/{key}_{n}.png')
for key,col in [('astral_void','#10192c'),('astral_floor','#3d4c69'),('astral_bridge','#687187')]:
 im=Image.new('RGBA',(64,64),col);d=ImageDraw.Draw(im);rng=random.Random(key)
 for i in range(20):
  x,y=rng.randrange(64),rng.randrange(64);d.rectangle((x,y,x+(0 if key=='astral_void' else 2),y),fill='#aab9ce70')
 if key!='astral_void':d.line((0,32,64,32),fill='#25364f');d.line((32,0,32,32),fill='#25364f');d.rectangle((1,1,62,62),outline='#7895b180')
 im.save(R/f'assets/{key}.png')
for key in ['star_obelisk','astrolabe']:
 im=Image.new('RGBA',(128,160));d=ImageDraw.Draw(im)
 if key=='star_obelisk':
  d.polygon([(64,2),(86,32),(80,140),(48,140),(42,32)],fill='#626c88',outline='#25304b');d.polygon([(64,12),(71,34),(66,103),(57,103),(56,34)],fill='#b1d8e4');d.ellipse((27,122,101,154),fill='#394660',outline='#8c9abd',width=3)
 else:
  d.rectangle((56,94,71,148),fill='#8b91a6');d.ellipse((6,4,121,119),outline='#b6a88a',width=8);d.ellipse((17,32,111,91),outline='#8dc9d3',width=6);d.line((65,12,65,108),fill='#e0d3a8',width=3);d.line((18,58,108,58),fill='#e0d3a8',width=3);d.ellipse((49,43,80,75),fill='#aa95d1',outline='#f0e4bd',width=3)
 im.save(R/f'assets/{key}.png')
lines=['[gd_scene load_steps=3 format=3]','[ext_resource type="Texture2D" path="res://assets/star_obelisk.png" id="obelisk"]','[ext_resource type="Texture2D" path="res://assets/astrolabe.png" id="astro"]','[node name="AstralRift" type="Node2D"]','[node name="Points" type="Node2D" parent="."]']
for name,x,y in [('Spawn',450,1800),('ReturnGate',300,1800),('Merchant',1000,2000),('Boss',7100,1800)]:lines += [f'[node name="{name}" type="Marker2D" parent="Points"]',f'position = Vector2({x},{y})']
lines+=['[node name="GroundPaint" type="Node2D" parent="."]']
patches=[(180,1100,7640,1400,'astral_floor'),(600,500,1100,500,'astral_floor'),(3400,500,1200,500,'astral_floor'),(6500,500,1200,500,'astral_floor'),(1050,900,200,500,'astral_bridge'),(3900,900,200,500,'astral_bridge'),(7000,900,200,500,'astral_bridge')]
for i,(x,y,w,h,tile) in enumerate(patches):lines += [f'[node name="Floor{i}" type="Polygon2D" parent="GroundPaint"]',f'polygon = PackedVector2Array({x},{y},{x+w},{y},{x+w},{y+h},{x},{y+h})',f'metadata/tile = "{tile}"']
lines+=['[node name="Enemies" type="Node2D" parent="."]']
for i in range(45):
 x=1200+i%15*400;y=1350+i//15*420
 lines += [f'[node name="Enemy{i}" type="Marker2D" parent="Enemies"]',f'position = Vector2({x},{y})',f'metadata/enemy_id = "{["rift_weaver","prism_kite","comet_urchin"][i%3]}"']
lines+=['[node name="Obstacles" type="Node2D" parent="."]']
for i in range(24):
 x=500+i%12*610;y=1050 if i<12 else 2580
 lines += [f'[node name="Obelisk{i}" type="Sprite2D" parent="Obstacles"]',f'position = Vector2({x},{y})','texture = ExtResource("obelisk")','metadata/kind = "star_obelisk"','metadata/radius = 34.0']
lines+=['[node name="Decorations" type="Node2D" parent="."]']
for i,x in enumerate([1100,4000,7100]):lines += [f'[node name="Astrolabe{i}" type="Sprite2D" parent="Decorations"]',f'position = Vector2({x},700)','texture = ExtResource("astro")','scale = Vector2(2.2,2.2)']
(R/'scenes/realms/astral_rift.tscn').write_text('\n\n'.join(lines)+'\n')
data('regions','astral_rift',dict(id='astral_rift',name='Astral Rift',size=[8000,3200],terrain='astral_void',scene='res://scenes/realms/astral_rift.tscn',boss_sprite='eclipse_engine',boss_health=1000,xp_per_level=4,boss_secondary='eclipse',expansion='astral'))
p=R/'content/manifest.json';m=json.loads(p.read_text())
for kind,keys in [('characters',['vesper']),('enemies',['rift_weaver','prism_kite','comet_urchin','eclipse_engine']),('regions',['astral_rift'])]:
 for key in keys:
  if key not in m[kind]:m[kind].append(key)
p.write_text(json.dumps(m,indent=2)+'\n')
print('Astral Rift generated')
