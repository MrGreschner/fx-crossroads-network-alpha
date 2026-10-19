extends RefCounted
const CLOCK=preload("res://scripts/cosmetic_rankings.gd")
var legacy:Node
var exploration_sizes:Dictionary={}
var life_context=""
var alive=true
func week()->String:return legacy.cosmetics.rankings.week()
func state()->Dictionary:
 if not legacy.data.has("competitive") or str(legacy.data.competitive.get("week",""))!=week():
  var previous:Dictionary=legacy.data.get("competitive",{}).get("cursors",{}).duplicate(true)
  legacy.data.competitive={"version":1,"week":week(),"wins":0,"kos":0,"deaths":0,"matches":0,"explore":0,"defeated":false,"cursors":previous}
 return legacy.data.competitive
func allowed()->bool:return not bool(legacy.data.get("teacher",false)) and not preload("res://scripts/profile_store.gd").progression_blocked() and not legacy.get_tree().root.has_meta("fx_dedicated_server")
func cursor(key:String)->Dictionary:
 var c:Dictionary=state().cursors
 if not c.has(key):
  if c.size()>=128:c.erase(c.keys()[0])
  c[key]={"kos":0,"deaths":0,"explore":0,"done":false}
 return c[key]
func pvp()->bool:
 var g=legacy.game
 return legacy.arcade and g.mode in ["arena","battlegrounds"] and not g.spectating() and not g.practice_match() and int(g.match_party_size)>=2
func match_stats(id:String,mode:String,stats:Dictionary)->void:
 if not allowed() or id.is_empty():return
 var seen=cursor("match:"+id);var deaths=maxi(0,int(stats.get("deaths",0)));var changed=deaths>int(seen.deaths)
 if changed:defeated(false)
 if pvp() and mode in ["arena","battlegrounds"]:
  var kos=maxi(0,int(stats.get("kills",0)));changed=changed or kos>int(seen.kos);state().kos=mini(1000000,int(state().kos)+maxi(0,kos-int(seen.kos)));state().deaths=mini(1000000,int(state().deaths)+maxi(0,deaths-int(seen.deaths)));seen.kos=maxi(kos,int(seen.kos))
 seen.deaths=maxi(deaths,int(seen.deaths))
 if changed:legacy.save();legacy.cosmetics.rankings.delay=1
func result(id:String,outcome:String)->void:
 if not allowed() or not pvp() or id.is_empty() or outcome not in ["win","loss","draw"]:return
 var seen=cursor("match:"+id)
 if bool(seen.done):return
 seen.done=true;state().matches=mini(1000000,int(state().matches)+1)
 if outcome=="win":state().wins=mini(1000000,int(state().wins)+1)
 legacy.save();legacy.cosmetics.rankings.delay=1
func explore(id:String,collected:Dictionary)->void:
 if not allowed() or id.is_empty():return
 var cache_key=week()+":"+id
 if int(exploration_sizes.get(cache_key,-1))==collected.size():return
 if exploration_sizes.size()>=128:exploration_sizes.erase(exploration_sizes.keys()[0])
 exploration_sizes[cache_key]=collected.size()
 var count=0
 for key in collected:
  # Cleared Waylight deposits certify a visited, defended map section; fog alone does not count.
  if str(key).contains(",") and not str(key).contains(":"):count+=1
 var seen=cursor("between:"+id);var added=maxi(0,count-int(seen.explore))
 if added>0:state().explore=mini(1000000,int(state().explore)+added);seen.explore=count;legacy.save();legacy.cosmetics.rankings.delay=1
func defeated(persist:bool=true)->void:
 if not allowed():return
 preload("res://scripts/named_records.gd").died(legacy)
 if state().defeated:return
 state().defeated=true
 if persist:legacy.save()
 legacy.cosmetics.rankings.notify()
func step()->void:
 if not allowed():return
 var g=legacy.game;var mode=str(g.mode)
 if mode=="town":life_context="";alive=true;return
 if not legacy.arcade and (g.practice or g.tutorial.active):return
 var context=str(g.match_id) if legacy.arcade else str(g.get_instance_id())+":"+str(g.region_id)+":"+str(g.run_time<1)
 var hp=float(g.health.get(g.my_id,1)) if legacy.arcade else float(g.health)
 if context!=life_context:life_context=context;alive=hp>0
 elif alive and hp<=0:defeated()
 alive=hp>0
static func valid(v:Variant)->bool:
 if not v is Dictionary or v.size()!=9 or v.get("version")!=1 or not v.get("week") is String or v.week.length()!=10 or not v.get("defeated") is bool or not v.get("cursors") is Dictionary or v.cursors.size()>128:return false
 for key in ["wins","kos","deaths","matches","explore"]:
  if not integer(v.get(key),1000000):return false
 if int(v.wins)>int(v.matches):return false
 for key in v.cursors:
  var r=v.cursors[key]
  if not key is String or key.length()>100 or not r is Dictionary or r.size()!=4 or not r.get("done") is bool:return false
  for field in ["kos","deaths","explore"]:
   if not integer(r.get(field),1000000):return false
 return true
static func integer(v:Variant,max_value:int)->bool:return (v is int or v is float) and is_finite(float(v)) and float(v)>=0 and float(v)<=max_value and float(v)==floor(float(v))
