extends Node
## Connected waterworks chambers. Two wing encounters unlock the Heart's bridge.
var adventure:Node
var active:=false
var initialized:=false
var done:=false
var cleared:Array=[]
var started:Array=[]
var warnings:Array=[]
var bolts:Array=[]
var clock:=0.0
var spring_used:=false
const TYPES=["sluice_crab","coil_singer","glass_mender","confluence_heart"]
const ROOMS=[Rect2(180,920,700,560),Rect2(1080,280,900,620),Rect2(1080,1500,900,620),Rect2(2210,890,650,620),Rect2(3130,780,850,840),Rect2(2280,280,490,350)]
const WALKS=[Rect2(850,1120,430,160),Rect2(1150,850,150,700),Rect2(1930,520,410,145),Rect2(1930,1750,410,145),Rect2(2230,610,150,1160),Rect2(2800,1120,400,160),Rect2(2400,570,150,380)]
const EXIT=Vector2(3850,1200)
func setup(id:String)->void:
 active=id=="confluence";initialized=false;done=false;cleared.clear();started.clear();warnings.clear();bolts.clear();clock=0;spring_used=false
func floor_at(p:Vector2)->bool:
 for r in ROOMS+WALKS:
  if r.grow(-15).has_point(p):return true
 return false
func barrier()->Rect2:return Rect2(2920,1090,35,220)
func can_stand(p:Vector2)->bool:
 if not floor_at(p):return false
 if not (cleared.has(1) and cleared.has(2)) and barrier().grow(18).has_point(p):return false
 for center in columns():
  if center.distance_to(p)<43:return false
 return true
func columns()->Array[Vector2]:return [Vector2(1390,460),Vector2(1750,750),Vector2(1390,1930),Vector2(1750,1640),Vector2(3330,970),Vector2(3760,1430)]
func spawn_room(index:int)->void:
 started.append(index)
 var r:Rect2=ROOMS[index]
 var types:Array=["sluice_crab","coil_singer","glass_mender","sluice_crab"]
 if index==0:types=["sluice_crab","coil_singer","sluice_crab"]
 if index==4:types=["confluence_heart","coil_singer","glass_mender"]
 for n in types.size():
  var p:Vector2=r.position+r.size*Vector2(.38+.15*(n%3),.38+.25*(n/3))
  while not can_stand(p):p+=Vector2(0,45)
  var boss:bool=types[n]=="confluence_heart"
  adventure.spawn(types[n],p,1200 if boss else 100 if types[n]=="sluice_crab" else 85,boss)
  var foe:Dictionary=adventure.foes()[-1];foe["foundry_room"]=index;foe.skill_timer=1.3+n*.55
func room_alive(index:int)->bool:
 for foe in adventure.foes():
  if str(foe.type) in TYPES and int(foe.get("foundry_room",-1))==index and float(foe.hp)>0:return true
 return false
func on_defeat(foe:Dictionary)->bool:
 if str(foe.type) not in TYPES:return false
 if str(foe.type)=="confluence_heart":
  done=true;adventure.announce("The currents are one again! Reach the glowing east exit and interact.")
 return true
func interact(owner:String)->bool:
 var p:Vector2=adventure.points().get(owner,Vector2.ZERO)
 if done and p.distance_to(EXIT)<120:
  if adventure.arcade:adventure.game.end_match("Confluence Foundry cleared!")
  else:adventure.game.finish_run(true)
  return true
 var spring:=Vector2(2520,430)
 if not spring_used and p.distance_to(spring)<90:
  spring_used=true
  if adventure.arcade:adventure.game._heal(owner,owner,35)
  else:adventure.game.health=minf(adventure.game.max_health(),adventure.game.health+35)
  adventure.announce("The hidden condenser restores 35 health. Its charge is spent.");return true
 return false
func warn(p:Vector2,r:float,damage:float,delay:float,kind:String,end:Vector2=Vector2.ZERO)->void:
 if warnings.size()>=32:return
 warnings.append({"pos":[p.x,p.y],"end":[end.x,end.y],"radius":r,"damage":damage,"left":delay,"total":delay,"kind":kind})
