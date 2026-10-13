extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var g=load("res://scenes/arcade.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.party_tools.set_process(false);g.legacy.set_process(false)
 g._solo();g.started=false;g._set_mode("arena");g._add_player("friend",1);g.roster.append({"id":"friend","name":"Friend"});g.lobby_heroes.friend="gopher";g.selected_hero="nullweaver";g._start_match()
 var kit=g.adventure.combat.v78;var c=g.adventure.combat
 g.positions[g.my_id]=Vector2(700,700);g.local_pos=g.positions[g.my_id];g.positions.friend=Vector2(900,700);g.hero_ids.friend="gopher";g.health.friend=110;g.invincible_until.friend=0
 # Host rejects movement packets while a gopher attack forces a surface stop.
 kit.lock("friend",.3);var previous:Vector2=g.positions.friend
 g._packet("friend",{"type":"pos","x":910,"y":700,"aim":0.0});check(g.positions.friend==previous,"host rejects movement while attacking")
 check(c.speed_factor("p:friend")==0,"guest movement factor stopped")
 var packet:Dictionary=JSON.parse_string(JSON.stringify(kit.snapshot()))
 var copy=load("res://scripts/v78_heroes.gd").new();copy.combat=c;copy.receive(packet);check(copy.locked("friend"),"remote lock uses remaining duration");check(absf(copy.now()-kit.now())<.05,"guest uses host gait clock");copy.free()
 kit.reset();g.cooldown_at.friend={};g._attack("friend","secondary",Vector2.LEFT,Vector2(700,700))
 check(kit.immune("friend"),"remote dive immunity")
 g._hurt("friend",20,"enemy");check(g.health.friend==110,"remote damage blocked while underground")
 kit.step(.6);check(g.positions.friend.x<900 and not kit.immune("friend"),"pounce surfaces after travel")
 g.invincible_until.friend=0;g._hurt("friend",10,"enemy");check(g.health.friend<110,"remote surfaced takes damage")
 # Actual walking phase requires observed movement; stationary gophers cannot stay immune.
 kit.reset();kit.clock_offset=-Time.get_ticks_msec()/1000.0+.65
 kit.sample("friend",g.positions.friend,true);check(not kit.immune("friend"),"stationary gopher vulnerable")
 g.positions.friend+=Vector2(10,0);kit.sample("friend",g.positions.friend,true);check(kit.immune("friend"),"moving gopher burrows")
 kit.lock("friend",.3);check(not kit.immune("friend"),"attack forces surface immediately")
 # PvP pin line hits rival but not caster; host owns pin placement and damage.
 kit.reset();g.positions[g.my_id]=Vector2(700,700);g.local_pos=g.positions[g.my_id];g.positions.friend=Vector2(840,840);g.health.friend=110;g.invincible_until.friend=0;g.cooldown_at[g.my_id]={}
 c.cast(g.my_id,g.characters.nullweaver.primary,Vector2.RIGHT,18);c.cast(g.my_id,g.characters.nullweaver.primary,Vector2.DOWN,18)
 check(g.health.friend<110,"rift seam damages arena rival")
 var hp:int=int(g.health.friend);g.role="guest";c.cast(g.my_id,g.characters.nullweaver.special,Vector2.RIGHT,36);check(g.health.friend==hp,"guest cannot cause authoritative damage");g.role="host"
 print("v78 multiplayer failures: ",failures);g.queue_free();await process_frame;await create_timer(.2).timeout;quit(failures)
