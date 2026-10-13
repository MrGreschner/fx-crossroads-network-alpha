"""Author the three v44 school adventures. Original editable map/content source.
Running this overwrites the three school definitions, scenes, and school enemy JSON.
"""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
def write(path,data):
    p=ROOT/path;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(data,indent=2)+'\n')
ENEMIES=[
 ('pencil_scrapper','Pencil Scrapper',48,115,7),('paper_sprite','Paper Sprite',42,105,6),
 ('backpack_biter','Backpack Biter',62,90,9),('hall_monitor','Hall-Pass Sentinel',100,82,12),
 ('gravel_skater','Gravel Skater',118,140,13),('chalkling','Chalkling',25,135,5),
 ('culture_blob','Culture Blob',45,90,10),('recess_ringleader','Recess Ringleader',420,65,11),
 ('yellow_bus','The Last Bus',650,42,18),('lunchline_leviathan','Lunchline Leviathan',850,65,18),
 ('bellwork_colossus','Bellwork Colossus',1100,85,21),('spotlight_sovereign','Spotlight Sovereign',900,115,22),
 ('layercake_golem','Layercake Golem',950,75,22),('iron_barbell','Iron Barbell',1000,95,25),
 ('exam_math','Final Exam: Mathematics',2000,85,25),('exam_english','Final Exam: English',1900,165,23),
 ('exam_history','Final Exam: History',2200,70,25),('exam_science','Final Exam: Science',2000,100,24)]
for key,name,hp,speed,damage in ENEMIES:
    write(f'content/enemies/{key}.json',{'id':key,'name':name,'sprite':key,'health':hp,'speed':speed,'damage':damage,'aggro_range':850,'behaviour':'custom','custom_attack':'school_'+key,'expansion_only':True})
def room(key,title,rect,theme='tile'):
    return dict(id=key,name=title,rect=rect,theme=theme)
def door(key,point,size,requires='',label='Open door'):
    return dict(id=key,pos=point,size=size,requires=requires,label=label)
def encounter(points,types,base=1):
    return [dict(type=types[n%len(types)],pos=p,hp=round(dict((e[0],e[2]) for e in ENEMIES)[types[n%len(types)]]*base)) for n,p in enumerate(points)]
def classrooms(data,room_id,columns=3,rows=2):
    r=next(r['rect'] for r in data['rooms'] if r['id']==room_id);x,y,w,h=r
    for row in range(rows):
        for col in range(columns):
            data['props'].append(dict(kind='school_desk',pos=[x+180+col*220,y+240+row*240],size=[125,80],solid=[105,52]))
    data['props'].append(dict(kind='school_board',pos=[x+w/2,y+80],size=[230,95],solid=[210,42]))
def finalize(key,name,size,difficulty,description,data,after):
    # Repeat campus motifs at different schools, without blocking hall aisles.
    hall=next(r for r in data['rooms'] if r['id']=='hall')['rect']
    for n in range(1,int(hall[2]/500)):
        p=[hall[0]+n*500,hall[1]+135]
        if not any(abs(p[0]-prop['pos'][0])<120 and abs(p[1]-prop['pos'][1])<120 for prop in data['props']):data['props'].append(dict(kind='school_locker',pos=p,size=[115,145],solid=[85,50]))
    street=next(r for r in data['rooms'] if r['id']=='street')['rect']
    for x in [street[0]+street[2]*.2,street[0]+street[2]*.72]:
        data['props'].append(dict(kind='school_bench',pos=[x,data['spawn'][1]-100],size=[180,95],solid=[140,48]))
    if key=='high_school':
        for x in [10400,11000,13000,14400]:data['props'].append(dict(kind='school_locker',pos=[x,2690],size=[115,145],solid=[85,50]))
    write(f'content/schools/{key}.json',data)
    write(f'content/regions/{key}.json',{'id':key,'name':name,'size':size,'terrain':'school_tile','scene':f'res://scenes/realms/{key}.tscn','school_campaign':f'res://content/schools/{key}.json','boss_sprite':'yellow_bus' if key=='elementary' else 'bellwork_colossus' if key=='middle_school' else 'exam_math','boss_health':650 if key=='elementary' else 1100 if key=='middle_school' else 2000,'xp_per_level':2 if key=='elementary' else 3,'difficulty_label':difficulty,'description':description})
    text='[gd_scene format=3]\n\n[node name="'+key.capitalize()+'" type="Node2D"]\n'
    for folder in ['GroundPaint','Obstacles','Enemies','Points']:text+=f'\n[node name="{folder}" type="Node2D" parent="."]\n'
    for point,pos in [('Spawn',data['spawn']),('ReturnGate',data['exit']),('Merchant',data['merchant']),('Boss',data['exit'])]:text+=f'\n[node name="{point}" type="Marker2D" parent="Points"]\nposition = Vector2({pos[0]}, {pos[1]})\n'
    (ROOT/f'scenes/realms/{key}.tscn').write_text(text)
    if key in manifest['regions']:manifest['regions'].remove(key)
    manifest['regions'].insert(manifest['regions'].index(after)+1,key)
