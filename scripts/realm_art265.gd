extends RefCounted
const IDS=["grove","quarry","honeyglass","elementary","sunfield","ice","confluence","folded_coast","moonburrow","moonveil","petalbrook","clockwork_orchard","middle_school"]
const ANCHORS={"grove":Vector2(2100,805),"quarry":Vector2(2100,805),"honeyglass":Vector2(530,3780),"elementary":Vector2(4550,4770),"sunfield":Vector2(1100,5630),"ice":Vector2(2250,875),"confluence":Vector2(480,1320),"folded_coast":Vector2(750,1650),"moonburrow":Vector2(950,1750),"moonveil":Vector2(3340,2650),"petalbrook":Vector2(510,4630),"clockwork_orchard":Vector2(660,1350),"middle_school":Vector2(3450,5570)}
static var cache:Dictionary={}
static var frames:Dictionary={}
static var meta:Dictionary={}
static func texture(id:String)->Texture2D:
 if cache.has(id):return cache[id]
 var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/foundry265/"+id+".png"));var t=ImageTexture.create_from_image(im);cache[id]=t;return t
static func frame(id:String)->Texture2D:
 if frames.has(id):return frames[id]
 if meta.is_empty():meta=JSON.parse_string(FileAccess.get_file_as_string("res://assets/foundry265/manifest.json"))
 var a=meta.frames[id];var t=AtlasTexture.new();t.atlas=texture("props");t.region=Rect2(a[0],a[1],a[2],a[3]);frames[id]=t;return t
static func prop(c:Node2D,id:String,at:Vector2,size:Vector2,cam:Vector2,tint:Color=Color.WHITE)->void:
 var r=Rect2(at-size*Vector2(.5,.92)-cam,size)
 if Rect2(Vector2.ZERO,c.VIEW).grow(80).intersects(r):c.draw_texture_rect(frame(id),r,false,tint)
static func cart(c:Node2D,realm:String,cam:Vector2)->void:
 if realm in ["sunfield","ice"]:return
 if ANCHORS.has(realm):preload("res://scripts/merchant_cart282.gd").draw(c,ANCHORS[realm],cam)
static func foundry(w:Node,c:Node2D,cam:Vector2)->void:
 if not w.active or w.adventure.between_guardians():return
 c.draw_rect(Rect2(Vector2.ZERO,c.VIEW),Color("#143941"))
 for p in [["ground0",Rect2(0,0,2100,2400)],["ground1",Rect2(2100,0,2100,2400)]]:
  var r:Rect2=p[1]
  if r.intersects(Rect2(cam,c.VIEW)):c.draw_texture_rect(texture(p[0]),Rect2(r.position-cam,r.size),false)
 var view=Rect2(cam,c.VIEW).grow(180)
 for at in w.columns():prop(c,"column",at+Vector2(0,28),Vector2(88,136),cam)
 for at in [Vector2(965,550),Vector2(2090,1660),Vector2(4070,1160),Vector2(2120,430)]:
  if not view.has_point(at):continue
  c.draw_line(at-cam-Vector2(0,85),at-cam+Vector2(0,85),Color(.28,.65,.67,.4),26,true)
  for n in 3:
   var q:Vector2=at-cam+Vector2((n-1)*10,-75+fposmod(w.clock*55+n*42,150));c.draw_line(q,q+Vector2(0,20),Color(.65,.83,.78,.35),2,true)
  c.world_transform(at-cam,w.clock*.5);c.draw_texture_rect(frame("wheel"),Rect2(-70,-70,140,140),false);c.world_transform()
 for at in [Vector2(2070,300),Vector2(2070,2120)]:prop(c,"sluice",at,Vector2(145,174),cam)
 var spring=Vector2(2520,430);prop(c,"condenser",spring+Vector2(0,30),Vector2(130,112),cam,Color(.65,.75,.76) if w.spring_used else Color.WHITE)
 c.draw_arc(spring-cam,47,0,TAU,32,Color(.5,.8,.7,.28) if w.spring_used else Color(.6,.9,.83,.6),2,true)
 var closed=not(w.cleared.has(1) and w.cleared.has(2));var b:Rect2=w.barrier()
 if closed:
  c.draw_texture_rect(frame("sluice"),Rect2(b.get_center()-Vector2(48,120)-cam,Vector2(96,240)),false)
  c.draw_string(ThemeDB.fallback_font,b.position-cam+Vector2(-105,-24),"RESTORE BOTH SLUICES",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#f3dba1"))
 else:
  for y in [b.position.y,b.end.y]:c.draw_rect(Rect2(Vector2(b.position.x-12,y-4)-cam,Vector2(60,8)),Color("#a3b69b"))
 var names=["ARRIVAL DOCK","RAINWORK HALL","COPPER CHOIR","CONFLUENCE","THE DIVIDED HEART","HIDDEN CONDENSER"]
 for n in w.ROOMS.size():
  var r:Rect2=w.ROOMS[n]
  if view.intersects(r):c.draw_string(ThemeDB.fallback_font,r.position-cam+Vector2(28,55),names[n],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#d5d3ae"))
 if w.done:
  preload("res://scripts/realm_portals258.gd").draw_at(c,w.adventure.game,w.EXIT,cam);c.draw_string(ThemeDB.fallback_font,w.EXIT-cam+Vector2(-55,-98),"INTERACT: EXIT",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
