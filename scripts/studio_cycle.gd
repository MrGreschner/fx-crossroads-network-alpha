extends RefCounted
## Versioned creation evidence. Readiness describes workflow, never grades or secure authorship.
const COLLECTIONS={"hero":"heroes","ability":"abilities","enemy":"enemies","behavior":"behaviors","object":"objects","realm":"realms"}
const FORMAT="fx-crossroads-creation"
static func fresh()->Dictionary:return {"records":{},"submissions":{},"showcase":{}}
static func check_value(kind:String,value:Variant)->String:
 match kind:
  "hero":return load("res://scripts/workshop_project.gd").validate(value)
  "ability":return load("res://scripts/workshop_project.gd").validate_attack(value)
  "enemy":return load("res://scripts/studio_enemy_project.gd").validate(value)
  "behavior":return load("res://scripts/studio_behavior.gd").validate(value)
  "object","realm":return load("res://scripts/studio_world_project.gd").validate(kind,value)
 return "Unknown creation type."
static func title(kind:String,value:Dictionary)->String:return str(value.hero.name) if kind=="hero" else str(value.get("name","Untitled"))
static func identity(kind:String,value:Dictionary)->String:
 return kind+":"+str(value.get("project_id",value.get("id",value.get("name","Untitled"))))
static func fingerprint(value:Dictionary)->String:
 var v=value.duplicate(true)
 for key in ["revision","reports","tests","notes","created_utc","updated_utc"]:v.erase(key)
 return JSON.stringify(v).sha256_text()
static func short(value:Variant,limit:int)->bool:return value is String and value.length()<=limit
static func valid_entry(e:Variant)->bool:
 if not e is Dictionary:return false
 if not short(e.get("id"),100) or not short(e.get("kind"),12) or not short(e.get("hash"),64) or not short(e.get("author"),40) or not short(e.get("description"),500) or not short(e.get("changes"),500) or not short(e.get("status"),24) or not short(e.get("date"),40):return false
 if not e.get("version") is float and not e.get("version") is int:return false
 if e.version<1 or e.version>100000:return false
 if not check_value(e.kind,e.get("value")).is_empty() or fingerprint(e.value)!=e.hash:return false
 if e.has("tests"):
  if not e.tests is Array or e.tests.size()>8:return false
  for t in e.tests:
   if not t is Dictionary or t.get("hash")!=e.hash or not short(t.get("source"),60) or not short(t.get("date"),40) or not t.get("metrics") is Dictionary or JSON.stringify(t.metrics).length()>5000:return false
 if not e.get("feedback") is Array or e.feedback.size()>12:return false
 for f in e.feedback:
  if not f is Dictionary:return false
  for k in ["reviewer","worked","confused","improve","date"]:
   if not short(f.get(k),500):return false
 return e.status in ["submitted","revision_requested","approved"] and JSON.stringify(e).to_utf8_buffer().size()<=2097152
static func valid(v:Variant)->bool:
 if not v is Dictionary:return false
 for c in ["records","submissions","showcase"]:
  if not v.get(c) is Dictionary or v[c].size()>(200 if c=="records" else 20):return false
 for key in v.records:
  var r=v.records[key]
  if not short(key,160) or not r is Dictionary:return false
  for k in ["kind","title","hash","final_hash","date"]:
   if not short(r.get(k),160):return false
  if not r.get("tests") is Array or r.tests.size()>8:return false
  for t in r.tests:
   if not t is Dictionary or not short(t.get("hash"),64) or not short(t.get("source"),60) or not short(t.get("date"),40) or not t.get("metrics") is Dictionary or JSON.stringify(t.metrics).length()>5000:return false
 for c in ["submissions","showcase"]:
  for id in v[c]:
   if not short(id,100) or not valid_entry(v[c][id]) or id!=v[c][id].id:return false
   if c=="showcase" and v[c][id].status!="approved":return false
 return JSON.stringify(v).to_utf8_buffer().size()<=8388608
