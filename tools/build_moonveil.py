from pathlib import Path
from PIL import Image,ImageDraw
import json,random
R=Path(__file__).resolve().parents[1]
def save(k,id,d):
 if k=='characters' and id=='elara':d.update({'secondary': {'name': 'Prism Unfurl', 'style': 'spiral_shards', 'damage': 14, 'cooldown': 6, 'duration': 2, 'radius': 250, 'color': '#c7ddf4', 'description': 'Three glass shards spiral outward from your casting spot for 2 seconds, reaching 250 units. Each shard can hit each enemy once for 14 damage; walls stop shards.'}, 'passive': 'Far Refraction: outward spirals reach 60 units farther.', 'passive_effect': 'far_refraction'})
 (R/f'content/{k}/{id}.json').write_text(json.dumps(d,indent=2)+'\n')
save('characters','elara',dict(id='elara',name='Elara',sprite='elara',run_cost=0,max_health=105,speed=240,lore='A human prism mage who guards Moonveil’s mirrors from the jealous Marquis.',primary=dict(name='Prism Lance',style='split_lance',damage=20,cooldown=.9,range=440,speed=410,split_distance=150,color='#b9dfff',description='Fire a 20-damage lance. After 150 units it splits into two diverging 13-damage bolts.'),secondary=dict(name='Glass Halo',style='orbit_shards',damage=12,cooldown=6,duration=2.4,radius=100,description='Three glass shards orbit you. Each can hit each enemy once for 12 damage.'),special=dict(name='Moonlit Procession',style='ground_sequence',damage=22,cooldown=15,count=5,spacing=90,interval=.2,radius=75,slow_duration=2,color='#c5b2f4',description='Five moonlight blooms advance along your aim, each dealing 22 damage and slowing enemies for 2 seconds.'),passive='Patient Refraction: Glass Halo remains for one extra second.',passive_effect='long_orbit'))
for key,hp,speed,damage,custom,beh in [('mask_duelist',85,105,12,'','chase'),('prism_acolyte',80,72,11,'prism_fan','ranged'),('mirror_marquis',1200,130,19,'masquerade','chase')]:
 save('enemies',key,dict(id=key,name=key.replace('_',' ').title(),sprite=key,health=hp,speed=speed,damage=damage,behaviour=beh,custom_attack=custom,aggro_range=600,shot_cooldown=3.2,shot_speed=260,expansion_only=True))
for key in ['elara','mask_duelist','prism_acolyte','mirror_marquis']:
 for n,pose in enumerate(['idle','walk1','walk2','attack']):
  im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);ink='#33344c';b=[0,1,-1,0][n];col='#628caf' if key=='elara' else '#93659f' if key=='prism_acolyte' else '#586a87' if key=='mask_duelist' else '#9c647e'
  if key=='elara':
   d.polygon([(18,10+b),(15,23+b),(14,43+b),(18,49+b),(24,42+b),(22,16+b)],fill='#d3c18a',outline=ink)
   d.polygon([(41,9+b),(47,18+b),(49,39+b),(46,49+b),(40,44+b),(40,16+b)],fill='#d3c18a',outline=ink)
   d.line((18,22+b,17,42+b),fill='#f0dfab',width=2);d.line((45,23+b,46,41+b),fill='#f0dfab',width=2)
  d.polygon([(20,28+b),(43,28+b),(51,53),(12,53)],fill=col,outline=ink);d.rectangle((21,49,27,60-n%2),fill=ink);d.rectangle((37,49,43,60+n%2),fill=ink)
  d.ellipse((19,7+b,44,33+b),fill='#dbc9b0' if key=='elara' else '#d9dde6',outline=ink)
  if key=='elara':
   d.polygon([(17,18+b),(13,31+b),(12,47+b),(17,53+b),(21,47+b),(20,27+b)],fill='#d3c18a',outline=ink)
   d.polygon([(44,17+b),(48,27+b),(52,44+b),(48,53+b),(43,47+b),(42,30+b)],fill='#d3c18a',outline=ink)
   d.line((16,28+b,15,45+b),fill='#f0dfab',width=2);d.line((46,29+b,48,44+b),fill='#f0dfab',width=2)
   d.polygon([(17,21),(16,9),(28,1),(42,5),(47,22),(41,17),(39,8),(23,10),(21,23)],fill='#d3c18a',outline=ink);d.line((26,37,40,43),fill='#c5dff3',width=3)
  else:
   d.polygon([(20,8),(17,0),(29,6),(35,0),(44,8)],fill='#d1b877',outline=ink);d.line((22,17,42,17),fill=col,width=4)
  for x in [25,36]:d.rectangle((x,18+b,x+2,21+b),fill=ink)
  d.line((50,17,50,55),fill='#b2a787',width=3);d.polygon([(50,4),(56,13),(50,22),(44,13)],fill='#bde5f8',outline=ink)
  if key=='mask_duelist':d.line((8,48,16,18),fill='#e6e4db',width=3)
  if pose=='attack':d.arc((39,0,63,30),0,320,fill='#decbfa',width=2)
  im.save(R/f'assets/{key}_{pose}.png')
  if n<2:im.save(R/f'assets/{key}_{n}.png')
