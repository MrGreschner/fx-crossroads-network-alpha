extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func clear_group(game:Node,token:String)->void:
 for n in range(game.enemies.size()-1,-1,-1):
  if str(game.enemies[n].get("quest_group",""))==token:game.damage_enemy(n,100000);game.menu=""
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
 var roster:Array=game.manifest.characters
 check(roster.find("veyra")==roster.find("snowman")+1 and roster.find("pippa")==roster.find("magnet")+1,"hero order")
 game.selected_character="dustdevil";game.start_run(false,"practice")
 check(game.practice and game.enemies.size()==6,"five fixed targets and one moving target")
 var runner:Dictionary={};var center:=false
 for foe in game.enemies:
  if foe.type=="training_runner":runner=foe
  if foe.pos==Vector2(1100,600):center=true
 check(center,"central bounce target")
 var old:Vector2=runner.pos;game.training_yard.step(game,.5);check(runner.pos!=old,"target moves")
 game.position_in_world=Vector2(1390,600);game.training_yard.step(game,2)
 check(game.enemy_shots.size()==2,"both launchers fire real projectiles")
 game.health=2;game.take_player_damage(50);check(game.health>=1,"practice shots are nonlethal")
 game.training_yard.step(game,1);check(game.health>1,"practice health regenerates")
 game.enemy_shots.clear();game.training_yard.reset();game.position_in_world=Vector2(1400,410)
 var kit=game.adventure.combat.v56
 kit.holding("solo",true,Vector2.RIGHT);game.adventure.combat.cast("solo",game.hero.primary,Vector2.RIGHT,12)
 game.training_yard.step(game,1.1);game.update_enemy_shots(.3)
 check(kit.intakes.solo.has("captured"),"practice launcher supports catching")
 game.start_run(false,"wayfarer");var q=game.adventure.quests
 check(q.data.quests.size()==5 and q.grid.region.size.x==320,"five quests in expanded world")
 check(not q.unlocked(q.data.quests[3]),"summit has prerequisite")
 q.states.waylights.done=true;q.states.mill.done=true;q.states.erase("summit_bell");q.states.erase("skyworks");q.save()
 game.start_run(false,"wayfarer")
 check(q.states.waylights.done and q.states.has("summit_bell") and not q.states.summit_bell.done,"old saves gain quests without losing progress")
 for index in [3,4]:
  var quest:Dictionary=q.data.quests[index];var npc:Dictionary={}
  for person in q.data.npcs:
   if person.id==quest.npc:npc=person
  game.position_in_world=q.v(npc.pos);q.clock+=1;q.interact("solo")
  check(q.states[quest.id].accepted,"new quest accepted")
  for stage_index in range(quest.stages.size()-1):
   var stage:Dictionary=quest.stages[stage_index]
   clear_group(game,str(quest.id)+":"+str(stage_index))
   if stage.type=="clear":q.step(.01)
   else:
    for target in stage.get("targets",[]):
     game.position_in_world=q.v(target.pos);q.clock+=1;q.interact("solo")
   check(int(q.states[quest.id].stage)==stage_index+1,"new objective advances")
  game.position_in_world=q.v(npc.pos);q.clock+=1;q.interact("solo");var paid:float=game.gold
  q.clock+=1;q.interact("solo");check(q.states[quest.id].done and game.gold==paid,"reward paid once")
 game.start_run(false,"wayfarer");check(q.states.summit_bell.done and q.states.skyworks.done,"new progress survives reload")
 game.enemies.clear();game.position_in_world=Vector2(14600,780);game.adventure.spawn("summit_golem",Vector2(14600,760),720,false)
 var golem:Dictionary=game.enemies[-1];golem.ice_cooldown=0;q.step_golems(.01)
 check(q.golem_warnings().size()==1,"golem telegraphs slam")
 var hp:float=game.health;q.step_golems(1)
 check(game.health<hp and game.adventure.combat.effect_time("p:solo","slow")>0,"slam hurts and slows")
 golem.ice_cooldown=0;q.step_golems(.01);game.position_in_world=Vector2(14900,780);hp=game.health;q.step_golems(1);check(game.health==hp,"telegraph can be dodged")
 var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame;party.set_process(false);party._set_mode("defense");party._solo();party._set_mode("coop")
 for n in party.realm_picker.item_count:
  if str(party.realm_picker.get_item_metadata(n))=="wayfarer":party.realm_picker.select(n)
 party._start_match();party.adventure.step(.01);var pq=party.adventure.quests
 pq.states.waylights.done=true;party.positions["partner"]=Vector2(1250,1750);party.health["partner"]=100;party.levels["partner"]=3;party.gold["partner"]=100;pq.clock+=1;pq.interact("partner")
 var packet:Dictionary=party._snapshot()
 check(packet.adventure.quests.states.summit_bell.accepted,"partner accepts shared summit quest")
 check(pq.data.quests.size()==5 and pq.grid.region.size.x==320,"co-op expanded map")
 for voice in game.journey.voices:voice.stop()
 for voice in party.journey.voices:voice.stop()
 game.queue_free();party.queue_free();await create_timer(.3).timeout
 print("v57: ",failures," failures");quit(1 if failures else 0)
