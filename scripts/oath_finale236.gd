extends RefCounted
## Authoritative finale. One retained floor mesh, one bounded fog mesh, deterministic moving lights.
const TYPE="unwritten_sovereign"
const FORMS=[TYPE,"unwritten_ascendant","unwritten_worldbreaker"]
const OLD_EXIT=Vector2(10150,6160)
const START=Vector2(15200,1000)
const DOOR=Vector2(17150,3800)
const ARENA=Rect2(15100,5400,2700,2100)
const ARRIVAL=Vector2(16450,7150)
const THRONE=Vector2(16450,6250)
const EXIT=Vector2(16450,5850)
const EXTENT=Vector2(21400,8500)
const FLOORS=[Rect2(14950,750,5400,500),Rect2(19850,750,500,1400),Rect2(15400,1650,4950,500),Rect2(15400,1650,500,1600),Rect2(15400,2750,5000,500),Rect2(19900,2750,500,1300),Rect2(16900,3550,3500,500),Rect2(16900,1180,400,360),Rect2(18100,2080,400,360)]
var adventure:Node
var enabled=false
var mode="dormant"
var phase=1
var clock=0.0
var phase_clock=0.0
var left=0.0
var turn=0
var attack_timer=2.0
var bars_timer=0.0
var sanctuary_entry=false
var resolved:Array=[]
var hp=0.0
var max_hp=1.0
var hazards:Array=[]
var last_hit:Dictionary={}
var floor_mesh:ArrayMesh
var fog_mesh:ArrayMesh
var fog_stamp=-1.0
var fog_camera=Vector2.INF
var packet_at=0
var lava:Array=[]
var holes:Array=[]
func setup(id:String)->void:
 enabled=id=="shattered_oath";mode="dormant";phase=1;clock=0;phase_clock=0;left=0;turn=0;attack_timer=2;sanctuary_entry=false;hp=0;max_hp=1;resolved.clear();hazards.clear();last_hit.clear();lava.clear();holes.clear();floor_mesh=null;fog_mesh=null;fog_stamp=-1
 if not enabled:return
 for n in 8:
  lava.append(Rect2(15900+n*510,830+(n%2)*180,170,140))
  lava.append(Rect2(15950+n*470,1730+(n%2)*170,180,130))
  lava.append(Rect2(15900+n*500,2830+(n%2)*180,160,130))
 for n in 7:
  holes.append(Vector2(16550+n*500,1020+(-1 if n%2 else 1)*90))
  holes.append(Vector2(16200+n*520,1910+(-1 if n%2 else 1)*95))
  holes.append(Vector2(16300+n*510,3000+(-1 if n%2 else 1)*90))
func local_point()->Vector2:return adventure.game.local_pos if adventure.arcade else adventure.game.position_in_world
func owns(p:Vector2)->bool:return enabled and p.x>14500
func in_depth()->bool:return enabled and mode!="dormant" and owns(local_point())
func can_stand(p:Vector2)->bool:
 if ARENA.grow(-25).has_point(p):return true
 for rect in FLOORS:
  if rect.grow(-22).has_point(p):return true
 return false
func open_gate()->void:
 if mode!="dormant":return
 mode="gate";adventure.restore_xp();adventure.complete=false
 adventure.announce("The Usurper is gone. Stolen XP restored. The exit portal is open…")
func widen()->void:
 if adventure.arcade:adventure.game.FIELD=Rect2(Vector2.ZERO,EXTENT)
func interact(id:String)->bool:
 if not adventure.authoritative():return false
 if not enabled or mode=="dormant" or not adventure.alive(id):return false
 var p:Vector2=adventure.points().get(id,Vector2.ZERO)
 if p.distance_to(OLD_EXIT)<150:
  if mode=="gate":mode="course"
  widen();adventure.teleport(id,START);adventure.announce("Beyond the false ending • follow the firelight. Lava burns; open chasms are fatal.");return true
 if not owns(p):return false
 if p.distance_to(DOOR)<160:
  if id not in resolved:
   resolved.append(id)
   if adventure.arcade:adventure.game.health[id]=maxf(float(adventure.game.health.get(id,0)),adventure.game._max_hp(id)*.75)
   else:adventure.game.health=maxf(adventure.game.health,adventure.game.max_health()*.75)
  if mode=="course":start_boss()
  adventure.teleport(id,ARRIVAL);return true
 if mode=="won" and p.distance_to(EXIT)<165:
  if adventure.arcade:adventure.game.end_match("The final Oath is restored • the Unwritten Sovereign defeated!")
  else:adventure.game.finish_run(true)
  return true
 return true # New room never routes through the old trial portals.
