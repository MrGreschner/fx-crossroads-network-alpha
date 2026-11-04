extends RefCounted
## Baked ground pages and shared props; bounded, world-anchored animation, no new lights or physics.
static var cache:Dictionary={}
static var frames:Dictionary={}
static var meta:Dictionary={}
static var shores:Array=[]
static func texture(id:String)->Texture2D:
 if cache.has(id):return cache[id]
 var im=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/coast266/"+id+".png"))!=OK:return null
 var t=ImageTexture.create_from_image(im);cache[id]=t;return t
static func frame(id:String)->Texture2D:
 if frames.has(id):return frames[id]
 if meta.is_empty():meta=JSON.parse_string(FileAccess.get_file_as_string("res://assets/coast266/props.json"))
 var a:Array=meta[id];var t=AtlasTexture.new();t.atlas=texture("props");t.region=Rect2(a[0],a[1],a[2],a[3]);frames[id]=t;return t
static func rect(p:Dictionary,cam:Vector2)->Rect2:
 var size=Vector2(p.size[0],p.size[1]);return Rect2(Vector2(p.pos[0],p.pos[1])-cam-size*Vector2(.5,.95),size)
static func fade(w:Node,r:Rect2,cam:Vector2)->float:
 for p in w.combat.adventure.points().values():
  if r.grow(20).has_point((p as Vector2)-cam-Vector2(0,30)):return .32
 return 1.0
static func cart(c:Node2D,cam:Vector2)->void:
 var at=Vector2(750,1650)-cam;var r=Rect2(at-Vector2(102,154),Vector2(204,174))
 if not Rect2(Vector2.ZERO,c.VIEW).grow(60).intersects(r):return
 c.draw_texture_rect(frame("cart"),r,false)
 label(c,at+Vector2(0,-170),"MERCHANT",15)
static func label(c:Node2D,p:Vector2,title:String,size:int=17)->void:
 var font=ThemeDB.fallback_font;var width=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x;var pos=p-Vector2(width/2,0)
 c.draw_string_outline(font,pos,title,HORIZONTAL_ALIGNMENT_LEFT,-1,size,4,Color("#28444e"));c.draw_string(font,pos,title,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("#f2e6c6"))
static func draw_world(w:Node,c:Node2D,cam:Vector2)->void:
 var view=Rect2(cam,c.VIEW);var local=Rect2(Vector2.ZERO,c.VIEW).grow(100);var data=w.terrain.data
 c.draw_rect(Rect2(Vector2.ZERO,c.VIEW),Color("#245b6b"))
 for i in 3:
  var r=Rect2(i*2000,0,2000,3200)
  if r.intersects(view):c.draw_texture_rect(texture("ground"+str(i)),Rect2(r.position-cam,r.size),false)
 # A maximum 24 visible surface glints, anchored to world water, not a screen overlay.
 var count=0
 for x in range(floori(cam.x/180)*180,int(cam.x+c.VIEW.x)+180,180):
  for y in range(floori(cam.y/170)*170,int(cam.y+c.VIEW.y)+170,170):
   var p=Vector2(x+fposmod(w.clock*7+x*.13,60),y+sin(w.clock*.5+x*.01)*4)
   if count<24 and not w.terrain.floor_at(p):c.draw_arc(p-cam,18,w.clock*.1,PI+w.clock*.1,10,Color(.72,.91,.86,.18),1.5,true);count+=1
 if shores.is_empty():shores=JSON.parse_string(FileAccess.get_file_as_string("res://assets/coast266/shore.json"))
 var foam=0
 for n in range(0,shores.size(),3):
  var a:Array=shores[n];var at=Vector2(a[0],a[1])-cam
  if foam<16 and local.has_point(at):
   c.draw_arc(at+Vector2(0,22),13+sin(w.clock*.8+n)*4,0,PI,10,Color(.87,.95,.87,.2),1.5,true);foam+=1
 for p in data.props:
  if bool(p.fore):continue
  var r=rect(p,cam)
  if not local.intersects(r):continue
  c.draw_texture_rect(frame(str(p.kind)),r,false,Color(1,1,1,fade(w,r,cam) if p.kind in ["lighthouse","observatory","cliff","sea_stack","arch"] else 1.0))
  if p.kind=="lighthouse":
   # Matte lamp sweep: a few translucent strokes, no light node, shader or huge full-screen cone.
   var hub=Vector2(p.pos[0],p.pos[1])-cam+Vector2(0,-float(p.size[1])*.78);var ray=Vector2.from_angle(w.clock*.35)
   c.draw_circle(hub,11,Color(.97,.83,.5,.2));c.draw_line(hub,hub+ray*130,Color(.97,.86,.6,.15),5,true)
  elif p.kind=="skiff":
   var p0=Vector2(p.pos[0],p.pos[1])-cam
   c.draw_arc(p0+Vector2(0,10+sin(w.clock*1.2)*2),55,0,PI,16,Color(.82,.94,.89,.3),2,true)
 for fall in data.falls:
  var at=Vector2(fall.pos[0],fall.pos[1])-cam;var size=Vector2(fall.size[0],fall.size[1]);var r=Rect2(at-size*Vector2(.5,.12),size)
  if not local.intersects(r):continue
  c.draw_texture_rect(frame("waterfall"),r,false)
  for n in 5:
   var q=r.position+Vector2(size.x*(.3+n*.1),fposmod(w.clock*72+n*51,size.y*.8))
   c.draw_line(q,q+Vector2(0,22),Color(.84,.98,.96,.38),2,true)
  c.draw_arc(r.position+Vector2(size.x*.5,size.y*.89),28+fposmod(w.clock*11,20),0,PI,16,Color(.8,.95,.91,.28),2,true)
 for mark in data.landmarks:
  var p=Vector2(mark.pos[0],mark.pos[1])-cam
  if local.has_point(p):label(c,p,str(mark.name))
