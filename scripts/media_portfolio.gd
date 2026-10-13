extends RefCounted
const MAX_SHOTS=8
static func valid(value:Variant)->bool:
 if not value is Array or value.size()>MAX_SHOTS:return false
 for shot in value:
  if not shot is Dictionary or not shot.has_all(["title","caption","image","time","place"]):return false
  for key in ["title","caption","image","time","place"]:
   if not shot[key] is String:return false
  if shot.title.length()>80 or shot.caption.length()>1200 or shot.place.length()>100 or shot.time.length()>50 or shot.image.length()>140000:return false
  if not preload("res://scripts/studio_audio.gd").base64_ok(shot.image):return false
  var bytes=Marshalls.base64_to_raw(shot.image)
  if not preload("res://scripts/workshop_project.gd").png_error(bytes).is_empty():return false
  var im=Image.new()
  if im.load_png_from_buffer(bytes)!=OK or im.get_width()>320 or im.get_height()>320:return false
 return true
static func add(game:Node,image:Image,title:String,caption:String)->bool:
 if preload("res://scripts/profile_store.gd").testing():return false
 var small=image.duplicate();small.resize(240,maxi(1,int(image.get_height()*240.0/image.get_width())),Image.INTERPOLATE_BILINEAR)
 if small.get_height()>240:small.resize(maxi(1,int(small.get_width()*240.0/small.get_height())),240)
 var shots:Array=game.legacy.data.get("media_portfolio",[]).duplicate(true)
 if shots.size()>=MAX_SHOTS:shots.pop_front()
 shots.append({"title":title.left(80),"caption":caption.left(1200),"image":Marshalls.raw_to_base64(small.save_png_to_buffer()),"time":Time.get_datetime_string_from_system(),"place":str(game.get("realm_id") if game.get("realm_id")!=null else game.get("mode"))})
 if not valid(shots):return false
 game.legacy.data.media_portfolio=shots;game.legacy.save();return true
static func report(shots:Array)->String:
 var text="# Crossroads photography portfolio\n\nExplain choices, audience and revisions. Full-resolution photos are downloaded separately.\n"
 for s in shots:text+="\n## "+str(s.title)+"\n"+str(s.time)+" • "+str(s.place)+"\n\n"+str(s.caption)+"\n"
 return text
