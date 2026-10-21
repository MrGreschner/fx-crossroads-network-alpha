extends RefCounted
## Server-owned objectives share the established Arena transport and combat.
const TILE=64
const GRID=Vector2i(40,30)
const SIZE=Vector2(2560,1920)
const LIMIT=300.0
const PALETTE=["#6cbdf2","#f28b87","#b9a2f2","#f2cf70","#78d6ae","#eea2cf","#83d7e1","#c0d76b"]
var world_ref:WeakRef
var world:RefCounted:
 get:return world_ref.get_ref() if world_ref!=null else null
 set(value):world_ref=weakref(value) if value!=null else null
var keys:Array=[]
var owner_group:Dictionary={}
var scores:Dictionary={}
var cells=PackedInt32Array()
var available=0
var revision=0
var last_received=-1
var encoded:Array=[]
var encoded_revision=-1
var meshes:Dictionary={}
var dirty:Dictionary={}
var previous:Dictionary={}
var credit:Dictionary={}
var painted:Dictionary={}
var held:Dictionary={}
var passes:Dictionary={}
var burdens:Dictionary={}
var beacons:Array=[]
var crown:Dictionary={}
var elapsed=0.0
var paint_clock=0.0
var turn=0
var throw_button:Button
func active()->bool:return world!=null and world.game.mode=="arena" and world.map_id in ["colour_clash","crown_chase"]
func setup(w:RefCounted)->void:
 world=w;keys.clear();owner_group.clear();scores.clear();cells.clear();available=0;revision=0;last_received=-1;encoded.clear();encoded_revision=-1;meshes.clear();dirty.clear();previous.clear();credit.clear();painted.clear();held.clear();passes.clear();burdens.clear();beacons.clear();elapsed=0;paint_clock=0;turn=0;crown.clear()
 if not active():return
 var g=world.game;g.FIELD=Rect2(Vector2.ZERO,SIZE);g.field_obstacles.clear();g.world_buildings.clear();g.world_patches.clear();g.world_decorations.clear();g.world_fountains.clear();g.world_spawns.clear();g.world_terrain="clock_floor" if world.map_id=="colour_clash" else "storm_floor";g.art[g.world_terrain]=load("res://assets/"+g.world_terrain+".png")
 for p in [Vector2(560,450),Vector2(2000,450),Vector2(560,1470),Vector2(2000,1470),Vector2(1050,650),Vector2(1510,650),Vector2(1050,1270),Vector2(1510,1270)]:g.field_obstacles.append({"pos":p,"radius":48.0,"kind":"rock"})
 for member in g.fighters():
  var id=str(member.id);var key="team:"+str(g.teams.get(id,0)) if g.pvp_rule=="teams" else id
  owner_group[id]=key;painted[id]=0;held[id]=0.0;passes[id]=0
  if key not in keys:keys.append(key);scores[key]=0.0
 if world.map_id=="colour_clash":
  cells.resize(GRID.x*GRID.y);cells.fill(0)
  for y in GRID.y:
   for x in GRID.x:
    var p=Vector2(x*TILE+32,y*TILE+32);var blocked=false
    for obstacle in g.field_obstacles:
     if p.distance_to(obstacle.pos)<float(obstacle.radius)+22:blocked=true;break
    if blocked:cells[y*GRID.x+x]=-1
    else:available+=1
  for p in [Vector2(820,960),Vector2(1740,960)]:beacons.append({"pos":[p.x,p.y],"owner":"","candidate":"","progress":0.0,"pulse":0.0,"contested":false})
  for y in ceili(float(GRID.y)/8):
   for x in ceili(float(GRID.x)/8):dirty[Vector2i(x,y)]=true
 else:
  crown={"holder":"","pos":[1280,960],"direction":[1,0],"flight":0.0,"ground_since":0.0,"blocked_id":"","blocked_until":0.0,"pickup_ready":0.0,"last_group":"","last_thrower":"","flight_age":0.0}
  if DisplayServer.get_name()!="headless" and not is_instance_valid(throw_button):
   var layer=CanvasLayer.new();layer.layer=32;g.add_child(layer);throw_button=preload("res://scripts/arena_throw_button.gd").new();throw_button.game=g;layer.add_child(throw_button);throw_button.text="E • THROW CROWN";throw_button.add_theme_font_size_override("font_size",14)
   for state in ["normal","hover","pressed","focus","disabled"]:throw_button.add_theme_stylebox_override(state,preload("res://scripts/studio_ui.gd").box("#24404a","#d7bd77",7,7))
   throw_button.pressed.connect(request_throw)
