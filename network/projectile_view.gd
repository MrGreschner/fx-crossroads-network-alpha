extends RefCounted
## Buffered authoritative shots and short-lived, stationary muzzle cues.
## The Arena supplies positions on world_view's clock, including owned shots.
const MUZZLE_SECONDS=.08
var tracks:Dictionary={}
var predicted:Array=[]
var local_owner=""
var latency=0.0
var handoffs=0
var confirmations=0
var last_handoff_error=0.0
var max_handoff_error=0.0
var ended=0
func point(value:Dictionary,_now:float)->Vector2:
 # These positions already come from the shared server-time interpolation.
 # Never blend a wall-clock preview into this older timeline.
 return value.p
func receive(shots:Array,now:float)->void:
 var alive={}
 for shot in shots:
  var key=preload("res://network/world_view.gd").shot_key(shot);alive[key]=true
  var p:Vector2=shot.get("draw_pos",Vector2(float(shot.pos[0]),float(shot.pos[1])))
  var v=Vector2(float(shot.velocity[0]),float(shot.velocity[1]))
  var owner=str(shot.owner);var seq=int(shot.get("action_seq",-1));var index=int(shot.get("shot_index",0))
  if not tracks.has(key):confirmations+=1
  for n in range(predicted.size()-1,-1,-1):
   var preview=predicted[n]
   if preview.owner==owner and int(preview.seq)==seq and int(preview.index)==index:
    handoffs+=1;predicted.remove_at(n)
  tracks[key]={"p":p,"v":v,"t":now,"owner":owner,"color":str(shot.get("color","#ffd985")),"custom":bool(shot.get("custom",false)),"art":shot.get("art",{}),"seq":seq}
 for key in tracks.keys():
  if not alive.has(key):tracks.erase(key);ended+=1
func samples(now:float)->Array:
 var result=[]
 for value in tracks.values():
  if not bool(value.custom):result.append({"pos":point(value,now),"owner":value.owner,"color":value.color})
 for n in range(predicted.size()-1,-1,-1):
  if now-float(predicted[n].t)>MUZZLE_SECONDS:predicted.remove_at(n)
 return result
func preview_position(shot:Dictionary,_now:float)->Vector2:return shot.p
func preview(owner:String,seq:int,p:Vector2,v:Vector2,tint:String,now:float,index:int=0,reach:float=480,radius:float=7,art:Dictionary={})->void:
 if predicted.size()<32:predicted.append({"owner":owner,"seq":seq,"index":index,"p":p,"v":v,"t":now,"color":tint,"range":reach,"radius":radius,"custom":not art.is_empty(),"art":art})
func reject(seq:int)->void:
 predicted=predicted.filter(func(value):return int(value.seq)!=seq)
 for key in tracks.keys():
  if int(tracks[key].seq)==seq:tracks.erase(key)
