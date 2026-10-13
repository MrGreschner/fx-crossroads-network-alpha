"""Rebuild distinct 48x48 pixel silhouettes for the bundled realm enemies.
Run from anywhere with: python tools/draw_enemy_variants.py
"""
from pathlib import Path
from PIL import Image, ImageDraw
ROOT = Path(__file__).resolve().parents[1]
A = ROOT / 'assets'
POSES = ('idle', 'walk1', 'walk2', 'attack')

def outline(d, rect, color, edge='#263346', width=2):
    d.rectangle(rect, fill=color, outline=edge, width=width)

def poly(d, coords, fill, edge='#263346'):
    d.polygon(coords, fill=fill)
    d.line(coords + [coords[0]], fill=edge, width=2, joint='curve')

def draw_enemy(name, pose, image, d):
    step = {'idle':0,'walk1':-2,'walk2':2,'attack':1}[pose]
    swing = pose == 'attack'
    if name == 'frostling':
        # Tiny jagged crystal with a faceted body, separate pointed feet.
        poly(d, [(23,2),(31,15),(37,12),(41,29),(31,43),(16,42),(7,29),(13,15),(17,18)], '#79c7ef', '#2c6388')
        poly(d, [(23,5),(31,29),(22,40),(12,27)], '#d9f8ff', '#80bbd6')
        outline(d,(14+step,39,18+step,46),'#468cc1');outline(d,(29-step,39,33-step,46),'#468cc1')
        d.rectangle((16,24,20,29),fill='#17405c');d.rectangle((28,24,32,29),fill='#17405c')
        if swing:poly(d,[(37,21),(47,16),(42,30)],'#e9fbff','#75c9f4')
    elif name == 'ice_archer':
        # Hooded archer with a separate recurved bow silhouette.
        poly(d,[(12,15),(22,4),(34,15),(39,42),(11,42)],'#28659e','#193b68')
        d.ellipse((17,10,31,29),fill='#bceafa',outline='#224e6c',width=2)
        d.polygon([(14,15),(23,3),(35,15)],fill='#77d1f5')
        d.rectangle((20,20,23,24),fill='#163f62');d.rectangle((27,20,30,24),fill='#163f62')
        d.arc((30,6,46,44),75,285,fill='#d9f7ed',width=3)
        d.line((37,9,37,43),fill='#f7eed1',width=1)
        d.line((11 if not swing else 5,27,40,27),fill='#d9e8f5',width=2)
        d.polygon([(4 if swing else 10,25),(11 if swing else 17,27),(4 if swing else 10,29)],fill='#a6dbfa')
        outline(d,(15+step,40,20+step,46),'#30436a');outline(d,(28-step,40,33-step,46),'#30436a')
    elif name == 'glacier_hound':
        # Four-legged wolf: muzzle, back spines, tail and paws.
        poly(d,[(11,17),(27,14),(34,19),(40,20),(46,27),(41,33),(35,31),(25,36),(8,32)],'#80aacd','#385d83')
        poly(d,[(6,22),(2,9),(15,17)],'#afdff2','#44668d')
        poly(d,[(16,18),(20,6),(25,16),(29,3),(33,18)],'#d6f6ff','#649cc3')
        outline(d,(10+step,32,15+step,44),'#456d9c');outline(d,(27-step,33,32-step,44),'#456d9c')
        poly(d,[(34,18),(42,10),(43,22),(46,25),(35,29)],'#b4deec','#456d9c')
        d.rectangle((38,20,41,23),fill='#1a3447')
        if swing:poly(d,[(43,26),(47,30),(40,33)],'#f7faf1','#517e98')
    elif name == 'snow_oracle':
        # Floating tall robe with halo and no walking legs.
        d.ellipse((9,3,39,19),outline='#d6faff',width=2)
        poly(d,[(24,9),(33,15),(40,39),(27,45),(9,39),(15,16)],'#c8eafb','#5889b8')
        d.polygon([(24,13),(34,35),(25,40)],fill='#7ab9df')
        d.ellipse((18,15,30,27),fill='#20335b',outline='#e7fbff',width=2)
        d.rectangle((22,18,26,22),fill='#f8dd92')
        for x in (9,37):d.ellipse((x-2,24+step,x+3,29+step),fill='#a2edfb')
        if swing:d.ellipse((3,10,12,19),fill='#e9ffff',outline='#79cbe7',width=2)
    elif name == 'drone':
        # Mechanical quadrotor, angular metal body and cyan optic.
        for x in (5,35):
            outline(d,(x,9,x+8,14),'#7a9db0','#2b4661')
            d.line((x-3,8,x+12,8),fill='#a2f0f3',width=2)
            d.line((x+4,15,23,20),fill='#607a91',width=2)
        poly(d,[(14,17),(33,17),(39,25),(33,37),(15,37),(9,25)],'#5d657d','#1d3449')
        outline(d,(18,21,30,30),'#192e48','#9ee1e8')
        d.ellipse((21,23,27,29),fill='#8af9f4')
        d.line((19,38,15+step,43),fill='#9aaabe',width=2)
        d.line((29,38,33-step,43),fill='#9aaabe',width=2)
        if swing:d.line((24,28,24,47),fill='#8cf9f1',width=3)
    elif name == 'star_mine':
        # Eight spikes around a dark metal charge; no face.
        for spike in [[(24,1),(19,14),(29,14)],[(24,47),(19,34),(29,34)],[(1,24),(14,19),(14,29)],[(47,24),(34,19),(34,29)],[(6,7),(14,12),(12,17)],[(42,7),(34,12),(36,17)],[(6,41),(14,36),(12,31)],[(42,41),(34,36),(36,31)]]:
            poly(d,spike,'#9d7c46','#4b5260')
        d.ellipse((12,12,36,36),fill='#59617d',outline='#d6b977',width=3)
        d.ellipse((19,19,29,29),fill='#efb85d',outline='#462e3d',width=2)
        if swing:d.line((17,18,31,30),fill='#fff2b0',width=3)
    elif name == 'void_seeker':
        # Jellyfish-like alien with one eye and trailing tentacles.
        for x in (13,22,31):
            d.line((x,28,x-3+step,44,x+2,47),fill='#9566c2',width=3)
        poly(d,[(5,26),(8,14),(17,7),(31,7),(40,16),(43,29),(34,34),(13,33)],'#604a92','#251f4e')
        d.ellipse((17,16,31,30),fill='#c3a4ff',outline='#241c48',width=2)
        d.ellipse((22,20,27,26),fill='#251d52')
        for x in (10,35):d.ellipse((x,28,x+4,32),fill='#ab86d4')
        if swing:d.polygon([(27,20),(47,13),(47,29)],fill='#caabff')
    elif name == 'shambler':
        # Lopsided human zombie, torn shirt and uneven reaching arms.
        outline(d,(18,6,31,20),'#8da67b','#374a3b')
        d.rectangle((20,11,23,13),fill='#f6d191');d.rectangle((27,11,30,13),fill='#f6d191')
        poly(d,[(15,20),(32,18),(36,37),(13,37)],'#5b6655','#343c39')
        d.line((15,22,4,29+step),fill='#9ab189',width=5)
        d.line((34,21,44,14 if swing else 29),fill='#9ab189',width=5)
        outline(d,(15+step,36,21+step,46),'#655a50');outline(d,(28-step,36,36-step,44),'#655a50')
        d.line((15,29,34,29),fill='#9caf75',width=2)
    elif name == 'spore_thrower':
        # Giant toadstool cap, stem legs and an arm holding a spore pod.
        d.ellipse((4,3,43,26),fill='#8f684f',outline='#564e43',width=3)
        for x,y in ((14,10),(29,8),(21,16),(36,17)):d.ellipse((x-2,y-2,x+3,y+2),fill='#f3daa0')
        outline(d,(17,24,31,39),'#e1d7b4','#756850')
        d.rectangle((19,28,22,31),fill='#3a473d');d.rectangle((27,28,30,31),fill='#3a473d')
        outline(d,(18+step,39,22+step,46),'#9b8662');outline(d,(28-step,39,32-step,46),'#9b8662')
        d.line((30,30,39,27),fill='#d2b383',width=3)
        d.ellipse((35 if not swing else 40,21,45 if not swing else 47,31),fill='#c6b866',outline='#826b49',width=2)
    elif name == 'hazmat_raider':
        # Yellow protective suit, respirator, pack and striking arm.
        outline(d,(8,18,19,33),'#797349','#383d3b')
        poly(d,[(15,15),(32,15),(39,38),(12,38)],'#e5bd38','#5e603f')
        d.ellipse((16,2,33,22),fill='#edc946',outline='#5d654d',width=2)
        outline(d,(19,9,30,16),'#246f78','#e0eece')
        d.rectangle((23,16,28,21),fill='#3a5252')
        d.line((13,23,3,35),fill='#e5bd38',width=6)
        d.line((37,24,45,16 if swing else 34),fill='#e5bd38',width=6)
        outline(d,(14+step,36,20+step,46),'#626048');outline(d,(29-step,36,35-step,46),'#626048')
        if swing:d.line((42,16,47,11),fill='#ec8b65',width=3)

