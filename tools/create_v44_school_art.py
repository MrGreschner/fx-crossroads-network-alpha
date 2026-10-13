"""Original pixel art for the school trilogy. Requires Pillow.
Overwrites school textures and the eighteen school creatures' sprite poses.
"""
from pathlib import Path
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]/'assets'
INK='#263442'
def canvas(size=(128,96)):
    im=Image.new('RGBA',size);return im,ImageDraw.Draw(im)
def save(key,im):im.save(ROOT/(key+'.png'))
for key,base,line in [('school_tile','#c3c3ae','#8e9d99'),('school_wood','#b69162','#80694e'),('school_street','#485568','#3a4657'),('school_yard','#739867','#63805e'),('school_carpet','#667b91','#5a6c82')]:
    im,g=canvas((64,64));g.rectangle((0,0,63,63),fill=base)
    if key=='school_tile':
        for x in [0,32]:
            for y in [0,32]:g.rectangle((x,y,x+30,y+30),outline=line);g.line((x+2,y+2,x+27,y+2),fill='#d6d4bd',width=1)
    elif key=='school_wood':
        for y in [0,16,32,48]:g.line((0,y,63,y),fill=line,width=2);g.line(((y*7)%64,y,(y*7)%64,y+15),fill=line,width=2);g.line((8,y+8,30,y+8),fill='#a48058',width=1)
    else:
        for n in range(20):x=(n*29)%64;y=(n*37)%64;g.rectangle((x,y,x+2,y+2),fill=line)
    save(key,im)
PROPS=['desk','board','locker','bookshelf','counter','oven','curtain','weightbench','hoop','clocktower','playframe','slide','bench']
for key in PROPS:
    im,g=canvas()
    g.ellipse((8,65,119,91),fill=(26,38,46,65))
    if key=='desk':
        g.rectangle((11,23,114,62),fill='#664d3e',outline=INK,width=3);g.rectangle((14,19,111,51),fill='#c6a574',outline=INK,width=3);g.line((25,56,25,85),fill=INK,width=5);g.line((99,56,99,85),fill=INK,width=5);g.rectangle((42,52,81,67),fill='#657f8e',outline=INK,width=3);g.rectangle((38,28,71,43),fill='#eee7c8',outline='#9f926e');g.line((52,33,52,41),fill='#829fa9',width=2);g.line((82,35,101,29),fill='#dcb76a',width=3)
    elif key=='board':
        g.rectangle((4,10,123,68),fill='#ad8c63',outline=INK,width=3);g.rectangle((10,16,117,60),fill='#3f6862');g.line((17,29,48,29),fill='#e1e4c4',width=2);g.line((17,38,63,38),fill='#e1e4c4',width=2);g.rectangle((84,24,102,44),outline='#e3d691',width=2);g.line((26,67,26,87),fill=INK,width=3);g.line((104,67,104,87),fill=INK,width=3)
    elif key=='locker':
        g.rectangle((25,6,100,87),fill='#6a879b',outline=INK,width=3)
        for x in [28,53,78]:
            g.rectangle((x,11,x+20,81),outline='#38505e',width=2)
            for y in [18,22,26]:g.line((x+4,y,x+16,y),fill='#314554',width=2)
            g.rectangle((x+13,42,x+16,49),fill='#dfcf8c')
    elif key=='bookshelf':
        g.rectangle((9,8,118,78),fill='#937752',outline=INK,width=3)
        for y in [16,44]:
            for n in range(11):g.rectangle((15+n*9,y,20+n*9,y+22),fill=['#8297a6','#bf9b79','#95a07b','#b18b91'][n%4],outline=INK)
            g.line((13,y+23,113,y+23),fill='#c6ac78',width=3)
    elif key in ['counter','oven']:
        g.rectangle((8,33,119,80),fill='#79898d',outline=INK,width=3);g.rectangle((5,26,122,43),fill='#c4c8b8',outline=INK,width=3)
        if key=='oven':
            g.rectangle((32,47,93,72),fill='#3a414a',outline='#babeb3',width=3)
            for x in [23,50,78,106]:g.ellipse((x-5,14,x+6,25),fill='#3d464d',outline=INK,width=2)
            g.line((37,55,88,55),fill='#c29463',width=2)
        else:
            for x in [14,49,83]:g.rectangle((x,48,x+29,72),outline='#485b63',width=2)
            g.ellipse((27,10,49,24),fill='#b1c596',outline=INK,width=2);g.rectangle((81,12,104,26),fill='#d8b28b',outline=INK,width=2)
    elif key=='curtain':
        g.rectangle((4,5,123,87),fill='#303547',outline=INK,width=3)
        for x in [7,21,35,77,91,105]:g.polygon([(x,9),(x+15,9),(x+9,78),(x,87)],fill='#98566a',outline='#633e53')
        g.rectangle((5,5,122,18),fill='#bb8a68',outline=INK,width=2)
    elif key=='weightbench':
        g.line((19,26,19,80),fill='#546b79',width=7);g.line((108,26,108,80),fill='#546b79',width=7);g.line((9,28,119,28),fill='#c3c8be',width=4)
        for x in [8,21,99,112]:g.rectangle((x,11,x+8,46),fill='#3b4759',outline=INK,width=2)
        g.rectangle((37,40,88,65),fill='#987c85',outline=INK,width=3);g.line((43,65,43,87),fill=INK,width=5);g.line((82,65,82,87),fill=INK,width=5)
    elif key=='hoop':
        g.line((66,30,66,85),fill='#7b8794',width=8);g.rectangle((25,3,107,41),fill='#ddd9bd',outline=INK,width=3);g.rectangle((46,17,87,35),outline='#ac7365',width=3);g.ellipse((42,31,91,47),outline='#cb8460',width=4)
        for x in [48,60,72,84]:g.line((x,43,64,62),fill='#e5e2ca',width=2)
    elif key=='clocktower':
        g.rectangle((34,22,96,85),fill='#8d9d9f',outline=INK,width=3);g.polygon([(20,24),(64,1),(109,24)],fill='#65738b',outline=INK);g.ellipse((44,24,85,64),fill='#e0d9b4',outline=INK,width=3);g.line((64,45,64,30),fill=INK,width=3);g.line((64,45,77,51),fill=INK,width=3);g.rectangle((51,68,78,86),fill='#4c5d70',outline=INK,width=2)
    elif key=='playframe':
        for x in [12,57,107]:g.line((x,28,x,83),fill='#487f8b',width=5)
        for y in [28,44,60,76]:g.line((12,y,109,y),fill='#deb65f',width=4)
        g.line((12,28,32,8),fill='#698c7c',width=4);g.line((109,28,120,8),fill='#698c7c',width=4);g.line((32,8,120,8),fill='#deb65f',width=4)
    elif key=='slide':
        g.polygon([(23,15),(52,12),(120,73),(106,87),(38,38)],fill='#77acc1',outline=INK);g.line((24,14,24,82),fill='#a4a788',width=5);g.line((53,17,53,70),fill='#a4a788',width=5)
        for y in [32,48,64]:g.line((25,y,50,y),fill='#cab879',width=3)
    else:
        g.rectangle((12,25,117,52),fill='#b48e68',outline=INK,width=3);g.rectangle((12,55,117,65),fill='#b48e68',outline=INK,width=3);g.line((27,65,27,83),fill=INK,width=5);g.line((101,65,101,83),fill=INK,width=5)
    save('school_'+key,im)
