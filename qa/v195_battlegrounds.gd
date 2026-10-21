extends SceneTree
var checks=0
var failures=[]
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_dedicated_server",true);root.set_meta("fx_dev_match",true);root.get_node("FXActivity").set_enabled(false);root.get_node("FXCommunityHeroes").set_process(false)
 var a=load("res://network/arena.gd").new();root.add_child(a);current_scene=a;await process_frame;a.set_process(false);a.set_physics_process(false);a.legacy.set_process(false);a.mode="battlegrounds";a._set_mode("battlegrounds");a.bg_team_size=3;a.bg_map="woodland";a.arena_seats=6;a._sync_bg_pickers();a.my_id="p0";a.host_id="p0";a.role="host";a.spectator_host=false
 for n in 6:
  var id="p"+str(n);a.roster.append({"id":id,"name":id,"hero":"ram","team":n/3});a._add_player(id,n);a.teams[id]=n/3;a.lobby_heroes[id]="ram"
 a.spectator_host=false;a._start_match();a.start_countdown=0;a.teams={"p0":0,"p1":0,"p2":0,"p3":1,"p4":1,"p5":1};var bg=a.battlegrounds;print("BATTLE195 INIT ",a.mode," role=",a.role," roster=",a.roster.size()," owners=",bg.owners," started=",a.started);var cmd=bg.command;var home:Dictionary=bg.bases[bg.owners.p0];var enemy:Dictionary=bg.bases[bg.owners.p3];a.positions.p0=home.pos;a.health.p0=60;a.gold.p0=10000
 check(bg.TYPES.size()==11,"eleven troop archetypes");check(bg.available(8,0) and bg.available(8,1),"lancer shared by factions");check(bg.available(9,0) and not bg.available(9,1),"standardbearer exclusive");check(bg.available(10,1) and not bg.available(10,0),"mossbinder exclusive")
 check(bg.buy("p0","unit:lancer") and bg.buy("p0","unit:standard"),"blue buys both new roles");check(not bg.buy("p0","unit:mossbinder"),"blue cannot buy opponent exclusive");a.positions.p3=enemy.pos;a.gold.p3=10000;check(bg.buy("p3","unit:mossbinder"),"red recruits exclusive")
 check(not bg.shielded(1),"capital vulnerable while barracks stand");bg.damage("bgheart:1",25,"p0");check(bg.heart_hp[1]==2575,"hero can damage capital directly");bg.damage("bgheart:0",100,"p0");check(bg.heart_hp[0]==2600,"friendly capital protected from friendly damage")
 check(bg.spawn("p0").distance_to(bg.heart_pos(0))<230,"hero respawns at capital");a.positions.p0=bg.heart_pos(0);var hp=int(a.health.p0);cmd.step(1);check(a.health.p0==hp+4,"capital heals four HP per second");a.positions.p0=home.pos;hp=a.health.p0;cmd.step(1);check(a.health.p0==hp+4,"personal base heals four HP per second");a.health.p0=0;cmd.step(1);check(a.health.p0==0,"healing never revives defeated hero");a.health.p0=60;a.positions.p0=Vector2(3000,2200)
 check(cmd.execute("p0","order:recall"),"ready recall works");check(a.positions.p0.distance_to(home.pos)<200,"recall lands at own barracks");check(not cmd.execute("p0","order:recall"),"second recall blocked");bg.clock=120;check(cmd.execute("p0","order:recall"),"recall ready after two minutes");a.health.p0=0;check(not cmd.execute("p0","order:capital"),"dead heroes cannot issue army orders");a.health.p0=60
 bg.units.clear();check(bg.spawn_unit(home,0,0),"spawn ordinary unit");var first=bg.units.keys()[0];var ally:Dictionary=bg.bases[bg.owners.p1];bg.spawn_unit(ally,0,0);var ally_key=bg.units.keys()[1]
 check(cmd.execute("p0","order:base"),"base rally command accepted");check(bg.units[first].order=="open","base rally preserves already deployed units");bg.spawn_unit(home,0,0);var fresh=bg.units.keys()[2];check(bg.units[fresh].order=="base","fresh recruits obey base rally");check(cmd.execute("p0","order:capital"),"capital rally accepted");check(bg.units[first].order=="capital" and bg.units[fresh].order=="capital","capital rally redirects all own troops");check(bg.units[ally_key].order=="open","ally player's army unaffected");check(cmd.goal(bg.units[first]).distance_to(bg.heart_pos(0))<=180,"rally point own capital")
 cmd.execute("p0","order:center");check(cmd.goal(bg.units[first]).distance_to(bg.SIZE*.5)<=220,"center rally points to market");cmd.execute("p0","order:enemy_capital");check(cmd.target(bg.units[first])=="bgheart:1","attack capital targets capital");cmd.execute("p0","order:open");check(bg.units[fresh].order=="open","open attack releases held army")
 bg.units.clear();for n in 32:check(bg.spawn_unit(home,0,n),"spawn within population cap")
 check(not bg.spawn_unit(home,0,33),"32 troop limit enforced");bg.units.erase(bg.units.keys()[0]);check(bg.spawn_unit(home,8,0),"replacements resume when room opens")
 home.counts=[1,1,1,1,1,1,1,1];bg.enqueue_wave(home);check(home.queue.size()==8,"old eight-role wave fixture safe");home.counts=[1,1,1,1,1,1,1,1,1,1,1];bg.enqueue_wave(home);check(home.queue.size()==10 and 9 in home.queue and 10 not in home.queue,"queue recruits all permitted roles")
 var money=int(a.gold.p0);cmd.hero_bounty("p3","p0");check(a.gold.p0-money==350,"hero kill awards 350 CC");money=a.gold.p0;cmd.hero_bounty("p1","p0");check(a.gold.p0==money,"friendly kill earns no bounty");cmd.hero_bounty("p3","bgarmy:p0");check(a.gold.p0-money==350,"own army hero kill credits its commander")
 var copy=bg.snapshot();var receiver=load("res://scripts/battlegrounds.gd").new();receiver.game=a;receiver.command.bg=receiver;receiver.receive(JSON.parse_string(JSON.stringify(copy)));check(receiver.units.size()==bg.units.size(),"snapshot round trip retains troops");check(receiver.command.recall_ready.p0==cmd.recall_ready.p0,"snapshot carries recall cooldown");check(receiver.bases[bg.owners.p0].order==home.order,"snapshot carries army orders")
 var gateway=load("res://network/server.gd").new()
 for key in bg.COMMANDS+ ["unit:lancer","unit:standard","unit:mossbinder"]:check(gateway.valid_action({"type":"bg_upgrade","key":key,"input_seq":0}),"server accepts "+key)
 check(not gateway.valid_action({"type":"bg_upgrade","key":"order:godmode","input_seq":0}),"server rejects unknown command");gateway.free()
 var p=Vector2(1900,940);var goal=Vector2(2400,940)
 for n in 180:p=cmd.move_unit(p,cmd.direction("qa_path",p,goal)*11.5);bg.clock+=.1
 check(p.distance_to(goal)<100,"troop navigation routes around tree island")
 var rng=RandomNumberGenerator.new();rng.seed=195;var safe=true
 for n in 1000:
  var start=Vector2(rng.randf_range(100,6700),rng.randf_range(100,4300));var finish=start+Vector2(rng.randf_range(-90,90),rng.randf_range(-90,90))
  if cmd.clear_path(start,finish) and not a._clear_path(start,finish):safe=false
 check(safe,"analytic movement never crosses sampled terrain or bounds in 1000 probes")
 home.counts=[2,0,0,0,0,0,0,0,0,0,0];a.positions.p0=home.pos;a.gold.p0=100000;a.health.p0=a._max_hp("p0");var state={"shop":0.0,"order":0}
 for n in 16:state.shop=0.0;bg.clock+=9;a.bots.strategy("p0",a.positions.p0,Vector2.RIGHT,state)
 check(home.counts[8]>0 and home.counts[9]>0,"AI can recruit Lancers and own exclusive")
 check(home.order in ["base","capital","enemy_base","enemy_capital"],"AI issues strategic army orders")
 bg.units.clear();bg.spawn_unit(home,9,0);var banner=bg.units.keys()[0];bg.spawn_unit(home,0,0);var foot=bg.units.keys()[1];bg.units[banner].pos=Vector2(800,700);bg.units[foot].pos=Vector2(820,700);bg.unit_grid_dirty=true
 check(is_equal_approx(cmd.banner_bonus(bg.units[foot]),1.1),"standardbearer boosts nearby troops ten percent");bg.spawn_unit(home,9,0);bg.units[bg.units.keys()[-1]].pos=Vector2(810,710);bg.unit_grid_dirty=true;check(is_equal_approx(cmd.banner_bonus(bg.units[foot]),1.1),"two standardbearers do not stack")
 bg.units.clear();bg.spawn_unit(enemy,10,0);var moss=bg.units.keys()[0];bg.units[moss].pos=Vector2(900,700);bg.units[moss].cooldown=0;a.positions.p0=Vector2(1100,700);a.health.p0=120;bg.unit_grid_dirty=true;a.adventure.combat.projectiles.clear();bg.tick_units(.1)
 check(a.adventure.combat.projectiles.any(func(shot):return shot.style=="homing" and shot.stats.get("slow_duration",0)==2 and shot.stats.get("slow",0)==.75),"mossbinder fires seeking slowing spores")
 var capital_hp=float(bg.heart_hp[1]);bg.blast(bg.heart_pos(1),100,30,"bgarmy:p0",0);check(bg.heart_hp[1]==capital_hp-30,"siege splash damages enemy capital");var base_hp=float(enemy.hp);bg.blast(enemy.pos,100,30,"bgarmy:p0",0);check(enemy.hp==base_hp-30,"siege splash damages enemy barracks")
 var art=preload("res://scripts/battleground_art.gd")
 check(art.pose({"attack_at":1.0},1.1)==6,"strike animation selected");check(art.pose({"attack_at":1.0},1.3)==7,"recovery animation selected");check(art.pose({"attack_at":-10.0,"winding":true},1.0)==5,"windup animation selected")
 for team in 2:
  for kind in 11:
   for pose in 8:check(preload("res://scripts/source_art.gd").texture("res://assets/battlegrounds/%d_%d_%d.svg" % [team,kind,pose])!=null,"troop pose loads")
 var result={"passed":failures.is_empty(),"checks":checks,"failures":failures};DirAccess.make_dir_recursive_absolute("res://validation/v195");var f=FileAccess.open("res://validation/v195/battlegrounds.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close();print("V195 BATTLEGROUNDS ",JSON.stringify(result));receiver.command.bg=null;receiver=null;cmd.bg=null;quit(0 if failures.is_empty() else 1)