func step(delta:float)->void:
 if not active or not adventure.authoritative():return
 clock+=delta
 if not initialized:initialized=true;adventure.announce("Confluence Foundry: clear both sluice halls to open the Heart bridge. Explore the upper condenser for a reserve heal.")
 for owner in adventure.points():
  if not adventure.alive(str(owner)):continue
  var p:Vector2=adventure.points()[owner]
  for index in [0,1,2,4]:
   if not started.has(index) and ROOMS[index].has_point(p):spawn_room(index)
 for index in started:
  if not cleared.has(index) and not room_alive(index):
   cleared.append(index)
   if adventure.arcade:
    var milestone:=6 if cleared.has(1) and cleared.has(2) else 4 if index in [1,2] else 3
    for owner in adventure.points():adventure.game.levels[owner]=maxi(int(adventure.game.levels.get(owner,1)),milestone)
   if index in [1,2]:adventure.announce("Sluice restored! "+("Both currents restored: the east bridge is open." if cleared.has(1) and cleared.has(2) else "Restore the other sluice hall to open the east bridge."))
 var combat:Node=adventure.combat
 for foe in adventure.foes().duplicate():
  if str(foe.type) not in TYPES or float(foe.hp)<=0 or combat.stunned(combat.npc_key(foe)):continue
  var target:="";var distance:=INF
  for owner in adventure.points():
   if adventure.alive(str(owner)) and foe.pos.distance_to(adventure.points()[owner])<distance:target=str(owner);distance=foe.pos.distance_to(adventure.points()[owner])
  if target.is_empty() or distance>850:continue
  var p:Vector2=foe.pos;var aim:Vector2=(adventure.points()[target]-p).normalized();var boss:bool=foe.type=="confluence_heart"
  var direction:=aim if distance>280 else -aim if distance<170 and foe.type!="sluice_crab" else Vector2.ZERO
  if foe.type=="sluice_crab":direction=aim if distance>48 else Vector2.ZERO
  if boss:direction=aim.orthogonal()*sin(clock*.7)
  var step_distance:float=delta*(85 if boss else 105)*combat.speed_factor(combat.npc_key(foe))
  var next:Vector2=p+direction*step_distance
  var room:Rect2=ROOMS[int(foe.get("foundry_room",0))].grow(-35)
  if can_stand(next) and room.has_point(next):foe.pos=next
  elif can_stand(p+direction.orthogonal()*step_distance) and room.has_point(p+direction.orthogonal()*step_distance):foe.pos=p+direction.orthogonal()*step_distance
  foe.skill_timer=float(foe.skill_timer)-delta
  if float(foe.skill_timer)>0 or not combat.path_clear(p,adventure.points()[target]):continue
  foe.skill_step=int(foe.skill_step)+1
  if boss:
   foe.skill_timer=2.5 if float(foe.hp)>float(foe.max_hp)*.5 else 1.9
   match int(foe.skill_step)%3:
    0:
     for n in 3:warn(adventure.points()[target]+Vector2.from_angle(n*TAU/3)*95,65,18,1.05+n*.18,"water")
    1:
     for side in [-1,1]:warn(p,24,20,1.1,"beam",p+aim.rotated(side*.32)*480)
    2:
     for n in 8:bolts.append({"pos":[p.x,p.y],"aim":[cos(n*TAU/8),sin(n*TAU/8)],"time":2.8,"damage":13})
  elif foe.type=="sluice_crab":
   foe.skill_timer=2;warn(p+aim*65,68,13,.7,"water")
  elif foe.type=="coil_singer":
   foe.skill_timer=2.6;warn(p,18,11,.9,"beam",p+aim*390)
  else:
   foe.skill_timer=3.6
   for ally in adventure.foes():
    if ally.pos.distance_to(p)<190 and float(ally.hp)>0:ally.hp=minf(float(ally.max_hp),float(ally.hp)+9)
   warn(adventure.points()[target],50,8,1.1,"glass")
 for i in range(warnings.size()-1,-1,-1):
  var w:Dictionary=warnings[i];w.left=float(w.left)-delta
  if float(w.left)>0:continue
  var p:Vector2=combat.vec(w.pos)
  for owner in adventure.points():
   var q:Vector2=adventure.points()[owner];var inside:=p.distance_to(q)<float(w.radius)
   if str(w.kind)=="beam":inside=Geometry2D.get_closest_point_to_segment(q,p,combat.vec(w.end)).distance_to(q)<float(w.radius)
   if inside and combat.path_clear(p,q):
    combat.damage(combat.player_key(str(owner)),float(w.damage),"enemy")
    if str(w.kind)=="water":combat.apply_status(combat.player_key(str(owner)),"slow",1.3,"enemy",.65)
  combat.confluence.flash(p,float(w.radius),"water" if str(w.kind)=="water" else "volt");warnings.remove_at(i)
 for i in range(bolts.size()-1,-1,-1):
  var b:Dictionary=bolts[i];var p:Vector2=combat.vec(b.pos);var next:Vector2=p+combat.vec(b.aim)*225*delta;b.time=float(b.time)-delta
  if not combat.path_clear(p,next):bolts.remove_at(i);continue
  var hit:=false
  for owner in adventure.points():
   if Geometry2D.get_closest_point_to_segment(adventure.points()[owner],p,next).distance_to(adventure.points()[owner])<23:combat.damage(combat.player_key(str(owner)),float(b.damage),"enemy");hit=true;break
  b.pos=[next.x,next.y]
  if hit or float(b.time)<=0:bolts.remove_at(i)
