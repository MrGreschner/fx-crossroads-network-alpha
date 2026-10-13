from pathlib import Path
from PIL import Image,ImageDraw
import json,math
R=Path(__file__).resolve().parents[1]
def write(path,value):
 p=R/path;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(value,indent=2)+'\n')
hero=dict(id='robot',name='Bolt Ironcore',sprite='robot',run_cost=0,max_health=130,speed=220,lore='Reclaimed from Neon Crucible, Bolt broke his factory oath to defend living towns. His iron chassis folds into the ancient saw that once built the Crossroads bridges.',primary=dict(name='Piston Jab',style='piston_jab',damage=30,cooldown=.6,description='Extend a mechanical fist at foes directly ahead: 30 damage within 100 units.'),secondary=dict(name='Missile Volley',style='missile_volley',damage=14,cooldown=7,description='Launch four guided missiles in a short volley. Each travels visibly, turns toward a foe and deals 14 direct damage plus 6 splash to other foes within 58 units. Walls stop missiles.'),special=dict(name='Iron Tempest',style='saw_transform',damage=0,contact_damage=12,cooldown=24,description='Fold into a giant spinning saw for 6s (0.45s to transform). Touching the 78-unit blade deals 12 damage every 0.3s. Move at 42% speed; no dodge or normal attacks. Primary becomes Shock Stomp: 16 damage within 170, 0.4s stun then 2.5s slow, with a 2.6s cooldown. You remain vulnerable.'),passive='Overclock Reserve: three successful Piston Jabs prime the next Missile Volley with one extra missile. Missing a jab gives no charge.',passive_effect='overclock_reserve')
write('content/characters/robot.json',hero)
enemies=[('hatch_sentinel','Hatch Sentinel',85,0,'ranged','rise_volley'),('sweep_drone','Sweep Drone',80,115,'ranged','scan_sweep'),('magnet_hauler','Magnet Hauler',190,72,'melee','magnet_tether'),('repair_wisp','Repair Wisp',65,100,'ranged','repair_arc'),('fork_runner','Fork Runner',80,125,'melee','vector_dash'),('relay_weaver','Relay Weaver',100,90,'ranged','signal_fence'),('continuum_forge','Continuum: Forge Shell',800,90,'custom','forge_logic'),('continuum_archive','Continuum: Archive Shell',1000,125,'custom','archive_logic'),('continuum_reactor','Continuum: Reactor Shell',1250,80,'custom','reactor_logic'),('continuum_crown','Continuum: Crown Shell',1700,150,'custom','crown_logic')]
for id,name,hp,speed,behaviour,attack in enemies:write(f'content/enemies/{id}.json',dict(id=id,name=name,sprite=id,health=hp,speed=speed,damage=15,behaviour=behaviour,custom_attack=attack,aggro_range=850,expansion_only=True))
rooms=[]
def room(name,bounds,colour):rooms.append(dict(name=name,rect=bounds,colour=colour))
room('ARRIVAL DOCK',[240,3000,1600,1400],'#9ed9c6');room('FABRICATION FOUNDRY',[240,900,1600,1800],'#e4b675');room('SIGNAL ARCHIVES',[2500,350,1800,1400],'#9dd9ef');room('COOLANT REACTOR',[2500,2550,1800,1850],'#7cdad8');room('CONTINUUM UPLINK',[4800,1300,1400,2100],'#c8b0ef');room('SPARE PARTS BAY',[300,300,1000,500],'#c0cf9b');room('REPAIR GARDEN',[4600,3900,1500,600],'#a1ddb0')
for bounds in [[760,2400,460,800],[1550,1450,1100,340],[3150,1450,500,1350],[4100,1150,1000,360],[4100,3150,1000,340],[700,650,350,400],[4100,4040,650,280]]:room('',bounds,'#547c8b')
props=[]
def prop(kind,pos,size,solid=True):
 p=dict(kind=kind,pos=pos,size=size)
 if solid:p['solid']=size
 props.append(p)
for x in [450,1570]:
 for y in [1300,2100]:prop('forge',[x,y],[150,130])
for y in [1350,2250,3500]:prop('belt',[1050,y],[450,90],False)
for x in [2700,4080]:
 for y in [650,1100,1550]:prop('server',[x,y],[95,130])
for x in [2750,4000]:
 for y in [2800,3900]:prop('coolant',[x,y],[210,190])
for x in [5000,5960]:
 for y in [1550,2950]:prop('antenna',[x,y],[80,100])
