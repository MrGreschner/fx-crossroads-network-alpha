extends SceneTree
var failures:=0
func check(ok:bool,name:String)->void:
 if not ok:failures+=1;print("FAIL: ",name)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false);g.presentation.asked=true;g.presentation.close();g.session_menu.resume();g.enter_region("practice");g.position_in_world=Vector2(1000,1000);g.obstacles.clear();g.scenery_tiles.clear();g.enemies.clear();g.menu="";g.hero=g.characters.tempo;g.character_id="tempo";g.level=10
 var c=g.adventure.combat;var kit=c.stance_heroes;c.setup("practice")
 for n in 3:g.adventure.spawn("bramble",Vector2(1100+n*45,1000),500,false)
 kit.cast("solo",c.effective_stats("solo","secondary",g.hero.secondary),Vector2.RIGHT,14)
 for n in 20:kit.step(.05)
 check(g.enemies.all(func(e):return e.hp==486),"triple kick strikes three distinct foes")
 check(g.enemies.all(func(e):return c.effect_time(c.npc_key(e),"stun")>0),"all kicked foes stun")
 kit.reset();c.statuses.clear();g.position_in_world=Vector2(1000,1000);kit.state("solo").form="ranged";g.enemies.clear();g.adventure.spawn("bramble",Vector2(1120,1000),500,false)
 kit.cast("solo",c.effective_stats("solo","secondary",g.hero.secondary),Vector2.RIGHT,6)
 for n in 40:kit.step(.05)
 check(g.enemies[0].hp==452 and c.effect_time(c.npc_key(g.enemies[0]),"burn")>0,"eight flame ticks and burn")
 kit.reset();c.statuses.clear();c.projectiles.clear();kit.state("solo").form="poison";kit.cast("solo",c.effective_stats("solo","secondary",g.hero.secondary),Vector2.RIGHT,8)
 check(c.projectiles.size()==8 and c.projectiles[0].stats.poison_duration==3,"poison darts carry poison payload")
 g.enemies.clear();g.adventure.spawn("bramble",Vector2(1060,1000),500,false);kit.cast("solo",c.effective_stats("solo","primary",g.hero.primary),Vector2.RIGHT,20);check(g.enemies[0].hp==480 and c.effect_time(c.npc_key(g.enemies[0]),"poison")>0,"poison jab")
 kit.reset();c.statuses.clear();c.morrow.reset();g.hero=g.characters.quill;g.character_id="quill";g.position_in_world=Vector2(1000,1000);g.enemies.clear();g.adventure.spawn("bramble",Vector2(1080,1000),500,false)
 kit.cast("solo",g.hero.primary,Vector2.RIGHT,24);check(g.enemies[0].hp==476 and is_equal_approx(c.reduction("solo"),.1),"quill claw and passive guard")
 kit.cast("solo",g.hero.special,Vector2.RIGHT,42)
 for n in 12:kit.step(.05)
 check(g.enemies[0].hp==434,"stampede hits once across travel path")
 var motion=load("res://scripts/hero_motion_v85.gd").new();var total:=Vector2.ZERO
 for n in 80:motion.advance(.01);total+=motion.displacement("solo","quill",Vector2.RIGHT,220,.01)
 check(absf(total.x-176)<.01,"bounding preserves average speed overcycle")
 # Every new food uses the existing automatic path, not a manual/equipment slot.
 g.character_id="ram";g.hero=g.characters.ram;g.practice=false;g.mode="run";g.menu="";c.setup("grove");g.inventory.clear();g.block_time=0;g.invulnerable_time=0;g.tutorial.active=false
 for id in ["sunapple","river_melon","root_roast","moonberry_tart"]:
  var food:Dictionary=g.provisions.defs[id];g.health=float(g.max_health())*float(food.threshold);g.provisions.packed=id;var old:float=g.health;check(g.provisions.check_auto() and g.health==minf(g.max_health(),old+float(food.amount)),"automatic heal "+id)
 for id in ["mint_leaf","cool_cucumber","iron_plum","clear_peach"]:
  c.statuses.clear();g.provisions.packed=id;var food:Dictionary=g.provisions.defs[id];c.apply_status("p:solo",str(food.statuses[0]),3,"enemy",.5);check(g.provisions.packed.is_empty() and c.effect_time("p:solo",str(food.statuses[0]))==0,"automatic cleanse "+id)
 g.queue_free();await process_frame
 var m=load("res://scenes/arcade.tscn").instantiate();root.add_child(m);await process_frame;m.set_process(false);m.party_tools.set_process(false);m.legacy.set_process(false);m.presentation.set_process(false);m._set_mode("arena");m.bot_count=1;m._solo();m.start_countdown=0;m.field_obstacles.clear();m.obstacle_grid.clear();m.my_id="solo";m._add_player("friend",1);m.hero_ids.friend="tempo";m.levels.friend=10;m.cooldown_at.friend={};m.invincible_until.friend=0;m.positions.friend=Vector2(1000,1000);m.positions.solo=Vector2(1090,1000);m.health.solo=120
 m._packet("friend",{"type":"attack","style":"primary","angle":0,"target":[1090,1000]});check(m.health.solo==120,"close punch respects85reach")
 m.cooldown_at.friend={};m.positions.solo=Vector2(1070,1000);m._packet("friend",{"type":"attack","style":"primary","angle":0,"target":[1070,1000]});m.adventure.combat.stance_heroes.step(.3);check(m.health.solo<120,"guest monk punch damages opposing player")
 m.hero_ids.friend="quill";var a:Dictionary=m.characters.quill.special;m.adventure.combat.stance_heroes.cast("friend",a,Vector2.RIGHT,42);m.adventure.combat.stance_heroes.step(.1);var before:Vector2=m.positions.friend;m._packet("friend",{"type":"pos","pos":[1000,1000]});check(m.positions.friend==before,"guest movement cannot cancel host-driven stampede")
 m.role="guest";var count:int=m.adventure.combat.morrow.units.size();m.adventure.combat.stance_heroes.cast("friend",m.characters.quill.mastery.technique.attack,Vector2.RIGHT,0);check(m.adventure.combat.morrow.units.size()==count,"guest cannot create authoritative summons")
 m.queue_free();await process_frame;print("v89 combat failures: ",failures);quit(failures)