static func record(data:Dictionary,kind:String,value:Dictionary,finalized:bool=false)->Dictionary:
 if not data.has("cycle"):data.cycle=fresh()
 var key=identity(kind,value);var hash=fingerprint(value)
 var r:Dictionary=data.cycle.records.get(key,{"kind":kind,"title":title(kind,value),"hash":hash,"final_hash":"","date":"","tests":[]})
 r.hash=hash;r.title=title(kind,value);r.date=Time.get_datetime_string_from_system(true)
 if finalized:r.final_hash=hash
 data.cycle.records[key]=r;return r
static func stored(kind:String,value:Dictionary,finalized:bool=false)->String:
 var issue=check_value(kind,value)
 if not issue.is_empty():return issue
 if finalized and kind=="realm":
  var problems=load("res://scripts/studio_world_project.gd").checks(value)
  if not problems.is_empty():return " • ".join(PackedStringArray(problems))
 var L=load("res://scripts/studio_library.gd");var d=L.load_data();record(d,kind,value,finalized);return L.save_data(d)
static func test(kind:String,value:Dictionary,metrics:Dictionary,source:String="Observed local test")->String:
 var issue=check_value(kind,value)
 if not issue.is_empty():return issue
 if source.begins_with("Observed") and float(metrics.get("seconds",0))<2:return "Run a test for at least two seconds first."
 var L=load("res://scripts/studio_library.gd");var d=L.load_data();var r=record(d,kind,value)
 if JSON.stringify(metrics).length()>5000:return "Test report is too large."
 r.tests.append({"hash":r.hash,"source":source,"date":Time.get_datetime_string_from_system(true),"metrics":metrics.duplicate(true)})
 if r.tests.size()>8:r.tests.pop_front()
 return L.save_data(d)
static func readiness(d:Dictionary,kind:String,value:Dictionary)->Dictionary:
 var r=d.get("cycle",fresh()).records.get(identity(kind,value),{});var hash=fingerprint(value);var tested=false
 for t in r.get("tests",[]):
  if t.hash==hash:tested=true
 var done=not r.is_empty() and r.get("final_hash","")==hash
 var shared=false;var feedback=false;var revised=false
 for e in d.get("cycle",fresh()).submissions.values():
  if identity(e.kind,e.value)!=identity(kind,value):continue
  if e.hash==hash:shared=true;feedback=feedback or not e.feedback.is_empty()
  elif not e.feedback.is_empty():revised=tested and done
 return {"tested":tested,"finalized":done,"ready":tested and done,"shared":shared,"feedback":feedback,"revised":revised,"next":"Finalize this revision" if not done else "Test this revision" if not tested else "Read feedback" if feedback else "Waiting for feedback" if shared else "Share a frozen submission"}
static func submit(kind:String,value:Dictionary,author:String,description:String,changes:String)->Dictionary:
 if load("res://scripts/profile_store.gd").testing():return {"error":"Exit GameDev / Playtest before submitting real work."}
 var issue=check_value(kind,value)
 if not issue.is_empty():return {"error":issue}
 if author.strip_edges().is_empty() or description.strip_edges().is_empty():return {"error":"Add a creator alias and a short description."}
 var L=load("res://scripts/studio_library.gd");var d=L.load_data()
 if not readiness(d,kind,value).ready:return {"error":readiness(d,kind,value).next+" before sharing."}
 var hash=fingerprint(value);var key=identity(kind,value);var version=1
 for old in d.cycle.submissions.values():
  if identity(old.kind,old.value)==key:
   if old.hash==hash:return {"error":"This revision is already submitted.","entry":old}
   version=maxi(version,int(old.version)+1)
 if d.cycle.submissions.size()>=20:return {"error":"20 submission snapshots maximum. Export and remove an older snapshot first."}
 var id=Crypto.new().generate_random_bytes(16).hex_encode()
 var e={"id":id,"kind":kind,"value":value.duplicate(true),"hash":hash,"version":version,"author":author.strip_edges().left(40),"description":description.strip_edges().left(500),"changes":changes.left(500),"status":"submitted","date":Time.get_datetime_string_from_system(true),"feedback":[],"tests":d.cycle.records[key].tests.filter(func(t:Dictionary)->bool:return t.hash==hash).duplicate(true)}
 d.cycle.submissions[id]=e;issue=L.save_data(d);return {"error":issue,"entry":e}
