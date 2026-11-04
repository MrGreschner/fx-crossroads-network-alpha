extends RefCounted
## Crossroads High presentation; school_world retains every collision and encounter.
static var textures:Dictionary={}
static var frames:Dictionary={}
static var manifest:Dictionary={}
static var placements:Array=[]
static var pages:Array=[]
static var signature=""
static var budget=24
const ORIGINAL={"school_desk":"desk","school_board":"chalkboard","school_locker":"lockers","school_bookshelf":"bookshelf","school_counter":"prep_counter","school_oven":"oven","school_curtain":"proscenium","school_weightbench":"weightbench","school_hoop":"hoop","school_bench":"bench"}
static func prepare()->void:
 if not manifest.is_empty():return
 manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/high291/manifest.json"))
 placements=JSON.parse_string(FileAccess.get_file_as_string("res://assets/high291/placements.json"))
 var info=JSON.parse_string(FileAccess.get_file_as_string("res://assets/high291/pages.json"));pages=info.pages;signature=str(info.source_signature)
static func texture(id:String)->Texture2D:
 if textures.has(id):return textures[id]
 var im=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/high291/"+id+".png"))!=OK:return null
 if id.begins_with("ground_"):
  var keys:Array=[]
  for key in textures:
   if str(key).begins_with("ground_"):keys.append(key)
  if keys.size()>=budget:textures.erase(keys[0])
 var t=CanvasTexture.new();t.diffuse_texture=ImageTexture.create_from_image(im);t.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;textures[id]=t;return t
static func frame(id:String)->Texture2D:
 prepare()
 if not frames.has(id):
  var r=manifest[id].region;var t=AtlasTexture.new();t.atlas=texture(str(manifest[id].get("texture","props")));t.region=Rect2(r[0],r[1],r[2],r[3]);frames[id]=t
 return frames[id]
static func view(w:Node,c:Node2D,cam:Vector2)->Rect2:
 var game=w.adventure.game;var factor=float(game.broadcast_scale) if w.adventure.arcade and game.spectating() else float(game.media.factor())
 return Rect2(cam,c.get_viewport_rect().size/maxf(.01,factor)).grow(180)
static func fitted(id:String,r:Rect2)->Rect2:
 var bb=manifest[id].bounds;var scale=r.size/Vector2(bb[2]-bb[0],bb[3]-bb[1])
 var region=manifest[id].region
 return Rect2(r.position-Vector2(bb[0],bb[1])*scale,Vector2(region[2],region[3])*scale)
static func prop(w:Node,c:Node2D,id:String,r:Rect2,cam:Vector2)->void:
 var alpha=1.0
 for hero in w.adventure.points().values():
  if r.grow(20).has_point(hero):alpha=.28
 c.draw_texture_rect(frame(id),fitted(id,Rect2(r.position-cam,r.size)),false,Color(1,1,1,alpha))
