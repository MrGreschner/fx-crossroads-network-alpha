extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func cell(p:Vector2)->Vector2i:return Vector2i(floori(p.x/50),floori(p.y/50))
func kill_group(game:Node,key:String)->void:
 for n in range(game.enemies.size()-1,-1,-1):
  if str(game.enemies[n].get("school_group",""))==key:game.damage_enemy(n,100000)
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
 for id in ["elementary","middle_school","high_school"]:
  game.start_run(false,id);var school=game.adventure.school;school.step(.01)
  check(school.active and game.enemies.size()>0,id+" starts authored patrol, not normal waves")
  check(school.can_stand(school.v(school.data.spawn)),id+" clear street spawn")
  var foyer:Dictionary=school.data.rooms.filter(func(room:Dictionary)->bool:return str(room.id)=="foyer")[0]
  check(school.grid.get_id_path(cell(school.v(school.data.spawn)),cell(school.rect(foyer.rect).get_center())).is_empty(),id+" closed front entrance cannot be walked around")
  for door in school.data.doors:school.open_door(door)
  for group in school.data.groups:
   for entry in school.data.groups[group]:
    var p:Vector2=school.v(entry.pos);check(school.can_stand(p),id+" clear "+str(entry.type)+" at "+str(p))
    var start:Vector2=school.v(school.data.spawn)
    if school.floor_id(p)==1:start=school.v(school.data.routes[0].end)
    check(not school.grid.get_id_path(cell(start),cell(p)).is_empty(),id+" reachable enemy "+str(p))
  for route in school.data.routes:check(school.can_stand(school.v(route.pos)) and school.can_stand(school.v(route.end)),id+" both staircase landings clear")
 game.start_run(false,"elementary");var school=game.adventure.school;var combat=game.adventure.combat;school.step(.01)
 var front:Dictionary=school.data.doors[0];game.position_in_world=school.v(front.pos)+Vector2(0,80);check(school.interact("solo") and school.opened.front,"front entrance opens via actual interact")
 check(not school.opened.playground,"playground starts sealed")
 for door in school.data.doors:
  if str(door.id)!="playground":school.open_door(door)
 check(school.grid.get_id_path(cell(game.position_in_world),cell(Vector2(3300,620))).is_empty(),"playground seal has no walk-around shortcut")
 kill_group(game,"school");school.step(.01);check(school.stage==1 and school.opened.playground,"classroom clear opens playground")
 game.position_in_world=Vector2(3350,680);school.step(.01);check(game.enemies.size()==1 and game.enemies[0].type=="recess_ringleader","playground guardian starts when entering yard")
 kill_group(game,"boss:recess");school.step(.01);check(school.stage==2 and game.enemies.size()==8 and not game.boss_defeated,"midboss spawns return patrol without completing run")
 school.step(.01);check(school.stage==2 and game.enemies.size()==8,"bus waits for street; return patrol is optional")
 game.position_in_world=Vector2(3800,5270);school.step(.01);school.step(.01);check(school.stage==3 and game.enemies.size()==9 and game.enemies[-1].type=="yellow_bus" and game.enemies[-1].hit_radius==85,"street entry spawns bus with optional patrol still alive");kill_group(game,"return")
 var bus:Dictionary=game.enemies[0];bus.school_turn=1;bus.school_timer=0;school.step_enemies(.01);check(game.enemies.size()>1,"bus releases melee minions")
 game.damage_enemy(game.enemies.size()-1,100000);school.step(.01);check(not school.done and not school.boss_dead.has("bus"),"bus passenger defeat cannot complete the boss")
 for n in 6:bus.school_turn=1;bus.school_timer=0;school.step_enemies(.01)
 check(game.enemies.size()<=9,"bus minions capped at eight")
 kill_group(game,"boss:bus");school.step(.01);check(school.done and game.boss_defeated,"bus defeat clears elementary")
 game.position_in_world=school.v(school.data.exit);school.interact("solo");check(game.presentation.page=="results" and game.result_text.begins_with("CLEARED"),"street exit awards successful clear")
 game.start_run(false,"middle_school");school=game.adventure.school;school.step(.01);kill_group(game,"arrival");school.step(.01)
 check(school.stage==1 and game.enemies.size()==14,"middle school opens three gear wings")
 var gear:Dictionary=school.data.gears[0];game.position_in_world=school.v(gear.pos);school.interact("solo");check(school.collected.is_empty(),"guarded gear cannot be collected")
 for entry in school.data.gears:
  kill_group(game,str(entry.id));game.position_in_world=school.v(entry.pos);school.clock+=1;check(school.interact("solo"),"collect cleared bell gear")
 school.step(.01);check(school.stage==2 and school.opened.canteen,"all three gears open cafeteria")
 game.position_in_world=Vector2(4450,4550);school.step(.01);kill_group(game,"boss:lunch");school.step(.01)
 check(school.stage==3 and game.enemies.size()==6,"cafeteria guardian opens rooftop patrol")
 game.position_in_world=Vector2(4670,3500);school.clock+=1;check(school.interact("solo") and school.floor_id(game.position_in_world)==1,"stairs go to roof")
 kill_group(game,"roof_patrol");school.step(.01);school.step(.01);check(school.stage==4 and game.enemies.size()==1 and game.enemies[0].type=="bellwork_colossus","roof guardian appears after rooftop clear")
 kill_group(game,"boss:bell");school.step(.01);check(school.done,"middle school completes after clock boss")
 game.position_in_world=Vector2(6300,3100);school.clock+=1;school.interact("solo");check(school.floor_id(game.position_in_world)==0,"roof stairs remain usable after clear")
 game.start_run(false,"high_school");school=game.adventure.school;school.step(.01)
 check(game.enemies[0].type=="gravel_skater","high school first enemy is skater")
 kill_group(game,"arrival");school.step(.01);check(game.enemies.size()==15 and school.opened.gym and school.opened.drama and school.opened.kitchen,"three high school wings unlock")
 for entry in school.data.departments:
  kill_group(game,str(entry.id));school.step(.01);check(school.spawned.has("boss:"+str(entry.id)),"department guardian follows its patrol")
  kill_group(game,"boss:"+str(entry.id));school.step(.01)
 check(school.completed.has("departments") and game.enemies.size()==8 and not game.boss_defeated,"all department bosses unlock upstairs without premature clear")
 game.position_in_world=Vector2(4370,2870);school.clock+=1;school.interact("solo");check(school.floor_id(game.position_in_world)==1,"high school upper floor works")
 kill_group(game,"upper");school.step(.01);check(school.opened.exam and school.exam_choice.is_empty(),"classroom opens; exam not chosen before entering")
 game.position_in_world=Vector2(12050,1700);school.step(.01);var selected:String=school.exam_choice
 check(selected in school.EXAMS and game.enemies.size()==1,"entering classroom selects one final exam")
 school.step(.01);school.choose_exam(0);check(school.exam_choice==selected and game.enemies.size()==1,"same exam persists without reroll/duplicate")
 for kind in school.EXAMS:
  game.enemies.clear();school.hazards.clear();combat.projectiles.clear();school.exam_choice=kind;var enemy:Dictionary=school.spawn_foe(kind,Vector2(12050,1550),"boss:final",true);game.position_in_world=Vector2(12250,1650)
  for n in 4:school.exam_attack(enemy,game.position_in_world,n)
  check(school.hazards.size()>0 and (combat.projectiles.size()>0 or bool(enemy.get("buried",false))),kind+" four patterns produce attacks")
  if kind=="exam_english":var hp:float=enemy.hp;game.damage_enemy(game.enemies.size()-1,100);check(enemy.hp==hp,"English ghost phase untargetable")
 game.enemies.clear();school.hazards.clear();combat.projectiles.clear();var skater:Dictionary=school.spawn_foe("gravel_skater",Vector2(3500,5350),"test");game.position_in_world=Vector2(3800,5350);skater.school_turn=2;skater.school_timer=0
 school.step_enemies(.01);check(school.hazards.size()==1 and school.v(school.hazards[0].end).distance_to(Vector2(4100,5350))<5,"skater locks endpoint equal distance beyond player")
 var health_before:float=game.health;school.step_hazards(.7);school.step_hazards(.3);check(skater.pos.distance_to(game.position_in_world)>250 and game.health<health_before,"skater passes through, damages and finishes away")
 game.health=100;school.damage_player("solo",1,{"burn_duration":5,"burn_damage":2});check(combat.effect_time("p:solo","burn")>0,"fire exam applies burn")
 school.damage_player("solo",1,{"slow_duration":3,"slow_factor":.5});check(combat.speed_factor("p:solo")==.5,"ice exam applies strong slow")
 school.damage_player("solo",1,{"poison_duration":5,"poison_damage":2});check(combat.effect_time("p:solo","poison")>0,"science exam applies poison")
 var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame;party.set_process(false);party._set_mode("defense");party._solo();party._set_mode("coop")
 for n in party.realm_picker.item_count:
  if str(party.realm_picker.get_item_metadata(n))=="high_school":party.realm_picker.select(n)
 party._start_match();party.adventure.step(.01);check(party.adventure.school.active and party.opponents.size()==6,"co-op begins school authored sequence")
 for slot in 4:check(party.adventure.school.can_stand(party._spawn_player(slot)),"four co-op starts clear")
 var shared=party.adventure.school;shared.choose_exam(2);shared.completed.append("arrival");shared.open_door(shared.data.doors[0]);var packet:Dictionary=party._snapshot()
 var serialized:Dictionary=JSON.parse_string(JSON.stringify(packet.adventure.school));check(serialized.exam_choice=="exam_history" and serialized.opened.front,"exam and doors serialize")
 shared.receive(serialized);check(shared.exam_choice=="exam_history" and shared.opened.front,"shared school state round-trips")
 for voice in game.journey.voices:voice.stop()
 for voice in party.journey.voices:voice.stop()
 game.queue_free();party.queue_free();await create_timer(.3).timeout
 print("V44 FAILURES: "+str(failures));quit(failures)