for pos in [[460,3300],[1580,4050],[530,520],[1060,520],[4810,4220],[5820,4220]]:prop('console',pos,[100,75])
for x,y in [(3200,700),(3600,700),(3150,4050),(3560,4050)]:prop('console',[x,y],[90,65])
for kind,pos,size in [("forge",[650,1800],[100,90]),("forge",[1450,2000],[100,90]),("server",[3000,1100],[95,130]),("server",[3780,1250],[95,130]),("server",[3170,1500],[95,130]),("coolant",[3060,3400],[160,150]),("coolant",[3840,3520],[160,150]),("antenna",[5210,1980],[80,100]),("antenna",[5800,2820],[80,100])]:prop(kind,pos,size)
spawns=[]
def spawn(kind,x,y,sector):spawns.append(dict(type=kind,pos=[x,y],sector=sector))
# All six roles appear across the realm, with varied clusters rather than a ranged row.
for kind,x,y in [('fork_runner',780,3480),('sweep_drone',1340,3550),('magnet_hauler',1140,3850),('hatch_sentinel',550,3920),('repair_wisp',1410,3770),('relay_weaver',1470,3200),('hatch_sentinel',840,2500),('magnet_hauler',680,2300),('fork_runner',1280,2100),('sweep_drone',1250,1300),('relay_weaver',600,1550),('repair_wisp',650,1940),('fork_runner',1040,1670),('hatch_sentinel',1420,1790),('sweep_drone',1100,2150),('relay_weaver',1340,2380)]:spawn(kind,x,y,0)
for kind,x,y in [('hatch_sentinel',2300,1610),('sweep_drone',3200,1000),('relay_weaver',3650,1350),('repair_wisp',3700,1020),('fork_runner',2850,1340),('magnet_hauler',3020,700),('hatch_sentinel',3940,820),('sweep_drone',4030,1300),('fork_runner',900,490)]:spawn(kind,x,y,1)
for kind,x,y in [('hatch_sentinel',3390,2310),('magnet_hauler',3360,3030),('sweep_drone',3800,3100),('repair_wisp',3670,3620),('relay_weaver',3100,3700),('fork_runner',3190,3200),('hatch_sentinel',3990,3440),('fork_runner',3850,4060),('relay_weaver',5170,4240)]:spawn(kind,x,y,2)
for kind,x,y in [('hatch_sentinel',4550,1320),('sweep_drone',5450,1590),('relay_weaver',5780,1940),('repair_wisp',5750,2470),('magnet_hauler',5260,2650),('fork_runner',5570,2890),('hatch_sentinel',5990,2380),('sweep_drone',5020,2260),('relay_weaver',4800,3300),('fork_runner',5650,1760)]:spawn(kind,x,y,3)
bodies=[dict(type='continuum_forge',name='Forge Shell',pos=[1050,1900],hp=800),dict(type='continuum_archive',name='Archive Shell',pos=[3400,1050],hp=1000),dict(type='continuum_reactor',name='Reactor Shell',pos=[3450,3450],hp=1250),dict(type='continuum_crown',name='Crown Shell',pos=[5500,2300],hp=1700)]
world=dict(name='Neon Crucible',size=[6400,4800],rooms=rooms,props=props,spawns=spawns,bodies=bodies,exit=[5500,3160],pods=[dict(id='spare',pos=[620,500],sector=1),dict(id='garden',pos=[5510,4240],sector=2)])
write('content/campaigns/neon_crucible.json',world)
write('content/regions/neon_crucible.json',dict(id='neon_crucible',name='Neon Crucible',size=[6400,4800],terrain='neon_plate',scene='res://scenes/realms/neon_crucible.tscn',boss_enemy='continuum_crown',boss_sprite='continuum_crown',boss_health=1700,xp_per_level=3,difficulty_label='Hard — guided missiles, repairing machines and four uploaded boss bodies',description='Bolt Ironcore\u2019s lost factory floats above an aether-lit abyss. Explore a foundry, signal archive, coolant reactor and uplink; discover repair bays, wake hidden turrets and break Continuum\u2019s four increasingly dangerous bodies. Each upload sends the same intelligence to a distant backup chassis.'))
scene='[gd_scene format=3]\n\n[node name="NeonCrucible" type="Node2D"]\n'
for key in ['Points','GroundPaint','Obstacles','Enemies']:scene+=f'\n[node name="{key}" type="Node2D" parent="."]\n'
for key,pos in [('Spawn',[550,3200]),('ReturnGate',[420,3120]),('Merchant',[650,3150]),('Boss',world['exit'])]:scene+=f'\n[node name="{key}" type="Marker2D" parent="Points"]\nposition = Vector2({pos[0]}, {pos[1]})\n'
(R/'scenes/realms/neon_crucible.tscn').write_text(scene)
p=R/'content/manifest.json';m=json.loads(p.read_text())
if 'robot' not in m['characters']:m['characters'].append('robot')
for id,*_ in enemies:
 if id not in m['enemies']:m['enemies'].append(id)
