extends SceneTree
var failures:=0
func check(ok:bool,name:String)->void:
 if not ok:failures+=1;print("FAIL: ",name)
func _initialize()->void:call_deferred("run")
func run()->void:
 var g=load("res://scenes/arcade.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.party_tools.set_process(false);g.legacy.set_process(false);g.presentation.set_process(false);g.level_cards.set_process(false);g.respawn_board.set_process(false)
 g._set_mode("coop");g.role="host";g.my_id="host";g.host_id="host";g.roster.assign([{"id":"host","name":"Host"},{"id":"friend","name":"Friend"}]);g._add_player("host",0);g._add_player("friend",1);g._start_match();g.start_countdown=0;g.field_obstacles.clear();g.obstacle_grid.clear();g.ice_walls.clear();g.opponents.clear();g.legacy.data=g.legacy.defaults();g.legacy.builds.clear()
 check(g.characters.size()>=65,"65 unlocked heroes")
 for id in ["lumen","harbor","mosaic","apiary","bailiff"]:
  check(g.characters[id].mastery.technique.ability!=g.characters[id].mastery.final_technique.ability,"independent mastery slots "+id)
  for pose in ["idle","walk1","walk2","attack"]:check(g.art.has(id+"_"+pose),"art "+id+pose)
 var c=g.adventure.combat;var p=c.party_heroes;g.positions.host=Vector2(1000,1000);g.positions.friend=Vector2(1100,1000);g.hero_ids.host="lumen";g.levels.host=10;g.health.friend=50
 p.cast("host",g.characters.lumen.primary,Vector2.RIGHT,16)
 for n in 8:p.step(.05)
 check(g.health.friend==57,"friendly dart heals and does not damage")
 g.mode="arena";g.pvp_rule="ffa";c.statuses.clear();p.reset();g.health.friend=100;p.cast("host",g.characters.lumen.primary,Vector2.RIGHT,16)
 for n in 8:p.step(.05)
 check(g.health.friend==84,"same dart damages opposing hero")
 g.mode="coop";g.health.host=50;g.health.friend=50;p.reset();c.v79.prepare("host",g.characters.lumen.special,Vector2.RIGHT,Vector2(1060,1000));p.cast("host",g.characters.lumen.special,Vector2.RIGHT,0)
 for n in 30:p.step(.1)
 check(g.health.host==68 and g.health.friend==68,"relay includes self and exactly3 heal ticks")
 # Five slots remain five slots after combining; merge never grants full health.
 p.reset();c.morrow.reset();g.hero_ids.host="mosaic"
 for n in 5:p.cast("host",g.characters.mosaic.primary,Vector2.RIGHT,7)
 check(p.slots("host","mosaic")==5 and not p.prepare("host",g.characters.mosaic.primary),"five-piece cap rejects sixth summon")
 var ids:Array=p.family_units("host","mosaic");c.morrow.units[ids[0]].hp=12;p.step(2.1)
 var fused:Array=p.family_units("host","mosaic");check(fused.size()==1 and p.slots("host","mosaic")==5,"quiet companions combine preserving capacity")
 var unit:Dictionary=c.morrow.units[fused[0]];check(unit.hp==140 and unit.max_hp==160 and unit.damage==23 and unit.time==14,"merge sums actual health, strengthens and refreshes time")
 c.v79.prepare("host",g.characters.mosaic.secondary,Vector2.RIGHT,Vector2(1300,1000));p.cast("host",g.characters.mosaic.secondary,Vector2.RIGHT,0);check(p.family_units("host","mosaic").size()==5,"scatter splits all5 pieces")
 var total:=0.0
 for id in p.family_units("host","mosaic"):total+=float(c.morrow.units[id].hp)
 check(total==140,"scatter cannot heal")
 p.reset();c.morrow.reset();g.hero_ids.host="apiary";p.cast("host",g.characters.apiary.secondary,Vector2.RIGHT,6);p.cast("host",g.characters.apiary.secondary,Vector2.RIGHT,6);check(p.slots("host","apiary")==4,"passive hive cap4")
 var victim:Dictionary={"pos":Vector2(1180,1000),"hp":500.0,"max_hp":500.0,"uid":991,"type":"bramble","boss":false,"attack_timer":10.0};g.opponents.append(victim)
 for n in 30:c.step(.05)
 check(victim.hp<500,"drones attack through normal projectile collision")
 # Delayed control and countering projectile field.
 p.reset();c.v79.prepare("host",g.characters.bailiff.special,Vector2.RIGHT,Vector2(1180,1000));p.cast("host",g.characters.bailiff.special,Vector2.RIGHT,28);p.step(.4);check(not c.stunned(c.npc_key(victim)),"court gives warning before stun");p.step(.41);check(c.stunned(c.npc_key(victim)),"court stuns after warning")
 c.v79.prepare("host",g.characters.harbor.mastery.final_technique.attack,Vector2.RIGHT,Vector2(1100,1000));p.cast("host",g.characters.harbor.mastery.final_technique.attack,Vector2.RIGHT,0);check(p.catch_shot(Vector2(1100,900),Vector2(1100,1000),"enemy"),"buoy catches hostile shot");check(not p.catch_shot(Vector2(1100,900),Vector2(1100,1000),"friend"),"buoy does not catch allies")
 var packet:Dictionary=c.snapshot();var clone=load("res://scripts/party_heroes.gd").new();clone.receive(packet.party_heroes);check(clone.fields.size()==p.fields.size(),"new effect snapshot replicated");clone.free()
 # Guest attacks use the same host dispatcher; team shots cannot heal rivals.
 g.opponents.clear();p.reset();c.morrow.reset();g.positions.friend=Vector2(1100,1000);g.hero_ids.friend="lumen";g.levels.friend=10;g.health.host=50;g.cooldown_at.friend={};c.statuses.clear()
 g._packet("friend",{"type":"attack","style":"primary","angle":PI,"target":[1000,1000]})
 for n in 8:p.step(.05)
 check(g.health.host==57,"guest dart heals host through authoritative attack packet")
 g.hero_ids.friend="mosaic";g.cooldown_at.friend={};g._packet("friend",{"type":"attack","style":"primary","angle":PI,"target":[1000,1000]});check(p.slots("friend","mosaic")==1,"guest summon packet creates owned companion")
 var hp_before:int=g.health.host;g.role="guest";p.cast("friend",g.characters.lumen.primary,Vector2.LEFT,16);p.step(1);check(g.health.host==hp_before,"guest cannot simulate authoritative healing");g.role="host"
 g.mode="defense";g.north_gate.game=g;g.opponents.append({"pos":Vector2(1300,1000),"hp":1.0,"type":"gate_rival","boss":false,"uid":992});g._hit_enemy(0,2,"host");check(g.arena_records.host.kills==1 and g.kills.host==1,"north-gate rival counts as hero KO and all kill")
 # Non-arena deaths and kills are match stats too; board disappears when revived.
 g.health.friend=1;g.mode="defense";g._hurt("friend",10,"enemy");check(g.arena_records.get("friend",{}).get("deaths",0)==1,"defence deaths counted")
 g.health.host=0;g.respawn_at.host=Time.get_ticks_msec()+2500;g.respawn_board._process(.1);check(g.respawn_board.panel.visible,"dead player sees respawn board");g.health.host=50;g.respawn_board._process(.1);check(not g.respawn_board.panel.visible,"board hides after respawn")
 g.contributions.host={"damage":50};g.contributions.friend={"damage":200};g.kills.host=4;g.kills.friend=2;check(g.respawn_board.rows()[0].id=="friend","damage sorting");g.respawn_board.sort_by="kills";check(g.respawn_board.rows()[0].id=="host","kills sorting")
 g.queue_free();await process_frame;print("v88 party and leaderboard failures: ",failures);quit(failures)
