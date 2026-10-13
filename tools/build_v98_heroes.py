"""Build two data-driven kits and matching procedural Crossroads sprite poses."""
from pathlib import Path
import json
from PIL import Image,ImageDraw
p=Path(__file__).resolve().parents[1]
def attack(name,style,damage,cooldown,reach,description,**extra):return dict(name=name,style=style,damage=damage,cooldown=cooldown,range=reach,description=description,**extra)
def mastery(title,first,final):
 return dict(title=title,technique=first,final_technique=final,technique_requirements=dict(clears=3,distinct_realms=2,damage=10000),title_requirements=dict(clears=6,distinct_realms=3,damage=20000),final_requirements=dict(clears=12,distinct_realms=6,damage=85000),crit_milestones=[dict(clears=n*3,chance=n*.02,bonus=n*.2) for n in range(1,4)])
def technique(name,ability,a,description):return dict(name=name,ability=ability,attack=a,description=description)
heroes={
 'wick':dict(name="Wick-o'-Wisp",max_health=105,speed=220,lore="A jack-o'-lantern from Lanternmarsh's autumn festival. Its brave little candle turns scary evenings into generous celebrations.",
 primary=attack('Cinder Candy','wick_fire',20,.85,410,'A visible fireball stops at the first enemy or wall: 20 damage, then burn for 2 damage/sec for 3 seconds.',speed=320,burn_duration=3,burn_damage=2,color='#ffac50'),
 secondary=attack('Scary Face','wick_face',0,7,170,'Foes in the visible forward fan are stunned for 1.1 seconds, then slowed 35% for 3 more seconds. Walls block the fright.',stun_duration=1.1),
 special=attack('Trick or Treat','wick_treats',6,22,260,'Lob 20 treats all around over 2 seconds. Each lands for 6 damage, bounces once for 6 more, then opens a three-second patch: slow, poison, burn, shock or allied healing. Small fields have distinct icons.',count=20),
 passive='Candle Light: three rotating overlapping circles boost allies\' existing critical bonus damage by 50% and healing received by 15%. Grants no critical chance; multiple lanterns do not stack.',passive_effect='candle_light',
 mastery=mastery('Keeper of the Last Candle',technique('Lantern Lance','primary',attack('Lantern Lance','wick_fire',28,1.15,480,'A heavier, longer-reaching ember for 28 damage with shorter, weaker burn. Slower recovery.',speed=380,burn_duration=2,burn_damage=1,color='#ffd285'),'Trade frequent burns for one heavier, longer-reaching shot.'),technique('Generous Goodies','special',attack('Generous Goodies','wick_treats',3,20,220,'Lob 16 bouncing treats. Only healing and slow patches; landing damage is halved.',count=16,goodies=True),'Trade poison, fire and shock for reliable allied healing and slows.'))),
 'cobbleclaw':dict(name='Cobbleclaw',max_health=145,speed=195,lore='A small masonry crab from Silverfall Reach, carrying a shell of polished river stones. It catches trouble in its claws and returns it with interest.',
 primary=attack('Pincer Ledger','crab_pincers',14,.85,88,'Two quick, visible claw snaps for 14 damage each. Both hit only their own short forward fans.'),
 secondary=attack('Shell Receipt','crab_shell',0,8,45,'Brace for 3.5 seconds with 50% damage reduction. Catch up to four hostile projectiles touching the shell; bank them for 12 seconds.',duration=3.5),
 special=attack('Crosswalk Crush','crab_crush',36,14,280,'Scuttle along the shown route, dealing 36 damage once per foe, pushing and slowing. At the end, spend banked shots on 12-damage stone shards. Walls stop the rush.'),
 passive='Shell Ledger: each banked projectile grants 3% damage reduction, up to 12%. Spend the bank or let it expire to lose this protection.',passive_effect='shell_ledger',
 mastery=mastery('Master of the Stone Ledger',technique('Heavy Accounts','primary',attack('Heavy Accounts','crab_pincers',22,1.35,112,'Two slower heavy snaps, 22 damage each, with longer reach.'),'Trade quick claw rhythm for heavier, slower snaps.'),technique('Pebble Nursery','secondary',attack('Pebble Nursery','crab_nursery',0,12,105,'Build a four-second stationary pebble refuge. Allies receive 20% damage reduction and 4 HP/sec, plus 1 HP/sec per banked shot consumed.'),'Trade projectile catching for a small allied refuge.'))) }
for id,h in heroes.items():
 h.update(id=id,sprite=id,run_cost=0);(p/'content/characters'/f'{id}.json').write_text(json.dumps(h,indent=2)+'\n')
m=json.loads((p/'content/manifest.json').read_text())
for id in heroes:
 if id not in m['characters']:m['characters'].append(id)
