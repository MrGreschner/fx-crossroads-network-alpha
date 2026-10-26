extends RefCounted
## Six poses per hero: idle, two movement, primary, secondary, special.
## Neutral front-facing poses in every travel direction; no sprite flipping.
## No combat, movement, camera or timing changes.
const HEROES=["teapot", "rook", "beaver", "iris", "robot", "cloudloom", "cairnheart", "caelum", "dustdevil", "merrymask","sunflower","snowman","veyra","drum","harbor","magnet","pippa","spindle","patch","bracken","elara","aurel","rune_duelist","garrick","nera","dawnblade","stormscribe","bailiff","tempo","quill","cindervane","tova","dunecook","dustmarshal","wick","cobbleclaw","twisterspell","goalie", "baseball", "golfer", "soccer", "welder", "velvetwing", "gopher", "nullweaver", "kage", "agent", "thistlebond", "chronicle","ram","cat","book","mosaic","vesper","morrow","ferryman"]
const NEW_HEROES=["mosaic","vesper","morrow","ferryman"]
const LATEST=["dawnblade", "stormscribe", "bailiff", "tempo", "quill", "cindervane", "tova", "dunecook", "dustmarshal", "wick", "cobbleclaw", "twisterspell"]
const UPGRADED=["goalie", "baseball", "golfer", "soccer", "welder", "velvetwing", "gopher", "nullweaver", "kage", "agent", "thistlebond", "chronicle", "ferryman", "elder_ram"]
const POLISHED=["sunflower", "snowman", "veyra", "drum", "harbor", "magnet", "pippa", "spindle", "patch", "bracken", "elara", "aurel", "rune_duelist", "garrick", "nera", "twisterspell", "baseball"]
const REFRESHED214=["teapot", "rook", "beaver", "iris", "robot", "cloudloom", "cairnheart", "caelum", "dustdevil", "merrymask"]
const ROOT="res://assets/core204/"
const POSES={"teapot":[0,1,2,3,4,5],"rook":[0,1,2,3,4,5],"beaver":[0,1,2,3,4,5],"iris":[0,1,2,3,4,5],"robot":[0,1,2,3,4,5],"cloudloom":[0,1,2,3,4,5],"cairnheart":[0,1,2,3,4,5],"caelum":[0,1,2,3,4,5],"dustdevil":[0,1,2,3,4,5],"merrymask":[0,1,2,3,4,5],"sunflower":[0,1,2,3,4,5],"snowman":[0,1,2,3,4,5],"veyra":[0,1,2,3,4,5],"drum":[0,1,2,3,4,5],"harbor":[0,1,2,3,4,5],"magnet":[0,1,2,3,4,5],"pippa":[0,1,2,3,4,5],"spindle":[0,1,2,3,4,5],"patch":[0,1,2,3,4,5],"bracken":[0,1,2,3,4,5],"elara":[0,1,2,3,4,5],"aurel":[0,1,2,3,4,5],"rune_duelist":[0,1,2,3,4,5],"garrick":[0,1,2,3,4,5],"nera":[0,1,2,3,4,5],"dawnblade":[0,1,2,3,4,5],"stormscribe":[0,1,2,3,4,5],"bailiff":[0,1,2,3,4,5],"tempo":[0,1,2,3,4,5],"quill":[0,1,2,3,4,5],"cindervane":[0,1,2,3,4,5],"tova":[0,1,2,3,4,5],"dunecook":[0,1,2,3,4,5],"dustmarshal":[0,1,2,3,4,5],"wick":[0,1,2,3,4,5],"cobbleclaw":[0,1,2,3,4,5],"twisterspell":[0,1,2,3,4,5],"ram":[0,1,3,6,7,9],"cat":[0,1,3,6,7,10],"book":[0,2,4,6,7,10],"mosaic":[0,1,2,3,4,5],"vesper":[0,1,2,3,4,5],"morrow":[0,1,2,3,4,5],"ferryman":[0,1,2,3,4,5],"goalie":[0,1,2,3,4,5],"baseball":[0,1,2,3,4,5],"golfer":[0,1,2,3,4,5],"soccer":[0,1,2,3,4,5],"welder":[0,1,2,3,4,5],"velvetwing":[0,1,2,3,4,5],"gopher":[0,1,2,3,4,5],"nullweaver":[0,1,2,3,4,5],"kage":[0,1,2,3,4,5],"agent":[0,1,2,3,4,5],"thistlebond":[0,1,2,3,4,5],"chronicle":[0,1,2,3,4,5],"elder_ram":[0,1,2,3,4,5]}
static var textures:Dictionary={}
var actions:Dictionary={}
static func texture(sprite:String,pose:String="idle")->Texture2D:
 var index=0
 if pose.is_valid_int():index=int(pose)
 else:
  var frames:Array=POSES.get(sprite,[0,1,2,5,5,7])
  var aliases={"idle":frames[0],"0":frames[0],"1":frames[1],"2":frames[2],"walk1":frames[1],"walk2":frames[2],"walk3":frames[1],"walk4":frames[2],"attack":frames[3],"attack2":frames[3],"secondary":frames[4],"spin":frames[4],"open":frames[4],"special":frames[5],"talk":4}
  index=int(aliases.get(pose,0))
 if sprite=="elder_ram" and index>=6:index=1
 var key=sprite+"_"+str(index).pad_zeros(2)
 if not textures.has(key):
  var image=Image.new();var path=("res://assets/hero214/" if sprite in REFRESHED214 else "res://assets/hero212/" if sprite in POLISHED else "res://assets/hero211/" if sprite in LATEST else "res://assets/hero210/" if sprite in UPGRADED else "res://assets/hero208/" if sprite in NEW_HEROES else ROOT)+key+".png"
  if not FileAccess.file_exists(path) or image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK:return null
  textures[key]=ImageTexture.create_from_image(image)
 return textures[key]
