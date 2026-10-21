extends RefCounted
const C=preload("res://scripts/waylight_catalog.gd")
static func state(l:Node)->Dictionary:
 var week=l.cosmetics.rankings.week()
 if not l.data.has("named_records"):l.data.named_records={"version":1,"week":week,"times_all":{},"times_week":{},"current":0,"best":0,"current_week":0,"best_week":0,"relic":{}}
 var s:Dictionary=l.data.named_records
 if not s.has("hero_records"):s.hero_records={}
 if str(s.week)!=week:
  s.week=week;s.times_week={};s.current_week=0;s.best_week=0
  for key in s.hero_records.keys():
   if not ":all:" in str(key):s.hero_records.erase(key)
 if not s.has("relic"):s.relic={}
 if not s.has("routes"):s.routes={"solo":{"all":{},"week":{},"week_id":week},"coop":{"all":{},"week":{},"week_id":week}}
 for route in s.routes:
  if s.routes[route].week_id!=week:s.routes[route].week={};s.routes[route].week_id=week
 return s
static func cleared(l:Node,realm:String,seconds:float)->void:
 if preload("res://scripts/profile_store.gd").progression_blocked() or realm not in l.game.manifest.regions or seconds<1:return
 var s=state(l);var route="coop" if l.arcade and l.game.mode=="coop" else "solo";var record=s.routes[route]
 var best=float(record.all.get(realm,86401))
 var kinds=["time","time_"+route]
 for kind in kinds:
  for scope in ["all",str(s.week)]:
   var previous=float((s.times_all if scope=="all" else s.times_week).get(realm,86401)) if kind=="time" else float(record.all.get(realm,86401)) if scope=="all" else float(record.week.get(realm,86401))
   if seconds<=previous:remember_hero(l,kind,scope,realm,seconds,seconds<previous)
 record.all[realm]=minf(best,seconds);record.week[realm]=minf(float(record.week.get(realm,86401)),seconds)
 if seconds<best:preload("res://scripts/record_toast.gd").show(l.game,"NEW PERSONAL BEST • "+route.to_upper()+" • "+realm_name(l,realm)+" • "+preload("res://scripts/named_records_ui.gd").clock(seconds))
 l.community.claims.append({"kind":"time","route":route,"realm":realm,"seconds":seconds});l.community.delay=1
 s.current=mini(1000000,int(s.current)+1);s.current_week=mini(1000000,int(s.current_week)+1);s.best=maxi(s.best,s.current);s.best_week=maxi(s.best_week,s.current_week)
 for key in ["times_all","times_week"]:
  s[key][realm]=minf(float(s[key].get(realm,86400)),seconds)
static func died(l:Node)->void:
 var s=state(l);s.current=0;s.current_week=0
static func payload(l:Node)->Dictionary:
 var s=state(l)
 for item in l.data.get("waylight",{}).get("relics",[]):note_relic(l,item)
 return {"hero_records":s.hero_records,"routes":s.routes,"lifetime":minf(1e12,float(l.data.tasks.get("damage",0))),"buckets":l.crowns.state().buckets,"times":{"all":s.times_all,str(s.week):s.times_week},"streak":{"all":s.best,str(s.week):s.best_week},"relic":s.relic if not s.relic.is_empty() else null}
static func note_relic(l:Node,item:Dictionary)->void:
 var s=state(l);var rare=s.relic;var best=(10 if rare.get("conclave",false) else 0)+int(rare.get("tier",0))+float(rare.get("percentile",0)) if not rare.is_empty() else -1.0
 if not C.valid_relic(item) or str(item.type)=="master_fisher":return
 var bounds=C.RELICS[item.type].range;var percentile=clampf((float(item.value)-float(bounds[0]))/maxf(.01,float(bounds[1])-float(bounds[0])),0,1)
 var score=(10 if item.get("conclave",false) else 0)+int(item.tier)+percentile
 if score>best:s.relic={"type":item.type,"tier":item.tier,"percentile":percentile,"conclave":bool(item.get("conclave",false))}
static func valid(v:Variant)->bool:
 if not v is Dictionary or v.size() not in [8,9,10,11] or v.get("version")!=1 or not v.get("week") is String:return false
 for k in ["current","best","current_week","best_week"]:
  if not preload("res://scripts/competitive_progress.gd").integer(v.get(k),1000000):return false
 if v.has("routes"):
  if not v.routes is Dictionary or v.routes.size()!=2:return false
  for route in ["solo","coop"]:
   if not v.routes.get(route) is Dictionary or v.routes[route].size()!=3 or not v.routes[route].get("week_id") is String:return false
   for scope in ["all","week"]:
    if not v.routes[route].get(scope) is Dictionary or v.routes[route][scope].size()>128:return false
    for id in v.routes[route][scope]:
     if id not in JSON.parse_string(FileAccess.get_file_as_string("res://content/manifest.json")).regions or not C.number(v.routes[route][scope][id],86400) or v.routes[route][scope][id]<1:return false
 if v.has("hero_records") and not valid_hero_records(v.hero_records):return false
 var relic=v.get("relic",{})
 if not relic is Dictionary or relic.size()>4:return false
 if not relic.is_empty():
  if relic.get("type") not in C.RELICS or not C.number(relic.get("percentile"),1) or not preload("res://scripts/competitive_progress.gd").integer(relic.get("tier"),3) or relic.tier<1 or not relic.get("conclave") is bool:return false
 var realms=JSON.parse_string(FileAccess.get_file_as_string("res://content/manifest.json")).regions
 for k in ["times_all","times_week"]:
  if not v.get(k) is Dictionary or v[k].size()>128:return false
  for id in v[k]:
   if id not in realms or not C.number(v[k][id],86400) or v[k][id]<1:return false
 return true

# Store the hero at the moment a matching best result is achieved. Never infer
# old winners from whichever hero happens to be selected at upload time.
static func remember_hero(l:Node,kind:String,scope:String,key:String,value:float,replace:bool)->void:
 var s=state(l);var id=str(l.game.hero_ids.get(l.game.my_id,l.game.selected_hero)) if l.arcade else str(l.game.character_id)
 if id not in l.game.manifest.characters:return
 var record_key=kind+":"+scope+":"+key
 if replace or not s.hero_records.has(record_key):s.hero_records[record_key]={"value":value,"hero":id}
static func valid_hero_records(records:Variant)->bool:
 if not records is Dictionary or records.size()>1024:return false
 var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://content/manifest.json"))
 for key in records:
  if not key is String:return false
  var parts=key.split(":")
  if parts.size()!=3 or parts[0] not in ["time","time_solo","time_coop","between"] or not (parts[1]=="all" or parts[1].length()==10):return false
  if parts[0]=="between":
   if parts[1]!="all" or parts[2] not in ["solo","coop"]:return false
  elif parts[2] not in manifest.regions:return false
  var r=records[key]
  if not r is Dictionary or r.size()!=2 or r.get("hero") not in manifest.characters or not C.number(r.get("value"),1000000 if parts[0]=="between" else 86400):return false
 return true

static func realm_name(l:Node,realm:String)->String:
 if not l.arcade:return str(l.game.realms.get(realm,{}).get("name",realm))
 var spec=JSON.parse_string(FileAccess.get_file_as_string("res://content/regions/"+realm+".json"))
 return str(spec.get("name",realm)) if spec is Dictionary else realm
