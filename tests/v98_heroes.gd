extends SceneTree
var failures:=0
func check(ok:bool,message:String)->void:
 if not ok:failures+=1;print("FAIL: ",message)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false);g.presentation.asked=true;g.presentation.close();g.session_menu.resume();g.enter_region("practice");g.practice=false;g.mode="run";g.menu="";g.level=10;g.position_in_world=Vector2(1000,1000);g.obstacles.clear();g.scenery_tiles.clear()
 var c=g.adventure.combat;var kit=c.v98
 check(g.characters.size()==74 and g.manifest.characters.size()==74,"74 playable heroes with sequential display numbers")
 for id in ["wick","cobbleclaw"]:
  check(g.characters.has(id),"registered kit "+id)
  for pose in ["idle","walk1","walk2","attack"]:check(g.art.has(id+"_"+pose),"loaded portrait/pose "+id+pose)
  check(g.characters[id].mastery.technique.ability!=g.characters[id].mastery.final_technique.ability,"masteries affect different slots "+id)
 g.character_id="wick";g.hero=g.characters.wick;g.health=50;g.enemies.clear();g.adventure.spawn("bramble",Vector2(1080,1000),500,false);g.adventure.spawn("bramble",Vector2(920,1000),500,false)
 var key:String=c.npc_key(g.enemies[0]);kit.cast("solo",g.hero.secondary,Vector2.RIGHT,0)
 check(is_equal_approx(c.effect_time(key,"stun"),.85) and is_equal_approx(c.effect_time(key,"slow"),3.85),"front fright stuns then gives three seconds of slow")
 check(c.effect_time(c.npc_key(g.enemies[1]),"stun")==0,"back enemies cannot see the forward face")
 c.tick_statuses(1.2);check(c.effect_time(key,"stun")==0 and c.effect_time(key,"slow")>2.6,"slow remains after stun ends")
 c.statuses.clear();g.obstacles.append({"pos":Vector2(1040,1000),"radius":18.0,"kind":"rock","texture":null});kit.cast("solo",g.hero.secondary,Vector2.RIGHT,0);check(c.effect_time(key,"stun")==0,"walls block fright")
 g.obstacles.clear()
 kit.cast("solo",g.hero.primary,Vector2.RIGHT,20);c.step_projectiles(.2)
 check(g.enemies[0].hp==480 and c.effect_time(key,"burn")>=3,"fireball damages and burns on collision")
 check(kit.candle("solo") and kit.heal_factor("solo")==1.15,"self candle healing multiplier")
 g.level=4;check(not kit.candle("solo"),"passive level gate");g.level=10
 g.legacy.data.teacher=true;check(is_equal_approx(g.legacy.critical("solo",100,g.position_in_world,0),190),"crit aura boosts bonus, not base damage or chance")
 check(g.legacy.critical("solo",100,g.position_in_world,.2)==100,"aura does not grant guaranteed crits")
 g.legacy.data.teacher=false;check(g.legacy.critical("solo",100,g.position_in_world,0)==100,"unearned crit stays unavailable")
 c.classics.heal("solo",20);check(is_equal_approx(g.health,73),"received healing amplification")
 kit.reset();g.enemies.clear();kit.cast("solo",g.hero.special,Vector2.RIGHT,6);kit.step(.01)
 var gift:Dictionary=kit.effects.filter(func(e):return e.kind=="treat")[0];var first:Vector2=c.vec(gift.first);var second:Vector2=c.vec(gift.second)
 g.adventure.spawn("bramble",first,500,false);kit.step(.75);check(g.enemies[0].hp==494,"first treat landing damages once")
 g.enemies[0].pos=second;kit.step(.5);check(g.enemies[0].hp<=488,"second bounce landing damages and opens")
 for n in 25:kit.step(.1)
 var flavours:Array=[]
 for e in kit.effects:
  if e.kind=="patch" and e.flavour not in flavours:flavours.append(e.flavour)
 check(flavours.size()==5,"volley opens all five readable flavours")
 for n in 50:kit.step(.1)
 check(kit.effects.is_empty(),"treats and patches expire")
 kit.reset();g.enemies.clear();g.adventure.spawn("bramble",g.position_in_world,500,false);key=c.npc_key(g.enemies[0]);g.health=50
 for flavour in ["slow","poison","burn","shock","heal"]:
  var field:Dictionary=kit.add("solo","patch",g.position_in_world,Vector2.RIGHT,3);field.flavour=flavour;field.range=36.0;field.tick=.5
 kit.step(.01)
 for status in ["slow","poison","burn","stun"]:check(c.effect_time(key,status)>0,"treat field applies "+status)
 check(g.health>50,"healing treat restores caster")
 kit.reset()
 for n in 250:kit.add("solo","impact",g.position_in_world,Vector2.RIGHT,.2)
 check(kit.effects.size()==192,"visual/effect budget is bounded");kit.step(.3);check(kit.effects.is_empty(),"full budget expires without invalid iteration")
 c.setup("practice");g.character_id="cobbleclaw";g.hero=g.characters.cobbleclaw;g.health=100;g.enemies.clear();g.adventure.spawn("bramble",Vector2(1060,1000),500,false)
 kit.cast("solo",g.hero.primary,Vector2.RIGHT,14);kit.step(.36);check(g.enemies[0].hp==472,"two timed pincer strikes")
 kit.cast("solo",g.hero.secondary,Vector2.RIGHT,0)
 for n in 4:check(kit.catch_shot(Vector2(960,1000),Vector2(1010,1000),"enemy"),"catch incoming projectile")
 check(not kit.catch_shot(Vector2(960,1000),Vector2(1010,1000),"enemy"),"four shot bank cap")
 check(is_equal_approx(kit.defence("solo"),.12),"banked shot passive defence")
 kit.cast("solo",g.hero.special,Vector2.RIGHT,36);check(kit.moving("solo") and kit.defence("solo")==0,"crush locks movement and spends bank")
 kit.step(.65);check(not kit.moving("solo") and g.position_in_world.distance_to(Vector2(1280,1000))<1,"rush reaches clear endpoint")
 check(c.projectiles.size()==4,"spent shots become four counter shards")
 c.projectiles.clear();g.position_in_world=Vector2(1000,1000);g.obstacles.append({"pos":Vector2(1140,1000),"radius":25.0,"kind":"rock","texture":null});kit.cast("solo",g.hero.special,Vector2.RIGHT,36);kit.step(.65);check(g.position_in_world.x<1120,"rush cannot cross a wall");g.obstacles.clear()
 kit.cast("solo",g.hero.secondary,Vector2.RIGHT,0);kit.step(4);check(not kit.catch_shot(g.position_in_world-Vector2(40,0),g.position_in_world,"enemy"),"catching ends with brace duration")
 for id in ["wick","cobbleclaw"]:
  c.setup("practice");g.character_id=id;g.hero=g.characters[id]
  for kind in ["primary","secondary","special"]:
   var stats:Dictionary=g.hero[kind];check(c.cast("solo",stats,Vector2.RIGHT,float(stats.damage)),"shared route "+id+kind)
  for choice in ["technique","final_technique"]:
   var stats:Dictionary=g.hero.mastery[choice].attack;check(c.cast("solo",stats,Vector2.RIGHT,float(stats.damage)),"mastery route "+id+choice)
  for n in 90:kit.step(.1)
  check(kit.effects.is_empty(),"finite mastery effects "+id)
 g.queue_free();await process_frame;await process_frame
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);await process_frame;a.set_process(false);a.party_tools.set_process(false);a.legacy.set_process(false);a.presentation.set_process(false);a._set_mode("arena");a.bot_count=1;a._solo();a.start_countdown=0;a.field_obstacles.clear();a.obstacle_grid.clear();a._add_player("friend",1);a.hero_ids.friend="wick";a.levels.friend=10;a.positions.friend=Vector2(1000,1000);a.positions[a.my_id]=Vector2(1080,1000);a.health[a.my_id]=120;a.invincible_until[a.my_id]=0;a.cooldown_at.friend={}
 c=a.adventure.combat;kit=c.v98
 check(not kit.candle(a.my_id),"rival cannot receive Candle Light")
 a._packet("friend",{"type":"attack","style":"secondary","angle":0,"target":[1080,1000]});check(c.effect_time(c.player_key(a.my_id),"stun")>0,"host executes guest fright")
 a.pvp_rule="teams";a.teams.friend=1;a.teams[a.my_id]=0
 a._add_player("partner",1);a.hero_ids.partner="ram";a.levels.partner=10;a.positions.partner=Vector2(1050,1000);a.teams.partner=a.teams.friend;a.health.partner=40
 check(kit.candle("partner") and kit.heal_factor("partner")==1.15,"same team receives aura")
 a._heal("friend","partner",20);check(a.health.partner==63,"ally healing amplified once")
 a.positions.partner=Vector2(1500,1000);check(not kit.candle("partner"),"leaving aura removes bonus");a.positions.partner=Vector2(1050,1000)
 a._add_player("lantern2",1);a.hero_ids.lantern2="wick";a.levels.lantern2=10;a.positions.lantern2=Vector2(1020,1000);a.teams.lantern2=a.teams.friend
 check(kit.heal_factor("partner")==1.15,"overlapping lantern auras do not stack")
 a.hero_ids.friend="cobbleclaw";a.cooldown_at.friend={};a._packet("friend",{"type":"attack","style":"special","angle":0,"target":[1280,1000]});kit.step(.1);var before:Vector2=a.positions.friend;a._packet("friend",{"type":"pos","pos":[1000,1000]});check(a.positions.friend==before,"guest cannot overwrite host rush")
 var snapshot:Dictionary=JSON.parse_string(JSON.stringify(c.snapshot()));check(snapshot.v98.effects.size()>0,"new effects serialize with combat snapshots")
 a.role="guest";var count:int=kit.effects.size();kit.cast("friend",a.characters.wick.special,Vector2.RIGHT,6);kit.step(3);check(kit.effects.size()==count,"guest never applies authority effects")
 kit.receive(snapshot.v98);check(kit.effects.size()==snapshot.v98.effects.size(),"guest receives visuals")
 a.queue_free();await process_frame;await process_frame;print("v98 hero failures: ",failures);quit(failures)
