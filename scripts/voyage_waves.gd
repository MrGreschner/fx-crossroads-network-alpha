extends RefCounted
## Bounded travelling fronts. Never run commands or access external resources.
var waves:Array=[]
var age=0.0
var next_open=8.0
var next_surf=5.0
var serial=0
func reset()->void:waves.clear();age=0;next_open=8;next_surf=5;serial=0
func add_front(origin:Vector2,direction:Vector2,large:bool,shore:bool)->void:
 if waves.size()>=8:return
 waves.append({"origin":origin,"dir":direction.normalized(),"born":age,"large":large,"shore":shore,"lead":1.8,"life":8.0,"speed":220.0 if large else 165.0,"width":650.0 if large else 420.0,"power":520.0 if large else 340.0})
func crest(w:Dictionary)->Vector2:return Vector2(w.origin)+Vector2(w.dir)*maxf(0,age-float(w.born)-float(w.lead))*float(w.speed)
func step(v:Node,dt:float)->void:
 if v.route!="coast":waves.clear();return
 age+=dt;waves=waves.filter(func(w):return age-float(w.born)<float(w.life)+float(w.lead))
 if v.boat.distance_to(v.HOME)<700:return
 var random=RandomNumberGenerator.new();random.seed=serial*7919+int(v.boat.x/800)*73+int(v.boat.y/800)*41+17
 if age>=next_open:
  serial+=1;next_open=age+(9.0 if str(v.context().weather)=="Storm" else 13.0)
  var dir=Vector2.from_angle(random.randf_range(-PI,PI));var large=serial%3==0 or str(v.context().weather)=="Storm" and serial%2==0
  add_front(v.boat-dir*520+dir.orthogonal()*random.randf_range(-180,180),dir,large,false)
 if age>=next_surf:
  next_surf=age+10
  var shore_dir=Vector2.LEFT if v.boat.x<1300 else Vector2.ZERO;var nearest=780.0
  for isle in v.islands():
   var distance=v.ISLES.distance_to_shore(isle,v.boat)
   if distance<nearest:nearest=distance;shore_dir=(Vector2(isle.p)-v.boat).normalized()
  if shore_dir!=Vector2.ZERO:serial+=1;add_front(v.boat-shore_dir*450,shore_dir,serial%2==0,true)
func force_at(p:Vector2)->Vector2:
 if p.distance_to(Vector2(1100,5650))<650:return Vector2.ZERO
 var force=Vector2.ZERO
 for w in waves:
  var t=age-float(w.born)-float(w.lead)
  if t<0:continue
  var rel=p-crest(w);var across=absf(rel.dot(Vector2(w.dir).orthogonal()))/(float(w.width)*.5);var depth=absf(rel.dot(w.dir))/85.0
  force+=Vector2(w.dir)*float(w.power)*maxf(0,1-depth)*clampf((1-across)*4,0,1)*clampf((float(w.life)-t)/1.3,0,1)
 return force.limit_length(620)
func warning_at(p:Vector2)->String:
 for w in waves:
  var relative=p-crest(w)
  if relative.length()<1000 and relative.dot(w.dir)>-100:return "SURF: steer along shore" if w.shore else "LARGE SWELL" if w.large else "MEDIUM SWELL"
 return ""
func draw_on(c:Node2D,cam:Vector2)->void:
 var view=Rect2(cam,c.VIEW).grow(200)
 for w in waves:
  var center=crest(w)
  if not view.grow(float(w.width)*.5).has_point(center):continue
  var t=age-float(w.born);var alpha=clampf(t/float(w.lead),0,1)*clampf((float(w.life)+float(w.lead)-t)/1.3,0,1)
  var direction=Vector2(w.dir);var side=direction.orthogonal();var front=PackedVector2Array();var back=PackedVector2Array()
  for n in 41:
   var f=n/40.0;var u=(f-.5)*float(w.width);var taper=sin(f*PI);var bow=cos(u/float(w.width)*PI)*25
   front.append(center+side*u+direction*(bow+sin(n*1.7+age*4)*3*taper)-cam)
   back.append(center+side*u+direction*(bow-(110 if w.large else 70)*taper)-cam)
  var body=front.duplicate()
  for n in range(back.size()-1,-1,-1):body.append(back[n])
  c.draw_colored_polygon(body,Color(.24,.52,.64,alpha*.42))
  c.draw_polyline(front,Color(.42,.75,.82,alpha*.7),12 if w.large else 8,true)
  for n in range(1,40):
   var fade=sin(n/40.0*PI);c.draw_line(front[n-1],front[n],Color(.84,.96,.94,alpha*fade),3.5 if w.large else 2.5,true)
   if n%3==0:
    var foam=front[n]-direction*(12+posmod(n*7,33));c.draw_arc(foam,3+n%4,0,PI*1.6,8,Color(.8,.94,.94,alpha*fade*.7),1.5,true)
   if n%2==0:c.draw_line(front[n]-direction*32,front[n]+side*8-direction*(38+sin(n)*8),Color(.51,.77,.81,alpha*.45),2,true)
