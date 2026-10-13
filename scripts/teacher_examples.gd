extends RefCounted
## Explicit synthetic data: never ingest into a teacher class or save to a player account.
const S=preload("res://scripts/learning_store.gd")
const B=preload("res://scripts/education_business.gd")
static func definitions()->Dictionary:return JSON.parse_string(FileAccess.get_file_as_string("res://content/studio/teacher-examples.json"))
static func stamp(order:int)->String:return "2026-09-20T"+"%02d:%02d:00Z" % [9+order/60,order%60]
static func art(level:int,pose:int)->String:
 var image=Image.create(48,48,false,Image.FORMAT_RGBA8);image.fill(Color.TRANSPARENT)
 var shift=0 if level==0 else [0,-1,1,0][pose]
 var line=Color("#264953") if level>0 else Color("#7c8c7b");var wool=Color("#e1dec1") if level>0 else Color("#a3aa91")
 image.fill_rect(Rect2i(13,18,22,22),line);image.fill_rect(Rect2i(15,20,18,18),wool);image.fill_rect(Rect2i(12,9+shift,24,17),line);image.fill_rect(Rect2i(14,11+shift,20,13),wool)
 for side in [-1,1]:
  image.fill_rect(Rect2i(22+side*12,11+shift,5,9),Color("#b99166"));image.fill_rect(Rect2i(21+side*5,17+shift,2,3),line)
  image.fill_rect(Rect2i(22+side*7,37+(shift if side==1 else -shift),5,5),line)
 var lantern_y=22 if pose!=3 else 12
 if level==0:lantern_y=22
 image.fill_rect(Rect2i(34,lantern_y,8,13),line);image.fill_rect(Rect2i(36,lantern_y+3,4,7),Color("#f1c866") if level>0 else wool)
 if level==2:
  image.fill_rect(Rect2i(17,27,14,6),Color("#628aa1"));image.fill_rect(Rect2i(18,27,2,6),Color("#a4d6dc"));image.fill_rect(Rect2i(17,12+shift,11,2),Color("#fff4d1"));image.set_pixel(27,22+shift,Color("#caac9a"));image.fill_rect(Rect2i(35,lantern_y+2,2,3),Color("#fff4cf"))
 return Marshalls.raw_to_base64(image.save_png_to_buffer())
static func effect(level:int,frame:int)->String:
 var image=Image.create(48,48,false,Image.FORMAT_RGBA8);image.fill(Color.TRANSPARENT)
 var y=28 if level==0 else [28,21,12,24][frame]
 var line=Color("#264953");image.fill_rect(Rect2i(18,y-3,12,19),line);image.fill_rect(Rect2i(21,y,6,12),Color("#f3d584"));image.fill_rect(Rect2i(21,y-7,6,3),line)
 if level==2 and frame==2:
  for x in 48:
   for py in 48:
    var distance=Vector2(x-24,py-y-6).length()
    if absf(distance-17)<1.4:image.set_pixel(x,py,Color("#85d2c3"))
 return Marshalls.raw_to_base64(image.save_png_to_buffer())
static func attach(d:Dictionary,code:String,kind:String,value:Dictionary,title:String)->void:
 var id=S.fingerprint(value);var order=int(d.next);d.next+=1
 if not d.artifacts.has(id):d.artifacts[id]={"kind":kind,"value":value,"title":title,"time":stamp(order),"origin":"FICTIONAL EXAMPLE • not actual student work","hash":id,"order":order};S.work(d,code).refs.append(id)
