extends Node
## Shared solo/co-op presentation, ice momentum and boss unsticking.
var adventure:Node
var id:=""
var data:Dictionary={}
var momentum:Dictionary={}
var boss_tracks:Dictionary={}
var clock:=0.0
var scenery:Array=[]
var art:Dictionary={}
func setup(realm:String)->void:
 id=realm;momentum.clear();boss_tracks.clear();clock=0;scenery.clear()
 if id=="ice":adventure.game.art["packed_snow"]=preload("res://scripts/source_art.gd").texture("res://assets/packed_snow.svg")
 data=adventure.game.regions.get(id,{}) if adventure.arcade else adventure.game.region
 var details:Array=data.get("route_points",[])
 if id in ["sunfield","petalbrook"]:details=adventure.immersive.data.get("meadow_details",[])
 var random=RandomNumberGenerator.new();random.seed=152+id.hash()
 if id in ["sunfield","petalbrook"]:
  for patch in details:
   var bounds:=Rect2(patch.rect[0],patch.rect[1],patch.rect[2],patch.rect[3])
   for n in 22:scenery.append({"pos":bounds.position+Vector2(random.randf_range(30,bounds.size.x-30),random.randf_range(30,bounds.size.y-30)),"kind":"sunflower" if str(patch.kind)=="sunflower" else "petal" if id=="petalbrook" else "wheat"})
 elif id in ["grove","quarry","ice"]:
  for p in details:
   for side in [-1,1]:
    for n in 6:scenery.append({"pos":Vector2(p[0]+n*35-80,p[1]+side*(215+n%3*15)),"kind":"snow" if id=="ice" else "ore" if id=="quarry" else "fern"})
 for kind in ["wheat","sunflower","petal","fern","ore","snow"]:
  art[kind]=preload("res://scripts/source_art.gd").texture("res://assets/realm_"+kind+".svg")
func icy(point:Vector2)->bool:
 if id!="ice":return false
 for patch in data.get("slip_patches",[]):
  if Rect2(patch[0],patch[1],patch[2],patch[3]).has_point(point):return true
 return false
func motion(player:String,point:Vector2,move:Vector2,delta:float)->Vector2:
 if not icy(point):momentum.erase(player);return move
 if adventure.combat.stunned(adventure.combat.player_key(player)) or (not adventure.arcade and adventure.game.stun_time>0):momentum.erase(player);return Vector2.ZERO
 if not momentum.has(player):
  if move.is_zero_approx():return move
  momentum[player]=move/maxf(.001,delta)
 # Mostly retain entry momentum; a little steering keeps the patch fair.
 var velocity:Vector2=momentum[player]
 if not move.is_zero_approx():velocity=velocity.lerp(move/maxf(.001,delta),minf(.08,delta*.35))
 velocity=velocity.limit_length(330)
 momentum[player]=velocity
 return velocity*delta
func bosses(delta:float)->void:
 if not adventure.authoritative() or not adventure.combat.playing():return
 clock+=delta
 var live:Dictionary={}
 for enemy in adventure.foes():
  if bool(enemy.get("finale_actor",false)) or not bool(enemy.get("boss",false)) or float(enemy.get("hp",0))<=0 or float(enemy.get("down_time",0))>0 or bool(enemy.get("buried",false)):continue
  var key:String=adventure.combat.npc_key(enemy);live[key]=true
  if adventure.combat.stunned(key):boss_tracks.erase(key);continue
  var target:Vector2=enemy.pos;var distance:=INF
  for player in adventure.points():
   if adventure.alive(str(player)) and enemy.pos.distance_to(adventure.points()[player])<distance:target=adventure.points()[player];distance=enemy.pos.distance_to(target)
  if distance>1100:boss_tracks.erase(key);continue
  var entry:Dictionary=boss_tracks.get(key,{"pos":enemy.pos,"idle":0.0})
  if enemy.pos.distance_to(entry.pos)>2:entry={"pos":enemy.pos,"idle":0.0}
  else:entry.idle=float(entry.idle)+delta
  boss_tracks[key]=entry
  if float(entry.idle)<1.1:continue
  # Correct only stalled movement, so authored charges/orbits retain their identity.
  var heading:Vector2=(target-(enemy.pos as Vector2)).normalized()
  if distance<190:heading=heading.orthogonal()*(-1 if int(enemy.get("uid",0))%2 else 1)
  var amount:float=92*delta*adventure.combat.speed_factor(key)
  for angle in [0.0,.7,-.7,1.5,-1.5]:
   var next:Vector2=enemy.pos+heading.rotated(angle)*amount
   if adventure.can_stand(next) and adventure.combat.path_clear(enemy.pos,next):enemy.pos=next;break
 for key in boss_tracks.keys():
  if not live.has(key):boss_tracks.erase(key)
