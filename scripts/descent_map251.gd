extends RefCounted
## Three small cached floor materials, static culled wall trim and unchanged pillars.
static var textures:Dictionary={}
static var frames:Dictionary={}
static func texture(id:String)->Texture2D:
 if not textures.has(id):
  var image=Image.new()
  if image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/descent251/"+id+".png"))!=OK:return null
  textures[id]=ImageTexture.create_from_image(image)
 return textures[id]
static func floor_id(depth:int)->String:return "lava_floor" if depth>100 else "deep_floor" if depth>=45 else "cave_floor"
static func floor_texture(depth:int)->Texture2D:return texture(floor_id(depth))
static func draw_floor(c:Node2D,camera:Vector2,view:Vector2,depth:int)->void:
 var t=floor_texture(depth)
 if t==null:return
 # At most 7x5 quads at 1280x720; no per-frame pixel generation or render target.
 for x in range(floori(camera.x/256),ceili((camera.x+view.x)/256)):
  for y in range(floori(camera.y/256),ceili((camera.y+view.y)/256)):
   c.draw_texture_rect(t,Rect2(Vector2(x,y)*256-camera,Vector2.ONE*256),false)
static func scenery(c:Node2D,camera:Vector2,field:Rect2,view:Vector2,depth:int)->void:
 var side=texture("cave_wall_side");var wall=texture("cave_wall");var bounds=Rect2(camera,view).grow(180);var tint=Color("#b6bcc0") if depth>=45 else Color.WHITE
 for x in range(0,int(field.size.x),150):
  for y in [20,field.size.y-20]:
   var at=Vector2(x+75,y)
   if bounds.has_point(at):c.draw_texture_rect(wall,Rect2(at-Vector2(92,50)-camera,Vector2(184,100)),false,tint)
 for y in range(130,int(field.size.y)-100,140):
  for x in [20,field.size.x-20]:
   var at=Vector2(x,y)
   if bounds.has_point(at):c.draw_texture_rect(side,Rect2(at-Vector2(48,70)-camera,Vector2(96,140)),false,tint)
static func pillar(c:Node2D,at:Vector2,radius:float,camera:Vector2)->void:
 var tex=texture("cave_pillar");var size=Vector2(radius*2+8,radius*2+8)
 c.draw_texture_rect(tex,Rect2(at-size*.5-camera,size),false)
static func enemy(c:CanvasItem,e:Dictionary,alpha:float)->bool:
 var id=str(e.get("kind",""))
 if id not in ["ds_wickcaller","ds_gloamrunner","ds_craglobber","ds_riftskulk","ds_mirebound"]:return false
 var atlas=texture("enemies")
 if atlas==null:return false
 var index=["ds_wickcaller","ds_gloamrunner","ds_craglobber","ds_riftskulk","ds_mirebound"].find(id);var pose=preload("res://scripts/cast_art232.gd").cave_pose(e);var tkey=id+str(pose)
 if not frames.has(tkey):
  var frame=AtlasTexture.new();frame.atlas=atlas;frame.region=Rect2(pose*80,index*80,80,80);frames[tkey]=frame
 var size=Vector2.ONE*80*float(e.get("art_scale",1));var tint=Color(1,1,1,alpha)
 if float(e.get("hurt",0))>0:tint=Color(1,.7,.65,alpha)
 c.draw_texture_rect(frames[tkey],Rect2(e.pos-size*Vector2(.5,.92),size),false,tint);return true
