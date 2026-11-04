extends RefCounted
## Shared static presentation. Authored collisions, patches and ice movement are independent.
static var cache:Dictionary={}
static var frames:Dictionary={}
static var manifest:Dictionary={}
static func texture(id:String)->Texture2D:
 if cache.has(id):return cache[id]
 var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes(("res://assets/motion275/" if id in ["ground0","ground1"] else "res://assets/frost264/")+id+".png"));var t=ImageTexture.create_from_image(im);cache[id]=t;return t
static func frame(id:String)->Texture2D:
 if frames.has(id):return frames[id]
 if manifest.is_empty():manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/frost264/manifest.json"))
 var a=manifest.frames[id];var t=AtlasTexture.new();t.atlas=texture("props");t.region=Rect2(a[0],a[1],a[2],a[3]);frames[id]=t;return t
static func prop(c:Node2D,id:String,at:Vector2,size:Vector2,cam:Vector2)->void:
 var r=Rect2(at-size*Vector2(.5,.94)-cam,size)
 if Rect2(Vector2.ZERO,c.VIEW).grow(60).intersects(r):c.draw_texture_rect(frame(id),r,false)
static func pillar(c:Node2D,at:Vector2,cam:Vector2)->void:prop(c,"pillar",at+Vector2(0,14),Vector2(80,118),cam)
static func active(c:Node)->bool:return c.adventure.polish.id=="ice" and not c.adventure.between_guardians()
static func draw(c:Node2D,cam:Vector2)->void:
 if not active(c):return
 c.draw_rect(Rect2(Vector2.ZERO,c.VIEW),Color("#718b9a"))
 for part in [["ground0",Rect2(0,0,3072,1900)],["ground1",Rect2(3072,0,3128,1900)]]:
  var r:Rect2=part[1]
  if r.intersects(Rect2(cam,c.VIEW)):c.draw_texture_rect(texture(part[0]),Rect2(r.position-cam,r.size),false)
 for x in range(160,6200,390):
  for y in [80,1860]:prop(c,"fir",Vector2(x,y),Vector2(155,205),cam)
 for x in range(2700,6150,260):
  for y in [440,1510]:prop(c,"board",Vector2(x,y),Vector2(235,92),cam)
 prop(c,"arch",Vector2(2750,820),Vector2(320,285),cam)
 prop(c,"goal",Vector2(5930,660),Vector2(180,145),cam);prop(c,"goal",Vector2(3060,1390),Vector2(180,145),cam)
 preload("res://scripts/merchant_cart282.gd").draw(c,Vector2(2250,875),cam,false)
 var f=ThemeDB.fallback_font
 for pair in [[Vector2(500,690),"PRACTICE SNOW"],[Vector2(2750,865),"THE FRACTURED RINK"],[Vector2(2250,925),"MERCHANT • E / INTERACT"]]:
  var at:Vector2=pair[0]-cam
  if Rect2(Vector2.ZERO,c.VIEW).grow(100).has_point(at):
   c.draw_string_outline(f,at-Vector2(130,0),pair[1],HORIZONTAL_ALIGNMENT_CENTER,260,16,3,Color("#344953"));c.draw_string(f,at-Vector2(130,0),pair[1],HORIZONTAL_ALIGNMENT_CENTER,260,16,Color("#f0dfb5"))
