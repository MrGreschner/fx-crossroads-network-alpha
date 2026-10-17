extends Node
## Practice continuation preserves the live battle but rolls back run-earned awards.
const STORE=preload("res://scripts/profile_store.gd")
const KEYS=["heroes","tasks","card","realm_counts","cosmetics","rolling_damage","daily","bread","quest_ids","title","backup_reminder"]
var game:Node
var arcade=false
var active=false
var baseline={}
var profile_before={}
var journey_before={}
var quest_before={}
var quest_existed=false
var gold_before=100
var best_before=0
var best_save={}
var best_existed=false
func setup(owner:Node,multi:bool=false)->void:game=owner;arcade=multi
func begin()->void:
 end();baseline.clear()
 for key in KEYS:
  if game.legacy.data.has(key):baseline[key]=game.legacy.data[key].duplicate(true) if game.legacy.data[key] is Dictionary or game.legacy.data[key] is Array else game.legacy.data[key]
 journey_before=game.journey.data.duplicate(true)
 profile_before=game.profile.duplicate(true) if not arcade else {}
 gold_before=100 if arcade else game.gold
 if arcade:
  best_before=game.best_floor;best_save=STORE.read(game.best_path);best_existed=FileAccess.file_exists(game.best_path)
 quest_before=STORE.read("user://fx_quests_wayfarer_solo.json");quest_existed=FileAccess.file_exists("user://fx_quests_wayfarer_solo.json")
func available()->bool:
 if baseline.is_empty():return false
 if arcade:return game.role=="host" and not game.spectating() and game.match_party_size==1 and game.links.is_empty() and game.mode in ["descent","defense","coop"] and int(game.health.get(game.my_id,0))<=0
 if game.get("waylight")!=null and game.waylight.special():return false
 return game.mode=="run" and game.health<=0 and not game.practice and not game.tutorial.active and not (game.mistglass_rift!=null and game.mistglass_rift.active)
func restore_progress()->void:
 for key in KEYS:
  if baseline.has(key):game.legacy.data[key]=baseline[key].duplicate(true) if baseline[key] is Dictionary or baseline[key] is Array else baseline[key]
  else:game.legacy.data.erase(key)
 game.legacy.crowns.dirty=true;game.legacy.crowns.refresh()
 game.journey.data=journey_before.duplicate(true);game.journey.save()
 if arcade:
  game.best_floor=best_before
  if best_existed:STORE.write(game.best_path,best_save)
  else:STORE.erase(game.best_path)
 if not arcade:
  game.profile=profile_before.duplicate(true);game.save_profile()
  if quest_existed:STORE.write("user://fx_quests_wayfarer_solo.json",quest_before)
  else:STORE.erase("user://fx_quests_wayfarer_solo.json")
 game.legacy.save()
func resume()->void:
 if not available():return
 restore_progress();active=true;get_tree().root.set_meta("fx_practice_continue",true)
 game.presentation.close();game.presentation.last_result="";game.mobile.reset_controls()
 if arcade:
  game.started=true;game.results_reason="";game.health[game.my_id]=game._max_hp(game.my_id);game.downed.erase(game.my_id);game.respawn_at.erase(game.my_id);game.invincible_until[game.my_id]=Time.get_ticks_msec()+3000
  if game.mode=="defense" and game.gate_hp<=0:game.gate_hp=game.gate_max
  game.status_label.text="PRACTICE CONTINUE • no progression rewards; enemy discoveries remain."
 else:
  game.menu="";game.respawn_clinic=false;game.health=game.max_health();game.invulnerable_time=3;game.stun_time=0;game.stealth_time=0;game.upgrade="";game.last_defeat.clear()
  game.message="PRACTICE CONTINUE • XP and abilities retained. No mastery, records or completion rewards. Enemy discoveries still save.";game.message_time=9
 var owner=game.my_id if arcade else "solo"
 game.adventure.combat.statuses.erase(game.adventure.combat.player_key(owner))
func end()->void:
 if active:
  active=false
  if get_tree().root.has_meta("fx_practice_continue"):get_tree().root.remove_meta("fx_practice_continue")
  if not arcade:game.gold=gold_before
func _exit_tree()->void:end()