func boss()->Dictionary:
 for e in adventure.foes():
  if bool(e.get("finale_actor",false)):return e
 return {}
func start_boss()->void:
 if mode!="course":return
 mode="battle";phase=1;phase_clock=0;turn=0;attack_timer=2.3;hazards.clear()
 adventure.spawn(TYPE,THRONE,6200,true,5)
 var e:Dictionary=adventure.foes()[-1];e.finale_actor=true;e.sprite=TYPE;e.hit_radius=66.0;e.v143_pose=0.0;hp=float(e.hp);max_hp=float(e.max_hp)
 adventure.announce("THE UNWRITTEN SOVEREIGN • I: The Sealed Crown. Read its windups and find the gaps.")
func adjust_damage(e:Dictionary,amount:float)->float:
 if not bool(e.get("finale_actor",false)):return amount
 if mode!="battle":return 0.0
 var floor_hp:float=max_hp*(.66 if phase==1 else .33 if phase==2 else 0.0)
 var accepted:float=maxf(0,minf(amount,float(e.hp)-floor_hp))
 if phase<3 and float(e.hp)-accepted<=floor_hp+.001:
  mode="interlude";left=10.5 if phase==1 else 13.0;phase_clock=0;bars_timer=0;sanctuary_entry=phase==2;hazards.clear();e.windup=0;e.v143_pose=0
  adventure.announce("EMBER PROCESSION • survive the moving gaps! The crown is sealed." if phase==1 else "OATHFALL • reach each lit sanctuary before the floor erupts!")
 hp=float(e.hp)-accepted
 return accepted
func on_defeat(e:Dictionary)->bool:
 if not bool(e.get("finale_actor",false)):return false
 mode="won";hp=0;hazards.clear();adventure.complete=true
 adventure.announce("THE LAST OATH IS RESTORED • the true exit has awakened. E / Interact to return victorious.")
 return true
func visual_clock()->float:
 return clock+(minf(.3,(Time.get_ticks_msec()-packet_at)/1000.0) if adventure.arcade and not adventure.authoritative() else 0.0)
func fireballs(t:float)->Array:
 var out:Array=[]
 for n in 18:
  var row=n%3;var x=15500+(n/3)*880;var y=[1000.0,1900.0,3000.0][row]
  var u=fposmod(t*.2+n*.217,1.0)
  var p=Vector2(x+sin(t*.23+n)*150,y-630+u*1260)
  out.append({"p":p,"v":Vector2(cos(t*.23+n)*34.5,252),"r":19.0})
 return out
func add_hazard(kind:String,p:Vector2,q:Vector2,radius:float,damage:float,delay:float,duration:float=1.0,angle:float=0.0)->void:
 if hazards.size()>=36:return
 hazards.append({"kind":kind,"p":[p.x,p.y],"q":[q.x,q.y],"r":radius,"damage":damage,"warn":delay,"life":duration,"age":0.0,"angle":angle})