func group(id:String)->String:return str(owner_group.get(id,""))
func colour(key:String)->Color:
 if key.begins_with("team:"):return Color(PALETTE[clampi(int(key.trim_prefix("team:")),0,1)])
 return Color(PALETTE[maxi(0,keys.find(key))%8])
func label(key:String)->String:
 if key.begins_with("team:"):return "Blue team" if key=="team:0" else "Red team"
 for member in world.game.roster:
  if str(member.id)==key:return str(member.name)
 return "Player "+str(maxi(1,keys.find(key)+1))
func value(key:String)->float:return float(scores.get(key,0))*100/maxi(1,available) if world.map_id=="colour_clash" else float(scores.get(key,0))
func score_label(id:String)->String:return ("%.1f%%" if world.map_id=="colour_clash" else "%.1fs") % value(group(id))
func winner_keys()->Array:
 var best=-1.0;var result=[]
 for key in keys:
  var score=float(scores.get(key,0))
  if score>best+.0001:best=score;result=[key]
  elif absf(score-best)<=.0001:result.append(key)
 return result
func outcome(id:String)->String:
 var winners=winner_keys()
 if group(id) not in winners:return "loss"
 return "win" if winners.size()==1 else "draw"
func finish()->void:
 if not active() or not world.game.started:return
 var winners=winner_keys();var reason="Draw" if winners.size()!=1 else label(str(winners[0]))+" wins"
 var amount=value(str(winners[0])) if not winners.is_empty() else 0.0
 world.game.end_match(str(world.MAPS[world.map_id])+" • "+reason+" • "+(("%.1f%% floor" if world.map_id=="colour_clash" else "%.1fs carrying") % amount))
func set_cell(index:int,key:String,credit_id:String="")->bool:
 if index<0 or index>=cells.size() or cells[index]<0 or key not in keys:return false
 var code=keys.find(key)+1;var old=int(cells[index])
 if old==code:return false
 if old>0 and old<=keys.size():scores[keys[old-1]]=maxf(0,float(scores.get(keys[old-1],0))-1)
 cells[index]=code;scores[key]=float(scores.get(key,0))+1;revision+=1;dirty[Vector2i((index%GRID.x)/8,(index/GRID.x)/8)]=true
 if painted.has(credit_id):painted[credit_id]=int(painted[credit_id])+1
 return true
func disc(center:Vector2,radius:float,key:String,only:String="",credit_id:String="")->void:
 var from=Vector2i((center-Vector2.ONE*radius)/TILE).clamp(Vector2i.ZERO,GRID-Vector2i.ONE);var to=Vector2i((center+Vector2.ONE*radius)/TILE).clamp(Vector2i.ZERO,GRID-Vector2i.ONE)
 for y in range(from.y,to.y+1):
  for x in range(from.x,to.x+1):
   var index=y*GRID.x+x;var p=Vector2(x*TILE+32,y*TILE+32)
   if p.distance_squared_to(center)>radius*radius:continue
   if not only.is_empty() and (cells[index]<=0 or keys[cells[index]-1]!=only):continue
   set_cell(index,key,credit_id)
