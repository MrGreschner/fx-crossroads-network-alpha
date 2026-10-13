extends SceneTree
var checks=0
var failures=0
func check(ok:bool,label:String)->void:
 checks+=1;print("PASS • " if ok else "FAIL • ",label)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 for n in 8:await process_frame
 g.set_process(false);g.legacy.set_process(false);g.presentation.close();g.session_menu.resume();g.menu=""
 var l=g.legacy;l.data=l.defaults();l.mine.setup(l);l.commerce.setup(l)
 var m=l.commerce;var wallet=l.mine.state().wallet.duplicate(true)
 check(g.gold==100,"combat starts with 100 CC")
 check(not m.start_problem().is_empty(),"empty market explains missing stock")
 check(m.basic_setup(),"starter setup works without commissioning mine")
 check(m.state().cash==130 and m.state().inventory.ore.units==5,"starter pack costs 30 market cash for five units")
 check(l.mine.state().wallet==wallet and g.gold==100,"starter does not debit Mine Gold or CC")
 check(m.basic_setup() and m.state().cash==130,"repeated setup does not double buy stocked goods")
 check(m.start_problem().is_empty() and m.run_day() and m.busy(),"basic strategy starts timed business day")
 check(not m.basic_setup(),"cannot overwrite trading day")
 m.state().pending={};m.state().inventory.ore.units=0;m.state().inventory.ore.book=0;m.state().cash=31
 check(not m.basic_setup() and m.state().cash==31,"starter protects operating reserve when unaffordable")
 l.data.tasks.food=2;l.data.tasks.clears=3;l.mine.state().wallet.ore=0
 check(not l.town_ready("market"),"achievement alone cannot bypass material requirement")
 l.mine.state().wallet.gold=20;l.mine.state().wallet.ore=10
 check(l.town_ready("market"),"small collected material cost unlocks town project")
 l.build_project("market")
 check(l.data.town.market and l.mine.state().wallet.gold==10 and l.mine.state().wallet.ore==5 and g.gold==100,"construction consumes mine resources only")
 l.build_project("market");check(l.mine.state().wallet.gold==10,"completed project cannot charge twice")
 l.data.tasks.talk=3;l.data.tasks.water=3;l.mine.state().wallet.gold=0;l.mine.state().wallet.ore=0
 check(l.town_ready("flowers"),"first community flower project stays free")
 check(g.cosmetic_town.blocked(Vector2(540,1000)) and not g.cosmetic_town.blocked(g.cosmetic_town.ENTRY),"Atelier door reachable and building solid")
 l.open_page("cosmetics");check(l.page=="cosmetics" and l.body.get_child_count()>0,"Atelier opens earned cosmetics UI")
 l.root.hide();g.menu=""
 m.open();for n in 4:await process_frame
 check(m.view!=null and m.view.active,"market onboarding screen opens")
 m.view.close()
 print("v149: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
