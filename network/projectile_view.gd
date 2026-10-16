extends RefCounted
## Cosmetic owner prediction. Damage and projectile existence stay authoritative.
const MUZZLE_SECONDS=.14
const PREDICTION_TIMEOUT=.45
const MAX_COAST=.10
var tracks:Dictionary={}
var predicted:Array=[]
var cues:Array=[]
var tombstones:Dictionary={}
var expected:Dictionary={}
var local_owner=""
var latency=0.0
var handoffs=0
var confirmations=0
var last_handoff_error=0.0
var max_handoff_error=0.0
var ended=0
var expired=0
var path_clear:Callable
func reset()->void:
 tracks.clear();predicted.clear();cues.clear();tombstones.clear();expected.clear()
 handoffs=0;confirmations=0;ended=0;expired=0;last_handoff_error=0;max_handoff_error=0
func identity(owner:String,seq:int,index:int)->String:return owner+":"+str(seq)+":"+str(index)
func point(value:Dictionary,now:float)->Vector2:
 var age=clampf(now-float(value.t),0,MAX_COAST)
 var offset:Vector2=value.get("offset",Vector2.ZERO)
 # Bound correction speed: a late confirmation cannot pull a straight shot backwards.
 offset=offset.move_toward(Vector2.ZERO,maxf(80,value.v.length()*.35)*age)
 return value.p+value.v*age+offset
func acknowledge(seq:int,tick:int,indices:Array)->void:
 if indices.is_empty():return
 expected[seq]={"tick":tick,"indices":indices}
 while expected.size()>128:expected.erase(expected.keys()[0])
func receive(shots:Array,now:float,tick:int=-1)->void:
 var alive={};var present={}

 for shot in shots:
  var key=preload("res://network/world_view.gd").shot_key(shot);alive[key]=true
  var owner=str(shot.owner);var seq=int(shot.get("action_seq",-1));var index=int(shot.get("shot_index",0))
  var ident=identity(owner,seq,index);present[ident]=true
  if tombstones.has(ident) and seq>=0:continue
  var p=Vector2(float(shot.pos[0]),float(shot.pos[1]))
  var v=Vector2(float(shot.velocity[0]),float(shot.velocity[1]))
  p+=v*clampf(latency*.5,0,.10)
  var offset=Vector2.ZERO
  if tracks.has(key):offset=point(tracks[key],now)-p
  else:
   confirmations+=1
   for n in range(predicted.size()-1,-1,-1):
    var preview=predicted[n]
    if identity(preview.owner,int(preview.seq),int(preview.index))==ident:
     offset=preview_position(preview,now)-p
     last_handoff_error=offset.length();max_handoff_error=maxf(max_handoff_error,last_handoff_error)
     handoffs+=1;predicted.remove_at(n)
  tracks[key]={"p":p,"v":v,"t":now,"offset":offset.limit_length(220),"owner":owner,"color":str(shot.get("color","#ffd985")),"custom":bool(shot.get("custom",false)),"art":shot.get("art",{}),"seq":seq,"index":index}
 for key in tracks.keys():
  if not alive.has(key):
   var value=tracks[key];tombstones[identity(value.owner,int(value.seq),int(value.index))]=now+2
   tracks.erase(key);ended+=1
 # A shot can hit a wall/player before it ever appears in a snapshot. Reliable
 # birth acknowledgements let that first post-action snapshot end its preview.
 for seq in expected.keys():
  var promise:Dictionary=expected[seq]
  if tick<int(promise.tick):continue
  for n in range(predicted.size()-1,-1,-1):
   var seed=predicted[n];var ident=identity(seed.owner,int(seed.seq),int(seed.index))
   if int(seed.seq)==int(seq) and int(seed.index) in promise.indices and not present.has(ident):
    tombstones[ident]=now+2;predicted.remove_at(n);ended+=1
  expected.erase(seq)
func visuals(now:float)->Array:
 var values:Array=tracks.values()
 for seed in predicted:
  var value:Dictionary=seed.duplicate();value.p=preview_position(seed,now);value.t=now;values.append(value)
 return values
func samples(now:float)->Array:
 for n in range(cues.size()-1,-1,-1):
  if now-float(cues[n].t)>MUZZLE_SECONDS:cues.remove_at(n)
 for key in tombstones.keys():
  if now>float(tombstones[key]):tombstones.erase(key)
 for n in range(predicted.size()-1,-1,-1):
  var seed=predicted[n];var elapsed=maxf(0,now-float(seed.t));var p=preview_position(seed,now)
  if elapsed>PREDICTION_TIMEOUT or seed.p.distance_to(p)>=float(seed.range) or (path_clear.is_valid() and not path_clear.call(seed.p,p)):
   tombstones[identity(seed.owner,int(seed.seq),int(seed.index))]=now+2;predicted.remove_at(n);expired+=1
 var result=[]
 for value in visuals(now):
  if not bool(value.custom):result.append({"pos":point(value,now),"owner":value.owner,"color":value.color})
 return result
func preview_position(shot:Dictionary,now:float)->Vector2:return shot.p+shot.v*clampf(now-float(shot.t),0,PREDICTION_TIMEOUT)
func preview(owner:String,seq:int,p:Vector2,v:Vector2,tint:String,now:float,index:int=0,reach:float=480,radius:float=7,art:Dictionary={})->void:
 if predicted.size()>=32:return
 var seed={"owner":owner,"seq":seq,"index":index,"p":p,"v":v,"t":now,"color":tint,"range":reach,"radius":radius,"custom":not art.is_empty(),"art":art}
 predicted.append(seed);cues.append(seed.duplicate())
func reject(seq:int)->void:
 predicted=predicted.filter(func(value):return int(value.seq)!=seq)
 cues=cues.filter(func(value):return int(value.seq)!=seq)
 for key in tracks.keys():
  if int(tracks[key].seq)==seq:tracks.erase(key)