func paint(id:String,dt:float)->void:
 var g=world.game;var p:Vector2=g.positions[id];var key=group(id)
 if key.is_empty():return
 credit[id]=minf(2.0,float(credit.get(id,0))+dt*8.0)
 if not previous.has(id):previous[id]=p;set_cell(clampi(int(p.y/TILE),0,GRID.y-1)*GRID.x+clampi(int(p.x/TILE),0,GRID.x-1),key,id);return
 var start:Vector2=previous[id];previous[id]=p
 if start.distance_to(p)<1:return
 # A teleport or fast jump claims the landing footprint, never the skipped path.
 if start.distance_to(p)>70:start=p
 var speed=maxf(130,float(g.characters.get(str(g.hero_ids.get(id,"ram")),{}).get("speed",230))*g.legacy.speed_factor(id));var radius=clampf(18000.0/speed,38,112)
 var low=start.min(p)-Vector2.ONE*radius;var high=start.max(p)+Vector2.ONE*radius;var delta=p-start;var length_squared=delta.length_squared();var candidates=[]
 for y in range(maxi(0,floori(low.y/TILE)),mini(GRID.y,ceili(high.y/TILE))):
  for x in range(maxi(0,floori(low.x/TILE)),mini(GRID.x,ceili(high.x/TILE))):
   var index=y*GRID.x+x;var q=Vector2(x*TILE+32,y*TILE+32);var t=clampf((q-start).dot(delta)/length_squared,0,1) if length_squared>0 else 0.0
   if q.distance_squared_to(start+delta*t)<=radius*radius and cells[index]>=0 and cells[index]!=keys.find(key)+1:candidates.append({"index":index,"distance":q.distance_squared_to(p)})
 candidates.sort_custom(func(a,b):return a.distance<b.distance)
 for item in candidates:
  if float(credit[id])<1:break
  if set_cell(int(item.index),key,id):credit[id]=float(credit[id])-1
func step_beacons(dt:float)->void:
 var g=world.game
 for beacon in beacons:
  var present=[];var center=world.point(beacon.pos)
  for id in g.positions:
   var key=group(str(id))
   if int(g.health.get(id,0))>0 and not key.is_empty() and (g.positions[id] as Vector2).distance_to(center)<110 and key not in present:present.append(key)
  beacon.contested=present.size()>1
  if present.size()==1:
   if str(beacon.candidate)!=str(present[0]):beacon.candidate=present[0];beacon.progress=0.0
   if str(beacon.owner)!=str(present[0]):
    beacon.progress=float(beacon.progress)+dt
    if float(beacon.progress)>=3:beacon.owner=present[0];beacon.progress=0.0;beacon.pulse=0.0
  elif present.is_empty():beacon.candidate="";beacon.progress=0.0
  if not str(beacon.owner).is_empty() and not beacon.contested:
   beacon.pulse=float(beacon.pulse)-dt
   if float(beacon.pulse)<=0:beacon.pulse=4.0;disc(center,105,str(beacon.owner))
func carrier_factor(id:String)->float:
 if not active() or world.map_id!="crown_chase" or str(crown.get("holder",""))!=id:return 1.0
 return 1.0-minf(.4,float(burdens.get(id,0))*.4/45.0)
func carrier_at(p:Vector2)->float:
 var id=str(crown.get("holder",""))
 return carrier_factor(id) if not id.is_empty() and world.game.positions.has(id) and (world.game.positions[id] as Vector2).distance_squared_to(p)<1 else 1.0
func drop(id:String)->void:
 if str(crown.get("holder",""))!=id:return
 var p:Vector2=world.game.positions.get(id,world.game.FIELD.size*.5);crown.holder="";crown.pos=[p.x,p.y];crown.flight=0.0;crown.ground_since=elapsed;crown.blocked_id=id;crown.blocked_until=elapsed+1.3;crown.pickup_ready=elapsed+.15
func elimination(victim:String,source:String)->void:
 if not active() or world.game.role!="host":return
 previous.erase(victim);credit.erase(victim)
 if world.map_id=="crown_chase":drop(victim);return
 if world.game.positions.has(source) and not group(source).is_empty() and group(source)!=group(victim):disc(world.game.positions[victim],140,group(source),group(victim),source)
func throw_crown(id:String,direction:Vector2)->bool:
 if not active() or world.map_id!="crown_chase" or world.game.role!="host" or not world.game.started or world.game.start_countdown>0 or str(crown.get("holder",""))!=id or int(world.game.health.get(id,0))<=0 or elapsed<float(crown.pickup_ready) or not direction.is_finite() or direction.length_squared()<.01 or world.game.adventure.combat.stunned("p:"+id):return false
 var p:Vector2=world.game.positions[id];crown.holder="";crown.pos=[p.x,p.y];crown.direction=[direction.normalized().x,direction.normalized().y];crown.flight=.58;crown.flight_age=0.0;crown.ground_since=elapsed;crown.blocked_id=id;crown.blocked_until=elapsed+1.3;crown.pickup_ready=elapsed+.12;crown.last_thrower=id;passes[id]=int(passes.get(id,0))+1;return true
