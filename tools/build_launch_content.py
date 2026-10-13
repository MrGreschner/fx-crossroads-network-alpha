"""Generate bundled launch examples. Student edits live in content/ and scenes/."""
from pathlib import Path
from PIL import Image, ImageDraw
import json, math, random
ROOT=Path(__file__).resolve().parents[1]
ASSETS=ROOT/'assets'; CONTENT=ROOT/'content'; SCENES=ROOT/'scenes'/'realms'
random.seed(814)
def write(kind, name, data):
 (CONTENT/kind/f'{name}.json').write_text(json.dumps(data,indent=2)+'\n')
def sprite(name, base, accent, shape='creature'):
 for frame,pose in enumerate(['idle','walk1','walk2','attack']):
  im=Image.new('RGBA',(48,48)); d=ImageDraw.Draw(im)
  dx=[0,-2,2,2][frame]; dy=[0,1,-1,-1][frame]
  if shape=='goalie':
   d.rectangle((13+dx,17+dy,34+dx,37+dy),fill=base,outline='#253d51',width=2)
   d.ellipse((14+dx,5+dy,33+dx,24+dy),fill='#e8f1f6',outline=base,width=3)
   d.rectangle((19+dx,13+dy,29+dx,18+dy),fill='#24465c')
   d.rectangle((6+dx,22+dy,13+dx,35+dy),fill=accent)
   d.line((35+dx,12+dy,39+dx,42+dy),fill='#755331',width=3)
   if frame==3:d.line((21,28,45,20),fill='#e4e3b5',width=4)
  elif shape=='astronaut':
   d.ellipse((11+dx,5+dy,36+dx,31+dy),fill=base,outline=accent,width=3)
   d.ellipse((16+dx,11+dy,32+dx,23+dy),fill='#18384d')
   d.rectangle((13+dx,26+dy,35+dx,40+dy),fill=base,outline=accent,width=2)
   d.ellipse((19+dx,27+dy,29+dx,36+dy),fill=accent)
   if frame==3:d.polygon([(33,24),(47,18),(47,30)],fill=accent)
  elif shape=='medic':
   d.ellipse((14+dx,6+dy,33+dx,25+dy),fill='#d2dbc9')
   d.polygon([(11+dx,42+dy),(14+dx,24+dy),(34+dx,24+dy),(38+dx,42+dy)],fill=base)
   d.rectangle((21+dx,29+dy,27+dx,38+dy),fill=accent);d.rectangle((18+dx,32+dy,30+dx,35+dy),fill=accent)
   if frame==3:d.line((33,30,45,22),fill='#9bdbd2',width=4)
  else:
   d.ellipse((9+dx,12+dy,38+dx,39+dy),fill=base,outline=accent,width=3)
   d.ellipse((13+dx,7+dy,22+dx,18+dy),fill=accent)
   d.ellipse((28+dx,7+dy,37+dx,18+dy),fill=accent)
   d.rectangle((17+dx,26+dy,21+dx,30+dy),fill='#f1f3e3');d.rectangle((29+dx,26+dy,33+dx,30+dy),fill='#f1f3e3')
   if frame==3:d.line((33,30,45,23),fill=accent,width=4)
  d.rectangle((15+dx,39,21+dx,44),fill=accent);d.rectangle((29+dx,39,35+dx,44),fill=accent)
  im.save(ASSETS/f'{name}_{pose}.png')
  if frame<2:im.save(ASSETS/f'{name}_{frame}.png')
def boss_sprite(name,base,accent):
 im=Image.new('RGBA',(48,48));d=ImageDraw.Draw(im)
 d.polygon([(24,2),(40,12),(45,35),(33,45),(13,45),(3,32),(8,10)],fill=base,outline=accent)
 d.ellipse((12,19,21,28),fill=accent);d.ellipse((27,19,36,28),fill=accent)
 d.rectangle((14,35,34,39),fill='#202534')
 im.save(ASSETS/f'{name}.png')
