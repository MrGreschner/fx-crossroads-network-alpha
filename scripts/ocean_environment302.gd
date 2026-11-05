extends RefCounted
## Region-exclusive scenery; offshore ruins are visibly submerged and passable.
const Geo=preload("res://scripts/ocean_geometry302.gd")
const Isles=preload("res://scripts/voyage_islands.gd")
static var textures:Dictionary={}
static var frames:Dictionary={}
static var manifest:Dictionary={}
static var placements:Dictionary={}
static var terrain:Dictionary={}
static var effects:Dictionary={}
static var visible_pages=0
static var visible_props=0
static var visible_rocks=0
const PAGE_BUDGET=12
static func prepare()->void:
 if not manifest.is_empty():return
 manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ocean302/manifest.json"))
 placements=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ocean302/placements.json"))
 terrain=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ocean302/pages.json"))
 effects=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ocean302/fx.json"))
static func texture(id:String)->Texture2D:
 if textures.has(id):return textures[id]
 var im=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/ocean302/"+id+".png"))!=OK:return null
 if id.begins_with("water_") or id.begins_with("coast_"):
  var keys=[]
  for key in textures:
   if str(key).begins_with("water_") or str(key).begins_with("coast_"):keys.append(key)
  if keys.size()>=PAGE_BUDGET:textures.erase(keys[0])
 var t=CanvasTexture.new();t.diffuse_texture=ImageTexture.create_from_image(im);t.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;textures[id]=t;return t
static func frame(id:String)->Texture2D:
 prepare()
 if not frames.has(id):
  var r=manifest[id];var b=r.region;var t=AtlasTexture.new();t.atlas=texture(str(r.get("texture","props")));t.region=Rect2(b[0],b[1],b[2],b[3]);frames[id]=t
 return frames[id]
static func fx(id:String)->Texture2D:
 prepare()
 if not frames.has("fx_"+id):
  var b=effects[id];var t=AtlasTexture.new();t.atlas=texture("fx");t.region=Rect2(b[0],b[1],b[2],b[3]);frames["fx_"+id]=t
 return frames["fx_"+id]
static func bounds(p:Dictionary,offset:Vector2=Vector2.ZERO)->Rect2:return Rect2(Vector2(p.pos[0],p.pos[1])+offset-Vector2(p.size[0]*.5,p.size[1]*.94),Vector2(p.size[0],p.size[1]))
static func prop(c:Node2D,cam:Vector2,p:Dictionary,hero:Vector2,offset:Vector2=Vector2.ZERO)->void:
 var r=bounds(p,offset);var alpha=float(p.alpha)
 if not bool(p.flat) and r.grow(20).has_point(hero):alpha*=.27
 c.draw_texture_rect(frame(str(p.kind)),Rect2(r.position-cam,r.size),false,Color(.58,.80,.79,alpha) if bool(p.flat) else Color(1,1,1,alpha));visible_props+=1
static func whirlpools(v:Node,c:Node2D,cam:Vector2,view:Rect2)->void:
 for e in Geo.EDDIES:
  if not view.grow(float(e.r)).has_point(e.p):continue
  var center=Vector2(e.p)-cam;var r=float(e.r)
  # The outer arms describe the current's real radius. No added contact damage.
  for arm in 3:
   var points=PackedVector2Array()
   for n in 48:
    var t=n/47.0;var a=t*TAU*1.35+arm*TAU/3+v.elapsed*.11*float(e.dir);points.append(center+Vector2.from_angle(a)*lerpf(r*.08,r*.94,t))
   c.draw_polyline(points,Color(.46,.73,.75,.14),5,true)
  c.draw_set_transform(center,v.elapsed*.10*float(e.dir))
  c.draw_texture_rect(fx("whirl_cw" if float(e.dir)>0 else "whirl_ccw"),Rect2(-Vector2.ONE*r*.45,Vector2.ONE*r*.9),false,Color(.75,.89,.9,.60))
  c.draw_set_transform(Vector2.ZERO)
static func wave_textures(v:Node,c:Node2D,cam:Vector2,view:Rect2)->void:
 for w in v.surf.waves:
  var center=v.surf.crest(w)
  if not view.grow(float(w.width)).has_point(center):continue
  var t=v.surf.age-float(w.born);var alpha=clampf(t/float(w.lead),0,1)*clampf((float(w.life)+float(w.lead)-t)/1.3,0,1)
  c.draw_set_transform(center-cam,Vector2(w.dir).angle()-PI/2)
  c.draw_texture_rect(fx("storm_crest" if w.large else "breaker_curl"),Rect2(-float(w.width)*.5,-float(w.depth)*.6,float(w.width),float(w.depth)*1.3),false,Color(1,1,1,alpha*.72))
  c.draw_set_transform(Vector2.ZERO)
