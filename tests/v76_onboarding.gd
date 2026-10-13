extends SceneTree
var failures:=0
func check(ok:bool,message:String)->void:
 if not ok:failures+=1;print("FAIL: ",message)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_process(false);g.presentation.set_process(false);g.legacy.set_process(false);g.presentation.asked=true
 g.profile={"runs":0,"records":{},"selected_hero":"ram"};g.legacy.data=g.legacy.defaults()
 g.presentation.starter();await process_frame
 var grid:GridContainer=g.presentation.content.get_child(1)
 check(grid.get_child_count()==9,"first nine heroes, no second page")
 g.mobile.enabled=true;g.mobile._process(0)
 check(g.mobile.blocked() and not g.mobile.panel.visible,"tutorial selector owns touch input")
 g.presentation.close()
 var original_damage:float=g.legacy.data.tasks.damage
 var original_clears:int=g.legacy.data.tasks.clears
 for id in g.manifest.characters.slice(0,9):
  g.loadout.assign(["aegis"]);g.provisions.packed="berry_bun"
  g.presentation.starter();g.presentation.content.get_child(1).get_child((g.manifest.characters as Array).find(id)).pressed.emit();check(g.character_id==str(id),"picker callback chooses "+str(id));check(g.tutorial.active and g.mode=="run" and g.region_id=="first_steps","tutorial starts "+str(id))
  check(g.inventory.is_empty() and g.provisions.packed.is_empty(),"supplies isolated")
  for wave in 4:
   g.tutorial.step(2)
   check(g.enemies.size()==(3 if wave==0 else 4 if wave<3 else 1),"wave size "+str(wave))
   if wave==3:check(g.level==6 and g.enemies[0].boss,"special ready before mini-boss")
   while not g.enemies.is_empty():g.damage_enemy(g.enemies.size()-1,10000)
  g.tutorial.step(.01)
  check(not g.tutorial.active and g.mode=="town" and bool(g.profile.tutorial_seen),"completed tutorial returns to town")
  check(g.loadout==["aegis"] and g.provisions.packed=="berry_bun","packed supplies restored")
  check(g.health==g.max_health(),"town health restored")
  g.presentation.close()
 check(g.legacy.data.tasks.damage==original_damage and g.legacy.data.tasks.clears==original_clears,"tutorial does not farm mastery")
 check(int(g.profile.runs)==0,"tutorial does not create speedrun record")
 g.tutorial.start("ram");g._unhandled_input(InputEventKey.new());g.tutorial.finish(false,true)
 check(g.mode=="town" and g.presentation.page.is_empty(),"skip exits directly")
 g.save_profile();g.profile.clear();g.load_profile();check(bool(g.profile.tutorial_seen),"tutorial choice survives reload")
 g.presentation.adventures();await process_frame
 check(g.presentation.content.get_child(1).get_child_count()==6,"all adventure types plus tutorial")
 g.presentation.realms();await process_frame
 var realms:GridContainer=g.presentation.content.get_child(0);check(realms.get_child_count()>20,"scrollable realm choices")
 g.presentation.close();g.start_run(false,"grove");g.run_time=95;g.kills=12;g.dealt_damage=800;g.finish_run(true);await process_frame
 check(g.presentation.page=="results","victory opens new result card")
 check(g.presentation.content.get_child_count()>=5,"victory has mastery and rewards")
 g.presentation.return_to_town();check(g.mode=="town" and g.menu.is_empty(),"result back-to-town action")
 g.legacy.data.tasks.clears=1;check(not g.town_life.recognition(g,4).is_empty(),"resident recognises actual clear")
 g.legacy.data.teacher=true;check(g.town_life.recognition(g,4).is_empty(),"teacher unlocks do not invent accomplishments")
 var muted:bool=AudioServer.is_bus_mute(0);g.presentation.toggle_sound();check(AudioServer.is_bus_mute(0)!=muted,"visible mute controls all audio");g.presentation.toggle_sound()
 g.queue_free();await process_frame;await create_timer(.5).timeout
 print("v76 onboarding/UI failures: ",failures);quit(failures)