if 'neon_crucible' not in m['regions']:m['regions'].insert(m['regions'].index('high_school')+1,'neon_crucible')
p.write_text(json.dumps(m,indent=2)+'\n')
# Original small pixel sprites. Different silhouettes, not palette swaps.
ink='#243540';metal='#819ca3';light='#c4d4cb';cyan='#9aeaf0';gold='#d7b270'
for id in ['robot']+[e[0] for e in enemies]:
 for n,pose in enumerate(['idle','walk1','walk2','attack']):
  im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);b=[0,-1,1,0][n]
  if id in ['robot','continuum_forge']:
   d.rectangle((14,38,25,57+b),fill=metal,outline=ink,width=2);d.rectangle((37,38,48,57-b),fill=metal,outline=ink,width=2)
   d.rectangle((10,55+b,27,61+b),fill=ink);d.rectangle((35,55-b,52,61-b),fill=ink)
   d.polygon([(14,22),(49,22),(47,43),(17,43)],fill=metal,outline=ink,width=2);d.rectangle((23,27,40,39),fill=ink);d.ellipse((26,28,37,38),fill=cyan)
   d.rectangle((21,6+b,43,24+b),fill=light,outline=ink,width=2);d.rectangle((25,12+b,40,18+b),fill=ink);d.line((26,15+b,37,15+b),fill=cyan,width=2)
   d.line((32,6+b,32,1+b),fill=ink,width=2);d.point((32,1+b),fill=gold)
   d.rectangle((4,22,16,32),fill=gold,outline=ink);d.rectangle((47,22,58,32),fill=gold,outline=ink)
   x=61 if pose=='attack' else 53
   d.line((52,32,x,45),fill=metal,width=9);d.rectangle((x-6,40,x+2,50),fill=light,outline=ink)
   d.line((12,31,10,43),fill=metal,width=7);d.rectangle((6,39,15,48),fill=light,outline=ink)
   if id=='continuum_forge':d.polygon([(4,29),(0,19),(8,15),(14,22)],fill='#e2a660',outline=ink);d.rectangle((27,30,37,35),fill='#f6ba69')
  elif id=='hatch_sentinel':
   d.ellipse((8,45,55,60),fill=ink);d.rectangle((20,28+b,43,53),fill=metal,outline=ink,width=2);d.ellipse((10,19+b,53,38+b),fill=light,outline=ink,width=2)
   d.rectangle((24,14+b,39,30+b),fill='#5c737e',outline=ink);d.rectangle((28,9+b,35,27+b),fill=ink);d.rectangle((29,9+b,34,15+b),fill=gold)
   d.line((16,28+b,47,28+b),fill=cyan,width=2);d.rectangle((25,42,37,45),fill=gold)
  elif id=='sweep_drone':
   d.polygon([(6,24+b),(25,17+b),(38,17+b),(58,24+b),(47,39+b),(16,39+b)],fill=metal,outline=ink,width=2)
   for x in [2,47]:d.ellipse((x,20+b,x+15,34+b),fill=ink,outline=light,width=2)
   d.ellipse((20,12+b,43,40+b),fill=light,outline=ink,width=2);d.rectangle((24,22+b,39,29+b),fill=ink);d.line((26,25+b,38,25+b),fill=cyan,width=3)
   d.line((24,43+b,26,50+b),fill='#728695',width=4);d.line((38,43+b,36,50+b),fill='#728695',width=4)
  elif id=='magnet_hauler':
   d.rectangle((10,40,25,60),fill=ink);d.rectangle((37,40,53,60),fill=ink)
   d.rectangle((8,18+b,54,44+b),fill='#a09076',outline=ink,width=2);d.rectangle((14,23+b,48,34+b),fill='#5d736f')
   d.rectangle((22,9+b,43,24+b),fill=metal,outline=ink);d.rectangle((25,14+b,39,18+b),fill=gold)
   d.arc((0,25+b,20,49+b),0,180,fill='#bf765a',width=7);d.arc((43,25+b,63,49+b),0,180,fill='#7499b1',width=7)
   d.line((26,38+b,38,38+b),fill=cyan,width=3)
  elif id=='repair_wisp':
   d.ellipse((18,12+b,46,40+b),fill='#72a796',outline=ink,width=2);d.ellipse((23,16+b,41,35+b),fill='#bce1b6')
   d.line((32,20+b,32,30+b),fill='#fcf6dc',width=4);d.line((27,25+b,37,25+b),fill='#fcf6dc',width=4)
   for x in [4,45]:d.polygon([(x,21+b),(x+14,12+b),(x+14,32+b)],fill='#7099a5',outline=ink)
   d.line((32,39+b,27,50+b,36,56+b),fill='#88bda9',width=3);d.ellipse((23,54,43,58),fill='#385363')
  elif id=='fork_runner':
   for side in [-1,1]:
    for j in range(3):d.line((32+side*9,27+j*5+b,32+side*(23+j*2),32+j*8+b,32+side*(20+j*2),45+j*5+b),fill=metal,width=4)
   d.polygon([(18,23+b),(31,10+b),(46,23+b),(42,42+b),(22,42+b)],fill='#bc8d68',outline=ink,width=2);d.rectangle((24,21+b,40,28+b),fill=ink);d.rectangle((28,23+b,35,26+b),fill=cyan)
  elif id=='relay_weaver':
   d.polygon([(15,14+b),(45,14+b),(52,46+b),(8,46+b)],fill='#797d9e',outline=ink,width=2)
   d.ellipse((21,4+b,41,24+b),fill=light,outline=ink);d.line((27,12+b,36,12+b),fill='#b4a4f2',width=3)
   for x in [9,49]:d.line((x,14+b,x,40+b),fill=cyan,width=3);d.ellipse((x-4,10+b,x+4,18+b),fill=ink,outline=cyan)
   d.rectangle((20,49,26,59-b),fill=metal,outline=ink);d.rectangle((34,49,40,59+b),fill=metal,outline=ink)
   d.polygon([(29,25+b),(35,31+b),(29,38+b),(23,31+b)],fill='#baa7e3')
  elif id=='continuum_archive':
   d.ellipse((19,15+b,46,43+b),fill=light,outline=ink,width=2);d.ellipse((25,21+b,40,37+b),fill=cyan,outline=ink)
   for x,sgn in [(5,-1),(50,1)]:
    d.polygon([(x,9+b),(x+10,13+b),(x+7,34+b),(x,29+b)],fill='#6d93af',outline=ink);d.polygon([(x,38+b),(x+10,35+b),(x+8,53+b),(x,55+b)],fill='#6d93af',outline=ink)
   d.line((15,20+b,24,28+b,15,42+b),fill=ink,width=4);d.line((46,20+b,40,28+b,48,42+b),fill=ink,width=4);d.rectangle((28,43+b,36,53+b),fill=metal,outline=ink)
  elif id=='continuum_reactor':
   d.rectangle((4,36+b,16,58+b),fill=ink);d.rectangle((47,36+b,60,58+b),fill=ink)
   d.ellipse((8,14+b,55,54+b),fill='#5e8892',outline=ink,width=3);d.ellipse((18,22+b,45,46+b),fill='#82cdd0',outline=light,width=3)
   for j in range(4):d.line((24+j*5,25+b,24+j*5,43+b),fill='#3e778c',width=2)
   for x in [5,53]:d.rectangle((x,8+b,x+6,29+b),fill=metal,outline=ink);d.rectangle((x+1,6+b,x+5,11+b),fill=cyan)
   d.rectangle((23,7+b,39,17+b),fill=metal,outline=ink);d.line((26,12+b,37,12+b),fill=cyan,width=3)
  else:
   d.polygon([(23,40),(11,60),(24,59),(32,46),(41,60),(53,60),(43,40)],fill=metal,outline=ink,width=2)
   d.polygon([(19,22+b),(43,22+b),(52,43+b),(12,43+b)],fill='#867ca6',outline=ink,width=2)
   d.ellipse((22,8+b,42,25+b),fill=light,outline=ink);d.line((26,16+b,38,16+b),fill='#c5b1f0',width=3)
   d.polygon([(20,10+b),(16,0+b),(28,6+b),(32,0+b),(36,6+b),(47,0+b),(43,11+b)],fill=gold,outline=ink)
   d.polygon([(11,24+b),(2,19+b),(4,40+b),(13,46+b)],fill='#5b7790',outline=ink);d.polygon([(49,24+b),(61,17+b),(60,40+b),(51,46+b)],fill='#5b7790',outline=ink)
   d.ellipse((26,29+b,38,41+b),fill='#d4bcf2',outline=ink)
  im.save(R/f'assets/{id}_{pose}.png')
  if n<2:im.save(R/f'assets/{id}_{n}.png')
 if id!='robot':im.save(R/f'assets/{id}.png')
im=Image.new('RGBA',(64,64),'#283b49');d=ImageDraw.Draw(im);d.rectangle((0,0,63,63),outline='#475762',width=2);d.rectangle((5,5,58,58),outline='#23343f',width=2)
for x in [6,56]:
 for y in [6,56]:d.rectangle((x,y,x+2,y+2),fill='#7a9297')
d.line((14,50,27,50,27,38,40,38),fill='#41626e',width=1);d.rectangle((41,37,43,39),fill='#719fa8');im.save(R/'assets/neon_plate.png')
print('Bolt Ironcore; Neon Crucible; six machine types, four boss bodies; 33 heroes and 22 realms.')