func record(id:String,kind:String,sprite:String,interval:float=.35)->void:
 if sprite not in HEROES:return
 var duration=.72 if kind=="special" else .62 if kind=="secondary" else maxf(.24,minf(interval,1.0))
 var strike=minf(.14,maxf(.025,interval*.5))
 actions[id]={"kind":kind,"duration":duration,"strike":strike,"until":Time.get_ticks_msec()+int(duration*1000)}
func packet(id:String)->Dictionary:
 var state:Dictionary=actions.get(id,{})
 if state.is_empty():return {}
 var left=maxi(0,int(state.until)-Time.get_ticks_msec())
 return {"kind":state.kind,"left":left,"duration":state.duration,"strike":state.get("strike",.12)} if left>0 else {}
func receive(id:String,state:Dictionary)->void:
 if state.is_empty():actions.erase(id);return
 actions[id]={"kind":str(state.get("kind","")),"duration":clampf(float(state.get("duration",.24)),.1,1),"strike":clampf(float(state.get("strike",.12)),.025,.14),"until":Time.get_ticks_msec()+clampi(int(state.get("left",0)),0,1000)}
func index_for(id:String,sprite:String,pose:String,point:Vector2,walking:bool,clock:float,channel:bool=false,charging:bool=false)->int:
 var frames:Array=POSES.get(sprite,[0,1,2,5,5,7])
 if sprite=="book" and channel:return int(frames[4])
 if sprite=="ram" and charging:return int(frames[4])
 var state:Dictionary=actions.get(id,{})
 if not state.is_empty() and Time.get_ticks_msec()<int(state.until):
  if state.kind=="special":return int(frames[5])
  if state.kind=="secondary":return int(frames[4])
  var elapsed=float(state.duration)-(int(state.until)-Time.get_ticks_msec())/1000.0
  if elapsed<float(state.get("strike",.12)):return int(frames[3])
  return movement_index(sprite,frames,walking,clock)
 if pose in ["attack","attack2"]:return int(frames[3])
 if pose in ["open","spin","secondary"]:return int(frames[4])
 if pose=="special":return int(frames[5])
 if walking:return movement_index(sprite,frames,walking,clock)
 return int(frames[0])
static func movement_index(sprite:String,frames:Array,walking:bool,clock:float)->int:
 if not walking:return int(frames[0])
 if sprite=="book":return int(frames[1] if sin(clock*3.0)>=0 else frames[2])
 return int(frames[1] if int(clock*7)%2==0 else frames[2])
func picture(id:String,sprite:String,pose:String,point:Vector2,walking:bool,clock:float,channel:bool=false,charging:bool=false)->Texture2D:
 var index=index_for(id,sprite,pose,point,walking,clock,channel,charging)
 return texture(sprite,str(index))
static func body_rect(sprite:String,rect:Rect2,clock:float)->Rect2:
 if sprite=="book":
  var smaller=rect.size*.78
  rect.position+=(rect.size-smaller)*Vector2(.5,1);rect.size=smaller
  rect.position.y-=6.0+sin(clock*3.0)*2.5
 return preload("res://scripts/hero_visual_scale.gd").apply(sprite,rect)
