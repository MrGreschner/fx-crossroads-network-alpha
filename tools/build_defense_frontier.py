from pathlib import Path
import re,random,math
R=Path(__file__).resolve().parents[1];p=R/'scenes/realms/defense_world.tscn';s=p.read_text().split('\n; V32 FRONTIER')[0]
keys=['garden_fountain','house','oath_ruined_arch','oath_banner','flower_bed','river_willow']
if 'id="front0"' not in s:
 s=s.replace('[gd_scene format=3]','[gd_scene load_steps=7 format=3]\n\n'+ '\n\n'.join(f'[ext_resource type="Texture2D" path="res://assets/{k}.png" id="front{i}"]' for i,k in enumerate(keys)))
# Clear the refuge and its branch from the northern road.
blocks=re.split(r'(?=\[node name=)',s);kept=[]
for b in blocks:
 if 'parent="Obstacles"' in b:
  m=re.search(r'position = Vector2\(([-\d.]+),\s*([-\d.]+)\)',b)
  if m:
   x,y=map(float,m.groups())
   if math.hypot(x-6400,y-7300)<330 or (6350<x<8100 and abs(y-7300)<135):continue
 kept.append(b)
s=''.join(kept);extra=['; V32 FRONTIER','[node name="Decorations" type="Node2D" parent="."]','[node name="Fountains" type="Node2D" parent="."]','[node name="PilgrimsSpring" type="Marker2D" parent="Fountains"]','position = Vector2(6400,7300)']
extra+=['[node name="SpringTrail" type="Polygon2D" parent="GroundPaint"]','polygon = PackedVector2Array(6270,7200,8050,7200,8050,7400,6270,7400)','metadata/tile = "path"']
extra+=['[node name="SpringClearing" type="Polygon2D" parent="GroundPaint"]','polygon = PackedVector2Array(6100,7000,6700,7000,6700,7600,6100,7600)','metadata/tile = "path"']
def prop(i,x,y,a,scale=1):extra.extend([f'[node name="Frontier{i}" type="Sprite2D" parent="Decorations"]',f'position = Vector2({x},{y})',f'texture = ExtResource("front{a}")',f'scale = Vector2({scale},{scale})'])
prop('Spring',6400,7230,0,1.5)
for i,(x,y) in enumerate([(6180,7070),(6620,7080),(6180,7540),(6620,7540)]):prop('Garden'+str(i),x,y,4);prop('Willow'+str(i),x-100,y,5)
# Distinct settlements and relic sites beside, rather than across, enemy routes.
for n,(x,y) in enumerate([(7200,4800),(8800,6500),(3900,8800),(12100,8800),(5200,10300),(10800,10300)]):
 for i,(dx,dy,a) in enumerate([(-160,-80,1),(160,-80,1),(0,180,4),(-210,160,3),(210,160,3)]):prop(f'Camp{n}_{i}',x+dx,y+dy,a,1.25 if a==1 else 1)
 extra.extend([f'[node name="CampGround{n}" type="Polygon2D" parent="GroundPaint"]',f'polygon = PackedVector2Array({x-300},{y-200},{x+300},{y-200},{x+300},{y+300},{x-300},{y+300})','metadata/tile = "path"'])
for n in range(24):
 x=8300+(n%2)*180;y=1300+(n//2)*480;prop(f'NorthRelic{n}',x,y,2 if n%3==0 else 3)
for n in range(36):prop(f'RoadRelic{n}',1000+n*380,9150 if n%2==0 else 9840,2 if n%4==0 else 3)
p.write_text(s+'\n\n'+'\n\n'.join(extra)+'\n')