static func draw(v:Node,c:Node2D,cam:Vector2)->void:
 prepare();Geo.prepare();visible_pages=0;visible_props=0;visible_rocks=0
 var view=Rect2(cam,c.VIEW).grow(170)
 c.draw_rect(Rect2(-cam,v.OCEAN_WORLD),Color("#17394b"))
 for p in terrain.pages:
  var r=Rect2(p.x,p.y,p.w,p.h)
  if view.intersects(r):c.draw_texture_rect(texture(str(p.id)),Rect2(r.position-cam,r.size),false);visible_pages+=1
 if view.intersects(Rect2(430,5600,600,100)):
  c.draw_texture_rect(texture("planks"),Rect2(Vector2(430,5600)-cam,Vector2(600,100)),true,Color(.75,.81,.76))
 for isle in v.islands():
  var p=terrain.islands[str(isle.name)];var r=Rect2(Vector2(isle.p)-Vector2(p.w,p.h)*.5,Vector2(p.w,p.h))
  if view.intersects(r):c.draw_texture_rect(texture(str(p.id)),Rect2(r.position-cam,r.size),false)
 for p in placements.day:
  if bool(p.flat) and view.intersects(bounds(p)):prop(c,cam,p,v.game.position_in_world)
 # Locally bounded wind marks. Size and animation vary with the regional surface.
 var count=0
 for x in range(floori(view.position.x/410)*410,int(view.end.x),410):
  for y in range(floori(view.position.y/350)*350,int(view.end.y),350):
   if count>=32:break
   var seed_value=absi(x*17+y*13);var at=Vector2(x+posmod(seed_value,177),y+posmod(seed_value,139))
   if at.x<Geo.coast_x(at.y)+90 or v.islands().any(func(i):return Isles.contains(i,at)):continue
   var ids=["wind_ripple","shoal_wash","wind_streak","crosscurrent"];var size=Vector2(110+seed_value%140,40+seed_value%42);var drift=Vector2(sin(v.elapsed*.5+x)*8,cos(v.elapsed*.3+y)*3)
   c.draw_texture_rect(fx(ids[posmod(seed_value,4)]),Rect2(at-cam+drift-size*.5,size),false,Color(.8,.92,.91,.18+.08*sin(v.elapsed*.6+seed_value)));count+=1
 whirlpools(v,c,cam,view);v.surf.draw_on(c,cam);wave_textures(v,c,cam,view);v.debris.draw_on(c,cam)
 for rock in v.rocks():
  var r=Rect2(rock.p-Vector2.ONE*(float(rock.r)*1.17+24),Vector2.ONE*(float(rock.r)*1.17+24)*2)
  if not view.intersects(r):continue
  visible_rocks+=1;var outline=PackedVector2Array()
  for p in Geo.footprint(rock):outline.append(p-cam)
  outline.append(outline[0]);c.draw_polyline(outline,Color(.6,.82,.81,.32+.08*sin(v.elapsed+rock.p.x)),5,true)
  var b=Geo.data.rocks[Geo.variant(rock)].region
  c.draw_texture_rect_region(texture("rocks"),Rect2(rock.p-cam-Vector2.ONE*float(rock.r),Vector2.ONE*float(rock.r)*2),Rect2(b[0],b[1],b[2],b[3]))
 for p in placements.day:
  if not bool(p.flat) and view.intersects(bounds(p)):prop(c,cam,p,v.game.position_in_world)
 if v.night():
  var center=v.night_center()
  for p in placements.night:
   if view.intersects(bounds(p,center)):prop(c,cam,p,v.game.position_in_world,center)
 for isle in v.islands():
  var at=Vector2(isle.p)-cam-Vector2(0,Isles.radius(isle,-PI*.5)+35)
  if view.has_point(isle.p):c.draw_string(ThemeDB.fallback_font,at-Vector2(85,0),str(isle.name),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#dedfc3"))
 for cage in v.cages:
  var at=Vector2(cage.pos[0],cage.pos[1])
  if not view.has_point(at):continue
  c.draw_texture_rect(frame("rope_creels"),Rect2(at-cam-Vector2(18,31),Vector2(36,36)),false)
  c.draw_string(ThemeDB.fallback_font,at-cam+Vector2(20,0),"READY" if v.elapsed>=float(cage.ready) else "%ds"%ceili(float(cage.ready)-v.elapsed),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#f7d4a2"))
 if view.has_point(v.HOME):c.draw_string(ThemeDB.fallback_font,v.HOME-cam-Vector2(280,145),"HOME HARBOUR • RETURN HERE",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#f2d296"))
 v.draw_boat(c,cam)
static func draw_chart(v:Node,c:Control,scale_xy:Vector2)->void:
 prepare();Geo.prepare()
 var bank=PackedVector2Array([Vector2.ZERO])
 for p in Geo.data.mainland_edge:bank.append(Vector2(p[0],p[1])*scale_xy)
 bank.append(Vector2(0,20000)*scale_xy);c.draw_colored_polygon(bank,Color("#81977a"))
 for id in v.ocean_charted:
  for p in placements.landmarks:
   if p.id!=id:continue
   var at=Vector2(p.pos[0],p.pos[1])*scale_xy;c.draw_circle(at,3,Color("#a6d7ca"));c.draw_string(ThemeDB.fallback_font,at+Vector2(4,-5),str(p.name),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#b9dacc"))
static func update_discoveries(v:Node)->void:
 prepare()
 for p in placements.landmarks:
  if str(p.id) not in v.ocean_charted and v.boat.distance_to(Vector2(p.pos[0],p.pos[1]))<750:v.ocean_charted.append(str(p.id))
