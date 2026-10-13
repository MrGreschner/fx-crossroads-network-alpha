"""Deterministic, original path-driven worlds and Pippa's pixel art. Run from any directory."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,math,random
R=Path(__file__).resolve().parents[1]
def write(path,data):
 p=R/path;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(data,indent=2)+'\n')
def world(key,name,size,spawn,boss,boss_type):return dict(id=key,name=name,size=size,spawn=spawn,exit=boss,boss_type=boss_type,floors=[],props=[],grass=[],mud=[],falls=[],secrets=[],spawns=[],stages=[],gates=[],lake=[],raft={},background='#324f46')
def room(w,name,r,kind='trail',stage=0):w['floors'].append(dict(name=name,rect=r,kind=kind,stage=stage))
def hexroom(w,name,c,r=430,stage=0):
 poly=[[round(c[0]+math.cos(i*math.pi/3)*r),round(c[1]+math.sin(i*math.pi/3)*r)] for i in range(6)]
 w['floors'].append(dict(name=name,poly=poly,kind='glass',stage=stage));return c

def path(w,points,width=230,kind='trail'):
 for a,b in zip(points,points[1:]):
  if a[0]==b[0]:r=[a[0]-width/2,min(a[1],b[1])-width/2,width,abs(a[1]-b[1])+width]
  elif a[1]==b[1]:r=[min(a[0],b[0])-width/2,a[1]-width/2,abs(a[0]-b[0])+width,width]
  else:raise ValueError('orthogonal paths')
  room(w,'',r,kind)
def prop(w,kind,x,y,s=1,solid=0):w['props'].append(dict(kind=kind,pos=[x,y],scale=s,solid=solid))
def secret(w,name,p,amount=35,kind='gold'):w['secrets'].append(dict(id=name,name=name,pos=p,amount=amount,kind=kind))
def enemies(w,kinds,points,stage=0):
 for i,p in enumerate(points):w['spawns'].append(dict(type=kinds[i%len(kinds)],pos=p,stage=stage))
# Honeycomb corridors connect differently sized hex chambers into a branching maze.
w=world('honeyglass','Honeyglass Gardens',[8600,5400],[420,3700],[7800,1200],'glass_queen');w['background']='#587557'
room(w,'Wildflower Approach',[120,3150,1450,1200],'meadow');path(w,[[1250,3700],[1900,3700]],260)
centers=[(1900,3700),(2950,3700),(2950,2400),(1900,2400),(2950,1100),(4100,1100),(4100,2400),(5250,2400)]
for i,c in enumerate(centers):hexroom(w,['Amber Vestibule','Apiary Gallery','Prism Nursery','Secret Nectar Cell','Honeydew Junction','Glass Orchard','Comb Crossroads','Garden Airlock'][i],c,460)
for pts in [[[1900,3700],[2950,3700],[2950,2400],[2950,1100],[4100,1100],[4100,2400],[5250,2400]],[[1900,3700],[1900,2400],[2950,2400]],[[2950,2400],[4100,2400]]]:path(w,pts,210,'glass')
room(w,'The Giant Blossom Garden',[5600,1550,1650,2400],'meadow');path(w,[[5250,2400],[6100,2400]],260,'glass');hexroom(w,'Queen Mellifera’s Crown Chamber',[7800,1200],620,1);path(w,[[6600,2100],[6600,1200],[7800,1200]],230,'glass')
w['gates']=[dict(rect=[7230,1090,65,220],stage=1,name='Crown seal: clear the maze and garden')]
enemies(w,['honey_beetle','seed_blossom','amber_hornet'],[[1100,3500],[1700,3700],[2090,3500],[2780,3800],[3160,3500],[2800,2450],[3120,2190],[1890,2200],[3100,1150],[2780,950],[4030,850],[4250,1260],[4000,2500],[4340,2250],[5240,2480],[6130,2250],[6760,2700],[6320,3360],[6000,3180],[6880,3510]],0)
w['stages']=['Explore the honeycomb maze and clear its garden defenders','Enter the Crown Chamber and defeat Queen Mellifera']
secret(w,'Nectar alcove',[1880,2390],40);secret(w,'Garden spring',[6950,1850],25,'heal')
for x,y in [(5800,1800),(5940,2850),(7040,2300),(6700,3760),(7060,3350),(1220,4080)]:prop(w,'giant_flower',x,y,1.5,44)
for c in centers:prop(w,'honey_lamp',c[0]+160,c[1]+210,1,0)
worlds=[w]
# Sunfield starts beneath a close tree canopy, then opens into grass pockets and terraces.
w=world('sunfield','Sunfield Expanse',[9400,5100],[450,4100],[8600,1000],'sun_sentinel');w['background']='#36513a'
path(w,[[400,4100],[1600,4100],[1600,3100],[2650,3100]],250)
for i in range(14):
 x=420+i*90;prop(w,'grand_tree',x,3920,1.2,42);prop(w,'grand_tree',x,4300,1.2,42)
for y in range(3080,4040,140):prop(w,'grand_tree',1400,y,1.1,40);prop(w,'grand_tree',1810,y,1.1,40)
room(w,'Whispergrass Fields',[2350,2450,2550,2100],'meadow');room(w,'Sunflower Terraces',[5250,1550,2100,2300],'meadow');room(w,'The Solstice Clearing',[7700,350,1500,1500],'meadow');path(w,[[4500,3100],[5800,3100],[6700,3100],[6700,1100],[8500,1100]],270)
for r in [[2600,2850,850,900],[3600,3550,1000,700],[3700,2600,800,750],[5500,2000,700,850],[6400,2920,620,650]]:w['grass'].append(r)
enemies(w,['bramble'],[[1200,4100],[1600,3380]])
enemies(w,['sun_sentinel','archer','sunbeam_cantor'],[[2800,3300],[3210,3070],[4000,3800],[4430,3720],[4180,2900],[5820,2360],[6190,2080],[6580,3330],[7040,2670],[6850,1760],[8040,1310],[8500,680]])
w['stages']=['Follow the wooded trail; search the grass fields and terraces','Defeat the Solstice guardian']
secret(w,'Sunken seed cache',[2750,4200],40);secret(w,'Terrace lookout',[7090,1770],25,'heal')
for x,y in [(2500,2650),(4700,4300),(5600,3670),(7320,1780),(8040,520)]:prop(w,'giant_flower',x,y,1,36)
worlds.append(w)
# Marsh: a ring of raised banks, causeways and a dangerous muddy shortcut.
w=world('lantern_marsh','Lantern Marsh',[8200,6000],[430,4600],[7350,1100],'bellroot');w['background']='#183d39'
room(w,'Lantern Landing',[180,4000,1250,1450],'marsh');room(w,'Mosswatch Island',[2200,2600,1600,1700],'marsh');room(w,'Bellroot Hollow',[6500,400,1450,1700],'marsh');room(w,'The Forgotten Shrine',[4500,4150,1300,1250],'marsh');room(w,'Wisp Fen',[4400,1500,1600,1650],'marsh')
path(w,[[850,4550],[1800,4550],[1800,3550],[2900,3550]],270,'boardwalk');path(w,[[3150,3300],[3150,2100],[5100,2100],[7100,2100],[7100,1500]],270,'boardwalk')
path(w,[[3100,3900],[3100,4750],[5050,4750],[6200,4750],[6200,1300],[7000,1300]],230,'marsh')
for r in [[2810,4010,570,950],[4870,4540,830,390],[6085,2200,230,1850],[4780,1770,500,780]]:w['mud'].append(r)
for x,y in [(400,4200),(1270,5000),(2380,2770),(3620,3990),(3600,2900),(4580,2780),(5790,1700),(4720,4370),(5590,5110),(6650,630),(7780,1800)]:prop(w,'moss_tree',x,y,1.65,55)
for i in range(32):
 x,y=[(1800,2800),(4020,3200),(6200,3700),(3900,5400)][i%4];prop(w,'moss_tree',x+(i//4)*120,y+(i%3)*105,1.1,35)
enemies(w,['lantern_crab','reed_stalker','wick_wisp','bog_bellringer'],[[1000,4480],[2000,3570],[2590,3220],[3310,3920],[3450,2860],[3110,2360],[4900,2350],[5630,2010],[5100,2840],[5210,4700],[6200,4030],[6200,2460],[7110,1920],[6990,1090],[7660,1550]])
w['stages']=['Explore the raised banks; black water is impassable, mud slows you','Reach Bellroot Hollow and defeat its guardian']
secret(w,'Forgotten shrine',[4750,5060],75);secret(w,'Lantern keeper’s spring',[2460,4010],30,'heal');secret(w,'Wisp hollow cache',[5760,2880],45)
worlds.append(w)
# Silverfall: interlocking elevated routes, enterable tree houses, enormous falls and lake transport.
w=world('silverfall','Silverfall Reach',[10500,7600],[520,6200],[9470,1500],'crowned_torrent');w['background']='#275c69'
for name,r in [('Ferryman’s Landing',[180,5600,1550,1550]),('Reed’s Hearth',[2500,4100,1450,1450]),('Mist Orchard',[5000,4200,1300,2000]),('Moonwater Jetty',[4400,1400,1500,1600]),('Upper Cascade',[7000,1400,1450,2000]),('Torrent Crown',[8700,750,1500,1900]),('Root Observatory',[1700,1700,1350,1600])]:room(w,name,r,'river')
path(w,[[1000,6250],[1850,6250],[1850,4800],[3300,4800],[5500,4800]],260,'bridge')
path(w,[[5500,5600],[7200,5600],[7200,2600],[9400,2600],[9400,1600]],240,'bridge')
path(w,[[3100,4800],[3100,3350],[2400,3350],[2400,2400],[5000,2400],[7750,2400]],240,'bridge')
path(w,[[5550,4800],[5550,3900],[4100,3900],[4100,2550],[5000,2550]],210,'trail')
# Lake is never a walkable floor. Its shore path is an optional alternative to the raft.
w['lake']=[6350,3650,2550,1750];w['raft']=dict(docks=[[6250,4590],[9100,4590]],route=[[6250,4590],[6800,4590],[8150,4590],[9100,4590]],speed=260)
path(w,[[5850,4590],[6250,4590]],210,'bridge');room(w,'Far-bank Dock',[8970,4290,550,700],'river');path(w,[[9180,4550],[9900,4550],[9900,2600],[9400,2600]],210,'bridge')
for r in [[1750,5350,320,850],[3580,3280,600,1150],[6610,1480,290,1370],[8380,400,240,2300]]:w['falls'].append(r)
for x,y,s in [(400,5860,2.2),(1600,6790,2.8),(2810,4450,3),(3630,5380,2.4),(2080,2200,2.5),(5810,5530,3.2),(5350,1850,2.9),(7820,1820,3),(9070,1050,2.7)]:prop(w,'grand_tree',x,y,s,65)
# House interiors are their own physical rooms connected by doors using E/Interact.
w['houses']=[]
for name,outside,inside,rect_ in [('Reed’s Riverside Hearth',[3000,4910],[3700,6800],[3320,6490,800,690]),('Canopy Tea Room',[5470,2110],[650,2650],[250,2260,800,780]),('Mistkeeper Observatory',[7550,2680],[8300,6550],[7920,6210,800,760])]:
 room(w,name,rect_,'house');w['houses'].append(dict(name=name,outside=outside,inside=inside));prop(w,'treehouse',*outside,1.4,0)
secret(w,'Reed’s river journal',[3850,6810],45);secret(w,'Canopy tea',[780,2590],35,'heal');secret(w,'Mistkeeper’s keepsake',[8440,6610],70);secret(w,'Root observatory',[2600,1990],60)
enemies(w,['cascade_heron','sluice_beetle','ripple_eel','tidebinder'],[[1290,6270],[3100,5160],[3590,4530],[2490,2830],[2820,1990],[4770,2520],[5650,2730],[5490,5020],[5900,5830],[7230,3700],[7880,2920],[7530,2230],[9000,2410],[9610,1920],[9740,1190]])
w['stages']=['Explore bridges, treehouses and the lake; either shore route works','Defeat the Crowned Torrent at the upper falls']
worlds.append(w)
# Pippa's winding canopy: split paths, hollow log tunnels, secret tea nooks.
w=world('petalbrook','Petalbrook Canopy',[7800,5900],[400,4550],[6870,950],'bloomtail_regent');w['background']='#354f47'
for name,r in [('Fernwhisker Village',[160,3920,1400,1500]),('Ribbon Grove',[2220,2700,1550,1500]),('Dewdrop Terrace',[4310,3450,1350,1700]),('Blossom Workshop',[4310,1100,1400,1400]),('Bloomtail’s Maypole',[6160,300,1450,1500]),('Hidden Tea Garden',[2200,400,1250,1200])]:room(w,name,r,'petal')
path(w,[[800,4450],[1700,4450],[1700,3400],[2900,3400],[2900,2100],[4900,2100],[4900,1100],[6850,1100]],230,'trail')
path(w,[[3300,3400],[3300,4360],[4900,4360],[6000,4360],[6000,1100],[6800,1100]],230,'bridge')
path(w,[[2900,2800],[2900,1000]],220,'log');path(w,[[5300,3800],[5300,2000]],190,'log')
w['gates']=[dict(rect=[6140,970,65,260],stage=1,name='Maypole seal: clear the canopy patrols')]
enemies(w,['petal_ducker','briar_tail','nectar_keeper'],[[1200,4330],[1710,3670],[2490,3630],[3390,2910],[2810,2370],[4830,1870],[5240,1420],[5230,2270],[4710,4430],[5220,4690],[5990,3560],[6000,2120],[2850,1020]],0)
w['stages']=['Follow the ribbon paths and clear the canopy patrols','Face Bloomtail Regent beneath the great maypole']
secret(w,'Tea with the fireflies',[2480,750],30,'heal');secret(w,'Ribbon chest',[5350,4870],65)
w['houses']=[]
for name,outside,inside,bounds in [('Fernwhisker Cottage',[1040,4640],[6870,5400],[6460,5100,840,700]),('Ribbon Atelier',[4850,1600],[1080,700],[670,370,850,780])]:
 room(w,name,bounds,'house');w['houses'].append(dict(name=name,outside=outside,inside=inside));prop(w,'treehouse',*outside,1.2,0)
secret(w,'Pippa’s welcome basket',[7010,5430],40);secret(w,'Atelier tea',[1240,720],25,'heal')
for x,y,s in [(330,4080,2),(1440,4990,2),(2350,3060,2.3),(3590,3840,2),(4470,3810,2.2),(5520,4920,2),(4500,1290,2.3),(7150,1590,2.5),(6260,480,2.6),(2360,460,2)]:prop(w,'grand_tree',x,y,s,48)
for p in [[900,4800],[5080,1650],[3020,790],[4730,4760],[6730,650]]:prop(w,'giant_flower',*p,1.3,30)
worlds.append(w)
# Border planting frames routes without plugging their corridors. Objects inside rooms have real trunks.
for w in worlds:
 rng=random.Random(w['id'])
 for f in w['floors']:
  if 'rect' not in f or not f['name'] or f['kind'] in ['house','glass']:continue
  x,y,ww,hh=f['rect']
  for i in range(int(ww/240)):
   for yy in [y+30,y+hh-25]:prop(w,'moss_tree' if w['id']=='lantern_marsh' else 'grand_tree',x+80+i*240,yy,.8,0)
 # Populate room interiors, preserving enemy positions and the connecting routes.
 protected=[w['spawn'],w['exit']]+[e['pos'] for e in w['spawns']]+[e['pos'] for e in w['secrets']]+[h['outside'] for h in w.get('houses',[])]+[h['inside'] for h in w.get('houses',[])]+w.get('raft',{}).get('docks',[])
 for f in w['floors']:
  if 'rect' not in f or not f['name'] or f['kind']=='house':continue
  x,y,ww,hh=f['rect']
  for xx in range(int(x+210),int(x+ww-140),300):
   for yy in range(int(y+250),int(y+hh-130),330):
    if any(math.dist((xx,yy),p)<155 for p in protected):continue
    if any('rect' in path and not path['name'] and path['rect'][0]-45<=xx<=path['rect'][0]+path['rect'][2]+45 and path['rect'][1]-45<=yy<=path['rect'][1]+path['rect'][3]+45 for path in w['floors']):continue
    if any(math.dist((xx,yy),p['pos'])<130 for p in w['props']):continue
    kind='moss_tree' if w['id']=='lantern_marsh' else 'giant_flower' if w['id']=='honeyglass' else 'grand_tree'
    prop(w,kind,xx,yy,1.2 if kind=='giant_flower' else 1.35,38)
 for f in w['floors']:
  if 'poly' not in f:continue
  c=[sum(p[0] for p in f['poly'])/6,sum(p[1] for p in f['poly'])/6]
  for dx,dy in [(-200,-220),(200,220)]:
   p=[c[0]+dx,c[1]+dy]
   if all(math.dist(p,q)>110 for q in protected):prop(w,'giant_flower',*p,.75,24)
 checkpoints={'honeyglass':[(2950,3700,3),(6100,2400,5)],'sunfield':[(3100,3300,3),(6100,2900,5)],'lantern_marsh':[(3000,3500,3),(5100,2100,5)],'silverfall':[(3100,4800,3),(5100,2400,5),(5500,5200,5)],'petalbrook':[(2900,3400,3),(4900,1800,5),(4900,4360,5)]}
 w['checkpoints']=[dict(pos=[x,y],level=level) for x,y,level in checkpoints[w['id']]]
 write(f"content/campaigns/{w['id']}_paths.json",w)
 key=w['id'];p=R/f'content/regions/{key}.json'
 region=json.loads(p.read_text()) if p.exists() else dict(id=key,name=w['name'],terrain='garden_grass',xp_per_level=3,boss_health=1000,boss_secondary='petalstorm',difficulty_label='Medium — ribbon paths, decoys and moving blossom traps')
 region.update(size=w['size'],scene=f'res://scenes/realms/{key}.tscn',immersive=True,boss_enemy=w['boss_type'],boss_sprite=w['boss_type'],description=w['stages'][0]+'. Optional treasures reward exploration; exit unlocks after its guardian falls.')
 write(f'content/regions/{key}.json',region)
 scene='[gd_scene format=3]\n\n[node name="ImmersiveRealm" type="Node2D"]\n'
 for n in ['Points','GroundPaint','Obstacles','Enemies']:scene+=f'\n[node name="{n}" type="Node2D" parent="."]\n'
 for n,pos in [('Spawn',w['spawn']),('ReturnGate',[w['spawn'][0]-90,w['spawn'][1]]),('Merchant',[w['spawn'][0]+110,w['spawn'][1]+80]),('Boss',w['exit'])]:scene+=f'\n[node name="{n}" type="Marker2D" parent="Points"]\nposition = Vector2({pos[0]}, {pos[1]})\n'
 (R/f'scenes/realms/{key}.tscn').write_text(scene)
hero=dict(id='pippa',name='Pippa Fernwhisker',sprite='pippa',max_health=108,speed=245,run_cost=0,lore='A red panda ribbon-weaver from Petalbrook Canopy. Pippa leaves warm tea for lost travelers and weaves living fern ribbons to protect her woodland home.',primary=dict(name='Ribbon Stitch',style='ribbon_stitch',damage=15,cooldown=.8,range=380,description='Send two intertwining living ribbons forward. Each deals 15 damage once; walls stop the weaving threads.'),secondary=dict(name='Fern Double',style='fern_double',damage=0,cooldown=8,range=160,description='Grow a leaf double at the aimed spot for 3s. Nearby enemies chase it instead of you. On expiry it blooms, healing you and allies within 150 for 8 HP; it never heals enemies.'),special=dict(name='Maypole Waltz',style='maypole_waltz',damage=36,cooldown=18,range=180,description='Plant a maypole ahead. Three ribbon tips spiral outward over 2.4s to a 230-unit radius. Each tip hits each foe once for 36 and slows for 2s. Walls block the ribbons.'),passive='Afterglow: allies healed by Fern Double also gain 20% movement speed for 2 seconds.',passive_effect='fern_afterglow')
write('content/characters/pippa.json',hero)
new=[('sunbeam_cantor','Solstice Cantor',100,65,'ranged'),('petal_ducker','Petal Ducker',72,110,'ranged'),('briar_tail','Briar Tail',105,95,'chase'),('nectar_keeper','Nectar Keeper',88,75,'ranged'),('bloomtail_regent','Bloomtail Regent',1000,120,'chase')]
for key,name,hp,speed,beh in new:write(f'content/enemies/{key}.json',dict(id=key,name=name,sprite=key,health=hp,speed=speed,damage=12,behaviour=beh,aggro_range=700,expansion_only=True))
m=json.loads((R/'content/manifest.json').read_text())
if 'pippa' not in m['characters']:m['characters'].append('pippa')
if 'petalbrook' not in m['regions']:m['regions'].insert(m['regions'].index('middle_school'),'petalbrook')
for key,*_ in new:
 if key not in m['enemies']:m['enemies'].append(key)
write('content/manifest.json',m)
# Original pixel props: substantial silhouettes, bark, hanging moss, giant petals and inhabitable treehouses.
ink='#283e40'
for key in ['grand_tree','moss_tree','giant_flower','treehouse']:
 im=Image.new('RGBA',(160,220));d=ImageDraw.Draw(im)
 if key in ['grand_tree','moss_tree','treehouse']:
  d.polygon([(57,205),(66,93),(99,87),(108,204),(135,216),(84,205),(28,218)],fill='#795d4b',outline=ink,width=3)
  for x in [67,78,89,99]:d.line((x,120,x-3,193),fill='#ac8060',width=2)
  d.line((72,147,34,106),fill='#795d4b',width=10);d.line((93,130,133,94),fill='#795d4b',width=10)
  for x,y,r in [(45,60,39),(80,40,42),(113,60,38),(51,98,38),(101,96,43)]:
   d.ellipse((x-r,y-r,x+r,y+r),fill='#4b8466' if key!='moss_tree' else '#476f5a',outline=ink,width=3);d.arc((x-r+9,y-r+8,x+r-7,y+r-12),200,285,fill='#82b58b',width=3)
  if key=='moss_tree':
   for x in range(17,151,13):
    y=95+(x%3)*12;d.line((x,y,x+3,y+45+(x%4)*9),fill='#98ad76',width=4);d.line((x+3,y+30,x-4,y+49),fill='#6b976c',width=3)
  if key=='treehouse':
   d.rectangle((33,105,127,165),fill='#be9a6b',outline=ink,width=3);d.polygon([(24,109),(78,67),(138,109)],fill='#719d80',outline=ink,width=3)
   for x in [44,100]:d.rectangle((x,119,x+16,140),fill='#b9e9da',outline=ink,width=2)
   d.rectangle((69,127,91,165),fill='#584b42',outline=ink);d.rectangle((21,164,139,174),fill='#ba956a',outline=ink)
   for y in range(175,213,9):d.line((69,y,91,y),fill='#bf9f72',width=3)
   for x in [68,92]:d.line((x,166,x,214),fill='#685c48',width=2)
 else:
  d.line((80,85,80,212),fill='#587c52',width=10)
  d.ellipse((20,150,80,177),fill='#87b576',outline=ink,width=3);d.ellipse((81,176,143,201),fill='#69965e',outline=ink,width=3)
  for a in range(6):
   x=80+math.cos(a*math.pi/3)*35;y=67+math.sin(a*math.pi/3)*35;d.ellipse((x-25,y-27,x+25,y+27),fill=['#e9a1b4','#ddb7de','#eacb8f'][a%3],outline='#825d76',width=3)
  d.ellipse((59,46,101,88),fill='#f6d185',outline='#8d7960',width=3);d.ellipse((71,58,88,76),fill='#bb9861')
 im.save(R/f'assets/v50_{key}.png')
# Pippa is visibly a red panda: ringed tail, ears, facial mask and ribbon spool.
for key in ['pippa']+[a[0] for a in new]:
 for n,pose in enumerate(['idle','walk1','walk2','attack']):
  im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);b=[0,-1,1,0][n]
  if key=='pippa':
   d.ellipse((35,27,61,58),fill='#b87354',outline=ink,width=2)
   for y in [36,44,52]:d.arc((35,y-12,61,y+10),10,160,fill='#5c5146',width=4)
   d.rectangle((20,42,26,57+b),fill='#514742');d.rectangle((32,42,38,57-b),fill='#514742')
   d.polygon([(18,27),(38,27),(43,47),(16,47)],fill='#8ebca0',outline=ink,width=2);d.line((19,34,39,34),fill='#e7bdd0',width=3)
   d.ellipse((12,5+b,25,21+b),fill='#a96952',outline=ink,width=2);d.ellipse((34,5+b,46,21+b),fill='#a96952',outline=ink,width=2)
   d.ellipse((12,12+b,45,34+b),fill='#c58362',outline=ink,width=2);d.ellipse((15,19+b,26,30+b),fill='#f3e2c8');d.ellipse((32,19+b,43,30+b),fill='#f3e2c8')
   for x in [21,35]:d.rectangle((x,21+b,x+2,24+b),fill=ink)
   d.polygon([(26,27+b),(32,27+b),(29,30+b)],fill=ink);d.line((27,32+b,31,32+b),fill='#82575a')
   d.ellipse((38,6+b,48,15+b),fill='#e2afc6');d.ellipse((42,9+b,45,12+b),fill='#f5d790')
   d.line((17,34,8,42+b),fill='#c58362',width=5);d.ellipse((3,35+b,14,47+b),fill='#efd2a5',outline=ink,width=2)
   d.line((38,34,47,40-b),fill='#c58362',width=5);d.line((48,39,57,27 if pose=='attack' else 46),fill='#e6b7d1',width=3)
  elif key=='sunbeam_cantor':
   d.polygon([(19,30),(44,30),(51,59),(12,59)],fill='#cca65a',outline=ink,width=2);d.ellipse((20,12+b,44,35+b),fill='#f2d394',outline=ink,width=2)
   for a in range(8):
    v=(32+math.cos(a*math.pi/4)*22,23+b+math.sin(a*math.pi/4)*22);d.line((32,23+b,*v),fill='#f4cc73',width=3)
   d.ellipse((24,17+b,40,31+b),fill='#76643e');d.line((50,23,50,59),fill='#725f45',width=3);d.ellipse((44,16,57,30),fill='#fff0ba',outline=ink)
  elif key=='nectar_keeper':
   d.ellipse((17,18+b,46,47+b),fill='#f0c4c6',outline=ink,width=2);d.polygon([(15,26),(8,9),(25,19)],fill='#adc8a1',outline=ink);d.polygon([(39,20),(56,10),(48,32)],fill='#adc8a1',outline=ink);d.rectangle((22,43,40,58),fill='#80aa81',outline=ink);d.ellipse((37,38,57,55),fill='#e4d19b',outline=ink)
  else:
   tint='#b999bd' if key=='petal_ducker' else '#967f6a' if key=='briar_tail' else '#d9b8cf'
   d.ellipse((34,26,61,51),fill=tint,outline=ink,width=2);d.ellipse((13,24+b,43,55+b),fill=tint,outline=ink,width=2);d.ellipse((12,11+b,43,33+b),fill=tint,outline=ink,width=2)
   for x in [14,32]:d.ellipse((x,3+b,x+11,18+b),fill=tint,outline=ink,width=2)
   d.ellipse((18,20+b,23,24+b),fill=ink);d.ellipse((32,20+b,37,24+b),fill=ink);d.ellipse((25,26+b,30,30+b),fill='#f5dec9')
   d.rectangle((14,47,24,59+b),fill=ink);d.rectangle((31,47,41,59-b),fill=ink)
   if key=='bloomtail_regent':
    d.polygon([(10,12),(10,1),(20,7),(28,1),(36,7),(44,1),(45,13)],fill='#ead38e',outline=ink);d.line((48,27,48,60),fill='#776b57',width=3);d.ellipse((40,20,57,35),fill='#eaaec8',outline=ink)
   elif key=='petal_ducker':d.polygon([(35,36),(57,25),(57,42)],fill='#aac78d',outline=ink)
   else:
    for x in range(37,59,7):d.polygon([(x,32),(x+3,17),(x+7,34)],fill='#637953',outline=ink)
  im.save(R/f'assets/{key}_{pose}.png')
  if n<2:im.save(R/f'assets/{key}_{n}.png')
print('Five authored worlds, Pippa and five enemy sprites built.')
