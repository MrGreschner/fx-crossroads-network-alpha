extends RefCounted
## Fixed-view four-pose animation. Grounded bodies use drawn steps, never whole-body bounce.
const IDS=["calderax", "cinder_page", "crucible_scuttler", "furnace_sentinel", "ashglass_alchemist", "coalwing_gargoyle", "brandbound_chain", "kiln_slug", "cinderbell_wisp", "gatebreaker_korr", "glass_matron", "pyrewing_bellkeeper", "castellan_varr", "exam_math", "gravel_skater", "spotlight_sovereign", "layercake_golem", "iron_barbell", "exam_english", "exam_history", "exam_science", "eclipse_engine", "rift_weaver", "prism_kite", "comet_urchin", "gravity_husk", "singularity_oracle", "rift_skitter", "silence_regent", "tuning_wraith", "resonance_beetle", "gongbreaker", "last_creditor", "ashen_revenant", "mercy_cantor", "chrysalis_knight", "brood_reliquary", "exalted_wraith"]
const FLYERS=["cinder_page", "coalwing_gargoyle", "brandbound_chain", "cinderbell_wisp", "pyrewing_bellkeeper", "eclipse_engine", "rift_weaver", "prism_kite", "comet_urchin", "singularity_oracle", "silence_regent", "tuning_wraith", "exalted_wraith"]
const ACTIVE_IDLE=["brood_reliquary"]
static var atlas:Texture2D
static var metadata:Dictionary={}
static var frames:Dictionary={}
static func has(id:String)->bool:return id in IDS
static func prepare()->void:
 if atlas!=null:return
 metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/motion279/actors.json"))
 var im=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/motion279/actors.png"))!=OK:
  push_error("V279 enemy atlas unavailable");return
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
 if id in ACTIVE_IDLE:return ["idle","walk1","idle","walk2"][posmod(int(clock*3.0),4)]
 if id in FLYERS:
  var rate=8.0 if id in ["coalwing_gargoyle","pyrewing_bellkeeper","exalted_wraith"] else 5.0
  return ["idle","walk1","idle","walk2"][posmod(int(clock*rate),4)]
 if pose not in ["walk1","walk2","1","2"]:return pose
 var stride=19.0 if id in ["calderax","furnace_sentinel","gatebreaker_korr","glass_matron","castellan_varr","layercake_golem","iron_barbell","gravity_husk","gongbreaker","last_creditor"] else 12.0
 return ["walk1","idle","walk2","idle"][posmod(int(distance/stride),4)]
static func draw(c:CanvasItem,id:String,pose:String,rect:Rect2,tint:Color=Color.WHITE,foe:Dictionary={})->void:
 var clock=float(c.get("visual_clock")) if c.get("visual_clock")!=null else float(c.get("visual_time")) if c.get("visual_time")!=null else 0.0
 var distance=0.0
 var tracker=c.get("enemy_motion229")
 if not foe.is_empty() and tracker!=null:distance=float(tracker.tracks.get(int(foe.get("uid",0)),{}).get("distance",0.0))
 # School overlays already choose step frames; no synthetic distance when no foe is supplied.
 var chosen=pose if foe.is_empty() and id not in FLYERS and id not in ACTIVE_IDLE else selected(id,pose,distance,clock)
 var box=fitted(id,rect)
 if id in FLYERS:box.position.y-=sin(clock*3.2+float(IDS.find(id))*.7)*1.5
 c.draw_texture_rect(texture(id,chosen),box,false,tint)
