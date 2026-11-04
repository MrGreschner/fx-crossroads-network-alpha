extends RefCounted
## Frontal pose drawings, never direction-indexed. Raw PNG loaded once for exports.
const IDS=["sunbeam_cantor","saffron_hopper","frostling","ice_archer","glacier_hound","cryowarden","confluence_heart","glass_mender","sluice_crab","coil_singer","sun_sentinel","sun_sentinel_crown","cartographer","inkfin","foldwing","crease_sentry","burrowfang","shardspitter","fusehare","rootwarden","echo_bat","sap_nurse","flintroot","snow_oracle"]
const FLOATERS=["confluence_heart","glass_mender","sun_sentinel","sun_sentinel_crown","cartographer","inkfin","foldwing","crease_sentry","echo_bat","snow_oracle"]
const HOPPERS=["saffron_hopper","coil_singer","fusehare"]
static var atlas:Texture2D
static var metadata:Dictionary={}
static var frames:Dictionary={}
static func has(id:String)->bool:return id in IDS
static func prepare()->void:
 if atlas!=null:return
 metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/motion275/actors.json"))
 var im=Image.new();var error=im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/motion275/actors.png"))
 if error!=OK:push_error("Enemy animation atlas unavailable");return
 atlas=ImageTexture.create_from_image(im)
static func pose_index(pose:String)->int:
 return 5 if pose=="special" else 4 if pose=="attack2" else 3 if pose in ["attack","open"] else 1 if pose in ["walk1","1"] else 2 if pose in ["walk2","2"] else 0
static func texture(id:String,pose:String="idle")->Texture2D:
 prepare();var n=pose_index(pose);var key=id+":"+str(n)
 if not frames.has(key):
  var t=AtlasTexture.new();t.atlas=atlas;t.region=Rect2(n*80,IDS.find(id)*80,80,80);frames[key]=t
 return frames[key]
static func fitted(id:String,rect:Rect2)->Rect2:
 prepare();var m:Dictionary=metadata[id];var factor=float(m.factor);var growth=rect.size*(factor-1.0)
 rect=Rect2(rect.position-growth*Vector2(.5,.9375),rect.size*factor)
 var b:Array=m.old_normalized;var height=rect.size.y*(float(b[3])-float(b[1]));var foot=rect.position+rect.size*Vector2((float(b[0])+float(b[2]))*.5,float(b[3]))
 var size=Vector2.ONE*80*(height/float(m.visible_height));return Rect2(foot-size*Vector2(.5,.925),size)
static func phase_pose(id:String,pose:String,distance:float)->String:
 if id not in HOPPERS or pose not in ["walk1","walk2"]:return pose
 return "walk1" if fposmod(distance,72.0)/72.0<.24 else "walk2"
static func motion(c:Node,id:String,pose:String,rect:Rect2,distance:float=0.0)->Rect2:
 var clock=float(c.get("visual_clock")) if c.get("visual_clock")!=null else 0.0
 if id in FLOATERS:
  # Floaters hover even when stationary; wings/parts animate independently.
  rect.position.y-=3.0+sin(clock*3.2+float(IDS.find(id))*.7)*2.3
 elif id in HOPPERS and pose in ["walk1","walk2"]:
  var phase=fposmod(distance,72.0)/72.0;var flight=clampf((phase-.24)/.76,0.0,1.0)
  rect.position.y-=sin(flight*PI)*(11.0 if id=="saffron_hopper" else 9.0)
 return rect