func point(a:Array)->Vector2:return Vector2(a[0],a[1])
func strike(p:Vector2)->void:
 var n=turn%4
 match n:
  0:
   for k in 3:
    var x=p.x+(k-1)*190
    add_hazard("line",Vector2(x,ARENA.position.y+80),Vector2(x+(-260 if k%2 else 260),ARENA.end.y-80),30,28+phase*3,1.15,.45)
  1:
   add_hazard("ring",THRONE,Vector2.ZERO,phase_clock*.21,28+phase*3,1.1,2.8,float(turn)*.71)
   if phase>=2:add_hazard("ring",THRONE,Vector2.ZERO,0,25+phase*3,1.8,2.8,float(turn)*.71+PI)
  2:
   for id in adventure.points():
    if not adventure.alive(str(id)) or not ARENA.has_point(adventure.points()[id]):continue
    var target:Vector2=adventure.points()[id]
    for k in 3:add_hazard("circle",target+Vector2((k-1)*150,0),Vector2.ZERO,75 if phase<3 else 90,26+phase*3,1.2+k*.18,.5)
  3:
   add_hazard("wheel",THRONE,Vector2.ZERO,620,24+phase*3,1.4,5.0,phase_clock*.24)
   if phase==3:add_hazard("wheel",THRONE+Vector2(0,420),Vector2.ZERO,420,26,1.9,4.5,-phase_clock*.24)
 if phase>=2 and turn%3==1:
  var destination=Vector2(THRONE.x+(-440 if turn%2 else 440),THRONE.y+sin(turn)*260)
  add_hazard("circle",destination,Vector2.ZERO,130,30,1.3,.45)
  var e=boss()
  if not e.is_empty():e.pos=destination
 turn+=1
func safe_center(t:float)->Vector2:
 var centers=[THRONE+Vector2(-420,-200),THRONE+Vector2(420,-200),THRONE+Vector2(420,400),THRONE+Vector2(-420,400)]
 return centers[mini(3,int(t/3.25))]
func contact(id:String,damage:float,cause:String)->void:
 if clock-float(last_hit.get(id,-10))<.7:return
 last_hit[id]=clock
 adventure.hit_player(id,damage,"",preload("res://scripts/defeat_credit.gd").hazard(cause))
func step(delta:float)->void:
 if not adventure.authoritative():return
 if not enabled or mode=="dormant" or mode=="gate" or mode=="won":return
 clock+=delta;phase_clock+=delta
 var e=boss()
 if not e.is_empty():
  hp=float(e.hp);e.attack_timer=99;e.secondary_timer=99;e.skill_timer=99
  if mode=="battle":
   var disabled=adventure.combat.stunned(adventure.combat.npc_key(e))
   var slow=adventure.combat.speed_factor(adventure.combat.npc_key(e))
   var desired=THRONE+Vector2(cos(phase_clock*.36)*390,sin(phase_clock*.5)*240)
   e.pos=(e.pos as Vector2).move_toward(desired,(95+phase*18)*delta*(0 if disabled else slow))
   attack_timer-=0 if disabled else delta
   if attack_timer<1.1:e.v143_pose=adventure.newcomers.clock+.15
   if attack_timer<=0 and not disabled:
    var target=ARRIVAL;var distance=INF
    for id in adventure.points():
     var q:Vector2=adventure.points()[id]
     if adventure.alive(str(id)) and ARENA.has_point(q) and q.distance_to(e.pos)<distance:target=q;distance=q.distance_to(e.pos)
    strike(target);attack_timer=3.5 if phase==1 else 2.9 if phase==2 else 2.4
 if mode=="interlude":
  if sanctuary_entry:
   sanctuary_entry=false
   var slot=0
   for id in adventure.points():
    if adventure.alive(str(id)) and ARENA.has_point(adventure.points()[id]):adventure.teleport(str(id),safe_center(0)+Vector2(slot*30,0));slot+=1
  left-=delta
  if phase==1:
   bars_timer-=delta
   if bars_timer<=0:
    bars_timer=1.7;add_hazard("wall",Vector2(ARENA.position.x+80,ARENA.position.y+50),Vector2(ARENA.end.x-80,ARENA.position.y+50),200,34,1.0,4.7,float(turn)*.8);turn+=1
  if left<=0:
   phase+=1;mode="battle";phase_clock=0;attack_timer=2.0;hazards.clear()
   if not e.is_empty():e.sprite=FORMS[phase-1]
   adventure.announce("II: THE UNBOUND ASCENDANT • twin pulse rings and shifting lances." if phase==2 else "III: WORLD BREAKER • the crown burns. Watch both fire wheels!")
 for n in range(hazards.size()-1,-1,-1):
  hazards[n].age=float(hazards[n].age)+delta
  if float(hazards[n].age)>float(hazards[n].warn)+float(hazards[n].life):hazards.remove_at(n)
 for key in adventure.points():
  var id=str(key);var p:Vector2=adventure.points()[id]
  if not adventure.alive(id) or not owns(p):continue
  if not ARENA.has_point(p):
   for hole in holes:
    if p.distance_to(hole)<52:contact(id,99999,"The Unwritten Chasm");break
   for rect in lava:
    if rect.has_point(p):contact(id,26,"Oath-depth lava")
   for f in fireballs(clock):
    var previous:Vector2=f.p-f.v*delta
    if Geometry2D.get_closest_point_to_segment(p,previous,f.p).distance_to(p)<float(f.r)+20:contact(id,25,"Wandering oathfire")
   continue
  if mode=="interlude" and phase==2 and fmod(phase_clock,3.25)>1.5 and p.distance_to(safe_center(phase_clock))>250:contact(id,32,"Oathfall • outside the sanctuary")
  for h in hazards:
   var age:float=float(h.age)-float(h.warn)
   if age<0:continue
   var hit=false;var a=point(h.p);var b=point(h.q);var r:float=h.r
   match str(h.kind):
    "circle":hit=p.distance_to(a)<r+16
    "line":hit=Geometry2D.get_closest_point_to_segment(p,a,b).distance_to(p)<r+18
    "ring":
     var radius=70+age*300;var gap=wrapf((p-a).angle()-float(h.angle),-PI,PI)
     hit=absf(p.distance_to(a)-radius)<32 and absf(gap)>.56
    "wheel":
     var v=p-a;var angle=float(h.angle)+age*(.32 if phase<3 else .4);var arms=4 if phase<3 else 6
     if v.length()>100 and v.length()<r:
      var d=absf(wrapf(v.angle()-angle,-PI/arms,PI/arms));hit=d*v.length()<26
    "wall":
     var y=a.y+age*400;var gap_x=ARENA.get_center().x+sin(float(h.angle))*680
     hit=absf(p.y-y)<37 and absf(p.x-gap_x)>float(h.r)
   if hit:contact(id,float(h.damage),"Unwritten Sovereign • "+str(h.kind))
