extends SceneTree
var failures:=0
func check(value:bool,message:String)->void:
 if not value:failures+=1;print("FAIL: ",message)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g)
 for n in 8:await process_frame
 g.set_process(false);g.legacy.set_process(false);g.presentation.asked=true;g.presentation.close();g.session_menu.resume()
 g.legacy.data=g.legacy.defaults();g.legacy.mine.setup(g.legacy);g.legacy.clear_adventure("ram","grove")
 g.selected_character="cat";g.start_run(false,"quarry");g.dealt_damage=99;g.level=7;g.health=0;g.finish_run(false)
 var found:=false
 for row in g.presentation.modal.get_child(0).get_children():
  if row is HBoxContainer:
   for child in row.get_children():
    if child is Button and child.text=="Play again":found=true
 check(found,"results include replay button")
 var before_runs:int=g.profile.runs;g.presentation.replay_realm()
 check(g.region_id=="quarry" and g.mode=="run" and g.character_id=="cat","replay same realm and hero directly")
 check(g.level==1 and g.health==g.max_health() and g.dealt_damage==0 and g.menu=="" and g.presentation.page=="","fresh run resets health, levels, statistics and modal")
 check(g.profile.runs==before_runs and not g.respawn_clinic,"replay does not double-record prior result or carry clinic flag")
 g.queue_free();await process_frame
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);await process_frame;a.set_process(false);a.party_tools.set_process(false);a.started=true
 var overlay=a.countdown_overlay
 a.start_countdown=5;overlay.update_view();check(overlay.card.visible and overlay.number.text=="5" and overlay.layer>46,"large countdown appears above lobby and result overlays")
 var yellow:Color=overlay.number.modulate;a.start_countdown=3;overlay.update_view();check(overlay.number.text=="3" and overlay.number.modulate!=yellow,"last three seconds change to red")
 a.start_countdown=0;overlay.update_view();check(not overlay.card.visible,"countdown disappears as play begins")
 a.queue_free();await process_frame;print("v104 replay/countdown failures: ",failures);quit(1 if failures else 0)
