extends SceneTree
const ACCESS=preload("res://scripts/realm_access.gd")
const STORE=preload("res://scripts/profile_store.gd")
var checks=0
var failures=0
func check(ok:bool,message:String)->void:
 checks+=1;print("PASS • " if ok else "FAIL • ",message)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 for n in 10:await process_frame
 g.set_process(false);g.legacy.set_process(false);g.presentation.close();g.session_menu.resume();g.menu="";g.legacy.data=g.legacy.defaults();g.legacy.mine.setup(g.legacy)
 check(ACCESS.unlocked(g.legacy,"grove"),"Grove starts unlocked")
 check(ACCESS.unlocked(g.legacy,"quarry"),"Quarry also starts open")
 for id in ["sunfield","lantern_marsh","astral_rift"]:check(not ACCESS.unlocked(g.legacy,id),"fresh profile blocks "+id)
 g.start_run(false,"astral_rift");check(g.mode=="town","direct launch cannot bypass realm gate")
 g.legacy.clear_adventure("ram","grove");check(ACCESS.unlocked(g.legacy,"elementary"),"starter win unlocks second pair")
 check(not ACCESS.unlocked(g.legacy,"ice"),"starter alone does not unlock moderate")
 g.legacy.clear_adventure("ram","elementary");check(ACCESS.unlocked(g.legacy,"ice"),"second pair unlocks moderate")
 g.legacy.clear_adventure("ram","sunfield");check(ACCESS.unlocked(g.legacy,"petalbrook"),"moderate unlocks medium")
 for id in ["moonveil","petalbrook","folded_coast"]:g.legacy.clear_adventure("ram",id)
 check(ACCESS.unlocked(g.legacy,"space"),"three mediums unlock challenging")
 g.legacy.clear_adventure("ram","space")
 for id in ["silverfall","brasslock","clockwork_orchard","lantern_marsh"]:g.legacy.clear_adventure("ram",id)
 check(ACCESS.unlocked(g.legacy,"astral_rift"),"four hard realms unlock expert")
 g.legacy.data=g.legacy.defaults();g.legacy.mine.setup(g.legacy)
 root.set_meta("fx_dev_match",true);check(ACCESS.unlocked(g.legacy,"shattered_oath"),"Playtest/GameDev testing session unlocks all realms");root.remove_meta("fx_dev_match")
 var mine=g.legacy.mine;mine.state().commissioned=true;mine.state().shafts=[]
 for n in 4:mine.state().shafts.append({"depth":n+1,"crew":1})
 check("Descent floor 5" in mine.next_requirement(),"shaft five requires cleared Descent floor five")
 g.legacy.card.descent_cleared(5,1);check(not "Descent" in mine.next_requirement(),"Descent five permits mining through ten")
 for n in range(4,10):mine.state().shafts.append({"depth":n+1,"crew":1})
 check("Descent floor 10" in mine.next_requirement(),"shaft eleven requires cleared Descent ten")
 g.legacy.card.descent_cleared(10,1);check(not "Descent" in mine.next_requirement(),"Descent ten permits all twenty shafts")
 var before=g.legacy.record("ram").damage;g.start_run(false,"grove");g.experience=37;g.level=6;g.highest_level=6;g.bonus_damage=8;g.health=0;var point=g.position_in_world;var count=g.enemies.size()
 g.legacy.add_damage("ram",200);g.finish_run(false)
 check(g.continuation.available(),"solo realm defeat offers continue")
 check(g.presentation.modal.find_children("*","Button",true,false).any(func(b):return b.text=="Continue • practice"),"defeat screen has visible Continue button")
 g.continuation.resume()
 check(g.health==g.max_health() and g.level==6 and g.experience==37 and g.bonus_damage==8,"continue retains XP, unlocked skills and run upgrades with full health")
 check(g.position_in_world==point and g.enemies.size()==count,"same battle state and position retained")
 check(g.legacy.record("ram").damage==before,"whole attempt mastery damage rolled back")
 check(STORE.progression_blocked() and not STORE.testing(),"practice blocks awards without disabling discovery saves")
 g.legacy.add_damage("ram",500);g.legacy.clear_adventure("ram","grove")
 check(g.legacy.record("ram").damage==before and not ACCESS.cleared(g.legacy,"grove"),"practice damage and clears cannot award progress")
 g.enemies.assign([{"pos":g.position_in_world+Vector2(10,0),"hp":10.0,"type":"bramble","boss":false,"uid":101}]);g.catalog_ui.record_encounters()
 check("bramble" in g.legacy.data.encounters.get("grove",[]),"continued practice still discovers enemies")
 var runs=g.profile.runs;g.finish_run(true);check(g.profile.runs==runs and not ACCESS.cleared(g.legacy,"grove"),"practice victory awards no run record or realm unlock")
 g.enter_region("town");check(not STORE.progression_blocked(),"town exit clears practice restriction")
 var build=g.version_check
 build.completed(0,200,PackedStringArray(),JSON.stringify({"game_build":153}).to_utf8_buffer());check(build.blocked(),"older native build sees newer online release")
 build.notice();check(build.ui!=null,"update notice provides save-first instruction and downloads")
 build.ui.queue_free();build.ui=null;build.shown=true
 build.completed(0,200,PackedStringArray(),'{"game_build":152}'.to_utf8_buffer());check(not build.blocked(),"matching build can play")
 build.completed(1,0,PackedStringArray(),PackedByteArray());check(not build.status.is_empty(),"network failure offers offline status")
 g.queue_free();await process_frame;await process_frame
 root.set_meta("fx_mode","descent");root.set_meta("fx_hero","ram")
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);current_scene=a
 for n in 10:await process_frame
 a.set_process(false);a.party_tools.auto_solo=false;a._solo();a.start_countdown=0;a.levels[a.my_id]=7;a.xp[a.my_id]=123;a.health[a.my_id]=0;var floor=a.floor_number
 a.end_match("You were defeated in the Descent.");check(a.continuation.available(),"solo Descent defeat also permits continue")
 a.continuation.resume();check(a.started and a.health[a.my_id]==a._max_hp(a.my_id) and a.levels[a.my_id]==7 and a.xp[a.my_id]==123 and a.floor_number==floor,"Descent continue preserves floor and XP with full health")
 a.legacy.card.descent_cleared(30,1);check(a.legacy.card.state().descent_best<30,"practice Descent cannot unlock mining or badges")
 a.continuation.end();a.mode="arena";check(not a.continuation.available(),"PvP never offers practice continue");a.mode="descent";a.health[a.my_id]=0;a.match_party_size=2;check(not a.continuation.available(),"multiplayer never offers continue")
 a.queue_free();await process_frame;check(not STORE.progression_blocked(),"scene exit clears transient practice mode")
 await create_timer(.5).timeout
 print("V147 ",checks," checks / ",failures," failures");quit(0 if failures==0 else 1)