func snapshot()->Dictionary:return {"resolved":resolved,"mode":mode,"phase":phase,"clock":clock,"phase_clock":phase_clock,"left":left,"turn":turn,"hp":hp,"max_hp":max_hp,"hazards":hazards}
func receive(d:Dictionary)->void:
 if not enabled:return
 resolved=d.get("resolved",[]);mode=str(d.get("mode","dormant"));phase=clampi(int(d.get("phase",1)),1,3);clock=float(d.get("clock",0));phase_clock=float(d.get("phase_clock",0));left=float(d.get("left",0));turn=int(d.get("turn",0));hp=float(d.get("hp",0));max_hp=maxf(1,float(d.get("max_hp",1)));hazards=d.get("hazards",[]).slice(0,36);packet_at=Time.get_ticks_msec()
 if mode!="dormant":widen()
func quad(v:PackedVector3Array,c:PackedColorArray,idx:PackedInt32Array,rect:Rect2,tint:Color)->void:
 var n=v.size()
 for p in [rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)]:v.append(Vector3(p.x,p.y,0));c.append(tint)
 for k in [0,1,2,0,2,3]:idx.append(n+k)
func make_mesh(v:PackedVector3Array,c:PackedColorArray,idx:PackedInt32Array)->ArrayMesh:
 var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=v;arrays[Mesh.ARRAY_COLOR]=c;arrays[Mesh.ARRAY_INDEX]=idx
 var m=ArrayMesh.new();m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);return m
