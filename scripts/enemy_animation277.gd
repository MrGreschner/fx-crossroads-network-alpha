extends RefCounted
## Fixed-view four-pose animation. Grounded bodies use drawn steps, never whole-body bounce.
const IDS=["mirror_marquis", "mask_duelist", "prism_acolyte", "lunar_usher", "velvet_dancer", "moonlit_puppeteer", "bloomtail_regent", "petal_ducker", "briar_tail", "nectar_keeper", "silk_spinner", "dewcap_guard", "hourglass_hart", "pendulum_moth", "tick_acorn", "gearhorn_runner", "ratchet_keeper", "spark_scarab", "bellwork_colossus", "hall_monitor", "culture_blob", "lunchline_leviathan", "drone", "star_mine", "void_seeker", "signal_core"]
const FLYERS=["pendulum_moth","drone","star_mine","void_seeker","signal_core"]
static var atlas:Texture2D
static var metadata:Dictionary={}
static var frames:Dictionary={}
static func has(id:String)->bool:return id in IDS
static func prepare()->void:
 if atlas!=null:return
 metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/motion277/actors.json"))
 var im=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/motion277/actors.png"))!=OK:
  push_error("V277 enemy atlas unavailable");return
 atlas=ImageTexture.create_from_image(im)
static func pose_index(pose:String)->int:
 return 3 if pose in ["attack","attack2","special","open"] else 1 if pose in ["walk1","1"] else 2 if pose in ["walk2","2"] else 0
static func texture(id:String,pose:String="idle")->Texture2D:
 if not has(id):return null
 prepare();var n=pose_index(pose);var key=id+":"+str(n)
 if not frames.has(key):
  var t=AtlasTexture.new();t.atlas=atlas;t.region=Rect2(n*80,IDS.find(id)*80,80,80);frames[key]=t
 return frames[key]
static func fitted(id:String,rect:Rect2)->Rect2:
 prepare();var m:Dictionary=metadata[id];var factor=float(m.factor);var growth=rect.size*(factor-1.0)
 rect=Rect2(rect.position-growth*Vector2(.5,.9375),rect.size*factor)
 var b:Array=m.old_normalized;var height=rect.size.y*(float(b[3])-float(b[1]));var foot=rect.position+rect.size*Vector2((float(b[0])+float(b[2]))*.5,float(b[3]))
 var size=Vector2.ONE*80*height/float(m.visible_height)
 return Rect2(foot-size*Vector2(.5,.925),size)
static func selected(id:String,pose:String,distance:float,clock:float)->String:
 if pose_index(pose)==3:return pose
 if id in FLYERS:
  var rate=5.0 if id in ["star_mine","signal_core"] else 10.0
  return ["idle","walk1","idle","walk2"][posmod(int(clock*rate),4)]
 if pose not in ["walk1","walk2","1","2"]:return pose
 var stride=19.0 if id in ["mirror_marquis","bloomtail_regent","hourglass_hart","bellwork_colossus","lunchline_leviathan"] else 12.0
 return ["walk1","idle","walk2","idle"][posmod(int(distance/stride),4)]
static func draw(c:CanvasItem,id:String,pose:String,rect:Rect2,tint:Color=Color.WHITE,foe:Dictionary={})->void:
 var clock=float(c.get("visual_clock")) if c.get("visual_clock")!=null else float(c.get("visual_time")) if c.get("visual_time")!=null else 0.0
 var distance=0.0
 if not foe.is_empty():distance=float(c.enemy_motion229.tracks.get(int(foe.get("uid",0)),{}).get("distance",0.0))
 # School overlays already choose step frames; no synthetic distance when no foe is supplied.
 var chosen=pose if foe.is_empty() and id not in FLYERS else selected(id,pose,distance,clock)
 var box=fitted(id,rect)
 if id in FLYERS:box.position.y-=sin(clock*3.2+float(IDS.find(id))*.7)*1.5
 c.draw_texture_rect(texture(id,chosen),box,false,tint)