manifest=json.loads((ROOT/'content/manifest.json').read_text())
for entry in ENEMIES:
    if entry[0] not in manifest['enemies']:manifest['enemies'].append(entry[0])

elementary=dict(id='elementary',name='Firstbell Elementary',spawn=[3900,5500],exit=[3900,5500],merchant=[4550,5300],rooms=[
 room('street','FIRSTBELL • SCHOOL STREET',[300,4800,6500,950],'street'),room('entry','WELCOME TO FIRSTBELL',[2950,4350,1300,600],'yard'),
 room('foyer','CUBBIES & WELCOME HALL',[2900,3500,1400,1100]),room('hall','THE COLOUR HALL',[1100,2700,4400,950]),
 room('class_a','SUNSHINE CLASSROOM',[1100,1100,1600,1400]),room('class_b','STARLIGHT CLASSROOM',[3650,1100,1850,1400]),
 room('west_link','',[1700,2350,400,500]),room('east_link','',[4300,2350,400,500]),room('back_hall','',[2850,950,650,1900]),
 room('playground','THE ENCHANTED PLAYGROUND',[1000,250,4700,700],'yard')],doors=[
 door('front',[3600,4630],[1300,50]),door('class_a',[1900,2500],[400,45]),door('class_b',[4500,2500],[400,45]),
 door('playground',[3175,950],[650,100],'school','Clear both classrooms to unlock the playground')],props=[],routes=[],gears=[],groups={},stages=[
 dict(id='school',text='Enter the school. Clear the Colour Hall and both classrooms.',groups=['school']),
 dict(id='recess',text='The playground door is unlocked. Defeat the Recess Ringleader outside.',boss='recess_ringleader',pos=[3300,620],trigger=[1000,250,4700,700]),
 dict(id='return',text='Recess is over! Fight through the school and return to the street.',groups=['return']),
 dict(id='bus',text='The Last Bus is waiting outside. Dodge its charge and its chalkling passengers.',boss='yellow_bus',pos=[3250,5270],trigger=[300,4800,6500,950])])
elementary['groups']['school']=encounter([[3650,4100],[3350,3700],[2250,3150],[4750,3000],[3175,2350],[2350,1550],[1500,2200],[2400,2100],[1550,1400],[4900,1600],[3950,2200],[4950,2150]],['pencil_scrapper','backpack_biter','paper_sprite'])
elementary['groups']['return']=encounter([[3150,1700],[3250,2400],[2200,3000],[4750,3200],[3800,3900],[3150,4150],[3950,4500],[5100,2100]],['paper_sprite','pencil_scrapper','backpack_biter'])
classrooms(elementary,'class_a');classrooms(elementary,'class_b',4)
for x in [1250,1650,2050,2450,4600,5000]:elementary['props'].append(dict(kind='school_locker',pos=[x,2830],size=[85,125],solid=[65,48]))
elementary['props'] += [dict(kind='school_playframe',pos=[1900,550],size=[300,220],solid=[210,95]),dict(kind='school_slide',pos=[4800,620],size=[250,200],solid=[165,85]),dict(kind='school_bench',pos=[4550,5000],size=[160,90],solid=[130,45])]
finalize('elementary','Firstbell Elementary',[7200,6000],'Easy — classrooms, playground guardian and the Last Bus','Enter the school, clear its classrooms, unlock the playground, defeat its guardian, then fight back through the halls. Your final obstacle is a giant yellow bus waiting on the street.',elementary,'honeyglass')

