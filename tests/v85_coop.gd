extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var g=load("res://scenes/arcade.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.party_tools.set_process(false);g.legacy.set_process(false)
 g._set_mode("coop");g.role="host";g.my_id="host";g.host_id="host";g.roster.assign([{"id":"host","name":"Host"},{"id":"friend","name":"Friend"}]);g._add_player("host",0);g._add_player("friend",1)
 g._start_match();g.start_countdown=0;g.legacy.data=g.legacy.defaults();g.legacy.builds.clear();g.field_obstacles.clear();g.opponents.clear()
 g.hero_ids.host="morrow";g.hero_ids.friend="mantis";g.levels.host=10;g.levels.friend=10;g.health.host=120;g.health.friend=100;g.positions.host=Vector2(1000,1000);g.positions.friend=Vector2(1200,1000);g.local_pos=g.positions.host
 var c=g.adventure.combat
 for n in 3:c.morrow.fallen({"pos":Vector2(1080+n*25,1020),"type":"bramble"})
 g.cooldown_at.host={};g._attack("host","secondary",Vector2.RIGHT,Vector2(1100,1000));check(c.morrow.units.size()==3,"remote-compatible raise through host attack dispatch")
 g.cooldown_at.host={};g._attack("host","special",Vector2.RIGHT,Vector2(1100,1000));check(c.morrow.links.has("host"),"host creates pool")
 var initial:float=c.morrow.links.host.hp;g.invincible_until.host=0;g._hurt("host",30,"enemy")
 check(absf(float(c.morrow.links.host.hp)-(initial-30))<.01,"multiplayer hero damage shared once")
 var id:String=c.morrow.units.keys()[0];var old:float=c.morrow.links.host.hp;g.invincible_until.host=Time.get_ticks_msec()+10000;c.morrow.hurt(id,20,"enemy")
 check(absf(float(c.morrow.links.host.hp)-(old-20))<.01,"linked summon damage bypasses hero immunity after allocation")
 check(g.health.host>0,"survives finite pool damage")
 var snapshot:Dictionary=c.snapshot();var clone=load("res://scripts/morrow_combat.gd").new();clone.receive(snapshot.morrow);check(clone.snapshot()==snapshot.morrow,"corpses bodies health mesh replicate");clone.free()
 check(c.hostile("enemy").has("p:"+id),"enemies can target summons")
 check(not c.hostile("friend").has("p:"+id),"co-op teammate cannot target summons")
 g.mode="arena";g.pvp_rule="ffa";check(c.hostile("friend").has("p:"+id),"arena rival can target summon")
 check(c.v59.rival_id(id)=="host" and g.adventure.alive(id),"AI target maps summon to owner")
 # A depleted pool must trigger actual death, even if a hero shield is active.
 c.morrow.hurt(id,10000,"enemy");check(g.health.host==0 and c.morrow.units.is_empty(),"zero pool kills owner and clears echoes without resurrection")
 g.health.friend=80;g.invincible_until.friend=0;g.cooldown_at.friend={};g._attack("friend","secondary",Vector2.RIGHT,Vector2(1400,1000));g._hurt("friend",20,"enemy")
 check(g.health.friend==88 and int(c.mantis.poise.friend)==1,"remote guard blocks and heals")
 g._hurt("friend",20,"enemy");check(g.health.friend==68,"guard blocks only one multiplayer hit")
 var guard_copy=load("res://scripts/mantis_combat.gd").new();guard_copy.receive(c.mantis.snapshot());check(guard_copy.snapshot()==c.mantis.snapshot(),"guard charge visuals replicate");guard_copy.free()
 print("v85 co-op failures: ",failures);g.queue_free();await process_frame;quit(failures)
