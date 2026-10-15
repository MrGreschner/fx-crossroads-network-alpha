extends RefCounted
## Draw-only adapter for the existing protocol-3 effect envelope.
static func identity(effect:Dictionary,clock:float)->String:
 # age and clock advance together on the authority. Birth tick is stable,
 # including when older effects disappear from the array.
 return str(effect.owner)+":"+str(effect.kind)+":"+str(roundi((clock-float(effect.get("age",0)))*60))
static func sample(world:RefCounted,local_owner:String,live:Dictionary)->Dictionary:
 var pair=world.pair()
 if pair.is_empty():return live
 var a:Dictionary=pair[0];var b:Dictionary=pair[1]
 var left:Dictionary=a.data.get("adventure",{}).get("combat",{}).get("twister",{})
 var right:Dictionary=b.data.get("adventure",{}).get("combat",{}).get("twister",{})
 var clock=float(left.get("clock",0))+maxf(0,world.render_time-float(a.t))
 var next={}
 for e in right.get("effects",[]):next[identity(e,float(right.get("clock",0)))]=e
 var effects:Array=[]
 for e in left.get("effects",[]):
  var copy:Dictionary=e.duplicate(true)
  var other:Dictionary=next.get(identity(e,float(left.get("clock",0))),{})
  var elapsed=maxf(0,world.render_time-float(a.t))
  if float(copy.get("time",0))<=elapsed:continue
  if not other.is_empty():
   var p=Vector2(float(e.pos[0]),float(e.pos[1]));var q=Vector2(float(other.pos[0]),float(other.pos[1]))
   if p.distance_to(q)<=160:
    var point=p.lerp(q,world.alpha(a,b));copy.pos=[point.x,point.y]
  copy.age=float(copy.get("age",0))+elapsed;copy.time=float(copy.get("time",0))-elapsed
  effects.append(copy)
 var charges:Dictionary=left.get("charges",{}).duplicate(true)
 charges.erase(local_owner)
 if live.get("charges",{}).has(local_owner):charges[local_owner]=live.charges[local_owner].duplicate(true)
 return {"effects":effects,"charges":charges,"links":left.get("links",[]),"clock":clock}