HEROES={
 'goalie':('Frostguard','#2c6992','#c1e8f5','goalie','slash','block','ice_wall'),
 'navigator':('Star Navigator','#563e9f','#b8a9ff','astronaut','projectile','homing','beam'),
 'medic':('Quarantine Medic','#4d8068','#9ee8b4','medic','kick','heal_wave','trap'),
}
for ident,(name,base,accent,shape,primary,secondary,special) in HEROES.items():
 sprite(ident,base,accent,shape)
 p={'name':'Stick Slash' if ident=='goalie' else 'Pulse Bolt' if ident=='navigator' else 'Boot Kick','style':primary,'damage':26 if ident=='navigator' else 31,'cooldown':0.75 if ident=='navigator' else 0.42,'range':340 if ident=='navigator' else 86,'speed':480,'arc_degrees':70,'color':accent}
 s={'name':'Glove Reflect' if ident=='goalie' else 'Seeking Orb' if ident=='navigator' else 'Field Dressing','style':secondary,'damage':1 if ident=='goalie' else 27,'cooldown':3.4 if ident=='goalie' else 4.0,'range':95 if ident=='goalie' else 350,'speed':350,'duration':1.1,'reduction':0.9,'reflect':True,'color':accent}
 sp={'name':'Crease Wall' if ident=='goalie' else 'Orbital Beam' if ident=='navigator' else 'Healing Beacon','style':special,'damage':35 if ident=='goalie' else 76 if ident=='navigator' else 1,'cooldown':12.0,'radius':170 if ident=='goalie' else 500 if ident=='navigator' else 155,'duration':4,'color':accent}
 if ident=='goalie': sp.update(travel_speed=400,range=340,blast_radius=110)
 write('characters',ident,{'id':ident,'name':name,'sprite':ident,'max_health':155 if ident=='goalie' else 95 if ident=='navigator' else 125,'speed':205 if ident=='goalie' else 235,'primary':p,'secondary':s,'special':sp,'passive':'Guardian: 10% less damage' if ident=='goalie' else 'Cosmic focus: faster secondary' if ident=='navigator' else 'Triage: heal on kill','passive_effect':'guard' if ident=='goalie' else 'quick_secondary' if ident=='navigator' else 'heal_on_kill','run_cost':0})
ENEMIES=[
 ('frostling','Frostling','#91cae8','#e8fcff',74,105,11,'chase','ice'),
 ('ice_archer','Ice Archer','#337abc','#ceeefd',92,82,12,'ranged','ice'),
 ('glacier_hound','Glacier Hound','#628cb8','#e3f2ff',135,167,15,'charger','ice'),
 ('snow_oracle','Snow Oracle','#89bbdc','#f6fafd',115,72,11,'homing','ice'),
 ('drone','Patrol Drone','#63678e','#b3eeef',87,138,10,'ranged','space'),
 ('star_mine','Orbit Mine','#a17f4a','#e0dca2',120,56,19,'chase','space'),
 ('void_seeker','Void Seeker','#474164','#b57fe9',122,93,15,'homing','space'),
 ('shambler','Shambler','#577559','#aed37d',145,67,15,'chase','zombie'),
 ('spore_thrower','Spore Thrower','#856f4f','#d0c061',113,75,13,'dual_ranged','zombie'),
 ('hazmat_raider','Hazmat Raider','#b7a034','#e9de8e',154,108,17,'charger','zombie'),
]
for ident,name,base,accent,hp,speed,damage,behaviour,_ in ENEMIES:
 sprite(ident,base,accent)
 data={'id':ident,'name':name,'sprite':ident,'health':hp,'speed':speed,'damage':damage,'aggro_range':630,'behaviour':behaviour}
 if behaviour in ('ranged','dual_ranged','homing'):
  data.update(shot_speed=225 if behaviour=='homing' else 315,shot_cooldown=3.0 if behaviour=='homing' else 2.2,secondary_cooldown=4.5)
 write('enemies',ident,data)
