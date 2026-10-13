from pathlib import Path
import json
from PIL import Image,ImageDraw
p=Path(__file__).resolve().parents[1]
def atk(n,s,d,c,r,text,**kw):return dict(name=n,style=s,damage=d,cooldown=c,range=r,description=text,**kw)
def mastery(title,a,b):return dict(title=title,technique=a,final_technique=b,technique_requirements=dict(clears=3,distinct_realms=2,damage=10000),title_requirements=dict(clears=6,distinct_realms=3,damage=20000),final_requirements=dict(clears=12,distinct_realms=6,damage=85000),crit_milestones=[dict(clears=i*3,chance=.02*i,bonus=.2*i) for i in range(1,4)])
def technique(n,slot,text,attack):return dict(name=n,ability=slot,description=text,attack=attack)
rider=dict(id='hollow_rider',sprite='hollow_rider',name='Hollow Rider',max_health=140,speed=215,run_cost=0,lore='An empty suit of armour carries a pumpkin lantern through Moonveil’s midnight roads. His spectral mare remembers every traveller he has guided home.',primary=atk('Lantern Reaping','grave_cleave',25,.65,95,'A short wind-up releases a forward scythe sweep for 25 damage. The green blade marks its actual reach.'),secondary=atk('Lantern Toll','grave_toll',26,7,125,'Raise the lantern for 0.3s, then slam a spectral shockwave: 26 damage, knockback and 1.2s stun within 125 reach.'),special=atk('Midnight Gallop','grave_ride',5,24,52,'Ride a spectral horse for 5s: +30% speed, +6 primary damage, and 5 hoof damage every 0.75s to nearby foes. No invulnerability.'),passive='Lantern Courage: hitting an enemy with Lantern Toll grants 12% damage reduction for 2 seconds.',passive_effect='lantern_courage')
rider['mastery']=mastery('Keeper of the Midnight Road',technique('Broad Reaping','primary','A wider sweep trades damage and attack speed for coverage.',atk('Broad Reaping','grave_cleave',19,.95,115,'A wider 115-reach scythe sweep deals 19 damage; 0.95s cooldown.')),technique('Last Watch','special','Trade mounted mobility for a targetable stationary guardian.',atk('Last Watch','grave_guardian',14,24,120,'A spectral horse guards the spot ahead for 6s: 70 health, 14 melee damage, 120 reach. It can be attacked and killed.')))
witch=dict(id='hazel_hex',sprite='hazel_hex',name='Hazel Hex',max_health=100,speed=225,run_cost=0,lore='Lantern Marsh’s kindly witch ties glowing embers to spinning spell-chains. Her broom delivers remedies—and a few surprises—to friends along the swamp roads.',primary=atk('Wickchain','witch_chain',18,.85,480,'A spinning chain fireball hits one foe for 18 damage and 35% slow for 2s. If it misses or hits a wall, it leaves a poison pool for 4s: 2 poison damage per second, 30% slow.'),secondary=atk('Broom Express','witch_flight',10,16,1100,'Fly toward the selected point, up to 1100 range along a clear route. Drop up to six warned bombs: 10 damage, 0.45s stun and 2 burn damage per second for 3s. Cannot attack or dodge during flight.'),special=atk('Neighbourhood Brew','witch_brew',8,25,240,'Place a cauldron for 7s. It lobs 8-damage poison splatters toward every visible foe within 310 reach every 1.0s, leaving slowing poison pools. Within 150 reach, allies gain +5% damage and 8% life-on-hit, capped at 6 healing per second. Auras do not stack; damage-over-time does not trigger healing.'),passive='Ember Infusion: Broom Express bomb burns last one extra second.',passive_effect='ember_infusion')
witch['mastery']=mastery('Mistress of the Lantern Coven',technique('Cold Wick','primary','Trade ground poison for a stronger direct hit and a greater slow.',atk('Cold Wick','witch_chain',23,.85,480,'23 direct damage and 50% slow for 2s. Missed shots leave slowing frost pools without poison.',frost=True)),technique('Welcoming Brew','special','Trade offensive splatters for steady healing. The support aura remains.',atk('Welcoming Brew','witch_brew',0,25,240,'A 7s cauldron heals allies within 150 reach for 3 health every 0.7s. Keeps its +5% damage and capped life-on-hit aura; fires no splatters.',gentle=True)))
m=json.loads((p/'content/manifest.json').read_text());lib=json.loads((p/'content/hero_library.json').read_text())
for hero in [rider,witch]:
 for slot,brief in zip(['primary','secondary','special'],{'hollow_rider': ['Melee sweep • 25 damage • 95 reach', 'Lantern slam • 26 damage • knockback + stun', 'Mounted form • 5 seconds • faster movement'], 'hazel_hex': ['One projectile • 18 damage + slow • poison on a miss', 'Long flight • up to six stunning, burning bombs', 'Cauldron • attacks all foes in range • allied aura']}[hero['id']]):hero[slot]['ui_brief']=brief
for h,role,tags,realm,summary in [(rider,'Melee',['Melee','Control'],'moonveil','Wind up a scythe, slam a spectral lantern and ride a ghostly horse.'),(witch,'Control',['Ranged','Control','Support'],'lantern_marsh','Spin poison shots, bomb a broom route and brew a helpful cauldron.')]:
 id=h['id'];(p/'content/characters'/f'{id}.json').write_text(json.dumps(h,indent=2)+'\n')
 if id not in m['characters']:m['characters'].append(id)
 lib[id]=dict(role=role,tags=tags,difficulty='Some practice' if id=='hollow_rider' else 'Technical',home_realm=realm,summary=summary,lore=h['lore'],passive_brief=h['passive'])
