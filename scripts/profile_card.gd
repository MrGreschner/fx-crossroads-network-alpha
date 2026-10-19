extends RefCounted
## Portable, local player-card records. Match cursors make snapshots idempotent.
var legacy:Node
const BADGES={"astral_rift":{"name":"Riftbreaker","color":"#a6b5f0","symbol":"rift"},"chimevault":{"name":"Silencebreaker","color":"#e9c68d","symbol":"bell"},"ebonwake":{"name":"Dawn Survivor","color":"#dc9dbe","symbol":"flame"},"shattered_oath":{"name":"Oath Unbroken","color":"#ead080","symbol":"crown"}}
const TROPHIES=["Unranked","Bronze","Silver","Gold","Platinum","Astral"]
const THRESHOLDS=[1,3,5,10,20]
func arena_defaults()->Dictionary:return {"wins":0,"losses":0,"draws":0,"kills":0,"npc_kills":0,"deaths":0,"streak":0,"best_streak":0,"kill_streak":0,"best_kill_streak":0}
func defaults()->Dictionary:return {"descent_best":0,"portrait":"","badges":[],"arena":{"standard":arena_defaults(),"random":arena_defaults()},"cursors":{}}
func state()->Dictionary:
 if not legacy.data.get("card") is Dictionary:legacy.data["card"]=defaults()
 var value:Dictionary=legacy.data.card
 for key in defaults():
  if not value.has(key):value[key]=defaults()[key]
 for mode in ["standard","random"]:
  if not value.arena.has(mode):value.arena[mode]=arena_defaults()
  for key in arena_defaults():
   if not value.arena[mode].has(key):value.arena[mode][key]=0
 return value
func tier(streak:int)->int:
 var result:=0
 for threshold in THRESHOLDS:
  if streak>=threshold:result+=1
 return result
func portrait_unlocked(id:String)->bool:return legacy.game.characters.has(id) and legacy.eligible(id)
func portrait_star(id:String)->bool:return not id.is_empty() and legacy.game.characters.has(id) and legacy.final_eligible(id)
func select_portrait(id:String)->void:
 if not id.is_empty() and not portrait_unlocked(id):return
 state().portrait=id;legacy.save();legacy.render()
func mastered()->int:
 var count:=0
 for id in legacy.game.characters:
  if legacy.final_eligible(str(id)):count+=1
 return count
func unlocked_portraits()->int:
 var count:=0
 for id in legacy.game.characters:
  if portrait_unlocked(str(id)):count+=1
 return count
func badges()->Array:
 var values:Array=state().badges.duplicate()
 for id in legacy.data.tasks.get("realms",[]):
  if BADGES.has(str(id)) and not values.has(str(id)):values.append(str(id))
 return values
func cleared(realm:String)->void:
 if (bool(legacy.data.teacher) or preload("res://scripts/profile_store.gd").progression_blocked()):return
 if BADGES.has(realm) and not state().badges.has(realm):state().badges.append(realm)
func coop_clear(realm:String)->void:
 if (bool(legacy.data.teacher) or preload("res://scripts/profile_store.gd").progression_blocked()):return
 legacy.data.tasks["coop_clears"]=int(legacy.data.tasks.get("coop_clears",0))+1
 var list:Array=legacy.data.tasks.get("coop_realms",[])
 if realm not in list:list.append(realm)
 legacy.data.tasks["coop_realms"]=list
 legacy.data.tasks["coop_distinct"]=list.size()
func wave_cleared(count:int,party_size:int)->void:
 if (bool(legacy.data.teacher) or preload("res://scripts/profile_store.gd").progression_blocked()):return
 weekly_survival("gate",count)
 legacy.daily.survival("defense",count,party_size)
 legacy.data.tasks["defense_best"]=maxi(int(legacy.data.tasks.get("defense_best",0)),count)
 if party_size>=2:legacy.data.tasks["coop_defense"]=maxi(int(legacy.data.tasks.get("coop_defense",0)),count)
 if count>=30:
  legacy.data.tasks["defense30"]=1;legacy.data.town["bastion"]=true
func descent_cleared(count:int,party_size:int)->void:
 if (bool(legacy.data.teacher) or preload("res://scripts/profile_store.gd").progression_blocked()):return
 weekly_survival("descent",count)
 legacy.daily.survival("descent",count,party_size)
 state().descent_best=maxi(int(state().descent_best),count)
 if party_size<2:return
 legacy.data.tasks["coop_descent"]=maxi(int(legacy.data.tasks.get("coop_descent",0)),count)
func weekly_survival(kind:String,count:int)->void:
 if count<=0:return
 if not legacy.arcade:legacy.weekly.advance(kind,count,true);return
 var seen=cursor(str(legacy.game.match_id));var field="weekly_"+kind
 if count<=int(seen.get(field,0)):return
 seen[field]=count;legacy.weekly.advance(kind,count,true)