BOSSES={
 'ice':('cryowarden','Cryowarden','#73a5d0','#e2f8ff','frostburst'),
 'space':('signal_core','Signal Core','#665cb9','#e6a9fa','seekerstorm'),
 'zombie':('plague_director','Plague Director','#546b37','#d4e971','sporeburst'),
}
for _,(ident,name,base,accent,secondary) in BOSSES.items():
 boss_sprite(ident,base,accent)
 write('bosses',ident,{'id':ident,'name':name,'sprite':ident,'secondary':secondary,'damage':28})
ITEMS=[
 ('iron_bark','Iron Bark',32,'armor',6,'Reduce each hit by 6.'),('guard_buckler','Guard Buckler',52,'block_boost',15,'Extend blocks and damage reduction.'),
 ('heart_locket','Heart Locket',85,'bonus_health',45,'Gain 45 maximum health.'),('swift_laces','Swift Laces',28,'bonus_speed',24,'Move faster.'),
 ('crit_charm','Crit Charm',48,'bonus_damage',8,'Add 8 damage to attacks.'),('vampire_pin','Vampire Pin',70,'lifesteal',10,'Heal for a tenth of damage dealt.'),
 ('mirror_shard','Mirror Shard',58,'reflect',1,'Reflect a projectile while blocking.'),('ice_bomb','Ice Bomb',26,'shockwave',38,'Blast nearby enemies.'),
 ('medkit','Field Medkit',35,'heal',65,'Restore 65 health.'),('aegis','Aegis Capsule',65,'invulnerable',3,'Ignore damage for 3 seconds.'),
 ('focus_lens','Focus Lens',82,'cooldown',14,'Reduce attack cooldowns by 14%.'),('gold_magnet','Bounty Magnet',44,'bounty',2,'Gain 2 extra gold per enemy kill.'),
 ('sprint_kit','Sprint Kit',22,'haste',1.6,'Short burst of speed.'),('thorn_coat','Thorn Coat',76,'thorns',9,'Damage nearby attackers.'),
 ('last_stand','Last Stand',100,'revive',1,'Prevent one defeat and restore 45 health.'),
]
for ident,name,cost,effect,amount,desc in ITEMS:
 write('items',ident,{'id':ident,'name':name,'cost':cost,'effect':effect,'amount':amount,'description':desc,'duration':3,'radius':145})
THEMES=[('ice','Frostbound Rink','ice','#baddea','#4d789e','ice_pillar',6200,['frostling','ice_archer','glacier_hound','snow_oracle'],'cryowarden',650,False),
 ('space','Orbital Breach','space','#171e3e','#5d4ca2','satellite',8200,['drone','star_mine','void_seeker'],'signal_core',1130,True),
 ('zombie','Hollow Quarantine','quarantine','#2f3930','#788e4d','barricade',8500,['shambler','spore_thrower','hazmat_raider'],'plague_director',1220,True)]
def deco(name,base,accent):
 im=Image.new('RGBA',(48,48));d=ImageDraw.Draw(im)
 d.rectangle((9,18,39,44),fill=base,outline=accent,width=3)
 d.polygon([(8,18),(24,3),(40,18)],fill=accent)
 d.line((14,31,33,31),fill='#f7f4df',width=2)
 im.save(ASSETS/f'{name}.png')
