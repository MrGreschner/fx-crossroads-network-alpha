extends SceneTree
var g:Node
var checks=0
var failures=[]
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize()->void:call_deferred("run")
func start(map:String,teamed:bool=false)->RefCounted:
 g.arena_map=map;g._sync_arena_pickers();g.rule_picker.select(1 if teamed else 0);g.pvp_rule="teams" if teamed else "ffa"
 for n in 8:g.teams["p"+str(n)]=n%2
 g._start_match();g.start_countdown=0
 for id in g.positions:g.health[id]=120;g.invincible_until[id]=0;g.positions[id]=Vector2(100+int(str(id).trim_prefix("p"))*45,150)
 return g.arena_world.objective
func run()->void:
 root.set_meta("fx_dedicated_server",true);root.set_meta("fx_dev_match",true);root.get_node("FXActivity").set_enabled(false);root.get_node("FXCommunityHeroes").set_process(false)
 g=load("res://network/arena.gd").new();root.add_child(g);current_scene=g;await process_frame;g.set_process(false);g.set_physics_process(false);g.legacy.set_process(false);g.mode="arena";g._set_mode("arena");g.arena_seats=8;g.role="host";g.spectator_host=false;g.my_id="p0";g.host_id="p0"
 for n in 8:
  var id="p"+str(n);g.roster.append({"id":id,"name":"Player "+str(n+1)});g._add_player(id,n);g.teams[id]=n%2;g.lobby_heroes[id]="ram"
 var o=start("colour_clash")
 check(g.arena_world.MAPS.size()==10 and o.keys.size()==8,"ten maps and eight distinct FFA colours");check(o.available>1100 and o.cells.size()==1200,"bounded floor grid excludes cover")
 for n in 80:o.paint("p0",.1)
 check(o.scores.p0==1,"standing still only paints initial tile")
 var amount=float(o.scores.p0);g.positions.p0=Vector2(2000,960);o.paint("p0",.1);check(float(o.scores.p0)-amount<=2,"teleport paint is bounded");check(o.cells[15*40+15]==0,"teleport leaves skipped floor unpainted")
 o=start("colour_clash");g.characters.qa_slow=g.characters.ram.duplicate(true);g.characters.qa_fast=g.characters.ram.duplicate(true);g.characters.qa_slow.speed=170;g.characters.qa_fast.speed=360;g.hero_ids.p0="qa_slow";g.hero_ids.p1="qa_fast";g.positions.p0=Vector2(200,320);g.positions.p1=Vector2(200,1600)
 for n in 50:g.positions.p0+=Vector2(17,0);g.positions.p1+=Vector2(36,0);o.paint("p0",.1);o.paint("p1",.1)
 var slow=float(o.scores.p0);var fast=float(o.scores.p1);print("PAINT BALANCE slow=",slow," fast=",fast)
 check(slow>=25 and fast>=25 and absf(slow-fast)<=maxf(slow,fast)*.25,"slow and fast heroes claim comparable fresh area");check(slow<=41 and fast<=41,"painting throughput stays bounded")
 var sum=0
 for v in o.scores.values():sum+=int(v)
 check(sum==o.cells.size()-o.cells.count(0)-o.cells.count(-1),"territory counters match floor ownership")
 var packet=JSON.parse_string(JSON.stringify(g.arena_world.snapshot()));var clone=load("res://scripts/arena_world.gd").new();clone.setup(g,"colour_clash");clone.receive(packet)
 check(clone.objective.cells==o.cells,"run-length paint survives wire JSON");check(is_equal_approx(clone.objective.value("p0"),o.value("p0")),"replicated percentages match")
 var painted_index=-1
 for n in o.cells.size():
  if o.cells[n]>0:painted_index=n;break
 check(o.paint_mesh(Vector2i((painted_index%40)/8,(painted_index/40)/8)).get_surface_count()==1,"paint renders as cached chunk mesh")
 o=start("colour_clash");g.positions.p1=Vector2(1280,960);g.positions.p0=Vector2(1280,1040);o.disc(g.positions.p1,260,"p1");o.disc(Vector2(2250,1700),100,"p1");var far_index=26*40+35;var before=float(o.scores.p0)
 g._hurt("p1",10000,"p0");check(g.health.p1==0 and float(o.scores.p0)>before,"hero defeat flips nearby victim territory");check(o.cells[far_index]==o.keys.find("p1")+1,"defeat preserves distant territory")
 g.pvp_scores.p0=100;g._simulate(.01);check(g.started,"KO target cannot end Colour Clash")
 o=start("colour_clash",true);check(o.keys.size()==2 and o.group("p0")==o.group("p2"),"team players share colours and scoring");g.positions.p0=Vector2(820,960);o.step_beacons(3.1);check(o.beacons[0].owner=="team:0" and float(o.scores["team:0"])>0,"holding beacon captures and paints a small area")
 g.positions.p1=g.positions.p0;o.step_beacons(4);check(o.beacons[0].contested and o.beacons[0].owner=="team:0","opposing presence contests beacon")
 g.positions.p0=Vector2(100,100);o.step_beacons(3.1);check(o.beacons[0].owner=="team:1","opponent can capture beacon")
 o.scores["team:0"]=200;o.scores["team:1"]=10;g.pvp_scores.p1=100;check(g._arena_outcome("p0")=="win" and g._arena_outcome("p1")=="loss","floor objective wins independently of kills")
 o.elapsed=299.99;o.step(.02);check(not g.started and g.arena_outcomes.p0=="win","five-minute finish records territory winner")
 o=start("crown_chase");check(o.keys.size()==8,"Crown Chase accepts eight FFA competitors");o.step(.5);check(o.crown.holder.is_empty() and o.scores.p0==0,"unclaimed crown scores nothing")
 g.positions.p0=Vector2(1280,960);g.positions.p1=g.positions.p0;o.step(.1);check(o.crown.holder=="p0","only one hero collects contested crown");g.positions.p1=Vector2(2400,1800);o.step(1);check(o.held.p0>.9 and o.scores.p0>.9,"carrying scores time")
 o.step(50);check(is_equal_approx(o.carrier_factor("p0"),.6),"crown weight caps at forty percent slowdown");var scored=float(o.scores.p0);g.invincible_until.p0=Time.get_ticks_msec()+10000;o.step(1);check(is_equal_approx(scored,float(o.scores.p0)),"invulnerability pauses crown scoring");g.invincible_until.p0=0
 o.drop("p0");o.step(.2);check(o.crown.holder.is_empty(),"recent holder cannot instantly reclaim drop");o.step(1.5);check(o.crown.holder=="p0" and is_equal_approx(o.carrier_factor("p0"),.6),"reclaiming drop preserves accumulated weight")
 o.step(.7);check(not o.throw_crown("p1",Vector2.RIGHT),"non-holder cannot throw");check(not o.throw_crown("p0",Vector2(INF,0)),"non-finite throw rejected")
 g.positions.p1=Vector2(1520,960);check(o.throw_crown("p0",Vector2.RIGHT),"holder can throw crown");check(not o.throw_crown("p0",Vector2.RIGHT),"duplicate throw rejected")
 for n in 60:o.step(1.0/60)
 check(o.crown.holder=="p1" and o.passes.p0==1,"opponent intercepts a thrown crown");check(o.carrier_factor("p1")>.98,"opponent possession starts fresh burden")
 var source=g.positions.p1;g._hurt("p1",10000,"p0");check(o.crown.holder.is_empty() and g.arena_world.point(o.crown.pos).distance_to(source)<1,"defeat drops crown at hero location")
 o.crown.pos=[-300,-300];o.step(.1);check(g.arena_world.point(o.crown.pos)==Vector2(1280,960),"unreachable crown resets to central plinth")
 o=start("crown_chase",true);g.positions.p0=Vector2(1280,960);g.positions.p2=Vector2(1520,960);o.step(.1);o.step(30);var group_time=float(o.scores["team:0"]);check(o.throw_crown("p0",Vector2.RIGHT),"team carrier throws to ally")
 for n in 60:o.step(1.0/60)
 check(o.crown.holder=="p2" and float(o.scores["team:0"])>group_time,"teammate catches and adds to shared carrying time")
 o.step(.7);check(o.throw_crown("p2",Vector2.LEFT),"teammate can pass back")
 for n in 60:o.step(1.0/60)
 check(o.crown.holder=="p0" and o.carrier_factor("p0")<.75,"passing back does not erase original carrier burden")
 var moved=preload("res://network/movement.gd").advance(g,"p0",g.positions.p0,Vector2.UP);check(moved.distance_to(g.positions.p0)<float(g.characters.ram.speed)/60,"shared movement applies carrier slowdown")
 var scores=o.scores.duplicate();o.elapsed=299.99;o.step(.02);check(not g.started and g.arena_outcomes.p0=="win" and g.arena_outcomes.p2=="win","team crown finish records shared victory")
 var gateway=load("res://network/server.gd").new();check(gateway.valid_action({"type":"crown_throw","angle":0.0,"input_seq":0}),"gateway accepts bounded throw action");check(not gateway.valid_action({"type":"crown_throw","angle":INF,"input_seq":0}),"gateway rejects invalid throw angle");gateway.free()
 var result={"passed":failures.is_empty(),"checks":checks,"failures":failures,"slow_paint":slow,"fast_paint":fast};DirAccess.make_dir_recursive_absolute("res://validation/v197");var f=FileAccess.open("res://validation/v197/objectives.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close();print("V197 OBJECTIVES ",JSON.stringify(result));quit(0 if failures.is_empty() else 1)
