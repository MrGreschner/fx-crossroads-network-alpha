extends RefCounted
const C=preload("res://scripts/waylight_catalog.gd")
const STORE=preload("res://scripts/profile_store.gd")
var ref:WeakRef
var legacy:Node:
 get:return ref.get_ref() if ref!=null else null
 set(value):ref=weakref(value)
static func fresh()->Dictionary:return {"version":1,"shards":0,"dust":0,"attuned":false,"expeditions":0,"best_extraction":0,"best_ring":0,"relics":[],"equipped":["",""],"pity":{},"run":{},"settled":[],"fisher_claimed":false,"fair":false,"last":""}
func state()->Dictionary:
 if not legacy.data.has("waylight"):legacy.data["waylight"]=fresh()
 if not legacy.data.waylight.has("best_extraction"):legacy.data.waylight.best_extraction=0
 return legacy.data.waylight
func blocked()->bool:return bool(legacy.data.get("teacher",false)) or STORE.progression_blocked()
func save()->void:legacy.save()
func item(id:String)->Dictionary:
 for v in state().relics:
  if str(v.id)==id:return v
 return {}
func prerequisites()->Array:return [between_unlocked()]
func between_unlocked()->bool:
 return blocked() or preload("res://scripts/realm_access.gd").count(legacy,preload("res://scripts/realm_access.gd").INTRO_MODERATE)>=1
func entry_issue(kind:String)->String:
 if blocked():return ""
 if kind in ["between","attunement"] and not between_unlocked():return "Clear Sunfield Expanse or Frostbound Rink to unlock The Between."
 if kind=="overcharge" and not state().attuned:return "Complete Portal Attunement in The Between to unlock Overcharged Realms."
 return ""
func can_attune()->bool:return between_unlocked()
func equip(id:String,slot:int)->bool:
 if slot<0 or slot>1 or item(id).is_empty():return false
 var type=str(item(id).type)
 for n in 2:
  var other=item(str(state().equipped[n]))
  if not other.is_empty() and str(other.type)==type:state().equipped[n]=""
 state().equipped[slot]=id;save();return true
func salvage(id:String)->String:
 for v in state().relics:
  if str(v.id)!=id:continue
  for n in 2:
   if str(state().equipped[n])==id:state().equipped[n]=""
  state().relics.erase(v);state().dust=mini(1000000,int(state().dust)+2+int(v.rank));save();return "Relic salvaged into Waydust."
 return "Relic no longer available."
func upgrade(id:String)->String:
 var v=item(id)
 if v.is_empty() or int(v.rank)>=3:return "Relic is unavailable or already rank 3."
 var rank=int(v.rank)+1;var shards=rank*10;var dust=rank*2
 if int(state().shards)<shards or int(state().dust)<dust:return "Need %d shards and %d Waydust." % [shards,dust]
 state().shards-=shards;state().dust-=dust;v.rank=rank;save();return "Relic upgraded to rank "+str(rank)+"."
func reroll(id:String,rng:RandomNumberGenerator)->String:
 var v=item(id)
 if v.is_empty():return "Relic unavailable."
 if int(state().shards)<8 or int(state().dust)<1:return "Need 8 shards and 1 Waydust."
 state().shards-=8;state().dust-=1;v.roll=rng.randi_range(1,4);save();return "Supporting stat rerolled. Main effect and upgrades retained."
func fisher_ready()->bool:
 var f=legacy.fishing_records
 return f.progress.level()>=40 and f.state().journal.size()>=15 and not state().fisher_claimed
func fisher_claim()->String:
 if not fisher_ready():return "Requires fishing level 40 and 15 discovered species."
 if state().relics.size()>=60:return "Make room in your relic collection first."
 state().relics.append({"id":"master-fisher-covenant","type":"master_fisher","value":12,"rank":0,"stat":"vitality","roll":2,"tier":1,"source":"fishing"});state().fisher_claimed=true;save();return "Earned Riverkeeper's Covenant. Equip it in a relic slot."
