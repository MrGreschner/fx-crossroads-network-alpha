extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func cell(point:Vector2)->Vector2i:return Vector2i(floori(point.x/50),floori(point.y/50))
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
 game.start_run(false,"practice");game.enemies.clear();game.position_in_world=Vector2(1100,600);game.level=10
 var combat=game.adventure.combat
 game.adventure.spawn("training_dummy",Vector2(1230,600),500,false);var foe:Dictionary=game.enemies[-1]
 check(combat.cast("solo",game.characters.baseball.special,Vector2.RIGHT,22),"Diamond special uses shared projectile effects")
 for n in 12:combat.step_projectiles(.02)
 check(foe.hp<500 and is_equal_approx(combat.effect_time(combat.npc_key(foe),"stun"),2.5),"Triple Play stuns for 2.5s")
 combat.projectiles.clear();game.enemies.clear();game.hero=game.characters.golfer;game.mobile.enabled=true;game.mobile.aim=Vector2.RIGHT
 for n in 6:game.adventure.spawn("training_dummy",Vector2(1500+n*110,600),500,false)
 game.cast_chain(game.hero.special,34,Vector2.RIGHT)
 var hurt:=0
 for enemy in game.enemies:
  if enemy.hp<500:hurt+=1
 check(hurt==5,"Course Ricochet hits five unique targets")
 game.enemies.clear();game.adventure.spawn("training_dummy",Vector2(1400,600),500,false);foe=game.enemies[-1]
 game.adventure.launch_lob("solo",Vector2(1100,600),Vector2(1400,600),game.hero.secondary,24)
 game.adventure.step_lobs(1)
 check(foe.hp==476 and game.adventure.lob_shots.size()==6,"Chip initial impact does 24 and launches six fragments")
 var child:Dictionary=game.adventure.lob_shots[0]
 check(child.damage==4 and child.radius==32 and int(child.fragments)==0,"small fragments cannot recursively split")
 foe.pos=combat.vec(child.end);game.adventure.step_lobs(1)
 check(foe.hp==472 and game.adventure.lob_shots.is_empty(),"fragment lands for four damage")
 game.hero=game.characters.velvetwing;game.enemies.clear();combat.v58.reset();combat.projectiles.clear()
 check(game.manifest.characters.size()==44,"44 heroes including Velvetwing and Chronicle Keeper")
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,12)
 check(combat.projectiles.size()==2 and float(combat.projectiles[0].aim[1])*float(combat.projectiles[1].aim[1])<0,"two needles converge from opposite wings")
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,22)
 check(combat.v58.lines.size()==3 and combat.reduction("solo")>=.15,"three armed silk lines and passive guard")
 game.adventure.spawn("training_dummy",Vector2(1240,660),500,false);foe=game.enemies[-1]
 combat.v58.step(.3);check(foe.hp==500,"silk warns before arming")
 combat.v58.step(.4);foe.pos=Vector2(1160,660);combat.v58.step(.02)
 check(foe.hp==478 and combat.effect_time(combat.npc_key(foe),"slow")>0,"crossing silk trips and slows")
 combat.v58.reset();foe.pos=Vector2(1375,720);foe.hp=500;combat.cast("solo",game.hero.special,Vector2.RIGHT,18)
 for n in 70:combat.v58.step(.05)
 check(foe.hp<500 and foe.hp>=440 and combat.v58.looms.is_empty(),"moving lunar wings deal capped damage and expire")
 var roundtrip:Dictionary=JSON.parse_string(JSON.stringify(combat.snapshot()));combat.receive(roundtrip);check(roundtrip.has("v58"),"silk effects serialize for guests")
 game.wing_motion.step("solo",Vector2.ZERO,.1,true);var rect:Rect2=game.wing_motion.sprite_rect("solo",Vector2.ZERO)
 check(rect.position.y< -42 and game.wing_motion.states.solo.point==Vector2.ZERO,"flight is visual and leaves ground position unchanged")
 for realm in ["elementary","middle_school","high_school"]:
  game.start_run(false,realm);var school=game.adventure.school
  for door in school.data.doors:
   var center:Vector2=school.v(door.pos)
   check(not school.can_stand(center),realm+" barrier blocks before unlock: "+str(door.id))
   school.open_door(door)
   check(school.can_stand(center),realm+" barrier clears after unlock: "+str(door.id))
   check(not school.grid.get_id_path(cell(center+Vector2(0,110)),cell(center-Vector2(0,110))).is_empty(),realm+" actual doorway crossing: "+str(door.id))
 game.start_run(false,"elementary");var school=game.adventure.school;school.step(.01)
 for door in school.data.doors:
  if door.id!="playground":school.open_door(door)
 for n in range(game.enemies.size()-1,-1,-1):game.damage_enemy(n,100000)
 school.step(.01)
 check(school.opened.playground and school.can_stand(Vector2(3175,950)),"defeating class patrol opens usable playground seam")
 check(not school.grid.get_id_path(cell(Vector2(3175,1200)),cell(Vector2(3300,620))).is_empty(),"playground reachable after actual clear")
 var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame;party.set_process(false);party._set_mode("defense");party._solo();party.hero_ids[party.my_id]="velvetwing";party._start_match();party.opponents.clear()
 var pc=party.adventure.combat;var origin:Vector2=party.positions[party.my_id]
 pc.cast(party.my_id,party.characters.velvetwing.secondary,Vector2.RIGHT,22)
 var packet:Dictionary=party._snapshot()
 check(packet.adventure.combat.v58.lines.size()==3,"host sends silk line effects in co-op")
 for voice in game.journey.voices:voice.stop()
 for voice in party.journey.voices:voice.stop()
 game.queue_free();party.queue_free();await create_timer(.3).timeout;print("v58: ",failures," failures");quit(1 if failures else 0)