ENEMIES=['pencil_scrapper','paper_sprite','backpack_biter','hall_monitor','gravel_skater','chalkling','culture_blob','recess_ringleader','yellow_bus','lunchline_leviathan','bellwork_colossus','spotlight_sovereign','layercake_golem','iron_barbell','exam_math','exam_english','exam_history','exam_science']
for key in ENEMIES:
    for pose in ['idle','walk1','walk2','attack','hurt','0','1']:
        im,g=canvas((128,96) if key=='yellow_bus' else (96,96));s=3 if pose in ['walk2','1'] else 0
        if key=='pencil_scrapper':
            g.polygon([(24,70),(58,10),(69,18),(35,78)],fill='#e6c073',outline=INK);g.polygon([(24,70),(20,82),(35,78)],fill='#ccb592',outline=INK);g.rectangle((58,10,68,20),fill='#dba5a4',outline=INK);g.line((30,62,61,20),fill='#aa874e',width=2);g.ellipse((36,45,43,53),fill=INK);g.line((23,65,10,60+s),fill=INK,width=4);g.line((45,57,59,63-s),fill=INK,width=4)
        elif key=='paper_sprite':
            g.polygon([(4,28+s),(45,9),(89,30-s),(58,56),(46,78),(35,56)],fill='#dcded0',outline=INK);g.line((5,29,45,40,88,29),fill='#809baa',width=3);g.line((45,11,45,75),fill='#a1a99d',width=2);g.ellipse((35,37,40,44),fill=INK);g.ellipse((52,37,57,44),fill=INK)
        elif key=='backpack_biter':
            g.arc((25,9,68,45),180,360,fill=INK,width=5);g.rounded_rectangle((19,22,76,77),radius=8,fill='#7b899d',outline=INK,width=3);g.rectangle((24,54,72,71),fill='#485b70',outline=INK,width=2)
            for x in [29,41,53,65]:g.polygon([(x,55),(x+6,55),(x+3,62)],fill='#e2d8b8')
            g.ellipse((28,34,36,43),fill='#e8cf9e');g.ellipse((59,34,67,43),fill='#e8cf9e');g.line((28,75,23,87-s),fill=INK,width=5);g.line((64,75,70,87+s),fill=INK,width=5)
        elif key=='hall_monitor':
            g.rectangle((18,25,75,73),fill='#82a5a4',outline=INK,width=3);g.rectangle((25,31,69,66),fill='#cfdbc3');g.rectangle((34,10,60,25),fill='#6f8a9a',outline=INK,width=3);g.ellipse((36,32,43,40),fill=INK);g.ellipse((52,32,59,40),fill=INK);g.line((34,47,59,47),fill='#6b8d83',width=3);g.line((22,74,18,87-s),fill=INK,width=5);g.line((69,74,73,87+s),fill=INK,width=5);g.line((8,64,18,54),fill='#cfb586',width=5);g.line((74,54,87,45),fill='#cfb586',width=5)
        elif key=='gravel_skater':
            g.ellipse((29,10,57,38),fill='#bfc3bc',outline=INK,width=3);g.polygon([(25,22),(30,6),(53,6),(62,26),(53,21),(32,21)],fill='#607984',outline=INK);g.polygon([(25,40),(60,38),(70,66),(32,65)],fill='#849689',outline=INK);g.line((37,65,31,79-s),fill='#455766',width=6);g.line((58,65,66,79+s),fill='#455766',width=6);g.rounded_rectangle((12,78,85,85),radius=3,fill='#b89b74',outline=INK,width=2);g.ellipse((19,83,29,93),fill=INK);g.ellipse((67,83,77,93),fill=INK);g.line((62,43,81,37-s),fill='#bfc3bc',width=6);g.ellipse((77,29,87,39),fill='#7f8c92',outline=INK);g.rectangle((37,25,41,28),fill=INK);g.rectangle((49,25,53,28),fill=INK)
        elif key=='chalkling':
            g.rectangle((32,28,64,68),fill='#e4e0c9',outline=INK,width=3);g.line((33,37,62,37),fill='#abc2c5',width=3);g.rectangle((39,46,42,51),fill=INK);g.rectangle((55,46,58,51),fill=INK);g.line((37,67,32,82-s),fill=INK,width=4);g.line((58,67,65,82+s),fill=INK,width=4)
        elif key=='culture_blob':
            g.polygon([(15,76),(17,48),(28,28),(45,17),(66,27),(78,47),(82,76)],fill='#90b38a',outline=INK);g.ellipse((24,33,39,49),fill='#c1d59c');g.ellipse((56,37,69,48),fill='#bdd2a1');g.rectangle((34,53,40,61),fill=INK);g.rectangle((59,53,65,61),fill=INK);g.arc((35,59,64,73),0,180,fill='#496956',width=3)
        elif key=='recess_ringleader':
            g.ellipse((10,31,84,76),fill='#7d9bb0',outline=INK,width=3);g.ellipse((25,25,68,73),fill='#dfb66b',outline=INK,width=3);g.arc((17,6,77,63),180,360,fill='#5b718e',width=7);g.rectangle((18,15,25,86-s),fill='#628e89',outline=INK);g.rectangle((72,15,79,86+s),fill='#628e89',outline=INK);g.ellipse((33,42,40,50),fill=INK);g.ellipse((54,42,61,50),fill=INK);g.arc((34,48,63,63),0,180,fill=INK,width=3)
        elif key=='yellow_bus':
            g.rounded_rectangle((4,22,123,78),radius=7,fill='#ddb850',outline=INK,width=3);g.rectangle((9,28,90,50),fill='#7296a2',outline=INK,width=2)
            for x in range(12,91,15):g.line((x,28,x,49),fill='#ddbb63',width=3)
            g.rectangle((95,29,115,64),fill='#5f7882',outline=INK,width=3);g.line((104,30,104,63),fill='#bcaa79',width=2);g.rectangle((6,61,88,66),fill='#344652');g.ellipse((18,65,41,91),fill=INK);g.ellipse((91,65,114,91),fill=INK);g.ellipse((24,72,35,84),fill='#8c9b9e');g.ellipse((97,72,108,84),fill='#8c9b9e');g.rectangle((116,53,123,62),fill='#f6e6a1');g.rectangle((8,11,54,22),fill='#d6b259',outline=INK);g.line((15,15,47,15),fill=INK,width=2)
        elif key=='lunchline_leviathan':
            g.polygon([(7,64),(22,22),(72,22),(88,65),(76,81),(20,81)],fill='#879eaa',outline=INK);g.rectangle((16,61,80,76),fill='#c0cabe',outline=INK,width=3);g.ellipse((22,10,69,34),fill='#d4d7b9',outline=INK,width=3);g.ellipse((25,36,39,51),fill='#c6dda6');g.ellipse((56,36,70,51),fill='#c6dda6');g.rectangle((26,58,68,62),fill=INK);g.line((11,49,3,32+s),fill='#b1b9ab',width=5);g.line((83,49,94,30-s),fill='#b1b9ab',width=5)
        elif key=='bellwork_colossus':
            g.polygon([(12,70),(22,22),(75,22),(86,70)],fill='#7f969e',outline=INK);g.ellipse((25,24,72,72),fill='#decf9d',outline=INK,width=3);g.line((48,49,48,31),fill=INK,width=4);g.line((48,49,63,56),fill=INK,width=4);g.polygon([(10,24),(48,4),(86,24)],fill='#a98c61',outline=INK);g.line((24,72,18,90-s),fill=INK,width=6);g.line((71,72,78,90+s),fill=INK,width=6)
        elif key=='spotlight_sovereign':
            g.line((46,54,26,87),fill='#697b89',width=6);g.line((46,54,69,87),fill='#697b89',width=6);g.line((46,54,46,90),fill='#697b89',width=6);g.polygon([(14,21),(67,12),(82,28),(27,60)],fill='#536377',outline=INK);g.ellipse((16,21,54,57),fill='#ddc98d',outline=INK,width=3);g.ellipse((23,28,47,51),fill='#f4dfa4',outline='#b99966',width=3);g.rectangle((57,9,77,23),fill='#7a8593',outline=INK,width=2)
        elif key=='layercake_golem':
            g.rectangle((13,53,81,79),fill='#bb8f8e',outline=INK,width=3);g.rectangle((21,32,74,57),fill='#d3bca0',outline=INK,width=3);g.rectangle((30,14,65,36),fill='#bb8f8e',outline=INK,width=3)
            for y,x1,x2 in [(18,32,63),(36,23,72),(57,15,79)]:g.line((x1,y,x2,y),fill='#ece0b9',width=6)
            g.ellipse((42,5,53,15),fill='#b86d64',outline=INK);g.rectangle((29,62,35,68),fill=INK);g.rectangle((60,62,66,68),fill=INK);g.line((23,80,18,90-s),fill=INK,width=5);g.line((71,80,78,90+s),fill=INK,width=5)
        elif key=='iron_barbell':
            g.line((5,40,90,40),fill='#bcc6c5',width=8)
            for x in [7,19,67,79]:g.rounded_rectangle((x,16,x+10,67),radius=3,fill='#49576b',outline=INK,width=3)
            g.rectangle((32,29,63,53),fill='#8a98a2',outline=INK,width=3);g.rectangle((37,36,42,40),fill='#dcba77');g.rectangle((55,36,60,40),fill='#dcba77');g.line((35,53,30,81-s),fill='#586778',width=6);g.line((61,53,68,81+s),fill='#586778',width=6)
        else:
            tint={'exam_math':'#d59572','exam_english':'#93b9aa','exam_history':'#91b7cf','exam_science':'#a6b68b'}[key]
            g.polygon([(20,13),(64,13),(78,27),(78,79),(17,79)],fill='#dfdec5',outline=INK);g.polygon([(64,13),(64,29),(78,29)],fill=tint,outline=INK);g.rectangle((27,24,57,31),fill=tint);g.rectangle((28,40,34,47),fill=INK);g.rectangle((58,40,64,47),fill=INK);g.arc((31,47,64,65),0,180,fill=INK,width=3)
            for y in [65,71]:g.line((25,y,68,y),fill=tint,width=2)
            if key=='exam_math':
                for x in [7,71]:g.polygon([(x,77),(x+5,43),(x+13,58),(x+19,35),(x+22,76)],fill='#d78854',outline='#ad674c')
                g.line((31,33,40,33),fill='#a65c48',width=2);g.line((36,29,36,37),fill='#a65c48',width=2)
            elif key=='exam_english':
                g.arc((3,13+s,91,76),200,340,fill='#8abcb0',width=5);g.line((4,58,14,66,8,75),fill='#8abcb0',width=3);g.polygon([(79,64),(88,80),(72,86)],fill='#9ac3b5')
            elif key=='exam_history':
                for x in [7,77]:g.polygon([(x,79),(x+6,45),(x+15,77)],fill='#b4d8df',outline='#739ab9')
                g.line((40,31,51,31),fill='#6f93b3',width=3)
            else:
                g.rectangle((4,62,15,75),fill='#859b67',outline=INK);g.ellipse((73,61,91,82),fill='#a7c36f',outline=INK);g.line((82,54,82,64),fill='#78985d',width=5)
            g.line((27,80,21,90-s),fill=INK,width=5);g.line((67,80,76,90+s),fill=INK,width=5)
        save(key+'_'+pose,im)
print('Created original school tiles, furniture and creature sprite poses.')
