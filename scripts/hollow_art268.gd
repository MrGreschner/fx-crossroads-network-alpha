extends RefCounted
## Culled scenery, cached textures and bounded presentation-only burrow transitions.
static var textures:Dictionary={}
static var frames:Dictionary={}
static var metadata:Dictionary={}
static var placements:Array=[]
var actors:Dictionary={}
var trails:Array=[]
var last_time:float=-1
var visual_clock:=0.0
static func texture(id:String)->Texture2D:
 if textures.has(id):return textures[id]
 var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/hollow268/"+id+".png"));var t=ImageTexture.create_from_image(im);textures[id]=t;return t
static func frame(id:String)->Texture2D:
 if frames.has(id):return frames[id]
 if metadata.is_empty():metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/hollow268/props.json"))
 var r:Array=metadata[id];var t=AtlasTexture.new();t.atlas=texture("props"+str(int(r[0])));t.region=Rect2(r[1],r[2],r[3],r[4]);frames[id]=t;return t
func reset()->void:actors.clear();trails.clear();last_time=-1;visual_clock=0
func advance(w:Node,dt:float)->void:
 visual_clock+=dt
 for i in range(trails.size()-1,-1,-1):
  trails[i].life-=dt
  if float(trails[i].life)<=0:trails.remove_at(i)
 var live={}
 for e in w.adventure.foes():
  if str(e.type)not in w.TYPES:continue
  var key=str(e.get("uid",0))+":"+str(e.type);live[key]=true;var at:Vector2=e.pos;var hidden=bool(e.get("buried",false))
  if not actors.has(key):actors[key]={"pos":at,"last":at,"visible":0.0 if hidden else 1.0,"dir":Vector2.RIGHT,"gait":0.0,"trail":0.0,"buried":hidden,"speed":0.0}
  var a:Dictionary=actors[key];var movement=at-(a.last as Vector2);a.speed=movement.length()/maxf(dt,.001)
  # Teleports and warren changes snap; ordinary replicated movement is exponentially smoothed.
  a.pos=at if (a.pos as Vector2).distance_to(at)>180 else (a.pos as Vector2).lerp(at,1-exp(-22*dt))
  if movement.length()>0.02:a.dir=(a.dir as Vector2).lerp(movement.normalized(),1-exp(-14*dt)).normalized();a.gait+=movement.length()*.12
  a.visible=move_toward(float(a.visible),0.0 if hidden else 1.0,dt/.28);a.trail+=movement.length()
  if hidden and movement.length()>.1 and float(a.trail)>20 and trails.size()<96:
   trails.append({"pos":at,"dir":a.dir,"life":.9,"boss":bool(e.get("boss",false))});a.trail=0.0
  a.last=at;a.buried=hidden
 for key in actors.keys():
  if not live.has(key):actors.erase(key)
func tick(w:Node)->void:
 var now=Time.get_ticks_usec()/1000000.0;var dt=0.0 if last_time<0 else clampf(now-last_time,0,.1);last_time=now;advance(w,dt)
static func label(c:CanvasItem,at:Vector2,text:String,size:int=17)->void:
 var f=ThemeDB.fallback_font;var p=at-Vector2(f.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x/2,0);c.draw_string_outline(f,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,4,Color("#202b35"));c.draw_string(f,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("#dce2c1"))
static func place(c:Node2D,id:String,at:Vector2,size:Vector2,cam:Vector2,alpha:float=1)->void:
 var r=Rect2(at-cam-size*Vector2(.5,.94),size)
 if Rect2(Vector2.ZERO,c.VIEW).grow(100).intersects(r):c.draw_texture_rect(frame(id),r,false,Color(1,1,1,alpha))
static func cart(c:Node2D,cam:Vector2)->void:
 place(c,"cart",Vector2(950,1750),Vector2(210,190),cam);label(c,Vector2(950,1545)-cam,"MERCHANT",15)