middle=dict(id='middle_school',name='Crossbell Middle School',spawn=[2700,5750],exit=[2700,5750],merchant=[3450,5570],rooms=[
 room('street','CROSSBELL • SCHOOL STREET',[300,5100,7900,1050],'street'),room('entry','',[2350,4700,800,600],'yard'),room('foyer','WELCOME TO CROSSBELL',[2100,3700,1450,1100]),
 room('hall','THE CLUB CONCOURSE',[800,3000,4300,900]),room('library','LIBRARY • THE QUIET WING',[800,1250,1450,1650],'carpet'),room('lab','SCIENCE CLUB',[2750,1000,2200,1850]),
 room('lib_link','',[1300,2750,400,500]),room('lab_link','',[3600,2700,400,500]),room('gym','AFTER-SCHOOL GYM',[800,3950,1000,1050],'wood'),room('gym_link','',[1250,3700,450,400]),
 room('canteen','CAFETERIA • LUNCHLINE',[3800,4000,1350,1000]),room('caf_link','',[4250,3700,400,450]),room('roof','ROOFTOP • THE BELL TOWER',[5700,700,2500,2700],'roof')],doors=[
 door('front',[2750,4850],[800,45]),door('library',[1500,2900],[400,45],'arrival'),door('lab',[3800,2850],[400,45],'arrival'),door('gym',[1475,3950],[450,45],'arrival'),door('canteen',[4450,4000],[400,45],'gears')],props=[],routes=[
 dict(pos=[4670,3500],end=[6300,3100],requires='lunch',name='Up to the bell tower'),dict(pos=[6300,3100],end=[4670,3500],requires='lunch',name='Down to the school')],gears=[
 dict(id='library',pos=[1750,1850],name='Quiet Gear'),dict(id='lab',pos=[4050,1550],name='Curiosity Gear'),dict(id='gym',pos=[1350,4600],name='Teamwork Gear')],groups={},stages=[
 dict(id='arrival',text='Enter Crossbell and clear the first hallway patrol.',groups=['arrival']),
 dict(id='gears',text='Clear the library, Science Club and gym. Interact with each bell gear.',groups=['library','lab','gym'],collect=True),
 dict(id='lunch',text='The cafeteria has opened. Defeat the Lunchline Leviathan.',boss='lunchline_leviathan',pos=[4500,4500],trigger=[3800,4000,1350,1000]),
 dict(id='roof_patrol',text='Take the stairs at the east end of the hallway. Clear the rooftop.',groups=['roof_patrol']),
 dict(id='bell',text='Silence the Bellwork Colossus, then return to the street.',boss='bellwork_colossus',pos=[7050,1650],trigger=[5700,700,2500,2700])])
middle['groups']['arrival']=encounter([[2600,5200],[2900,4400],[2450,4100],[2650,3500],[3650,3450],[4400,3400]],['backpack_biter','paper_sprite','pencil_scrapper'],1.3)
middle['groups']['library']=encounter([[1250,1800],[1850,1600],[1900,2300],[1250,2550],[1900,2700]],['paper_sprite','hall_monitor','backpack_biter'],1.05)
middle['groups']['lab']=encounter([[3200,1570],[4350,1350],[4500,2200],[3300,2250],[4000,2450]],['culture_blob','paper_sprite','hall_monitor'],1.05)
middle['groups']['gym']=encounter([[1050,4200],[1550,4200],[1000,4750],[1600,4750]],['backpack_biter','pencil_scrapper','hall_monitor'],1.3)
middle['groups']['roof_patrol']=encounter([[6300,2500],[7500,2600],[6100,1400],[7800,1400],[6500,1100],[7550,1000]],['paper_sprite','hall_monitor','backpack_biter'],1.15)
classrooms(middle,'lab',4,3)
for x in [1000,1350,1700]:
 for y in [1430,2120]:middle['props'].append(dict(kind='school_bookshelf',pos=[x,y],size=[190,110],solid=[165,65]))
middle['props'] += [dict(kind='school_hoop',pos=[1000,4040],size=[145,160],solid=[70,55]),dict(kind='school_hoop',pos=[1600,4040],size=[145,160],solid=[70,55]),dict(kind='school_counter',pos=[3950,4220],size=[230,100],solid=[210,62]),dict(kind='school_counter',pos=[4950,4220],size=[230,100],solid=[210,62]),dict(kind='school_clocktower',pos=[7020,950],size=[220,250],solid=[150,85])]
finalize('middle_school','Crossbell Middle School',[8600,7000],'Medium — three clubs, a cafeteria guardian and the bell tower','Recover the Quiet, Curiosity and Teamwork bell gears from three school wings. Break the cafeteria guardian’s spell, climb to the rooftop and stop the Bellwork Colossus before returning to the street.',middle,'moonveil')

