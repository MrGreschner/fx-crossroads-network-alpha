extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_dev_match",true);root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
 check(game.manifest.characters.size()>=43 and game.manifest.regions.size()>=23,"original immersive roster remains available")
 for id in ["honeyglass","sunfield","lantern_marsh","silverfall","petalbrook"]:
  game.start_run(false,id);game.invulnerable_time=100
  var world=game.adventure.immersive;var origin:Vector2=world.v(world.data.spawn)
  check(world.active and world.can_stand(origin),id+" walkable arrival")
  for entry in world.data.spawns:
   var point:Vector2=world.v(entry.pos)
   check(world.can_stand(point),id+" walkable defender "+str(entry.pos))
   check(not world.route(origin,point).is_empty(),id+" connected defender "+str(entry.pos))
  for secret in world.data.secrets:
   var point:Vector2=world.v(secret.pos)
   check(world.can_stand(point),id+" walkable discovery "+str(secret.name))
   var interior:=false
   for house in world.data.get("houses",[]):
    if point.distance_to(world.v(house.inside))<400:interior=true
   if not interior:check(not world.route(origin,point).is_empty(),id+" connected discovery "+str(secret.name))
  world.step(.01);check(game.enemies.size()==world.data.spawns.size() and not world.boss_live,id+" seeds defenders before guardian")
  for n in range(game.enemies.size()-1,-1,-1):game.damage_enemy(n,100000)
  game.menu="";world.step(.01)
  check(world.boss_live and game.enemies.size()==1 and game.level>=6,id+" guardian awakens only after clear with specials unlocked")
  check(world.can_stand(world.v(world.data.exit)) and not world.route(origin,world.v(world.data.exit)).is_empty(),id+" reachable guardian and exit")
  game.damage_enemy(0,100000);check(world.done and game.boss_defeated,id+" defeated guardian unlocks completion")
  game.position_in_world=world.v(world.data.exit);world.interact("solo");check(game.presentation.page=="results",id+" reachable completion interaction")
 game.start_run(false,"sunfield");var world=game.adventure.immersive;world.initialized=true;game.enemies.clear();game.health=100;game.invulnerable_time=0;game.position_in_world=Vector2(2800,3300)
 var foe:Dictionary=world.spawn("sunbeam_cantor",game.position_in_world);foe.hp=50;world.add_beam(game.position_in_world)
 world.step_beams(1.2);check(game.health==100 and foe.hp==50,"sunbeam has pre-damage warning")
 world.step_beams(.11);world.step_beams(.99);check(game.health==100,"sunbeam waits full one-second tick")
 world.step_beams(.02);check(game.health==84 and foe.hp==59,"sunbeam deals 16/s and heals foes 9/s")
 game.position_in_world=Vector2(2600,4200);game.invulnerable_time=0;world.step_beams(1);check(game.health==84,"leaving sunbeam prevents its next hit")
 check(world.data.grass.is_empty() and not world.grass_at(Vector2(450,4100)),"Sunfield uses canopy cover instead of dense animated grass")
 game.start_run(false,"lantern_marsh");world=game.adventure.immersive;game.position_in_world=Vector2(3100,4500)
 check(is_equal_approx(game.adventure.combat.speed_factor("p:solo"),.55),"mud reduces player movement to 55 percent")
 game.position_in_world=Vector2(430,4600);check(game.adventure.combat.speed_factor("p:solo")==1,"leaving mud restores speed immediately")
 var reward:Dictionary=world.data.secrets[0];game.position_in_world=world.v(reward.pos);var gold:int=game.gold;world.interact("solo");world.interact("solo");check(game.gold==gold+int(reward.amount),"discovery reward once per player")
 game.start_run(false,"silverfall");world=game.adventure.immersive
 for house in world.data.houses:
  game.position_in_world=world.v(house.outside);check(world.interact("solo"),"enter "+str(house.name));check(game.position_in_world.distance_to(world.v(house.inside))<100,"inside treehouse room")
  world.interact("solo");check(game.position_in_world.distance_to(world.v(house.outside))<100,"leave treehouse")
 game.position_in_world=world.v(world.data.raft.docks[0]);world.interact("solo");check(world.aboard("solo") and game.adventure.combat.speed_factor("p:solo")==0,"boarding locks walking on raft")
 world.step_boat(1.21);world.step_boat(3);check(world.moving("solo") and game.position_in_world.x>6500 and game.position_in_world.x<9100,"raft carries continuously over impassable water")
 var serialized:Dictionary=JSON.parse_string(JSON.stringify(world.snapshot()));check(serialized.boat.passengers.has("solo"),"raft passengers serialize")
 world.step_boat(12);check(not world.aboard("solo") and world.can_stand(game.position_in_world),"raft disembarks onto walkable far shore")
 game.position_in_world=world.v(world.data.raft.docks[0]);world.interact("solo");world.step_boat(.2);world.step_boat(12);check(world.boat.dock==0,"empty raft can be called from opposite jetty")
 game.selected_character="pippa";game.start_run(false,"petalbrook");world=game.adventure.immersive;world.initialized=true;game.enemies.clear();game.level=6;game.position_in_world=Vector2(2800,3400)
 var combat=game.adventure.combat;var fern=combat.fern;var enemy:Dictionary=world.spawn("briar_tail",Vector2(2940,3400));enemy.hp=500;enemy.max_hp=500
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,15);fern.step(.4);check(enemy.hp==470,"two travelling ribbons each hit once")
 fern.step(.4);check(enemy.hp==470,"ribbons cannot repeatedly damage same foe")
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,0);check(not fern.decoy_for(enemy.pos).is_empty(),"leaf double attracts nearby defenders")
 game.health=80;game.position_in_world=Vector2(2850,3400);fern.step(3.01);fern.step(1.0);check(game.health==88 and combat.effect_time("p:solo","fern_stride")>0,"decoy bloom heals and grants passive stride")
 fern.reset();game.position_in_world=Vector2(2800,3400);enemy.pos=Vector2(3000,3400);var oldhp:float=enemy.hp
 combat.cast("solo",game.hero.special,Vector2.RIGHT,36)
 for n in 48:fern.step(.05)
 check(enemy.hp<oldhp and enemy.hp>=oldhp-108,"three spiral tips deal finite unique contacts")
 fern.step(.1);check(fern.dances.is_empty(),"maypole ends after 2.4 seconds")
 for voice in game.journey.voices:voice.stop()
 game.queue_free();await process_frame;await create_timer(.2).timeout
 print("v50 worlds: "+str(failures)+" failures");quit(1 if failures else 0)
