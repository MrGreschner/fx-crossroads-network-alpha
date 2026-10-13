"""Original object heroes and the Folded Coast; rerunnable content generator."""
from pathlib import Path
from PIL import Image, ImageDraw
import json, math
R=Path(__file__).resolve().parents[1]
def data(kind,key,value): (R/f'content/{kind}/{key}.json').write_text(json.dumps(value,indent=2)+'\n')
def move(name,style,damage,cooldown,**kw):return dict(name=name,style=style,damage=damage,cooldown=cooldown,**kw)
heroes={
'sunflower':dict(name='Sunpetal',max_health=100,speed=210,lore='A sunlit garden guardian who followed a lost dawn to the Crossroads.',primary=move('Bullet Seed','projectile',5,.75,count=4,spread=.12,range=360,speed=480,color='#b5dc79',bonus_split=True),secondary=move('Warmth Wave','heal_wave',0,9,heal=25,radius=180),special=move('Solarbeam','charged_beam',90,16,charge=2.5,width=140,range=620,description='Charge for 2.5 seconds, then fire a wide beam for 90 damage. Move slowly while charging; stunning interrupts it.'),passive='Sun-fed: recover 4 health after defeating an enemy.',passive_effect='heal_on_kill'),
'snowman':dict(name='Snowdrift',max_health=130,speed=200,lore='An abandoned snow sculpture determined to see every season.',primary=move('Snowball','projectile',18,.65,range=360,speed=360,color='#e9f7ff'),secondary=move('Ice Chill','chill_aura',0,10,duration=4,radius=145,slow=.55,reduction=.3,description='For 4 seconds, nearby enemies move 45% slower and you take 30% less damage.'),special=move('Rolling Snowball','rolling_snow',22,13,range=480,speed=250,description='A growing snowball explodes on impact: 22–58 damage, knockback, and six small snowballs dealing 5 damage each.'),passive='Packed Snow: take 10% less damage.',passive_effect='guard'),
'drum':dict(name='Backbeat',max_health=120,speed=205,lore='A forgotten marching drum with a heartbeat loud enough to wake a realm.',primary=move('Sound Wave','pulse_wave',14,.7,radius=105,wave_speed=260,description='An expanding sound ring hits enemies around you once for 14 damage.'),secondary=move('Triple Tempo','pulse_burst',8,6.5,radius=150,wave_speed=400,clear_projectiles=True,description='Three expanding pulses deal 8 damage each and erase hostile projectiles.'),special=move('Big Bang','pulse_wave',45,16,radius=280,wave_speed=500,stun=2,description='A huge sound ring deals 45 damage and stuns struck enemies for 2 seconds.'),passive='Drums of War: you and nearby allies deal 8% more damage within your 200-unit aura.',passive_effect='war_drums'),
'magnet':dict(name='Polarity',max_health=110,speed=220,lore='A living horseshoe magnet drawn to the strange forces between realms.',primary=move('Anchor Pin','magnet_pin',18,.8,range=340,speed=420,description='Fire a magnetic pin for 18 damage. It leaves an anchor for 8 seconds; keep up to two.'),secondary=move('Attraction','magnet_pull',22,5,radius=170,description='Pull enemies near your anchors toward them, dealing 22 damage and briefly slowing them.'),special=move('Live Wire','magnet_wire',9,14,description='Connect your two anchors for 3 seconds. The wire deals 9 damage every half-second; missing anchors are placed ahead.'),passive='Iron Resolve: take 10% less damage.',passive_effect='guard')}
for key,v in heroes.items():data('characters',key,dict(id=key,sprite=key,run_cost=0,**v))
for key,hp,speed,dmg in [('inkfin',55,95,8),('foldwing',65,110,9),('cartographer',780,0,12)]:data('enemies',key,dict(id=key,name=key.title(),sprite=key,health=hp,speed=speed,damage=dmg,behaviour='chase',aggro_range=650,expansion_only=True))
data('regions','folded_coast',dict(id='folded_coast',name='The Folded Coast',size=[6000,3200],terrain='space',scene='res://scenes/realms/folded_coast.tscn',boss_sprite='cartographer',boss_health=780,xp_per_level=3,boss_secondary='paper',difficulty_label='Medium: folding gates, ink pools and paper fans'))
for key in [*heroes,'inkfin','foldwing','cartographer']:
 for n,pose in enumerate(['idle','walk1','walk2','attack']):
  im=Image.new('RGBA',(48,48));d=ImageDraw.Draw(im);b=[0,1,-1,0][n];ink='#283047';d.ellipse((8,42,41,47),fill='#18233860')
  if key=='sunflower':
   d.line((24,24,24,42),fill='#5c9758',width=6);d.ellipse((6,30,23,39),fill='#79b061');d.ellipse((25,28,42,37),fill='#79b061')
   for j in range(10):
    x,y=24+13*math.cos(j*math.tau/10),19+b+13*math.sin(j*math.tau/10);d.ellipse((x-6,y-6,x+6,y+6),fill='#efc866',outline=ink)
   d.ellipse((14,9+b,34,29+b),fill='#916443',outline=ink)
  elif key=='snowman':
   d.ellipse((10,23,38,45),fill='#d2e5ef',outline=ink);d.ellipse((14,11+b,35,31+b),fill='#f0f7ef',outline=ink);d.rectangle((13,10+b,37,14+b),fill=ink);d.rectangle((19,0+b,31,11+b),fill='#475571');d.rectangle((14,26,36,30),fill='#aa6473');d.rectangle((31,29,35,39),fill='#aa6473');d.polygon([(24,19+b),(37,22+b),(24,24+b)],fill='#dfa35f');d.line((13,31,2,22+b),fill='#917051',width=3);d.line((36,31,46,23-b),fill='#917051',width=3)
  elif key=='drum':
   d.rectangle((8,15+b,40,36+b),fill='#a35262',outline=ink,width=2);d.ellipse((8,30+b,40,42+b),fill='#b88166',outline=ink);d.ellipse((8,10+b,40,24+b),fill='#e8d7b4',outline=ink,width=2)
   for x in [12,20,28,36]:d.line((x,22+b,x,35+b),fill='#edc478',width=2)
   d.line((4,5,24,17+b),fill='#c7a46c',width=3);d.line((43,4,29,16+b),fill='#c7a46c',width=3);d.rectangle((13,39,18,46),fill=ink);d.rectangle((31,39,36,46),fill=ink)
  elif key=='magnet':
   d.arc((7,1+b,41,44+b),0,180,fill=ink,width=13);d.arc((8,2+b,40,42+b),0,180,fill='#968ea5',width=9);d.rectangle((7,10+b,17,25+b),fill='#c35b69',outline=ink);d.rectangle((31,10+b,41,25+b),fill='#629acc',outline=ink);d.rectangle((7,7+b,17,13+b),fill='#d9e8e3');d.rectangle((31,7+b,41,13+b),fill='#d9e8e3')
  elif key=='inkfin':
   d.polygon([(24,6+b),(44,33),(27,27),(25,43),(21,28),(3,33)],fill='#725d92',outline=ink);d.line((24,19,24,35),fill='#b391d0',width=3)
  elif key=='foldwing':
   d.polygon([(1,6+b),(23,17),(47,5-b),(35,33),(25,41),(13,32)],fill='#ebe2bd',outline=ink);d.line((1,6+b,25,28,47,5-b),fill='#9f9a91',width=2);d.line((23,17,25,41),fill='#9f9a91',width=2)
  else:
   d.rectangle((8,8+b,39,37+b),fill='#e0d4b6',outline=ink,width=2);d.ellipse((5,5+b,13,39+b),fill='#b9aa92',outline=ink);d.ellipse((35,5+b,43,39+b),fill='#b9aa92',outline=ink);d.line((17,13,31,32,17,30,30,15),fill='#9c7cae',width=2);d.polygon([(24,0),(18,7),(24,12),(30,7)],fill='#cab47c',outline=ink)
  y=20+b if key in ['sunflower','snowman'] else 27+b
  for x in [19,29]:d.rectangle((x,y,x+2,y+3),fill=ink)
  if pose=='attack':d.ellipse((38,4,45,11),fill='#f4d781')
  im.save(R/f'assets/{key}_{pose}.png')
  if n<2:im.save(R/f'assets/{key}_{n}.png')