func pay_ticket(kind:String,realm:String,tier:int,seed_value:int,day:int)->String:
 if not state().run.is_empty():return "Resume or forfeit your existing expedition first."
 var gate=entry_issue(kind)
 if not gate.is_empty():return gate
 if kind=="overcharge":
  if tier<1 or tier>3 or realm!=C.featured(day):return "The daily overcharge has changed. Reopen the portal."
  if not preload("res://scripts/realm_access.gd").unlocked(legacy,realm):return preload("res://scripts/realm_access.gd").reason(legacy,realm)
  if tier>1 and (not state().attuned or int(state().best_ring)<(tier-1)*3):return "Higher tiers require attunement and deeper successful expeditions."
  if int(state().shards)<C.COSTS[tier-1]:return "Gather more Waylight Shards in the Between."
  state().shards-=C.COSTS[tier-1]
 elif kind not in ["between","attunement"]:return "Unknown expedition."
 if kind=="attunement" and not can_attune():return "Clear Sunfield Expanse or Frostbound Rink first."
 state()["run"]={"id":"w%d-%d" % [seed_value,Time.get_ticks_usec()],"kind":kind,"realm":realm,"tier":tier,"seed":seed_value,"day":day,"eligible":bool(state().attuned),"layout_version":3,"depth":preload("res://scripts/between_access.gd").depth(legacy),"hero":legacy.game.selected_character,"checkpoint":{}}
 if kind=="attunement":state().run["trial_version"]=2
 save();return ""
func settle(won:bool,carried:int,ring:int,guardian:bool,events:int,trial:Dictionary={})->String:
 var ticket:Dictionary=state().run
 if ticket.is_empty() or str(ticket.id) in state().settled:return "This run has already been settled."
 if blocked():state().run={};return "Game Dev / practice expedition: no saved shards, relics or attunement."
 var text=""
 if ticket.kind in ["between","attunement"]:
  var complete=won and ticket.kind=="attunement" and int(ticket.get("trial_version",0))==2 and int(trial.get("seals",0))==6
  var bonus=trial_bonus(carried,float(trial.get("seconds",0))) if complete else 0
  var earned=(carried if won else floori(carried*.5))+bonus;state().shards=mini(1000000,int(state().shards)+earned)
  if won:state().best_ring=maxi(int(state().best_ring),ring);state().best_extraction=maxi(int(state().best_extraction),carried)
  if won and carried>=20:state().expeditions=mini(1000000,int(state().expeditions)+1)
  text="Banked %d Waylight Shards%s." % [earned,"" if won else " (half of your haul)"]
  if complete:
   var first=not bool(state().attuned);state().attuned=true
   text+=" PORTAL ATTUNEMENT COMPLETE — relic drops unlocked!" if first else " Crossing Seals restored."
   text+=" +%d trial bonus shards (capped at 60)." % bonus
  elif ticket.kind=="attunement":text+=" Trial incomplete: extract with all six Crossing Seals in a solo challenge. No trial bonus."
 elif won:
  state().dust=mini(1000000,int(state().dust)+1+events)
  if bool(ticket.eligible):
   var misses=int(state().pity.get(ticket.realm,0));var rng=RandomNumberGenerator.new();rng.seed=int(ticket.seed)^791901
   if misses>=9 or rng.randf()<C.CHANCES[int(ticket.tier)-1]:
    var relic=C.roll(str(ticket.realm),int(ticket.tier),int(ticket.seed))
    if state().relics.size()<60:state().relics.append(relic);text="RELIC FOUND: "+str(C.RELICS[relic.type].name)+"!"
    else:state().dust=mini(1000000,int(state().dust)+8);text="Relic found; collection full, converted to 8 bonus Waydust."
    state().pity[ticket.realm]=0
   else:state().pity[ticket.realm]=misses+1;text="No relic this time. Attunement: %d / 10 clears toward a guaranteed drop." % (misses+1)
  else:text="Overcharge cleared. Complete Portal Attunement to become eligible for relic drops."
  text+=" +%d Waydust." % (1+events)
  if bool(trial.get("conclave",false)):
   state().dust=mini(1000000,int(state().dust)+3);text+=" CONCLAVE CACHE: +3 Waydust."
   var cache_rng=RandomNumberGenerator.new();cache_rng.seed=int(ticket.seed)^351771
   if bool(ticket.eligible) and cache_rng.randf()<.35:
    var extra=C.conclave_roll(str(ticket.realm),int(ticket.tier),int(ticket.seed))
    if state().relics.size()<60:state().relics.append(extra);text+=" BONUS RELIC: "+C.display_name(extra)+"!"
    else:state().dust=mini(1000000,int(state().dust)+8);text+=" Bonus relic converted to 8 Waydust; collection full."
 else:text="Overcharge attempt ended. A new attempt requires shards."
 state().settled.append(str(ticket.id))
 if state().settled.size()>100:state().settled.pop_front()
 state().run={};state().last=text;save();return text
