from pathlib import Path
from PIL import Image,ImageDraw
import json
R=Path(__file__).resolve().parents[1]
d=dict(id='bracken',name='Bracken',sprite='bracken',max_health=115,speed=245,run_cost=0,lore='A fox sapper who protects the frontier with buried moonstones and a very short fuse.',primary=dict(name='Moonstone Mines',style='manual_mines',damage=38,cooldown=.65,range=100,radius=95,duration=12,color='#edbf77',description='Clicks one and two plant a mine nearby in your aim direction. Click three detonates both for 38 damage each within 95 units. Mines expire after 12 seconds.'),secondary=dict(name='Burrow Bloom',style='ground_sequence',damage=12,cooldown=5.5,count=3,spacing=85,interval=.24,radius=65,slow_duration=1.5,color='#c9a4eb',description='Three ground eruptions advance along your aim. Each deals 12 damage and slows enemies for 1.5 seconds.'),special=dict(name='Faultline',style='ground_sequence',damage=19,cooldown=16,count=6,spacing=85,interval=.18,radius=72,stun=.6,color='#edd6a0',description='Six eruptions tear a faultline ahead of you, each dealing 19 damage and briefly stunning enemies. Walls stop the sequence.'),passive='Wide Fuse: mine explosions gain 20 units of radius.',passive_effect='wide_mines')
d["special"]={'name': 'Foxfire Escape', 'style': 'blink_bomb', 'damage': 62, 'cooldown': 15, 'range': 280, 'radius': 115, 'fuse': 1, 'color': '#edbf77', 'description': 'Teleport up to 280 units along your aim, stopping before walls. Leave a glowing bomb at your old position; after 1 second it explodes for 62 damage within 115 units.'}
(R/'content/characters/bracken.json').write_text(json.dumps(d,indent=2)+'\n');p=R/'content/manifest.json';m=json.loads(p.read_text())
if 'bracken' not in m['characters']:m['characters'].append('bracken')
p.write_text(json.dumps(m,indent=2)+'\n')
for n,pose in enumerate(['idle','walk1','walk2','attack']):
 im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);b=[0,1,-1,0][n];ink='#343440'
 d.polygon([(40,41),(55,33),(61,18),(51,21),(43,30),(34,33)],fill='#ba764e',outline=ink);d.polygon([(55,33),(61,18),(51,21)],fill='#eadbb4')
 d.rectangle((20,33+b,42,51+b),fill='#668272',outline=ink,width=2);d.rectangle((20,49,26,60-n%2),fill=ink);d.rectangle((36,49,42,59+n%2),fill=ink)
 d.polygon([(14,16+b),(15,2+b),(28,12+b),(38,9+b),(49,3+b),(47,23+b),(38,37+b),(24,36+b),(13,26+b)],fill='#c48657',outline=ink)
 d.polygon([(16,5+b),(17,16+b),(25,13+b)],fill='#e4c2a4');d.polygon([(46,7+b),(39,14+b),(45,19+b)],fill='#e4c2a4')
 d.polygon([(15,24+b),(28,28+b),(43,24+b),(38,35+b),(25,36+b)],fill='#eddfbe');d.ellipse((26,26+b,33,31+b),fill=ink)
 for x in [21,38]:d.rectangle((x,20+b,x+3,23+b),fill=ink)
 d.line((19,39+b,42,46+b),fill='#b59b69',width=4);d.rectangle((12,37+b,20,48+b),fill='#856947',outline=ink)
 d.ellipse((44,40+b,55,50+b),fill='#ccb483',outline=ink);d.line((50,40+b,51,35+b,55,34+b),fill='#d8ceac',width=2)
 if pose=='attack':d.ellipse((53,29,57,33),fill='#ffda85')
 im.save(R/f'assets/bracken_{pose}.png')
 if n<2:im.save(R/f'assets/bracken_{n}.png')
