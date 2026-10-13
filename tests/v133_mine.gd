extends SceneTree
const Mine=preload("res://scripts/idle_mine.gd")
var failures=0
class Owner extends Node:
 var data:Dictionary={"teacher":false}
 var writes=0
 func save()->void:writes+=1
func check(value:bool,label:String)->void:
 print("PASS • " if value else "FAIL • ",label)
 if not value:failures+=1
func fixture(stamp:float=1000000)->RefCounted:
 var owner=Owner.new();root.add_child(owner);var m=Mine.new();m.time_for_test=stamp;m.setup(owner);return m
func near(a:float,b:float)->bool:return absf(a-b)<.0001
func _initialize()->void:call_deferred("run")
func run()->void:
 var m=fixture()
 check(Mine.valid(m.state()),"fresh save schema")
 m.time_for_test+=600;m.advance();check(m.state().stored.gold==0,"uncommissioned mine earns nothing")
 check(m.commission() and m.state().wallet.gold==40 and m.depth()==1,"80-gold starter camp")
 var rate=m.rates();m.time_for_test+=60;m.advance()
 check(near(m.state().stored.gold,float(rate.gold)*60),"one-minute gold integration")
 check(near(m.state().stored.ore,float(rate.ore)*60),"one-minute ore integration")
 var produced=m.state().stored.duplicate(true);m.collect();check(near(m.state().wallet.gold,40+float(produced.gold)) and m.stored_units()==0,"collection transfers resources once")
 var coins=m.state().wallet.gold;m.collect();check(near(coins,m.state().wallet.gold),"repeat collect cannot duplicate income")
 check(m.hire(0) and m.workers()==2,"hire ram digger")
 m.state().shafts[0].crew=12;check(not m.hire(0),"crew cap enforced")
 check(m.rates().flow<m.rates().dig,"lift bottleneck limits output")
 m.state().levels.lift=25;m.state().shafts=[{"depth":1,"crew":12},{"depth":2,"crew":12},{"depth":3,"crew":12}]
 check(m.rates().air<1,"air demand reduces efficiency")
 m.state().levels.vent=5;check(m.rates().air==1,"ventilation restores efficiency")
 m.state().shafts=[{"depth":1,"crew":2}];m.state().wallet={"gold":1000000.0,"ore":1000000.0,"gems":10000.0};m.state().last=m.now();m.state().stored=Mine.zeros()
 check(m.excavate(),"excavation queues construction");check(not m.upgrade("tools"),"one construction crew")
 var job_end=m.state().job.end;m.time_for_test=float(job_end)+60;m.advance();check(m.depth()==2 and m.state().job.is_empty(),"shaft finishes offline")
 check(m.state().stored.gold>0,"crews produce during construction")
 check(m.upgrade("tools"),"building upgrade queued");var saved_wallet=m.state().wallet.duplicate(true);var cost=m.state().job.cost.duplicate(true);m.cancel_build()
 check(near(m.state().wallet.gold,float(saved_wallet.gold)+float(cost.gold)),"cancel refunds only paid cost")
 check(not m.upgrade("drill"),"deep building unlock enforced")
 m.state().levels.smelter=1;check(m.refine(),"smelter order starts");check(not m.refine(),"refining cannot overlap")
 var gold=m.state().wallet.gold;m.time_for_test+=30;m.advance();check(near(m.state().wallet.gold,float(gold)+18.45) and m.state().refined==30,"smelter finishes its independent timer")
 check(m.boost("rally"),"rally unlocked at shaft two");check(not m.boost("rally"),"boost cooldown enforced")
 var started=m.now();m.state().stored=Mine.zeros();var active_rate=m.rates(started);var base_rate=m.rates(started+61)
 m.time_for_test=started+120;m.advance();check(near(m.state().stored.gold,(float(active_rate.gold)+float(base_rate.gold))*60),"offline boost expiry integrated exactly")
 var f=fixture();f.commission();f.state().levels.depot=25;var normal=f.rates();f.time_for_test+=86400*10;f.advance()
 check(near(f.state().stored.gold,float(normal.gold)*86400),"24-hour absence cap")
 var full=fixture();full.commission();full.time_for_test+=86400;full.advance();check(near(full.stored_units(),full.capacity()),"full depot pauses at capacity")
 var lifetime=full.state().lifetime.gold;full.time_for_test+=86400;full.advance();check(near(full.state().lifetime.gold,float(lifetime)),"full depot never invents production")
 full.collect();full.time_for_test+=60;full.advance();check(full.state().stored.gold>0,"collecting resumes production")
 var before=full.state().duplicate(true);full.time_for_test-=100;full.advance();check(full.state()==before,"backward clock cannot replay production")
 full.time_for_test+=100;var stamp=full.now();full.state().stored=Mine.zeros();full.state().last=stamp
 var snapshot=JSON.parse_string(JSON.stringify(full.state()));var restored=fixture(stamp+120);restored.legacy.data.mine=snapshot;restored.setup(restored.legacy)
 check(restored.state().stored.gold>0 and Mine.valid(restored.state()),"portable JSON restores and catches up")
 restored.state().shafts[0].crew=3;check(restored.claim("crew") and not restored.claim("crew"),"milestones grant once")
 var research=root.get_node("FXResearch");research.active=true;var protected=restored.state().duplicate(true);restored.time_for_test+=100;restored.advance();check(restored.state()==protected and not restored.collect() and not restored.hire(0),"Playtest cannot modify mine")
 research.active=false
 var bad=restored.state().duplicate(true);bad.wallet.gold=-1;check(not Mine.valid(bad),"negative funds rejected")
 bad=restored.state().duplicate(true);bad.levels.lift=INF;check(not Mine.valid(bad),"nonfinite upgrade rejected")
 bad=restored.state().duplicate(true);bad.shafts[0].crew=13;check(not Mine.valid(bad),"oversized crew rejected")
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g;await process_frame;g.set_process(false);g.presentation.close();g.session_menu.resume()
 check(g.can_stand_at(g.idle_mine_town.ENTRY),"town mine doorway is reachable")
 g.position_in_world=g.idle_mine_town.ENTRY;check(g.idle_mine_town.interact(g) and "Deepwell Mine" in g.hint,"mine interaction is discoverable")
 var combat_gold=g.gold;var attacks=g.characters.duplicate(true);g.legacy.mine.commission();g.legacy.mine.collect()
 check(g.gold==combat_gold and g.characters==attacks,"mine never changes combat gold or heroes")
 var bundle=g.legacy.bundle();check(bundle.progress.has("mine") and g.legacy.validate(bundle),"profile includes valid mine state")
 var malformed=bundle.duplicate(true);malformed.progress.mine.wallet.gold=-1;check(not g.legacy.validate(malformed),"bad mine cannot replace account")
 var zip_path="user://v133-profile-test.zip"
 check(preload("res://scripts/studio_bundle.gd").make(bundle,zip_path)==OK,"profile ZIP writes mine")
 var decoded=preload("res://scripts/studio_bundle.gd").read(zip_path);check(decoded.error.is_empty() and JSON.stringify(decoded.payload.progress.mine)==JSON.stringify(JSON.parse_string(JSON.stringify(bundle.progress.mine))),"profile ZIP restores whole mine")
 var old=bundle.duplicate(true);old.progress.erase("mine");check(g.legacy.validate(old),"older profiles without mine remain valid")
 g.legacy.mine.open();await process_frame;check(g.menu=="idle_mine" and g.legacy.mine.view.active,"mine UI opens")
 for tab in 4:g.legacy.mine.view.tabs.current_tab=tab;await process_frame
 g.legacy.mine.view.close();check(g.menu=="" and g.visible,"mine returns to town")
 var before_import=g.legacy.mine.state().duplicate(true);g.legacy.pending=g.legacy.bundle();g.legacy.apply_import()
 for n in 3:await process_frame
 g=current_scene;g.set_process(false);g.presentation.close();g.session_menu.resume()
 check(g.legacy.mine.depth()==before_import.shafts.size() and near(g.legacy.mine.state().wallet.gold,float(before_import.wallet.gold)),"actual profile replacement restores mine")
 g.legacy.save();var normal_saved=""
 g.legacy.enable_teacher();normal_saved=FileAccess.get_file_as_string(g.legacy.PATH);check(g.legacy.mine.depth()==20 and g.legacy.mine.workers()==240,"Game Dev temporary mine unlocks")
 g.legacy.mine.time_for_test=g.legacy.mine.now()+3600;g.legacy.mine.collect();g.legacy.save()
 check(FileAccess.get_file_as_string(g.legacy.PATH)==normal_saved,"Game Dev mine cannot overwrite saved account")
 print("V133 MINE FAILURES • ",failures);quit(failures)