func request_throw()->void:
 if not active():return
 var g=world.game
 var direction:Vector2=g.mobile.aim if g.mobile.enabled else (g.media_mouse_world()-g.local_pos).normalized()
 if direction.length_squared()<.01:direction=g.last_aim
 if g.role=="host":throw_crown(g.my_id,direction)
 else:g._send_channel(g.host_id,{"type":"crown_throw","angle":direction.angle()})
func step_crown(dt:float)->void:
 var g=world.game;var holder=str(crown.holder)
 if not holder.is_empty():
  if not g.positions.has(holder) or int(g.health.get(holder,0))<=0:drop(holder);return
  var p:Vector2=g.positions[holder];crown.pos=[p.x,p.y];burdens[holder]=float(burdens.get(holder,0))+dt
  if Time.get_ticks_msec()>=int(g.invincible_until.get(holder,0)):
   scores[group(holder)]=float(scores.get(group(holder),0))+dt;held[holder]=float(held.get(holder,0))+dt
  return
 var point=world.point(crown.pos)
 if float(crown.flight)>0:
  var next=point+world.point(crown.direction)*520*minf(dt,float(crown.flight));crown.flight=maxf(0,float(crown.flight)-dt);crown.flight_age=float(crown.flight_age)+dt
  if g.FIELD.grow(-40).has_point(next) and g._clear_path(point,next):point=next;crown.pos=[point.x,point.y]
  else:crown.flight=0.0
 if elapsed>=float(crown.pickup_ready):
  var candidate="";var nearest=43.0
  for id in g.positions:
   if int(g.health.get(id,0))<=0 or group(str(id)).is_empty() or Time.get_ticks_msec()<int(g.invincible_until.get(id,0)) or str(id)==str(crown.blocked_id) and elapsed<float(crown.blocked_until):continue
   var d:float=point.distance_to(g.positions[id])
   if d<nearest and g._clear_path(point,g.positions[id]):candidate=str(id);nearest=d
  if not candidate.is_empty():
   if str(crown.last_group)!=group(candidate):burdens.clear()
   crown.holder=candidate;crown.last_group=group(candidate);crown.flight=0.0;crown.pickup_ready=elapsed+.65;return
 if elapsed-float(crown.ground_since)>12 or not g.FIELD.grow(-40).has_point(point) or not g._clear_path(point,point):crown.pos=[1280,960];crown.flight=0.0;crown.ground_since=elapsed;crown.blocked_id=""
func step(dt:float)->void:
 if not active() or world.game.role!="host" or not world.game.started or world.game.start_countdown>0:return
 dt=minf(dt,LIMIT-elapsed)
 if dt<=0:finish();return
 elapsed+=dt
 if world.map_id=="colour_clash":
  paint_clock+=dt
  if paint_clock>=.1:
   var ids=world.game.positions.keys();var step_dt=paint_clock;paint_clock=0;turn+=1
   for offset in ids.size():
    var id=str(ids[(offset+turn)%ids.size()])
    if int(world.game.health.get(id,0))>0:paint(id,step_dt)
    else:previous.erase(id);credit.erase(id)
   step_beacons(step_dt)
 else:step_crown(dt)
 if elapsed>=LIMIT:finish()
func runs()->Array:
 if encoded_revision==revision:return encoded
 encoded=[];var start=0
 while start<cells.size():
  var end=start+1
  while end<cells.size() and cells[end]==cells[start]:end+=1
  encoded.append([start,end-start,int(cells[start])]);start=end
 encoded_revision=revision;return encoded
func snapshot()->Dictionary:
 return {"elapsed":elapsed,"keys":keys,"owner_group":owner_group,"scores":scores,"available":available,"revision":revision,"paint":runs() if world.map_id=="colour_clash" else [],"beacons":beacons,"crown":crown,"burdens":burdens,"painted":painted,"held":held,"passes":passes}
