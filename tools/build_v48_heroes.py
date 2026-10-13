from pathlib import Path
from PIL import Image,ImageDraw
import json
R=Path(__file__).resolve().parents[1]
def ability(name,style,damage,cooldown,description,**kw):return dict(name=name,style=style,damage=damage,cooldown=cooldown,description=description,**kw)
heroes=[dict(id='beaver',name='Alderjaw',sprite='beaver',run_cost=0,max_health=140,speed=215,lore='An alder-bank beaver who builds bridges by daylight and fells corrupted timber by moonlight.',primary=ability('Bite','beaver_bite',28,.55,'Snap your incisors at enemies directly ahead within 90 units.'),secondary=ability('Tail Slap','tail_slap',26,6,'Sweep a broad paddle tail ahead: 26 damage, knockback and a 1.2s stun. Reach: 120.'),special=ability('Timber','timber_fall',65,18,'An upright tree shakes and falls over 1.1s, striking a 380-unit line for 65 damage and a 1.8s stun. Walls stop the fall; enemies can escape the warning.'),passive='Alder Armour: each different foe you stun grants 2% damage reduction for 8s, up to 20%. Stunning the same foe refreshes its stack.',passive_effect='alder_armour'),dict(id='teapot',name='Tumblebrew',sprite='teapot',run_cost=0,max_health=105,speed=235,lore='A runaway porcelain teapot whose mischievous woodland brew is delicious to friends and bitter to monsters.',primary=ability('Spout Shot','tea_shot',18,.85,'Pour two curling tea drops for 9 damage each. Hits poison for 1 damage per second over 4s; poison refreshes rather than stacks.',range=440,speed=360),secondary=ability('Tumble Pour','tumble_pour',12,7,'Hop three times along a 240-unit path in 0.9s, leaving three 3s poison puddles. Landing hits deal 12 damage once per foe; puddles poison for 1 damage/s. Walls stop you; you remain vulnerable.'),special=ability('Bitter Bloom','bitter_bloom',38,18,'Place a giant brewing cup up to 220 units ahead. After 1s it erupts across a 150-unit radius for 38 damage and poison (2 damage/s for 4s). Walls block the splash.'),passive='Fresh Pour: landing on a poisoned foe restores 2 health, once per different foe per Tumble Pour, up to 6 health.',passive_effect='fresh_pour')]
for hero in heroes:
 (R/f'content/characters/{hero["id"]}.json').write_text(json.dumps(hero,indent=2)+'\n')
 for n,pose in enumerate(['idle','walk1','walk2','attack']):
  im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);b=[0,-2,1,0][n];ink='#343d35'
  if hero['id']=='beaver':
   d.ellipse((35,30+b,61,57+b),fill='#79523c',outline=ink,width=2)
   for x in range(40,59,5):d.line((x,36+b,x-3,52+b),fill='#503f32',width=1)
   d.ellipse((13,23+b,46,55+b),fill='#916643',outline=ink,width=2);d.ellipse((20,31+b,40,50+b),fill='#c19564')
   d.ellipse((14,4+b,25,17+b),fill='#916643',outline=ink,width=2);d.ellipse((37,5+b,47,17+b),fill='#916643',outline=ink,width=2)
   d.ellipse((12,10+b,47,36+b),fill='#a1764d',outline=ink,width=2);d.ellipse((14,21+b,44,37+b),fill='#c8a374')
   d.rectangle((24,29+b,29,39+b),fill='#fff1c7',outline=ink);d.rectangle((30,29+b,35,39+b),fill='#fff1c7',outline=ink)
   d.ellipse((25,22+b,34,28+b),fill=ink)
   for x in [20,38]:d.rectangle((x,17+b,x+3,21+b),fill=ink);d.point((x,17+b),fill='#fff4d9')
   d.rectangle((13,48,24,59-n%2),fill='#69513d',outline=ink);d.rectangle((32,48,43,59+n%2),fill='#69513d',outline=ink)
   d.line((14,28+b,11,44+b),fill='#916643',width=7);d.line((44,28+b,47,44+b),fill='#916643',width=7)
   d.line((15,33+b,44,33+b),fill='#799b6b',width=3)
   if pose=='attack':d.arc((8,15,50,47),15,145,fill='#fff1c7',width=3)
  else:
   d.ellipse((12,21+b,46,53+b),fill='#efe7ce',outline=ink,width=2)
   d.ellipse((13,30+b,46,53+b),fill='#bacdbb');d.arc((44,22+b,61,43+b),260,100,fill=ink,width=7);d.arc((44,22+b,61,43+b),260,100,fill='#e1dabc',width=3)
   d.polygon([(14,29+b),(3,18+b),(3,11+b),(8,12+b),(19,22+b)],fill='#efe7ce',outline=ink)
   d.ellipse((12,15+b,46,25+b),fill='#799b6b',outline=ink,width=2);d.rectangle((25,10+b,33,16+b),fill='#e6d09e',outline=ink)
   for x in [22,35]:d.rectangle((x,29+b,x+3,33+b),fill=ink)
   d.arc((24,34+b,35,40+b),0,180,fill=ink,width=2)
   d.rectangle((18,49+b,25,57+b),fill='#806648',outline=ink);d.rectangle((34,49+b,41,57+b),fill='#806648',outline=ink)
   d.ellipse((19,38+b,24,44+b),fill='#92b870');d.ellipse((35,38+b,40,44+b),fill='#92b870')
   if pose=='attack':d.ellipse((0,4,6,10),fill='#b2d774')
  im.save(R/f'assets/{hero["id"]}_{pose}.png')
  if n<2:im.save(R/f'assets/{hero["id"]}_{n}.png')
p=R/'content/manifest.json';m=json.loads(p.read_text());order=[x for x in m['characters'] if x not in ['beaver','teapot','garrick']]
order.insert(order.index('rune_duelist')+1,'garrick');order.insert(order.index('nera')+1,'teapot');order.insert(order.index('iris'),'beaver');m['characters']=order;p.write_text(json.dumps(m,indent=2)+'\n')
print('32 heroes: Alderjaw before Iris; Tumblebrew after Nera; Garrick after Rune Duelist.')
