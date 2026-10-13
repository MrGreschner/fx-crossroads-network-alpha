"""Overhaul only the Oath nexus and final arena scenery; preserve trial nodes."""
from pathlib import Path
from PIL import Image,ImageDraw
import random,re,math
R=Path(__file__).resolve().parents[1]
for key in ['oath_ruined_arch','oath_memorial','oath_rubble','oath_banner','oath_roots','oath_crater']:
 im=Image.new('RGBA',(160,180));d=ImageDraw.Draw(im);ink='#313744';stone='#78808a';light='#a5a7a7'
 if key=='oath_ruined_arch':
  d.polygon([(15,171),(15,67),(28,36),(50,20),(69,14),(75,37),(54,47),(41,75),(41,171)],fill=stone,outline=ink)
  d.polygon([(118,171),(118,93),(107,71),(132,54),(145,81),(145,171)],fill=stone,outline=ink)
  d.polygon([(29,36),(50,20),(69,14),(75,37),(54,47)],fill=light,outline=ink)
  for y in [83,112,141]:d.line((17,y,40,y),fill=ink,width=3);d.line((120,y,144,y),fill=ink,width=3)
  d.line((26,48,30,81,22,99),fill=ink,width=2)
 elif key=='oath_memorial':
  d.rectangle((34,143,126,175),fill=stone,outline=ink,width=3);d.rectangle((45,126,114,148),fill=light,outline=ink)
  d.polygon([(52,126),(47,61),(59,38),(82,29),(100,44),(105,91),(92,125)],fill=stone,outline=ink)
  d.ellipse((62,8,95,41),fill=light,outline=ink);d.line((82,12,74,27,84,38),fill=ink,width=3);d.line((54,67,91,116),fill='#c2b38e',width=5)
  d.polygon([(105,60),(126,78),(118,88),(98,70)],fill=light,outline=ink)
 elif key=='oath_rubble':
  for x,y,w in [(5,120,44),(45,100,43),(90,128,54),(26,146,51),(90,154,35)]:d.polygon([(x,y+15),(x+8,y),(x+w-6,y+3),(x+w,y+23),(x+9,y+31)],fill=stone,outline=ink);d.line((x+8,y,x+w-6,y+3),fill=light,width=3)
 elif key=='oath_banner':
  d.line((47,15,47,174),fill='#927d68',width=6);d.polygon([(50,23),(124,30),(111,107),(91,94),(82,118),(67,100),(51,104)],fill='#756080',outline=ink)
  d.polygon([(74,41),(101,47),(100,69),(85,86),(73,68)],fill='#d0b985');d.line((84,50,91,67,82,74),fill='#756080',width=3)
 elif key=='oath_roots':
  for x in [10,42,85,135]:d.line((80,90,x,148,x+12,175),fill='#45574f',width=8);d.line((80,90,x,148,x+12,175),fill='#6f8270',width=3)
  d.line((80,94,70,48,87,19),fill='#526458',width=12);d.line((74,60,39,40,25,16),fill='#526458',width=7)
 else:
  d.ellipse((5,57,155,171),fill='#282e3d',outline='#686d7c',width=5);d.ellipse((23,79,137,153),fill='#17212f');d.arc((30,91,130,145),10,160,fill='#698092',width=3)
 im.save(R/f'assets/{key}.png')
im=Image.new('RGBA',(64,64),'#666979');d=ImageDraw.Draw(im)
for x,y in [(0,0),(32,0),(16,32),(48,32)]:d.rectangle((x,y,x+30,y+30),fill='#7c7d89',outline='#434a5d',width=2)
d.line((8,0,18,14,12,28,30,41,27,64),fill='#30394d',width=2);im.save(R/'assets/oath_broken_road.png')
p=R/'scenes/realms/shattered_oath.tscn';s=p.read_text();s=s.split('\n; V31 RUINS')[0]
keys=['oath_ruined_arch','oath_memorial','oath_rubble','oath_banner','oath_roots','oath_crater']
if 'id="ruin0"' not in s:
 s=s.replace('load_steps=9','load_steps=15');pos=s.index('[node name=')
 s=s[:pos]+''.join(f'[ext_resource type="Texture2D" path="res://assets/{k}.png" id="ruin{i}"]\n\n' for i,k in enumerate(keys))+s[pos:]
extra=['; V31 RUINS']
def sprite(name,x,y,asset,solid=False):
 extra.extend([f'[node name="{name}" type="Sprite2D" parent="{ "Obstacles" if solid else "Decorations"}"]',f'position = Vector2({x},{y})',f'texture = ExtResource("ruin{asset}")'])
 if solid:extra.extend(['metadata/kind = "rock"','metadata/radius = 36.0'])
# Broad radial routes remain clear. Fragmented paving makes each portal a destination.
for i,(x,y) in enumerate([(10360,2170),(11900,2170),(10360,2660),(11900,2660),(11130,3458)]):
 vx,vy=x-11130,y-2730;length=math.hypot(vx,vy);nx,ny=-vy/length*90,vx/length*90
 for n in range(5):
  a=(n+.05)/5;b=(n+.85)/5;ax,ay=11130+vx*a,2730+vy*a;bx,by=11130+vx*b,2730+vy*b
  extra.extend([f'[node name="RuinRoad{i}_{n}" type="Polygon2D" parent="GroundPaint"]',f'polygon = PackedVector2Array({ax+nx},{ay+ny},{bx+nx},{by+ny},{bx-nx},{by-ny},{ax-nx},{ay-ny})','metadata/tile = "oath_broken_road"'])
rng=random.Random(31)
for i in range(64):
 x=rng.randrange(9700,12700);y=rng.randrange(1730,3900)
 # Keep central welcome area, merchant, all portal pads and connecting spokes open.
 pads=[(11130,2730),(11130,2926),(10360,2170),(11900,2170),(10360,2660),(11900,2660),(11130,3458)]
 if any(math.hypot(x-a,y-b)<220 for a,b in pads):continue
 if abs(y-2730)<140 or abs(x-11130)<150:continue
 sprite(f'NexusRuin{i}',x,y,i%6)
for i,(x,y) in enumerate([(9820,1830),(12520,1830),(9820,3770),(12520,3770)]):sprite(f'SolidNexusRubble{i}',x,y,2,True)
for i in range(16):
 x=9760+i*190;sprite(f'ArenaFrieze{i}',x,4910,0 if i%4==0 else 3 if i%3==0 else 2);sprite(f'ArenaFriezeSouth{i}',x,7360,1 if i%5==0 else 4)
p.write_text(s+'\n\n'+'\n\n'.join(extra)+'\n')
p=R/'scripts/game.gd';s=p.read_text().replace('"garden_grass","river_grass"','"oath_broken_road","garden_grass","river_grass"');p.write_text(s)