func receive(data:Dictionary)->void:
 if not active():return
 elapsed=float(data.get("elapsed",elapsed));keys=data.get("keys",keys);owner_group=data.get("owner_group",owner_group);scores=data.get("scores",scores);available=int(data.get("available",available));beacons=data.get("beacons",beacons);crown=data.get("crown",crown);burdens=data.get("burdens",burdens);painted=data.get("painted",painted);held=data.get("held",held);passes=data.get("passes",passes)
 var incoming=int(data.get("revision",-1))
 if world.map_id=="colour_clash" and incoming!=last_received:
  var next=PackedInt32Array();next.resize(GRID.x*GRID.y);next.fill(0)
  for run in data.get("paint",[]):
   for n in range(maxi(0,int(run[0])),mini(next.size(),int(run[0])+int(run[1]))):next[n]=int(run[2])
  for n in next.size():
   if cells.size()!=next.size() or cells[n]!=next[n]:dirty[Vector2i((n%GRID.x)/8,(n/GRID.x)/8)]=true
  cells=next;last_received=incoming;revision=incoming
func header()->String:return str(world.MAPS[world.map_id])+" • "+world.game.pvp_rule.to_upper()+" • "+score_label(world.game.my_id)+" • %d:%02d left" % [int(maxf(0,LIMIT-elapsed))/60,int(maxf(0,LIMIT-elapsed))%60]
func bot_goal(id:String,p:Vector2,target:Vector2,state:Dictionary)->Vector2:
 if not active():return target
 var g=world.game
 if world.map_id=="colour_clash":
  if elapsed<float(state.get("objective_until",0)) and state.has("objective_goal"):return state.objective_goal
  var best=p;var weight=INF;var key=group(id);var offset=absi(hash(id))%cells.size()
  for n in 90:
   var index=(offset+n*37+int(elapsed)*17)%cells.size()
   if cells[index]<0 or cells[index]==keys.find(key)+1:continue
   var q=Vector2(index%GRID.x*TILE+32,index/GRID.x*TILE+32);var d=p.distance_to(q)
   if d<weight:weight=d;best=q
  for beacon in beacons:
   var q=world.point(beacon.pos);var d=p.distance_to(q)*.55
   if str(beacon.owner)!=key and d<weight:weight=d;best=q
  state.objective_until=elapsed+1.0;state.objective_goal=best;return best
 var holder=str(crown.get("holder",""));var point=world.point(crown.get("pos",[1280,960]))
 if holder==id:
  if float(burdens.get(id,0))>18 and g.pvp_rule=="teams" and elapsed>=float(crown.pickup_ready):
   for other in g.positions:
    if str(other)!=id and group(str(other))==group(id) and int(g.health.get(other,0))>0 and float(burdens.get(other,0))<float(burdens.get(id,0))-8 and p.distance_to(g.positions[other])<280 and g._clear_path(p,g.positions[other]):throw_crown(id,(g.positions[other]-p).normalized());break
  var enemy=Vector2.INF;var distance=INF
  for other in g.positions:
   if g._rival(id,str(other)) and p.distance_to(g.positions[other])<distance:distance=p.distance_to(g.positions[other]);enemy=g.positions[other]
  return (p+(p-enemy).normalized()*240).clamp(Vector2(120,120),SIZE-Vector2(120,120)) if enemy.is_finite() else SIZE*.5+Vector2.from_angle(elapsed*.25+hash(id)%6)*650
 if not holder.is_empty() and group(holder)==group(id):return point+(p-point).normalized()*140
 return point
func paint_mesh(chunk:Vector2i)->ArrayMesh:
 var vertices=PackedVector3Array();var colors=PackedColorArray();var indices=PackedInt32Array()
 for y in range(chunk.y*8,mini(GRID.y,(chunk.y+1)*8)):
  for x in range(chunk.x*8,mini(GRID.x,(chunk.x+1)*8)):
   var code=int(cells[y*GRID.x+x])
   if code<=0 or code>keys.size():continue
   var tint=colour(str(keys[code-1]));tint.a=.6;var r=Rect2(x*TILE+2,y*TILE+2,TILE-4,TILE-4);var n=vertices.size()
   vertices.append_array(PackedVector3Array([Vector3(r.position.x,r.position.y,0),Vector3(r.end.x,r.position.y,0),Vector3(r.end.x,r.end.y,0),Vector3(r.position.x,r.end.y,0)]));colors.append_array(PackedColorArray([tint,tint,tint,tint]));indices.append_array(PackedInt32Array([n,n+1,n+2,n,n+2,n+3]))
 if vertices.is_empty():return null
 var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_COLOR]=colors;arrays[Mesh.ARRAY_INDEX]=indices;var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);return mesh
