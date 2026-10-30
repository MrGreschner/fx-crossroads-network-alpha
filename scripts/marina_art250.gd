extends RefCounted
## Static material atlas and precise original dock/boat footprints; no new physics.
const ROOT="res://assets/marina250/"
static var textures:Dictionary={}
static var shore_data:Dictionary={}
static var bank_pages:Dictionary={}
static var white=PackedColorArray([Color.WHITE])
static var square=PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)])
static var shore_draws=0
static var sprite_data:Dictionary={}
static func texture(id:String)->Texture2D:
 if not textures.has(id):
  var im=Image.new()
  if im.load_png_from_buffer(FileAccess.get_file_as_bytes(ROOT+id+".png"))!=OK:return null
  textures[id]=ImageTexture.create_from_image(im)
 return textures[id]
static func cached_page(name:String)->Texture2D:
 if bank_pages.is_empty():bank_pages=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"bank_cache.json")).pages
 return texture(str(bank_pages[name])) if bank_pages.has(name) else null
static func shore(c:Node2D,camera:Vector2)->void:
 if shore_data.is_empty():shore_data=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"shore.json"))
 var view=Rect2(camera,c.VIEW).grow(2);var image=texture("shore")
 for tile in shore_data.tiles:
  var w:Array=tile.world;var r=Rect2(w[0],w[1],w[2],w[3])
  if not view.intersects(r):continue
  var uv:Array=tile.region;c.draw_texture_rect_region(image,Rect2(r.position-camera,r.size),Rect2(uv[0],uv[1],uv[2],uv[3]));shore_draws+=1
static func boat(c:Node2D,id:String,at:Vector2,size:Vector2,angle:float,tint:Color=Color.WHITE)->void:
 if sprite_data.is_empty():sprite_data=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"sprites.json"))
 var info:Dictionary=sprite_data[id];var b:Array=info.bounds;var canvas:Array=info.canvas;var factor=size/Vector2(b[2]-b[0],b[3]-b[1]);var r=Rect2(-size*.5-Vector2(b[0],b[1])*factor,Vector2(canvas[0],canvas[1])*factor)
 var polygon=PackedVector2Array()
 for corner in [r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)]:polygon.append(at+corner.rotated(angle))
 c.draw_polygon(polygon,PackedColorArray([tint]),square,texture(id))
static var static_data:Dictionary={}
static func structure(c:Node2D,id:String,camera:Vector2)->void:
 if static_data.is_empty():static_data=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"static.json"))
 var b:Array=static_data[id];var r=Rect2(b[0],b[1],b[2],b[3])
 if Rect2(camera,c.VIEW).grow(3).intersects(r):c.draw_texture_rect(texture(id),Rect2(r.position-camera,r.size),false)
static func deck(c:Node2D,camera:Vector2)->void:structure(c,"deck",camera)
static func deck_source(c:Node2D,camera:Vector2)->void:
 var view=Rect2(camera,c.VIEW).grow(70)
 if not view.intersects(Rect2(1540,2150,930,620)):return
 var wood=texture("dock_wood");var docks=preload("res://scripts/town_marina.gd")
 for ends in [[Vector2(1740,2360),Vector2(1815,2350)],[Vector2(1920,2340),Vector2(1855,2345)],[Vector2(2155,2340),Vector2(2095,2345)],[Vector2(1850,2610),Vector2(1834,2510)]]:
  c.draw_polyline(PackedVector2Array([ends[0]-camera,(ends[0]+ends[1])*.5-camera+Vector2(0,5),ends[1]-camera]),Color("#bda782"),2,true)
 for r in docks.DECKS:
  var rect=Rect2(r.position-camera,r.size)
  if not view.intersects(r):continue
  c.draw_rect(Rect2(rect.position+Vector2(2,5),rect.size).grow(3),Color("#243a3b",.45))
  # Small bounded regions tile the generated wood without stretching its plank grain.
  for x in range(0,ceili(r.size.x),128):
   for y in range(0,ceili(r.size.y),128):
    var size=Vector2(minf(128,r.size.x-x),minf(128,r.size.y-y));c.draw_texture_rect_region(wood,Rect2(rect.position+Vector2(x,y),size),Rect2(Vector2.ZERO,size))
  c.draw_rect(rect,Color("#665c48"),false,3);c.draw_line(rect.position+Vector2(2,2),rect.position+Vector2(rect.size.x-2,2),Color("#d4b98b"),2)
  for p in [r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)]:
   c.draw_circle(p-camera+Vector2(1,3),6,Color("#544e40"));c.draw_circle(p-camera,4.5,Color("#b39c72"));c.draw_arc(p-camera,3,0,TAU,12,Color("#dac49b"),1,true)
 for at in [Vector2(1654,2236),Vector2(2188,2236)]:lamp(c,at-camera,false,true)
 var sign=Rect2(Vector2(1667,2281)-camera,Vector2(370,39));c.draw_style_box(sign_style(),sign)
 c.draw_string(ThemeDB.fallback_font,sign.position+Vector2(0,17),"RIPPLE & REEL MARINA",HORIZONTAL_ALIGNMENT_CENTER,370,16,Color("#f1dfb1"))
 c.draw_string(ThemeDB.fallback_font,sign.position+Vector2(0,32),"Lake & coastal voyages",HORIZONTAL_ALIGNMENT_CENTER,370,11,Color("#b6d1cc"))
static var plate:StyleBoxFlat
static func sign_style()->StyleBoxFlat:
 if plate==null:
  plate=StyleBoxFlat.new();plate.bg_color=Color("#29464a");plate.border_color=Color("#ab986f");plate.set_border_width_all(1);plate.set_corner_radius_all(3)
 return plate
static func lamp(c:Node2D,point:Vector2,lit:bool,short_post:bool=false)->void:
 var rect=Rect2(point-Vector2(9,37),Vector2(18,50)) if short_post else Rect2(point-Vector2(14,72),Vector2(28,80))
 c.draw_texture_rect(texture("harbor_lamp"),rect,false)
 if lit:c.draw_rect(Rect2(point-Vector2(2,29) if short_post else point-Vector2(3,59),Vector2(4,6) if short_post else Vector2(6,10)),Color("#f8d891"))
