extends RefCounted
## One immutable source for navigation, rendered shores, stair openings and services.
var world:Node
var data:Dictionary={}
var polygons:Array[PackedVector2Array]=[]
var landings:Array[Vector2]=[]
var solids:Array=[]
var grid:AStarGrid2D
var routes:Dictionary={}
func reset()->void:
 data.clear();polygons.clear();landings.clear();solids.clear();routes.clear();grid=null
func setup(source:Node)->void:
 reset();world=source;data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/coast266/layout.json"))
 for shape in data.floors+data.bridges:
  var p=PackedVector2Array()
  for a in shape:p.append(v(a))
  polygons.append(p)
 for p in data.boss_landings:landings.append(v(p))
 for p in data.props:
  if float(p.solid)>0:solids.append({"pos":v(p.pos),"radius":float(p.solid)+16})
 var nav=JSON.parse_string(FileAccess.get_file_as_string("res://assets/coast266/navigation.json"))
 grid=AStarGrid2D.new();grid.region=Rect2i(0,0,int(nav.cols),int(nav.rows));grid.cell_size=Vector2.ONE*60;grid.offset=Vector2.ONE*30;grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grid.update()
 for index in nav.solid:grid.set_point_solid(Vector2i(int(index)%100,int(index)/100))
func v(a:Array)->Vector2:return Vector2(float(a[0]),float(a[1]))
func r(a:Array)->Rect2:return Rect2(float(a[0]),float(a[1]),float(a[2]),float(a[3]))
func floor_at(point:Vector2)->bool:
 for p in polygons:
  if Geometry2D.is_point_in_polygon(point,p):return true
 return false
func can_stand(point:Vector2)->bool:
 if not floor_at(point):return false
 for side in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
  if not floor_at(point+side*18):return false
 for t in data.terraces:
  if r(t.cliff).has_point(point) and not r(t.stairs).grow(-16).has_point(point):return false
 for p in solids:
  if point.distance_squared_to(p.pos)<float(p.radius)*float(p.radius):return false
 return true
func cell(p:Vector2)->Vector2i:return Vector2i(floori(p.x/60),floori(p.y/60))
func nearest(c:Vector2i)->Vector2i:
 if grid.is_in_boundsv(c) and not grid.is_point_solid(c):return c
 for rad in range(1,5):
  for x in range(-rad,rad+1):
   for y in range(-rad,rad+1):
    var q=c+Vector2i(x,y)
    if grid.is_in_boundsv(q) and not grid.is_point_solid(q):return q
 return c
func route(start:Vector2,end:Vector2)->PackedVector2Array:
 if grid==null:return PackedVector2Array()
 var a=nearest(cell(start));var b=nearest(cell(end))
 if not grid.is_in_boundsv(a) or not grid.is_in_boundsv(b) or grid.is_point_solid(a) or grid.is_point_solid(b):return PackedVector2Array()
 return grid.get_point_path(a,b)
func direction(enemy:Dictionary,target:Vector2,ranged:bool)->Vector2:
 if world.combat.path_clear(enemy.pos,target):return world.combat.ranged_direction(enemy,target) if ranged else (target-(enemy.pos as Vector2)).normalized()
 var key=str(enemy.uid);var item:Dictionary=routes.get(key,{})
 if routes.size()>64:routes.clear()
 if world.clock>=float(item.get("until",-1)):item={"path":route(enemy.pos,target),"until":world.clock+1.1};routes[key]=item
 var path:PackedVector2Array=item.get("path",PackedVector2Array());var closest=0;var distance=INF
 for n in path.size():
  var d=(enemy.pos as Vector2).distance_squared_to(path[n])
  if d<distance:distance=d;closest=n
 for n in range(closest,path.size()):
  if (enemy.pos as Vector2).distance_to(path[n])>35:return (path[n]-(enemy.pos as Vector2)).normalized()
 return Vector2.ZERO
