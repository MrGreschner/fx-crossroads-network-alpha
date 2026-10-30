extends RefCounted
## Shared matte practice sprites; only new drafts and built-in examples use these defaults.
static var atlas:Texture2D
static var metadata:Dictionary={}
static var frames:Dictionary={}
static var embedded:Dictionary={}
static var props:Dictionary={}
static func prepare()->void:
 if atlas!=null:return
 metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/studio249/manifest.json"))
 var image=Image.new()
 if image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/studio249/studio.png"))!=OK:return
 atlas=ImageTexture.create_from_image(image)
static func texture(id:String,pose:String="idle")->Texture2D:
 prepare()
 if not metadata.has(id):return null
 var n=["idle","walk1","walk2","attack"].find(pose);n=maxi(0,n)
 var key=id+":"+str(n)
 if not frames.has(key):
  var index:int=metadata[id].index;var t=AtlasTexture.new();t.atlas=atlas;t.region=Rect2((index%2*4+n)*80,int(index/2)*80,80,80);frames[key]=t
 return frames[key]
static func encoded(id:String)->Dictionary:
 if embedded.is_empty():embedded=JSON.parse_string(FileAccess.get_file_as_string("res://assets/studio249/templates.json"))
 return embedded.get(id,{}).duplicate(true)
static func prop(id:String)->Texture2D:
 if not props.has(id):
  var image=Image.new()
  if image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/studio249/"+id+".png"))!=OK:return null
  props[id]=ImageTexture.create_from_image(image)
 return props[id]