for key in ['moonveil_court','moonveil_canal']:
 im=Image.new('RGBA',(64,64),'#52627c' if key.endswith('court') else '#2b4969');d=ImageDraw.Draw(im)
 if key.endswith('court'):
  for y in [0,32]:
   for x in [0,32]:d.rectangle((x+1,y+1,x+30,y+30),outline='#8292a7',width=2)
  d.polygon([(32,18),(45,32),(32,46),(19,32)],outline='#a79cc0')
 else:
  for y in [8,25,48]:d.line((4,y,51,y),fill='#669cbb',width=2)
 im.save(R/f'assets/{key}.png')
for key in ['moonveil_arch','moonveil_lantern','moonveil_mirror']:
 im=Image.new('RGBA',(128,160));d=ImageDraw.Draw(im);ink='#353b56'
 if key=='moonveil_arch':
  d.polygon([(7,154),(7,58),(20,26),(48,9),(82,9),(108,26),(120,58),(120,154),(97,154),(97,61),(87,38),(64,30),(41,38),(30,61),(30,154)],fill='#8996ac',outline=ink)
  for y in [75,110,145]:d.line((9,y,28,y),fill=ink,width=2);d.line((99,y,118,y),fill=ink,width=2)
 elif key=='moonveil_lantern':
  d.line((64,47,64,157),fill='#9d9caf',width=5);d.polygon([(43,27),(64,10),(85,27),(81,50),(64,64),(47,50)],fill='#b5dcec',outline=ink);d.ellipse((56,24,73,49),fill='#e4edfa')
 else:
  d.ellipse((19,7,108,130),fill='#a59bbb',outline=ink,width=4);d.ellipse((29,18,98,118),fill='#526b8d');d.line((41,40,76,21),fill='#badfe9',width=4);d.line((39,72,85,46),fill='#a0bbd6',width=3);d.rectangle((27,130,99,153),fill='#929bab',outline=ink)
 im.save(R/f'assets/{key}.png')
keys=['moonveil_arch','moonveil_lantern','moonveil_mirror','glass_pavilion','flower_bed','garden_fountain']
lines=['[gd_scene load_steps=7 format=3]']+[f'[ext_resource type="Texture2D" path="res://assets/{k}.png" id="a{i}"]' for i,k in enumerate(keys)]
lines+=['[node name="Moonveil" type="Node2D"]','[node name="Points" type="Node2D" parent="."]']
for name,x,y in [('Spawn',350,1800),('ReturnGate',180,1800),('Merchant',3300,1800),('Boss',6950,1800)]:lines += [f'[node name="{name}" type="Marker2D" parent="Points"]',f'position = Vector2({x},{y})']
lines+=['[node name="GroundPaint" type="Node2D" parent="."]']
for i,(x,y,w,h) in enumerate([(0,300,7600,200),(0,3100,7600,200),(0,1100,6000,120),(0,2400,6000,120)]):lines += [f'[node name="Canal{i}" type="Polygon2D" parent="GroundPaint"]',f'polygon = PackedVector2Array({x},{y},{x+w},{y},{x+w},{y+h},{x},{y+h})','metadata/tile = "moonveil_canal"']
lines+=['[node name="Obstacles" type="Node2D" parent="."]']
for i in range(16):
 x=1000+(i//2)*650;y=800 if i%2==0 else 2780
 lines += [f'[node name="Mirror{i}" type="Sprite2D" parent="Obstacles"]',f'position = Vector2({x},{y})','texture = ExtResource("a2")','metadata/kind = "rock"','metadata/radius = 38.0']
lines+=['[node name="Decorations" type="Node2D" parent="."]']
for i in range(100):
 x=250+(i//2)*145;y=620 if i%2==0 else 2960;a=3 if i%10==0 else 0 if i%6==0 else 4 if i%3==0 else 1
 lines += [f'[node name="Festival{i}" type="Sprite2D" parent="Decorations"]',f'position = Vector2({x},{y})',f'texture = ExtResource("a{a}")']
lines+=['[node name="Enemies" type="Node2D" parent="."]']
for i in range(36):
 x=1100+(i//6)*850;y=1300+(i%6)*190
 lines += [f'[node name="Enemy{i}" type="Marker2D" parent="Enemies"]',f'position = Vector2({x},{y})',f'metadata/enemy_id = "{"prism_acolyte" if i%3==0 else "mask_duelist"}"']
(R/'scenes/realms/moonveil.tscn').write_text('\n\n'.join(lines)+'\n')
save('regions','moonveil',dict(id='moonveil',name='Moonveil Masquerade',size=[7600,3600],terrain='moonveil_court',scene='res://scenes/realms/moonveil.tscn',boss_sprite='mirror_marquis',boss_enemy='mirror_marquis',boss_health=1200,xp_per_level=4,unlock_cost=0,difficulty_label='Medium — moving mirrors and split lances',description='A moonlit festival city with silver canals, glass gardens and mirror courts. The Mirror Marquis circles and dashes while prism lances split in flight.'))
p=R/'content/manifest.json';m=json.loads(p.read_text())
for kind,ids in [('characters',['elara']),('enemies',['mask_duelist','prism_acolyte','mirror_marquis'])]:
 for id in ids:
  if id not in m[kind]:m[kind].append(id)
if 'moonveil' in m['regions']:m['regions'].remove('moonveil')
m['regions'].insert(m['regions'].index('silverfall')+1,'moonveil');p.write_text(json.dumps(m,indent=2)+'\n')