lines=['[gd_scene format=3]','[node name="FoldedCoast" type="Node2D"]','[node name="Points" type="Node2D" parent="."]']
for name,x,y in [('Spawn',450,1500),('ReturnGate',350,1500),('Merchant',750,1650),('Boss',5200,1500)]:lines.extend([f'[node name="{name}" type="Marker2D" parent="Points"]',f'position = Vector2({x},{y})'])
for folder in ['GroundPaint','Enemies','Obstacles','Decorations','Buildings']:lines.append(f'[node name="{folder}" type="Node2D" parent="."]')
for n in range(30):
 island=n//10;x=[850,2550,4750][island]+(n%3)*260;y=650+(n%10)*210
 lines.extend([f'[node name="Enemy{n}" type="Marker2D" parent="Enemies"]',f'position = Vector2({x},{y})',f'metadata/enemy_id = "{["inkfin","foldwing"][n%2]}"'])
(R/'scenes/realms/folded_coast.tscn').write_text('\n\n'.join(lines)+'\n')
p=R/'content/manifest.json';m=json.loads(p.read_text())
for key in heroes:
 if key not in m['characters']:m['characters'].append(key)
for key in ['inkfin','foldwing','cartographer']:
 if key not in m['enemies']:m['enemies'].append(key)
if 'folded_coast' not in m['regions']:m['regions'].insert(m['regions'].index('space'),'folded_coast')
p.write_text(json.dumps(m,indent=2)+'\n')
