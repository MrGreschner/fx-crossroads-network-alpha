from pathlib import Path
import json
from PIL import Image,ImageDraw
p=Path(__file__).resolve().parents[1]
def a(n,s,d,c,r,desc,**kw):return dict(name=n,style=s,damage=d,cooldown=c,range=r,description=desc,**kw)
def t(n,slot,desc,attack):return dict(name=n,ability=slot,description=desc,attack=attack)
def mastery(title,first,last):return dict(title=title,technique=first,final_technique=last,technique_requirements=dict(clears=3,distinct_realms=2,damage=10000),title_requirements=dict(clears=6,distinct_realms=3,damage=20000),final_requirements=dict(clears=12,distinct_realms=6,damage=85000),crit_milestones=[dict(clears=i*3,chance=.02*i,bonus=.2*i) for i in range(1,4)])
e=dict(id='echo_dancer',sprite='echo_dancer',name='Echo Dancer',max_health=115,speed=240,run_cost=0,lore='A travelling ribbon-swordsman from the Folded Coast who learned to dance between seconds. Every step leaves a memory; every memory can become another blade.',primary=a('Second Step','echo_cut',22,.9,90,'A forward ribbon-sabre cut deals 22 damage. An afterimage repeats half the damage at the same spot 0.45s later. Only the last three origins are remembered, for 5s.'),secondary=a('Curtain Feint','echo_feint',12,8,400,'Return to your most recent strike origin within 400 range along a clear route. The spot you leave bursts for 12 damage within 70 reach. Strike first to set a return spot.'),special=a('Encore','echo_encore',20,23,105,'Your last three strike origins replay in order, 0.3s apart, for 20 forward damage each. Position your memories before casting.'),passive='Lingering Applause: afterimage damage increases from 50% to 65% of the direct primary hit.',passive_effect='echo_applause')
e['mastery']=mastery('Virtuoso Between Seconds',t('Long Ribbon','primary','Trade direct damage for wider strikes and stronger delayed echoes.',a('Long Ribbon','echo_cut',16,1,110,'A 110-reach ribbon cut deals 16 damage; its echo repeats the full damage after 0.45s.',echo_ratio=1)),t('Dance Company','special','Trade instant replay damage for three fragile, targetable sword companions.',a('Dance Company','echo_company',6,23,105,'Summon a dancer at each remembered origin for 6s. Each has 24 health and deals 6 melee damage. They can be attacked and killed.')))
l=dict(id='little_menace',sprite='little_menace',name='Little Menace',max_health=120,speed=240,run_cost=0,lore='This mouse brawler carries a pocketful of shrinking charms and an oversized sense of courage. Small does not mean safe: his boldest strike spends his own heartbeats.',primary=a('Three Knocks','mini_jabs',8,.7,72,'Three fast forward punches deal 8 damage each. Landing all three on the same foe slows it 35% for 2s.'),secondary=a('Pocket Size','mini_shift',0,11,0,'Shrink to half size for 4s: +50% movement speed and a smaller projectile hitbox. You can still attack and take damage; area attacks remain dangerous.',duration=4,move_factor=1.5),special=a('Heart on the Line','heart_forfeit',0,26,165,'Charge for 1 second at reduced movement speed, then pay 50% of your maximum health. Each enemy within 165 reach takes that same raw damage before its defences. The cost bypasses your armour and may defeat you if your health is too low.',health_cost=.5),passive='Small Courage: landing all three punches grants 10% damage reduction for 1.5s.',passive_effect='small_courage')
l['mastery']=mastery('The Unflinching Little Legend',t('All In','special','Spend 75% maximum health for greater damage, but a smaller circle.',a('All In','heart_forfeit',0,26,110,'Charge for 1 second, then pay 75% of maximum health to damage every foe within 110 reach for that amount. Can defeat you; the circle is smaller.',health_cost=.75)),t('Long Mischief','secondary','Stay small longer, with a smaller speed increase.',a('Long Mischief','mini_shift',0,11,0,'Shrink for 6s instead of 4, but gain only +30% movement speed. Still able to attack; no invulnerability.',duration=6,move_factor=1.3)))
m=json.loads((p/'content/manifest.json').read_text());lib=json.loads((p/'content/hero_library.json').read_text())
for hero in [e,l]:
 for slot,brief in zip(['primary','secondary','special'],{'echo_dancer': ['Melee cut • 22 damage + a delayed echo', 'Return to last strike • burst at the spot you leave', 'Replay your last three strikes • 20 damage each'], 'little_menace': ['Melee • three 8-damage jabs • all three hits slow', 'Shrink • 4 seconds • faster, smaller, still vulnerable', '1-second charge • sacrifice health • area damage']}[hero['id']]):hero[slot]['ui_brief']=brief
