extends RefCounted
## Cosmetic traces and bounded, collision-compatible movement. No trails deal damage.
var clock:=0.0
var tracks:Dictionary={}
var velocities:Dictionary={}
var footprints:Array=[]
const TRAIL_HEROES=["aurel","cindervane","snowman","stormscribe","wick","snail","morrow","velvetwing","vesper","sunflower","iris","teapot"]
func trace(hero:String,p:Vector2,aim:Vector2)->void:
 if footprints.size()>=96:footprints.pop_front()
 footprints.append({"pos":p,"aim":aim,"time":1.6,"hero":hero})
func landing(id:String,p:Vector2,phase:float)->void:
 if not tracks.has(id) or str(tracks[id].get("hero",""))!="ripplejaw":return
 var old:Dictionary=tracks[id];var previous:float=float(old.get("fish_phase",phase))
 if previous>.65 and phase<.25 and p.distance_to(old.get("last_landing",p-Vector2(20,0)))>3:
  trace("ripplejaw",p,Vector2.RIGHT);old.last_landing=p
 old.fish_phase=phase
func advance(delta:float)->void:
 clock+=minf(delta,.1)
 for id in tracks.keys():
  if clock-float(tracks[id].get("seen",clock))>2:tracks.erase(id);velocities.erase(id)
 for i in range(footprints.size()-1,-1,-1):
  footprints[i].time=float(footprints[i].time)-delta
  if float(footprints[i].time)<=0:footprints.remove_at(i)
func sample(id:String,hero:String,p:Vector2,enabled:bool)->void:
 if not enabled:tracks.erase(id);velocities.erase(id);return
 var old:Dictionary=tracks.get(id,{"pos":p,"distance":0.0,"side":1})
 var shift:Vector2=p-old.pos;old.pos=p
 if shift.length()>180:old.distance=0;old.fish_phase=0;velocities.erase(id)
 elif hero in TRAIL_HEROES and shift.length()>.1:
  old.distance=float(old.distance)+shift.length()
  if float(old.distance)>=(8 if hero=="snail" else 22):
   old.distance=0;old.side=-int(old.side)
   trace(hero,p if hero=="snail" else p+shift.normalized().orthogonal()*int(old.side)*6,shift.normalized())
 old.hero=hero;old.seen=clock
 if shift.length()>.1:old.last_move=clock
 tracks[id]=old
func displacement(id:String,hero:String,direction:Vector2,speed:float,delta:float)->Vector2:
 if speed<=0:velocities.erase(id);return Vector2.ZERO
 if hero=="quill":
  var rate:=TAU/.8;var travel:=delta+.8*(cos((clock-delta)*rate)-cos(clock*rate))/rate
  return direction*speed*maxf(0,travel)
 if hero=="cobbleclaw":return direction.rotated(sin(clock*9)*.07)*speed*delta
 if hero=="spindle":return direction.rotated(sin(clock*7)*.19)*speed*delta
 if hero!="snowman":return direction*speed*delta
 var velocity:Vector2=velocities.get(id,Vector2.ZERO)
 velocity=velocity.move_toward(direction*speed,(185.0 if direction.is_zero_approx() else 420.0)*delta)
 velocity=velocity.limit_length(speed);velocities[id]=velocity
 return velocity*delta
func offset(hero:String)->Vector2:
 return Vector2(0,-8+sin(clock*3)*3) if hero=="magnet" else Vector2.ZERO
