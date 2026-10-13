extends RefCounted
## Transparent evidence-based suggestion. Never writes ratings or awards credits.
const S=preload("res://scripts/learning_store.gd")
static func outcome(data:Dictionary,code:String,w:Dictionary,o:Dictionary)->Dictionary:
 if o.get("observation",false):return {"score":-1,"reason":"Teacher observation / discussion; no extra journal required."}
 var ready=S.readiness(data,code,w)[o.id]
 var ratio=1.0 if int(ready.need)==0 else float(ready.count)/int(ready.need)
 var assets:Array=o.get("assets",[])
 var asset_ratio=1.0 if assets.is_empty() else float(assets.size()-ready.missing.size())/assets.size()
 var score=roundi(100*ratio if assets.is_empty() else 60*ratio+40*asset_ratio)
 var reason="Evidence completeness: %d/%d short responses" % [ready.count,ready.need]
 if not assets.is_empty():reason+=" • %d/%d required work types" % [assets.size()-ready.missing.size(),assets.size()]
 if not ready.get("sequence_ok",true):score=mini(score,40);reason+=" • initial vision was not recorded before the work"
 # A complete upload alone cannot establish the quality of the work.
 score=mini(85,score)
 var relevant=[]
 for ref in w.get("refs",[]):
  var a=data.artifacts[ref]
  if a.kind=="quiz" or a.kind=="program":relevant.append(ref)
 if not relevant.is_empty():
  var passed=0;var total=0
  for check in preload("res://scripts/learning_auto.gd").checks(data,{"refs":relevant}):passed+=check.passed;total+=check.total
  if total>0:score=mini(90,roundi(score*.8+20*float(passed)/total));reason+=" • checks %d/%d" % [passed,total]
 return {"score":score,"reason":reason+". Read the work for accuracy, originality and reasoning before accepting a mark."}
static func module(data:Dictionary,code:String,w:Dictionary)->Dictionary:
 var sum=0;var count=0
 for o in S.assessed_outcomes(code):
  var advice=outcome(data,code,w,o);sum+=advice.score;count+=1
 return {"score":roundi(float(sum)/maxi(1,count)),"reason":"Provisional evidence-based suggestion; teacher confirms quality. No marks are saved automatically."}
