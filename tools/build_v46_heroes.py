"""v46 hero data and original code-drawn pixel poses (no source-image edits)."""
from pathlib import Path
from PIL import Image, ImageDraw
import json
R=Path(__file__).resolve().parents[1]
def update(key,change):
 p=R/f'content/characters/{key}.json';d=json.loads(p.read_text());change(d);p.write_text(json.dumps(d,indent=2)+'\n')
for key,visual in [('ram','horns'),('basketball','bounce'),('book','paper_cut'),('cat','scratch')]:
 update(key,lambda d,v=visual:d['primary'].update(style='identity_strike',visual=v))
for key in ['basketball','goalie','medic']:update(key,lambda d:d['primary'].update(damage=29))
update('ram',lambda d:d['primary'].update(description='Headbutt with a close pair of horn impacts: 28 damage, 82 reach, 70-degree arc.'))
update('basketball',lambda d:d['primary'].update(description='Bounce forward for a narrow close hit: 29 damage, 88 reach, 40-degree arc.'))
update('cat',lambda d:d['primary'].update(description='Sweep three claws across a close 65-degree arc: 22 damage, 86 reach. Each enemy is hit once.'))
update('basketball',lambda d:d['secondary'].update(style='body_bounce',damage=28,cooldown=5,description='Bounce your whole body quickly between up to three different enemies: 28 damage each. First target within 350 units; later jumps within 260. Walls stop travel. You can still take damage.'))
update('book',lambda d:d['primary'].update(description='Slash a sharp paper edge in a close 105-degree arc: 25 damage, 86 reach.'))
update('book',lambda d:d['secondary'].update(style='page_channel',damage=11,cooldown=.35,range=460,description='Hold secondary to open the book and release seeking pages every 0.22s, each for 11 damage. You cannot move or dodge and take 30% more damage while open. Release to stop.'))
update('cat',lambda d:d['secondary'].update(style='cat_sweep',description='Sweep your claws around yourself over 0.6s. Each enemy within 128 reach takes 43 damage once when the moving sweep reaches it. Walls block the swipe.'))
hero=dict(id='iris',name='Iris Chalkbinder',sprite='iris',run_cost=0,max_health=105,speed=235,
 lore='A travelling tutor who carries enchanted chalk and turns forgotten lessons into pathways of light.',
 primary=dict(name='Chalkstroke',style='chalkstroke',damage=16,cooldown=.7,range=250,duration=4,description='Draw a 250-unit chalk line over 0.45s. It lasts 4s and damages each enemy touching it once for 16. Keep up to three lines; walls stop the drawing.'),
 secondary=dict(name='Erase & Release',style='erase_release',damage=12,cooldown=7,description='Erase your chalk lines. Each releases two seeking chalk shards for 12 damage each. With no lines, release one shard.'),
 special=dict(name='Living Blackboard',style='chalk_grid',damage=7,cooldown=18,range=180,duration=4,description='Draw a 300 by 220 grid ahead for 4s. Enemies inside move 35% slower and take 7 damage every half-second. Walls block its damage.'),
 passive='Second Draft: Erase & Release heals you for 3 health per erased line.',passive_effect='second_draft')
(R/'content/characters/iris.json').write_text(json.dumps(hero,indent=2)+'\n')
p=R/'content/manifest.json';m=json.loads(p.read_text())
if 'iris' not in m['characters']:m['characters'].append('iris')
p.write_text(json.dumps(m,indent=2)+'\n')

# Fresh attack poses preserve the original four heroes' small silhouettes/colors.
ink='#35434a'
for key in ['ram','basketball','book','cat']:
 im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im)
 if key=='ram':
  d.rectangle((21,44,28,60),fill='#735f4f');d.rectangle((36,44,43,60),fill='#735f4f')
  d.polygon([(18,31),(43,31),(46,47),(19,48)],fill='#71958b',outline=ink,width=2)
  d.rectangle((19,23,47,35),fill='#e4ddc9',outline=ink,width=2)
  d.polygon([(24,12),(39,10),(48,18),(48,30),(24,32),(18,24)],fill='#f0e9d5',outline=ink,width=2)
  for x in [18,44]:d.arc((x-9,9,x+9,28),10,340,fill='#a88759',width=6)
  d.rectangle((35,18,39,22),fill=ink);d.rectangle((43,25,48,28),fill='#b89182')
  d.line((12,31,3,34),fill='#c6ddd7',width=3);d.line((12,39,2,43),fill='#c6ddd7',width=3)
 elif key=='basketball':
  d.rectangle((19,45,25,56),fill='#88745e');d.rectangle((39,45,45,56),fill='#88745e')
  d.ellipse((9,15,55,46),fill='#d9893d',outline=ink,width=3)
  d.arc((9,15,55,46),40,170,fill='#f3b366',width=4)
  d.line((10,30,54,30),fill='#654c3c',width=2);d.arc((22,13,42,48),80,270,fill='#654c3c',width=2)
  d.rectangle((23,23,27,27),fill=ink);d.rectangle((39,23,43,27),fill=ink)
  d.arc((26,29,41,39),0,180,fill=ink,width=2)
  for x in [18,32,46]:d.line((x,3,x-2,11),fill='#efc793',width=2)
 elif key=='book':
  d.polygon([(16,17),(43,14),(48,48),(19,52)],fill='#b49064',outline=ink,width=2)
  d.polygon([(20,19),(42,17),(45,46),(23,49)],fill='#e9dfbf',outline=ink)
  d.rectangle((25,24,28,28),fill=ink);d.rectangle((36,23,39,27),fill=ink)
  d.line((28,35,36,34),fill=ink,width=2)
  d.polygon([(34,34),(60,26),(59,37),(38,44)],fill='#f5eecf',outline='#8aafb5',width=2)
  d.line((38,37,54,32),fill='#9baca7',width=1)
  d.rectangle((22,51,29,60),fill='#77634c');d.rectangle((38,50,45,59),fill='#77634c')
 else:
  d.rectangle((22,43,28,60),fill='#62544a');d.rectangle((37,43,43,60),fill='#62544a')
  d.polygon([(19,27),(43,27),(49,48),(18,48)],fill='#8e684b',outline=ink,width=2)
  d.polygon([(16,24),(18,7),(28,13),(38,12),(48,7),(49,28),(41,33),(22,32)],fill='#dfcfaf',outline=ink,width=2)
  d.polygon([(20,10),(26,15),(21,18)],fill='#dcae9a');d.polygon([(46,10),(40,15),(45,18)],fill='#dcae9a')
  d.rectangle((26,20,29,23),fill=ink);d.rectangle((39,20,42,23),fill=ink)
  d.polygon([(32,25),(36,25),(34,28)],fill='#a88178')
  d.line((18,32,8,39),fill='#dfcfaf',width=5);d.line((44,31,56,25),fill='#dfcfaf',width=5)
  for y in [21,26,31]:d.line((50,y,61,y-5),fill='#c9efe0',width=2)
 im.save(R/f'assets/{key}_attack.png')

