extends RefCounted
## CPU-only classification mask used to bake the visible snow/ice pages.
## Shared solo/co-op authority, no independent rectangular slip overlays.
static var mask:Image
static func prepare()->void:
 if mask!=null:return
 mask=Image.new();var error=mask.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/motion275/surface_mask.png"))
 if error!=OK:push_error("Frostbound surface map unavailable")
static func icy(point:Vector2)->bool:
 if point.x<0 or point.y<0 or point.x>=6200 or point.y>=1900:return false
 prepare()
 return mask.get_pixel(int(point.x/2.0),int(point.y/2.0)).r>.5
