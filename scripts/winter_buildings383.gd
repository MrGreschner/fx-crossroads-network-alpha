extends RefCounted
## Offline-painted winter variants. No snow image processing during gameplay.
const ROOT="res://assets/town_winter383/"
const IDS={
 "shops":["gather","market","fishing","post","mill","barracks","apothecary","tower","hall","office","fellowship","relay","atelier","supply","healer","seedhouse","training","pavilion","wayfinder","bakery","food","arcade","bait","reading"],
 "landmarks":["studio","academy","arena","lodge"],
 "props":["exchange","cave"],
 "mine":["entrance","vent"],
 "street":["gate","lookout","guard_booth","notice","adventure_board","event_stall","tent","bastion_tower","scaffold","bridge_home"],
 "scenery":["well","records","railway"],
 "marina":["bait_stall","fittings"],
 "nature":["flowers","flowers_small","shrub","garden_bed"],
 "cache":["post242"]}
static var atlas:Texture2D
static var frames:Dictionary={}
const EXTERNAL={"marina:fittings":"marina_fittings","cache:post242":"post242"}
static var external_frames:Dictionary={}
static func season(c:CanvasItem)->String:
 var life=c.get("town_life")
 return str(life.calendar.season()) if str(c.get("mode"))=="town" and life!=null else ""
static func has(family:String,id:String)->bool:return id in IDS.get(family,[])
static func prepare()->void:
 if atlas!=null:return
 var image=Image.new()
 if image.load_png_from_buffer(FileAccess.get_file_as_bytes(ROOT+"buildings.png"))!=OK:return
 atlas=ImageTexture.create_from_image(image)
 var info=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"buildings.json"))
 for key in info.frames:
  var a:Array=info.frames[key].region;var frame=AtlasTexture.new();frame.atlas=atlas;frame.region=Rect2(a[0],a[1],a[2],a[3]);frames[key]=frame
static func texture(family:String,id:String,current:String,original:Texture2D)->Texture2D:
 if current!="Winter" or not has(family,id):return original
 var key=family+":"+id
 if EXTERNAL.has(key):
  if not external_frames.has(key):
   var image=Image.new()
   if image.load_png_from_buffer(FileAccess.get_file_as_bytes(ROOT+EXTERNAL[key]+".png"))!=OK:return original
   external_frames[key]=ImageTexture.create_from_image(image)
  return external_frames[key]
 prepare();return frames.get(key,original)
static func canvas_texture(c:CanvasItem,family:String,id:String,original:Texture2D)->Texture2D:
 return texture(family,id,season(c),original)