func draw_world(w:Node,c:Node2D,cam:Vector2)->void:
 tick(w);var view=Rect2(cam,c.VIEW)
 c.draw_rect(Rect2(Vector2.ZERO,c.VIEW),Color("#18222c"))
 for n in 4:
  var r=Rect2(n%2*3200,n/2*3500,3200,3500)
  if r.intersects(view):c.draw_texture_rect(texture("ground"+str(n)),Rect2(r.position-cam,r.size),false)
 if placements.is_empty():placements=JSON.parse_string(FileAccess.get_file_as_string("res://assets/hollow268/placements.json"))
 for p in placements:
  if p.kind=="cart":continue
  var at=Vector2(p.pos[0],p.pos[1]);var sz=Vector2(p.size[0],p.size[1]);var r=Rect2(at-sz*Vector2(.5,.94),sz)
  if not r.grow(60).intersects(view):continue
  var alpha=1.0
  if sz.y>175:
   for hero in w.adventure.points().values():
    if r.has_point((hero as Vector2)-Vector2(0,24)):alpha=.32
  place(c,str(p.kind),at,sz,cam,alpha)
  if p.kind in ["lantern","well","oak","mine_gate","den"]:
   var q=at-cam-Vector2(0,sz.y*.4);c.draw_circle(q,8+sin(visual_clock*2+at.x)*1.2,Color(.98,.7,.31,.12))
  elif p.kind in ["crystals","glow_log","nursery","cave_pool"]:
   var q=at-cam-Vector2(0,sz.y*.3);c.draw_circle(q,12+sin(visual_clock+at.x)*2,Color(.37,.74,.85,.09))
 # Surface chasms retain exactly the original bridge openings. Thin rails sit outside each walking deck.
 if cam.y<3700:
  for a in [[2080,700],[4100,2900]]:
   for side in [-1,1]:c.draw_line(Vector2(a[0]-20,a[1]+side*117)-cam,Vector2(a[0]+260,a[1]+side*117)-cam,Color("#a49979"),4,true)
  for item in [[Vector2(950,1750),"FOXTAIL COMMON"],[Vector2(3150,1750),"ROOTWELL RIDGE"],[Vector2(5350,1750),"MOONSTONE GARDEN"]]:
   if view.grow(180).has_point(item[0]):label(c,item[0]-cam-Vector2(0,300),item[1])
 else:
  for n in 4:
   var at=w.CAVE_GATES[n]-Vector2(0,260)
   if view.grow(180).has_point(at):label(c,at-cam,["FOXTAIL DEN","THE FUSEWORKS","GLITTERVEIN","ANCIENT WARREN"][n])
 for gate in w.routes():
  if not view.grow(200).has_point(gate.pos):continue
  label(c,gate.pos-cam-Vector2(0,190),str(gate.label),14)
  for hero in w.adventure.points().values():
   if (hero as Vector2).distance_to(gate.pos)<140:label(c,gate.pos-cam+Vector2(0,83),"E • TRAVEL",14);break
func draw_enemy(w:Node,c:Node2D,e:Dictionary,cam:Vector2)->void:
 var key=str(e.get("uid",0))+":"+str(e.type);var a:Dictionary=actors.get(key,{"pos":e.pos,"visible":0.0 if bool(e.get("buried",false))else 1.0,"gait":0.0,"dir":Vector2.RIGHT});var p:Vector2=a.pos-cam
 if not Rect2(Vector2.ZERO,c.VIEW).grow(180).has_point(p):return
 var v=float(a.visible);var boss=bool(e.get("boss",false));var hidden=bool(e.get("buried",false));var actor=preload("res://scripts/hollow_actors268.gd")
 if v>0.01:
  var walking=float(a.get("speed",0))>2
  var pose="attack"if float(e.get("v143_pose",0))>w.adventure.newcomers.clock else "walk1"if walking and sin(float(a.gait))>0 else "walk2"if walking else "idle"
  pose=preload("res://scripts/enemy_animation275.gd").phase_pose(str(e.type),pose,float(a.gait)/.12)
  var box=Rect2(p-Vector2(50,50),Vector2(100,100))if boss else Rect2(p-Vector2(28,30),Vector2(56,56));var r=actor.fitted(str(e.type),box)
  var height=r.size.y*maxf(.05,v);r.position.y=r.end.y-height;r.size.y=height
  r=preload("res://scripts/enemy_animation275.gd").motion(c,str(e.type),pose,r,float(a.gait)/.12)
  c.draw_texture_rect(actor.texture(str(e.type),pose),r,false,Color(1,1,1,.45+.55*v))
 if hidden or v<.98:
  var sz=Vector2(125,63)if boss else Vector2(61,32);var n=1 if hidden and sin(visual_clock*9)>0 else 0 if hidden else 3
  c.draw_texture_rect(actor.texture("dig_fx",["idle","walk1","walk2","attack"][n]),Rect2(p-sz*Vector2(.5,.64),sz),false)
  var dir:Vector2=a.dir;var wing=dir.orthogonal()
  for k in 3:
   var q=p-dir*(k*8+5);c.draw_line(q-wing*9,q+wing*9,Color(.59,.48,.34,.5),1.5,true)
func draw_trails(c:Node2D,cam:Vector2)->void:
 for t in trails:
  var p:Vector2=t.pos-cam
  if not Rect2(Vector2.ZERO,c.VIEW).grow(100).has_point(p):continue
  var side:Vector2=(t.dir as Vector2).orthogonal();var width=19 if bool(t.boss)else 9;var alpha=float(t.life)/.9*.4
  c.draw_line(p-side*width,p+side*width,Color(.46,.36,.25,alpha),3,true)
