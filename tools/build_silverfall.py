"""Original Silverfall content; rerunnable without replacing student content."""
from pathlib import Path
from PIL import Image, ImageDraw
import json, random
R=Path(__file__).resolve().parents[1]
def save(kind,key,value): (R/f'content/{kind}/{key}.json').write_text(json.dumps(value,indent=2)+'\n')
save('characters','ferryman',dict(id='ferryman',name='Reed of Silverfall',sprite='ferryman',max_health=115,speed=235,run_cost=0,primary=dict(name='Oar Sweep',style='melee',damage=25,cooldown=.65,range=82,arc_degrees=75,visual='swing',color='#bdeee1'),secondary=dict(name='Skipping Stones',style='projectile',damage=12,cooldown=3.5,range=390,speed=460,count=3,spread=.2,color='#90dfed'),special=dict(name='Riverward',style='block',damage=0,cooldown=12,duration=2.5,reduction=.6,color='#8ae3ef'),passive='Rivercraft: take 10% less damage.',passive_effect='guard',lore='An otter ferryman from Silverfall Reach, guiding lost travelers through the mist.'))
for key,hp,speed,damage,behaviour in [('cascade_heron',70,100,9,'ranged'),('sluice_beetle',105,65,12,'chase'),('ripple_eel',55,145,8,'chase'),('crowned_torrent',950,65,17,'chase')]:
 save('enemies',key,dict(id=key,name=key.replace('_',' ').title(),sprite=key,health=hp,speed=speed,damage=damage,behaviour=behaviour,aggro_range=450,shot_speed=270,shot_cooldown=2.8,expansion_only=True))
for key in ['ferryman','cascade_heron','sluice_beetle','ripple_eel','crowned_torrent']:
 for n,pose in enumerate(['idle','walk1','walk2','attack']):
  im=Image.new('RGBA',(48,48));d=ImageDraw.Draw(im);b=[0,1,-1,0][n];ink='#203541'
  d.ellipse((7,41,42,46),fill='#173b4250')
  if key=='ferryman':
   d.polygon([(30,28),(44,31),(43,40),(29,41)],fill='#866046',outline=ink)
   d.rectangle((15,23+b,32,39+b),fill='#3e8a87',outline=ink,width=2);d.line((17,27+b,30,34+b),fill='#dbc895',width=3)
   d.ellipse((12,7+b,35,27+b),fill='#98765b',outline=ink,width=2)
   d.ellipse((11,5+b,18,13+b),fill='#98765b');d.ellipse((29,5+b,36,13+b),fill='#98765b')
   d.ellipse((16,16+b,33,26+b),fill='#dcc79b');d.rectangle((18,13+b,20,15+b),fill=ink);d.rectangle((28,13+b,30,15+b),fill=ink);d.ellipse((23,18+b,26,21+b),fill=ink)
   d.rectangle((16,38,21,44),fill='#725744');d.rectangle((28,38,33,44),fill='#725744')
   d.line((6,11,9,43),fill='#b5a574',width=3);d.polygon([(3,2),(9,2),(11,15),(5,17)],fill='#d8c999',outline=ink)
   if pose=='attack':d.line((10,30,45,17),fill='#e4d8aa',width=4)
  elif key=='cascade_heron':
   d.line((19,32,14,44),fill='#d9aa6e',width=2);d.line((28,33,33,44),fill='#d9aa6e',width=2)
   d.ellipse((9,22+b,32,36+b),fill='#a4ccd0',outline=ink);d.line((29,25+b,28,10+b),fill='#d8eded',width=5);d.ellipse((24,5+b,36,15+b),fill='#e0f1e9',outline=ink);d.polygon([(35,9+b),(47,12+b),(35,14+b)],fill='#d7a864');d.point((32,9+b),fill=ink)
   d.polygon([(20,23+b),(4,12 if n==2 else 28),(12,34),(28,30+b)],fill='#528c9d',outline=ink)
  elif key=='sluice_beetle':
   for x in [5,42]:
    for y in [23,32,39]: d.line((24,28,x,y+b),fill='#80a7a3',width=3)
   d.ellipse((11,10+b,37,39+b),fill='#416b70',outline=ink,width=2);d.line((24,13+b,24,36+b),fill='#b9d1bb',width=2)
   d.rectangle((15,20+b,33,25+b),fill='#a89766');d.ellipse((17,4+b,30,16+b),fill='#6b999c',outline=ink);d.line((18,8,12,1),fill='#d5c591',width=2);d.line((29,8,35,1),fill='#d5c591',width=2)
  elif key=='ripple_eel':
   d.line((5,35+b,15,40-b,29,30+b,22,22,34,12),fill=ink,width=10);d.line((5,35+b,15,40-b,29,30+b,22,22,34,12),fill='#57b5c0',width=6)
   d.ellipse((28,5,43,18),fill='#a7e8dd',outline=ink);d.rectangle((37,9,39,11),fill=ink);d.polygon([(21,26),(15,15),(25,21)],fill='#d1cf8e')
  else:
   d.line((8,40,18,34,9,26,21,21,32,30,39,21,30,13),fill=ink,width=14);d.line((8,40,18,34,9,26,21,21,32,30,39,21,30,13),fill='#4497ad',width=10)
   d.ellipse((19,8+b,40,26+b),fill='#aadbd5',outline=ink,width=2);d.polygon([(20,10),(18,1),(25,6),(29,0),(33,6),(40,1),(39,12)],fill='#dbbc73',outline=ink)
   d.rectangle((23,15+b,26,17+b),fill=ink);d.rectangle((33,15+b,36,17+b),fill=ink);d.line((21,22,35,22),fill='#437a89',width=2)
   d.line((20,26,3,19),fill='#a4d8d0',width=3);d.line((37,29,46,36),fill='#a4d8d0',width=3)
  im.save(R/f'assets/{key}_{pose}.png')
  if n<2: im.save(R/f'assets/{key}_{n}.png')
