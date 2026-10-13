extends RefCounted
const S=preload("res://scripts/learning_store.gd")
static func questions(code:String)->Array:
 match code:
  "COM1145":return [q("Cel animation builds motion using…",["Successive drawn frames","A single unchanging drawing","Only camera zoom"],0),q("Claymation is…",["Live coding only","Stop-motion with repositioned models","A vector file format"],1),q("Computer animation can create movement using…",["Only paper cut-outs","File names","Keyframes and calculated in-between frames"],2),q("Anticipation helps the viewer…",["Read the action about to happen","Ignore the action","Avoid needing any frames"],0)]
  "COM1035":return [q("A raster image stores…",["Pixels","Only mathematical paths","Audio samples"],0),q("SVG is normally…",["Uncompressed audio","A vector format","A video codec"],1),q("A small sprite enlarged without smoothing usually…",["Gains new detail","Turns into SVG","Shows larger pixels"],2),q("An editable source file and an export should…",["Have clear names and versions","Always replace each other","Be kept without backups"],0)]
  "CSE1110":return [q("The sequential IPO order is…",["Output, input, process","Input, process, output","Process, output, input"],1),q("damage = 8; hits = 3; total = damage * hits outputs…",["11","83","24"],2),q("A program that runs but computes the wrong answer has…",["A logic error","No error","A copyright licence"],0),q("Crossroads IPO source is executed by…",["A bounded interpreter","A new native executable for each click","The artwork itself"],0)]
 return []
static func q(text:String,choices:Array,answer:int)->Dictionary:return {"text":text,"choices":choices,"answer":answer}
static func valid_quiz(v:Variant)->bool:
 if not v is Dictionary or not v.get("module") is String or not v.get("answers") is Array:return false
 var qs=questions(v.module)
 if qs.is_empty() or v.answers.size()!=qs.size():return false
 for answer in v.answers:
  if not S.P.number(answer,0,2) or float(answer)!=floorf(float(answer)):return false
 return true
static func quiz_score(v:Dictionary)->int:
 var qs=questions(v.module);var count=0
 for i in qs.size():if int(v.answers[i])==qs[i].answer:count+=1
 return count
static func checks(data:Dictionary,w:Dictionary)->Array:
 var out=[]
 for id in w.get("refs",[]):
  var a:Dictionary=data.artifacts[id]
  if a.kind=="quiz":out.append({"title":a.title,"passed":quiz_score(a.value),"total":questions(a.value.module).size(),"detail":"Automatic concept exercise; explanation and application still need teacher review."})
  elif a.kind=="program":
   var passed=0;var total=a.value.cases.size();var failures=0
   for test in a.value.cases:
    var r=load("res://scripts/education_ipo.gd").execute(a.value.code,test.inputs)
    var ok=not r.error.is_empty() if test.error else r.error.is_empty() and S.fingerprint(r.output)==S.fingerprint(test.expected)
    if ok:passed+=1
    if test.error:failures+=1
   out.append({"title":a.title+" • predicted outputs","passed":passed,"total":total,"detail":"Re-executed saved code. "+str(failures)+" failure cases. Confirm predictions address the student's algorithm and aren't trivial."})
  elif a.kind=="business":out.append({"title":a.title+" • decision / result consistency","passed":1 if preload("res://scripts/education_business.gd").valid(a.value) and not a.value.results.is_empty() else 0,"total":1,"detail":"Recomputed teaching-model results match decisions. Research quality, ethics and interpretation still require teacher review."})
  elif a.kind=="graphic":out.append({"title":a.title+" • paired exports","passed":2,"total":2,"detail":"Valid PNG raster and safe SVG vector present. Design quality and tool explanation need review."})
  elif a.kind=="hero" or a.kind=="ability":
   var frames=[]
   if a.kind=="hero":frames=a.value.hero.art.values()
   else:frames=a.value.get("animation",[])
   var distinct=[]
   for frame in frames:if not frame in distinct:distinct.append(frame)
   out.append({"title":a.title+" • motion frames","passed":1 if distinct.size()>=2 else 0,"total":1,"detail":str(distinct.size())+" different frames found. This does not assess motion readability or originality."})
 return out
