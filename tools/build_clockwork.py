"""Original Dawnblade, Stormscribe and Clockwork Orchard content."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,random
R=Path(__file__).resolve().parents[1]
def data(kind,key,value):
 if kind=='enemies' and key=='pendulum_moth': value.update({'health': 85, 'damage': 14, 'behaviour': 'chase', 'custom_attack': 'lob', 'lob_speed': 340, 'blast_radius': 90, 'skill_cooldown': 3.6, 'attack_color': '#ffd68a'})
 (R/f'content/{kind}/{key}.json').write_text(json.dumps(value,indent=2)+'\n')
data('characters','dawnblade',dict(id='dawnblade',name='Mara Dawnblade',sprite='dawnblade',max_health=130,speed=225,run_cost=0,lore='A wandering swordswoman who keeps the old orchard roads safe.',primary=dict(name='Sword Cut',style='melee',damage=28,cooldown=.6,range=82,arc_degrees=70,visual='swing',color='#ffe2a0'),secondary=dict(name='Riposte Guard',style='block',damage=0,cooldown=5,duration=1.2,reduction=.65,reflect=True),special=dict(name='Dawn Circle',style='spin',damage=48,cooldown=10,range=115,radius=115,color='#ffe6b7'),passive='Resolute: take 10% less damage.',passive_effect='guard'))
data('characters','stormscribe',dict(id='stormscribe',name='Stormscribe',sprite='stormscribe',max_health=90,speed=220,run_cost=0,lore='A wizard who reads the weather in the orchard clock towers.',primary=dict(name='Spark Script',style='projectile',damage=19,cooldown=.7,range=410,speed=480,color='#b0ceff'),secondary=dict(name='Threefold Lightning',style='chain',fork=True,damage=22,cooldown=4.8,range=350,jumps=3,jump_range=350,color='#b8daff'),special=dict(name='Thunderfall',style='target_aoe',damage=55,cooldown=13,range=330,blast_radius=155,color='#c6dcff'),passive='Spell Rhythm: primary cooldown is 20% shorter.',passive_effect='quick_primary'))
for key,hp,speed,dmg,behaviour in [('pendulum_moth',65,100,9,'ranged'),('tick_acorn',102,120,12,'chase'),('hourglass_hart',900,75,17,'chase')]:data('enemies',key,dict(id=key,name=key.replace('_',' ').title(),sprite=key,health=hp,speed=speed,damage=dmg,behaviour=behaviour,aggro_range=420,shot_speed=250,shot_cooldown=2.7,expansion_only=True))
for key in ['dawnblade','stormscribe','pendulum_moth','tick_acorn','hourglass_hart']:
 for n,pose in enumerate(['idle','walk1','walk2','attack']):
  im=Image.new('RGBA',(48,48));d=ImageDraw.Draw(im);ink='#282e42';b=[0,1,-1,0][n];d.ellipse((7,41,42,46),fill='#20223055')
  if key=='dawnblade':
   d.polygon([(12,19),(30,19),(39,42),(10,42)],fill='#8c405a',outline=ink)
   d.rectangle((16,22+b,31,36+b),fill='#a8b7bf',outline=ink,width=2);d.line((18,25,28,30),fill='#e3ca8d',width=3)
   d.ellipse((15,5+b,32,24+b),fill='#d8b590',outline=ink);d.polygon([(15,11),(14,4),(25,1),(32,7),(30,12),(24,7)],fill='#624a43')
   d.rectangle((19,14+b,21,16+b),fill=ink);d.rectangle((27,14+b,29,16+b),fill=ink)
   d.rectangle((17,36,22,44),fill='#48566b');d.rectangle((27,36,32,44),fill='#48566b')
   d.line((37,40,39,10),fill='#d8e6df',width=4);d.line((33,31,43,31),fill='#d8b970',width=3)
   if pose=='attack':d.line((33,28,47,9),fill='#f8eac0',width=4)
  elif key=='stormscribe':
   d.polygon([(19,18),(30,18),(38,44),(9,44)],fill='#5b568d',outline=ink);d.line((24,23,24,41),fill='#c5ad78',width=3)
   d.ellipse((16,11+b,32,27+b),fill='#d0bb9b',outline=ink);d.polygon([(19,25),(31,25),(26,37)],fill='#c7d9dd')
   d.polygon([(12,15),(23,1),(29,9),(35,16)],fill='#716eaa',outline=ink);d.line((12,16,36,16),fill='#d1b57a',width=3)
   d.rectangle((19,19,21,21),fill=ink);d.rectangle((28,19,30,21),fill=ink)
   d.line((40,9,39,44),fill='#a38b6e',width=3);d.polygon([(40,1),(34,7),(40,14),(46,7)],fill='#a6d7f1',outline=ink)
   if pose=='attack':d.line((41,5,47,0),fill='#ecf7ff',width=3)
  elif key=='pendulum_moth':
   d.polygon([(22,23),(3,8+b),(4,31),(18,37)],fill='#958a67',outline=ink);d.polygon([(26,23),(45,8-b),(44,31),(30,37)],fill='#c0aa75',outline=ink)
   for x in [10,33]:d.ellipse((x,18,x+8,27),fill='#536678',outline='#d7c397')
   d.line((24,10,24,32),fill='#37435a',width=5);d.line((24,31,24,41),fill='#e0bb70',width=2);d.ellipse((20,39,28,46),fill='#cba867',outline=ink)
  elif key=='tick_acorn':
   d.ellipse((12,14+b,36,39+b),fill='#b08053',outline=ink,width=2);d.pieslice((9,5+b,39,27+b),180,360,fill='#6a7276',outline=ink,width=2)
   d.rectangle((21,1,26,8),fill='#d1a86b');d.rectangle((17,22,20,25),fill='#f5dfac');d.rectangle((28,22,31,25),fill='#f5dfac')
   d.line((15,35,7,43),fill='#919c9d',width=3);d.line((32,35,41,43),fill='#919c9d',width=3);d.line((13,27,4,19),fill='#c1ac7f',width=3);d.line((35,27,44,19),fill='#c1ac7f',width=3)
  else:
   d.ellipse((9,23,38,36),fill='#788b91',outline=ink,width=2)
   for x in [12,19,30,36]: d.line((x,32,x+(2 if n==1 else -2),45),fill='#c5aa74',width=3)
   d.line((32,29,32,16),fill='#97adb0',width=7);d.ellipse((26,11,42,24),fill='#b0c4c3',outline=ink);d.rectangle((36,15,38,17),fill=ink)
   for x,dx in [(28,-1),(36,1)]:
    d.line((x,13,x+dx*5,3),fill='#d6bc78',width=3);d.line((x+dx*3,7,x+dx*9,6),fill='#d6bc78',width=2)
   d.polygon([(18,24),(28,24),(25,29),(28,34),(18,34),(21,29)],fill='#eed89f',outline=ink);d.line((12,25,6,18),fill='#a7bfbd',width=2)
  im.save(R/f'assets/{key}_{pose}.png')
  if n<2:im.save(R/f'assets/{key}_{n}.png')
for key,col in [('clock_floor','#484b63'),('brass_path','#999074')]:
 im=Image.new('RGBA',(64,64),col);d=ImageDraw.Draw(im);rng=random.Random(key)
 for i in range(22):
  x,y=rng.randrange(64),rng.randrange(64);d.rectangle((x,y,x+2,y+1),fill='#bdbaab60')
 if key=='brass_path':d.line((0,0,64,0),fill='#c5b77d',width=2);d.line((0,32,64,32),fill='#736955');d.line((32,0,32,32),fill='#736955')
 im.save(R/f'assets/{key}.png')
for key in ['clock_tree','clock_arch']:
 im=Image.new('RGBA',(96,128));d=ImageDraw.Draw(im)
 if key=='clock_tree':
  d.line((47,116,47,33),fill='#867554',width=9);d.line((47,63,16,32),fill='#867554',width=6);d.line((47,63,79,27),fill='#867554',width=6)
  for x,y in [(15,19),(49,3),(72,29),(25,52)]:
   d.ellipse((x-13,y-12,x+17,y+18),fill='#786b6b',outline='#b6a477',width=3)
   for k in range(4):d.rectangle((x-3+(k%2)*14,y-4+(k//2)*14,x+1+(k%2)*14,y+(k//2)*14),fill='#d4c48e')
 else:
  d.line((12,122,12,44,47,13,84,44,84,122),fill='#8b907f',width=12);d.ellipse((25,0,71,45),fill='#d4c49a',outline='#595967',width=4);d.line((48,9,48,23,60,23),fill='#46516d',width=3)
 im.save(R/f'assets/{key}.png')
lines=['[gd_scene load_steps=3 format=3]','[ext_resource type="Texture2D" path="res://assets/clock_tree.png" id="tree"]','[ext_resource type="Texture2D" path="res://assets/clock_arch.png" id="arch"]','[node name="ClockworkOrchard" type="Node2D"]','[node name="Points" type="Node2D" parent="."]']
for name,x,y in [('Spawn',450,2100),('ReturnGate',300,2100),('Merchant',1100,2250),('Boss',6200,2100)]:lines += [f'[node name="{name}" type="Marker2D" parent="Points"]',f'position = Vector2({x},{y})']
lines += ['[node name="GroundPaint" type="Node2D" parent="."]']
for i,(x,y,w,h) in enumerate([(250,1840,6350,520),(1900,700,460,3000),(3900,700,460,3000),(5400,1500,1400,1300)]):lines += [f'[node name="Brass{i}" type="Polygon2D" parent="GroundPaint"]',f'polygon = PackedVector2Array({x},{y},{x+w},{y},{x+w},{y+h},{x},{y+h})','metadata/tile = "brass_path"']
lines+=['[node name="Enemies" type="Node2D" parent="."]']
for i in range(44):
 x=1100+(i%11)*460;y=900+(i//11)*820
 lines += [f'[node name="Enemy{i}" type="Marker2D" parent="Enemies"]',f'position = Vector2({x},{y})',f'metadata/enemy_id = "{"pendulum_moth" if i%3==0 else "tick_acorn"}"']
lines+=['[node name="Obstacles" type="Node2D" parent="."]']
for i in range(40):
 x=500+i%20*320;y=500 if i<20 else 3800
 lines += [f'[node name="Tree{i}" type="Sprite2D" parent="Obstacles"]',f'position = Vector2({x},{y})','texture = ExtResource("tree")','metadata/kind = "clock_tree"','metadata/radius = 35.0']
lines+=['[node name="Decorations" type="Node2D" parent="."]']
for i in range(6):lines += [f'[node name="Arch{i}" type="Sprite2D" parent="Decorations"]',f'position = Vector2({900+i*1000},1670)','texture = ExtResource("arch")','scale = Vector2(1.6,1.6)']
(R/'scenes/realms/clockwork_orchard.tscn').write_text('\n\n'.join(lines)+'\n')
data('regions','clockwork_orchard',dict(id='clockwork_orchard',name='The Clockwork Orchard',size=[7200,4200],terrain='clock_floor',scene='res://scenes/realms/clockwork_orchard.tscn',boss_sprite='hourglass_hart',boss_health=900,xp_per_level=4,boss_secondary='clockwork',expansion='clockwork'))
p=R/'content/manifest.json';m=json.loads(p.read_text())
for kind,keys in [('characters',['dawnblade','stormscribe']),('enemies',['pendulum_moth','tick_acorn','hourglass_hart']),('regions',['clockwork_orchard'])]:
 for key in keys:
  if key not in m[kind]:m[kind].append(key)
p.write_text(json.dumps(m,indent=2)+'\n')
print('Clockwork content generated')
