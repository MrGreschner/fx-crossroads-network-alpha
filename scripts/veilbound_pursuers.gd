extends Node
## Shared, bounded, authoritative expedition hunters. All clocks measure active play only.
var adventure:Node
var clock=0.0
var next_visit=180.0
var visits=0
var serial=0
var survivors:Array=[]
var marks:Array=[]
var portals:Array=[]
const ORIGIN=Vector2(16512,16512)
static var cached_kits:Array=[]
static func kits()->Array:
 if cached_kits.is_empty():cached_kits=JSON.parse_string(FileAccess.get_file_as_string("res://content/veilbound_pursuers.json"))
 return cached_kits
static func install(g:Node,multi:bool)->void:
 var defs:Dictionary=g.enemy_defs if multi else g.enemy_types
 for kit in kits():
  defs[kit.id]=kit
  for pose in ["idle","walk1","walk2","attack","0","1"]:g.art[str(kit.id)+"_"+pose]=preload("res://scripts/source_art.gd").texture("res://assets/"+str(kit.id)+"_"+pose+".svg")
func reset()->void:clock=0;next_visit=180;visits=0;serial=0;survivors.clear();marks.clear();portals.clear()
func active()->bool:
 if adventure.arcade:
  # Local arcade modes have no network expedition controller.
  var expedition=adventure.game.get("expedition")
  return expedition!=null and adventure.game.started and adventure.game.mode=="coop" and expedition.kind=="between"
 return adventure.game.waylight.kind=="between" and adventure.game.waylight.active()
func layout():return adventure.game.expedition.expedition if adventure.arcade else adventure.game.waylight.expedition
func actors()->Array:return adventure.foes().filter(func(e):return bool(e.get("veilbound",false)))
func living()->Array:
 var out=[]
 for id in adventure.points():
  if adventure.alive(str(id)):out.append(str(id))
 return out
func kit_for(enemy:Dictionary)->Dictionary:
 for kit in kits():
  if kit.id==enemy.type:return kit
 return {}
func announce(text:String)->void:adventure.announce("VEILBOUND • "+text)
func valid(point:Vector2)->bool:return layout().open(point) and point.distance_to(ORIGIN)>180
func move(origin:Vector2,heading:Vector2,distance:float)->Vector2:
 var result=origin
 for n in maxi(1,ceili(distance/10)):
  var p=origin+heading.normalized()*minf(distance,(n+1)*10)
  if not valid(p):break
  result=p
 return result
func place(target:Vector2,angle:float,radius:float)->Vector2:
 for n in 24:
  var p=target+Vector2.from_angle(angle+n*TAU/24)*radius
  if valid(p) and adventure.combat.path_clear(target,p):return p
 return Vector2.INF
func gate(at:Vector2,color:String)->void:
 if portals.size()<20:portals.append({"at":[at.x,at.y],"left":1.4,"color":color})
func start_visit()->void:
 var players=living()
 if players.is_empty():return
 # The entrance remains a safe extraction point. Defer a portal until someone leaves it.
 var targets=players.filter(func(id):return adventure.points()[id].distance_to(ORIGIN)>260)
 if targets.is_empty():return
 var defs=kits();var roster=survivors.duplicate(true);var count=mini(6,maxi(1,visits))
 while roster.size()<count:
  var target:Vector2=adventure.points()[targets[roster.size()%targets.size()]];var ring=layout().cell_at(target);var elite=visits>0 and (clock>=900 or maxi(absi(ring.x),absi(ring.y))>=maxi(4,layout().max_ring()-1)) and roster.size()==count-1
  var index=randi_range(6,8) if elite else randi_range(0,5);roster.append({"type":defs[index].id,"ratio":1.0})
 var spawned=0;var remaining=[]
 for record in roster.slice(0,count):
  var target:Vector2=adventure.points()[targets[spawned%targets.size()]];var point=place(target,randf()*TAU,300)
  if point==Vector2.INF:remaining.append(record);continue
  var spec:Dictionary={}
  for def in defs:
   if def.id==record.type:spec=def;break
  if spec.is_empty():continue
  adventure.spawn(str(spec.id),point,float(spec.health)*(1+minf(.6,visits*.06)),false)
  var e:Dictionary=adventure.foes()[-1];serial+=1;e.veilbound=true;e.veil_pose=0.0;e.sprite=spec.id;e.hit_radius=25 if not spec.elite else 36;e.veil_age=0.0;e.veil_arrive=1.4;e.veil_dodge=2.0;e.veil_primary=2.0;e.veil_secondary=4.5;e.veil_special=9.0;e.veil_control=7.0;e.veil_control_turn=0;e.veil_phase=randf()*TAU;e.hp=float(e.max_hp)*clampf(float(record.ratio)+.2,.65,1.0);spawned+=1
  gate(point,str(spec.color))
 survivors=remaining
 if spawned>0:
  visits+=1;next_visit=INF;announce("Pursuit %d • %d hunter%s. Drive them to half health to force a retreat. Return to the crossing to extract." % [visits,spawned,"s" if spawned!=1 else ""])