for ident,name,tile,bg,accent,obstacle,width,pool,boss,hp,hard in THEMES:
 deco(obstacle,accent,bg)
 # The first obstacle image also doubles as the ground texture in this prototype.
 Image.new('RGBA',(32,32),bg).save(ASSETS/f'{tile}.png')
 write('regions',ident,{'id':ident,'name':name,'size':[width,1450],'background':bg,'accent':accent,'boss_health':hp,'xp_per_level':6,'terrain':tile,'boss_secondary':BOSSES[ident][4],'scene':f'res://scenes/realms/{ident}.tscn','boss_sprite':boss,'difficulty':'hard' if hard else 'standard'})
 resources=[('1',f'{tile}.png'),('2','path.png'),('3','ram_0.png'),('4','portal.png'),('5','merchant.png'),('6',f'{boss}.png'),('7',f'{obstacle}.png')]
 for j,eid in enumerate(pool,8):resources.append((str(j),f'{eid}_idle.png'))
 out=['[gd_scene load_steps='+str(len(resources)+1)+' format=3]','']+[f'[ext_resource type="Texture2D" path="res://assets/{file}" id="{rid}"]' for rid,file in resources]
 def node(title,typ,parent,lines=None):out.extend(['',f'[node name="{title}" type="{typ}" parent="{parent}"]']+(lines or []))
 node(ident.capitalize(),'Node2D','',[]);out[-1]=f'[node name="{ident.capitalize()}" type="Node2D"]'
 node('Floor','Polygon2D','.',[f'polygon = PackedVector2Array(0, 0, {width}, 0, {width}, 1450, 0, 1450)',f'color = Color({int(bg[1:3],16)/255:.6f}, {int(bg[3:5],16)/255:.6f}, {int(bg[5:7],16)/255:.6f}, 1)'])
 node('GroundPaint','Node2D','.');node('Road','Polygon2D','GroundPaint',[f'polygon = PackedVector2Array(0, 650, {width}, 650, {width}, 800, 0, 800)','color = Color(0.55, 0.57, 0.60, 1)','metadata/tile = "path"'])
 node('Points','Node2D','.')
 for label,x,rid in [('Spawn',250,'3'),('ReturnGate',90,'4'),('Merchant',width//2,'5'),('Boss',width-300,'6')]:
  node(label,'Sprite2D','Points',[f'position = Vector2({x}, 725)',f'texture = ExtResource("{rid}")','scale = Vector2(2, 2)'])
 node('Enemies','Node2D','.')
 count=68 if hard else 54
 for n in range(count):
  eid=pool[(n*7+n//4)%len(pool)];x=620+n*(width-1100)//count;y=[400,1050,560,890,340,1120][n%6]
  node(f'Enemy_{n+1:03}','Sprite2D','Enemies',[f'position = Vector2({x}, {y})',f'texture = ExtResource("{8+pool.index(eid)}")','scale = Vector2(2, 2)',f'metadata/enemy_id = "{eid}"'])
 node('Obstacles','Node2D','.')
 for n in range(45):
  x=570+n*(width-900)//45;y=250 if n%2 else 1200
  node(f'{obstacle.capitalize()}_{n+1:02}','Sprite2D','Obstacles',[f'position = Vector2({x}, {y})','texture = ExtResource("7")','scale = Vector2(2, 2)',f'metadata/kind = "{obstacle}"','metadata/radius = 42.0'])
 (SCENES/f'{ident}.tscn').write_text('\n'.join(out)+'\n')
# Existing art receives 4 named frames; the two original frames stay for old submissions.
for category in ('characters','enemies'):
 for path in (CONTENT/category).glob('*.json'):
  data=json.loads(path.read_text());prefix=data.get('sprite'); p0=ASSETS/f'{prefix}_0.png'; p1=ASSETS/f'{prefix}_1.png'
  if not p0.exists() or not p1.exists():continue
  for pose,source in [('idle',p0),('walk1',p0),('walk2',p1),('attack',p1)]:
   target=ASSETS/f'{prefix}_{pose}.png'
   if not target.exists():
    im=Image.open(source).convert('RGBA');
    if pose=='walk1':im=im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    if pose=='attack':
     d=ImageDraw.Draw(im);d.line((im.width-13,im.height-22,im.width-2,im.height-29),fill='#fff2aa',width=3)
    im.save(target)
manifest=json.loads((CONTENT/'manifest.json').read_text())
for category in ('characters','enemies','items','regions'):
 for path in sorted((CONTENT/category).glob('*.json')):
  if path.stem!='town' and path.stem not in manifest[category]:manifest[category].append(path.stem)
manifest['characters']=['ram']+[p for p in manifest['characters'] if p!='ram']
(CONTENT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('Added',len(HEROES),'heroes,',len(ENEMIES),'enemies,',len(BOSSES),'bosses,',len(ITEMS),'items, and',len(THEMES),'realms')
from draw_enemy_variants import build as redraw_enemy_variants
redraw_enemy_variants()
