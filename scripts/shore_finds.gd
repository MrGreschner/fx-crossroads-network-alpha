extends RefCounted

const C=preload("res://scripts/fishing_catalog.gd")
static var catalogue:Dictionary={}
static var sprites:Dictionary={}

static func roll(pool:String,rng:RandomNumberGenerator)->Dictionary:
 if catalogue.is_empty():catalogue=JSON.parse_string(FileAccess.get_file_as_string("res://content/shore_finds.json"))
 var region:=str(C.pools().get(pool,{}).get("region",""))
 var key:=region
 if pool in ["town_river","town_marina"] or region=="voyage_lake":key="shared"
 elif pool in ["town_pond","town_dawn","voyage_night_crater"] or region=="between_remote":key=pool
 elif region.begins_with("descent"):key="descent"
 var items:Array=catalogue.get(key,[])
 var count:=4 if key=="shared" and region!="voyage_lake" else items.size()
 if count==0:return {}
 return items[rng.randi_range(0,count-1)]

static func texture(path:String)->Texture2D:
 if not sprites.has(path):
  var image:=Image.new()
  if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK:return null
  sprites[path]=ImageTexture.create_from_image(image)
 return sprites[path]