func draw_ground(c:CanvasItem,camera:Vector2)->void:
 if not in_depth():return
 if floor_mesh==null:
  var vertices=PackedVector3Array();var colors=PackedColorArray();var indices=PackedInt32Array()
  for rect in FLOORS+[ARENA]:
   quad(vertices,colors,indices,rect,Color("#0d111a"))
   for x in ceili(rect.size.x/128):
    for y in ceili(rect.size.y/128):
     var size=Vector2(minf(124,rect.size.x-x*128-4),minf(124,rect.size.y-y*128-4))
     if size.x<=0 or size.y<=0:continue
     var tile=Rect2(rect.position+Vector2(x*128+2,y*128+2),size)
     var tint=Color("#343b42") if (x*13+y*17)%4 else Color("#424346")
     quad(vertices,colors,indices,tile,tint);quad(vertices,colors,indices,Rect2(tile.position,Vector2(tile.size.x,3)),Color("#626366"));quad(vertices,colors,indices,Rect2(tile.position+Vector2(0,tile.size.y-5),Vector2(tile.size.x,5)),Color("#222a33"));quad(vertices,colors,indices,Rect2(tile.position+Vector2(tile.size.x-4,3),Vector2(4,tile.size.y-5)),Color("#292d35"))
     if (x+y)%5==0:quad(vertices,colors,indices,Rect2(tile.position+Vector2(17,31),Vector2(31,2)),Color("#535557"))
  floor_mesh=make_mesh(vertices,colors,indices)
 c.draw_rect(Rect2(Vector2.ZERO,c.get_viewport_rect().size),Color("#020308"));c.draw_set_transform(-camera);c.draw_mesh(floor_mesh,null);c.draw_set_transform(Vector2.ZERO)
 for rect in lava:
  if not Rect2(camera,c.get_viewport_rect().size).grow(50).intersects(rect):continue
  var box=Rect2(rect.position-camera,rect.size);var edges=PackedVector2Array([box.position+Vector2(12,0),box.position+Vector2(box.size.x-23,4),box.position+Vector2(box.size.x,20),box.end-Vector2(5,16),box.end-Vector2(24,0),box.position+Vector2(18,box.size.y-3),box.position+Vector2(0,box.size.y-20),box.position+Vector2(3,19)])
  c.draw_colored_polygon(edges,Color("#6e5145"));var inner=PackedVector2Array()
  for edge in edges:inner.append(edge.lerp(box.get_center(),.13))
  c.draw_colored_polygon(inner,Color("#c04d28"));c.draw_polyline(inner+PackedVector2Array([inner[0]]),Color("#f08038"),3,true)
  for k in 3:
   var p=box.position+Vector2(20+k*48,box.size.y*.5+sin(visual_clock()*2+k)*18);c.draw_line(p,p+Vector2(25,-8),Color("#ffcf77"),4,true)
 for hole in holes:
  if not Rect2(camera,c.get_viewport_rect().size).grow(90).has_point(hole):continue
  var rim=PackedVector2Array();var pit=PackedVector2Array()
  for n in 11:
   var ray=Vector2.from_angle(n*TAU/11);rim.append(hole-camera+ray*(60+sin(n*3.9)*5));pit.append(hole-camera+ray*(51+sin(n*3.9)*5))
  c.draw_colored_polygon(rim,Color("#665858"));c.draw_colored_polygon(pit,Color("#010106"));c.draw_arc(hole-camera,59,.2,PI,16,Color("#a28d79"),3,true)
 if ARENA.has_point(local_point()):
  c.draw_arc(THRONE-camera,670,0,TAU,80,Color("#8a775e"),5,true)
  c.draw_arc(THRONE-camera,310,.2,TAU-.2,64,Color("#675c52"),3,true);c.draw_arc(THRONE-camera,160,0,TAU,48,Color("#79684d"),3,true)
  for n in 16:
   var angle=n*TAU/16;var p=THRONE+Vector2.from_angle(angle)*325-camera;c.draw_line(p,p+Vector2.from_angle(angle+.7)*20,Color("#a18e65"),3,true)
  for n in 12:
   var p=THRONE+Vector2.from_angle(n*TAU/12)*670-camera;c.draw_line(p,p+Vector2.from_angle(n*TAU/12)*30,Color("#c7a55c"),3,true)
var lava_box:StyleBoxFlat
func lava_style()->StyleBoxFlat:
 if lava_box==null:
  lava_box=StyleBoxFlat.new();lava_box.bg_color=Color("#b74425");lava_box.border_color=Color("#634438");lava_box.set_border_width_all(7);lava_box.set_corner_radius_all(14)
 return lava_box
