"""Editable content and original pixel sprites for the Crossroads expansion."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,random,math,wave,struct
R=Path(__file__).resolve().parents[1]
def data(kind,key,value):
 if kind=='enemies' and key=='wick_wisp': value.update({'health': 78, 'damage': 12, 'behaviour': 'chase', 'custom_attack': 'lob', 'lob_speed': 300, 'blast_radius': 75, 'skill_cooldown': 3.8, 'attack_color': '#ffbb76'})
 (R/f'content/{kind}/{key}.json').write_text(json.dumps(value,indent=2)+'\n')
heroes={
 'soccer':dict(id='soccer',name='Crosswind Striker',sprite='soccer',max_health=105,speed=250,run_cost=0,primary=dict(name='Driven Shot',style='projectile',damage=21,cooldown=.7,range=420,speed=610,color='#e8f3ed'),secondary=dict(name='Slide Tackle',style='charge',damage=30,cooldown=3.8,range=190,speed=600,color='#a0efd3'),special=dict(name='Team Huddle',style='heal_zone',damage=0,cooldown=15,duration=5,radius=125,heal_per_tick=6,color='#91efad'),passive='Second Wind: primary cooldown is 20% shorter.',passive_effect='quick_primary'),
 'welder':dict(id='welder',name='Emberwright',sprite='welder',max_health=125,speed=210,run_cost=0,primary=dict(name='Forging Hammer',style='melee',damage=28,cooldown=.8,range=78,arc_degrees=80,visual='swing',color='#ffc575'),secondary=dict(name='Torch Sweep',style='flame',damage=8,cooldown=4.5,range=150,arc_degrees=55,duration=.9,tick=.18,color='#ff9d45'),special=dict(name='Quench Shield',style='block',damage=0,cooldown=12,duration=2.2,reduction=.65,color='#98d9e8'),passive='Tempered Plate: take 10% less damage.',passive_effect='guard')}
for key,value in heroes.items():data('characters',key,value)
# Each enemy has its own silhouette, not recoloured copies.
entities={
 'oath_shade':('#a794df','shade'), 'thorn_sentinel':('#84a74d','thorn'), 'cinder_salamander':('#e89047','lizard'),
 'mirror_moth':('#c2e9f5','moth'), 'storm_rook':('#83a9f0','rook'),
 'briar_matron':('#71904c','matron'), 'kiln_knight':('#e7a261','knight'), 'mirror_oracle':('#b5cbea','oracle'), 'storm_archon':('#929be5','archon'), 'gilded_usurper':('#d8b359','thief'),
 'lantern_crab':('#7cd0bc','crab'), 'reed_stalker':('#739752','reed'), 'wick_wisp':('#edc16c','wisp'), 'bellroot':('#bdb67d','root')}
for key in [*heroes,*entities]:
 for n,pose in enumerate(['idle','walk1','walk2','attack']):
  im=Image.new('RGBA',(48,48));d=ImageDraw.Draw(im);b=1 if n==1 else -1 if n==2 else 0
  ink='#202b3d';d.ellipse((8,41,41,46),fill='#101d2350')
  if key=='soccer':
   d.ellipse((8,8+b,40,40+b),fill='#e5eae2',outline=ink,width=2)
   for x,y in [(24,15+b),(15,27+b),(32,28+b)]:d.polygon([(x,y-4),(x+5,y-1),(x+3,y+4),(x-3,y+4),(x-5,y-1)],fill=ink)
   d.rectangle((16,22+b,18,24+b),fill='#7adbd2');d.rectangle((29,22+b,31,24+b),fill='#7adbd2')
   d.line((7,30+b,3,23+b),fill='#397c75',width=4);d.line((39,30+b,44,23+b),fill='#397c75',width=4)
   d.line((17,39,13 if n==2 else 18,44),fill=ink,width=4);d.line((32,39,39 if pose=='attack' else 33,44),fill=ink,width=4)
   d.rectangle((8,43,18,46),fill='#579791');d.rectangle((32,43,44,46),fill='#579791')
  elif key=='welder':
   d.rectangle((13,19+b,33,37+b),fill='#586270',outline=ink,width=2);d.rectangle((17,22+b,30,35+b),fill='#ae7950')
   d.rectangle((12,5+b,33,21+b),fill='#2c394c',outline=ink,width=2);d.rectangle((15,10+b,30,15+b),fill='#8cc4c8');d.line((16,11+b,28,11+b),fill='#d0e9d3')
   d.rectangle((15,36,22,44),fill='#384557');d.rectangle((26,36,33,44),fill='#384557');d.rectangle((13,43,23,46),fill=ink);d.rectangle((25,43,36,46),fill=ink)
   d.rectangle((7,22+b,13,30+b),fill='#deb15e');d.rectangle((33,22+b,39,30+b),fill='#deb15e');d.rectangle((4,12,8,28),fill='#9ba9ac');d.rectangle((0,10,13,16),fill='#b0bac1')
   d.line((37,27+b,43,23 if pose=='attack' else 31),fill='#dfbf75',width=3)
   if pose=='attack':d.polygon([(42,23),(47,16),(47,27)],fill='#ffb75b');d.point((47,20),fill='#f6ecbd')
  else:
   c,shape=entities[key]
   if shape=='shade':
    d.polygon([(24,5),(35,16),(39,43),(26,38),(13,44),(12,17)],fill=c,outline=ink);d.rectangle((19,16,30,23),fill=ink);d.rectangle((21,18,23,19),fill='#efce7f');d.rectangle((27,18,29,19),fill='#efce7f')
   elif shape=='thorn':
    d.rectangle((17,16,31,38),fill='#615342');d.polygon([(9,8),(22,12),(26,3),(29,15),(40,8),(35,29),(30,43),(20,38),(11,28)],fill=c,outline=ink);d.rectangle((18,21,29,24),fill=ink);d.point((21,22),fill='#f5d579');d.point((27,22),fill='#f5d579')
   elif shape=='lizard':
    d.polygon([(4,34),(13,30),(15,21),(27,18),(33,24),(44,22),(43,33),(31,36),(22,41),(12,38)],fill=c,outline=ink);d.ellipse((31,17,45,30),fill=c,outline=ink);d.rectangle((38,21,40,23),fill=ink);d.line((15,37,12,44),fill=c,width=4);d.line((28,37,31,44),fill=c,width=4);d.polygon([(17,22),(19,11),(24,21)],fill='#db603d')
   elif shape=='moth':
    d.polygon([(23,23),(4,8+b),(2,26),(17,39),(24,30)],fill=c,outline=ink);d.polygon([(25,23),(44,8-b),(46,26),(31,39),(24,30)],fill=c,outline=ink);d.line((24,14,24,35),fill='#506486',width=5);d.ellipse((8,16,15,24),fill='#538bb9');d.ellipse((34,16,41,24),fill='#538bb9');d.line((22,16,18,7),fill=ink,width=2);d.line((26,16,30,7),fill=ink,width=2)
   elif shape=='rook':
    d.rectangle((15,17,32,37),fill=c,outline=ink);d.rectangle((11,5,16,15),fill=c);d.rectangle((21,5,26,15),fill=c);d.rectangle((31,5,36,15),fill=c);d.rectangle((11,13,36,20),fill=c,outline=ink);d.rectangle((11,36,36,43),fill='#5665a4');d.polygon([(24,21),(19,30),(25,28),(21,35),(30,25),(24,27)],fill='#faf0b8')
   elif shape=='matron':
    d.polygon([(24,5),(12,15),(8,42),(19,39),(24,45),(30,39),(40,42),(35,15)],fill=c,outline=ink);d.ellipse((16,11,31,26),fill='#c9b991');d.line((13,16,5,4),fill='#634e39',width=3);d.line((33,16,43,5),fill='#634e39',width=3);d.ellipse((4,3,10,9),fill='#b98bba');d.ellipse((38,3,45,10),fill='#b98bba');d.rectangle((20,17,22,19),fill=ink);d.rectangle((27,17,29,19),fill=ink)
   elif shape=='knight':
    d.rectangle((12,18,35,39),fill='#735344',outline=ink,width=2);d.rectangle((15,4,32,19),fill=c,outline=ink);d.rectangle((18,11,31,14),fill='#2e2d3b');d.rectangle((8,21,16,39),fill=c);d.line((37,12,38,41),fill='#b7b7a2',width=4);d.polygon([(34,9),(41,2),(44,13)],fill='#e9753d');d.rectangle((16,38,21,45),fill=c);d.rectangle((27,38,33,45),fill=c)
   elif shape=='oracle':
    d.polygon([(24,3),(15,16),(12,42),(36,42),(33,16)],fill=c,outline=ink);d.ellipse((17,11,31,25),fill='#7280a2');d.rectangle((20,17,29,20),fill='#dff6ff');d.line((8,12,7,43),fill='#8baac4',width=3);d.polygon([(7,3),(1,10),(7,17),(13,10)],fill='#e0fafb');d.polygon([(35,22),(46,16),(44,35),(36,39)],fill='#d3e6f0',outline='#68829b')
   elif shape=='archon':
    d.polygon([(23,4),(8,15),(14,32),(7,43),(25,39),(41,43),(35,31),(40,15)],fill=c,outline=ink);d.ellipse((17,9,30,24),fill='#38456b');d.rectangle((19,15,28,18),fill='#ecf0d3');d.polygon([(3,13),(12,18),(6,28),(11,27),(4,40),(5,28),(1,29)],fill='#e6e6bd');d.polygon([(44,13),(35,18),(41,28),(36,27),(43,40)],fill='#e6e6bd')
   elif shape=='thief':
    d.polygon([(24,3),(11,14),(8,39),(20,44),(36,40),(39,14)],fill='#423553',outline=ink);d.rectangle((17,15,31,25),fill='#c3a377');d.rectangle((16,14,32,19),fill=ink);d.rectangle((19,17,22,18),fill=c);d.rectangle((27,17,30,18),fill=c);d.polygon([(12,13),(14,3),(19,8),(24,2),(29,8),(35,3),(34,13)],fill=c);d.rectangle((16,30,33,33),fill=c);d.ellipse((2,24,15,39),fill='#a78847',outline=ink);d.line((38,23,44,37),fill='#dad7bb',width=3)
   elif shape=='crab':
    for x,y in [(5,30),(6,39),(42,30),(41,39)]:d.line((24,30,x,y),fill=c,width=3)
    d.ellipse((10,19,37,38),fill='#476967',outline=ink);d.line((13,24,5,18),fill=c,width=4);d.line((34,24,43,18),fill=c,width=4);d.ellipse((0,10,12,22),fill=c,outline=ink);d.ellipse((36,10,47,22),fill=c,outline=ink);d.rectangle((20,6,28,23),fill='#a7e4be',outline=ink);d.rectangle((22,9,26,19),fill='#f4de93')
   elif shape=='reed':
    d.line((24,42,22,11),fill='#657d4c',width=7);d.line((21,26,8,14),fill=c,width=4);d.line((26,29,40,11),fill=c,width=4);d.ellipse((16,4,28,18),fill='#705940');d.rectangle((18,9,26,11),fill='#e9ce76');d.line((21,37,13,45),fill=c,width=4);d.line((27,36,35,45),fill=c,width=4)
   elif shape=='wisp':
    d.polygon([(24,2),(19,14),(8,20),(16,36),(24,44),(32,36),(40,20),(29,14)],fill='#75638c',outline=ink);d.ellipse((15,15+b,34,36+b),fill=c);d.ellipse((20,18+b,29,29+b),fill='#fff3bb');d.rectangle((18,28+b,20,30+b),fill=ink);d.rectangle((28,28+b,30,30+b),fill=ink)
   elif shape=='root':
    d.polygon([(24,3),(10,16),(13,29),(3,44),(17,40),(24,46),(31,40),(45,44),(35,29),(38,16)],fill='#655c4b',outline=ink);d.polygon([(14,11),(34,11),(37,30),(11,30)],fill=c,outline=ink);d.rectangle((15,16,33,18),fill='#666147');d.rectangle((18,23,29,26),fill='#f1d993');d.line((11,19,3,9),fill='#70835a',width=4);d.line((36,19,43,6),fill='#70835a',width=4)
  im.save(R/f'assets/{key}_{pose}.png')
  if n<2:im.save(R/f'assets/{key}_{n}.png')
for key,(colour,shape) in entities.items():
 boss=key in ['briar_matron','kiln_knight','mirror_oracle','storm_archon','gilded_usurper','bellroot']
 behaviour='ranged' if shape in ['moth','rook','wisp'] else 'chase'
 data('enemies',key,dict(id=key,name=key.replace('_',' ').title(),sprite=key,health=65 if not boss else 500,speed=80 if shape not in ['shade','lizard'] else 110,damage=8 if not boss else 16,behaviour=behaviour,aggro_range=420,shot_speed=230,shot_cooldown=2.6,expansion_only=True))
# Original terrain tiles and environmental props.
for key,col in {'oath_void':'#101725','oath_stone':'#313346','briar_floor':'#354638','cinder_floor':'#5c3d3a','mirror_floor':'#45556a','storm_floor':'#414766','marsh_floor':'#263f43'}.items():
 im=Image.new('RGBA',(64,64),col);d=ImageDraw.Draw(im);rng=random.Random(key)
 for i in range(28):
  x,y=rng.randrange(64),rng.randrange(64);d.rectangle((x,y,x+2,y+1),fill='#657b7860')
 if key in ['oath_stone','mirror_floor','storm_floor']:
  d.line((0,32,64,32),fill='#222e3c');d.line((32,0,32,32),fill='#222e3c');d.line((16,32,16,64),fill='#222e3c')
 im.save(R/f'assets/{key}.png')
for key in ['oath_pillar','marsh_reeds','lantern_tree','creator_board','realm_banner']:
 im=Image.new('RGBA',(64,96));d=ImageDraw.Draw(im)
 if key=='oath_pillar':
  d.rectangle((18,16,46,78),fill='#6d7085',outline='#343546',width=3);d.rectangle((12,8,52,21),fill='#898a9e');d.rectangle((12,75,52,90),fill='#565f75');d.polygon([(32,27),(25,43),(32,57),(40,43)],fill='#a3b4c9')
 elif key=='marsh_reeds':
  for x,y in [(10,20),(24,6),(42,14),(54,28)]:d.line((32,88,x,y+20),fill='#68875c',width=4);d.rectangle((x-3,y,x+3,y+25),fill='#9c8657')
 elif key=='lantern_tree':
  d.rectangle((27,29,36,87),fill='#62533f');d.line((30,52,7,24),fill='#62533f',width=6);d.line((32,44,52,18),fill='#62533f',width=6);d.ellipse((2,0,58,45),fill='#38594f');d.rectangle((6,30,17,48),fill='#bbbc75');d.rectangle((9,33,14,44),fill='#f6e5a0');d.rectangle((47,23,57,41),fill='#bbbc75');d.rectangle((50,26,54,37),fill='#f6e5a0')
 elif key=='creator_board':
  d.rectangle((11,15,54,58),fill='#a58a61',outline='#493e37',width=3);d.rectangle((15,21,49,51),fill='#dfd3aa');d.rectangle((16,59,22,91),fill='#745c42');d.rectangle((43,59,49,91),fill='#745c42');d.line((20,29,44,29),fill='#536a78',width=3);d.line((20,38,40,38),fill='#536a78',width=3)
 else:
  d.line((18,4,18,90),fill='#a39373',width=4);d.polygon([(20,10),(54,10),(54,62),(37,52),(20,62)],fill='#4d6688');d.polygon([(37,20),(29,34),(37,44),(45,34)],fill='#e6ca81')
 im.save(R/f'assets/{key}.png')
# Code-native short audio cues: no external recordings/assets required.
(R/'assets/audio').mkdir(exist_ok=True)
for key,hz,length in [('swing',220,.09),('shot',650,.07),('flame',110,.18),('hit',150,.075),('hurt',90,.12),('reward',880,.18)]:
 rng=random.Random(key);samples=[]
 for i in range(int(22050*length)):
  t=i/22050;fade=(1-t/length)**2;noise=rng.uniform(-1,1)*(.7 if key in ['flame','hit'] else .08)
  val=.22*fade*(math.sin(2*math.pi*(hz*t-150*t*t))+noise);samples.append(struct.pack('<h',int(max(-1,min(1,val))*32767)))
 with wave.open(str(R/f'assets/audio/{key}.wav'),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(22050);w.writeframes(b''.join(samples))

for key in ['briar_arch','kiln_forge','mirror_shard_env','storm_coil']:
 im=Image.new('RGBA',(64,96));d=ImageDraw.Draw(im)
 if key=='briar_arch':
  d.line((10,88,10,30,31,10,52,30,52,88),fill='#66513a',width=9)
  for x,y in [(6,31),(49,37),(13,17),(36,12),(3,55),(52,65)]:d.ellipse((x,y,x+14,y+13),fill='#637b43');d.polygon([(x+4,y+5),(x+12,y-4),(x+10,y+8)],fill='#ab8cb4')
 elif key=='kiln_forge':
  d.rectangle((11,8,52,84),fill='#4e4146',outline='#292636',width=4);d.rectangle((21,34,43,72),fill='#f2813c');d.polygon([(22,72),(24,43),(30,57),(36,39),(42,72)],fill='#f2ce68');d.rectangle((7,79,58,91),fill='#73665b');d.rectangle((19,0,43,10),fill='#928371')
 elif key=='mirror_shard_env':
  d.polygon([(31,3),(48,27),(45,71),(32,91),(15,71),(12,27)],fill='#7198b4',outline='#344d68');d.polygon([(31,10),(41,29),(39,69),(31,81),(23,69),(20,29)],fill='#c3e5f0');d.line((22,64,40,28),fill='#f3fbec',width=4)
 else:
  d.rectangle((18,64,48,85),fill='#4c5978');d.rectangle((25,19,40,73),fill='#768aa9');d.ellipse((10,8,53,33),fill='#4d5e87',outline='#a4bce1',width=3);d.ellipse((11,35,54,54),fill='#4d5e87',outline='#a4bce1',width=3);d.polygon([(32,0),(26,17),(33,14),(28,31),(41,10),(34,12)],fill='#f2e6a0')
 im.save(R/'assets'/f'{key}.png')

def scene(key,size,spawn,boss,enemies,patches,props):
 resources={'tree':'tree.png','oath_pillar':'oath_pillar.png','marsh_reeds':'marsh_reeds.png','lantern_tree':'lantern_tree.png',**{k:k+'.png' for k in ['briar_arch','kiln_forge','mirror_shard_env','storm_coil']}}
 lines=[f'[gd_scene load_steps={len(resources)+1} format=3]']
 for i,(name,file) in enumerate(resources.items()):lines += [f'[ext_resource type="Texture2D" path="res://assets/{file}" id="{name}"]']
 lines += [f'[node name="{key.title()}" type="Node2D"]','[node name="Points" type="Node2D" parent="."]']
 for name,pos in [('Spawn',spawn),('ReturnGate',(spawn[0]-110,spawn[1])),('Merchant',(spawn[0],spawn[1]+140)),('Boss',boss)]:lines += [f'[node name="{name}" type="Marker2D" parent="Points"]',f'position = Vector2({pos[0]},{pos[1]})']
 lines += ['[node name="Enemies" type="Node2D" parent="."]']
 for i,(enemy,x,y) in enumerate(enemies):lines += [f'[node name="Enemy{i}" type="Marker2D" parent="Enemies"]',f'position = Vector2({x},{y})',f'metadata/enemy_id = "{enemy}"']
 lines += ['[node name="GroundPaint" type="Node2D" parent="."]']
 for i,(x,y,w,h,tile) in enumerate(patches):lines += [f'[node name="Ground{i}" type="Polygon2D" parent="GroundPaint"]',f'polygon = PackedVector2Array({x},{y},{x+w},{y},{x+w},{y+h},{x},{y+h})',f'metadata/tile = "{tile}"']
 lines += ['[node name="Obstacles" type="Node2D" parent="."]']
 for i,(kind,x,y) in enumerate(props):lines += [f'[node name="Prop{i}" type="Sprite2D" parent="Obstacles"]',f'position = Vector2({x},{y})',f'texture = ExtResource("{kind}")',f'metadata/kind = "{kind}"',f'metadata/radius = {24 if kind=="marsh_reeds" else 38}.0']
 lines += ['[node name="Decorations" type="Node2D" parent="."]']
 (R/f'scenes/realms/{key}.tscn').write_text('\n\n'.join(lines)+'\n')
trials=[dict(name='Briar Reliquary',origin=[300,300],tile='briar_floor',enemy='thorn_sentinel',boss='briar_matron',attack='roots'),dict(name='Cinder Causeway',origin=[3100,300],tile='cinder_floor',enemy='cinder_salamander',boss='kiln_knight',attack='charge'),dict(name='Mirrorfrost Gallery',origin=[300,3100],tile='mirror_floor',enemy='mirror_moth',boss='mirror_oracle',attack='mirrors'),dict(name='Stormglass Spire',origin=[3100,3100],tile='storm_floor',enemy='storm_rook',boss='storm_archon',attack='beam')]
patches=[(t['origin'][0],t['origin'][1],2000,2000,t['tile']) for t in trials]+[(6800,1100,2400,1800,'oath_stone'),(6800,3400,2400,2000,'oath_stone')]
props=[]
for n,t in enumerate(trials):
 x,y=t['origin']
 for dx,dy in [(120,120),(480,220),(1450,220),(1870,120),(120,1880),(450,1770),(1450,1790),(1870,1880)]:props.append((['briar_arch','kiln_forge','mirror_shard_env','storm_coil'][n],x+dx,y+dy))
scene('shattered_oath',(10000,5800),(7950,1950),(8100,4400),[],patches,props)
data('regions','shattered_oath',dict(id='shattered_oath',name='The Shattered Oath',size=[10000,5800],terrain='oath_void',scene='res://scenes/realms/shattered_oath.tscn',boss_health=600,xp_per_level=4,expansion='four_trials',trials=trials))
rng=random.Random(2026);enemies=[];props=[]
for i in range(42):
 x=1000+i%14*460;y=450+i//14*650+rng.randrange(-110,111);enemies.append((['lantern_crab','reed_stalker','wick_wisp'][i%3],x,y))
for i in range(115):
 x=rng.randrange(300,7800);y=rng.choice([150,250,2400,2550])+rng.randrange(-50,51)
 props.append(('lantern_tree' if i%3==0 else 'marsh_reeds',x,y))
scene('lantern_marsh',(8400,2800),(400,1400),(7700,1400),enemies,[(350,1120,7650,560,'path'),(2300,450,650,450,'mirror_floor'),(4900,1750,950,480,'briar_floor')],props)
data('regions','lantern_marsh',dict(id='lantern_marsh',name='The Lantern Marsh',size=[8400,2800],terrain='marsh_floor',scene='res://scenes/realms/lantern_marsh.tscn',boss_sprite='bellroot',boss_health=850,xp_per_level=4,boss_secondary='sporeburst',expansion='marsh'))
if not (R/'content/creators.json').exists():data('','creators',{'heading':'Built at St. FX','entries':[{'name':'Design students','contribution':'Character art, realm banners and environments'},{'name':'Computer Science students','contribution':'Heroes, enemies, items and new mechanics'},{'name':'Academy and shop programs','contribution':'Inspiration for the Crossroads heroes'}]})
m=json.loads((R/'content/manifest.json').read_text())
for key in heroes:
 if key not in m['characters']:m['characters'].append(key)
for key in entities:
 if key not in m['enemies']:m['enemies'].append(key)
for key in ['lantern_marsh','shattered_oath']:
 if key not in m['regions']:m['regions'].append(key)
(R/'content/manifest.json').write_text(json.dumps(m,indent=2)+'\n')
print('Expansion content generated')
