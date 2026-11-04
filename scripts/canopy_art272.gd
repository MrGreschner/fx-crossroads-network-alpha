extends RefCounted
## Environment presentation only; original campaign remains authoritative.
static var textures:Dictionary={}
static var frames:Dictionary={}
static var manifest:Dictionary={}
static var placements:Array=[]
static var visible_props:int=0
static func texture(id:String)->Texture2D:
 if textures.has(id):return textures[id]
 var im=Image.new();var error=im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/canopy272/"+id+".png"))
 if error!=OK:push_error("Canopy artwork unavailable: "+id);return null
 var raw=ImageTexture.create_from_image(im)
 if id.begins_with("ground"):
  var smooth=CanvasTexture.new();smooth.diffuse_texture=raw;smooth.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;textures[id]=smooth
 else:textures[id]=raw
 return textures[id]
static func prepare()->void:
 if not manifest.is_empty():return
 manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/canopy272/manifest.json"));placements=JSON.parse_string(FileAccess.get_file_as_string("res://assets/canopy272/placements.json"))
static func frame(id:String)->Texture2D:
 prepare()
 if not frames.has(id):
  var a:Array=manifest[id].region;var t=AtlasTexture.new();t.atlas=texture("props");t.region=Rect2(a[0],a[1],a[2],a[3]);frames[id]=t
 return frames[id]
static func bounds(at:Vector2,size:Vector2)->Rect2:return Rect2(at-size*Vector2(.5,.9375),size)
static func view(c:Node2D,cam:Vector2)->Rect2:return Rect2(cam,c.get_viewport_rect().size+Vector2(200,200)).grow(160)
static func prop(c:Node2D,id:String,at:Vector2,size:Vector2,cam:Vector2,tint:Color=Color.WHITE)->bool:
 var r=bounds(at,size)
 if not view(c,cam).intersects(r):return false
 c.draw_texture_rect(frame(id),Rect2(r.position-cam,r.size),false,tint);return true
static func cart(c:Node2D,cam:Vector2)->void:
 var at=Vector2(510,4638);prop(c,"cart",at,Vector2(185,175),cam)
 var label=at-cam+Vector2(-105,-177);c.draw_string_outline(ThemeDB.fallback_font,label,"MERCHANT",HORIZONTAL_ALIGNMENT_CENTER,210,15,3,Color("#304638"));c.draw_string(ThemeDB.fallback_font,label,"MERCHANT",HORIZONTAL_ALIGNMENT_CENTER,210,15,Color("#f5e3ba"))
static func garden_at(w:Node,point:Vector2)->bool:
 for floor in w.data.floors:
  if not str(floor.name).is_empty() and w.r(floor.rect).has_point(point):return true
 return false
