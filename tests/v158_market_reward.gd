extends SceneTree
var failures=0
func check(ok:bool,message:String)->void:
 if not ok:failures+=1;print("FAIL: ",message)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 for n in 12:await process_frame
 g.presentation.close();g.session_menu.resume();g.set_process(false);g.legacy.set_process(false)
 var m=g.legacy.commerce;g.legacy.data.commerce=m.fresh();m.reward_date_for_test="2026-10-09";m.time_for_test=1000
 check(m.basic_setup() and m.run_day(),"starter business opens")
 m.time_for_test=1299;m.advance();check(m.supply_reward().pending==0,"no early reward")
 m.time_for_test=1301;m.advance();check(m.supply_reward().pending==20,"profitable timed day earns reward")
 check(not m.earn_supply(100,1),"same real day cannot earn twice")
 check(not m.earn_supply(-5,1) and not m.earn_supply(10,0),"loss and no sales excluded")
 var coins=g.gold;check(m.claim_supply(),"claim in town")
 check(g.gold==coins+20 and m.supply_reward().pending==0,"claim credits exactly 20")
 check(not m.claim_supply() and g.gold==coins+20,"repeat claim blocked")
 for n in 4:m.reward_date_for_test="2026-10-"+str(10+n);m.earn_supply(10,1)
 check(m.supply_reward().pending==60,"bank capped at 60")
 g.mode="run";check(not m.claim_supply(),"cannot claim during combat");g.mode="town"
 check(m.valid(m.state()) and g.legacy.validate(g.legacy.bundle()),"profile portability")
 g.legacy.data.teacher=true;m.supply_reward().pending=0;m.reward_date_for_test="2026-10-20"
 check(not m.earn_supply(100,1),"GameDev cannot earn real reward");g.legacy.data.teacher=false
 m.open();await process_frame;check(m.view.page.get_child_count()>0,"reward card renders")
 m.view.close();g.queue_free()
 for n in 4:await process_frame
 print("v158 market reward: ",failures," failures");quit(failures)
