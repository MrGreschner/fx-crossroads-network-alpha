extends SceneTree
var failures=0
const Commerce=preload("res://scripts/commerce.gd")
const Mine=preload("res://scripts/idle_mine.gd")
class Owner extends Node:
 var data={"teacher":false}
 var mine:RefCounted
 func save()->void:pass
func check(value:bool,label:String)->void:
 print("PASS • " if value else "FAIL • ",label)
 if not value:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 var owner=Owner.new();root.add_child(owner);owner.mine=Mine.new();owner.mine.time_for_test=1000000;owner.mine.setup(owner);owner.mine.commission();owner.mine.state().wallet.ore=1000
 var m=Commerce.new();m.time_for_test=1000000;m.setup(owner);m.stock(0,20)
 check(m.set_duration(300) and not m.set_duration(299) and not m.set_duration(86401),"business day range 5 minutes to 24 hours")
 check(m.run_day() and m.busy() and m.state().day==0 and m.state().revenue==0,"start trading does not settle instantly")
 check(not m.run_day() and not m.stock(0,1) and not m.upgrade("shop") and not m.loan() and not m.transfer(1),"one trading day; spending and decisions locked")
 check(not m.set_duration(600),"duration locked for active day")
 m.time_for_test+=299;m.advance();check(m.state().day==0,"no early settlement")
 var saved=JSON.parse_string(JSON.stringify(owner.data));check(Commerce.valid(saved.commerce),"timed profile is portable")
 owner.data=saved;m.time_for_test+=1;m.advance();check(m.state().day==1 and not m.busy() and m.state().revenue>0,"saved countdown settles at deadline")
 var revenue=m.state().revenue;m.time_for_test+=86400;m.advance();check(m.state().day==1 and m.state().revenue==revenue,"offline completion happens once; no automatic new days")
 check(m.set_duration(86400),"24 hour setting")
 m.stock(0,20);m.run_day();m.time_for_test+=86400;m.advance();check(m.state().day==2,"24 hour settlement")
 var old=m.state().duplicate(true);old.erase("day_seconds");old.erase("trading");owner.data.commerce=old;m.setup(owner);check(m.state().day==2 and m.state().day_seconds==300,"old commerce save migrates without losing sales")
 var bad=m.state().duplicate(true);bad.trading={"start":1,"end":10,"seconds":300};check(not Commerce.valid(bad),"malformed timer rejected")
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 for n in 3:await process_frame
 g.set_process(false);g.presentation.close();g.session_menu.resume()
 g.legacy.answer("media");check(g.media.active and not preload("res://scripts/profile_store.gd").testing(),"Media enables without disabling normal progress")
 for z in [.75,1.0,1.25,1.5]:
  g.media.zoom=z;g.update_camera();var p=Vector2(340,440);var world=p+g.camera;var projected=g.media.offset()+p*z
  check(g.media.screen_point(projected).distance_to(p)<.001,"zoom inverse mapping "+str(z))
  check(Commerce.valid(g.legacy.commerce.state()),"camera does not affect account finances")
 g.legacy.answer("gameDev");g.legacy.answer("R4ms");check(not root.get_node("FXDevSession").active,"old Game Dev password rejected")
 g.legacy.answer("gameDev");g.legacy.answer("R4ms!90");check(root.get_node("FXDevSession").active,"new Game Dev password accepted")
 check(g.media.enabled(),"Game Dev has camera controls")
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);current_scene=a;g.queue_free()
 for n in 4:await process_frame
 a.set_process(false);a.started=true;a.local_pos=Vector2(2500,1800);a.media.enable()
 for z in [.75,1.0,1.25,1.5]:
  a.media.zoom=z;a.media.refresh_arcade()
  check((a.camera+a.VIEW/z*.5).distance_to(a.local_pos)<.001,"multiplayer camera centered "+str(z))
 a.session_menu.page="main";a.media.update_visible();check(not a.media.panel.visible,"camera panel hidden behind multiplayer menus")
 print("V135 FAILURES: ",failures);quit(failures)