func draw_trails(c:Node2D,camera:Vector2)->void:
 var visible:=Rect2(Vector2(-64,-64),c.get_viewport_rect().size+Vector2(128,128))
 for foot in footprints:
  var p:Vector2=foot.pos-camera+Vector2(0,15);var aim:Vector2=foot.aim;var fade:=float(foot.time)/1.6
  if not visible.has_point(p):continue
  match str(foot.get("hero","aurel")):
   "aurel":
    c.draw_line(p-aim*4,p+aim*4,Color(1,.15,.12,.48*fade),5,true)
    c.draw_circle(p+aim*7,2,Color(1,.4,.2,.7*fade))
   "snowman":
    c.draw_circle(p,9,Color(.55,.8,.9,.13*fade));c.draw_arc(p,8,0,PI,12,Color(.7,.94,1,.3*fade),1,true)
   "cindervane":
    p+=Vector2(sin(clock*3+p.x)*4,-(1-fade)*35-15)
    c.draw_circle(p,3*fade,Color(1,.4,.13,.65*fade));c.draw_line(p,p+Vector2(2,6),Color(1,.75,.3,.4*fade),2,true)
   "stormscribe":
    var side:=aim.orthogonal()
    c.draw_polyline(PackedVector2Array([p-aim*9,p-aim*2+side*4,p+aim*2-side*3,p+aim*9]),Color(.65,.8,1,.48*fade),1.5,true)
   "snail":
    c.draw_line(p-aim*10,p+aim*10,Color(.82,.22,.15,.22*fade),9,true);c.draw_line(p-aim*10,p+aim*10,Color(1,.45,.24,.17*fade),3,true)
   "ripplejaw":
    c.draw_circle(p,10+4*(1-fade),Color(.37,.74,.84,.13*fade));c.draw_arc(p,13+9*(1-fade),0,TAU,16,Color(.71,.91,.96,.23*fade),1,true)
   "morrow":
    p+=Vector2(sin(clock*2+p.x)*3,-12-(1-fade)*10)
    for n in 3:c.draw_circle(p+Vector2(n*7-7,sin(n)*3),7+n,Color(.18,.15,.25,.11*fade))
   "wick":
    p+=Vector2(sin(clock*4+p.x)*4,-22-(1-fade)*18);c.draw_circle(p,2.3*fade,Color(1,.68,.2,.65*fade));c.draw_line(p,p+Vector2(1,5),Color(1,.85,.42,.3*fade),1,true)
   "velvetwing":
    p+=Vector2(sin(clock*3+p.x)*3,-36+(1-fade)*22);spark(c,p,Color(.77,.49,.94,.5*fade),3)
   "vesper":
    p+=Vector2(0,-24+(1-fade)*7);spark(c,p,Color(.76,.87,1,.55*fade),3);c.draw_arc(p,6,PI*.2,PI*1.25,10,Color(.66,.8,1,.18*fade),1,true)
   "sunflower":
    p+=Vector2(sin(clock*3+p.x)*6,-12+(1-fade)*8);var tint:=Color(1,.83,.32,.48*fade)
    c.draw_colored_polygon(PackedVector2Array([p-Vector2(2,4),p+Vector2(3,0),p+Vector2(1,5),p-Vector2(3,1)]),tint)
   "iris":
    var side:=aim.orthogonal();c.draw_line(p-side*3,p+side*3,Color(.87,.87,.78,.3*fade),1,true);c.draw_line(p-aim*3,p+aim*3,Color(.87,.87,.78,.3*fade),1,true)
   "teapot":
    p+=Vector2(sin(clock*2+p.x)*3,-24-(1-fade)*22);c.draw_circle(p,2+(1-fade)*3,Color(.88,.93,.88,.17*fade))
 for id in tracks:
  var track:Dictionary=tracks[id]
  var hero:String=str(track.get("hero",""));var p:Vector2=track.pos-camera-Vector2(0,6)
  if not visible.has_point(p):continue
  match hero:
   "magnet":
    if clock-float(track.get("last_move",-10))>.18:continue
    for n in 3:c.draw_arc(p,24+n*5,clock*1.8+n,clock*1.8+n+PI*.75,16,Color(.55,.8,1,.12+n*.03),1,true)
   "apiary":
    var count:int=1+int((sin(clock*.45)+1)*1.49)
    for n in count:
     var bee:Vector2=p+Vector2(cos(clock*2+n*TAU/3)*25,sin(clock*2.7+n*TAU/3)*11-20)
     c.draw_circle(bee+Vector2(-1,-2-sin(clock*18+n)),2,Color(.91,.96,.91,.5));c.draw_circle(bee+Vector2(2,-2+sin(clock*18+n)),2,Color(.91,.96,.91,.5));c.draw_line(bee-Vector2(2,0),bee+Vector2(2,0),Color("#e4c475"),3,true);c.draw_line(bee,bee+Vector2(0,1),Color("#514e3c"),1)
   "wick":
    for n in 2:
     var fly:Vector2=p+Vector2(cos(clock*1.8+n*PI)*22,sin(clock*2.1+n*PI)*8-26);c.draw_circle(fly,4,Color(1,.7,.25,.08));c.draw_circle(fly,1.5,Color(1,.85,.39,.7))
   "morrow":
    for n in 3:
     var mist:Vector2=p+Vector2(sin(clock*.9+n*2)*12,7+cos(clock*.7+n)*3);c.draw_circle(mist,9+n*2,Color(.17,.15,.23,.08))
   "velvetwing":
    for n in 3:
     var t:float=fposmod(clock*.75+n/3.0,1);var wing:Vector2=p+Vector2((20 if n%2==0 else -20)+sin(clock*2+n)*3,-36+t*29);spark(c,wing,Color(.75,.47,.95,.45*(1-t)),2)
   "teapot":
    for n in 2:
     var t:float=fposmod(clock*.6+n*.5,1);var steam:Vector2=p+Vector2(17+sin(t*PI*2+n)*3,-20-t*24);c.draw_circle(steam,2+t*3,Color(.9,.95,.9,.2*(1-t)))
func spark(c:Node2D,p:Vector2,tint:Color,r:float)->void:
 c.draw_line(p-Vector2(r,0),p+Vector2(r,0),tint,1,true);c.draw_line(p-Vector2(0,r),p+Vector2(0,r),tint,1,true)
