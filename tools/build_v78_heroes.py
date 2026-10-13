# Rebuild the v78 hero definitions and matching pixel sprites.
import json,pathlib
from PIL import Image,ImageDraw
root=pathlib.Path(__file__).resolve().parents[1]
base=json.loads((root/'content/characters/ripplejaw.json').read_text())['mastery']
def attack(name,style,damage,cooldown,description,**kw):return dict(name=name,style=style,damage=damage,cooldown=cooldown,description=description,**kw)
g=dict(id='gopher',name='Burrowick',sprite='gopher',max_health=110,speed=230,run_cost=0,lore='A quarry gopher who maps the world beneath its feet. Attacking forces Burrowick to stop and surface; short tunnel slides evade incoming hits.',primary=attack('Quarry Claws','gopher_claw',25,.7,'Stop and surface to rake a close 80-range arc.',range=80),secondary=attack('Pop-up Pounce','gopher_dive',35,7,'Burrow up to 280 along a clear path, then erupt in a 65-radius splash and stun for 1s. Attacks and walking pause during the dive.',range=280,radius=65,stun_duration=1),special=attack('Cave In','gopher_cave',65,15,'Surface and warn along your last four tunnel slides for 0.65s, then collapse those paths. Each enemy takes damage once, even where paths cross.',width=38,slow_duration=2,slow=.65),passive='Packed Earth: Pop-up Pounce grants 12% damage reduction for 2s after surfacing.',passive_effect='packed_earth')
n=dict(id='nullweaver',name='Nullweaver',sprite='nullweaver',max_health=95,speed=235,run_cost=0,lore='An eccentric masked rift tailor. Weak pins become deadly lines when carefully placed; aim beyond foes, rotate the seam, and catch them on triangle edges.',primary=attack('Stitch Reality','rift_pin',18,.85,'Place a pin up to 280 away for 18 damage in a tiny area. Two pins flash a 25.2-damage seam; a third replaces the oldest. Pins over 600 apart lose their link. Walls block travel.',range=280,link_multiplier=1.4),secondary=attack('Quarter Turn','rift_rotate',42,5,'Rotate the line between two pins by 90 degrees over 0.6s. Its sweeping seam hits each foe once. Requires two pins.',width=20),special=attack('Impossible Hem','rift_triangle',36,14,'Draw a triangle ahead. After a 0.65s warning, three edges fire in sequence. Each edge deals 36; the empty centre is safe. Precise placement can catch a foe twice.',radius=125),passive='Needle Frost: Rift seams slow struck enemies by 20% for 1s after level 5.',passive_effect='needle_frost')
for data in [g,n]:
 m=json.loads(json.dumps(base));m['title']='Cartographer of the Deep' if data==g else 'Master of Impossible Seams'
 if data==g:
  m['technique']=dict(name='Gentle Excavation',ability='secondary',description='Pounce has a larger 90-radius impact and 1.5s stun, but deals 25 damage.',set=dict(radius=90,damage=25,stun_duration=1.5))
  m['final_technique']=dict(name='Faultline',ability='special',description='Replace your trail collapse with one aimed 340-range crack. Less damage, reliable reach and a longer slow.',attack=attack('Faultline','gopher_fault',52,15,'Warn for 0.65s, then crack a straight 340-range strip for 52 damage and a 3s slow.',width=32,slow_duration=3,slow=.55))
 else:
  m['technique']=dict(name='Broad Seam',ability='secondary',description='Sweep twice as wide, but reduce damage from 42 to 30.',set=dict(width=40,damage=30))
  m['final_technique']=dict(name='Unravel',ability='primary',description='Replace pins and links with three delayed 60-radius rift bursts in a fan. Easier aim, but no linked line for Quarter Turn: switch it back to recover the pin playstyle.',attack=attack('Unravel','rift_scatter',13,1.25,'Three marked rifts burst after 0.6–0.9s, for 13 damage each. No pins are placed.',range=180))
 # Final primary must still support the separate secondary: use special instead.
 if data==n:m['final_technique']=dict(name='Unravel',ability='special',description='Replace precise triangle edges with three smaller delayed rift bursts in a fan. Easier to land, less potential damage.',attack=attack('Unravel','rift_scatter',26,14,'Three 60-radius rifts burst after 0.6–0.9s, dealing 26 each. Spread them across foes or overlap them.',range=180))
 data['mastery']=m
 (root/f'content/characters/{data["id"]}.json').write_text(json.dumps(data,indent=2)+'\n')
 for pose in ['idle','walk1','walk2','attack','0','1']:
  im=Image.new('RGBA',(32,40));d=ImageDraw.Draw(im);step=1 if pose in ['walk1','1'] else -1 if pose=='walk2' else 0
  if data==g:
   d.ellipse((6,9,26,31),fill='#513b30');d.ellipse((7,10,25,30),fill='#a67948');d.ellipse((10,22,23,34),fill='#d0ad74');d.ellipse((4,6,12,15),fill='#563d2e');d.ellipse((22,6,29,15),fill='#563d2e');d.ellipse((6,8,10,12),fill='#d5a783');d.ellipse((24,8,27,12),fill='#d5a783');d.ellipse((8,13,27,25),fill='#b18553');d.rectangle((12,16,14,19),fill='#21232c');d.rectangle((23,16,25,19),fill='#21232c');d.ellipse((17,20,22,24),fill='#563b32');d.rectangle((18,24,21,27),fill='#fff1d0');d.rectangle((8,32+step,13,36+step),fill='#624939');d.rectangle((21,32-step,26,36-step),fill='#624939');d.rectangle((3,24,8,29),fill='#8c653f');d.rectangle((26,24,30,29),fill='#8c653f')
   if pose=='attack':
    for y in [23,26,29]:d.line((26,y,31,y-4),fill='#fff0c5',width=1)
   d.rectangle((8,28,26,30),fill='#517465');d.rectangle((15,28,18,31),fill='#e7be64')
  else:
   d.polygon([(16,2),(24,9),(26,21),(22,34),(7,34),(5,21),(8,10)],fill='#242638');d.polygon([(16,4),(22,12),(24,24),(19,32),(9,31),(7,22),(10,11)],fill='#635084');d.ellipse((10,11,22,23),fill='#e4dacd');d.rectangle((11,16,21,19),fill='#35283f');d.rectangle((12,16,14,17),fill='#daafff');d.rectangle((19,16,21,17),fill='#daafff');d.polygon([(7,23),(16,26),(24,22),(24,26),(16,29),(7,27)],fill='#a975c0');d.rectangle((10,32+step,14,37+step),fill='#282735');d.rectangle((19,32-step,23,37-step),fill='#282735');d.rectangle((3,20,7,27),fill='#dfd6be');d.rectangle((25,20,29,27),fill='#dfd6be');d.line((27,18,30,9),fill='#c9b0da',width=2);d.polygon([(30,5),(27,9),(30,12),(31,9)],fill='#f1c4ff')
   if pose=='attack':d.line((3,22,1,14),fill='#eac7ff',width=2)
  im.save(root/f'assets/{data["id"]}_{pose}.png')
manifest=root/'content/manifest.json';j=json.loads(manifest.read_text())
for i in ['gopher','nullweaver']:
 if i not in j['characters']:j['characters'].append(i)
manifest.write_text(json.dumps(j,indent=2)+'\n')
