extends SceneTree
const Commerce=preload("res://scripts/commerce.gd")
const Mine=preload("res://scripts/idle_mine.gd")
var failures=0
class Owner extends Node:
 var data:Dictionary={"teacher":false}
 var mine:RefCounted
 var writes=0
 func save()->void:writes+=1
func check(v:bool,message:String)->void:
 print("PASS • " if v else "FAIL • ",message)
 if not v:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 var owner=Owner.new();root.add_child(owner);owner.mine=Mine.new();owner.mine.time_for_test=1000000;owner.mine.setup(owner)
 var m=Commerce.new();m.setup(owner)
 check(Commerce.valid(m.state()),"fresh market schema")
 check(not m.stock(0,1),"mine product locked before commissioning")
 owner.mine.commission();owner.mine.state().wallet.ore=500
 var initial_gold=owner.mine.state().wallet.gold
 check(m.stock(0,5),"stock uses mine ore and market processing cash")
 check(owner.mine.state().wallet.ore==450 and m.state().cash==150,"atomic purchase accounting")
 check(owner.mine.state().wallet.gold==initial_gold,"stock does not spend mine gold or combat gold")
 var before=JSON.stringify(owner.data);check(not m.stock(0,101) and JSON.stringify(owner.data)==before,"invalid order leaves account unchanged")
 check(not m.stock(2,1),"deep product remains locked")
 check(m.settle_day(),"business day produces results")
 var r=m.state().history.back()
 check(r.sold<=5 and m.state().inventory.ore.units==5-r.sold,"sales cannot exceed inventory")
 check(is_equal_approx(r.profit,r.revenue-r.cogs-r.advertising-r.overhead),"profit subtracts opportunity cost and expenses")
 check(is_equal_approx(m.state().cash,150+r.revenue-r.advertising-r.overhead),"cash does not pay committed COGS twice")
 check(Commerce.valid(JSON.parse_string(JSON.stringify(m.state()))),"JSON profile roundtrip")
 var bad=m.state().duplicate(true);bad.inventory.ore.price=-1;check(not Commerce.valid(bad),"invalid product price rejected")
 bad=m.state().duplicate(true);bad.cash=NAN;check(not Commerce.valid(bad),"nonfinite finances rejected")
 bad=m.state().duplicate(true);bad.segment=4;check(not Commerce.valid(bad),"invalid customer rejected")
 m.state().cash=1000;check(m.upgrade("quality") and m.state().quality==1,"quality investment")
 var cash=m.state().cash;var gold=owner.mine.state().wallet.gold;check(m.transfer(25) and m.state().cash==cash-25 and owner.mine.state().wallet.gold==gold+25,"reinvestment transfers one-to-one exactly")
 check(not m.transfer(-1),"negative transfer rejected")
 check(m.research(),"customer survey purchase")
 check(m.loan() and not m.loan() and m.state().debt==100,"one working-capital loan; no duplication")
 check(m.repay() and m.state().debt==0,"loan repayment")
 owner.mine.state().lifetime.ore=800;owner.mine.state().lifetime.gems=18
 check(m.ore_level()==3 and m.gem_level()==4,"ore and gem levels separately measured")
 check(JSON.parse_string(m.report()).business.history.size()==1,"report includes assessment decisions")
 bad=m.state().duplicate(true);bad.history=[{}];check(not Commerce.valid(bad),"incomplete report rows rejected")
 var experiment=m.state().duplicate(true)
 m.state().cash=1000;m.stock(0,20);var prepared=m.state().duplicate(true)
 m.state().inventory.ore.price=6;m.settle_day();var cheap=int(m.state().history.back().sold)
 owner.data.commerce=prepared.duplicate(true);m.state().inventory.ore.price=48;m.settle_day();var expensive=int(m.state().history.back().sold)
 check(cheap>expensive,"higher price reduces sales in controlled comparison")
 owner.data.commerce=experiment
 m.state().cash=0;m.state().budget=100;var unchanged=JSON.stringify(m.state());check(not m.settle_day() and unchanged==JSON.stringify(m.state()),"unfunded business day leaves state unchanged")
 owner.data.commerce=experiment.duplicate(true)
 var g=load("res://scenes/main.tscn").instantiate();root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true);root.add_child(g);current_scene=g;await process_frame;g.set_process(false);g.presentation.close();g.session_menu.resume()
 var legacy=g.legacy
 check(legacy.commerce!=null,"market wired into real game")
 var payload=legacy.bundle();check(legacy.validate(payload),"profile validates market save")
 payload.progress.commerce.cash=-9;check(not legacy.validate(payload),"malformed market import rejected")
 check(not g.can_stand_at(Vector2(-300,190)),"northwest fence blocks bypass")
 check(g.can_stand_at(g.commerce_town.DOOR),"market doorway accessible")
 check(not g.can_stand_at(Vector2(-100,600)),"market walls solid")
 check(not g.can_stand_at(g.commerce_town.CONSTRUCTION.get_center()),"future construction solid")
 legacy.commerce.open();await process_frame
 for i in 5:legacy.commerce.view.tabs.current_tab=i;await process_frame
 check(legacy.commerce.view.active,"all five market UI tabs render")
 legacy.commerce.view.close();check(not legacy.commerce.view.active,"close restores world")
 var old=legacy.bundle();old.progress.erase("commerce");check(legacy.validate(old),"old profile without market accepted")
 root.set_meta("fx_dev_match",true);var before_playtest=JSON.stringify(legacy.commerce.state());check(not legacy.commerce.loan() and not legacy.commerce.run_day() and JSON.stringify(legacy.commerce.state())==before_playtest,"Playtest blocks business progress");root.remove_meta("fx_dev_match")
 legacy.commerce.state().cash=555;legacy.pending=legacy.bundle();legacy.apply_import()
 for n in 3:await process_frame
 g=current_scene;g.set_process(false);g.presentation.close();g.session_menu.resume();legacy=g.legacy
 check(legacy.commerce.state().cash==555,"actual profile import restores market cash")
 var zip="user://v134-business.zip";check(preload("res://scripts/studio_bundle.gd").make(legacy.bundle(),zip)==OK,"profile ZIP stores market")
 var decoded=preload("res://scripts/studio_bundle.gd").read(zip);check(decoded.error.is_empty() and decoded.payload.progress.commerce.cash==555,"profile ZIP roundtrip restores market")
 legacy.enable_teacher();var disk=FileAccess.get_file_as_string(legacy.PATH)
 check(legacy.commerce.loan(),"Game Dev can experiment with business")
 check(JSON.parse_string(legacy.commerce.report()).testing_mode=="Game Dev","assessment report marks Game Dev testing")
 check(FileAccess.get_file_as_string(legacy.PATH)==disk,"Game Dev business cannot overwrite normal account")
 print("V144 MARKET REGRESSION FAILURES: ",failures);quit(1 if failures else 0)
