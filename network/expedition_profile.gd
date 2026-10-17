extends RefCounted
const P=preload("res://scripts/waylight_progress.gd")
const C=preload("res://scripts/waylight_catalog.gd")
static func progress(g:Node)->RefCounted:
 var p=P.new();p.legacy=g.legacy;p.state();return p
static func offer(g:Node)->Dictionary:
 var p=progress(g);var s=p.state();var items=[]
 if not bool(s.fair):
  for id in s.equipped:
   var v=p.item(str(id))
   if not v.is_empty():items.append(v.duplicate(true))
 return {"shards":int(s.shards),"attuned":bool(s.attuned),"best_ring":int(s.best_ring),"between_unlocked":p.between_unlocked(),"between_depth":preload("res://scripts/between_access.gd").depth(g.legacy),"can_attune":p.can_attune(),"practice":p.blocked(),"busy":not s.run.is_empty(),"relics":items,"fair":bool(s.fair)}
static func clean(v:Variant)->Dictionary:
 if not v is Dictionary:return {}
 for key in ["shards","best_ring"]:
  if not C.number(v.get(key),1000000):return {}
 if not C.number(v.get("between_depth",6),14) or float(v.get("between_depth",6))!=floorf(float(v.get("between_depth",6))) or int(v.get("between_depth",6)) not in [6,8,10,12,14]:return {}
 var out={"between_depth":int(v.get("between_depth",6)),"shards":int(v.shards),"best_ring":mini(14,int(v.best_ring))}
 for key in ["attuned","between_unlocked","can_attune","practice","busy","fair"]:
  if not v.get(key) is bool:return {}
  out[key]=v[key]
 out.relics=[];var types=[]
 if not v.get("relics") is Array or v.relics.size()>2:return {}
 for item in v.relics:
  if not C.valid_relic(item) or item.type in types:return {}
  types.append(item.type);out.relics.append(item.duplicate(true))
 if out.fair:out.relics=[]
 return out
static func issue(v:Dictionary,config:Dictionary)->String:
 if v.is_empty():return "Refresh your expedition profile before starting."
 if v.busy:return "Resume or forfeit the existing expedition on this profile first."
 if config.kind=="attunement":return "Attunement Challenge is solo only. Choose The Between for co-op."
 if v.practice:return ""
 if config.kind in ["between","attunement"] and not v.between_unlocked:return "Both players must clear Sunfield Expanse or Frostbound Rink to unlock The Between."
 if config.kind=="overcharge" and not v.attuned:return "Both players must complete Portal Attunement before overcharging."
 if config.kind=="attunement":return "Attunement Challenge is solo only. Choose The Between for co-op."
 if config.kind=="overcharge":
  if int(v.shards)<C.COSTS[int(config.tier)-1]:return "Each player needs "+str(C.COSTS[int(config.tier)-1])+" Waylight Shards."
  if int(config.tier)>1 and (not v.attuned or int(v.best_ring)<(int(config.tier)-1)*3):return "Both players need attunement and the required banked depth for this tier."
 return ""
static func reserve(g:Node,config:Dictionary)->String:
 var p=progress(g);var s=p.state()
 if not s.run.is_empty():
  return "" if str(s.run.get("coop",{}).get("reservation",""))==str(config.id) else "Resume or forfeit the existing expedition first."
 var problem=issue(offer(g),config)
 if not problem.is_empty():return problem
 if config.kind=="overcharge" and not p.blocked() and not preload("res://scripts/realm_access.gd").unlocked(g.legacy,str(config.realm)):return "Unlock today's realm on this profile first."
 var cost=C.COSTS[int(config.tier)-1] if config.kind=="overcharge" and not p.blocked() else 0
 s.shards=int(s.shards)-cost
 s.run={"id":"n"+str(config.id)+"-"+g.my_id,"kind":str(config.kind),"realm":str(config.realm),"tier":int(config.tier),"seed":int(config.personal_seed),"day":int(config.day),"eligible":bool(s.attuned),"layout_version":3,"depth":int(config.get("depth",6)),"hero":g.preferred_hero,"checkpoint":{},"coop":{"reservation":str(config.id),"room":g.net_room,"token":g.resume_token,"endpoint":g.url_field.text,"world_seed":int(config.seed),"started":false,"cost":cost,"carried":0,"farthest":0,"guardian":false,"events":0}}
 p.save();return ""
static func cancel(g:Node,id:String="")->void:
 var p=progress(g);var t=p.state().run;var n:Dictionary=t.get("coop",{})
 if n.is_empty() or bool(n.get("started",false)) or not id.is_empty() and str(n.reservation)!=id:return
 p.state().shards=mini(1000000,int(p.state().shards)+int(n.cost));p.state().run={};p.save()
static func commit(g:Node,config:Dictionary)->void:
 if config.is_empty():return
 var p=progress(g);var t=p.state().run
 if str(t.get("coop",{}).get("reservation",""))==str(config.get("id","")):t.coop.started=true;p.save()
static func record(g:Node,state:Dictionary)->String:
 var p=progress(g);var t=p.state().run;var n:Dictionary=t.get("coop",{})
 if n.is_empty() or str(n.reservation)!=str(state.get("id","")):return ""
 n.started=true
 var changed=false
 for key in ["carried","farthest","guardian","events"]:
  var value=state.get(key,n[key])
  if n[key]!=value:n[key]=value;changed=true
 if state.get("finished",false):return p.settle(bool(state.get("won",false)),int(n.carried),int(n.farthest),bool(n.guardian),int(n.events),{"conclave":bool(state.get("conclave_complete",false))})
 if changed:p.save()
 return ""
static func forfeit(g:Node)->String:
 var p=progress(g);var t=p.state().run;var n:Dictionary=t.get("coop",{})
 if n.is_empty():return "No co-op expedition to forfeit."
 if not bool(n.get("started",false)):cancel(g);return "Unstarted co-op reservation cancelled; entry shards refunded."
 return p.settle(false,int(n.get("carried",0)),int(n.get("farthest",0)),false,0)
