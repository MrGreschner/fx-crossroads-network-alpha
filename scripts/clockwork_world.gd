extends Node
## Shared timed machinery. One aperture opens at a time; occupied gates wait.
var adventure:Node
var active=false
var clock=0.0
var phase=0
var held:Array=[]
var blasts:Array=[]
var hit_at:Dictionary={}
const TYPES=["ratchet_keeper","spark_scarab"]
const WALL_X=[1450.0,2850.0]
const GAP_Y=[420.0,1260.0,2100.0]
const PERIOD=4.8
func setup(id:String)->void:
 active=id=="clockwork_orchard";clock=0;phase=0;held=[];blasts=[];hit_at.clear()
func gate(index:int,gap:int)->Rect2:return Rect2(WALL_X[index]-35,GAP_Y[gap]-150,70,300)
func gate_open(index:int,gap:int)->bool:return gap==posmod(phase+index,3) or [index,gap] in held
func can_stand(p:Vector2)->bool:
 for index in 2:
  if absf(p.x-WALL_X[index])>53:continue
  for gap in 3:
   if absf(p.y-GAP_Y[gap])<130 and gate_open(index,gap):return true
  return false
 return true
func update_gates()->void:
 var next=floori(clock/PERIOD)%3
 if next!=phase:
  for index in 2:
   var old=posmod(phase+index,3)
   if occupied(gate(index,old).grow(30)):held.append([index,old])
  phase=next
 for n in range(held.size()-1,-1,-1):
  if not occupied(gate(int(held[n][0]),int(held[n][1])).grow(30)):held.remove_at(n)
func occupied(rect:Rect2)->bool:
 for p in adventure.points().values():
  if rect.has_point(p):return true
 for foe in adventure.foes():
  if float(foe.hp)>0 and rect.has_point(foe.pos):return true
 return false
func summon(origin:Vector2)->void:
 if not active or not adventure.authoritative():return
 var count=0
 for foe in adventure.foes():
  if foe.type=="spark_scarab":count+=1
 for n in maxi(0,3-count):
  for attempt in 16:
   var p=origin+Vector2.from_angle(n*TAU/3+attempt*.37)*(90+attempt*10)
   if adventure.can_stand(p) and adventure.combat.path_clear(origin,p):
    adventure.spawn("spark_scarab",p,32,false);adventure.foes()[-1].summoned=true;break
func on_defeat(enemy:Dictionary)->bool:
 if not active or str(enemy.type)!="spark_scarab":return false
 if blasts.size()<12:blasts.append({"pos":[enemy.pos.x,enemy.pos.y],"time":.65,"hit":false})
 return false # Preserve ordinary XP/kill handling.
func step(dt:float)->void:
 if not active:return
 if not adventure.authoritative():return
 clock+=dt;update_gates()
 var combat=adventure.combat
 for foe in adventure.foes().duplicate():
  if str(foe.type) not in TYPES or float(foe.hp)<=0 or combat.stunned(combat.npc_key(foe)):continue
  var nearest=INF;var target=""
  for id in adventure.points():
   if adventure.alive(str(id)) and foe.pos.distance_to(adventure.points()[id])<nearest:nearest=foe.pos.distance_to(adventure.points()[id]);target=str(id)
  if target.is_empty() or nearest>760:continue
  var goal:Vector2=combat.fern.redirect(foe,adventure.points()[target]);nearest=foe.pos.distance_to(goal)
  var aim:Vector2=(goal-foe.pos).normalized();var melee=str(foe.type)=="spark_scarab"
  var direction=aim if melee else aim if nearest>340 else -aim if nearest<190 else Vector2.ZERO
  var move:Vector2=direction*(185 if melee else 85)*dt*combat.speed_factor(combat.npc_key(foe))
  if combat.path_clear(foe.pos,foe.pos+move):foe.pos+=move
  foe.skill_timer=float(foe.get("skill_timer",1))-dt
  if float(foe.skill_timer)>0:continue
  if melee:
   if nearest<64:
    foe.skill_timer=1.3;adventure.warn(foe.pos+aim*25,45,7,.35)
    preload("res://scripts/enemy_visual227.gd").mark(adventure,foe,.35)
  elif combat.path_clear(foe.pos,goal):
   foe.skill_timer=2.6
   preload("res://scripts/enemy_visual227.gd").mark(adventure,foe,.65)
   for angle in [-.24,0,.24]:combat.launch_projectile("enemy",foe.pos,aim.rotated(angle),{"range":590,"speed":225,"color":"#ead397"},9,"plain")
 for n in range(blasts.size()-1,-1,-1):
  var blast=blasts[n];blast.time=float(blast.time)-dt
  if float(blast.time)<=0 and not bool(blast.hit):
   blast.hit=true;var p=Vector2(blast.pos[0],blast.pos[1])
   for id in adventure.points():
    if adventure.alive(str(id)) and p.distance_to(adventure.points()[id])<92 and combat.path_clear(p,adventure.points()[id]):adventure.hit_player(str(id),12)
  if float(blast.time)<-.25:blasts.remove_at(n)