static func draw(w:Node,c:Node2D,cam:Vector2)->void:
 prepare();var viewport=view(c,cam);visible_props=0;c.draw_rect(Rect2(-cam,Vector2(7800,5900)),Color("#263e35"))
 for n in 4:
  var r=Rect2(Vector2((n%2)*3900,int(n/2)*2950),Vector2(3900,2950))
  if viewport.intersects(r):c.draw_texture_rect(texture("ground"+str(n)),Rect2(r.position-cam,r.size),false)
 var people:Array=w.adventure.points().values()
 for item in placements:
  var id=str(item.kind);var at=Vector2(item.pos[0],item.pos[1]);var size=Vector2(item.size[0],item.size[1]);var r=bounds(at,size)
  if not viewport.intersects(r):continue
  visible_props+=1
  if item.layer=="tree":
   # Trunks below actors; crowns above with a visibility gap near each player.
   c.draw_texture_rect_region(frame(id),Rect2(r.position+Vector2(0,size.y*190/320)-cam,Vector2(size.x,size.y*130/320)),Rect2(0,190,320,130))
  else:
   var tint=Color.WHITE
   if id in ["cottage","atelier","gazebo","root_arch","ribbon_arch","maypole"]:
    for hero in people:
     if r.grow(-20).has_point(hero):tint.a=.4
   if id=="bellflowers":r.position.x+=sin(w.clock*.9+at.x)*1.1
   c.draw_texture_rect(frame(id),Rect2(r.position-cam,r.size),false,tint)
 # Baked bridge planks get sparse carved posts at the original route edges.
 var post_lines=PackedVector2Array();var post_caps=PackedVector2Array()
 for floor in w.data.floors:
  if str(floor.kind) not in ["bridge","log"]:continue
  var r:Rect2=w.r(floor.rect)
  if not viewport.intersects(r):continue
  if r.size.y>r.size.x:
   for yy in range(int(r.position.y)+30,int(r.end.y),180):
    for xx in [r.position.x+9,r.end.x-9]:
     var world_at=Vector2(xx,yy)
     if viewport.has_point(world_at) and not garden_at(w,world_at):
      var at=world_at-cam;post_lines.append(at);post_lines.append(at-Vector2(0,15));post_caps.append(at+Vector2(-3,-15));post_caps.append(at+Vector2(3,-15))
  else:
   for xx in range(int(r.position.x)+30,int(r.end.x),180):
    for yy in [r.position.y+9,r.end.y-9]:
     var world_at=Vector2(xx,yy)
     if viewport.has_point(world_at) and not garden_at(w,world_at):
      var at=world_at-cam;post_lines.append(at);post_lines.append(at-Vector2(0,15));post_caps.append(at+Vector2(-3,-15));post_caps.append(at+Vector2(3,-15))
 if not post_lines.is_empty():c.draw_multiline(post_lines,Color("#786044"),6,true);c.draw_multiline(post_caps,Color("#c4a77b"),4,true)
 for gate in w.data.gates:
  if w.stage>=int(gate.stage):continue
  var r:Rect2=w.r(gate.rect);var q=r.get_center()-cam;c.draw_line(q-Vector2(0,r.size.y*.5),q+Vector2(0,r.size.y*.5),Color(.82,.57,.69,.62),14,true)
  for j in 7:
   var at=q+Vector2(sin(j*1.9)*9,-r.size.y*.43+j*r.size.y*.14);c.draw_circle(at,6,Color("#e9cbd8"));c.draw_circle(at,2,Color("#efdaa7"))
  c.draw_string_outline(ThemeDB.fallback_font,r.position-cam+Vector2(-160,-25),str(gate.name),HORIZONTAL_ALIGNMENT_LEFT,-1,15,3,Color("#304638"));c.draw_string(ThemeDB.fallback_font,r.position-cam+Vector2(-160,-25),str(gate.name),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#f4e5c6"))
 for secret in w.data.secrets:
  var at=w.v(secret.pos)
  if not viewport.has_point(at):continue
  var used=false
  for id in w.adventure.points():
   if w.used.has(str(secret.id)+":"+str(id)):used=true
  c.draw_arc(at-cam,26,0,TAU,24,Color(.79,.86,.65,.17 if used else .65),2,true)
  if not used:c.draw_string_outline(ThemeDB.fallback_font,at-cam+Vector2(-70,45),"E • discovery",HORIZONTAL_ALIGNMENT_LEFT,-1,14,3,Color("#304638"));c.draw_string(ThemeDB.fallback_font,at-cam+Vector2(-70,45),"E • discovery",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#f5e5c3"))
 for house in w.data.houses:
  for side in ["outside","inside"]:
   var at=w.v(house[side])
   if not viewport.has_point(at):continue
   c.draw_arc(at-cam,31,0,TAU,24,Color("#edd9ac"),2,true);c.draw_string_outline(ThemeDB.fallback_font,at-cam+Vector2(-65,48),"E • enter / leave",HORIZONTAL_ALIGNMENT_LEFT,-1,14,3,Color("#304638"));c.draw_string(ThemeDB.fallback_font,at-cam+Vector2(-65,48),"E • enter / leave",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#f5e5c3"))
 for floor in w.data.floors:
  if str(floor.name).is_empty():continue
  var r:Rect2=w.r(floor.rect);var at=r.position+Vector2(28,44)
  if viewport.has_point(at):c.draw_string_outline(ThemeDB.fallback_font,at-cam,str(floor.name),HORIZONTAL_ALIGNMENT_LEFT,-1,18,3,Color("#304638"));c.draw_string(ThemeDB.fallback_font,at-cam,str(floor.name),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#f0dfb6"))
static func overlay(w:Node,c:Node2D,cam:Vector2)->void:
 prepare();var viewport=view(c,cam);var people:Array=w.adventure.points().values()
 for item in placements:
  var id=str(item.kind);var at=Vector2(item.pos[0],item.pos[1]);var size=Vector2(item.size[0],item.size[1]);var r=bounds(at,size)
  if not viewport.intersects(r):continue
  if item.layer=="tree":
   var alpha=.95
   for hero in people:
    if r.grow(24).has_point(hero):alpha=.28
   c.draw_texture_rect_region(frame(id),Rect2(r.position-cam+Vector2(sin(w.clock*.65+at.x)*.7,0),Vector2(size.x,size.y*190/320)),Rect2(0,0,320,190),Color(1,1,1,alpha))
  elif id=="lantern":
   var p=at-cam-Vector2(0,size.y*.55);c.draw_circle(p,3.3+sin(w.clock*2+at.x)*.6,Color(1,.85,.57,.35));c.draw_circle(p,8,Color(1,.78,.4,.05))
  elif id=="butterflies":
   var p=at-cam-Vector2(0,size.y*.64)+Vector2(sin(w.clock*1.3)*10,cos(w.clock*1.7)*5);c.draw_line(p-Vector2(3,2),p+Vector2(3,-2),Color("#e4bfce"),2,true)
 for floor in w.data.floors:
  if str(floor.kind)!="petal":continue
  var r:Rect2=w.r(floor.rect)
  if not viewport.intersects(r):continue
  for j in 10:
   var p=r.position+Vector2(fposmod(j*173+w.clock*12,r.size.x),fposmod(j*97+w.clock*7,r.size.y))-cam;c.draw_line(p,p+Vector2(3,1+sin(w.clock+j)),Color(.94,.72,.81,.4),2,true)
 w.draw_attacks(c,cam)