(p/'content/manifest.json').write_text(json.dumps(m,indent=2)+'\n')
(p/'content/hero_numbers.json').write_text(json.dumps({id:index+1 for index,id in enumerate(m['characters'])},indent=2)+'\n')
lib=json.loads((p/'content/hero_library.json').read_text())
lib['wick']=dict(role='Control',tags=['Ranged','Control','Support'],difficulty='Technical',home_realm='lantern_marsh',summary='Frighten groups, scatter mixed treat patches and amplify allied critical bonuses.',lore=heroes['wick']['lore'],passive_brief='Rotating candle aura: +50% critical bonus, +15% received healing.')
lib['cobbleclaw']=dict(role='Melee',tags=['Melee','Support','Control'],difficulty='Technical',home_realm='silverfall',summary='Catch shots in a stone shell, then scuttle through foes with a banked counterattack.',lore=heroes['cobbleclaw']['lore'],passive_brief='Each banked shot adds 3% damage reduction (max 12%).')
(p/'content/hero_library.json').write_text(json.dumps(lib,indent=2)+'\n')
for id in heroes:
 for pose in ['idle','walk1','walk2','attack']:
  im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);dy=-1 if pose=='walk1' else 1 if pose=='walk2' else 0
  def box(x,y,w,h,c):d.rectangle((x,y+dy,x+w-1,y+dy+h-1),fill=c)
  def oval(x,y,w,h,c):d.ellipse((x,y+dy,x+w-1,y+dy+h-1),fill=c)
  def poly(points,c):d.polygon([(x,y+dy) for x,y in points],fill=c)
  dark='#293d40'
  if id=='wick':
   box(20,46,8,12,dark);box(39,46,8,12,dark);box(17 if pose=='walk1' else 20,56,12,5,'#6e5748');box(38 if pose=='walk2' else 39,56,12,5,'#6e5748')
   poly([(16,22),(6,35),(8,45),(17,40)],'#719569');poly([(47,22),(59,33),(57,43),(47,38)],'#719569')
   oval(11,13,43,38,'#75433b');oval(13,14,39,35,'#cf6e37');oval(17,15,12,33,'#e98d3d');oval(29,14,12,35,'#ec9c48');oval(40,17,10,29,'#b95c31');box(27,8,9,10,'#638d60');box(29,5,5,9,'#8aa86a');poly([(33,9),(41,3),(46,6),(37,13)],'#719c68')
   poly([(20,24),(27,24),(24,17)],dark);poly([(37,24),(44,24),(40,17)],dark);poly([(22,23),(26,23),(24,20)],'#ffe8a0');poly([(38,23),(43,23),(40,20)],'#ffe8a0')
   poly([(19,31),(23,35),(28,31),(32,35),(37,31),(43,34),(40,41),(24,42)],dark);poly([(22,34),(27,36),(31,34),(36,37),(41,35),(38,39),(26,39)],'#ffd078')
   box(8,42,7,7,'#bf8d50');box(48,42,7,7,'#bf8d50')
   if pose=='attack':oval(49,31,13,13,'#ef9d45');poly([(53,35),(60,24),(62,36),(58,42)],'#ffd486')
   for x in [13,48]:box(x,19,1,8,'#f1ab54')
  else:
   for n,x in enumerate([12,20,42,50]):
    off=3 if pose=='walk1' and n%2 else -3 if pose=='walk2' and n%2 else 0
    poly([(x,38),(x+off-6,50),(x+off-10,54),(x+off-12,51),(x+off-7,46)],'#5b8f8b')
   oval(17,16,32,34,dark);oval(19,18,28,29,'#81948a');poly([(23,19),(33,14),(44,22),(39,34),(22,32)],'#b9b99d');poly([(23,34),(38,35),(44,43),(29,47),(20,42)],'#a9aa92');d.line((33,16+dy,30,34+dy),fill='#667c75',width=2);d.line((21,33+dy,42,35+dy),fill='#667c75',width=2)
   for x in [25,40]:box(x,9,3,15,'#648e82');oval(x-3,6,9,9,'#dde0bc');box(x,8,3,4,dark)
   for x,side in [(6,-1),(51,1)]:
    yy=20 if pose=='attack' else 29;oval(x,yy,12,19,'#b4b39b');poly([(x,yy+3),(x+side*3+6,yy-4),(x+10,yy+7),(x+5,yy+11)],'#d4c4a0');box(x+4,yy+11,5,6,'#72968b')
   box(26,41,14,4,'#d2c6aa')
  im.save(p/'assets'/f'{id}_{pose}.png')
  if pose=='idle':im.save(p/'assets'/f'{id}.png');im.save(p/'assets'/f'{id}_0.png')
  if pose=='walk1':im.save(p/'assets'/f'{id}_1.png')