func snapshot()->Dictionary:return {"clock":clock,"phase":phase,"held":held,"blasts":blasts}
func receive(data:Dictionary)->void:
 clock=float(data.get("clock",clock));phase=int(data.get("phase",phase));held=[];blasts=data.get("blasts",[])
 for pair in data.get("held",[]).slice(0,6):
  if pair is Array and pair.size()==2:held.append([int(pair[0]),int(pair[1])])
func draw_world(c:Node2D,camera:Vector2)->void:
 if not active:return
 var view=Rect2(camera-Vector2(80,80),c.get_viewport_rect().size+Vector2(160,160))
 for index in 2:
  var x=float(WALL_X[index]);var top=0.0
  for gap in 3:
   var rect=gate(index,gap)
   draw_wall(c,Rect2(x-35,top,70,rect.position.y-top),camera,view);top=rect.end.y
   if not view.intersects(rect.grow(70)):continue
   var p=rect.get_center()-camera;var open=gate_open(index,gap);var remaining=PERIOD-fmod(clock,PERIOD);var warn=open and remaining<1.2
   c.draw_rect(Rect2(rect.position-camera,rect.size),Color("#4c7868") if open else Color("#454e4b"))
   if not open:
    for line in 6:c.draw_line(p+Vector2(-30,-135+line*52),p+Vector2(30,-115+line*52),Color("#bca676"),8,true)
   for side in [-1,1]:
    var at=p+Vector2(0,side*162);c.draw_circle(at,33,Color("#354248"));c.draw_arc(at,27,0,TAU,20,Color("#d8af67"),7,true)
    for n in 8:
     var a=Vector2.from_angle(n*TAU/8+clock*(1 if index==0 else -1));c.draw_line(at+a*24,at+a*36,Color("#d8af67"),7,true)
   c.draw_string(ThemeDB.fallback_font,p+Vector2(-100,-22),"CLEAR GATE" if warn else "OPEN" if open else "WAIT",HORIZONTAL_ALIGNMENT_CENTER,200,15,Color("#ffce75") if warn else Color("#ceead6") if open else Color("#b6b3a4"))
   c.draw_string(ThemeDB.fallback_font,p+Vector2(-100,4),"%.1fs" % remaining,HORIZONTAL_ALIGNMENT_CENTER,200,14,Color("#f0db9e"))
  draw_wall(c,Rect2(x-35,top,70,2520-top),camera,view)
func draw_wall(c:Node2D,rect:Rect2,camera:Vector2,view:Rect2)->void:
 if not view.intersects(rect):return
 c.draw_rect(Rect2(rect.position-camera,rect.size),Color("#364b4c"));c.draw_rect(Rect2(rect.position-camera,rect.size),Color("#c29f68"),false,4)
func draw_on(c:Node2D,camera:Vector2)->void:
 if not active:return
 for b in blasts:
  var p=Vector2(b.pos[0],b.pos[1])-camera;var hit=bool(b.hit)
  if not hit:
   var shell:Texture2D=adventure.game.art.get("spark_scarab_idle")
   if shell!=null:c.draw_texture_rect(shell,Rect2(p-Vector2(25,28),Vector2(50,50)),false,Color("#edb681"))
  else:
   var progress=clampf(-float(b.time)/.25,0,1)
   for n in 8:
    var direction=Vector2.from_angle(n*TAU/8);c.draw_line(p+direction*(20+progress*20),p+direction*(45+progress*45),Color(1,.72,.34,1-progress),4,true)
  c.draw_circle(p,92,Color(1,.58,.25,.32 if hit else .12));c.draw_arc(p,92,0,TAU,28,Color("#ffc46e"),3,true)
 if not blasts.is_empty():c.draw_string(ThemeDB.fallback_font,Vector2(30,145),"VOLATILE SCARABS • MOVE CLEAR OF THEIR FALLEN SHELLS",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#f9d191"))
