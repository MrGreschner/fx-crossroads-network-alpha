extends RefCounted
## Immediate local presentation only. Remote objects use world_view's server clock.
var tracks:Dictionary={}
var predicted:Array=[]
var local_owner=""
var latency=0.0
func point(value:Dictionary,now:float)->Vector2:
 var elapsed=clampf(now-float(value.t),0,.12)
 if bool(value.get("local_path",false)):elapsed=minf(.12,maxf(0,now-float(value.t)))
 return value.p+value.v*elapsed
func receive(shots:Array,now:float)->void:
 var alive={}
 for shot in shots:
  var key=str(shot.get("net_id",0));alive[key]=true
  var p=Vector2(float(shot.pos[0]),float(shot.pos[1]));var v=Vector2(float(shot.velocity[0]),float(shot.velocity[1]))
  var owner=str(shot.owner);var seq=int(shot.get("action_seq",-1));var index=int(shot.get("shot_index",0))
  var local_path=false
  for n in range(predicted.size()-1,-1,-1):
   var preview=predicted[n]
   if preview.owner==owner and int(preview.seq)==seq and int(preview.index)==index:
    # Prediction ends at confirmation. Cosmetic launch paths cannot override collisions.
    predicted.remove_at(n)
  tracks[key]={"p":p,"v":v,"t":now,"local_path":local_path,"owner":owner,"color":str(shot.get("color","#ffd985")),"custom":bool(shot.get("custom",false)),"art":shot.get("art",{}),"seq":seq}
 for key in tracks.keys():
  if not alive.has(key):tracks.erase(key)
func samples(now:float)->Array:
 var result=[]
 for value in tracks.values():
  if not bool(value.custom):result.append({"pos":point(value,now),"owner":value.owner,"color":value.color})
 for n in range(predicted.size()-1,-1,-1):
  if now-float(predicted[n].t)>.8 or (now-float(predicted[n].t))*predicted[n].v.length()>float(predicted[n].range):predicted.remove_at(n)
 return result
func preview_position(shot:Dictionary,now:float)->Vector2:return shot.p+shot.v*maxf(0,now-float(shot.t))
func preview(owner:String,seq:int,p:Vector2,v:Vector2,tint:String,now:float,index:int=0,reach:float=480,radius:float=7,art:Dictionary={})->void:
 if predicted.size()<32:predicted.append({"owner":owner,"seq":seq,"index":index,"p":p,"v":v,"t":now,"color":tint,"range":reach,"radius":radius,"custom":not art.is_empty(),"art":art})
func reject(seq:int)->void:
 predicted=predicted.filter(func(value):return int(value.seq)!=seq)
 for key in tracks.keys():
  if int(tracks[key].seq)==seq:tracks.erase(key)