func snapshot()->Dictionary:return {"active":active,"initialized":initialized,"done":done,"cleared":cleared,"started":started,"warnings":warnings,"bolts":bolts,"clock":clock,"spring_used":spring_used}
func receive(d:Dictionary)->void:
 active=bool(d.get("active",false));initialized=bool(d.get("initialized",false));done=bool(d.get("done",false));cleared=d.get("cleared",[]);started=d.get("started",[]);warnings=d.get("warnings",[]);bolts=d.get("bolts",[]);clock=float(d.get("clock",0));spring_used=bool(d.get("spring_used",false))
func draw_world(c:Node2D,camera:Vector2)->void:
 if not active:return
 var view:=Rect2(camera-Vector2(150,150),Vector2(2300,1600))
 c.draw_rect(Rect2(-camera,Vector2(4200,2400)),Color("#102c3b"))
 # Water channels animate gently; geometry and collision use the same room plan.
 for x in range(maxi(0,int(camera.x/100)-1),mini(43,int(camera.x/100)+24)):
  for y in range(maxi(0,int(camera.y/90)-1),mini(28,int(camera.y/90)+18)):
   var p:=Vector2(x*100,y*90)-camera;c.draw_arc(p,18,clock*.3,clock*.3+PI,10,Color(.3,.68,.73,.16),2,true)
 for r in WALKS+ROOMS:
  if not view.intersects(r):continue
  c.draw_rect(Rect2(r.position-camera+Vector2(0,12),r.size),Color("#0c192b"))
  c.draw_rect(Rect2(r.position-camera,r.size),Color("#c19660"));c.draw_rect(Rect2(r.position-camera+Vector2(8,8),r.size-Vector2(16,16)),Color("#334c5b"))
  for x in range(int(r.position.x)+20,int(r.end.x)-20,64):
   for y in range(int(r.position.y)+20,int(r.end.y)-20,64):
    var p:=Vector2(x,y)
    if view.has_point(p):c.draw_rect(Rect2(p-camera,Vector2(59,59)),Color("#3d5963") if (x/64+y/64)%2 else Color("#405965"))
 for n in ROOMS.size():
  var r:Rect2=ROOMS[n]
  if not view.intersects(r):continue
  var center:Vector2=r.get_center()-camera
  # An inlaid seal teaches the two-colour identity without obscuring combat.
  var seal_color:=Color(.4,.85,.8,.14) if n==1 else Color(.95,.75,.35,.14) if n==2 else Color(.6,.8,.85,.12)
  c.draw_arc(center,105,0,TAU,48,seal_color,5,true)
  c.draw_arc(center,82,0,TAU,40,seal_color,2,true)
  for spoke in 8:
   var direction:=Vector2.from_angle(spoke*TAU/8)
   c.draw_line(center+direction*88,center+direction*103,seal_color,3,true)
  for side in [0,1]:
   var a:Vector2=r.position-camera+Vector2(45,145+side*(r.size.y-195))
   var b:Vector2=a+Vector2(r.size.x-90,0)
   c.draw_line(a,b,Color("#243d4b"),12,true);c.draw_line(a,b,Color("#8a7357"),4,true)
   for x in range(0,int(r.size.x)-90,80):
    var q:=a+Vector2(x,0);c.draw_circle(q,5,Color("#bea37a"));c.draw_circle(q,2,Color("#43505c"))
  # Low glass inspection plates and drainage grates are flush with the floor.
  for side in [0,1]:
   var q:=r.position-camera+Vector2(70+side*(r.size.x-205),r.size.y-120)
   c.draw_rect(Rect2(q,Vector2(90,45)),Color("#1c3749"))
   c.draw_rect(Rect2(q+Vector2(4,4),Vector2(82,37)),Color(.25,.7,.72,.32))
   for bar in 6:c.draw_line(q+Vector2(10+bar*14,4),q+Vector2(10+bar*14,41),Color("#799b9b"),2)
  var tint:=Color("#78d8d0") if n==1 else Color("#f2cd75") if n==2 else Color("#9bb9c9")
  # Glass roof edges, brass supports and lit windows frame each hall.
  for x in range(int(r.position.x)+45,int(r.end.x)-30,100):
   var p:=Vector2(x,r.position.y+10)-camera;c.draw_rect(Rect2(p-Vector2(20,20),Vector2(40,35)),Color("#182b40"));c.draw_rect(Rect2(p-Vector2(15,15),Vector2(30,23)),Color(tint,.6));c.draw_line(p+Vector2(0,-15),p+Vector2(0,8),Color("#c29a67"),3)
  for side in [0,1]:
   var p:=Vector2(r.position.x+30+side*(r.size.x-60),r.position.y+45)-camera;c.draw_rect(Rect2(p,Vector2(16,48)),Color("#aa845c"));c.draw_circle(p+Vector2(8,-5),7,tint)
  var names:=["ARRIVAL DOCK","RAINWORK HALL","COPPER CHOIR","CONFLUENCE","THE DIVIDED HEART","HIDDEN CONDENSER"]
  c.draw_string(ThemeDB.fallback_font,r.position-camera+Vector2(35,90),names[n],HORIZONTAL_ALIGNMENT_LEFT,-1,20,tint)
 for p in columns():
  c.draw_circle(p-camera+Vector2(0,10),40,Color(0,0,0,.3));c.draw_rect(Rect2(p-camera-Vector2(25,60),Vector2(50,88)),Color("#bc996e"));c.draw_rect(Rect2(p-camera-Vector2(17,54),Vector2(34,64)),Color("#506c78"));c.draw_circle(p-camera-Vector2(0,38),12,Color("#8ae1dc"))
 # Working waterwheels and copper turbines outside the walking lanes.
 for location in [Vector2(965,550),Vector2(2090,1810),Vector2(4070,1160),Vector2(2120,430)]:
  var center:Vector2=location-camera
  c.draw_rect(Rect2(center-Vector2(20,95),Vector2(40,190)),Color("#304f62"))
  for stream in 5:
   var q:=center+Vector2(-14+stream*7,-85+fposmod(clock*55+stream*32,155))
   c.draw_line(q,q+Vector2(0,24),Color(.4,.8,.83,.4),3,true)
  c.draw_arc(center,68,0,TAU,32,Color("#ba8a56"),9,true)
  for spoke in 8:c.draw_line(center,center+Vector2.from_angle(clock*.5+spoke*TAU/8)*62,Color("#9eb8b2"),5,true)
 var spring:=Vector2(2520,430)-camera;c.draw_circle(spring,37,Color("#132a3b"));c.draw_arc(spring,33,0,TAU,28,Color("#b5cfbd"),5,true);c.draw_circle(spring,23,Color("#42636d") if spring_used else Color("#70d7d1"))
 if not (cleared.has(1) and cleared.has(2)):
  c.draw_rect(Rect2(barrier().position-camera,barrier().size),Color(.5,.8,1,.4));c.draw_string(ThemeDB.fallback_font,barrier().position-camera+Vector2(-90,-20),"Restore both sluices",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#f2d891"))
 if done:
  c.draw_circle(EXIT-camera,55,Color(.4,.95,.85,.2));c.draw_arc(EXIT-camera,42,clock,clock+TAU,32,Color("#c8fff0"),5,true);c.draw_string(ThemeDB.fallback_font,EXIT-camera+Vector2(-55,-70),"INTERACT: EXIT",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
func draw_on(c:Node2D,camera:Vector2)->void:
 if not active:return
 for w in warnings:
  var p:=Vector2(float(w.pos[0]),float(w.pos[1]))-camera;var tint:=Color(1,.48,.3,.28)
  if str(w.kind)=="beam":
   var end:=Vector2(float(w.end[0]),float(w.end[1]))-camera;c.draw_line(p,end,tint,float(w.radius)*2,true);c.draw_dashed_line(p,end,Color("#ffd987"),2,14,true)
  else:c.draw_circle(p,float(w.radius),tint);c.draw_arc(p,float(w.radius)*(1-float(w.left)/float(w.total)),0,TAU,28,Color("#ffe1a2"),3,true)
 for b in bolts:
  var p:=Vector2(float(b.pos[0]),float(b.pos[1]))-camera;c.draw_circle(p,9,Color("#ebca70"));c.draw_circle(p,4,Color.WHITE)