(p/'content/manifest.json').write_text(json.dumps(m,indent=2)+'\n');(p/'content/hero_library.json').write_text(json.dumps(lib,indent=2)+'\n');(p/'content/hero_numbers.json').write_text(json.dumps({id:i+1 for i,id in enumerate(m['characters'])},indent=2)+'\n')
for id in ['hollow_rider','hazel_hex','gravehorse']:
 for pose in ['idle','walk1','walk2','attack']:
  im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);dy=-1 if pose=='walk1' else 1 if pose=='walk2' else 0
  def rect(b,c):d.rectangle((b[0],b[1]+dy,b[2],b[3]+dy),fill=c)
  def poly(pts,c):d.polygon([(x,y+dy) for x,y in pts],fill=c)
  def ellipse(b,c):d.ellipse((b[0],b[1]+dy,b[2],b[3]+dy),fill=c)
  ink='#29333e'
  if id=='hazel_hex':
   poly([(20,31),(42,31),(48,52),(16,52)],ink);poly([(22,32),(40,32),(44,49),(19,49)],'#765193');rect((22,46,43,49),'#b790cd');rect((29,32,33,46),'#bca5d3')
   rect((21,52,27,60),ink);rect((36,52,42,60),ink);rect((19 if pose=='walk1' else 21,58,30,61),'#775c79');rect((36,58,46 if pose=='walk2' else 44,61),'#775c79')
   ellipse((19,14,44,40),'#c8834a');rect((18,26,24,43),'#c8834a');rect((39,25,45,43),'#c8834a');ellipse((23,18,40,35),'#f1d2af');rect((25,25,27,28),ink);rect((35,25,37,28),ink);rect((29,32,33,33),'#af6885')
   poly([(13,18),(24,6),(34,1),(40,14),(49,18)],ink);poly([(18,16),(26,8),(34,5),(37,14),(43,16)],'#644788');rect((12,17,49,21),'#82619c');rect((24,14,40,17),'#be8c45');rect((30,14,34,17),'#efc479')
   poly([(21,34),(13,39),(14,44),(25,38)],'#765193');rect((12,40,17,44),'#f1d2af');rect((44,36,50,43),'#f1d2af');rect((52,22,54,56),'#ac7e50');poly([(48,51),(59,51),(62,62),(45,62)],'#c9ac69');rect((47,52,59,54),'#89613b')
   if pose=='attack':ellipse((4,33,13,42),'#ef9853');rect((7,35,10,39),'#ffe0a0')
  elif id=='hollow_rider':
   poly([(18,20),(42,20),(47,52),(13,52)],'#416954');poly([(20,22),(41,22),(43,46),(16,46)],'#24433c');rect((21,45,28,59),ink);rect((35,45,42,59),ink);rect((18 if pose=='walk1' else 21,56,30,60),'#7f9394');rect((35,56,45 if pose=='walk2' else 42,60),'#7f9394')
   poly([(21,23),(40,23),(44,41),(18,41)],ink);poly([(24,25),(38,25),(40,38),(22,38)],'#879c9b');rect((24,29,38,31),'#b7c7bd');rect((22,39,40,44),'#645641');rect((29,39,33,43),'#ddbd72');rect((25,18,37,23),'#a9b6a7');ellipse((28,19,35,22),'#142f2c')
   ellipse((11,25,23,36),'#657e7e');ellipse((39,25,50,36),'#657e7e');rect((13,35,18,42),'#91a8a4');rect((46,35,50,41),'#91a8a4')
   rect((53,10,55,54),'#927e59');poly([(52,10),(41,7),(29,11),(34,13),(43,12),(52,16)],'#cff1d1');poly([(53,9),(43,6),(30,10),(33,11),(44,9),(53,13)],'#8fbd9a')
   ellipse((3,38,18,51),'#de9842');rect((9,36,12,39),'#6d8945');poly([(6,41),(9,41),(7,44)],ink);poly([(12,41),(15,41),(14,44)],ink);rect((7,46,14,47),'#fff1a1')
   if pose=='attack':d.arc((0,6,32,28),180,310,fill='#a3d9ac',width=2)
  else:
   ellipse((10,25,46,43),'#659f91');poly([(36,28),(41,10),(51,9),(54,27),(46,35)],'#91c8ae');poly([(42,10),(43,3),(47,10)],'#a4d6b6');ellipse((43,12,59,24),'#acdec2');rect((49,14,51,16),'#f5edb2');poly([(10,29),(4,24),(2,19),(3,35),(10,36)],'#8fc7b3')
   for i in range(4):
    x=15+i*8;step=3 if (i%2==0)==(pose=='walk1') else -3
    poly([(x,37),(x+4,37),(x+step+4,56),(x+step,56)],'#85b8a6');rect((x+step,55,x+step+5,58),'#c6e2bb')
  im.save(p/'assets'/f'{id}_{pose}.png')
  for alias in ([id,id+'_0'] if pose=='idle' else [id+'_1'] if pose=='walk1' else [id+'_2'] if pose=='walk2' else []):im.save(p/'assets'/f'{alias}.png')
