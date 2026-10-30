extends RefCounted
## Presentation only. Shared lazy atlas and retained floor commands; no world-data edits.
static var cache:Dictionary={}
static var frames:Dictionary={}
static var metadata:Dictionary={}
static func texture(id:String)->Texture2D:
 if cache.has(id):return cache[id]
 var image=Image.new()
 if image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/honeyglass255/"+id+".png"))!=OK:return null
 var result=ImageTexture.create_from_image(image);cache[id]=result;return result
static func prop(id:String)->Texture2D:
 if frames.has(id):return frames[id]
 if metadata.is_empty():metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/honeyglass255/manifest.json"))
 if not metadata.frames.has(id):return null
 var b:Array=metadata.frames[id];var t=AtlasTexture.new();t.atlas=texture("props");t.region=Rect2(b[0],b[1],b[2],b[3]);frames[id]=t;return t
static func ground(c:Node2D,w:Node,floor:Dictionary)->void:
 var bounds:Rect2=w.floor_bounds(floor);var kind=str(floor.kind);var name=str(floor.name)
 var points:PackedVector2Array=w.polygon(floor.poly) if floor.has("poly") else PackedVector2Array([bounds.position,Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)])
 var uv=PackedVector2Array()
 for p in points:uv.append(p/(256.0 if kind=="glass" else 128.0))
 c.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
 var tint=Color.WHITE
 if kind=="glass":tint=Color("#fff1d2")
 var tile=texture("glass" if kind=="glass" else "grass") if kind!="trail" else preload("res://scripts/grove_art253.gd").texture("path")
 c.draw_polygon(points,PackedColorArray([tint]),uv,tile)
 # A quiet matte veil retains material detail without competing with attack cues.
 if kind!="trail":
  var tone=Color("#beb089") if kind=="glass" else Color("#7c9569")
  c.draw_colored_polygon(points,Color(tone,.64 if kind=="glass" else .58))
 if floor.has("poly"):
  var closed=points.duplicate();closed.append(points[0])
  c.draw_polyline(closed,Color("#736c50"),12,true)
  c.draw_polyline(closed,Color("#c6b385"),8,true)
  c.draw_polyline(closed,Color("#bad7c5") if kind=="glass" else Color("#8c9c6a"),3,true)
 if kind=="glass" and floor.has("poly"):
  var center=bounds.get_center()
  c.draw_arc(center,93,0,TAU,6,Color(.88,.82,.57,.28),3,true)
  c.draw_arc(center,85,0,TAU,6,Color(.58,.68,.56,.28),2,true)
 if not name.is_empty():
  var at=bounds.position+Vector2(28,40);var font=ThemeDB.fallback_font
  c.draw_string_outline(font,at,name,HORIZONTAL_ALIGNMENT_LEFT,-1,19,3,Color("#394b43"))
  c.draw_string(font,at,name,HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("#f6e7ba"))
