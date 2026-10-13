"""Original pixel hero and data for v45; safe to rerun for Rook and roster order."""
from pathlib import Path
from PIL import Image, ImageDraw
import json

ROOT = Path(__file__).resolve().parents[1]
hero = dict(
    id='rook', name='Rook Ironhand', sprite='rook', run_cost=0,
    max_health=125, speed=230,
    lore='A travelling bridge keeper with a brass gauntlet and a salvaged chain. Rook clears a path for others, one carefully timed swing at a time.',
    primary=dict(name='Chain Sweep', style='chain_sweep', damage=22, cooldown=.9,
                 range=210, arc_degrees=120, follow_bonus=8,
                 description='Extend a flail, sweep it through a 120-degree arc, then reel it back. Each enemy can take 22 damage once per swing; walls stop the chain. Successive swings alternate direction.'),
    secondary=dict(name='Grapnel Rush', style='grapnel_rush', damage=18, cooldown=6,
                   range=260, stun_duration=.6,
                   description='Throw a grapnel, then pull yourself smoothly up to 260 units forward. Enemies crossed take 18 damage and a 0.6-second stun. Walls stop your travel; this grants no invulnerability.'),
    special=dict(name='Iron Haul', style='iron_haul', damage=38, catch_damage=12,
                 cooldown=18, range=430, width=42, max_targets=4,
                 description='Send a hooked chain down a marked lane. Catch up to four enemies for 12 damage and a brief slow, drag them back, then deal 38 damage as the chain returns. Bosses resist the pull. In PvP, players are pulled at half speed.'),
    passive='Follow Through: hitting an enemy with Grapnel Rush empowers your next Chain Sweep within 4 seconds, adding 8 damage.',
    passive_effect='follow_through')
(ROOT/'content/characters/rook.json').write_text(json.dumps(hero,indent=2)+'\n')
path=ROOT/'content/manifest.json';manifest=json.loads(path.read_text())
roster=manifest['characters']
for key in ['medic','navigator']:
    roster.remove(key)
index=roster.index('welder')+1
roster[index:index]=['medic','navigator']
if 'rook' not in roster:roster.append('rook')
path.write_text(json.dumps(manifest,indent=2)+'\n')

for n,pose in enumerate(['idle','walk1','walk2','attack']):
    im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im)
    ink='#263440';coat='#42656d';edge='#83a49e';brass='#cba364';skin='#d4a47b';hair='#3d363a'
    b=[0,1,-1,0][n];left=[0,-2,2,0][n];right=-left
    # Sturdy boots, split travelling coat and brass belt.
    d.rectangle((21,46+left,28,59+left),fill='#45474b',outline=ink,width=2)
    d.rectangle((35,46+right,42,59+right),fill='#45474b',outline=ink,width=2)
    d.rectangle((19,56+left,29,61),fill=ink);d.rectangle((35,56+right,45,61),fill=ink)
    d.polygon([(19,26+b),(42,26+b),(47,49+b),(34,52+b),(30,45+b),(25,53+b),(17,49+b)],fill=coat,outline=ink,width=2)
    d.line((22,30+b,21,48+b),fill=edge,width=2);d.line((40,30+b,43,48+b),fill=edge,width=2)
    d.rectangle((20,40+b,43,44+b),fill='#674e43',outline=ink)
    d.rectangle((29,40+b,34,44+b),fill=brass)
    d.polygon([(24,29+b),(32,33+b),(39,28+b),(37,36+b),(31,39+b),(25,35+b)],fill='#eee1b6',outline=ink)
    # Human face with tied dark hair and a diagonal scar.
    d.rectangle((24,7+b,39,26+b),fill=skin,outline=ink,width=2)
    d.polygon([(22,17+b),(22,8+b),(27,3+b),(38,4+b),(43,12+b),(40,20+b),(37,9+b),(31,12+b),(24,12+b)],fill=hair,outline=ink)
    d.rectangle((40,12+b,45,23+b),fill=hair,outline=ink)
    d.rectangle((27,17+b,28,19+b),fill=ink);d.rectangle((35,17+b,36,19+b),fill=ink)
    d.line((35,20+b,38,23+b),fill='#b06b60');d.line((29,24+b,34,24+b),fill='#855e51')
    # Reinforced left glove; oversized right iron gauntlet carries the chain.
    d.polygon([(19,28+b),(13,33+b),(14,42+b),(20,43+b),(23,33+b)],fill=coat,outline=ink)
    d.rectangle((13,39+b,20,46+b),fill='#655c53',outline=ink,width=2)
    arm_x=43 if pose!='attack' else 47
    d.polygon([(39,28+b),(48,30+b),(arm_x+5,38+b),(arm_x,44+b),(39,39+b)],fill=coat,outline=ink)
    d.rectangle((arm_x-2,35+b,arm_x+8,47+b),fill=brass,outline=ink,width=2)
    d.line((arm_x,38+b,arm_x+6,38+b),fill='#eed3a2',width=2)
    for y in [40,44]:d.line((arm_x,y+b,arm_x+6,y+b),fill='#806646',width=1)
    for x,y in [(arm_x+6,48),(arm_x+3,52),(arm_x-1,55)]:d.ellipse((x-2,y-2,x+2,y+2),outline='#b2c8ca')
    d.ellipse((arm_x-8,51,arm_x+2,61),fill='#7b959e',outline=ink,width=2)
    if pose=='attack':d.line((5,23,12,19),fill='#ecd3a3',width=2)
    im.save(ROOT/f'assets/rook_{pose}.png')
    if n<2:im.save(ROOT/f'assets/rook_{n}.png')
print('Rook Ironhand created; Medic and Navigator follow Emberwright.')