static func trial_bonus(carried:int,seconds:float)->int:
 # Higher pace helps, but never doubles an unlimited farm. Every complete run earns a bonus.
 var rate=.60 if seconds<=600 else .40 if seconds<=900 else .25
 return mini(60,floori(maxi(0,carried)*rate))
static func valid(v:Variant)->bool:
 if not v is Dictionary or int(v.get("version",0))!=1:return false
 for key in ["shards","dust","expeditions","best_ring"]:
  if not C.number(v.get(key),1000000):return false
 if v.has("best_extraction") and not C.number(v.best_extraction,1000000):return false
 for key in ["attuned","fisher_claimed","fair"]:
  if not v.get(key) is bool:return false
 if not v.get("last",null) is String or v.last.length()>1000:return false
 if not v.get("relics") is Array or v.relics.size()>60 or not v.get("equipped") is Array or v.equipped.size()!=2:return false
 var ids=[];var types=[]
 for item in v.relics:
  if not C.valid_relic(item) or item.id in ids:return false
  ids.append(item.id)
 for id in v.equipped:
  if not id is String:return false
  if id=="":continue
  if id not in ids:return false
  var type=""
  for item in v.relics:
   if item.id==id:type=str(item.type)
  if type in types:return false
  types.append(type)
 if not v.get("pity") is Dictionary or v.pity.size()>C.ROTATION.size():return false
 for realm in v.pity:
  if realm not in C.ROTATION or not C.number(v.pity[realm],9):return false
 if not v.get("settled") is Array or v.settled.size()>100:return false
 for id in v.settled:
  if not id is String or id.length()>80:return false
 if not v.get("run") is Dictionary:return false
 var run:Dictionary=v.run
 if not run.is_empty():
  if run.get("kind","") not in ["between","attunement","overcharge"] or not run.get("eligible") is bool:return false
  if not run.get("id") is String or run.id.length()>80 or not run.get("hero") is String or run.hero.length()>64:return false
  if run.has("trial_version") and (run.kind!="attunement" or run.trial_version!=2 or run.has("coop")):return false
  if run.has("depth") and (not C.number(run.depth,14) or float(run.depth)!=floorf(float(run.depth)) or int(run.depth) not in [6,8,10,12,14]):return false
  if run.has("layout_version") and (not C.number(run.layout_version,3) or float(run.layout_version)!=floorf(float(run.layout_version)) or int(run.layout_version)<1):return false
  for key in ["seed","day","tier"]:
   if not C.number(run.get(key),2147483647):return false
  if int(run.tier)<1 or int(run.tier)>3:return false
  if run.kind=="overcharge" and run.get("realm","") not in C.ROTATION:return false
  if run.kind!="overcharge" and run.get("realm","")!="between":return false
  if not run.get("checkpoint") is Dictionary or not bounded(run.checkpoint):return false
  if not run.checkpoint.is_empty() and not valid_checkpoint(run.checkpoint,str(run.kind)):return false
  if run.has("coop"):
   var n=run.coop
   if not n is Dictionary or not run.checkpoint.is_empty():return false
   for key in ["reservation","room","token","endpoint"]:
    if not n.get(key) is String or n[key].is_empty() or n[key].length()>(512 if key=="endpoint" else 80):return false
   if n.has("conclave") and not n.conclave is bool:return false
   if not n.get("started") is bool or not n.get("guardian") is bool:return false
   for key in ["world_seed","cost","carried","farthest","events"]:
    if not C.number(n.get(key),2147483647) or float(n[key])!=floorf(float(n[key])):return false
   if n.farthest>14 or n.events>2 or int(n.cost) not in [0,100,200,300] or n.carried>100000:return false
  if str(run.id) in v.settled:return false
 return true
