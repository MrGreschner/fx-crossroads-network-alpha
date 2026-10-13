extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
 game.selected_character="nera";game.start_run(false,"brasslock")
 var city=game.adventure.city;var combat=game.adventure.combat
 check(game.characters.size()>=26 and game.enemies.size()==30,"original hero roster retained and all 30 borough enemies")
 check(city.buildings.size()==15 and city.doors.size()==45,"dense divided interiors and 45 doors")
 check(not city.can_stand(Vector2(180,180)),"masonry blocks movement")
 var door:Dictionary=city.doors[0];var center:Vector2=city.door_rect(door).get_center()
 check(not city.can_stand(center),"closed door blocks")
 game.position_in_world=center-Vector2(0,70);check(city.interact("solo") and city.can_stand(center),"interact opens a door")
 city.clock+=1;game.position_in_world=center;city.interact("solo");check(bool(door.open),"door cannot close on player")
 combat.projectiles.clear()
 combat.launch_projectile("enemy",Vector2(450,700),Vector2.UP,{"range":700,"speed":235,"wall_bounces":2},10,"bankshot")
 combat.step_projectiles(.2)
 check(combat.projectiles.size()==1 and float(combat.projectiles[0].aim[1])>0 and int(combat.projectiles[0].wall_bounces)==1,"city bankshot reflects off masonry")
 for entry in city.doors:entry.open=true
 city.rebuild_grid()
 for foe in game.enemies:
  var destination:=Vector2i(floori(foe.pos.x/40),floori(foe.pos.y/40))
  check(not city.grid.get_id_path(Vector2i(2,31),destination).is_empty(),"every room enemy is reachable through open doors")
 check(not city.grid.get_id_path(Vector2i(2,31),Vector2i(87,58)).is_empty(),"courthouse reachable")
 game.start_run(false,"honeyglass");city=game.adventure.city;combat=game.adventure.combat
 var heights:Array=[];var hornets:=0
 for enemy in game.enemies:
  if enemy.type=="seed_blossom":heights.append(enemy.pos.y)
  if enemy.type=="amber_hornet":hornets+=1
 heights.sort();check(hornets==5 and heights[-1]-heights[0]>1400,"garden shooters distributed and five hornets added")
 game.enemies.clear();game.position_in_world=Vector2(2000,1500)
 game.adventure.spawn("lantern_moth",Vector2(2200,1500),100,false);game.update_enemies(.01)
 check(combat.projectiles.size()==1 and combat.projectiles[0].style=="weaving","moth actually casts weaving projectile")
 combat.projectiles.clear();game.enemies.clear()
 combat.launch_projectile("enemy",Vector2(1000,1500),Vector2.RIGHT,{"range":700,"speed":170,"amplitude":32,"wavelength":170},11,"weaving")
 combat.step_projectiles(.25);check(absf(float(combat.projectiles[0].pos[1])-1532)<.1,"wave swings to first side")
 combat.step_projectiles(.5);check(absf(float(combat.projectiles[0].pos[1])-1468)<.1,"wave swings to opposite side")
 combat.setup("honeyglass");game.level=1;game.hero=game.characters.nera
 for x in [2080,2200]:game.adventure.spawn("bramble",Vector2(x,1500),500,false)
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,20)
 for n in 20:combat.step(.025)
 check(game.enemies[0].hp==480 and game.enemies[1].hp==480,"key pierces two enemies once each")
 game.enemies.clear();combat.setup("honeyglass");game.adventure.spawn("bramble",Vector2(2230,1500),500,false)
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,24)
 for n in 30:combat.step(.025)
 check(game.enemies[0].hp==476 and game.enemies[0].pos.x<2150,"hook damages and pulls target")
 game.enemies.clear();combat.setup("honeyglass");game.adventure.spawn("bramble",Vector2(2190,1500),500,false)
 combat.cast("solo",game.hero.special,Vector2.RIGHT,72);combat.step(.5)
 check(game.enemies[0].hp==500,"tram has warning delay")
 for n in 30:combat.step(.025)
 check(game.enemies[0].hp==428,"tram hits once after travelling")
 check(combat.snapshot().courier.has("trams"),"courier effects replicated")
 var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame;party.set_process(false);party.selected_hero="nera";party._set_mode("defense");party._solo();party._set_mode("coop")
 for n in party.realm_picker.item_count:
  if str(party.realm_picker.get_item_metadata(n))=="brasslock":party.realm_picker.select(n)
 party._start_match()
 check(party.adventure.city.active and party.opponents.size()==30,"co-op loads all city rooms")
 for slot in 4:check(party.adventure.city.can_stand(party._spawn_player(slot)),"all four co-op starts clear of walls")
 party.opponents.clear();party._simulate(.01)
 check(party.opponents.size()==1 and party.opponents[0].type=="lockmaster_regent" and party.opponents[0].pos==Vector2(3500,2330),"city boss spawns in courthouse without resetting doors")
 party.local_pos=Vector2(3380,2330);party.positions.solo=party.local_pos
 for turn in 3:
  party.opponents[0].city_timer=0;party.adventure.step(.01)
 check(party.adventure.combat.projectiles.size()>=3 and party.adventure.city.eruptions.size()==4 and party.adventure.warnings.size()>0,"Regent uses bank shots, drain eruptions and warning lunge")
 var door_center:Vector2=party.adventure.city.door_rect(party.adventure.city.doors[0]).get_center()
 party.local_pos=door_center-Vector2(0,70);party.positions.solo=party.local_pos
 var press:=InputEventKey.new();press.pressed=true;press.keycode=KEY_E;party._unhandled_input(press)
 check(bool(party.adventure.city.doors[0].open),"co-op Interact input opens city doors")
 var packet:Dictionary=party._snapshot();check(packet.adventure.city.doors.size()==45,"co-op door state included")
 for voice in game.journey.voices:voice.stop()
 for voice in party.journey.voices:voice.stop()
 game.queue_free();party.queue_free();await create_timer(.3).timeout
 print("V39 FAILURES: "+str(failures));quit(failures)