func retreat(e:Dictionary)->void:
 var kit=kit_for(e);gate(e.pos,str(kit.color));survivors.append({"type":e.type,"ratio":clampf(float(e.hp)/float(e.max_hp),.1,1)})
 adventure.foes().erase(e)
 # Leaving is not a kill: no XP, loot or leaderboard credit.
func schedule_return()->void:
 if next_visit==INF and actors().is_empty():next_visit=clock+120;announce("The hunters withdraw. Their next crossing opens in two minutes.")
func outgoing(id:String)->float:
 return .72 if active() and adventure.combat.effect_time("p:"+id,"veil_weaken")>0 else 1.0
func leech_blocked(id:String)->bool:return active() and adventure.combat.effect_time("p:"+id,"veil_dry")>0
func mark(e:Dictionary,at:Vector2,end:Vector2,style:String,radius:float,damage:float,warn:float=1.0)->void:
 if marks.size()>=48:return
 var kit=kit_for(e);marks.append({"uid":int(e.uid),"at":[at.x,at.y],"end":[end.x,end.y],"style":style,"radius":radius,"damage":damage,"warn":warn,"total":warn,"left":1.5 if style=="suction" else .3,"hits":[],"color":kit.color})
func attack(e:Dictionary,slot:String,target:Vector2)->void:
 var kit=kit_for(e);var style=str(kit[slot]);var at:Vector2=e.pos;var aim=(target-at).normalized();e.veil_pose=clock+.65
 var bonus=1.25 if kit.elite else 1.0
 match style:
  "bolt","needle","fan":
   var count=5 if style=="fan" else 1
   for n in count:
    adventure.combat.launch_projectile("enemy",at+aim*30,aim.rotated((n-(count-1)*.5)*.23),{"name":str(kit.name)+" • "+slot,"speed":310 if style=="needle" else 255,"range":720,"color":kit.color,"projectile_radius":6 if style=="needle" else 9,"credit":preload("res://scripts/defeat_credit.gd").resolve(adventure.game,"e:"+str(e.uid),str(kit.name)+" • "+slot)},(12 if count==1 else 9)*bonus)
  "claw","crescent":mark(e,at,at+aim*150,"cleave",135,17*bonus,.8)
  "beam":mark(e,at,at+aim*650,"beam",22,16*bonus,1.1)
  "dash":mark(e,at,move(at,aim,340),"dash",34,18*bonus,1.0)
  "pool":mark(e,target,target,"pool",95,20*bonus,1.25)
  "cross":
   for side in [-.55,.55]:mark(e,at,at+aim.rotated(side)*550,"beam",24,19*bonus,1.1)
  "ring":mark(e,at,at,"ring",230,22*bonus,1.3)
  "orbit":
   for n in 5:
    var p=target+Vector2.from_angle(n*TAU/5)*120;mark(e,p,p,"pool",65,17*bonus,1.2+n*.14)
func control(e:Dictionary,target:Vector2)->void:
 var kit=kit_for(e);var kinds:Array=kit.control
 if kinds.is_empty():return
 var kind=str(kinds[int(e.veil_control_turn)%kinds.size()]);e.veil_control_turn+=1;e.veil_pose=clock+.9
 mark(e,target,target,kind,200 if kind=="suction" else 160,0,1.6)
 announce(str(kit.name)+" • "+{"suction":"VACUUM: leave the spiral","weakness":"FALTER: leave the cracked blade seal (-28% damage, 4s)","siphon":"NULL: leave the hollow heart seal (lifesteal disabled, 4s)"}[kind])
