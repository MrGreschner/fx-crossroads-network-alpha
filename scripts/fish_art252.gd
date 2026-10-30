extends RefCounted
## Three painted specimens per species; catch IDs preserve appearance without a save migration.
const ROOT="res://assets/fishing252/"
const CACHE_LIMIT=48
static var metadata:Dictionary={}
static var cache:Dictionary={}
static var recent:Array=[]
static func index()->Dictionary:
 if metadata.is_empty():
  var parsed=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"manifest.json"))
  if parsed is Dictionary:metadata=parsed.get("species",{})
 return metadata
static func variation(catch:Dictionary)->int:
 var identity=str(catch.get("catch_id",catch.get("id","")))
 if identity.is_empty():return 0
 var h:int=2166136261
 for b in (str(catch.get("species",""))+":"+identity).to_utf8_buffer():h=((h^b)*16777619)&0xffffffff
 return h%3
static func texture(id:String,variant:int=0)->Texture2D:
 if not index().has(id):return null
 var v=clampi(variant,0,2);var key=id+":"+str(v)
 if cache.has(key):recent.erase(key);recent.append(key);return cache[key]
 var image=Image.new();var code=image.load_png_from_buffer(FileAccess.get_file_as_bytes(ROOT+"sprites/"+id+"_"+str(v)+".png"))
 if code!=OK:return null
 var t=ImageTexture.create_from_image(image)
 while recent.size()>=CACHE_LIMIT:
  var old=recent.pop_front();cache.erase(old)
 cache[key]=t;recent.append(key);return t
static func geometry(id:String,variant:int=0)->Dictionary:
 return index().get(id,{}).get("variants",[])[clampi(variant,0,2)] if index().has(id) else {}
static func legacy_path(path:String)->Texture2D:
 if not path.begins_with("res://assets/fishing/") or not path.ends_with(".svg"):return null
 return texture(path.get_file().get_basename())
static func clear()->void:cache.clear();recent.clear()