for key,col in [('river_grass','#416a65'),('river_water','#286f91'),('river_bridge','#9d967c')]:
 im=Image.new('RGBA',(64,64),col);d=ImageDraw.Draw(im);rng=random.Random(key)
 for i in range(25):
  x,y=rng.randrange(64),rng.randrange(64);d.line((x,y,x+(14 if key=='river_water' else 3),y),fill='#86c5c780')
 if key=='river_bridge':
  for y in range(0,64,16):d.line((0,y,64,y),fill='#625f57',width=2)
 im.save(R/f'assets/{key}.png')
for key in ['waterfall','river_willow']:
 im=Image.new('RGBA',(128,192));d=ImageDraw.Draw(im)
 if key=='waterfall':
  d.polygon([(2,0),(125,0),(115,157),(7,166)],fill='#4f6972');d.rectangle((25,5,103,161),fill='#53aec4')
  for x in [30,45,61,79,95]: d.line((x,8,x-4,154),fill='#c2eeed',width=5)
  for x,y in [(0,150),(25,163),(55,153),(84,160)]:d.ellipse((x,y,x+45,y+28),fill='#c2e6e2d0')
 else:
  d.rectangle((55,55,69,177),fill='#7b7660');d.ellipse((7,8,117,96),fill='#326e65')
  for x in range(12,116,16):d.line((x,50,x-7,125+(x%3)*8),fill='#72a78b',width=7)
 im.save(R/f'assets/{key}.png')
# Visual scene remains editable through Godot markers, terrain paint and decorations.
lines=['[gd_scene load_steps=3 format=3]','[ext_resource type="Texture2D" path="res://assets/waterfall.png" id="falls"]','[ext_resource type="Texture2D" path="res://assets/river_willow.png" id="willow"]','[node name="SilverfallReach" type="Node2D"]','[node name="Points" type="Node2D" parent="."]']
for name,x,y in [('Spawn',450,1900),('ReturnGate',300,1900),('Merchant',850,2050),('Boss',6900,1900)]:lines += [f'[node name="{name}" type="Marker2D" parent="Points"]',f'position = Vector2({x},{y})']
lines+=['[node name="GroundPaint" type="Node2D" parent="."]']
patches=[(0,0,7600,460,'river_water')]
for n,y in enumerate([1100,2600,1400]):
 x=1600+n*1800;patches += [(x,460,380,3340,'river_water'),(x-50,y-180,480,360,'river_bridge')]
for i,(x,y,w,h,tile) in enumerate(patches):lines += [f'[node name="Paint{i}" type="Polygon2D" parent="GroundPaint"]',f'polygon = PackedVector2Array({x},{y},{x+w},{y},{x+w},{y+h},{x},{y+h})',f'metadata/tile = "{tile}"']
lines+=['[node name="Enemies" type="Node2D" parent="."]']
rng=random.Random(13)
for i in range(48):
 bank=i//12;x=900+bank*1800+(i%4)*155;y=750+(i%12)//4*1050+rng.randrange(-90,90)
 lines += [f'[node name="Enemy{i}" type="Marker2D" parent="Enemies"]',f'position = Vector2({x},{y})',f'metadata/enemy_id = "{["cascade_heron","sluice_beetle","ripple_eel"][i%3]}"']
lines+=['[node name="Obstacles" type="Node2D" parent="."]','[node name="Decorations" type="Node2D" parent="."]']
for i in range(18):
 x=250+i*410;lines += [f'[node name="Falls{i}" type="Sprite2D" parent="Decorations"]',f'position = Vector2({x},260)','texture = ExtResource("falls")','scale = Vector2(2.4,2.2)']
for i in range(38):
 x=300+i*185;y=590 if i%2==0 else 3510
 lines += [f'[node name="Willow{i}" type="Sprite2D" parent="Decorations"]',f'position = Vector2({x},{y})','texture = ExtResource("willow")']
(R/'scenes/realms/silverfall.tscn').write_text('\n\n'.join(lines)+'\n')
save('regions','silverfall',dict(id='silverfall',name='Silverfall Reach',size=[7600,3800],terrain='river_grass',scene='res://scenes/realms/silverfall.tscn',boss_sprite='crowned_torrent',boss_health=950,xp_per_level=4,boss_secondary='torrent',expansion='river'))
p=R/'content/manifest.json';m=json.loads(p.read_text())
for kind,keys in [('characters',['ferryman']),('enemies',['cascade_heron','sluice_beetle','ripple_eel','crowned_torrent']),('regions',['silverfall'])]:
 for key in keys:
  if key not in m[kind]: m[kind].append(key)
p.write_text(json.dumps(m,indent=2)+'\n')
print('Silverfall Reach generated')
