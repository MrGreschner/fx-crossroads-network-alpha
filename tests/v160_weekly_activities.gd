extends SceneTree
const W=preload("res://scripts/weekly_activities.gd")
const F=preload("res://scripts/fishing_catalog.gd")
var failures=0
func check(ok:bool,message:String)->void:
 if not ok:failures+=1;push_error(message)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 for n in 14:await process_frame
 g.presentation.close();g.session_menu.resume();g.set_process(false);g.legacy.set_process(false);g.lodges.set_process(false)
 var w=g.legacy.weekly;var cosmetic=g.legacy.cosmetics;cosmetic.date_for_test="2026-10-10";g.legacy.data.erase("weekly_activities")
 check(w.week()=="2026-10-04","Week starts Sunday in local calendar")
 var task=w.fishing_task();check(task==w.fishing_task(),"Fishing target stable throughout week")
 check(F.fish()[task.species].rarity in ["Common","Uncommon"] and float(task.kg)<float(F.fish()[task.species].max_kg),"Reachable non-legendary weekly catch")
 w.catch_fish({"species":task.species,"kg":float(task.kg)-.01});check(not w.earned("week_fish"),"Too-small catch does not complete goal")
 w.catch_fish({"species":task.species,"kg":task.kg});check(w.earned("week_fish"),"Exact minimum catch completes goal")
 var market=g.legacy.commerce;g.legacy.data.commerce=market.fresh();market.time_for_test=1000;market.basic_setup();market.run_day();market.time_for_test=1301;market.advance();check(w.earned("week_market"),"Profitable timed market settlement awards cosmetic")
 g.legacy.lodge_economy.medal("stand:0",1);g.legacy.lodge_economy.medal("stand:0",2);w.advance("descent",10,true);w.advance("gate",10,true)
 for id in ["week_market","week_challenge","week_descent","week_gate"]:check(w.earned(id),"Activity cosmetic earned: "+id)
 w.advance("descent",10,true);check(w.state().counts.descent==10,"Survival snapshots do not double-count")
 var card=g.legacy.card;g.legacy.data.card=card.defaults()
 card.sync_match("weekly-a","arena",false,"ram",{"kills":2},0)
 card.sync_match("weekly-a","arena",false,"ram",{"kills":2},0)
 check(w.state().counts.arena_kills==2,"Arena snapshots idempotent")
 card.sync_match("weekly-a","arena",false,"ram",{"kills":3},0);check(w.earned("week_arena_2"),"Three player KOs unlock crossblades")
 card.arena_result("weekly-a",false,"win");card.arena_result("weekly-a",false,"win");card.arena_result("weekly-b",false,"win")
 check(w.state().counts.arena_wins==2 and w.state().counts.arena_matches==2,"Only new completed matches count")
 check(w.earned("week_arena_3"),"Two wins unlock diadem")
 cosmetic.select("week_gate");check(cosmetic.effect()=="week_gate","Unlocked weekly effect selectable")
 check(g.legacy.validate(g.legacy.bundle()),"Weekly progress and selection travel in validated profile")
 var malformed={"week":"2026-10-04","counts":{"fish":"bad"}};check(not W.valid(malformed),"Malformed weekly count rejected")
 g.legacy.data.teacher=true;var before=w.state().duplicate(true);w.advance("market",1);check(w.state()==before,"Game Dev cannot earn weekly rewards");g.legacy.data.teacher=false
 root.set_meta("fx_practice_continue",true);w.advance("market",1);check(w.state()==before,"Continued practice cannot earn weekly rewards");root.remove_meta("fx_practice_continue")
 g.practice=true;w.advance("market",1);check(w.state()==before,"Training cannot earn weekly rewards");g.practice=false
 cosmetic.date_for_test="2026-10-11";cosmetic.refresh();check(w.state().counts.is_empty() and cosmetic.effect()=="","Sunday expires progress and equipped weekly effect")
 cosmetic.date_for_test="2026-10-10";g.legacy.data.erase("weekly_activities")
 var f=g.fishing;f.records().state().rod=true;g.position_in_world=Vector2(230,520);f._process(.01)
 f.activate();f.bite_at=-1;f.timer=.001;f._process(.02);check(not f.busy() and f.status in ["Not even a nibble. Try another cast.","Quiet water… no bite this time.","The fish ignored that cast. Try again."],"No guaranteed bite at full wait meter")
 f.activate();f.bite_at=.01;f._process(.02);check(f.phase=="bite","Bite can occur immediately after cast")
 for pair in [[2.3,true],[1.9,false],[1.5,true],[1.1,false],[.7,true],[.3,false]]:
  f.timer=pair[0];check(f.bite_flash()==pair[1],"Exactly three alternating bite flashes")
 f.timer=.001;f._process(.02);check(f.phase=="" and "slipped" in f.status,"Missed reaction loses fish")
 var has_bite=0;var no_bite=0
 for n in 80:
  f.rng.seed=n;f.activate()
  if f.bite_at<0:no_bite+=1
  else:has_bite+=1;check(f.bite_at>=.6 and f.bite_at<float(f.cast_spot.wait),"Random bite lies within cast")
  f.cancel("")
 check(has_bite>0 and no_bite>0,"Real casting produces both fish chances and quiet casts")
 var lodge=g.lodges;var s=lodge.state();s.apple_next=0;g.provisions.packed="berry_bun";lodge.knock_tree();check(s.apple_next==0 and g.provisions.packed=="berry_bun","Tree does not replace food or consume attempt with full slot")
 g.provisions.packed="";lodge.knock_tree();var next=float(s.apple_next);check(next>g.legacy.lodge_economy.now(),"Knock starts persistent five-minute cooldown")
 g.provisions.packed="";lodge.knock_tree();check(float(s.apple_next)==next and g.provisions.packed=="","Repeated knock cannot bypass cooldown")
 var found=false
 for n in 50:
  seed(n);s.apple_next=0;lodge.knock_tree()
  if g.provisions.packed=="lodge_apple":found=true;break
 check(found,"Tree can grant a Lodge Apple")
 var food:Dictionary=g.provisions.defs.lodge_apple;check(food.amount==20 and food.shop==false and g.provisions.paid==0,"Free apple is a modest one-use food")
 check(g.legacy.validate(g.legacy.bundle()),"Tree cooldown and packed apple export correctly")
 for point in [lodge.CHALLENGE,lodge.GATHER,lodge.APPLE_TREE+Vector2(0,25)]:check(g.clear_of_obstacles(point,14),"Lodge doors/tree reachable")
 check(lodge.blocked(lodge.CHALLENGE-Vector2(190,120)),"Expanded challenge wing blocks movement")
 check(lodge.visual_textures.apple_tree!=null,"New tree art loads from embedded source")
 w.open_board();check(g.presentation.page=="weekly_activities","Weekly board opens")
 g.presentation.close();cosmetic.open_picker();check(is_instance_valid(cosmetic.picker),"Scrollable cosmetics picker opens");cosmetic.close_picker()
 g.queue_free();for n in 4:await process_frame
 print("Weekly and fishing v160: "+str(failures)+" failures");quit(failures)
