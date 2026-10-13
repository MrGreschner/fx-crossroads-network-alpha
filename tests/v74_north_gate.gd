extends SceneTree
var failures:=0
func check(ok:bool,text:String)->void:
 if not ok:failures+=1;print("FAIL: ",text)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var game=load("res://scenes/arcade.tscn").instantiate();root.add_child(game);await process_frame
 game.set_process(false);game.legacy.set_process(false);game.role="host";game.my_id="host";game.host_id="host";game._add_player("host",0);game._set_mode("defense");game._start_match()
 var gate=game.north_gate
 check(game.FIELD.size==Vector2(10600,9400),"new field")
 for lane in 3:
  for n in range(1,int(gate.length_of(lane)/40)):
   var a:Vector2=gate.point_at(lane,n*40);var b:Vector2=gate.point_at(lane,n*40+40)
   check(game._clear_path(a,b),"clear lane %d segment %d" % [lane,n])
 check(not game._clear_path(Vector2(3000,4000),Vector2(3000,4500)),"water blocks shortcut")
 gate.reinforce();check(game.guards.size()==9,"two base + one outpost per lane")
 for lane in 3:
  var base:=0;var post:=0
  for guard in game.guards:
   if int(guard.lane)==lane:
    if str(guard.origin)=="base":base+=1
    else:post+=1
  check(base==2 and post==1,"lane reinforcements "+str(lane))
 var first:Vector2=game.guards[0].pos;game._simulate_guards(1.0);check(game.guards[0].pos.distance_to(first)>50,"soldiers march along road")
 for i in game.guards.size():
  for j in range(i+1,game.guards.size()):check((game.guards[i].pos as Vector2).distance_to(game.guards[j].pos)>=45,"soldier separation")
 game.gold.host=100
 for n in 5:gate.guard_bounty(false)
 check(game.gold.host==102,"fractional twenty-percent gold accumulates")
 game._add_player("friend",1);game.gold.friend=100
 gate.guard_bounty(true)
 check(game.gold.host==106 and game.gold.friend==104,"each player receives boss bounty share")
 game.opponents.clear();game.wave=1;gate.spawn_wave(1);check(game.opponents.size()==7,"solo opening wave")
 var normal=game.opponents[0];game._hit_enemy(0,10000,"lane_guard");check(game.gold.friend==104,"no rounded-up free gold per guard kill")
 var old:int=gate.wave_count(15);gate.party_size=4;check(gate.wave_count(15)>old and gate.creep_health(15)>1,"four-player scaling")
 check(gate.boss_health()>2100,"scaled checkpoint boss")
 gate.party_size=1;game.opponents.clear();game.wave=30;gate.spawn_wave(30)
 check(game.opponents.filter(func(f:Dictionary):return f.type=="tollbreaker").size()==1,"one unique wave-30 boss")
 check(not gate.next_wave_allowed(),"checkpoint waits for boss")
 gate.spawn_rival();var rival:Dictionary=gate.rival_body();check(not rival.is_empty() and bool(rival.campaign_hero),"rival spawn")
 game._track_card_progress();check(game.defense_cleared_wave<30,"boss gates town unlock")
 var index:=-1
 for n in game.opponents.size():
  if game.opponents[n].type=="tollbreaker":index=n
 game._hit_enemy(index,100000,"host");check(gate.boss_defeated,"boss kill recognized")
 check(not gate.next_wave_allowed(),"checkpoint also waits for army")
 game.opponents.assign(game.opponents.filter(func(f:Dictionary):return bool(f.get("campaign_hero",false))))
 game._track_card_progress();check(game.defense_cleared_wave==30,"recurring rival does not block wave completion")
 check(game.legacy.data.town.get("bastion",false),"bastion unlock after real boss defeat")
 check(gate.next_wave_allowed(),"endless waves resume")
 gate.rival_gain(6);check(gate.rival_level==2,"rival levels from player kills")
 gate.rival_gain(6);check(gate.rival_level>=3,"rival secondary unlock")
 var saved_level:int=gate.rival_level
 index=game.opponents.find(gate.rival_body());game._hit_enemy(index,100000,"host")
 check(gate.rival_body().is_empty() and gate.rival_respawn>0,"rival death starts cooldown")
 gate.rival_respawn=.01;gate.step(.02)
 check(not gate.rival_body().is_empty() and gate.rival_level==saved_level,"rival respawns retaining level")
 rival=gate.rival_body();rival.pos=game.positions.host+Vector2(100,0);rival.dodge_cd=0;rival.think=0;rival.hp=rival.max_hp;gate.step_rival(rival,.02)
 check(float(rival.dodge_left)>0,"rival dodge on nearby threat")
 var before:int=gate.rival_kills;game.guards.clear();game._spawn_defense_guard(0,"melee",1,10);gate.hurt_guard(0,10,"gate_rival")
 check(gate.rival_kills==before+1,"guard kills grant rival XP")
 game.health.host=1;game.inventory.host=[];game.invincible_until.host=0;game.shield_until.host=0;before=gate.rival_kills;game._hurt("host",1000,"gate_rival")
 check(gate.rival_kills==before+1,"player kill attribution grants rival XP")
 var packet:Dictionary=JSON.parse_string(JSON.stringify(game._snapshot()));check(packet.north_gate.rival_level==gate.rival_level,"rival state serializes")
 check(packet.enemies[0].campaign_hero,"rival flag serializes")
 gate.warn(game.positions.friend,120,.1,12,"rival_snare","gate_rival");game.health.friend=100;gate.step(.11)
 check(game.health.friend<100 and game.adventure.combat.effect_time("p:friend","slow")>0,"telegraphed snare damage and slow")
 gate.rival_level=6;rival=gate.rival_body();rival.hp=rival.max_hp;rival.pos=game.positions.friend+Vector2(300,0);rival.target="p:friend";rival.think=1;rival.special_cd=0;gate.step_rival(rival,.02)
 check(gate.warnings.filter(func(w:Dictionary):return w.kind=="crossfire").size()==3,"three-point special telegraphs")
 var remote=load("res://scripts/north_gate.gd").new();remote.game=game;remote.receive(gate.snapshot());check(remote.rival_level==gate.rival_level and remote.warnings.size()==gate.warnings.size(),"guest display state")
 print("v74 North Gate failures: ",failures);game.queue_free();await process_frame;await create_timer(.2).timeout;quit(failures)