im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im)
d.polygon([(5,16),(28,12),(32,18),(36,12),(59,16),(57,49),(36,46),(32,51),(28,46),(7,49)],fill='#a28260',outline=ink,width=2)
d.polygon([(9,19),(27,16),(30,21),(30,45),(10,45)],fill='#f1e6c5',outline='#897b60')
d.polygon([(34,21),(38,16),(55,19),(54,45),(34,45)],fill='#f1e6c5',outline='#897b60')
for y in [25,30,35]:d.line((13,y,26,y-2),fill='#85999a');d.line((38,y-2,51,y),fill='#85999a')
d.rectangle((19,38,22,41),fill=ink);d.rectangle((43,38,46,41),fill=ink)
d.rectangle((20,50,26,60),fill='#77634c');d.rectangle((40,50,46,60),fill='#77634c')
im.save(R/'assets/book_open.png')
im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im)
d.arc((7,7,56,57),20,320,fill='#9a7354',width=9)
d.ellipse((15,20,49,48),fill='#8e684b',outline=ink,width=2)
d.polygon([(18,23),(18,9),(28,15),(38,15),(47,9),(48,26),(39,33),(26,32)],fill='#dfcfaf',outline=ink,width=2)
d.rectangle((26,22,29,25),fill=ink);d.rectangle((39,22,42,25),fill=ink)
d.line((12,44,5,34),fill='#dfcfaf',width=6);d.line((51,38,59,29),fill='#dfcfaf',width=6)
im.save(R/'assets/cat_spin.png')

for n,pose in enumerate(['idle','walk1','walk2','attack']):
 im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);b=[0,1,-1,0][n]
 d.rectangle((21,46,28,60-n%2),fill='#425967',outline=ink);d.rectangle((36,46,43,60+n%2),fill='#425967',outline=ink)
 d.polygon([(20,26+b),(42,26+b),(48,51),(16,51)],fill='#547668',outline=ink,width=2)
 d.line((26,30,23,48),fill='#a8c8af',width=2);d.line((37,30,42,48),fill='#a8c8af',width=2)
 d.rectangle((24,40,41,43),fill='#897956');d.rectangle((32,40,35,43),fill='#e5d6a6')
 d.ellipse((21,5+b,43,28+b),fill='#c69978',outline=ink,width=2)
 d.polygon([(19,18+b),(20,8+b),(27,2+b),(41,5+b),(47,21+b),(44,34),(39,30),(40,13+b),(31,10+b),(23,15+b),(22,30)],fill='#403f55',outline=ink)
 d.rectangle((26,17+b,28,20+b),fill=ink);d.rectangle((35,17+b,37,20+b),fill=ink);d.line((29,24+b,34,24+b),fill='#976653')
 d.line((17,30,13,42),fill='#547668',width=8);d.rectangle((10,40,17,47),fill='#c69978',outline=ink)
 x=51 if pose=='attack' else 46
 d.line((42,30,x,36),fill='#547668',width=8);d.ellipse((x-4,34,x+3,41),fill='#c69978',outline=ink)
 d.rectangle((x,29,x+4,36),fill='#eee7cb',outline='#89afa5')
 d.rectangle((15,39,22,48),fill='#c3b590',outline=ink)
 if pose=='attack':d.arc((42,16,61,47),240,340,fill='#d4edca',width=2)
 im.save(R/f'assets/iris_{pose}.png')
 if n<2:im.save(R/f'assets/iris_{n}.png')
print('Original heroes revamped; Iris Chalkbinder added as hero 29.')
