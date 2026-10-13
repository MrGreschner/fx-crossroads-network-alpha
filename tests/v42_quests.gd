extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func cell(point:Vector2)->Vector2i:return Vector2i(floori(point.x/50),floori(point.y/50))
func clear_group(game:Node,token:String)->void:
 for n in range(game.enemies.size()-1,-1,-1):
  if str(game.enemies[n].get("quest_group",""))==token:game.damage_enemy(n,100000);game.menu=""
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
 check(game.manifest.regions.find("moonveil")<game.manifest.regions.find("lantern_marsh") and game.manifest.regions.find("moonveil")<game.manifest.regions.find("silverfall"),"medium realm moved ahead of hard realms")
 check(not game.manifest.regions.has("wayfarer"),"quests have separate entrance from realm list")
 game.selected_character="cat";game.position_in_world=Vector2(2100,1130);game.set_process(true)
 var input:=InputEventKey.new();input.keycode=KEY_E;input.physical_keycode=KEY_E;input.pressed=true;Input.parse_input_event(input);await process_frame;await process_frame
 check(game.menu=="quest_entrance","real town input opens forest quest entrance")
 input.pressed=false;Input.parse_input_event(input);game.set_process(false)
 input=InputEventKey.new();input.keycode=KEY_1;input.pressed=true;game._unhandled_input(input);game.adventure.step(.01)
 var quest=game.adventure.quests
 check(quest.active and game.hero.id=="cat" and game.level>=3,"quest expedition accepts any hero with secondary unlocked")
 check(quest.data.quests.size()==5 and quest.props.size()>200,"five authored quests and forest scenery")
 for npc in quest.data.npcs:check(quest.can_stand(quest.v(npc.pos)),"NPC accessible "+str(npc.id))
 for route in quest.routes():
  check(quest.can_stand(route.pos) and quest.can_stand(route.end),"dungeon entrances and arrivals clear")
  var start:=cell(Vector2(1400,1800)) if route.pos.y<6500 else cell(route.pos)
  check(not quest.grid.get_id_path(start,cell(route.pos)).is_empty(),"surface entrances reachable")
 for q in quest.data.quests:
  for stage in q.stages:
   for target in stage.get("targets",[]):
    var point:Vector2=quest.v(target.pos)
    var start:=cell(Vector2(1000,8100)) if point.y>6500 and point.x<5000 else cell(Vector2(5600,8150)) if point.y>6500 else cell(Vector2(1400,1800))
    check(quest.can_stand(point) and not quest.grid.get_id_path(start,cell(point)).is_empty(),"every quest objective reachable: "+str(target.id))
   for enemy in stage.get("encounters",[]):check(quest.can_stand(quest.v(enemy.pos)),"quest enemy starts clear")
 game.position_in_world=Vector2(1100,2250);quest.clock+=1;quest.interact("solo");check(not bool(quest.states.roots.accepted),"final quest requires first two")
 game.position_in_world=Vector2(1450,1400);quest.clock+=1;quest.interact("solo");check(bool(quest.states.waylights.accepted),"NPC offers first quest")
 game.mobile.enabled=true;quest.journal_key(KEY_Q);check(game.mobile.active_menu()=="quest_journal","mobile journal has its own controls")
 quest.journal_key(KEY_ESCAPE);check(game.menu=="" and not quest.journal,"closing journal restores gameplay")
 game.position_in_world=Vector2(3400,1750);quest.clock+=1;quest.interact("solo");check(quest.states.waylights.targets.is_empty(),"guarded item cannot be collected early")
 clear_group(game,"waylights:0")
 for target in quest.data.quests[0].stages[0].targets:
  game.position_in_world=quest.v(target.pos);quest.clock+=1;quest.interact("solo")
 check(int(quest.states.waylights.stage)==1,"three glimmers advance to return step")
 game.start_run(false,"wayfarer");game.adventure.step(.01);check(int(quest.states.waylights.stage)==1 and bool(quest.states.waylights.accepted),"unfinished quest stage survives re-entry")
 game.position_in_world=Vector2(1450,1400);quest.clock+=1;quest.interact("solo");var paid:float=game.gold
 quest.clock+=1;quest.interact("solo");check(bool(quest.states.waylights.done) and game.gold==paid,"turn-in reward is paid once")
 game.position_in_world=Vector2(1850,2000);quest.clock+=1;quest.interact("solo")
 game.position_in_world=Vector2(4600,3650);quest.clock+=1;quest.interact("solo")
 check(int(quest.states.mill.stage)==1,"waterwheel triggers mill encounter")
 clear_group(game,"mill:1");quest.step(.01);check(int(quest.states.mill.stage)==2,"clear only relevant encounter completes mill battle")
 game.position_in_world=Vector2(1850,2000);quest.clock+=1;quest.interact("solo")
 game.position_in_world=Vector2(1100,2250);quest.clock+=1;quest.interact("solo");check(bool(quest.states.roots.accepted),"two completed quests unlock third")
 clear_group(game,"roots:0")
 for target in quest.data.quests[2].stages[0].targets:
  game.position_in_world=quest.v(target.pos);quest.clock+=1;quest.interact("solo")
 check(int(quest.states.roots.stage)==1,"three dungeon seals awaken keeper")
 game.position_in_world=Vector2(8450,10000)
 for enemy in game.enemies:
  if enemy.type=="rootbound_keeper":enemy.skill_timer=0
 for n in 3:
  for enemy in game.enemies:
   if enemy.type=="rootbound_keeper":enemy.skill_timer=0
  game.adventure.step(.01)
 check(game.adventure.warnings.size()>0 and game.adventure.lob_shots.size()>0 and game.adventure.combat.projectiles.size()>0,"quest keeper uses warned charge, lob volley and weaving fan")
 clear_group(game,"roots:1");quest.step(.01)
 game.position_in_world=Vector2(8550,10000);quest.clock+=1;quest.interact("solo")
 game.position_in_world=Vector2(1100,2250);quest.clock+=1;quest.interact("solo")
 check(quest.completed_count()==3,"all three quest chains can complete")
 game.start_run(false,"wayfarer");check(quest.completed_count()==3,"progress survives reload without duplicate rewards")
 game.adventure.step(.01);game.position_in_world=Vector2(6800,1900);quest.clock+=1;quest.interact("solo");check(game.position_in_world.y>7400,"dungeon travel uses actual interaction")
 quest.clock+=1;game.position_in_world=Vector2(1000,8000);quest.interact("solo");check(game.position_in_world.y<6500,"dungeon exit returns safely")
 game.start_run(false,"silverfall");game.adventure.immersive.initialize();game.enemies.clear();game.position_in_world=Vector2(1100,1300)
 var tide=game.adventure.immersive.spawn("tidebinder",Vector2(1350,1300));game.adventure.immersive.skill(tide,game.position_in_world)
 check(game.adventure.immersive.attacks.size()>0,"Silverfall tidebinder warns its water attack")
 game.start_run(false,"lantern_marsh");game.adventure.immersive.initialize();game.enemies.clear();game.position_in_world=Vector2(2000,900)
 var bell=game.adventure.immersive.spawn("bog_bellringer",Vector2(2300,900));game.adventure.immersive.skill(bell,game.position_in_world)
 check(game.adventure.immersive.attacks.size()>0,"Marsh bellringer warns its root attack")
 var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame;party.set_process(false);party._set_mode("defense");party._solo();party._set_mode("coop")
 for n in party.realm_picker.item_count:
  if str(party.realm_picker.get_item_metadata(n))=="wayfarer":party.realm_picker.select(n)
 party._start_match();party.adventure.step(.01)
 check(party.adventure.quests.active and party.levels[party.my_id]>=3,"quest world works with authoritative party controller")
 party.positions["partner"]=Vector2(1465,1400);party.health["partner"]=100;party.levels["partner"]=3;party.gold["partner"]=100
 party.adventure.quests.interact("partner");check(bool(party.adventure.quests.states.waylights.accepted),"either partner can accept shared quest")
 var packet:Dictionary=party._snapshot();check(packet.adventure.quests.states.waylights.accepted,"party quest progress synchronized")
 var first:Dictionary={}
 for enemy in packet.enemies:
  if enemy.get("quest_group","")=="waylights:0":first=enemy;break
 check(not first.is_empty(),"quest enemy groups synchronized for guest guidance")
 party.opponents.clear();party._simulate(.01);check(party.started and party.wave==0,"quest world does not advance normal realm waves or auto-complete")
 for voice in game.journey.voices:voice.stop()
 for voice in party.journey.voices:voice.stop()
 game.queue_free();party.queue_free();await create_timer(.3).timeout
 print("V42 FAILURES: "+str(failures));quit(failures)