func cursor(match_id:String)->Dictionary:
 var cursors:Dictionary=state().cursors
 if not cursors.has(match_id):
  if cursors.size()>=24:cursors.erase(cursors.keys()[0])
  cursors[match_id]={"damage":0.0,"kills":0,"npc_kills":0,"deaths":0,"done":false}
 return cursors[match_id]
func sync_match(match_id:String,mode:String,random_heroes:bool,hero:String,stats:Dictionary,damage:float,guest:bool=false)->void:
 if match_id.is_empty() or (bool(legacy.data.teacher) or preload("res://scripts/profile_store.gd").progression_blocked()):return
 var seen:=cursor(match_id)
 if bool(seen.done):return
 if guest:
  var total:=maxf(0,damage);var added:=maxf(0,total-float(seen.damage))
  if added>0:legacy.add_damage(hero,added)
  seen.damage=maxf(total,float(seen.damage))
 seen["mode"]=mode;seen["random"]=random_heroes
 legacy.cosmetics.competitive.match_stats(match_id,mode,stats)
 if mode!="arena":return
 var record:Dictionary=state().arena["random" if random_heroes else "standard"]
 for key in ["kills","npc_kills","deaths"]:
  var total:=maxi(0,int(stats.get(key,0)))
  if key=="kills":legacy.weekly.advance("arena_kills",maxi(0,total-int(seen[key])))
  record[key]=int(record[key])+maxi(0,total-int(seen[key]));seen[key]=maxi(int(seen[key]),total)
 record.kill_streak=maxi(0,int(stats.get("kill_streak",0)))
 record.best_kill_streak=maxi(int(record.best_kill_streak),int(stats.get("best_kill_streak",0)))
func arena_result(match_id:String,random_heroes:bool,outcome:String)->void:
 if (bool(legacy.data.teacher) or preload("res://scripts/profile_store.gd").progression_blocked()) or match_id.is_empty() or outcome not in ["win","loss","draw"]:return
 var seen:=cursor(match_id)
 if bool(seen.done):return
 legacy.cosmetics.competitive.result(match_id,outcome)
 seen.done=true
 if outcome!="loss" or legacy.arcade and not legacy.game.results_reason.is_empty():legacy.weekly.advance("arena_matches",1)
 if outcome=="win":legacy.weekly.advance("arena_wins",1)
 var record:Dictionary=state().arena["random" if random_heroes else "standard"]
 if outcome=="win":record.wins+=1;record.streak+=1;record.best_streak=maxi(int(record.best_streak),int(record.streak))
 elif outcome=="loss":record.losses+=1;record.streak=0
 else:record.draws+=1
 legacy.save()
func recover_abandoned()->void:
 if (bool(legacy.data.teacher) or preload("res://scripts/profile_store.gd").progression_blocked()):return
 for id in state().cursors.keys():
  var seen:Dictionary=state().cursors[id]
  if not bool(seen.get("done",false)) and str(seen.get("mode",""))=="arena":arena_result(str(id),bool(seen.get("random",false)),"loss")
func finish_cursor(match_id:String)->void:
 if not match_id.is_empty():cursor(match_id).done=true
func valid(value:Variant)->bool:
 if not value is Dictionary:return false
 var depth:Variant=value.get("descent_best",0)
 if not (depth is int or depth is float) or not is_finite(float(depth)) or float(depth)<0 or float(depth)>1000000:return false
 if not value.get("portrait","") is String or not value.get("badges",[]) is Array or not value.get("arena",{}) is Dictionary or not value.get("cursors",{}) is Dictionary:return false
 for badge in value.get("badges",[]):
  if not badge is String or not BADGES.has(badge):return false
 for mode in value.get("arena",{}):
  if mode not in ["standard","random"] or not value.arena[mode] is Dictionary:return false
  for key in arena_defaults():
   var n:Variant=value.arena[mode].get(key,0)
   if not (n is int or n is float) or not is_finite(float(n)) or float(n)<0 or float(n)>1000000000:return false
 if value.get("cursors",{}).size()>24:return false
 for id in value.get("cursors",{}):
  var seen:Variant=value.cursors[id]
  if not id is String or not seen is Dictionary:return false
  for key in ["damage","kills","npc_kills","deaths","weekly_gate","weekly_descent"]:
   var n:Variant=seen.get(key,0)
   if not (n is int or n is float) or not is_finite(float(n)) or float(n)<0 or float(n)>1000000000:return false
 return true

func descent_tier()->int:
 var result:=0
 for floor in [5,10,20,30,50]:
  if int(state().descent_best)>=floor:result+=1
 return result
