extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
 game.selected_character="agent";game.start_run(false,"practice");game.practice=false;game.level=6;game.enemies.clear();game.position_in_world=Vector2(1100,600)
 var combat=game.adventure.combat;var agent=combat.agent
 check(game.manifest.characters.size()==43 and game.art.has("agent_idle") and game.hero.name=="The Agent","hero 42 registered and has portrait")
 game.cooldowns.special=0;game.fire("special")
 check(game.cooldowns.special==0 and agent.ambushes.is_empty(),"empty-target Ambush does not spend cooldown")
 game.adventure.spawn("training_dummy",Vector2(1150,600),500,false);var front:Dictionary=game.enemies[-1]
 game.adventure.spawn("training_dummy",Vector2(1230,600),500,false);var rear:Dictionary=game.enemies[-1]
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,42)
 check(is_equal_approx(front.hp,458) and rear.hp==500 and agent.rays.size()==7,"seven six-damage rays stop at the first foe")
 front.hp=1;agent.rays.clear();combat.cast("solo",game.hero.primary,Vector2.RIGHT,42)
 check(not game.enemies.has(front) and rear.hp==500,"simultaneous rays cannot pierce newly defeated front target")
 agent.reset();game.enemies.clear();game.adventure.spawn("training_dummy",Vector2(1350,600),500,false);front=game.enemies[-1]
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,42)
 check(front.hp==494,"thin distant target receives only the center ray")
 agent.reset();game.enemies.clear();game.adventure.spawn("training_dummy",Vector2(1300,800),500,false);front=game.enemies[-1]
 var stats:Dictionary=game.hero.secondary.duplicate(true)
 check(agent.prepare("solo",stats,Vector2.RIGHT,Vector2(1300,600)),"lens accepts valid placement")
 combat.cast("solo",stats,Vector2.RIGHT,0);agent.step(.36);combat.cast("solo",game.hero.primary,Vector2.RIGHT,42)
 check(is_equal_approx(front.hp,485.6) and agent.marks.get("solo",{}).has(combat.npc_key(front)),"three lens-bent rays reach off-angle foe at 80 percent damage and mark")
 var special:Dictionary=game.hero.special.duplicate(true)
 check(agent.prepare("solo",special,Vector2(1,1).normalized(),front.pos),"cursor selects the intended Ambush target")
 combat.cast("solo",special,Vector2(1,1).normalized(),96)
 var entry:Dictionary=agent.ambushes[0];var away:Vector2=(front.pos-game.position_in_world).normalized()
 check(entry.spots.size()==3,"Ambush places three projected agents")
 var angles:Array=[]
 for spot in entry.spots:
  var offset:Vector2=combat.vec(spot)-front.pos
  check(is_equal_approx(offset.length(),180) and offset.dot(away)>0,"each circle is behind the target")
  angles.append(rad_to_deg(away.angle_to(offset)))
 check(absf(float(angles[0])+60)<.001 and absf(float(angles[1]))<.001 and absf(float(angles[2])-60)<.001,"three circles span the rear 120-degree arc")
 var before:float=front.hp;agent.step(.59)
 check(front.hp==before and not entry.fired,"warning flashes deal no damage")
 agent.step(.02);check(front.hp==before and float(entry.age)>.6,"agents appear after two flashes without immediate damage")
 agent.step(.98);check(front.hp==before,"one-second charge is respected")
 agent.step(.02);check(is_equal_approx(front.hp,before-111) and entry.fired,"three 32-damage beams plus marked-target bonus fire once")
 agent.step(.5);check(is_equal_approx(front.hp,before-111) and agent.ambushes.is_empty(),"beam visual cannot repeatedly deal damage")
 game.start_run(false,"neon_crucible");game.level=6;game.enemies.clear();game.position_in_world=Vector2(2600,650)
 game.adventure.spawn("sweep_drone",Vector2(2820,650),500,false);front=game.enemies[-1]
 game.adventure.spawn("sweep_drone",Vector2(2500,650),500,false);rear=game.enemies[-1]
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,42)
 check(front.hp==500,"solid server racks stop primary laser rays")
 special=game.hero.special.duplicate(true);agent.prepare("solo",special,Vector2.RIGHT,front.pos);combat.cast("solo",special,Vector2.RIGHT,96);agent.step(1.61)
 check(front.hp==404 and rear.hp==468,"Ambush pierces the target and solid walls to hit another foe")
 agent.reset();special=game.hero.special.duplicate(true);check(not agent.prepare("solo",special,Vector2.RIGHT,Vector2(NAN,0)),"invalid target coordinates rejected")
 var host=load("res://scenes/arcade.tscn").instantiate();root.add_child(host);await process_frame;host.set_process(false);host._set_mode("defense");host._solo();host.hero_ids[host.my_id]="agent";host._start_match();host.opponents.clear();host.levels[host.my_id]=6
 var hc=host.adventure.combat;var origin:Vector2=host.positions[host.my_id]
 host.positions["friend"]=origin+Vector2(50,0);host.health["friend"]=100;host.hero_ids["friend"]="ram"
 hc.cast(host.my_id,host.characters.agent.primary,Vector2.RIGHT,42)
 check(host.health.friend==100,"shotgun excludes co-op allies")
 host.mode="arena";host.pvp_rule="ffa";hc.agent.reset();hc.cast(host.my_id,host.characters.agent.primary,Vector2.RIGHT,42)
 check(host.health.friend==58,"shotgun damages PvP opponents")
 host.positions.friend=origin+Vector2(250,0);host.health.friend=500
 host.cooldown_at.clear();host._attack(host.my_id,"special",Vector2.RIGHT,host.positions.friend)
 check(hc.agent.ambushes.size()==1,"real multiplayer attack selects target and starts Ambush")
 var packet:Dictionary=JSON.parse_string(JSON.stringify(host._snapshot()))
 check(packet.adventure.combat.agent.ambushes[0].spots.size()==3,"target and projected-agent circles synchronize")
 hc.agent.step(1.61);check(host.health.friend==404 and host.health[host.my_id]>0,"PvP Ambush deals three beams without self damage")
 var data:Dictionary=packet.adventure.combat.agent;hc.agent.reset();hc.agent.receive(data)
 check(hc.agent.ambushes.size()==1 and hc.agent.ambushes[0].target=="p:friend","snapshot restores selected target")
 host.role="guest";var age:float=hc.agent.ambushes[0].age;hc.agent.step(2)
 check(hc.agent.ambushes[0].age==age and not hc.agent.ambushes[0].fired,"guest renders Ambush without applying independent damage")
 for node in [game,host]:
  for voice in node.journey.voices:voice.stop()
  node.queue_free()
 await create_timer(.3).timeout;print("v62: ",failures," failures");quit(1 if failures else 0)
