extends RefCounted
## One authored model for the ocean's shoreline and visible rock footprints.
static var data:Dictionary={}
static func prepare()->void:
 if data.is_empty():data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ocean302/geometry.json"))
static func radius(isle:Dictionary,angle:float)->float:
 prepare()
 var rs:Array=data.islands[str(isle.name)].radii
 var value=fposmod(angle,TAU)*80.0/TAU;var i=floori(value)%80;var j=(i+1)%80
 var a=Vector2.from_angle(i*TAU/80)*float(rs[i]);var b=Vector2.from_angle(j*TAU/80)*float(rs[j]);var edge=b-a;var dir=Vector2.from_angle(angle)
 var den=dir.cross(edge)
 return float(isle.r)*(a.cross(edge)/den if absf(den)>.000001 else float(rs[i]))
static func coast_x(y:float)->float:
 prepare()
 var points:Array=data.mainland_edge;var i=clampi(floori(y/160),0,points.size()-2);var a=points[i];var b=points[i+1]
 return lerpf(float(a[0]),float(b[0]),clampf((y-float(a[1]))/(float(b[1])-float(a[1])),0,1))
static func variant(rock:Dictionary)->int:return posmod(int(rock.get("variant302",int(rock.p.x+rock.p.y))),12)
static func footprint(rock:Dictionary)->PackedVector2Array:
 prepare()
 var result=PackedVector2Array()
 for p in data.rocks[variant(rock)].footprint:result.append(Vector2(rock.p)+Vector2(float(p[0]),float(p[1]))*float(rock.r))
 return result
static func clearance(rock:Dictionary,point:Vector2)->float:
 var p=footprint(rock);var distance=INF
 for n in p.size():distance=minf(distance,point.distance_to(Geometry2D.get_closest_point_to_segment(point,p[n],p[(n+1)%p.size()])))
 return -distance if Geometry2D.is_point_in_polygon(point,p) else distance
static func rock_hit(rock:Dictionary,from:Vector2,to:Vector2,padding:float=25)->bool:
 if Geometry2D.get_closest_point_to_segment(rock.p,from,to).distance_to(rock.p)>float(rock.r)*1.17+padding:return false
 var p=footprint(rock)
 if Geometry2D.is_point_in_polygon(from,p) or Geometry2D.is_point_in_polygon(to,p):return true
 for n in p.size():
  var a=p[n];var b=p[(n+1)%p.size()]
  if Geometry2D.segment_intersects_segment(from,to,a,b)!=null:return true
  if from.distance_to(Geometry2D.get_closest_point_to_segment(from,a,b))<=padding or to.distance_to(Geometry2D.get_closest_point_to_segment(to,a,b))<=padding:return true
  if a.distance_to(Geometry2D.get_closest_point_to_segment(a,from,to))<=padding or b.distance_to(Geometry2D.get_closest_point_to_segment(b,from,to))<=padding:return true
 return false

static func crater_radius(angle:float)->float:
 prepare()
 var value=fposmod(angle,TAU)*80.0/TAU;var i=floori(value)%80;var j=(i+1)%80
 var a=Vector2.from_angle(i*TAU/80)*float(data.crater_radii[i]);var b=Vector2.from_angle(j*TAU/80)*float(data.crater_radii[j]);var e=b-a
 return a.cross(e)/Vector2.from_angle(angle).cross(e)
static func crater_contains(point:Vector2)->bool:return point.length()<crater_radius(point.angle())
const EDDIES=[{"p":Vector2(10600,3400),"r":1250.0,"power":90.0,"dir":1.0},{"p":Vector2(19100,11900),"r":950.0,"power":80.0,"dir":-1.0},{"p":Vector2(11600,16500),"r":1050.0,"power":85.0,"dir":1.0}]
static func eddy_force(point:Vector2)->Vector2:
 var flow=Vector2.ZERO
 for e in EDDIES:
  var d=point-Vector2(e.p);var distance=d.length()
  if distance<float(e.r) and distance>20:flow+=d.normalized().orthogonal()*float(e.power)*float(e.dir)*(1-distance/float(e.r))
 return flow
static func region(point:Vector2)->String:
 var x=point.x+250*sin(point.y/1500)+90*sin(point.y/450);var y=point.y+300*sin(point.x/2300)+120*sin(point.x/600)
 if x<4100 and y>3800:return "shoals"
 if x<6500 and y<3800:return "reef"
 if x<6500:return "kelp"
 if x>=17000 and y<10000:return "opal"
 if x>=15000 and y>=10000:return "deeps"
 if y<6500 or x>=15000 and y<10000:return "storm"
 if y>=14500:return "trench"
 return "wrecks"
const REGION_NAMES={"shoals":"Sunlit Shoals","reef":"Glassreef Shelf","kelp":"Kelp Cathedral","wrecks":"Sundered Fleet","storm":"Stormglass Reach","opal":"Opal Drift","deeps":"Compass Deeps","trench":"Lantern Trench"}
