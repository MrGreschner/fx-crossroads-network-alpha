from pathlib import Path
from PIL import Image,ImageDraw
import json
R=Path(__file__).resolve().parents[1]
hero=dict(id='aurel',name='Aurel',sprite='aurel',run_cost=0,max_health=120,speed=225,lore='A copper-scaled star dragon, small enough to fit through a town gate and old enough to remember when the sky was closer.',primary=dict(name='Starfire Spiral',style='spiral_shot',damage=23,cooldown=.85,range=380,speed=390,curve=.8,color='#ffd397',description='Fire a curving starfire bolt for 23 damage. Successive bolts curve in alternating directions.'),secondary=dict(name='Wingbeat',style='waterfall_wave',damage=18,cooldown=4.5,radius=145,wave_speed=420,knockback=65,slow_duration=1,color='#eab782',description='Beat your wings to send an expanding gust around you: 18 damage, knockback and a one-second slow.'),special=dict(name='Skyfall Constellation',style='meteor_shower',damage=24,cooldown=18,range=230,radius=125,blast_radius=65,count=7,interval=.16,color='#ffd29a',description='Trace a glowing constellation ahead of you. Seven telegraphed meteors fall in sequence, each exploding for 24 damage within 65 units.'),passive='Afterglow: meteor explosions gain 12 units of radius.',passive_effect='wide_meteors')
hero["primary"]={'name': 'Starfire Breath', 'style': 'fire_breath', 'damage': 4, 'cooldown': 0.65, 'duration': 0.4, 'range': 170, 'arc_degrees': 24, 'burn_damage': 1, 'burn_duration': 3, 'color': '#ffc887', 'description': 'Breathe a narrow 24-degree stream of fire up to 170 units. Four ticks deal 4 damage each; hits refresh a burn for 1 damage per second over 3 seconds.'}
(R/'content/characters/aurel.json').write_text(json.dumps(hero,indent=2)+'\n');p=R/'content/manifest.json';m=json.loads(p.read_text())
if 'aurel' not in m['characters']:m['characters'].append('aurel')
p.write_text(json.dumps(m,indent=2)+'\n')
for n,pose in enumerate(['idle','walk1','walk2','attack']):
 im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);b=[0,1,-1,0][n];ink='#383341';copper='#bd8056';light='#e4ae74';wing='#825d77';wingy=6 if n==2 else 13
 d.polygon([(20,33+b),(4,wingy),(1,40),(9,35),(13,44),(23,43)],fill=wing,outline=ink);d.line((5,wingy+2,19,37),fill=light,width=2)
 d.polygon([(40,33+b),(59,wingy),(63,40),(55,35),(51,44),(39,43)],fill=wing,outline=ink);d.line((58,wingy+2,42,37),fill=light,width=2)
 d.polygon([(35,47),(52,48),(58,40),(60,48),(54,57),(39,56)],fill=copper,outline=ink)
 d.ellipse((18,26+b,44,55+b),fill=copper,outline=ink,width=2);d.ellipse((24,33+b,38,52+b),fill='#e0c68b')
 for y in [38,44,50]:d.line((26,y,36,y),fill='#b49a71')
 d.polygon([(19,12+b),(22,1+b),(29,10+b),(38,8+b),(44,1+b),(44,18+b),(48,26+b),(38,34+b),(24,33+b),(16,24+b)],fill=copper,outline=ink)
 d.polygon([(22,2+b),(24,13+b),(29,10+b)],fill='#ebd29f');d.polygon([(43,2+b),(37,10+b),(43,14+b)],fill='#ebd29f')
 d.polygon([(20,23+b),(27,27+b),(43,23+b),(41,31+b),(27,33+b)],fill=light)
 for x in [24,38]:d.rectangle((x,18+b,x+3,21+b),fill='#e8eabc');d.line((x+1,18+b,x+1,21+b),fill=ink)
 d.ellipse((31,25+b,36,28+b),fill=ink);d.rectangle((19,52,27,60-n%2),fill=copper,outline=ink);d.rectangle((37,52,45,60+n%2),fill=copper,outline=ink)
 d.polygon([(31,4),(33,7),(31,10),(29,7)],fill='#c0e8ee')
 if pose=='attack':
  d.ellipse((3,1,11,9),fill='#ffd291');d.ellipse((53,1,61,9),fill='#ffd291');d.line((7,0,7,10),fill='#f9eed6');d.line((56,0,56,10),fill='#f9eed6')
 im.save(R/f'assets/aurel_{pose}.png')
 if n<2:im.save(R/f'assets/aurel_{n}.png')