static func draw(w:Node,c:Node2D,cam:Vector2)->bool:
 prepare()
 if JSON.stringify(w.data).sha256_text()!=signature:return false
 var visible=view(w,c,cam);c.draw_rect(Rect2(visible.position-cam,visible.size),Color("#35434a"))
 budget=pages.size() if w.adventure.arcade and w.adventure.game.spectating() else 24
 for chunk in w.floor_chunks:chunk.visible=false
 for p in pages:
  var r=Rect2(p.x,p.y,p.w,p.h)
  if visible.intersects(r):c.draw_texture_rect(texture(p.id),Rect2(r.position-cam,r.size),false)
 for room in w.data.rooms:
  var r:Rect2=w.rect(room.rect)
  if not visible.intersects(r):continue
  if str(room.id)=="gym":
   var center=r.get_center()-cam;var line=Color("#e7d7b0")
   c.draw_rect(Rect2(r.position+Vector2(130,200)-cam,r.size-Vector2(260,330)),line,false,3)
   c.draw_arc(center,140,0,TAU,48,line,3);c.draw_line(center-Vector2(r.size.x*.43,0),center+Vector2(r.size.x*.43,0),line,3)
  elif str(room.id)=="drama":
   c.draw_rect(Rect2(r.position+Vector2(150,160)-cam,Vector2(r.size.x-300,330)),Color(.2,.18,.26,.18))
   c.draw_line(r.position+Vector2(150,490)-cam,r.position+Vector2(r.size.x-150,490)-cam,Color("#ae9675"),5)
 for p in w.data.props:
  var size=w.v(p.size);var r=Rect2(w.v(p.pos)-size*Vector2(.5,.7),size)
  if visible.intersects(r):prop(w,c,ORIGINAL[str(p.kind)],r,cam)
 for p in placements:
  var size=w.v(p.size);var r=Rect2(w.v(p.pos)-size*Vector2(.5,.94),size)
  if visible.intersects(r):prop(w,c,str(p.kind),r,cam)
 for room in w.data.rooms:
  if str(room.name).is_empty():continue
  var r:Rect2=w.rect(room.rect);var at=r.position+Vector2(40,95)
  if not visible.has_point(at):continue
  c.draw_string_outline(ThemeDB.fallback_font,at-cam,str(room.name),HORIZONTAL_ALIGNMENT_LEFT,-1,20,3,Color("#35434a"))
  c.draw_string(ThemeDB.fallback_font,at-cam,str(room.name),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#ecdfbd"))
 var at=Vector2(4050,4355)-cam
 if visible.has_point(Vector2(4050,4355)):
  c.draw_string_outline(ThemeDB.fallback_font,at-Vector2(145,0),"CROSSROADS HIGH",HORIZONTAL_ALIGNMENT_LEFT,-1,25,3,Color("#35434a"))
  c.draw_string(ThemeDB.fallback_font,at-Vector2(145,0),"CROSSROADS HIGH",HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("#ecdfbd"))
 return true
static func overlay(w:Node,c:Node2D,cam:Vector2)->void:
 prepare()
 if JSON.stringify(w.data).sha256_text()!=signature:return
 var visible=view(w,c,cam)
 for p in placements:
  var size=w.v(p.size);var at=w.v(p.pos);var r=Rect2(at-size*Vector2(.5,.94),size)
  if not visible.intersects(r):continue
  var alpha=1.0
  for hero in w.adventure.points().values():
   if r.grow(25).has_point(hero):alpha=.15
  var q=at-cam-Vector2(0,size.y*.52)
  if p.kind in ["oven","prep_counter","cakes"]:
   for j in 2:
    var age=fposmod(w.clock*.24+j*.5+at.x*.003,1)
    c.draw_arc(q+Vector2(sin(age*5+j)*7,-age*30),3+age*4,PI*.2,PI*.9,8,Color(.9,.88,.8,(1-age)*.32*alpha),1.5)
  elif p.kind=="chemistry":
   for j in 3:
    var age=fposmod(w.clock*.25+j*.33,1)
    c.draw_circle(q+Vector2(j*7-7,-age*22),2,Color(.62,.83,.7,(1-age)*.6*alpha))
  elif p.kind=="spotlight":
   c.draw_circle(q,12+sin(w.clock*1.2+at.x)*2,Color(.94,.8,.5,.08*alpha))
   c.draw_line(q,q+Vector2(sin(w.clock*.32+at.x)*28,35),Color(.94,.8,.5,.15*alpha),7)
  elif p.kind=="lamp":c.draw_circle(q,18+sin(w.clock*1.4+at.x)*2,Color(.98,.84,.54,.07*alpha))
  elif p.kind=="globe":
   c.draw_arc(q,12,w.clock*.3,w.clock*.3+PI*.6,12,Color(.65,.78,.72,.45*alpha),1.5)
  elif p.kind=="bell":
   c.draw_line(q,q+Vector2(sin(w.clock*.7)*2,20),Color(.76,.65,.45,.5*alpha),2)
