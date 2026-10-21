extends RefCounted
const ORDERS={"base":"Rally base • new recruits","capital":"Rally capital","center":"Rally center","open":"Open attack","enemy_base":"Attack enemy barracks","enemy_capital":"Attack enemy capital"}
var bg_ref:WeakRef
var bg:RefCounted:
 get:return bg_ref.get_ref() if bg_ref!=null else null
 set(value):bg_ref=weakref(value) if value!=null else null
var recall_ready:Dictionary={}
var healing=0.0
var grid=AStarGrid2D.new()
var routes:Dictionary={}
var obstacles:Dictionary={}
var ui:CanvasLayer
func setup(owner:RefCounted)->void:
 bg=owner;recall_ready.clear();healing=0;routes.clear();obstacles.clear()
 grid.region=Rect2i(0,0,95,62);grid.cell_size=Vector2(72,72);grid.offset=Vector2(36,36);grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grid.update()
 for obstacle in bg.game.field_obstacles:
  var p:Vector2=obstacle.pos;var radius=float(obstacle.get("radius",30))+66
  var cell=Vector2i(p/160)
  if not obstacles.has(cell):obstacles[cell]=[]
  obstacles[cell].append(obstacle)
  for x in range(maxi(0,floori((p.x-radius)/72)),mini(95,ceili((p.x+radius)/72)+1)):
   for y in range(maxi(0,floori((p.y-radius)/72)),mini(62,ceili((p.y+radius)/72)+1)):
    if (Vector2(x,y)*72+Vector2(36,36)).distance_to(p)<radius:grid.set_point_solid(Vector2i(x,y))
 if is_instance_valid(ui):ui.queue_free()
 if DisplayServer.get_name()!="headless":ui=preload("res://scripts/battleground_command_ui.gd").new();bg.game.add_child(ui);ui.setup(bg)
func execute(id:String,key:String)->bool:
 var g:Node=bg.game
 if g.role!="host" or not g.started or g.mode!="battlegrounds" or g.start_countdown>0 or bg.winner>=0 or int(g.health.get(id,0))<=0:return false
 var b:Dictionary=bg.bases.get(bg.owners.get(id,""),{})
 if b.is_empty():return false
 var order=key.trim_prefix("order:")
 if order=="recall":
  if float(b.hp)<=0 or bg.clock<float(recall_ready.get(id,0)) or g.adventure.combat.stunned("p:"+id):return false
  var destination:Vector2=b.pos+Vector2(0,145)
  if not g._clear_path(destination,destination):return false
  recall_ready[id]=bg.clock+120;g.positions[id]=destination
  if g.has_method("network_relocate"):g.network_relocate(id,destination)
  else:g._send_channel(id,{"type":"teleport","point":[destination.x,destination.y]})
  if id==g.my_id:g.local_pos=destination;g.dodge_time=0
  g.charges.erase(id);g.adventure.polish.momentum.erase(id)
  g._emit_effect({"pos":destination,"radius":70.0,"time":.5,"color":"#8bd8d6"});return true
 if order not in ORDERS:return false
 b.order=order
 # Base rally queues fresh reinforcements; other orders immediately direct all owned troops.
 if order!="base":
  for unit in bg.units.values():
   if str(unit.owner)==id:unit.order=order
 return true
func request(key:String)->void:
 if bg.game.role=="host":
  var ok=execute(bg.game.my_id,key);bg.game.status_label.text="Army order accepted." if ok else "Order unavailable. Recall needs a living hero, standing barracks and a ready cooldown."
 elif bg.game.has_method("request_battleground_order"):bg.game.request_battleground_order(key)
func goal(u:Dictionary)->Vector2:
 var order=str(u.get("order","open"));var side=int(u.team);var home:Dictionary=bg.bases.get(bg.owners.get(str(u.owner),""),{})
 if order=="base":return home.pos+Vector2(140 if side==0 else -140,0) if float(home.get("hp",0))>0 else bg.heart_pos(side)
 if order=="capital":return bg.heart_pos(side)+Vector2(0,150)
 if order=="center":return bg.SIZE*.5+Vector2(0,200)
 if order=="enemy_capital":return bg.heart_pos(1-side)
 var opposite=str(1-side)+":"+str(u.lane)
 if bg.bases.has(opposite) and float(bg.bases[opposite].hp)>0:return bg.bases[opposite].pos
 for b in bg.bases.values():
  if int(b.team)!=side and float(b.hp)>0:return b.pos
 return bg.heart_pos(1-side)
func target(u:Dictionary)->String:
 var order=str(u.get("order","open"));var rally=order in ["base","capital","center"]
 var goal_point=goal(u);var result="";var nearest=maxf(380.0,float(bg.REACH[int(u.kind)])+80) if not rally else maxf(280.0,float(bg.REACH[int(u.kind)])+40)
 for id in bg.game.positions:
  if int(bg.game.teams.get(id,-1))==int(u.team) or int(bg.game.health.get(id,0))<=0:continue
  var p:Vector2=bg.game.positions[id];var d:float=u.pos.distance_to(p)
  if rally and p.distance_to(goal_point)>460:continue
  if d<nearest:nearest=d;result="p:"+str(id)
 for summon in bg.game.adventure.combat.v59.target_points():
  var owner=bg.game.adventure.combat.v59.rival_id(str(summon))
  if not bg.game._rival(str(u.owner),owner):continue
  var p:Vector2=bg.game.adventure.combat.v59.target_position(str(summon));var d:float=u.pos.distance_to(p)
  if rally and p.distance_to(goal_point)>460:continue
  if d<nearest:nearest=d;result="p:"+str(summon)
 for key in bg.nearby_units(u.pos,nearest):
  if not bg.units.has(key):continue
  var other:Dictionary=bg.units[key];var d:float=u.pos.distance_to(other.pos)
  if int(other.team)==int(u.team) or rally and (other.pos as Vector2).distance_to(goal_point)>460:continue
  if d<nearest:nearest=d;result=str(key)
 if not result.is_empty() or rally:return result
 if order=="enemy_capital":return "bgheart:"+str(1-int(u.team))
 # A distant hero should not pull an entire army away from its strategic destination.
 var best="";var distance=INF
 for key in bg.bases:
  var b:Dictionary=bg.bases[key]
  if int(b.team)!=int(u.team) and float(b.hp)>0 and goal_point.distance_to(b.pos)<distance:distance=goal_point.distance_to(b.pos);best="bgbase:"+str(key)
 return best if not best.is_empty() else "bgheart:"+str(1-int(u.team))