func draw_world(c:Node2D,camera:Vector2)->void:
 if id not in ["grove","quarry","ice","sunfield","petalbrook"]:return
 var view:=Rect2(camera,c.get_viewport_rect().size).grow(100)
 for item in scenery:
  if view.has_point(item.pos) and art.get(item.kind)!=null:c.draw_texture_rect(art[item.kind],Rect2(item.pos-camera-Vector2(36,42),Vector2(72,72)),false)
 if id=="quarry":
  var path:Array=data.get("route_points",[])
  for n in path.size()-1:
   var a:=Vector2(path[n][0],path[n][1]);var b:=Vector2(path[n+1][0],path[n+1][1]);var along:Vector2=(b-a).normalized();var across:=along.orthogonal()*28
   for side in [-1,1]:c.draw_line(a+across*side-camera,b+across*side-camera,Color("#756359"),4)
   for offset in range(0,int(a.distance_to(b)),90):
    var p:=a+along*offset
    if view.has_point(p):c.draw_line(p-across*1.3-camera,p+across*1.3-camera,Color("#483e39"),7)
 if id=="ice":
  for patch in data.get("slip_patches",[]):
   var bounds:=Rect2(patch[0],patch[1],patch[2],patch[3])
   if not bounds.intersects(view):continue
   var p:=bounds.position-camera
   c.draw_style_box(ice_style(),Rect2(p,bounds.size))
   for n in 6:
    var start:=p+Vector2(35+n*bounds.size.x/7,35+posmod(n*57,int(bounds.size.y)-60))
    c.draw_polyline(PackedVector2Array([start,start+Vector2(45,28),start+Vector2(78,10),start+Vector2(100,42)]),Color("#d8f7ff"),2,true)
   c.draw_string(ThemeDB.fallback_font,p+Vector2(25,28),"SLIPPERY ICE",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#315c79"))
  # Rink boards and lane markings frame the later fight without blocking travel.
  for x in range(2600,6100,260):
   if not view.has_point(Vector2(x,420)):continue
   c.draw_rect(Rect2(Vector2(x,420)-camera,Vector2(235,24)),Color("#416480"));c.draw_rect(Rect2(Vector2(x,420)-camera+Vector2(0,4),Vector2(235,8)),Color("#f0d2a2"))
  for x in [2400,4800]:
   if view.has_point(Vector2(x,960)):c.draw_arc(Vector2(x,960)-camera,170,0,TAU,48,Color(.4,.59,.7,.32),4)
 if id in ["grove","quarry","ice"]:
  var routes:Array=data.get("route_points",[])
  for n in routes.size():
   var point:=Vector2(routes[n][0],routes[n][1])
   if not view.has_point(point):continue
   if n==0 or n==3:
    var title:="ARRIVAL GLADE" if id=="grove" else "COOLED EMBER TRAIL" if id=="quarry" else "PRACTICE SNOW" if n==0 else "THE FRACTURED RINK"
    c.draw_rect(Rect2(point-camera+Vector2(-140,-245),Vector2(280,42)),Color("#3c4a40"))
    c.draw_string(ThemeDB.fallback_font,point-camera+Vector2(-127,-216),title,HORIZONTAL_ALIGNMENT_LEFT,260,18,Color("#f1d9a3"))
func ice_style()->StyleBoxFlat:
 if not has_meta("ice_style"):
  var style=StyleBoxFlat.new();style.bg_color=Color("#96c9e0");style.border_color=Color("#d5edf1");style.set_border_width_all(6);style.set_corner_radius_all(35);set_meta("ice_style",style)
 return get_meta("ice_style")
