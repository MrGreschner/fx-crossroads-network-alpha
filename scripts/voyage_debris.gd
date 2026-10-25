extends RefCounted
## Local, deterministic drift field: never instantiate the whole ocean's debris.
const CELL=800.0
const MAX_PIECES=25
var pieces:Array=[]
var cache_key=""
var specs:Array=[]
var last_boat=Vector2.ZERO
func reset()->void:pieces.clear();specs.clear();cache_key=""
static func capsule_hit(from:Vector2,to:Vector2,a:Vector2,b:Vector2,radius:float)->bool:
 if Geometry2D.segment_intersects_segment(from,to,a,b)!=null:return true
 return Geometry2D.get_closest_point_to_segment(from,a,b).distance_to(from)<=radius or Geometry2D.get_closest_point_to_segment(to,a,b).distance_to(to)<=radius or Geometry2D.get_closest_point_to_segment(a,from,to).distance_to(a)<=radius or Geometry2D.get_closest_point_to_segment(b,from,to).distance_to(b)<=radius
static func center(spec:Dictionary,t:float)->Vector2:
 return Vector2(spec.base)+Vector2(sin(t*.018+float(spec.phase))*210,cos(t*.014+float(spec.phase)*1.7)*180)
func step(v:Node,dt:float)->void:
 if v.route!="coast":reset();return
 var cell=Vector2i(floori(v.boat.x/CELL),floori(v.boat.y/CELL));var key=str(cell)+":"+str(v.night_number())+":"+str(v.night())
 if key!=cache_key:
  cache_key=key;specs.clear()
  for y in range(cell.y-2,cell.y+3):
   for x in range(cell.x-2,cell.x+3):
    var random=RandomNumberGenerator.new();random.seed=absi(x*73856093 ^ y*19349663)+43
    if random.randf()<.18:continue
    var base=Vector2((x+.5)*CELL+random.randf_range(-130,130),(y+.5)*CELL+random.randf_range(-130,130))
    if base.x<850 or base.y<400 or base.x>v.world_size().x-400 or base.y>v.world_size().y-400 or base.distance_to(v.HOME)<1250:continue
    var blocked=false
    for isle in v.islands():
     if base.distance_to(isle.p)<float(isle.r)+500:blocked=true
    if blocked:continue
    var kind=random.randi_range(0,2)
    specs.append({"base":base,"phase":random.randf_range(0,TAU),"angle":random.randf_range(-PI,PI),"half":random.randf_range(42,76) if kind!=2 else 24.0,"radius":9.0 if kind!=2 else 22.0,"kind":kind})
 pieces.clear();last_boat=v.boat
 for spec in specs:
  var p=center(spec,v.elapsed);var previous=center(spec,maxf(0,v.elapsed-dt));var angle=float(spec.angle)+sin(v.elapsed*.025+float(spec.phase))*.35
  var old_angle=float(spec.angle)+sin(maxf(0,v.elapsed-dt)*.025+float(spec.phase))*.35
  var axis=Vector2.from_angle(angle)*float(spec.half);var old_axis=Vector2.from_angle(old_angle)*float(spec.half)
  pieces.append({"p":p,"a":p-axis,"b":p+axis,"old_a":previous-old_axis,"old_b":previous+old_axis,"axis":axis,"radius":spec.radius,"kind":spec.kind})
 assert(pieces.size()<=MAX_PIECES)
func hit(from:Vector2,to:Vector2)->String:
 for piece in pieces:
  if Geometry2D.get_closest_point_to_segment(piece.p,from,to).distance_to(piece.p)>160:continue
  var radius=float(piece.radius)+26
  if capsule_hit(from,to,piece.a,piece.b,radius) or capsule_hit(from,to,piece.old_a,piece.old_b,radius) or capsule_hit(from,to,piece.old_a,piece.a,radius) or capsule_hit(from,to,piece.old_b,piece.b,radius):return "drifting debris"
 return ""
func warning_at(p:Vector2)->bool:
 return pieces.any(func(piece):return p.distance_to(piece.p)<260)
func draw_on(c:Node2D,cam:Vector2)->void:
 var view=Rect2(cam,c.VIEW).grow(150)
 for piece in pieces:
  if not view.has_point(piece.p):continue
  var a:Vector2=piece.a-cam;var b:Vector2=piece.b-cam;var p:Vector2=piece.p-cam;var axis:Vector2=piece.axis.normalized();var side=axis.orthogonal()
  c.draw_line(a+Vector2(2,7),b+Vector2(2,7),Color('#0c2637',.7),float(piece.radius)*2+9,true)
  c.draw_arc(p+Vector2(0,9),float(piece.axis.length())+12,.2,PI-.2,18,Color('#9cbbbd',.4),1.5,true)
  if int(piece.kind)==2:
   var points=PackedVector2Array([p-axis*24-side*22,p+axis*24-side*22,p+axis*24+side*22,p-axis*24+side*22])
   c.draw_colored_polygon(points,Color('#886f4e'));points.append(points[0]);c.draw_polyline(points,Color('#d3b787'),3,true)
   for n in [-12,0,12]:c.draw_line(p+axis*n-side*20,p+axis*n+side*20,Color('#584c39'),2,true)
   c.draw_line(p-axis*20-side*17,p+axis*20+side*17,Color('#b69c6b'),3,true)
  else:
   c.draw_line(a,b,Color('#473f32'),float(piece.radius)*2+4,true);c.draw_line(a,b,Color('#99815a'),float(piece.radius)*2,true)
   c.draw_line(a-side*3,b-side*3,Color('#c2aa79'),3,true)
   for n in range(1,5):
    var at=a.lerp(b,n/5.0);c.draw_line(at-side*6,at+side*6,Color('#66513c'),2,true)
   c.draw_circle(a,float(piece.radius)-1,Color('#d6bd87'));c.draw_arc(a,4,0,TAU,10,Color('#7d6544'),1.5,true)
   if int(piece.kind)==1:c.draw_line(p-axis*13,p-axis*33+side*29,Color('#806947'),9,true);c.draw_line(p+axis*10,p+axis*38-side*22,Color('#a58b5e'),6,true)