func clear_cell(p:Vector2)->Vector2i:
 var cell=Vector2i(floori(p.x/72),floori(p.y/72)).clamp(Vector2i.ZERO,Vector2i(94,61))
 if not grid.is_point_solid(cell):return cell
 for ring in range(1,7):
  for x in range(maxi(0,cell.x-ring),mini(94,cell.x+ring)+1):
   for y in range(maxi(0,cell.y-ring),mini(61,cell.y+ring)+1):
    if not grid.is_point_solid(Vector2i(x,y)):return Vector2i(x,y)
 return cell
func direction(id:String,origin:Vector2,destination:Vector2)->Vector2:
 var delta:Vector2=destination-origin
 if delta.length()<10:return Vector2.ZERO
 if clear_path(origin,origin+delta.limit_length(150)):return delta.normalized()
 var goal_cell=clear_cell(destination);var route:Dictionary=routes.get(id,{})
 if route.is_empty() or route.goal!=goal_cell or bg.clock>float(route.until):
  var path=grid.get_point_path(clear_cell(origin),goal_cell)
  route={"goal":goal_cell,"path":path,"index":0,"until":bg.clock+3.0};routes[id]=route
 var path:PackedVector2Array=route.path
 while int(route.index)<path.size() and origin.distance_to(path[int(route.index)])<48:route.index+=1
 if int(route.index)<path.size():return (path[int(route.index)]-origin).normalized()
 return delta.normalized()
# Analytic segment/circle collision avoids dozens of nine-pixel samples per soldier.
# Both Battlegrounds maps use these static islands; temporary ice walls stay dynamic.
func clear_path(start:Vector2,finish:Vector2)->bool:
 if not Rect2(Vector2(30,30),bg.SIZE-Vector2(60,60)).has_point(finish):return false
 var delta=finish-start;var length_squared=delta.length_squared()
 var low=start.min(finish)-Vector2(100,100);var high=start.max(finish)+Vector2(100,100)
 for x in range(floori(low.x/160),floori(high.x/160)+1):
  for y in range(floori(low.y/160),floori(high.y/160)+1):
   for obstacle in obstacles.get(Vector2i(x,y),[]):
    var p:Vector2=obstacle.pos;var t=clampf((p-start).dot(delta)/length_squared,0,1) if length_squared>0 else 0.0
    if p.distance_squared_to(start+delta*t)<pow(float(obstacle.get("radius",30))+18,2):return false
 for wall in bg.game.ice_walls:
  var p:Vector2=wall.pos;var t=clampf((p-start).dot(delta)/length_squared,0,1) if length_squared>0 else 0.0
  if p.distance_squared_to(start+delta*t)<2304:return false
 return true
func move_unit(origin:Vector2,displacement:Vector2)->Vector2:
 var steps=maxi(1,ceili(displacement.length()/10));var part=displacement/steps;var point=origin
 for n in steps:
  var horizontal=(point+Vector2(part.x,0)).clamp(Vector2(30,30),bg.SIZE-Vector2(30.01,30.01))
  if clear_path(point,horizontal):point=horizontal
  var vertical=(point+Vector2(0,part.y)).clamp(Vector2(30,30),bg.SIZE-Vector2(30.01,30.01))
  if clear_path(point,vertical):point=vertical
 return point
func banner_bonus(u:Dictionary)->float:
 if bg.unit_grid_dirty:bg.rebuild_unit_grid()
 for key in bg.nearby_units(u.pos,180):
  if bg.units.has(key) and int(bg.units[key].kind)==9 and int(bg.units[key].team)==int(u.team) and float(bg.units[key].hp)>0:return 1.1
 return 1.0
func step(dt:float)->void:
 if bg.game.role!="host" or not bg.game.started or bg.game.start_countdown>0:return
 healing+=dt
 if healing<1:return
 var ticks=floori(healing);healing-=ticks
 for id in bg.game.positions:
  if int(bg.game.health.get(id,0))<=0:continue
  var b:Dictionary=bg.bases.get(bg.owners.get(id,""),{});var p:Vector2=bg.game.positions[id]
  if p.distance_to(bg.heart_pos(bg.side_of(id)))<=230 or (not b.is_empty() and float(b.hp)>0 and p.distance_to(b.pos)<=190):bg.game._heal(str(id),str(id),4*ticks)
 for key in routes.keys():
  if key.begins_with("bgunit:") and not bg.units.has(key):routes.erase(key)
func hero_bounty(victim:String,source:String)->void:
 var owner=str(bg.units.get(source,{}).get("owner",source)).trim_prefix("bgarmy:")
 if bg.game.positions.has(owner) and owner!=victim and bg.side_of(owner)!=bg.side_of(victim):bg.reward(owner,350,30)
func ui_step()->void:pass
