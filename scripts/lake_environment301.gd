extends RefCounted
const Geo=preload("res://scripts/lake_geometry301.gd")
static var textures:Dictionary={}
static var frames:Dictionary={}
static var manifest:Dictionary={}
static var placements:Array=[]
static var pages:Array=[]
static var visible_pages=0
static var visible_props=0
static var visible_rocks=0
static var page_budget=12
static func prepare()->void:
 if not manifest.is_empty():return
 manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/lake301/manifest.json"));placements=JSON.parse_string(FileAccess.get_file_as_string("res://assets/lake301/placements.json"));pages=JSON.parse_string(FileAccess.get_file_as_string("res://assets/lake301/pages.json"))
static func texture(id:String)->Texture2D:
 if textures.has(id):return textures[id]
 var im=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/lake301/"+id+".png"))!=OK:return null
 if id.begins_with("ground_"):
  var keys=[]
  for key in textures:
   if str(key).begins_with("ground_"):keys.append(key)
  if keys.size()>=page_budget:textures.erase(keys[0])
 var t=CanvasTexture.new();t.diffuse_texture=ImageTexture.create_from_image(im);t.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;textures[id]=t;return t
static func frame(id:String)->Texture2D:
 prepare()
 if not frames.has(id):
  var r=manifest[id];var box=r.region;var t=AtlasTexture.new();t.atlas=texture(str(r.get("texture","props")));t.region=Rect2(box[0],box[1],box[2],box[3]);frames[id]=t
 return frames[id]
static func bounds(p:Dictionary)->Rect2:return Rect2(Vector2(p.pos[0],p.pos[1])-Vector2(p.size[0]*.5,p.size[1]*.94),Vector2(p.size[0],p.size[1]))
static func prop(c:Node2D,cam:Vector2,p:Dictionary,hero:Vector2)->void:
 var r=bounds(p);var alpha=float(p.alpha)
 if not bool(p.flat) and r.grow(20).has_point(hero):alpha*=.27
 c.draw_texture_rect(frame(str(p.kind)),Rect2(r.position-cam,r.size),false,Color(.78,.89,.83,alpha) if alpha<.6 and p.flat else Color(1,1,1,alpha))
 visible_props+=1
static func draw(v:Node,c:Node2D,cam:Vector2)->void:
 prepare();Geo.prepare();visible_pages=0;visible_props=0;visible_rocks=0
 var view=Rect2(cam,c.VIEW).grow(170)
 page_budget=pages.size() if c.has_method("spectating") and c.spectating() else 12
 c.draw_rect(Rect2(-cam,v.WORLD),Color("#214d5a"))
 for p in pages:
  var r=Rect2(p.x,p.y,p.w,p.h)
  if view.intersects(r):c.draw_texture_rect(texture(p.id),Rect2(r.position-cam,r.size),false);visible_pages+=1
 for p in placements:
  if bool(p.flat) and view.intersects(bounds(p)):prop(c,cam,p,v.game.position_in_world)
 # Sparse wind glints and short current strokes are cosmetic; current_at is untouched.
 var accents=0
 for x in range(floori(view.position.x/260)*260,int(view.end.x),260):
  for y in range(floori(view.position.y/240)*240,int(view.end.y),240):
   if accents>=40:break
   var at=Vector2(x+posmod(x*17+y*13,131),y+posmod(y*11+x*7,113))
   if at.x<Geo.coast_x(at.y)+85 or v.islands().any(func(i):return v.ISLES.contains(i,at)):continue
   var drift=Vector2(sin(v.elapsed*.6+x*.01)*5,cos(v.elapsed*.4+y*.01)*2);var p=at-cam+drift;var flow=v.current_at(at).normalized()
   c.draw_line(p-Vector2(11,1),p+Vector2(13,0),Color(.72,.84,.79,.19),1.3,true)
   if posmod(x+y,3)==0:
    c.draw_line(p-flow*8,p+flow*17,Color(.72,.85,.83,.2),1.5,true)
    c.draw_line(p+flow*17,p+flow*10+flow.orthogonal()*4,Color(.72,.85,.83,.2),1.5,true)
   accents+=1
 var rock_atlas=texture("rocks")
 for rock in v.rocks():
  var r=Rect2(rock.p-Vector2.ONE*(float(rock.r)+24),Vector2.ONE*(float(rock.r)+24)*2)
  if not view.intersects(r):continue
  visible_rocks+=1
  var poly=Geo.footprint(rock);var outline=PackedVector2Array()
  for p in poly:outline.append(p-cam)
  outline.append(outline[0]);c.draw_polyline(outline,Color(.19,.36,.38,.75),12,true)
  c.draw_polyline(outline,Color(.75,.85,.79,.43+.1*sin(v.elapsed*.8+rock.p.x)),3,true)
  var src=Geo.data.rocks[Geo.variant(rock)].region
  c.draw_texture_rect_region(rock_atlas,Rect2(rock.p-cam-Vector2.ONE*float(rock.r),Vector2.ONE*float(rock.r)*2),Rect2(src[0],src[1],src[2],src[3]))
 # Raised scenery has no added invisible colliders and fades beside the hero.
 for p in placements:
  if not bool(p.flat) and view.intersects(bounds(p)):prop(c,cam,p,v.game.position_in_world)
 for isle in v.islands():
  var at:Vector2=isle.p-cam-Vector2(0,Geo.radius(isle,-PI*.5)+45)
  if not Rect2(Vector2.ZERO,c.VIEW).grow(80).has_point(at):continue
  var font=ThemeDB.fallback_font;var name=str(isle.name);var w=font.get_string_size(name,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x
  c.draw_rect(Rect2(at-Vector2(w*.5+10,22),Vector2(w+20,30)),Color(.035,.09,.10,.8));c.draw_string(font,at-Vector2(w*.5,0),name,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#ede1bc"))
 var hp=v.HOME-cam
 if view.grow(300).has_point(v.HOME):c.draw_string(ThemeDB.fallback_font,hp-Vector2(270,145),"HOME HARBOUR • RETURN HERE",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#f2d296"))
 for cage in v.cages:
  var at=Vector2(cage.pos[0],cage.pos[1]);var r=Rect2(at-cam-Vector2(18,31),Vector2(36,36))
  if not view.has_point(at):continue
  c.draw_texture_rect(frame("trap_stack"),r,false);c.draw_line(at-cam,at-cam-Vector2(0,25),Color("#d8d4ba"),2)
  c.draw_string(ThemeDB.fallback_font,at-cam+Vector2(20,0),"READY" if v.elapsed>=float(cage.ready) else "%ds"%ceili(float(cage.ready)-v.elapsed),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#f7d4a2"))
 v.draw_boat(c,cam)
static func draw_chart_bank(c:Control,scale_xy:Vector2)->void:
 Geo.prepare();var p=PackedVector2Array([Vector2.ZERO])
 for a in Geo.data.mainland_edge:p.append(Vector2(a[0],a[1])*scale_xy)
 p.append(Vector2(0,6800)*scale_xy);c.draw_colored_polygon(p,Color("#81977a"))
static func draw_chart_rock(c:Control,rock:Dictionary,scale_xy:Vector2)->void:
 var p=PackedVector2Array()
 for a in Geo.footprint(rock):p.append(a*scale_xy)
 c.draw_colored_polygon(p,Color("#9badac"))
