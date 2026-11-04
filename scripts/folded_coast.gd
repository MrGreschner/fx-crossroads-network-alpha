extends Node
## Paper islands and paired folds. Host owns enemies, poison and transports.
var combat:Node
var active:=false
var scenery:Node2D
var clock:=0.0
var pending:Array=[]
var terrain=preload("res://scripts/coast_map266.gd").new()
const FLOORS=[Rect2(200,200,1500,2700),Rect2(2250,500,1700,2100),Rect2(4550,200,1250,2700),Rect2(1600,1300,750,400),Rect2(3850,1300,850,400)]
const GATES=[Vector2(1000,900),Vector2(5200,2200),Vector2(1000,2200),Vector2(3100,900)]
func setup(id:String)->void:
 if is_instance_valid(scenery):scenery.queue_free()
 scenery=null;active=id=="folded_coast";clock=0;pending.clear();terrain.setup(self) if active else terrain.reset()
func can_stand(point:Vector2)->bool:return terrain.can_stand(point)
func direction(enemy:Dictionary,target:Vector2,ranged:bool)->Vector2:return terrain.direction(enemy,target,ranged)
func interact(id:String)->bool:
 if not active or not combat.adventure.alive(id):return false
 for n in GATES.size():
  if combat.owner_pos(id).distance_to(GATES[n])<105:
   combat.adventure.teleport(id,GATES[n^1]+Vector2(0,110));return true
 return false
func step(delta:float)->void:
 if not active:return
 clock+=delta
 # Both friendly and hostile shots can pass through a fold, preserving direction.
 var lists:Array=[combat.projectiles,combat.adventure.game.missiles] if combat.adventure.arcade else [combat.projectiles,combat.adventure.game.bullets,combat.adventure.game.enemy_shots]
 for shots in lists:
  for shot in shots:
   shot["fold_lock"]=maxf(0,float(shot.get("fold_lock",0))-delta)
   if float(shot["fold_lock"])>0:continue
   var point:Vector2=combat.vec(shot["pos"]) if shot["pos"] is Array else shot["pos"]
   for n in GATES.size():
    if point.distance_to(GATES[n])<65:
     var destination:Vector2=GATES[n^1]+point-GATES[n]
     shot["pos"]=combat.point_array(destination) if shot["pos"] is Array else destination;shot["fold_lock"]=.5;break
 for i in range(pending.size()-1,-1,-1):
  var warning:Dictionary=pending[i];warning["time"]=float(warning["time"])-delta
  if float(warning["time"])>0:continue
  var source:Dictionary=combat.actor(str(warning["source"]))
  pending.remove_at(i)
  if source.is_empty() or combat.stunned(str(warning["source"])):continue
  if str(warning["kind"])=="ink":
   if combat.pools.size()<24:combat.pools.append({"pos":warning["pos"],"radius":80,"time":4.0})
  else:
   var point:Vector2=combat.vec(warning["pos"]);source["npc"]["pos"]=point
   for n in 10:combat.launch_projectile("enemy",point,Vector2.from_angle(TAU*n/10),{"range":500,"speed":250,"color":"#d6b9ef"},12)
 for foe in combat.adventure.foes().duplicate():
  var kind:=str(foe.get("type",""))
  if kind not in ["inkfin","foldwing","cartographer"] or combat.stunned(combat.npc_key(foe)):continue
  var nearest:=INF;var target:=Vector2.ZERO
  for id in combat.adventure.points():
   if combat.adventure.alive(str(id)) and (foe["pos"] as Vector2).distance_to(combat.owner_pos(str(id)))<nearest:target=combat.owner_pos(str(id));nearest=(foe["pos"] as Vector2).distance_to(target)
  foe["paper_timer"]=float(foe.get("paper_timer",2.0))-delta
  if nearest>650 or float(foe["paper_timer"])>0:continue
  foe["paper_timer"]=3.8 if kind=="cartographer" else 3.2
  var phase:=int(foe.get("paper_phase",0));foe["paper_phase"]=phase+1
  preload("res://scripts/enemy_visual227.gd").mark(combat.adventure,foe,.65)
  if kind=="inkfin" or (kind=="cartographer" and phase%3==0):
   for offset in ([Vector2.ZERO,Vector2(110,0),Vector2(-110,0)] if kind=="cartographer" else [Vector2.ZERO]):
    if pending.size()<16:pending.append({"kind":"ink","pos":combat.point_array(target+offset),"time":1.0,"source":combat.npc_key(foe)})
  elif kind=="cartographer" and phase%3==2:
   var destination:Vector2=fold_destination(foe["pos"],target,phase)
   pending.append({"kind":"fold","pos":combat.point_array(destination),"time":1.2,"source":combat.npc_key(foe)})
  else:
   var aim:Vector2=(target-(foe["pos"] as Vector2)).normalized();var count:=5 if kind=="cartographer" else 3
   for n in count:combat.launch_projectile("enemy",foe["pos"],aim.rotated((n-(count-1)*.5)*.23),{"range":600,"speed":300,"color":"#e9dfc9"},12 if kind=="cartographer" else 9)
func fold_destination(origin:Vector2,target:Vector2,phase:int)->Vector2:
 # Prefer a different landing within pursuit range, so a fold cannot strand the fight.
 var destinations=terrain.landings
 for n in 3:
  var candidate:Vector2=destinations[(int(phase/3)+n)%3]
  if candidate.distance_to(target)<1100 and candidate.distance_to(origin)>160:return candidate
 var nearest:Vector2=destinations[0]
 for candidate in destinations:
  if candidate.distance_to(target)<nearest.distance_to(target):nearest=candidate
 return nearest
func snapshot()->Dictionary:return {"active":active,"clock":clock,"pending":pending}
func receive(data:Dictionary)->void:active=bool(data.get("active",false));clock=float(data.get("clock",0));pending=data.get("pending",[])
func draw_world(canvas:Node2D,camera:Vector2)->void:
 if not combat.adventure.between_guardians():preload("res://scripts/coast_art267.gd").draw_world(self,canvas,camera)
func paint_world(canvas:Node2D,camera:Vector2)->void:draw_world(canvas,camera)
func draw_on(canvas:Node2D,camera:Vector2)->void:
 if not active:return
 if combat.adventure.between_guardians():return
 preload("res://scripts/coast_art267.gd").draw_on(self,canvas,camera)
 for warning in pending:
  var point:Vector2=combat.vec(warning["pos"])-camera
  preload("res://scripts/combat_cues.gd").danger(canvas,point,80,float(warning.time),1.2,Color("#f1a8dd"))
