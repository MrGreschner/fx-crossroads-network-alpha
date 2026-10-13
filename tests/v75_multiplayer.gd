extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/arcade.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false)
 g.role="host";g.my_id="host";g.host_id="host";g._add_player("host",0);g._add_player("friend",1);g._set_mode("arena");g._start_match();g.pvp_rule="teams";g.teams.host=0;g.teams.friend=1
 g.hero_ids.host="ripplejaw";g.hero_ids.friend="hearthwarden";g.positions.host=Vector2(1000,1000);g.positions.friend=Vector2(1100,1000);g.health.host=105;g.health.friend=145;g.levels.host=10;g.levels.friend=10;g.opponents.clear();g.field_obstacles.clear();g.obstacle_grid.clear();g.inventory.host=[];g.inventory.friend=[]
 var c=g.adventure.combat;var kit=c.v75
 c.cast("friend",g.characters.hearthwarden.secondary,Vector2.LEFT,0);kit.step(.1)
 check(c.reduction("friend")>=.18 and c.reduction("host")==0,"banner does not protect opposing team")
 kit.reset();g.teams.friend=0;c.cast("friend",g.characters.hearthwarden.secondary,Vector2.LEFT,0);kit.step(.1)
 check(c.reduction("host")>=.18,"banner protects teammate")
 g.teams.friend=1;kit.reset();c.statuses.clear();c.projectiles.clear();c.cast("host",g.characters.ripplejaw.primary,Vector2.RIGHT,21);kit.step(.26)
 check(g.health.friend<145,"water jet damages PvP opponent")
 c.cast("host",g.characters.ripplejaw.secondary,Vector2.RIGHT,26);kit.step(.1)
 var packet:Dictionary=JSON.parse_string(JSON.stringify(c.snapshot()));check(packet.v75.effects.size()>0,"new effects in multiplayer packet")
 var old:float=g.health.friend;g.role="guest";c.receive(packet);kit.step(10)
 check(g.health.friend==old,"guest cannot apply combat damage")
 check(c.v75.effects.size()==packet.v75.effects.size(),"guest retains replicated visuals")
 g.role="host";kit.reset();c.statuses.clear();g.mode="defense";g.north_gate.setup(g);g.hero_ids.host="ripplejaw";g.positions.host=Vector2(5000,7000)
 # Exercise the actual arcade projectile interception path rather than calling the passive directly.
 g.levels.host=10;g.health.host=105;g.invincible_until.host=0;g.shield_until.host=0;g.guards.clear();g.opponents.clear();g.missiles.clear();g.positions.friend=Vector2(6000,7000)
 for n in 3:
  g.invincible_until.host=0
  g.missiles.append({"owner":"enemy","pos":Vector2(4960,7000),"direction":Vector2.RIGHT,"speed":400,"distance":0.0,"damage":10.0,"range":500.0})
  g._simulate(.1)
 check(int(kit.scales.get("host",0))==3,"real defence projectile counter")
 check(c.projectiles.size()==1,"third real defence shot creates reflection")
 print("v75 multiplayer failures: ",failures);g.queue_free();await process_frame;await create_timer(.2).timeout;quit(failures)