func lights(camera:Vector2,view:Vector2)->Array:
 var result=[{"p":local_point()-camera,"r":155.0}]
 for f in fireballs(visual_clock()):
  var p:Vector2=f.p-camera
  if Rect2(-Vector2.ONE*260,view+Vector2.ONE*520).has_point(p):result.append({"p":p,"r":260.0})
 for p in [START,Vector2(20100,1900),Vector2(15650,3000),DOOR]:
  if Rect2(camera,view).grow(150).has_point(p):result.append({"p":p-camera,"r":110.0})
 if ARENA.has_point(local_point()):
  var e=boss();result.append({"p":(e.pos if not e.is_empty() else THRONE)-camera,"r":620.0})
  if mode=="interlude" and phase==2:
   result.append({"p":safe_center(phase_clock)-camera,"r":420.0});result.append({"p":safe_center(minf(12.9,phase_clock+3.25))-camera,"r":340.0})
  for h in hazards:
   if result.size()>=24:break
   if h.kind=="circle":result.append({"p":point(h.p)-camera,"r":170.0})
 for rect in lava:
  if result.size()>=24:break
  if Rect2(camera,view).grow(85).has_point(rect.get_center()):result.append({"p":rect.get_center()-camera,"r":105.0})
 return result
func draw_fog(c:CanvasItem,camera:Vector2,view:Vector2)->void:
 if not in_depth():return
 var t=visual_clock()
 if fog_mesh==null or absf(t-fog_stamp)>.033 or fog_camera.distance_to(camera)>8:
  fog_stamp=t;fog_camera=camera;var illumination=lights(camera,view);var v=PackedVector3Array();var col=PackedColorArray();var idx=PackedInt32Array();var cols=ceili(view.x/40);var rows=ceili(view.y/40)
  for y in rows+1:
   for x in cols+1:
    var p=Vector2(x*view.x/cols,y*view.y/rows);var alpha=1.0
    for light in illumination:
     var offset:Vector2=p-light.p;var radius:float=light.r
     if absf(offset.x)>radius or absf(offset.y)>radius:continue
     alpha=minf(alpha,smoothstep(radius*.26,radius,offset.length()))
    v.append(Vector3(p.x,p.y,0));col.append(Color(0,0,0,alpha))
  for y in rows:
   for x in cols:
    var n=y*(cols+1)+x
    for k in [0,1,cols+2,0,cols+2,cols+1]:idx.append(n+k)
  fog_mesh=make_mesh(v,col,idx)
 c.draw_mesh(fog_mesh,null)