func draw_ground()->void:
 if not active():return
 var g=world.game
 if world.map_id=="colour_clash":
  for chunk in dirty:meshes[chunk]=paint_mesh(chunk)
  dirty.clear();var bounds=Rect2(g.camera,g.VIEW).grow(64)
  for chunk in meshes:
   if meshes[chunk]!=null and bounds.intersects(Rect2(Vector2(chunk)*512,Vector2(512,512))):g.draw_mesh(meshes[chunk],null,Transform2D(0.0,-g.camera))
  for beacon in beacons:
   var p=world.point(beacon.pos)-g.camera;var tint=colour(str(beacon.owner)) if not str(beacon.owner).is_empty() else Color("#b9c4ca")
   g.draw_circle(p,110,Color(tint,.08));g.draw_arc(p,110,0,TAU,48,Color(tint,.45),2);g.draw_circle(p,35,Color("#183342"));g.draw_arc(p,35,0,TAU,32,tint,4)
   if float(beacon.progress)>0:g.draw_arc(p,43,-PI/2,-PI/2+TAU*clampf(float(beacon.progress)/3,0,1),32,Color("#fff1ad"),5)
   for n in 4:g.draw_line(p+Vector2.from_angle(n*PI/2)*12,p+Vector2.from_angle(n*PI/2)*26,tint,4)
   g.draw_string(ThemeDB.fallback_font,p+Vector2(-48,66),"CONTESTED" if beacon.contested else "HOLD TO CLAIM" if str(beacon.owner).is_empty() else "PAINT BEACON",HORIZONTAL_ALIGNMENT_LEFT,120,12,tint)
 else:
  var p=SIZE*.5-g.camera;g.draw_circle(p,76,Color("#173440"));g.draw_arc(p,76,0,TAU,48,Color("#b49b60"),3);g.draw_arc(p,61,0,TAU,48,Color("#698995"),2)
func draw_crown()->void:
 if not active():return
 if world.map_id=="colour_clash":
  for id in world.game.positions:
   if int(world.game.health.get(id,0))<=0:continue
   var p=world.game._player_draw_position(str(id),world.game.positions[id])-world.game.camera;world.game.draw_arc(p+Vector2(0,13),28,0,TAU,32,colour(group(str(id))),3)
  return
 if crown.is_empty():return
 var g=world.game;var p=world.point(crown.pos)
 var holder=str(crown.holder)
 if not holder.is_empty():p=g._player_draw_position(holder,p)
 p-=g.camera
 var lift=-70.0 if not holder.is_empty() else -15.0-12*sin(PI*clampf(float(crown.get("flight",0))/.58,0,1))
 var at=p+Vector2(0,lift);var time=world.clock
 g.draw_circle(at,30,Color(1,.78,.32,.1));g.draw_arc(at,25+sin(time*3)*2,0,TAU,32,Color(1,.85,.45,.5),2)
 var shape=PackedVector2Array([at+Vector2(-18,-10),at+Vector2(-10,-2),at+Vector2(0,-21),at+Vector2(10,-2),at+Vector2(18,-10),at+Vector2(14,13),at+Vector2(-14,13)])
 g.draw_colored_polygon(shape,Color("#e6bc62"));g.draw_polyline(shape+PackedVector2Array([shape[0]]),Color("#fff0bc"),2,true);g.draw_rect(Rect2(at+Vector2(-13,7),Vector2(26,6)),Color("#a77743"));g.draw_circle(at+Vector2(0,4),4,Color("#78cfe4"))
 if not holder.is_empty():g.draw_arc(p+Vector2(0,12),30,0,TAU,32,Color("#f4dc96"),3)