def draw_boss(name,pose,image,d):
    step = {'idle':0,'walk1':-1,'walk2':1,'attack':0}[pose]
    swing=pose=='attack'
    if name=='cryowarden':
        # Knight: horned helm, broad ice shoulders, heavy legs and sword.
        poly(d,[(3,16),(18,10),(29,10),(45,16),(39,33),(9,33)],'#5e9fc8','#204f84')
        poly(d,[(15,14),(10,1),(21,10),(26,5),(29,11),(39,1),(35,16)],'#b9e8f6','#427aa6')
        outline(d,(17,12,31,24),'#d6f5fc','#477caf')
        d.rectangle((20,18,28,21),fill='#2e547f')
        outline(d,(12,27,36,39),'#3d739f','#23476e')
        outline(d,(12+step,37,20+step,47),'#5f9ec1');outline(d,(28-step,37,36-step,47),'#5f9ec1')
        d.line((41,14,45 if swing else 38,46 if swing else 31),fill='#f1fbff',width=5)
    elif name=='signal_core':
        # Floating computer eye with satellite arms and segmented ring.
        for x in (1,37):
            outline(d,(x,12+step,x+10,35+step),'#6f64b2','#262553')
            d.line((x+5,14+step,24,25),fill='#d4b6fa',width=2)
        d.ellipse((10,5,38,43),fill='#353464',outline='#ad8be3',width=3)
        d.ellipse((16,14,32,34),fill='#bc79e4',outline='#242553',width=2)
        d.ellipse((21,19,27,29),fill='#fff0f9')
        for x,y in [(18,3),(34,8),(9,38),(38,42)]:d.rectangle((x,y,x+3,y+3),fill='#c1a6f6')
        if swing:d.polygon([(25,26),(47,20),(47,33)],fill='#f2bff9')
    elif name=='plague_director':
        # Tall infected scientist with mask, asymmetrical arms and flask.
        d.ellipse((16,3,31,20),fill='#9fb279',outline='#46543b',width=2)
        d.polygon([(18,11),(30,11),(26,18),(21,18)],fill='#304d4b')
        poly(d,[(11,21),(35,20),(41,44),(7,44)],'#d9d5ba','#465442')
        d.line((24,22,24,42),fill='#6f8c58',width=2)
        outline(d,(13+step,39,20+step,47),'#5e6849');outline(d,(30-step,39,37-step,47),'#5e6849')
        d.line((11,23,2,16),fill='#879d62',width=5)
        d.line((36,23,44,34 if not swing else 12),fill='#879d62',width=5)
        d.ellipse((39,29 if not swing else 6,47,39 if not swing else 16),fill='#a9e665',outline='#425d43',width=2)

def build():
    for name in ('frostling','ice_archer','glacier_hound','snow_oracle','drone','star_mine','void_seeker','shambler','spore_thrower','hazmat_raider'):
        for pose in POSES:
            image=Image.new('RGBA',(48,48));d=ImageDraw.Draw(image)
            draw_enemy(name,pose,image,d)
            image.save(A/f'{name}_{pose}.png')
            if pose=='idle':image.save(A/f'{name}_0.png')
            if pose=='walk2':image.save(A/f'{name}_1.png')
    for name in ('cryowarden','signal_core','plague_director'):
        for pose in POSES:
            image=Image.new('RGBA',(48,48));d=ImageDraw.Draw(image)
            draw_boss(name,pose,image,d)
            image.save(A/f'{name}_{pose}.png')
            if pose=='idle':image.save(A/f'{name}.png')
    print('Redrew 10 enemies and 3 bosses with unique four-pose silhouettes.')

if __name__=='__main__':build()