high=dict(id='high_school',name='Crossroads High',spawn=[4050,5550],exit=[4050,5550],merchant=[4700,5500],rooms=[
 room('street','CROSSROADS HIGH • SCHOOL STREET',[300,5050,7400,1000],'street'),room('entry','',[3300,4650,1450,600],'yard'),room('foyer','MAIN ENTRANCE',[3300,3800,1450,1050]),
 room('hall','GROUND FLOOR • DEPARTMENT HALL',[1100,2550,5950,750]),room('foyer_link','',[3500,3150,1000,900]),
 room('gym','ATHLETICS • IRON HALL',[1100,3250,2000,1600],'wood'),room('gym_link','',[1900,3100,600,300]),
 room('kitchen','FOODS • THE ENCHANTED KITCHEN',[1100,900,2000,1500]),room('kitchen_link','',[1900,2250,600,500]),
 room('drama','DRAMA • THE BLACK BOX',[4750,900,2200,1500],'stage'),room('drama_link','',[5550,2250,600,500]),
 room('library','STUDENT COMMONS',[5000,3450,1850,1400],'carpet'),room('library_link','',[5500,3150,500,450]),
 room('upper_hall','UPPER FLOOR • THE FINAL EXAM',[9200,2550,5850,800]),room('upper_foyer','',[11100,3150,1500,1200]),
 room('math_room','MATHEMATICS & SCIENCE',[9200,3600,1500,1100]),room('math_link','',[9650,3200,500,550]),
 room('humanities','HUMANITIES',[13300,3600,1700,1100],'carpet'),room('humanities_link','',[13900,3200,500,550]),
 room('exam','THE FINAL EXAM',[10900,650,2300,1650],'exam'),room('exam_link','',[11600,2150,700,650])],doors=[
 door('front',[4050,4900],[1450,45]),door('gym',[2200,3260],[600,45],'arrival'),door('kitchen',[2200,2400],[600,45],'arrival'),door('drama',[5850,2400],[600,45],'arrival'),
 door('commons',[5750,3450],[500,45],'arrival'),door('exam',[11950,2300],[700,50],'upper','Clear the upstairs hallway to unlock the exam')],props=[],routes=[
 dict(pos=[4370,2870],end=[11750,3850],requires='departments',name='Upstairs • Final Exam'),dict(pos=[11750,3850],end=[4370,2870],requires='departments',name='Downstairs • street exit')],gears=[],groups={},stages=[])
high['groups']['arrival']=encounter([[4050,5200],[3800,4200],[4250,4000],[4050,3450],[3550,2900],[4800,2900]],['gravel_skater','pencil_scrapper','paper_sprite','backpack_biter'],1.05)
high['groups']['gym']=encounter([[1550,3650],[2550,3650],[1650,4150],[2600,4400],[2050,4650]],['gravel_skater','backpack_biter','hall_monitor'],1.1)
high['groups']['kitchen']=encounter([[1650,1450],[2600,1450],[1550,2100],[2550,2100],[2300,1800]],['culture_blob','paper_sprite','hall_monitor'],1.15)
high['groups']['drama']=encounter([[5150,1400],[6500,1400],[5200,2050],[6500,2100],[5900,1900]],['gravel_skater','paper_sprite','hall_monitor'],1.15)
high['groups']['upper']=encounter([[11750,3300],[10750,2900],[12850,2900],[9800,4200],[14300,4150],[9900,2850],[14100,2850],[12300,3150]],['hall_monitor','gravel_skater','paper_sprite','culture_blob'],1.3)
high['departments']=[dict(id='drama',boss='spotlight_sovereign',pos=[5880,1430]),dict(id='kitchen',boss='layercake_golem',pos=[2150,1520]),dict(id='gym',boss='iron_barbell',pos=[2150,4100])]
classrooms(high,'math_room',3);classrooms(high,'humanities',4);classrooms(high,'exam',3)
for x in [1400,1800,2200,6000,6400,6800,9600,10000,13500,14000]:high['props'].append(dict(kind='school_locker',pos=[x,2670],size=[90,125],solid=[70,48]))
high['props'] += [dict(kind='school_curtain',pos=[5850,1020],size=[470,170],solid=[370,60]),dict(kind='school_oven',pos=[1300,1100],size=[200,155],solid=[165,70]),dict(kind='school_counter',pos=[2800,1100],size=[220,110],solid=[195,65]),dict(kind='school_weightbench',pos=[1450,3400],size=[250,110],solid=[205,60]),dict(kind='school_weightbench',pos=[2750,3400],size=[250,110],solid=[205,60]),dict(kind='school_hoop',pos=[2100,3450],size=[145,160],solid=[80,50]),dict(kind='school_bookshelf',pos=[5400,3670],size=[220,115],solid=[195,65]),dict(kind='school_bookshelf',pos=[6400,3670],size=[220,115],solid=[195,65])]
finalize('high_school','Crossroads High',[16000,6500],'Hard — three department bosses and four possible Final Exams','Defeat the Drama, Foods and Athletics guardians, climb upstairs, and enter the unlocked exam classroom. The host chooses one random Final Exam per run: fire Mathematics, ghostly wind English, slowing ice History, or poisonous Science. Each has four distinct attacks.',high,'clockwork_orchard')
write('content/manifest.json',manifest)
print('Authored three school realms and eighteen school enemy/boss definitions.')