for h,realm,summary in [(e,'folded_coast','Place delayed blade echoes, feint back and replay a three-step combo.'),(l,'grove','Three fast punches, pocket-sized movement and a dangerous health trade.')]:
 id=h['id'];(p/'content/characters'/f'{id}.json').write_text(json.dumps(h,indent=2)+'\n')
 if id not in m['characters']:m['characters'].append(id)
 lib[id]=dict(role='Melee',tags=['Melee','Control'],difficulty='Technical',home_realm=realm,summary=summary,lore=h['lore'],passive_brief=h['passive'])
(p/'content/manifest.json').write_text(json.dumps(m,indent=2)+'\n');(p/'content/hero_library.json').write_text(json.dumps(lib,indent=2)+'\n');(p/'content/hero_numbers.json').write_text(json.dumps({id:i+1 for i,id in enumerate(m['characters'])},indent=2)+'\n')
for id in ['echo_dancer','little_menace']:
 for pose in ['idle','walk1','walk2','attack']:
  im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);dy=-1 if pose=='walk1' else 1 if pose=='walk2' else 0
  def r(b,c):d.rectangle((b[0],b[1]+dy,b[2],b[3]+dy),fill=c)
  def o(b,c):d.ellipse((b[0],b[1]+dy,b[2],b[3]+dy),fill=c)
  def pol(pts,c):d.polygon([(x,y+dy) for x,y in pts],fill=c)
  ink='#29363e'
  if id=='echo_dancer':
   pol([(21,25),(42,25),(48,48),(17,48)],ink);pol([(23,28),(39,28),(43,45),(20,45)],'#567b96');r((24,31,37,36),'#b9cfca');r((25,38,40,42),'#d3ba7d');r((22,48,28,60),ink);r((36,47,42,60),ink);r((19 if pose=='walk1' else 22,57,30,60),'#7c96a0');r((36,57,47 if pose=='walk2' else 44,60),'#7c96a0')
   o((22,8,42,29),'#ac7b62');pol([(21,18),(21,8),(29,3),(42,9),(44,22),(39,19),(39,13),(28,12),(26,20)],ink);r((27,20,29,22),'#c8e6e1');r((35,20,37,22),'#c8e6e1');r((30,26,35,27),'#785047')
   pol([(23,27),(43,28),(39,34),(24,33),(14,29)],'#b1d9da');pol([(16,28),(6,21 if pose=='walk1' else 28),(9,34),(24,34)],'#86bbc4')
   r((12,32,20,43),'#567b96');r((12,40,18,44),'#ac7b62');r((42,32,49,41),'#567b96');r((45,40,51,44),'#ac7b62');pol([(50,42),(56,23),(59,22),(54,43)],'#cdebf0');r((49,41,56,44),'#d4bc84')
   if pose=='attack':d.arc((39,6,63,39),250,70,fill='#8ac6d7',width=2)
  else:
   # Mouse: visible round ears, whiskers, scarf, knuckle wraps and curved tail.
   d.arc((4,35,31,63),40,240,fill='#bc8b91',width=3)
   o((18,4,31,18),ink);o((36,4,49,18),ink);o((21,7,29,16),'#c8939a');o((38,7,46,16),'#c8939a')
   o((21,11,46,34),'#a4a7a0');o((28,25,40,35),'#ddd0b2');r((27,21,29,24),ink);r((38,21,40,24),ink);o((32,28,35,30),'#8c5e6c');d.line((21,28+dy,15,26+dy),fill='#dbd7c2');d.line((43,28+dy,51,26+dy),fill='#dbd7c2')
   pol([(23,34),(41,34),(44,48),(20,48)],'#725064');r((22,34,42,37),'#c67b71');pol([(39,34),(48,39),(48,44),(40,38)],'#c67b71');r((23,47,29,59),ink);r((35,47,41,59),ink);r((21 if pose=='walk1' else 24,56,30,60),'#9b7d6e');r((35,56,44 if pose=='walk2' else 41,60),'#9b7d6e')
   o((13,35,24,45),'#a4a7a0');o((40,35,52,45),'#a4a7a0');r((13,39,22,44),'#ded0ad');r((44,39,52,44),'#ded0ad');r((16,40,19,43),'#be9779');r((46,40,49,43),'#be9779')
   if pose=='attack':r((47,32,58,39),'#ded0ad');r((50,32,53,39),'#be9779')
  im.save(p/'assets'/f'{id}_{pose}.png')
  for alias in ([id,id+'_0'] if pose=='idle' else [id+'_1'] if pose=='walk1' else [id+'_2'] if pose=='walk2' else []):im.save(p/'assets'/f'{alias}.png')