func draw_on(c:CanvasItem,camera:Vector2)->void:
 if not enabled or mode=="dormant":return
 if mode=="gate" or not owns(local_point()):
  var p=OLD_EXIT-camera;c.draw_string(ThemeDB.fallback_font,p+Vector2(-100,-98),"EXIT PORTAL • E / Interact",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#c4e6ba"))
 if not in_depth():return
 var t=visual_clock()
 for f in fireballs(t):
  var p:Vector2=f.p-camera
  if not Rect2(Vector2.ZERO,c.get_viewport_rect().size).grow(80).has_point(p):continue
  var axis:Vector2=f.v.normalized();var side=axis.orthogonal();var tail=p-axis*(61+sin(t*5+p.x)*9)
  c.draw_colored_polygon(PackedVector2Array([tail,p-axis*10+side*16,p+axis*15,p-axis*10-side*16]),Color("#a73929"));c.draw_colored_polygon(PackedVector2Array([p-axis*43+side*3,p-axis*5+side*13,p+axis*20,p-axis*4-side*13]),Color("#ef853b"));c.draw_circle(p,17,Color("#f6ad56"));c.draw_circle(p-axis*3-side*3,10,Color("#ffe3a0"));c.draw_circle(p-axis*3-side*5,4,Color("#fff0c6"))
 if not ARENA.has_point(local_point()):
  var p=DOOR-camera;c.draw_arc(p,54,0,TAU,40,Color("#edc181"),5,true);c.draw_string(ThemeDB.fallback_font,p+Vector2(-115,-75),"THE LAST CHAMBER • E",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#edd1a5"))
 for h in hazards:
  var age:float=float(h.age)-float(h.warn);var p=point(h.p)-camera;var q=point(h.q)-camera;var color=Color("#edb36a") if age<0 else Color("#ff7954");var width=3.0 if age<0 else 11.0
  match str(h.kind):
   "circle":c.draw_circle(p,float(h.r),Color(color,.10 if age<0 else .5));c.draw_arc(p,float(h.r),0,TAU,40,color,width,true)
   "line":c.draw_line(p,q,Color(color,.25),float(h.r)*2);c.draw_line(p,q,color,width,true)
   "ring":
    var radius=70+maxf(0,age)*300;var angle:float=h.angle;c.draw_arc(p,radius,angle+.56,angle+TAU-.56,64,color,width,true)
   "wheel":
    var arms=4 if phase<3 else 6;var angle=float(h.angle)+maxf(0,age)*(.32 if phase<3 else .4)
    for n in arms:
     var ray=Vector2.from_angle(angle+TAU*n/arms);c.draw_line(p+ray*100,p+ray*float(h.r),Color(color,.24),23,true);c.draw_line(p+ray*100,p+ray*float(h.r),color,width,true)
   "wall":
    var y=p.y+maxf(0,age)*400;var gap_x=ARENA.get_center().x+sin(float(h.angle))*680-camera.x
    for seg in [[p.x,gap_x-float(h.r)],[gap_x+float(h.r),q.x]]:
     c.draw_line(Vector2(seg[0],y),Vector2(seg[1],y),Color(color,.25),60,true);c.draw_line(Vector2(seg[0],y),Vector2(seg[1],y),color,width,true)
 if mode=="interlude" and phase==2:
  var next=safe_center(minf(12.9,phase_clock+3.25))-camera;c.draw_arc(next,250,0,TAU,48,Color(.7,.75,.6,.4),2,true)
  var p=safe_center(phase_clock)-camera;c.draw_circle(p,250,Color(.5,.8,.7,.16));c.draw_arc(p,250,0,TAU,60,Color("#d8e5aa"),6,true)
 if mode=="won":
  var p=EXIT-camera;c.draw_string(ThemeDB.fallback_font,p+Vector2(-115,-98),"THE TRUE EXIT • E / Interact",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#ffe6ad"))
func draw_hud(c:CanvasItem)->void:
 if not in_depth():return
 var font=ThemeDB.fallback_font;var text="THE UNWRITTEN DEPTH • follow moving firelight • lava burns / chasms kill"
 if ARENA.has_point(local_point()):text="THE UNWRITTEN SOVEREIGN • "+["I: SEALED CROWN","II: UNBOUND ASCENDANT","III: WORLD BREAKER"][phase-1]
 if mode=="interlude":text+=" • SEALED"
 var top=124.0 if adventure.arcade else 115.0
 c.draw_style_box(hud_style(),Rect2(30,top,680,76));c.draw_string(font,Vector2(45,top+23),text,HORIZONTAL_ALIGNMENT_LEFT,650,16,Color("#efdbb2"))
 if mode in ["battle","interlude"]:
  c.draw_rect(Rect2(45,top+36,640,10),Color("#332c38"));c.draw_rect(Rect2(45,top+36,640*clampf(hp/max_hp,0,1),10),Color("#db8d60"))
  for split in [.33,.66]:c.draw_line(Vector2(45+640*split,top+34),Vector2(45+640*split,top+48),Color("#f6dfa6"),2)
  if mode=="interlude":c.draw_string(font,Vector2(45,top+66),("EMBER PROCESSION • move through the gaps • " if phase==1 else "OATHFALL • follow the lit sanctuary • ")+str(ceili(left))+"s",HORIZONTAL_ALIGNMENT_LEFT,650,15,Color("#cfe7dc"))
 elif mode=="won":c.draw_string(font,Vector2(45,top+58),"The final Oath is restored. Find the true exit.",HORIZONTAL_ALIGNMENT_LEFT,650,17,Color("#cce8c5"))
 else:c.draw_string(font,Vector2(45,top+58),"Normal hero controls • E / Interact at the final chamber",HORIZONTAL_ALIGNMENT_LEFT,650,15,Color("#c0d3ce"))
var hud_box:StyleBoxFlat
func hud_style()->StyleBoxFlat:
 if hud_box==null:
  hud_box=StyleBoxFlat.new();hud_box.bg_color=Color(.035,.045,.075,.92);hud_box.border_color=Color("#9b855c");hud_box.set_border_width_all(1);hud_box.set_corner_radius_all(7)
 return hud_box