func draw_minimap()->void:
 var g=world.game;var rect=Rect2(g.VIEW.x-220,100,200,145);g.draw_style_box(preload("res://scripts/studio_ui.gd").box("#122a36","#799c9d",7,8),rect)
 if world.map_id=="colour_clash":
  for chunk in dirty:meshes[chunk]=paint_mesh(chunk)
  dirty.clear()
  for chunk in meshes:
   if meshes[chunk]!=null:g.draw_mesh(meshes[chunk],null,Transform2D(0.0,rect.size/SIZE,0.0,rect.position))
  for beacon in beacons:g.draw_arc(rect.position+world.point(beacon.pos)/SIZE*rect.size,5,0,TAU,16,Color("#fff0af"),2)
  for id in g.positions:
   if str(id)==g.my_id or g.pvp_rule=="teams" and group(str(id))==group(g.my_id):g.draw_circle(rect.position+g.positions[id]/SIZE*rect.size,3,Color.WHITE)
 else:
  var font=ThemeDB.fallback_font;var center=rect.position+Vector2(100,70);g.draw_string(font,rect.position+Vector2(12,24),"FOLLOW THE CROWN",HORIZONTAL_ALIGNMENT_LEFT,178,14,Color("#edce85"));g.draw_arc(center,27,0,TAU,32,Color("#7ba6b3"),2)
  var direction=(world.point(crown.get("pos",[1280,960]))-g.local_pos).normalized()
  if str(crown.get("holder",""))!=g.my_id:
   var angle=snappedf(direction.angle(),PI/8);direction=Vector2.from_angle(angle);g.draw_line(center-direction*15,center+direction*25,Color("#f0d88e"),4);g.draw_colored_polygon(PackedVector2Array([center+direction*28,center+direction*15+direction.orthogonal()*8,center+direction*15-direction.orthogonal()*8]),Color("#f0d88e"))
  else:g.draw_circle(center,12,Color("#efcc78"))
  g.draw_string(font,rect.position+Vector2(10,124),"Carry it • pass it • steal it",HORIZONTAL_ALIGNMENT_LEFT,180,12,Color("#b9d0d7"))
func draw_hud()->void:
 if not active():return
 var g=world.game;var font=ThemeDB.fallback_font;var width=maxf(260,g.VIEW.x-270);var columns=keys.size() if width>=720 else mini(4,keys.size());var tile=width/maxi(1,columns);var rows=ceili(float(keys.size())/maxi(1,columns));g.draw_style_box(preload("res://scripts/studio_ui.gd").box("#102835","#557b85",7,5),Rect2(20,99,width,rows*25+29))
 var x=24.0
 if world.map_id=="colour_clash":
  for key in keys:
   var span=width*float(scores.get(key,0))/maxi(1,available);g.draw_rect(Rect2(x,105,span,7),colour(str(key)));x+=span
 else:
  var holder=str(crown.get("holder",""));var title="Crown on the ground • go get it!" if holder.is_empty() else "YOU HAVE THE CROWN • speed %d%%" % roundi(carrier_factor(holder)*100) if holder==g.my_id else "Carrier: "+label(holder if g.pvp_rule=="ffa" else group(holder))
  g.draw_string(font,Vector2(29,115),title,HORIZONTAL_ALIGNMENT_LEFT,width-20,13,Color("#f0d58c"))
 for n in keys.size():
  var key=str(keys[n]);var point=Vector2(29+n%columns*tile,135+int(n/columns)*25);g.draw_circle(point+Vector2(3,-5),4,colour(key));g.draw_string(font,point+Vector2(12,0),label(key).left(10)+" "+(("%.1f%%" if world.map_id=="colour_clash" else "%.1fs") % value(key)),HORIZONTAL_ALIGNMENT_LEFT,tile-14,12,colour(key))
func report()->Dictionary:
 return {"elapsed":elapsed,"painted_cells":available-int(cells.count(0)) if world.map_id=="colour_clash" else 0,"available_cells":available,"paint_revision":revision,"claimed_beacons":beacons.filter(func(b):return not str(b.owner).is_empty()).size(),"carrier_active":not str(crown.get("holder","" )).is_empty(),"carrier_slow":carrier_factor(str(crown.get("holder",""))),"scores":scores}