static func bounded(v:Variant,depth:int=0)->bool:
 if depth>16:return false
 if v==null or v is bool:return true
 if v is int or v is float:return is_finite(float(v)) and absf(float(v))<=1e12
 if v is String:return v.length()<=1000
 if v is Array:
  if v.size()>60000:return false
  for item in v:
   if not bounded(item,depth+1):return false
  return true
 if v is Dictionary:
  if v.size()>60000:return false
  for key in v:
   if not key is String or key.length()>100 or not bounded(v[key],depth+1):return false
  return true
 return false

static func vector(v:Variant)->bool:
 if not v is Dictionary or v.size()!=1 or not v.get("vector2") is Array or v.vector2.size()!=2:return false
 for n in v.vector2:
  if not (n is int or n is float) or not is_finite(float(n)) or absf(float(n))>40000:return false
 return true
static func foe(v:Variant)->bool:
 if not v is Dictionary or not vector(v.get("pos")) or not v.get("boss") is bool:return false
 if not v.get("type") is String or v.type.length()>64:return false
 for key in ["hp","max_hp","uid","attack_timer"]:
  if not C.number(v.get(key),1e10):return false
 return float(v.max_hp)>0
static func valid_checkpoint(v:Dictionary,kind:String)->bool:
 if not vector(v.get("position_in_world")) or not v.get("world") is Dictionary:return false
 for key in ["health","level","highest_level","experience","kills","gold","run_time","bonus_health","bonus_damage","bonus_speed","next_enemy_uid","dealt_damage","damage_taken","bounty_earned"]:
  if not C.number(v.get(key),1e12):return false
 if float(v.health)<=0 or float(v.level)<1 or float(v.level)>10 or float(v.highest_level)<float(v.level) or float(v.highest_level)>10:return false
 for key in ["boss_spawned","boss_defeated","boss_split_triggered"]:
  if not v.get(key) is bool:return false
 for key in ["upgrade","mastery","food"]:
  if not v.get(key) is String or v[key].length()>64:return false
 if not v.get("inventory") is Array or v.inventory.size()>3 or not v.get("enemies") is Array or v.enemies.size()>250:return false
 for id in v.inventory:
  if not id is String or id.length()>64:return false
 for enemy in v.enemies:
  if not foe(enemy):return false
 var w:Dictionary=v.world
 if w.has("conclave") and not preload("res://scripts/roaming_conclave.gd").valid(w.conclave):return false
 if w.has("trial_seconds") and not C.number(w.trial_seconds,1e9):return false
 if w.has("seal_drops"):
  if not w.seal_drops is Dictionary or w.seal_drops.size()>6:return false
  for at in w.seal_drops.values():
   if not vector(at):return false
 if kind in ["between","attunement"]:
  for key in ["dead","collected","explored","sleeping"]:
   if not w.get(key) is Dictionary:return false
  for key in ["dead","collected","explored"]:
   for value in w[key].values():
    if not value is bool:return false
  for enemy in w.sleeping.values():
   if not foe(enemy):return false
  if not C.number(w.get("carried"),100000) or not C.number(w.get("farthest"),14) or not w.get("guardian") is bool:return false
 else:
  if not w.get("events") is Array or w.events.size()>2:return false
  for e in w.events:
   if not e is Dictionary or not vector(e.get("at")) or e.get("state","") not in ["waiting","active","complete"]:return false
   if not C.number(e.get("type"),2) or not C.number(e.get("progress"),60) or not C.number(e.get("id"),1) or not e.get("spawned") is bool:return false
  if not C.number(w.get("modifier"),2):return false
  for key in ["clock","boss_timer"]:
   if not C.number(w.get(key),1e9):return false
 return true