static func accept(packet:Variant)->String:
 if not packet is Dictionary or packet.get("format")!=FORMAT or not valid_entry(packet.get("entry")):return "Choose a valid creation submission / feedback file."
 var L=load("res://scripts/studio_library.gd");var d=L.load_data();var e:Dictionary=packet.entry.duplicate(true)
 if d.cycle.submissions.has(e.id) and d.cycle.submissions[e.id].hash!=e.hash:return "Submission identity conflicts with a different revision."
 if d.cycle.submissions.has(e.id):
  var old:Dictionary=d.cycle.submissions[e.id]
  var combined:Array=old.feedback.duplicate(true)
  for f in e.feedback:
   if not f in combined:combined.append(f)
  while combined.size()>12:combined.pop_front()
  e.feedback=combined
  if e.status=="submitted" and old.status!="submitted":e.status=old.status
 d.cycle.submissions[e.id]=e
 # Importing a submission never publishes it automatically.
 return L.save_data(d)
static func review(id:String,approve:bool,feedback:Dictionary)->String:
 if not load("res://scripts/education_access.gd").review_allowed():return "Teacher access is required for curation."
 var L=load("res://scripts/studio_library.gd");var d=L.load_data()
 if not d.cycle.submissions.has(id):return "Submission not found."
 var e:Dictionary=d.cycle.submissions[id]
 if feedback.get("reviewer","").strip_edges().is_empty() or feedback.get("improve","").strip_edges().is_empty():return "Add your reviewer alias and a next step."
 e.feedback.append(feedback.duplicate(true))
 if e.feedback.size()>12:e.feedback.pop_front()
 e.status="approved" if approve else "revision_requested"
 if approve:d.cycle.showcase[id]=e.duplicate(true)
 else:d.cycle.showcase.erase(id)
 return L.save_data(d)
static func catalog()->Dictionary:
 var L=load("res://scripts/studio_library.gd");var d=L.load_data()
 return {"format":"fx-crossroads-showcase","version":1,"entries":d.cycle.showcase.values()}
static func import_catalog(value:Variant)->String:
 if not value is Dictionary or value.get("format")!="fx-crossroads-showcase" or not value.get("entries") is Array or value.entries.size()>20:return "Invalid Showcase pack."
 var L=load("res://scripts/studio_library.gd");var d=L.load_data()
 for e in value.entries:
  if not valid_entry(e) or e.status!="approved":return "Pack contains an invalid or unapproved entry."
  if d.cycle.showcase.has(e.id) and d.cycle.showcase[e.id].hash!=e.hash:return "Showcase identity conflict."
  d.cycle.showcase[e.id]=e.duplicate(true)
 return L.save_data(d)
static func envelope(e:Dictionary)->Dictionary:return {"format":FORMAT,"version":1,"entry":e}

static func nominate(kind:String,value:Dictionary,alias:String,description:String)->String:
 if not load("res://scripts/education_access.gd").review_allowed():return "Teacher access required."
 var issue=check_value(kind,value)
 if not issue.is_empty():return issue
 var L=load("res://scripts/studio_library.gd");var d=L.load_data();var id="portfolio-"+fingerprint(value).left(24)
 if d.cycle.submissions.has(id):return ""
 d.cycle.submissions[id]={"id":id,"kind":kind,"value":value.duplicate(true),"hash":fingerprint(value),"version":1,"author":alias.left(40),"description":description.left(500),"changes":"Nominated from a frozen class portfolio artifact","status":"submitted","date":Time.get_datetime_string_from_system(true),"feedback":[]}
 return L.save_data(d)
