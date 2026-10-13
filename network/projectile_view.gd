extends RefCounted
## Visual prediction only: hit detection and damage remain on the authority.
var tracks:Dictionary={}
var predicted:Array=[]
var local_owner=""
var latency=0.0
var presentation_ahead=-1.0
func point(value:Dictionary,now:float)->Vector2:
 var elapsed=clampf(now-float(value.t),0,.12)
 return value.p+value.v*elapsed+value.get("offset",Vector2.ZERO)*maxf(0,1-elapsed/float(value.get("blend",.12)))
func receive(shots:Array,now:float)->void:
 var alive={}
 for shot in shots:
  var key=str(shot.get("net_id",0));alive[key]=true
  var p=Vector2(float(shot.pos[0]),float(shot.pos[1]))
  var v=Vector2(float(shot.velocity[0]),float(shot.velocity[1]))
  var owner=str(shot.owner);var seq=int(shot.get("action_seq",-1));var index=int(shot.get("shot_index",0))
  # Own shots are displayed on the same present-time clock as local movement.
  var lead=presentation_ahead if presentation_ahead>=0 else (clampf(latency*.5,0,.15) if owner==local_owner else 0.0)
  p+=v*lead
  var offset=Vector2.ZERO
  if tracks.has(key):offset=point(tracks[key],now)-p
  for n in range(predicted.size()-1,-1,-1):
   var preview=predicted[n]
   if preview.owner==owner and int(preview.seq)==seq and int(preview.index)==index:
    if not tracks.has(key):offset=preview_position(preview,now)-p
    predicted.remove_at(n)
  if offset.length()>120:offset=offset.limit_length(120)
  # Limit correction speed to half projectile speed. A late confirmation must
  # never drag a forward-flying projectile backward along its path.
  var blend=maxf(.12,offset.length()*2/maxf(1,v.length()))
  tracks[key]={"p":p,"v":v,"t":now,"offset":offset,"blend":blend,"owner":owner,"color":str(shot.get("color","#ffd985")),"custom":bool(shot.get("custom",false))}
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
func preview(owner:String,seq:int,p:Vector2,v:Vector2,tint:String,now:float,index:int=0,reach:float=480,radius:float=7)->void:
 if predicted.size()<32:predicted.append({"owner":owner,"seq":seq,"index":index,"p":p,"v":v,"t":now,"color":tint,"range":reach,"radius":radius})
func reject(seq:int)->void:predicted=predicted.filter(func(value):return int(value.seq)!=seq)
