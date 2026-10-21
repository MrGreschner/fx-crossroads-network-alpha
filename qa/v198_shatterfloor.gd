extends "res://qa/v197_objectives.gd"
func start_shatter(teamed:bool=false)->RefCounted:
 start("shatterfloor",teamed)
 var s=g.arena_world.shatter
 s.reset_round()
 for id in g.positions:g.invincible_until[id]=0
 return s
func run()->void:
 root.set_meta("fx_dedicated_server",true);root.set_meta("fx_dev_match",true);root.get_node("FXActivity").set_enabled(false);root.get_node("FXCommunityHeroes").set_process(false)
 g=load("res://network/arena.gd").new();root.add_child(g);current_scene=g;await process_frame;g.set_process(false);g.set_physics_process(false);g.legacy.set_process(false);g.mode="arena";g._set_mode("arena");g.arena_seats=8;g.role="host";g.spectator_host=false;g.my_id="p0";g.host_id="p0"
 for n in 8:
  var id="p"+str(n);g.roster.append({"id":id,"name":"Player "+str(n+1)});g._add_player(id,n);g.teams[id]=n%2;g.lobby_heroes[id]="ram" if n%2==0 else "cat"
 var s=start_shatter()
 check(g.arena_world.MAPS.size()==10 and s.layers.size()==8,"ten maps and eight Shatterfloor participants")
 check(s.cells.size()==3 and s.cells[0].size()==140,"three bounded floor grids")
 var p:Vector2=g.positions.p0;var i=s.tile_index("p0",p)
 s.step(.81);check(s.remaining(0,i)>.8 and s.remaining(0,i)<.9,"stepping starts visible crack warning")
 s.step(.86);check(s.layers.p0==1 and g.health.p0>0,"first fall drops to second floor alive")
 check(absf(g.positions.p0.y-p.y-1040)<1,"drop preserves horizontal route and shifts one deck")
 s.grace.p0=0;s.cells[1][s.tile_index("p0",g.positions.p0)]=0;s.step(.01);check(s.layers.p0==2,"second fall reaches final deck")
 s.grace.p0=0;s.cells[2][s.tile_index("p0",g.positions.p0)]=0;s.step(.01);check(s.eliminated.has("p0") and g.health.p0==0,"bottom fall eliminates without combat health damage")
 g._simulate(.1);check(g.health.p0==0 and g.started,"ordinary arena respawn and KO end disabled")
 s=start_shatter();g.positions.p0=Vector2(500,500);g.positions.p1=Vector2(580,500);var hp=int(g.health.p1)
 check(s.action("p0","primary",Vector2.RIGHT),"primary performs uniform shove")
 check(g.positions.p1.x==644 and g.health.p1==hp,"shove displaces sixty-four pixels without damage")
 check(not s.action("p0","primary",Vector2.RIGHT),"shove cooldown enforced")
 s.clock+=.76;g.positions.p0=g.positions.p1-Vector2(80,0);var before:Vector2=g.positions.p1;s.action("p0","primary",Vector2.RIGHT);check(g.positions.p1==before,"knockback protection blocks repeated shoves")
 check(not s.action("p0","special",Vector2.RIGHT),"hero special disabled")
 check(not s.action("p0","secondary",Vector2(INF,0)),"invalid hop direction rejected")
 check(s.action("p0","secondary",Vector2.RIGHT),"shared hop starts")
 check(not s.action("p0","secondary",Vector2.RIGHT),"hop cooldown enforced")
 var old:Vector2=g.positions.p0;s.cells[0].fill(0.0);s.step(.1);check(g.positions.p0.x>old.x and s.layers.p0==0,"hop crosses missing tiles without falling")
 s.step(.3);check(s.layers.p0==1,"landing over a hole drops to lower deck")
 g._hurt("p0",10000,"p1");check(g.health.p0>0,"ordinary combat cannot kill players")
 var Move=preload("res://network/movement.gd");g.hero_ids.p0="ram";g.hero_ids.p1="cat";s.hops.clear()
 var a=Move.advance(g,"p0",Vector2(500,500),Vector2.RIGHT);var b=Move.advance(g,"p1",Vector2(500,500),Vector2.RIGHT)
 check(a.is_equal_approx(b) and absf(a.x-500-260.0/60)<.01,"all heroes use identical shared movement speed")
 s=start_shatter(true);g.positions.p0=Vector2(500,500);g.positions.p2=Vector2(570,500);s.action("p0","primary",Vector2.RIGHT);check(g.positions.p2.x==570,"teammates cannot shove each other")
 s.layers.p1=1;g.positions.p1=Vector2(570,500);s.clock=2;s.action("p0","primary",Vector2.RIGHT);check(g.positions.p1.x==570,"shoves cannot hit another floor")
 s=start_shatter();s.eliminated={"p0":1.0,"p1":1.0,"p2":2.0,"p3":3.0,"p4":4.0,"p5":5.0,"p6":6.0};s.round_time=7;s.finish_round()
 check(s.points.p0==s.points.p1 and s.points.p7==8,"simultaneous falls tie and survivor earns placement points")
 check(s.intermission==4,"round break allows review")
 s.step(4.1);check(s.round_number==2 and s.eliminated.is_empty() and g.health.p0>0,"new round rebuilds floors and restores contestants")
 s.round_number=3;s.finish_round();check(not g.started and g.arena_outcomes.has("p0"),"third round finishes match and records outcomes")
 s=start_shatter(true);s.points.p0=8;s.points.p2=5;s.points.p1=2;check(s.outcome("p0")=="win" and s.outcome("p2")=="win" and s.outcome("p1")=="loss","team totals decide shared result")
 var packet=JSON.parse_string(JSON.stringify(g.arena_world.snapshot()));var clone=load("res://scripts/arena_world.gd").new();clone.setup(g,"shatterfloor");clone.receive(packet);check(clone.shatter.layers==JSON.parse_string(JSON.stringify(s.layers)) and clone.shatter.points==JSON.parse_string(JSON.stringify(s.points)) and clone.shatter.cells==JSON.parse_string(JSON.stringify(s.cells)),"floors actions and scores survive JSON replication")
 s=start_shatter();s.round_time=22;s.step(.01);check(not is_inf(s.remaining(0,0)),"outside-in erosion starts with warning");check(is_inf(s.remaining(0,70+7)),"centre remains safe during first erosion ring")
 s=start_shatter();g.bot_count=7;g.bot_plan=[];g.bots.sync_lobby();s.setup(g.arena_world);s.reset_round();var began=g.positions.duplicate();var rounds=0
 for n in 16000:
  g.bots.step(1.0/60);g.arena_world.step(1.0/60)
  if not g.started:break
 var moved=0
 for id in g.positions:
  if str(id).begins_with("bot:") and g.positions[id].distance_to(began.get(id,Vector2.ZERO))>80:moved+=1
 check(moved>=6,"practice AI navigate collapsing floors");check(not g.started and s.round_number==3,"AI practice completes all three rounds")
 var data={"passed":failures.is_empty(),"checks":checks,"failures":failures,"bots_moved":moved,"ai_rounds":s.round_number};DirAccess.make_dir_recursive_absolute("res://validation/v198");var f=FileAccess.open("res://validation/v198/shatterfloor.json",FileAccess.WRITE);f.store_string(JSON.stringify(data,"  "));f.close();print("V198 SHATTERFLOOR ",JSON.stringify(data));quit(0 if failures.is_empty() else 1)
