extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false);g.presentation.asked=true;g.presentation.close();g.session_menu.resume();g.enter_region("practice");g.obstacles.clear();g.scenery_tiles.clear();g.enemies.clear();g.position_in_world=Vector2(1000,1000);g.level=10;g.menu=""
 var c=g.adventure.combat;c.setup("practice");g.character_id="tempo";g.hero=g.characters.tempo
 g.adventure.spawn("bramble",Vector2(1070,1000),500,false);var key:String=c.npc_key(g.enemies[0]);c.stance_heroes.cast("solo",c.effective_stats("solo","primary",g.hero.primary),Vector2.RIGHT,24)
 c.stance_heroes.step(.01);check(g.enemies[0].hp==492,"first of three jabs")
 c.stance_heroes.step(.09);check(g.enemies[0].hp==484,"second timed jab")
 c.stance_heroes.step(.1);check(g.enemies[0].hp==476 and c.effect_time(key,"slow")>0,"all three jabs slow")
 c.stance_heroes.reset();c.statuses.clear();g.enemies[0].hp=500;c.stance_heroes.cast("solo",c.effective_stats("solo","primary",g.hero.primary),Vector2.RIGHT,24);c.stance_heroes.step(.01);g.enemies[0].pos=Vector2(1100,1100);c.stance_heroes.step(.3);check(g.enemies[0].hp==492 and c.effect_time(key,"slow")==0,"missing jabs grants no slow")
 var kit=c.v90
 for id in ["cindervane","tova","merrymask","dunecook","dustmarshal"]:
  c.setup("practice");g.character_id=id;g.hero=g.characters[id];g.position_in_world=Vector2(1000,1000);g.health=50;g.enemies.clear();g.adventure.spawn("bramble",Vector2(1070,1000),500,false)
  for kind in ["primary","secondary","special"]:
   var a:Dictionary=g.hero[kind];check(kit.cast("solo",a,Vector2.RIGHT,float(a.damage)),"casts "+id+kind)
   for n in 35:kit.step(.05)
  check(g.enemies.is_empty() or float(g.enemies[0].hp)<500,"new kit hurts enemies "+id)
  for key2 in ["technique","final_technique"]:
   var a:Dictionary=g.hero.mastery[key2].attack;check(kit.cast("solo",a,Vector2.RIGHT,float(a.damage)),"mastery casts "+id+key2)
   for n in 25:kit.step(.1)
  check(kit.effects.size()<15,"bounded effects "+id)
 c.setup("practice");g.character_id="merrymask";g.hero=g.characters.merrymask
 for n in 8:kit.cast("solo",g.hero.secondary,Vector2.RIGHT,0)
 check(kit.units("solo").size()==4,"puppet cap four")
 for n in 100:kit.step(.1);c.morrow.step(.1)
 check(kit.units("solo").is_empty(),"finite puppet lifetime")
 c.setup("practice");g.character_id="cindervane";g.hero=g.characters.cindervane;g.enemies.clear();g.adventure.spawn("bramble",g.position_in_world+Vector2(70,0),500,false);kit.cast("solo",g.hero.primary,Vector2.RIGHT,12);kit.step(.35);check(int(kit.feathers.get("solo",0))==2,"wing cuts bank feathers")
 kit.cast("solo",g.hero.secondary,Vector2.RIGHT,20);check(kit.moving("solo"),"curving leap locks normal movement");kit.step(.65);check(not kit.moving("solo"),"leap ends")
 g.queue_free();await process_frame
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);await process_frame;a.set_process(false);a.party_tools.set_process(false);a.legacy.set_process(false);a.presentation.set_process(false);a._set_mode("arena");a.bot_count=1;a._solo();a.start_countdown=0;a.field_obstacles.clear();a.obstacle_grid.clear();a._add_player("friend",1);a.hero_ids.friend="cindervane";a.levels.friend=10;a.positions.friend=Vector2(1000,1000);a.positions[a.my_id]=Vector2(1070,1000);a.health[a.my_id]=120;a.invincible_until[a.my_id]=0;a.cooldown_at.friend={}
 a._packet("friend",{"type":"attack","style":"primary","angle":0,"target":[1070,1000]});a.adventure.combat.v90.step(.2);check(a.health[a.my_id]<120,"guest new hero host damage")
 a.adventure.combat.v90.cast("friend",a.characters.cindervane.secondary,Vector2.RIGHT,20);a.adventure.combat.v90.step(.1);var before:Vector2=a.positions.friend;a._packet("friend",{"type":"pos","pos":[1000,1000]});check(a.positions.friend==before,"guest cannot overwrite host leap")
 var packet:Dictionary=a.adventure.combat.snapshot();check(packet.v90.effects.size()>0,"new effects in host snapshots")
 a.role="guest";var count:int=a.adventure.combat.morrow.units.size();a.adventure.combat.v90.cast("friend",a.characters.merrymask.secondary,Vector2.RIGHT,0);check(a.adventure.combat.morrow.units.size()==count,"guest cannot spawn authoritative units")
 a.queue_free();await process_frame;print("v90 combat failures: ",failures);quit(failures)
