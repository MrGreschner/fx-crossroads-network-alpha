"""Rebuild v79's two complete hero definitions and matching low-resolution sprites."""
from pathlib import Path
import json, math
from PIL import Image, ImageDraw
root=Path(__file__).resolve().parents[1]
def attack(name,style,damage,cooldown,description,**kw):return dict(name=name,style=style,damage=damage,cooldown=cooldown,description=description,**kw)
base=json.loads((root/'content/characters/ripplejaw.json').read_text())['mastery']
snail=dict(id='snail',name='Molten Pilgrim',sprite='snail',max_health=165,speed=75,run_cost=0,lore='A volcanic snail carrying a living furnace. Crawling is painfully slow and dodge travels only 28% as far. Learn to aim Shellbound from one lava patch to the next; the airborne arc is visible, but does not make you invulnerable.',primary=attack('Furnace Breath','magma_breath',54,1.15,'A short lava burst hits a narrow 130-range cone for 54 damage, burns for 2 per second for 3s, and leaves small lava patches.',range=130,color='#ff8232'),secondary=attack('Shellbound','shell_lob',32,4,'Curl up and lob yourself to the aimed spot, up to 460 away, over 0.8s. Land for 32 splash damage and leave lava. Walls stop travel; you remain vulnerable in flight.',range=460,color='#ff8232'),special=attack('Backdraft Volcano','back_volcano',12,20,'For 6s, your shell erupts with two lava balls every 0.5s. Each lands for 12 damage and leaves lava. Overlapping lava patches do not stack their damage.',color='#ff8232'),passive='Melting Presence: Enemies within 155 lose up to 40 percentage points of damage reduction (60% becomes 20%). Cannot reduce protection below zero or cancel invulnerability. Does not stack with another snail.',passive_effect='melting_presence')
kite=dict(id='kite',name='Kite Corsair',sprite='kite',max_health=100,speed=280,run_cost=0,lore='A sky smuggler riding a patched sail. Movement builds momentum and banks gradually; release movement to brake. The small blue gauge shows how much extra force your next Sail Needle carries.',primary=attack('Sail Needle','sail_needle',18,.65,'Fire a fast wind needle for 18 damage, plus up to 12 more from your actual gliding speed. The first foe or wall stops it.',range=520,color='#b5efff'),secondary=attack('Windlass Swing','windlass_swing',28,5,'Hook a wind anchor and swing along a curved path toward the aimed point, up to 360 away. Touching foes take 28 damage once. Walls interrupt the swing.',range=360,color='#b5efff'),special=attack('Storm Delivery','storm_delivery',42,16,'Three parachute parcels land around your aim point after staggered warnings. Each blasts for 42 and pushes foes away. Their wind pads grant allies 20% speed for 1.5s while crossed.',range=430,color='#b5efff'),passive='Updraft Reserve: Completing Windlass Swing grants 15% damage reduction for 2s.',passive_effect='updraft_reserve')
for d in [snail,kite]:
 m=json.loads(json.dumps(base))
 if d is snail:
  m['title']='Keeper of the Living Caldera'
  m['technique']=dict(name='Long Migration',ability='secondary',description='Shellbound reaches 600 instead of 460, but its impact drops from 32 to 20 damage.',set=dict(range=600,damage=20))
  m['final_technique']=dict(name='Caldera Crown',ability='special',description='Replace the moving 6s volcano with a warned ring eruption around your current spot. Deals 60 once per foe and leaves eight lava patches for 6s; the centre is safe.',attack=attack('Caldera Crown','caldera_ring',60,20,'Warn for 0.75s, then erupt an eight-patch lava ring at 120 radius. A foe hit by overlapping patches takes the initial 60 only once. Lava lasts 6s.',color='#ff8232'))
 else:
  m['title']='Captain of the Unbroken Wind'
  m['technique']=dict(name='Long Tack',ability='secondary',description='Windlass Swing reaches 480 instead of 360, but deals 18 instead of 28 damage.',set=dict(range=480,damage=18))
  m['final_technique']=dict(name='Headwind Harpoon',ability='primary',description='Replace momentum-powered needles with 26-damage harpoons. They pull foes slightly and slow them for 1.5s, but fire more slowly and gain no movement damage.',attack=attack('Headwind Harpoon','headwind_harpoon',26,.9,'Fire a harpoon for 26 damage, pulling a hit foe 35 toward you and slowing it by 40% for 1.5s. No momentum bonus.',range=470,color='#b5efff'))
 d['mastery']=m;(root/f'content/characters/{d["id"]}.json').write_text(json.dumps(d,indent=2)+'\n')
 for pose in ['idle','walk1','walk2','attack','0','1']+(['shell'] if d is snail else []):
  im=Image.new('RGBA',(40,44));p=ImageDraw.Draw(im);step=1 if pose in ['walk1','1'] else -1 if pose=='walk2' else 0
  if d is snail:
   p.ellipse((3,31,37,39+step),fill='#392f32');p.ellipse((4,31,36,37+step),fill='#c64d27');p.line((5,36+step,34,36+step),fill='#ffb23d',width=2)
   p.ellipse((8,12,32,35),fill='#382e32');p.ellipse((10,13,31,33),fill='#885047');p.ellipse((12,15,28,31),fill='#e35e2e');p.arc((14,17,27,30),0,300,fill='#ffbe51',width=2);p.arc((17,20,24,27),40,330,fill='#552e31',width=2)
   p.line((12,17,16,20,15,24),fill='#ffdb62',width=1);p.line((26,16,23,21,28,25),fill='#ffdc68',width=1)
   if pose!='shell':
    p.ellipse((28,25,38,36),fill='#e8803b');p.line((31,28,30,19+step),fill='#eb9655',width=2);p.line((36,28,37,19-step),fill='#eb9655',width=2)
    for x,y in [(30,19+step),(37,19-step)]:p.ellipse((x-2,y-2,x+2,y+2),fill='#fff0b2');p.point((x+1,y),fill='#30282e')
   else:
    p.rectangle((0,0,39,43),fill=(0,0,0,0));p.ellipse((7,10,34,37),fill='#382e32');p.ellipse((9,12,32,35),fill='#a24d35');p.ellipse((12,15,29,32),fill='#f57c28');p.arc((14,17,28,31),15,330,fill='#ffdb64',width=3);p.arc((18,20,25,27),0,310,fill='#694133',width=2);p.line((11,15,15,20,12,25),fill='#ffcf4d',width=1)
  else:
   # Diamond sail, goggles, long scarf and a narrow wooden board.
   p.polygon([(20,0),(38,13),(21,25),(3,13)],fill='#283f4b');p.polygon([(20,2),(35,13),(21,22),(6,13)],fill='#82bfc3');p.polygon([(20,2),(21,22),(6,13)],fill='#e0b466');p.line((20,2,21,22),fill='#ece0bf',width=1);p.line((6,13,35,13),fill='#ece0bf',width=1)
   p.line((8,14,14,26),fill='#c0bbb0');p.line((33,14,25,26),fill='#c0bbb0');p.ellipse((14,16,27,28),fill='#493732');p.rectangle((16,18,25,27),fill='#d79f70');p.rectangle((15,18,26,21),fill='#5b422e');p.rectangle((17,21,25,23),fill='#93d2e4');p.point((20,22),fill='#293744');p.point((24,22),fill='#293744')
   p.polygon([(15,27),(26,27),(28,36),(13,36)],fill='#36606b');p.rectangle((17,27,25,29),fill='#d7794f');p.polygon([(15,28),(9,27),(3,31+step),(13,32)],fill='#d7794f');p.rectangle((15,35,18,39-step),fill='#5e4232');p.rectangle((24,35,27,39+step),fill='#5e4232');p.line((9,40,32,40),fill='#8f623f',width=3);p.line((10,39,30,39),fill='#dfc28a')
   if pose=='attack':p.line((27,28,37,23),fill='#bceaf1',width=2);p.polygon([(37,20),(39,22),(37,25)],fill='#f1ffff')
  im.save(root/f'assets/{d["id"]}_{pose}.png')
f=root/'content/manifest.json';manifest=json.loads(f.read_text())
for id in ['snail','kite']:
 if id not in manifest['characters']:manifest['characters'].append(id)
f.write_text(json.dumps(manifest,indent=2)+'\n')
