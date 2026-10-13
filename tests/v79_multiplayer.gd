extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var g=load("res://scenes/arcade.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.party_tools.set_process(false);g.legacy.set_process(false)
 g.role="host";g.my_id="host";g.host_id="host";g._add_player("host",0);g._add_player("friend",1);g._set_mode("arena");g._start_match();g.pvp_rule="teams";g.teams.host=0;g.teams.friend=1
 g.hero_ids.host="snail";g.hero_ids.friend="kite";g.positions.host=Vector2(1000,1000);g.local_pos=g.positions.host;g.positions.friend=Vector2(1100,1000);g.health.host=165;g.health.friend=200;g.levels.host=10;g.levels.friend=10;g.opponents.clear();g.field_obstacles.clear();g.obstacle_grid.clear();g.inventory.host=[];g.inventory.friend=[];g.legacy.data=g.legacy.defaults();g.legacy.builds.clear()
 var c=g.adventure.combat;var kit=c.v79
 check(is_equal_approx(kit.erode("p:friend",100,40),80),"60 percent protection becomes 20")
 check(kit.erode("p:friend",100,100)==100,"aura cannot create bonus damage against unprotected foes")
 check(kit.erode("p:friend",100,90)==100,"erosion stops at zero reduction")
 g.levels.host=4;check(kit.erode("p:friend",100,40)==40,"passive locked below five");g.levels.host=10
 g.teams.friend=0;check(kit.erode("p:friend",100,40)==40,"aura never strips teammate armor");g.teams.friend=1
 g.positions.friend=Vector2(1400,1000);check(kit.erode("p:friend",100,40)==40,"outside aura retains protection");g.positions.friend=Vector2(1100,1000)
 g.shield_until.friend=Time.get_ticks_msec()+10000;g.shield_reduction.friend=.6;g.invincible_until.friend=0
 g._hurt("friend",100,"host");check(g.health.friend==120,"actual arena damage pipeline erodes shield")
 g.health.friend=200;g.invincible_until.friend=Time.get_ticks_msec()+10000;g._hurt("friend",100,"host");check(g.health.friend==200,"aura never bypasses invulnerability");g.invincible_until.friend=0;g.shield_until.friend=0
 # Friendly fire must stay disabled for overlapping lava pools.
 g.teams.friend=0;kit.pool("host",g.positions.friend,80,5);kit.step(.5);check(g.health.friend==200,"lava does not burn teammates");g.teams.friend=1;kit.step(.5);check(g.health.friend==196,"lava damages opponent")
 kit.reset();g.cooldown_at.host={};g.hero_ids.host="snail";g.selected_hero="snail";g._attack("host","secondary",Vector2.RIGHT,Vector2(1460,1000));kit.step(.4)
 check(g.positions.host.x>1000 and g.positions.host.x<1460,"host shell lob moves gradually")
 var packet:Dictionary=JSON.parse_string(JSON.stringify(c.snapshot()));check(packet.v79.effects.size()>0,"flight serializes")
 var before:Vector2=g.positions.host
 g._packet("host",{"type":"pos","x":before.x+20,"y":before.y});check(g.positions.host==before,"walking packets cannot override a flight")
 var hp:int=int(g.health.friend);g.role="guest";c.receive(packet);kit.step(10);check(g.health.friend==hp,"guest never simulates damage");g.local_pos=Vector2(1000,1000);kit.follow_local(.1);check(g.local_pos==before,"guest follows host flight position");g.role="host"
 kit.step(.4);check(g.positions.host.distance_to(Vector2(1460,1000))<1,"host lands exact target")
 kit.reset();g.hero_ids.host="kite";g.selected_hero="kite";g.positions.host=Vector2(1000,1000);g.local_pos=g.positions.host;g.positions.friend=Vector2(1250,1000);g.health.friend=200
 kit.observed.host={"speed":280.0,"pos":[1000,1000]};c.cast("host",g.characters.kite.primary,Vector2.RIGHT,18)
 kit.step(.5);check(g.health.friend==170,"momentum needle damages rival for thirty")
 var alt:Dictionary=g.characters.kite.mastery.final_technique.attack;c.cast("host",alt,Vector2.RIGHT,26);kit.step(.5)
 check(g.health.friend==144 and c.effect_time("p:friend","slow")>0,"alternate harpoon damage and slow")
 check(g.positions.friend.x<1250,"harpoon pulls hit rival")
 print("v79 multiplayer failures: ",failures);g.queue_free();await process_frame;await create_timer(.2).timeout;quit(failures)
