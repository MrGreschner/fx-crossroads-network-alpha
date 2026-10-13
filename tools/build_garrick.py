from pathlib import Path
from PIL import Image,ImageDraw
import json
R=Path(__file__).resolve().parents[1]
hero=dict(id='garrick',name='Garrick Runebearer',sprite='garrick',run_cost=0,max_health=125,speed=225,
 lore='A wandering male rune smith with a weathered beard and a hammer inscribed with three old promises: courage, swiftness and shelter.',
 primary=dict(name='Rune Hammer',style='rune_hammer',damage=24,cooldown=.8,range=400,speed=430,splash_radius=65,splash_damage=8,
 description='Throw a spinning rune hammer for 24 damage. Walls stop it. Splash reaches 65 units around the impact.'),
 secondary=dict(name='Threefold Oath',style='rune_cycle',damage=0,cooldown=6,duration=4.5,
 description='Each use grants the next rune for 4.5s: Might (+20% damage), Stride (+30% movement), then Ward (35% less damage taken). Only one rune is active at a time. The next rune is shown beside you.'),
 special=dict(name='Triune Verdict',style='triune_verdict',damage=28,cooldown=20,range=240,
 description='Mark a spot ahead. After warnings: a 24-damage hammer seal knocks foes back; a 28-damage crosscut slows; a 38-damage final ring stuns for 0.65s. Each strike has its own area; walls block damage.'),
 passive='Purifying Rune: activating Ward removes burn, bleeding and poison from Garrick.',passive_effect='purifying_rune')
(R/'content/characters/garrick.json').write_text(json.dumps(hero,indent=2)+'\n')
p=R/'content/manifest.json';m=json.loads(p.read_text())
if 'garrick' not in m['characters']:m['characters'].append('garrick')
p.write_text(json.dumps(m,indent=2)+'\n')
for n,pose in enumerate(['idle','walk1','walk2','attack']):
 im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);b=[0,1,-1,0][n];ink='#303a49';skin='#c39777';hair='#725447';gold='#d5b57a'
 d.rectangle((19,44,28,60-n%2),fill='#514a47',outline=ink,width=2);d.rectangle((36,44,45,60+n%2),fill='#514a47',outline=ink,width=2)
 d.polygon([(17,26+b),(45,26+b),(50,48),(14,48)],fill='#49596d',outline=ink,width=2)
 d.rectangle((21,28+b,41,42+b),fill='#98aaad',outline=ink,width=2)
 d.line((25,31+b,38,38+b),fill='#cee0d8',width=2);d.rectangle((19,40,45,44),fill='#705441',outline=ink)
 d.rectangle((29,40,35,45),fill=gold,outline=ink)
 d.polygon([(19,29+b),(12,26+b),(10,35+b),(19,38+b)],fill='#a7b6b7',outline=ink)
 d.polygon([(43,29+b),(51,26+b),(54,35+b),(44,38+b)],fill='#a7b6b7',outline=ink)
 d.ellipse((20,6+b,44,29+b),fill=skin,outline=ink,width=2)
 d.polygon([(20,18+b),(20,8+b),(26,3+b),(39,4+b),(45,10+b),(44,19+b),(38,12+b),(26,13+b)],fill=hair,outline=ink)
 d.polygon([(22,23+b),(28,24+b),(32,22+b),(38,24+b),(43,22+b),(40,32+b),(31,35+b),(24,30+b)],fill=hair,outline=ink)
 d.line((27,27+b,35,29+b),fill='#9e7d64',width=2);d.line((26,16+b,30,16+b),fill=ink,width=2);d.line((36,16+b,40,16+b),fill=ink,width=2)
 d.rectangle((27,18+b,29,20+b),fill='#dce3d3');d.rectangle((37,18+b,39,20+b),fill='#dce3d3')
 d.line((15,35+b,13,46+b),fill='#49596d',width=8);d.ellipse((8,43+b,17,51+b),fill=skin,outline=ink)
 x=54 if pose=='attack' else 49
 d.line((48,35+b,x,42+b),fill='#49596d',width=8);d.ellipse((x-5,40+b,x+3,47+b),fill=skin,outline=ink)
 d.line((x,26,x,52),fill='#8b6745',width=5);d.rectangle((x-10,19,x+9,31),fill='#b6c7ca',outline=ink,width=2)
 d.polygon([(x-2,21),(x+3,25),(x-2,29),(x-6,25)],fill=gold,outline='#6d7778')
 for j,color in enumerate(['#efb976','#86dac4','#a3c9ed']):d.rectangle((20+j*10,45,23+j*10,48),fill=color)
 if pose=='attack':d.arc((38,9,62,37),210,320,fill='#edcf8c',width=2)
 im.save(R/f'assets/garrick_{pose}.png')
 if n<2:im.save(R/f'assets/garrick_{n}.png')
print('Garrick Runebearer, male hero 30, created.')