static func portfolio(level:int)->Dictionary:
 level=clampi(level,0,2);var spec:Dictionary=definitions().levels[level];var d=S.fresh();d.learner_id=("example"+str(level)).sha256_text().left(32);d.student=spec.student;d.enabled=true
 for code in ["DES1020","COM1145","CSE1110","MAM1010"]:
  var w=S.work(d,code)
  for stage in S.stages(code):
   if not spec.answers[code].has(stage.id):continue
   var order=int(d.next);d.next+=1;w.entries.append({"stage":stage.id,"text":spec.answers[code][stage.id],"time":stamp(order),"order":order})
 var hero=S.P.fresh();hero.project_id="fictional-lantern-"+str(level);hero.author="Fictional demonstration student";hero.concept="Readable co-op support";hero.hero.name="Lantern Keeper";hero.hero.species="Ram";hero.hero.role="Support";hero.hero.lore="An original teaching-example lantern keeper, not an official game hero."
 hero.hero.primary.name="Lantern sweep";hero.hero.primary.range=100;hero.hero.primary.cooldown=1.2;hero.hero.secondary.name="Helping light";hero.hero.secondary.style="heal_wave";hero.hero.secondary.damage=0;hero.hero.secondary.heal=12
 for i in 4:hero.hero.art[["idle","walk1","walk2","attack"][i]]=art(mini(level,1),i)
 hero.notes={"hypothesis":"Lantern contrast improves recognition" if level>0 else "It looks nice","method":"Same training cluster and fixed camera" if level>0 else "No test","observations":"Before and after counts recorded in the journal" if level>0 else "No results","next_change":"Test unfamiliar viewers" if level>0 else "None"}
 attach(d,"DES1020","hero",hero,"Lantern Keeper • prototype")
 if level==2:
  var revision=hero.duplicate(true);revision.revision=2;revision.hero.primary.range=90
  for i in 4:revision.hero.art[["idle","walk1","walk2","attack"][i]]=art(2,i)
  attach(d,"DES1020","hero",revision,"Lantern Keeper • revision 2")
 var ability=S.P.attack("heal_wave");ability.name="Lantern lift animation";ability.damage=0;ability.heal=12;ability.animation=[]
 for frame in 4:ability.animation.append(effect(level,frame))
 attach(d,"COM1145","ability",ability,"Lantern lift • four-frame sequence")
 attach(d,"COM1145","hero",hero,"Lantern Keeper • pose sheet")
 attach(d,"COM1145","quiz",{"module":"COM1145","answers":[1,0,1,2] if level==0 else ([0,1,2,1] if level==1 else [0,1,2,0])},"Animation concept questions")
 var program={"format":"fx-ipo-program","version":1,"name":"Repeated-hit total • draft","code":"# Equal hits\ninput damage\ninput hits\nlet total = damage "+("+" if level==0 else "*")+" hits\noutput total","cases":[{"inputs":{"damage":8,"hits":3},"expected":[24],"error":false}]}
 if level==2:program.cases.append({"inputs":{"damage":8,"hits":0},"expected":[0],"error":false})
 attach(d,"CSE1110","program",program,"IPO code • unfinished tests")
 var business=B.fresh("MAM1010");B.run(business);business.reflection=spec.answers.MAM1010.campaigns;attach(d,"MAM1010","business",business,"Same-product price A/B • draft")
 for code in ["DES1020","COM1145"]:
  var w:Dictionary=d.work[code];var marks={}
  for o in S.catalog()[code].outcomes:
   var feedback=feedback_for(code,str(o.id),level);var score=int(spec.score)
   var rating=["More evidence needed","Meets","Extends"][level]
   if str(o.id)=="5":rating="Developing" if level<2 else "Meets";score=[30,65,85][level];feedback+=" In a real assessment, confirm this through observation; fictional answers cannot prove conduct."
   marks[o.id]={"rating":rating,"score":score,"feedback":feedback}
  var sub={"id":"example-"+str(level)+"-"+code,"module":code,"time":stamp(int(d.next)),"entries":w.entries.duplicate(true),"refs":w.refs.duplicate(),"marks":marks,"teacher":"Illustrative reviewer • practise only","reviewed":stamp(int(d.next)+1),"digest":""};sub.digest=S.digest(sub);d.submissions.append(sub);d.next+=2
 return d
static func feedback_for(code:String,id:String,level:int)->String:
 var evidence={
 "DES1020":{"1":"brief, research, alternatives and evaluation","2":"tool choices, playable prototype and revision","3":"pose sheet and audience presentation","4":"source credits and permission reasoning","5":"routine statement and backup plan","6":"numerical testing and responsibilities","7":"interests, occupation and next learning goal"},
 "COM1145":{"1":"three-style comparison","2":"storyboard, different frames and timing tests","3":"art/audio authorship and permission","4":"presentation, critique and selected motion","5":"workstation and file routines","6":"timing calculation, revision and roles","7":"animation interests and next step"}}
 var subject=str(evidence[code][id])
 if level==0:return "Not yet sufficient: "+subject+" are missing, unsupported or contain misconceptions. Replace broad claims with specific examples and recorded tests; correct copyright/animation statements. A submitted checkbox alone is not achievement."
 if level==1:return "Adequate introductory evidence in "+subject+". The reasoning connects a decision to work shown. Improve by recording another independent test or comparison and explaining the remaining limitation."
 return "Strong, specific evidence in "+subject+" links intentions, decisions and evaluation. The sample preserves revisions and acknowledges limitations. Extend with an unfamiliar audience or another justified iteration rather than simply adding more effects."
