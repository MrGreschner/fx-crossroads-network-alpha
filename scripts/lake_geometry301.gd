extends RefCounted
## One authored model for Oldwater's shoreline and visible rock footprints.
static var data:Dictionary={}
static func prepare()->void:
 if data.is_empty():data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/lake301/geometry.json"))
static func lake_island(isle:Dictionary)->bool:
 return str(isle.get("name","")) in ["Birch Landing","Oldwater Isle","Reedwatch Island"]
static func radius(isle:Dictionary,angle:float)->float:
 prepare()
 var rs:Array=data.islands[str(isle.name)].radii
 var value=fposmod(angle,TAU)*80.0/TAU;var i=floori(value)%80;var j=(i+1)%80
 var a=Vector2.from_angle(i*TAU/80)*float(rs[i]);var b=Vector2.from_angle(j*TAU/80)*float(rs[j]);var edge=b-a;var dir=Vector2.from_angle(angle)
 var den=dir.cross(edge)
 return float(isle.r)*(a.cross(edge)/den if absf(den)>.000001 else float(rs[i]))
static func coast_x(y:float)->float:
 prepare()
 var points:Array=data.mainland_edge;var i=clampi(floori(y/80),0,points.size()-2);var a=points[i];var b=points[i+1]
 return lerpf(float(a[0]),float(b[0]),clampf((y-float(a[1]))/(float(b[1])-float(a[1])),0,1))
static func variant(rock:Dictionary)->int:return posmod(int(rock.get("variant301",int(rock.p.x+rock.p.y))),8)
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
 if Geometry2D.get_closest_point_to_segment(rock.p,from,to).distance_to(rock.p)>float(rock.r)+padding:return false
 var p=footprint(rock)
 if Geometry2D.is_point_in_polygon(from,p) or Geometry2D.is_point_in_polygon(to,p):return true
 for n in p.size():
  var a=p[n];var b=p[(n+1)%p.size()]
  if Geometry2D.segment_intersects_segment(from,to,a,b)!=null:return true
  if from.distance_to(Geometry2D.get_closest_point_to_segment(from,a,b))<=padding or to.distance_to(Geometry2D.get_closest_point_to_segment(to,a,b))<=padding:return true
  if a.distance_to(Geometry2D.get_closest_point_to_segment(a,from,to))<=padding or b.distance_to(Geometry2D.get_closest_point_to_segment(b,from,to))<=padding:return true
 return false