func step_marks(dt:float)->void:
 for n in range(marks.size()-1,-1,-1):
  var m:Dictionary=marks[n];m.warn-=dt
  if m.warn>0:continue
  var at=Vector2(m.at[0],m.at[1]);var end=Vector2(m.end[0],m.end[1]);var style=str(m.style)
  for id in living():
   var p:Vector2=adventure.points()[id];var d=p-at;var inside=d.length()<=float(m.radius)
   if id in m.hits and style!="suction":continue
   if style in ["beam","dash"]:inside=Geometry2D.get_closest_point_to_segment(p,at,end).distance_to(p)<float(m.radius)+14
   elif style=="cleave":inside=inside and (d.length()<1 or d.normalized().dot((end-at).normalized())>.3)
   elif style=="ring":inside=d.length()>130 and d.length()<230
   if not inside or not adventure.combat.path_clear(at,p):continue
   if id not in m.hits:m.hits.append(id)
   if float(m.damage)>0:adventure.hit_player(id,float(m.damage),"e:"+str(m.uid),preload("res://scripts/defeat_credit.gd").resolve(adventure.game,"e:"+str(m.uid),"Veilbound "+style))
   if style=="suction":
    var pulled=move(p,at-p,minf(125*dt,maxf(0,d.length()-30)))
    if adventure.arcade:adventure.game.positions[id]=pulled
    else:adventure.game.position_in_world=pulled
    adventure.combat.apply_status("p:"+id,"slow",.25,"enemy",.7)
   elif style=="weakness":adventure.combat.apply_status("p:"+id,"veil_weaken",4,"enemy",.28)
   elif style=="siphon":adventure.combat.apply_status("p:"+id,"veil_dry",4,"enemy",1)
  if style=="dash" and m.hits.size()==0:pass
  if style=="dash":
   for e in actors():
    if int(e.uid)==int(m.uid):e.pos=move(e.pos,end-e.pos,minf(700*dt,(end-e.pos).length()))
  m.left-=dt
  if m.left<=0:marks.remove_at(n)
func threat(e:Dictionary)->bool:
 for shot in adventure.combat.projectiles:
  if str(shot.get("owner","enemy"))=="enemy":continue
  var at=Vector2(float(shot.pos[0]),float(shot.pos[1]))
  if at.distance_to(e.pos)<155:return true
 var shots:Array=adventure.game.missiles if adventure.arcade else adventure.game.bullets
 for shot in shots:
  if str(shot.get("owner","solo"))=="enemy":continue
  var at:Vector2=shot.get("pos",Vector2.INF)
  if at.distance_to(e.pos)<135:return true
 return false
func step(dt:float)->void:
 if not active() or not adventure.authoritative():return
 if not adventure.arcade and adventure.game.menu!="":return
 clock+=dt
 for n in range(portals.size()-1,-1,-1):
  portals[n].left-=dt
  if portals[n].left<=0:portals.remove_at(n)
 if clock>=next_visit:start_visit()
 step_marks(dt)
 if not active():return
 for e in actors():
  if bool(e.get("converted",false)):continue
  e.veil_age=float(e.get("veil_age",0))+dt
  if float(e.hp)<=float(e.max_hp)*.5 or float(e.veil_age)>45:
   marks=marks.filter(func(m):return int(m.uid)!=int(e.uid));retreat(e);continue
  var chosen="";var nearest=INF
  for id in living():
   var distance:float=e.pos.distance_to(adventure.points()[id])
   if distance<nearest:chosen=id;nearest=distance
  if chosen.is_empty():continue
  var target:Vector2=adventure.combat.fern.redirect(e,adventure.points()[chosen]);nearest=e.pos.distance_to(target);var kit=kit_for(e)
  e.veil_arrive=maxf(0,float(e.get("veil_arrive",0))-dt)
  if float(e.veil_arrive)>0 or adventure.combat.stunned(adventure.combat.npc_key(e)):continue
  e.veil_blocked=float(e.get("veil_blocked",0))+dt if not adventure.combat.path_clear(e.pos,target) else 0.0
  if nearest>1000 or float(e.veil_blocked)>4:
   var point=place(target,float(e.veil_phase),330)
   if point!=Vector2.INF:gate(e.pos,str(kit.color));e.pos=point;gate(point,str(kit.color));e.veil_arrive=1.4;e.veil_blocked=0
   continue
  e.veil_dodge=float(e.veil_dodge)-dt
  if float(e.veil_dodge)<=0 and (nearest<110 or threat(e)):
   var aim=(target-e.pos).normalized().rotated(PI/2 if sin(float(e.veil_phase))>0 else -PI/2);var point=move(e.pos,aim,120)
   gate(e.pos,str(kit.color));e.pos=point;e.veil_dodge=3.5;e.veil_phase=float(e.veil_phase)+1.0
  var busy=false
  for m in marks:
   if int(m.uid)==int(e.uid) and float(m.warn)>0:busy=true;break
  var heading:Vector2=(target-e.pos).normalized();var melee=str(kit.primary) in ["claw","crescent"]
  if not melee:
   heading=heading.rotated(PI/2)*.8+heading*(1 if nearest>300 else -1 if nearest<200 else 0)
  if not busy:
   var step_size=float(kit.speed)*dt*adventure.combat.speed_factor(adventure.combat.npc_key(e))
   var next=move(e.pos,heading,step_size)
   if next.distance_to(e.pos)<step_size*.4:next=move(e.pos,heading.rotated(.8 if int(e.uid)%2 else -.8),step_size)
   e.pos=next
  for slot in ["primary","secondary","special","control"]:
   var field="veil_"+slot;e[field]=float(e[field])-dt
   if float(e[field])>0 or busy:continue
   if slot=="primary" and melee and nearest>160:continue
   if not adventure.combat.path_clear(e.pos,target):continue
   e[field]={"primary":2.3,"secondary":5.5,"special":11.0,"control":13.0}[slot]
   if slot=="control":
    if kit.elite:control(e,target);busy=true
   else:attack(e,slot,target);busy=true
 schedule_return()