static func draw_on(w:Node,c:Node2D,cam:Vector2)->void:
 var data=w.terrain.data;var local=Rect2(Vector2.ZERO,c.VIEW).grow(100)
 for p in data.props:
  if not bool(p.fore):continue
  var r=rect(p,cam)
  if not local.intersects(r):continue
  var at=Vector2(p.pos[0],p.pos[1])-cam;var alpha=fade(w,r,cam)
  c.world_transform(at,sin(w.clock*.65+at.x*.01)*.006);c.draw_texture_rect(frame("pine"),Rect2(r.position-at,r.size),false,Color(1,1,1,alpha));c.world_transform()
 for n in w.GATES.size():
  var p:Vector2=w.GATES[n]-cam
  if not local.grow(120).has_point(p):continue
  c.draw_texture_rect(frame("fold"),Rect2(p-Vector2(66,133),Vector2(132,153)),false)
  # The folding transport has its own paper identity, distinct from realm entrance/exit portals.
  var hub=p-Vector2(0,66)
  for ring in 2:c.draw_arc(hub,25+ring*10,w.clock*(.8 if ring==0 else -.5),w.clock*(.8 if ring==0 else -.5)+TAU*.78,24,Color(.8,.67,.95,.6),2,true)
  var near=false
  for player in w.combat.adventure.points().values():
   if (player as Vector2).distance_to(w.GATES[n])<145:near=true
  if near:label(c,p+Vector2(0,49),"E • FOLD "+("A" if n<2 else "B"),16)
 # Keep posts/ropes outside the navigable deck; cull each bridge before drawing.
 for bridge in data.bridges:
  var first=Vector2(bridge[0][0],bridge[0][1]);var end=Vector2(bridge[1][0],bridge[1][1]);var low=Vector2(bridge[3][0],bridge[3][1]);var low_end=Vector2(bridge[2][0],bridge[2][1])
  if not Rect2(first,low_end-first).grow(80).intersects(Rect2(cam,c.VIEW)):continue
  for pair in [[first,end],[low,low_end]]:
   var a:Vector2=pair[0]-cam;var b:Vector2=pair[1]-cam
   c.draw_line(a+Vector2(0,-26),b+Vector2(0,-26),Color("#9e967d"),3,true)
   for n in 7:
    var p=a.lerp(b,n/6.0);c.draw_line(p,p+Vector2(0,-40),Color("#6c736b"),6,true);c.draw_circle(p+Vector2(0,-40),4,Color("#c1b27d"))
