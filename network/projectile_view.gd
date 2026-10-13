extends RefCounted
## Stable identities and bounded forward presentation. Never applies damage.
var tracks:Dictionary={}
var predicted:Array=[]
func receive(shots:Array,now:float)->void:
 var alive={}
 for shot in shots:
  var key=str(shot.get("net_id",0));alive[key]=true
  var p=Vector2(float(shot.pos[0]),float(shot.pos[1]))
  var v=Vector2(float(shot.velocity[0]),float(shot.velocity[1]))
  tracks[key]={"p":p,"v":v,"t":now,"owner":str(shot.owner),"color":str(shot.get("color","#ffd985"))}
  for n in range(predicted.size()-1,-1,-1):
   if predicted[n].owner==str(shot.owner) and int(predicted[n].seq)==int(shot.get("action_seq",-1)):predicted.remove_at(n)
 for key in tracks.keys():
  if not alive.has(key):tracks.erase(key)
func samples(now:float)->Array:
 var result=[]
 for value in tracks.values():
  # A late packet cannot let a cosmetic shot travel indefinitely through walls.
  result.append({"pos":value.p+value.v*clampf(now-value.t,0,.12),"owner":value.owner,"color":value.color})
 for n in range(predicted.size()-1,-1,-1):
  if now-float(predicted[n].t)>.35:predicted.remove_at(n)
 return result
func preview(owner:String,seq:int,p:Vector2,v:Vector2,tint:String,now:float)->void:
 if predicted.size()<8:predicted.append({"owner":owner,"seq":seq,"p":p,"v":v,"t":now,"color":tint})
func reject(seq:int)->void:predicted=predicted.filter(func(value):return int(value.seq)!=seq)
