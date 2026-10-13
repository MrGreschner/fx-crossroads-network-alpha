extends SceneTree
var failures:=0
func check(ok:bool,message:String)->void:
 if not ok:failures+=1;print("FAIL: ",message)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false);g.presentation.asked=true;g.presentation.close();g.session_menu.resume()
 g.menu="";g.legacy.data.heroes.clear();g.legacy._process(.1)
 var quick:Button=g.legacy.get_node("Quick")
 check(quick.position.y==g.presentation.adventure_button.position.y,"town buttons share top baseline")
 check(quick.get_theme_stylebox("normal").bg_color==g.presentation.adventure_button.get_theme_stylebox("normal").bg_color,"normal profile skin matches Adventures")
 g.legacy.record("ram").points=2;g.legacy.refresh_point_notice();g.legacy._process(.1)
 check(g.legacy.point_notice and g.legacy.mastery_tab.text.contains("points"),"unspent points highlight both entry and Mastery tab")
 g.legacy.record("ram").tuning=[2,0,0];g.legacy.refresh_point_notice();g.legacy._process(.1)
 check(not g.legacy.point_notice,"spending available points clears highlight")
 g.enter_region("practice");g.practice=false;g.mode="run";g.menu="";g.level=10;g.obstacles.clear();g.scenery_tiles.clear();g.position_in_world=Vector2(1000,1000);g.enemies.clear()
 var c=g.adventure.combat;var kit=c.v90
 g.character_id="tova";g.hero=g.characters.tova;g.health=50
 g.adventure.spawn("bramble",Vector2(1094,1000),500,false);g.adventure.spawn("bramble",Vector2(1097,1000),500,false);g.adventure.spawn("bramble",Vector2(1070,1030),500,false)
 kit.cast("solo",g.hero.primary,Vector2.RIGHT,21);kit.step(.07)
 check(g.enemies[0].hp==479 and g.enemies[1].hp==500 and g.enemies[2].hp==500,"Tova tip/path damage stays within visible tongue reach")
 check(kit.primary_contains("chop",Vector2.ZERO,Vector2.RIGHT,Vector2(90,0),90) and not kit.primary_contains("chop",Vector2.ZERO,Vector2.RIGHT,Vector2(93,0),90),"Cook attack boundary excludes spatula overshoot")
 kit.on_hit("solo",20);check(g.health==54,"Tova primary heal plus passive life on hit")
 kit.on_hit("solo",20);check(g.health==54,"life aura rate limit")
 kit.clock+=.8;c.dot_damage=true;kit.on_hit("solo",2);c.dot_damage=false;check(g.health==54,"damage over time does not trigger life aura")
 g.level=4;kit.on_hit("solo",20);check(g.health==54,"aura gated by passive level")
 g.level=10
 c.setup("practice");g.character_id="dustmarshal";g.hero=g.characters.dustmarshal;g.enemies.clear();g.adventure.spawn("bramble",Vector2(1220,1000),500,false)
 var key:String=c.npc_key(g.enemies[0]);kit.cast("solo",g.hero.secondary,Vector2.RIGHT,18);kit.step(.31)
 check(g.enemies[0].pos==Vector2(1220,1000) and c.effect_time(key,"stun")>=1.9,"lasso hits then begins a timed pull with two-second stun")
 var previous:Vector2=g.enemies[0].pos
 for n in 8:
  kit.step(.05);var point:Vector2=g.enemies[0].pos;check(point.distance_to(previous)<=30.1 and point.x<=previous.x,"Hogtie pull moves smoothly toward caster");previous=point
 check(g.enemies[0].pos.distance_to(g.position_in_world)<=51,"Hogtie brings enemy close without crossing caster")
 kit.step(2);check(g.enemies[0].pos==previous,"finishing lasso does not jump target")
 c.setup("practice");g.character_id="dustmarshal";g.hero=g.characters.dustmarshal;g.enemies.clear();g.adventure.spawn("bramble",Vector2(1220,1000),500,false)
 kit.cast("solo",g.hero.secondary,Vector2.RIGHT,18);kit.step(.31)
 g.obstacles.append({"pos":Vector2(1130,1000),"radius":20.0,"kind":"rock","texture":null})
 for n in 10:kit.step(.05)
 check(g.enemies[0].pos.x>=1150,"a wall stops an in-flight Hogtie pull")
 g.obstacles.clear()
 c.setup("practice");g.character_id="mantis";g.hero=g.characters.mantis;g.enemies.clear();g.adventure.spawn("bramble",g.position_in_world+Vector2.RIGHT.rotated(PI*.3-.01)*84,500,false);g.adventure.spawn("bramble",g.position_in_world+Vector2.RIGHT.rotated(PI*.3+.02)*84,500,false)
 c.mantis.cast("solo",g.hero.primary,Vector2.RIGHT,22);check(g.enemies[0].hp==478 and g.enemies[1].hp==500,"Mantis primary follows the displayed sector boundary")
 c.setup("practice");g.character_id="cindervane";g.hero=g.characters.cindervane;g.enemies.clear();kit.cast("solo",g.hero.special,Vector2.RIGHT,10)
 check(is_equal_approx(kit.smoke_chance("solo"),.12),"smoke protects the caster")
 check(kit.smoke_dodges("solo",.119) and not kit.smoke_dodges("solo",.12),"smoke dodge threshold is exactly twelve percent")
 var snap:Dictionary=JSON.parse_string(JSON.stringify(kit.snapshot()));check(snap.effects.any(func(e):return e.style=="smoke"),"smoke uses existing host snapshot")
 kit.step(1.3);check(is_equal_approx(kit.smoke_chance("solo"),.12),"smoke survives offensive ring sweeps")
 g.position_in_world+=Vector2(160,0);check(kit.smoke_chance("solo")==0,"walking out of smoke removes dodge")
 g.position_in_world-=Vector2(160,0);kit.step(4.3);check(kit.smoke_chance("solo")==0,"smoke expires at 5.5 seconds")
 check(load("res://assets/cindervane_walk1.png").get_image().get_data()!=load("res://assets/cindervane_walk2.png").get_image().get_data(),"distinct wing-up and wing-down walking poses")
 var motion=preload("res://scripts/hero_motion_v85.gd").new()
 for id in ["aurel","cindervane","snowman","stormscribe","magnet"]:
  motion.sample(id,id,Vector2.ZERO,true)
  for n in 100:motion.sample(id,id,Vector2(n*25,0),true)
 check(motion.footprints.size()<=96,"cosmetics share a capped effect budget")
 motion.advance(2);check(motion.footprints.is_empty(),"movement trails fade and are removed")
 g.enter_region("town");g.menu="portal";g.catalog_ui._process(.1)
 var catalogue=g.catalog_ui
 for id in catalogue.rosters:
  var seen_boss:=false
  for kind in catalogue.roster(id):
   if catalogue.is_boss(id,kind):seen_boss=true
   else:check(not seen_boss,"ordinary/summoned enemy never follows boss: "+str(id))
 check(catalogue.is_boss("shattered_oath","gilded_usurper") and catalogue.is_boss("high_school","spotlight_sovereign"),"procedural and school bosses classified")
 check(catalogue.difficulty_color("Expert")!=Color.WHITE and catalogue.difficulty_color("Easy")!=catalogue.difficulty_color("Extreme"),"difficulty has distinct readable colours")
 g.queue_free();await process_frame;await process_frame
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);await process_frame;a.set_process(false);a.party_tools.set_process(false);a.legacy.set_process(false);a.presentation.set_process(false);a._set_mode("arena");a.rule_picker.select(1);a.bot_count=1;a._solo();a.start_countdown=0;a.field_obstacles.clear();a.obstacle_grid.clear();a._add_player("friend",1);a._add_player("foe",1)
 a.teams[a.my_id]=0;a.teams.friend=0;a.teams.foe=1;a.hero_ids[a.my_id]="cindervane";a.levels[a.my_id]=10;a.health[a.my_id]=100;a.positions[a.my_id]=Vector2(1000,1000);a.positions.friend=Vector2(1080,1000);a.positions.foe=Vector2(1080,1000)
 var k=a.adventure.combat.v90;k.cast(a.my_id,a.characters.cindervane.special,Vector2.RIGHT,10)
 check(is_equal_approx(k.smoke_chance("friend"),.12) and k.smoke_chance("foe")==0,"smoke affects teammates, not arena rivals")
 var remote:Dictionary=JSON.parse_string(JSON.stringify(k.snapshot()));a.role="guest";k.receive(remote)
 check(is_equal_approx(k.smoke_chance("friend"),.12) and k.smoke_chance("foe")==0,"guest snapshot preserves smoke radius and team restriction")
 a.role="host"
 a.hero_ids[a.my_id]="tova";a.levels[a.my_id]=10;a.health.friend=50;k.on_hit("friend",20);check(a.health.friend==52,"life-on-hit works for nearby ally")
 a.health.foe=50;k.on_hit("foe",20);check(a.health.foe==50,"Tova aura does not heal rivals")
 a.started=false;a.session_menu.resume();a.session_menu._process(0);await process_frame
 var menu:Button=a.session_menu.menu_button;check(absf(menu.position.y+menu.size.y*.5-51)<2,"lobby Menu centred in title bar")
 check(a.code_field.alignment==HORIZONTAL_ALIGNMENT_CENTER,"room code centred")
 check(a.hero_picker.get_theme_stylebox("normal").content_margin_left>=12,"match fields have text inset")
 a.queue_free();await process_frame;await process_frame;print("v97 refinements failures: ",failures);quit(failures)
