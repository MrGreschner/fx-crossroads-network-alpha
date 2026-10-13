"""Original easy conservatory realm; deterministic editable scene and pixel assets."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,random
R=Path(__file__).resolve().parents[1]
def save(kind,key,value): (R/f'content/{kind}/{key}.json').write_text(json.dumps(value,indent=2)+'\n')
for key in ['honey_beetle','seed_blossom','glass_queen']:
 for n,pose in enumerate(['idle','walk1','walk2','attack']):
  im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);b=n%2;ink='#453e40'
  if key=='honey_beetle':
   for y in [30,39,47]: d.line((10,y,54,y+b),fill=ink,width=3)
   d.ellipse((15,17+b,49,52+b),fill='#e6a14c',outline=ink,width=2);d.line((32,20,32,48),fill=ink,width=2);d.ellipse((23,9,41,25),fill='#75553b',outline=ink)
   for x,y in [(21,29),(38,30),(23,41),(38,42)]: d.ellipse((x,y,x+5,y+5),fill='#fff0af')
  elif key=='seed_blossom':
   d.line((32,29,32,55),fill='#537a52',width=5);d.ellipse((10,39,31,49),fill='#8ab970',outline=ink);d.ellipse((33,42,54,52),fill='#8ab970',outline=ink)
   for x,y in [(16,11),(32,8),(39,22),(27,32),(12,27)]:d.ellipse((x,y+b,x+18,y+18+b),fill='#efbaac',outline=ink)
   d.ellipse((24,20,41,37),fill='#ffd681',outline=ink);d.ellipse((30,27,36,32),fill=ink)
  else:
   d.ellipse((4,15+b,31,43),fill='#b8e7e7aa',outline='#6a9c9e');d.ellipse((33,15,60,43+b),fill='#b8e7e7aa',outline='#6a9c9e');d.ellipse((18,25,46,57),fill='#efb855',outline=ink,width=2)
   for y in [35,45]:d.line((21,y,43,y),fill=ink,width=4)
   d.ellipse((20,12,44,32),fill='#f3d894',outline=ink);d.polygon([(22,14),(21,3),(28,8),(33,1),(38,8),(45,3),(42,15)],fill='#ffc660',outline=ink)
   for x in [26,36]:d.rectangle((x,21,x+2,24),fill=ink)
  im.save(R/f'assets/{key}_{pose}.png')
  if n<2:im.save(R/f'assets/{key}_{n}.png')
for key in ['glass_pavilion','garden_fountain','flower_bed','honey_lamp']:
 im=Image.new('RGBA',(128,144));d=ImageDraw.Draw(im);ink='#536461'
 if key=='glass_pavilion':
  d.rectangle((10,51,118,131),fill='#9ccfc7b0',outline=ink,width=4);d.polygon([(8,52),(64,6),(120,52)],fill='#c4eee3bb',outline=ink)
  for x in [35,64,93]:d.line((x,51,x,130),fill='#a98452',width=4)
  d.line((12,91,116,91),fill='#a98452',width=3);d.rectangle((49,97,78,131),fill='#467768');d.rectangle((6,132,122,139),fill='#b69f78')
 elif key=='garden_fountain':
  d.ellipse((5,91,123,141),fill='#b5aa88',outline=ink,width=3);d.ellipse((14,97,114,129),fill='#72bfc7');d.rectangle((57,39,71,114),fill='#d0c9a2');d.ellipse((31,39,96,63),fill='#bcc5ab',outline=ink)
  d.line((63,50,63,16),fill='#c6f5ed',width=6)
  for x in [32,46,82,96]: d.line((63,26,x,54,x,103),fill='#a7e5de',width=3)
 elif key=='flower_bed':
  d.rectangle((3,79,125,137),fill='#a68b66',outline=ink,width=3);d.rectangle((9,85,119,131),fill='#637b4a')
  for x in range(18,119,24):
   for y in [91,115]:d.ellipse((x-6,y-6,x+7,y+7),fill='#edaab1' if x%3 else '#f5d885');d.ellipse((x-2,y-2,x+2,y+2),fill='#fff1b5')
 else:
  d.rectangle((60,45,67,139),fill=ink);d.polygon([(45,27),(63,13),(81,27),(81,49),(63,63),(45,49)],fill='#edbb61',outline=ink);d.ellipse((56,27,70,49),fill='#fff0ba')
 im.save(R/f'assets/{key}.png')
im=Image.new('RGBA',(64,64),'#779366');d=ImageDraw.Draw(im);rng=random.Random(28)
for _ in range(65):
 x,y=rng.randrange(64),rng.randrange(64);d.rectangle((x,y,x+2,y+2),fill=rng.choice(['#8ca977','#6b865b','#9aaf7c']))
im.save(R/'assets/garden_grass.png')
for key,hp,speed,damage,behaviour in [('honey_beetle',60,72,7,'chase'),('seed_blossom',48,32,6,'ranged'),('glass_queen',640,55,10,'chase')]:
 save('enemies',key,dict(id=key,name={'honey_beetle':'Honey Beetle','seed_blossom':'Seed Blossom','glass_queen':'Queen Mellifera'}[key],sprite=key,health=hp,speed=speed,damage=damage,behaviour=behaviour,aggro_range=380,shot_speed=200,shot_cooldown=3.4,expansion_only=True))
lines=['[gd_scene load_steps=5 format=3]']
for i,key in enumerate(['glass_pavilion','garden_fountain','flower_bed','honey_lamp']):lines.append(f'[ext_resource type="Texture2D" path="res://assets/{key}.png" id="a{i}"]')
lines+=['[node name="HoneyglassGardens" type="Node2D"]','[node name="Points" type="Node2D" parent="."]']
for name,x,y in [('Spawn',300,1500),('ReturnGate',150,1500),('Merchant',2800,1500),('Boss',5550,1500)]:lines += [f'[node name="{name}" type="Marker2D" parent="Points"]',f'position = Vector2({x},{y})']
lines+=['[node name="GroundPaint" type="Node2D" parent="."]']
for i,(x,y,w,h) in enumerate([(0,1380,6200,240),(1300,500,200,2100),(3000,500,200,2100),(4700,500,200,2100),(1100,500,3900,160),(1100,2500,3900,160)]):lines += [f'[node name="Path{i}" type="Polygon2D" parent="GroundPaint"]',f'polygon = PackedVector2Array({x},{y},{x+w},{y},{x+w},{y+h},{x},{y+h})','metadata/tile = "path"']
lines+=['[node name="Enemies" type="Node2D" parent="."]']
for i in range(24):
 x=850+(i//4)*710;y=[1120,1820,850,2140][i%4];lines += [f'[node name="Enemy{i}" type="Marker2D" parent="Enemies"]',f'position = Vector2({x},{y})',f'metadata/enemy_id = "{ "seed_blossom" if i%4==3 else "honey_beetle"}"']
lines+=['[node name="Obstacles" type="Node2D" parent="."]']
for i,x in enumerate([1100,2200,3300,4400]):
 for j,y in enumerate([420,2680]):lines += [f'[node name="Fountain{i}_{j}" type="Sprite2D" parent="Obstacles"]',f'position = Vector2({x},{y})','texture = ExtResource("a1")','metadata/kind = "rock"','metadata/radius = 44.0']
lines+=['[node name="Decorations" type="Node2D" parent="."]']
for i in range(76):
 x=450+(i//2)*145;y=210 if i%2==0 else 2860;asset=0 if i%10==0 else 3 if i%3==0 else 2
 lines += [f'[node name="Garden{i}" type="Sprite2D" parent="Decorations"]',f'position = Vector2({x},{y})',f'texture = ExtResource("a{asset}")']
(R/'scenes/realms/honeyglass.tscn').write_text('\n\n'.join(lines)+'\n')
save('regions','honeyglass',dict(id='honeyglass',name='Honeyglass Gardens',size=[6200,3100],terrain='garden_grass',scene='res://scenes/realms/honeyglass.tscn',boss_sprite='glass_queen',boss_health=640,boss_secondary='fireball',xp_per_level=4,unlock_cost=0,difficulty_label='Easy — amber conservatory',description='Explore glass pavilions, fountains and blossom beds. Slow beetles and seed blossoms guard Queen Mellifera.'))
p=R/'content/manifest.json';m=json.loads(p.read_text())
for k in ['honey_beetle','seed_blossom','glass_queen']:
 if k not in m['enemies']:m['enemies'].append(k)
if 'honeyglass' in m['regions']:m['regions'].remove('honeyglass')
m['regions'].insert(m['regions'].index('quarry')+1,'honeyglass');p.write_text(json.dumps(m,indent=2)+'\n')
