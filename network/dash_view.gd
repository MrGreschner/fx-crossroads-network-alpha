extends RefCounted
## Cosmetic only: at most four fading samples per actor, regardless of FPS.
const LIFE=.18
const INTERVAL=.045
const PER_ACTOR=4
const MAX_RECORDS=32
var emitted=0
var owners:Dictionary={}
var clock=0.0
var records:Array=[]
var tracks:Dictionary={}
func clear()->void:
 clock=0;emitted=0;owners.clear();records.clear();tracks.clear()
func remove(id:String)->void:
 records=records.filter(func(r):return r.owner!=id)
 tracks.erase(id)
func advance(delta:float)->void:
 clock+=maxf(0,delta)
 for n in range(records.size()-1,-1,-1):
  records[n].left-=maxf(0,delta)
  if records[n].left<=0:records.remove_at(n)
func sample(id:String,hero:String,point:Vector2,active:bool,rect:Rect2)->void:
 if not active:
  if tracks.has(id):tracks[id].active=false
  return
 var prior:Dictionary=tracks.get(id,{})
 if not prior.is_empty() and point.distance_to(prior.point)>160:
  remove(id);prior={}
 var due=prior.is_empty() or not bool(prior.get("active",false)) or clock>=float(prior.get("next",0))
 tracks[id]={"point":point,"active":true,"next":clock+INTERVAL if due else prior.next}
 if not due:return
 var count=0
 for n in range(records.size()-1,-1,-1):
  if records[n].owner==id:
   count+=1
   if count>=PER_ACTOR:records.remove_at(n)
 emitted+=1;owners[id]=int(owners.get(id,0))+1
 records.append({"owner":id,"hero":hero,"point":point,"rect":rect,"left":LIFE})
 while records.size()>MAX_RECORDS:records.pop_front()