func snapshot()->Dictionary:return {"clock":clock,"next":next_visit if next_visit!=INF else -1,"visits":visits,"serial":serial,"survivors":survivors,"marks":marks,"portals":portals}
func receive(v:Dictionary)->void:
 clock=maxf(0,float(v.get("clock",0)));next_visit=float(v.get("next",180));visits=int(v.get("visits",0));serial=int(v.get("serial",0));survivors=v.get("survivors",[]).duplicate(true);marks=v.get("marks",[]).duplicate(true);portals=v.get("portals",[]).duplicate(true)
 if next_visit<0:next_visit=INF
func body_size(e:Dictionary)->Vector2:return Vector2(96,108) if kit_for(e).get("elite",false) else Vector2(68,82)
func draw_on(c:Node2D,cam:Vector2)->void:
 if not active():return
 var view=Rect2(cam,c.VIEW).grow(100)
 for p in portals:
  var at=Vector2(p.at[0],p.at[1]);var color=Color(p.color)
  if not view.has_point(at):continue
  c.draw_arc(at-cam,35*(.7+float(p.left)*.3),0,TAU,24,color,4,true);c.draw_line(at-cam-Vector2(0,50),at-cam+Vector2(0,50),color,4,true)
 for m in marks:
  var at=Vector2(m.at[0],m.at[1]);var end=Vector2(m.end[0],m.end[1]);var color=Color(m.color);var live=float(m.warn)<=0
  if not view.grow(700).has_point(at):continue
  if m.style in ["beam","dash"]:
   c.draw_line(at-cam,end-cam,Color(color,.16 if not live else .55),float(m.radius)*2,true);c.draw_line(at-cam,end-cam,color,2 if not live else 6,true)
  else:
   c.draw_circle(at-cam,float(m.radius),Color(color,.12 if not live else .3));c.draw_arc(at-cam,float(m.radius),0,TAU,40,color,3,true)
   if m.style=="ring":c.draw_arc(at-cam,130,0,TAU,32,color,2,true)
   if m.style=="suction":
    for n in 4:c.draw_arc(at-cam,40+n*40,clock+n,clock+n+PI,20,color,3,true)
   c.draw_string(ThemeDB.fallback_font,at-cam+Vector2(-55,-12),str(m.style).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,13,color)
 for e in actors():
  if not view.has_point(e.pos):continue
  var kit=kit_for(e);var p:Vector2=e.pos-cam
  c.draw_string(ThemeDB.fallback_font,p+Vector2(-75,-body_size(e).y*.7-20),str(kit.name),HORIZONTAL_ALIGNMENT_LEFT,160,13,Color(kit.color))

func draw_hud(c:Node2D)->void:
 if not active():return
 var label="Hunters: %d • pursuit %d" % [actors().size(),visits] if not actors().is_empty() else "Next pursuit: %ds" % maxi(0,ceili(next_visit-clock))
 var x=c.VIEW.x-185;c.draw_rect(Rect2(x,368,165,30),Color(.04,.07,.12,.94));c.draw_string(ThemeDB.fallback_font,Vector2(x+6,388),label,HORIZONTAL_ALIGNMENT_LEFT,155,12,Color("#d9c7f2"))
 var id=str(c.my_id) if adventure.arcade else "solo";var effects=[]
 if outgoing(id)<1:effects.append("FALTER: damage -28%")
 if leech_blocked(id):effects.append("NULL: lifesteal disabled")
 if not effects.is_empty():c.draw_string(ThemeDB.fallback_font,Vector2(x,419)," • ".join(effects),HORIZONTAL_ALIGNMENT_LEFT,300,13,Color("#ffbfac"))
