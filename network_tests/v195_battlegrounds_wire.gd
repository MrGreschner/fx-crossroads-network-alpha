extends SceneTree
class CaptureGateway:
 extends "res://network/server.gd"
 var captured:Dictionary={}
 var controls:Array=[]
 func send_actor(id:String,data:Dictionary)->void:controls.append({"actor":id,"packet":data})
 func send_snapshot(_key:int,bytes:PackedByteArray)->void:captured=JSON.parse_string(bytes.decompress_dynamic(16777216,FileAccess.COMPRESSION_GZIP).get_string_from_utf8())
var checks=0
var failures=0
var g:Node
var c:Node
var shell:Node
var capture:Node
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func fixture(seats:int,map_id:String)->void:
 root.set_meta("fx_dedicated_server",true);root.set_meta("fx_dev_match",true)
 g=load("res://network/arena.gd").new();root.add_child(g);await process_frame;g.set_process(false);g.set_physics_process(false)
 g.mode="battlegrounds";g._set_mode("battlegrounds");g.bg_team_size=seats/2;g.bg_map=map_id;g.arena_seats=seats;g._sync_bg_pickers();g.positions.clear();g.teams.clear();g.roster.clear()
 for n in seats:
  var id="p"+str(n);g.roster.append({"id":id,"name":id,"hero":"ram","team":n%2});g._add_player(id,n);g.teams[id]=n%2;g.lobby_heroes[id]="ram";g.food_registered[id]=true;g.food_loadouts[id]="berry_bun"
 g._start_match();g.start_countdown=0
 capture=CaptureGateway.new();g.gateway=capture
 var members={};capture.identities={};capture.peers={}
 for n in seats:
  var id="p"+str(n);members[id]={"id":id,"team":n%2};capture.identities[id]={"connection":n+1,"event_ack":0,"room":"TEST","last_seq":0,"action_seq":0};capture.peers[n+1]={"ws":WebSocketPeer.new(),"actor":id}
 capture.rooms={"TEST":{"game":g,"members":members,"events":[],"event_seq":0,"seats":seats,"host":"p0"}}
 root.remove_meta("fx_dedicated_server");root.set_meta("fx_mode","battlegrounds")
 shell=load("res://network/client.tscn").instantiate();root.add_child(shell);c=shell.game;await process_frame;c.set_process(false);c.set_physics_process(false);c.legacy.set_process(false)
 c.roster.assign(g.roster);c.my_id="p0";c.net_ready=true;c.receive_net(capture.start_packet(g));root.set_meta("fx_dedicated_server",true)
 sync()
func sync()->void:
 g.authority_tick+=3;capture.snapshot(g);var data=capture.captured.duplicate(true);c._buffer_state(data);c.receive_net(data)
 check(data.battlegrounds.bases["0:0"].pos is Array,"Applying snapshot preserves buffered wire positions")
func clean()->void:
 c.net_ready=false;c.started=false;g.started=false;shell.queue_free();g.queue_free();capture.free();await process_frame;await process_frame
func run()->void:
 root.get_node("FXActivity").set_enabled(false)
 for seats in [6,8]:
  for map_id in ["woodland","warzone"]:
   await fixture(seats,map_id);var b=g.battlegrounds
   check(g.pvp_rule=="teams" and c.pvp_rule=="teams","Teams retained on authority and guest")
   check(b.bases.size()==seats and c.battlegrounds.bases.size()==seats,"Every fighter has a replicated personal barracks")
   check(c.bg_map==map_id and c.bg_team_size==seats/2 and c.FIELD==g.FIELD,"Map, lane count and collision bounds match")
   check(c.teams==g.teams and c.food_slots.p0=="berry_bun","Faction and packed food retained")
   for n in 55:b.step(.1)
   sync();check(b.units.size()==seats*2 and c.battlegrounds.units.size()==seats*2,"Starting armies are server owned and replicated")
   var key=str(b.units.keys()[0]);var unit:Dictionary=b.units[key];var hp=float(unit.hp)
   b.damage(key,20,"p0");check(unit.hp==hp,"Friendly army cannot be damaged")
   b.damage(key,20,"p1");check(unit.hp==hp-20,"Enemy army can be damaged")
   # Ordered economy: same path used by actual network packets, no claimed buyer accepted.
   g.positions.p0=b.bases["0:0"].pos;g.gold.p0=10000;g.input_ack.p0=0;g.server_actions.p0=[];g.server_inputs.p0=[];g.server_input_credit.p0=0
   var counts=int(b.bases["0:0"].counts[1])
   capture.receive(1,{"type":"bg_upgrade","key":"unit:archer","seq":1,"input_seq":2,"match_id":g.match_id,"buyer":"p1"})
   check(g.server_actions.p0.size()==1 and int(b.bases["0:0"].counts[1])==counts,"Army order waits for movement and ignores forged buyer")
   g.server_inputs.p0=[{"seq":1,"d":[0,0],"a":0,"ph":false,"sh":false},{"seq":2,"d":[0,0],"a":0,"ph":false,"sh":false}]
   g._physics_process(1.0/60);g._physics_process(1.0/60)
   check(int(b.bases["0:0"].counts[1])==counts+1,"Queued order recruits at own barracks")
   var ack=capture.controls.filter(func(x):return x.packet.type=="economy_ack")
   check(ack.size()==1 and ack[0].packet.accepted,"Order acknowledges success once")
   c.receive_net(ack[0].packet);check(c.battlegrounds.bases["0:0"].counts[1]==counts+1 and c.gold.p0==g.gold.p0,"Order feedback shows fresh CC and recruitment counts")
   capture.receive(1,{"type":"bg_upgrade","key":"unit:archer","seq":1,"input_seq":2,"match_id":g.match_id})
   check(g.server_actions.p0.is_empty(),"Duplicate order serial does not spend again")
   capture.receive(1,{"type":"bg_upgrade","key":"unit:infinite","seq":2,"input_seq":2,"match_id":g.match_id})
   check(g.server_actions.p0.is_empty(),"Unknown army upgrade rejected")
   g.set_meta("economy_ready_p0",0);g.positions.p0=b.bases["1:0"].pos
   capture.execute_action(g,"p0",{"type":"bg_upgrade","key":"melee","seq":3,"input_seq":2})
   check(not capture.controls[-1].packet.accepted and int(b.bases["1:0"].upgrades.melee)==0,"Cannot upgrade an enemy barracks")
   g.set_meta("economy_ready_p0",0);g.positions.p0=b.bases["0:0"].pos;g.gold.p0=0
   capture.execute_action(g,"p0",{"type":"bg_upgrade","key":"melee","seq":4,"input_seq":2});check(not capture.controls[-1].packet.accepted,"No-CC order rejected")
   g.gold.p0=1000;g.health.p0=0;g.set_meta("economy_ready_p0",0)
   capture.execute_action(g,"p0",{"type":"bg_upgrade","key":"melee","seq":5,"input_seq":2});check(not capture.controls[-1].packet.accepted,"Dead fighter cannot buy")
   g.health.p0=g._max_hp("p0");g.invincible_until.p0=0
   g._hurt("p0",100000,"p1");check(g.health.p0==0 and int(g.respawn_at.p0)-Time.get_ticks_msec()>6800,"Death starts seven-second respawn")
   sync();b.step(.1);check(g.health.p0==0,"Death does not instantly respawn")
   var epoch=int(g.player_epochs.get("p0",0));g.net_dash.p0={"time":.2,"direction":Vector2.RIGHT};g.respawn_at.p0=0;b.step(.1)
   check(g.health.p0>0 and g.positions.p0.distance_to(b.spawn("p0"))<1 and int(g.player_epochs.p0)==epoch+1 and not g.net_dash.has("p0"),"Respawn uses capital, new epoch and clears old dash")
   sync();check(c.local_pos.distance_to(g.positions.p0)<1 and not c.net_dash.get("p0",{}).get("time",0)>0,"Guest follows respawn without stale movement")
   # The central shop uses the correct purchase packet and checks authority distance.
   var item=str(g.item_list[0]);g.gold.p0=100000;g.positions.p0=b.spawn("p0");g.set_meta("economy_ready_p0",0)
   capture.execute_action(g,"p0",{"type":"purchase","id":item,"seq":6,"input_seq":2});check(not capture.controls[-1].packet.accepted,"Central market rejects purchase from home")
   g.positions.p0=b.SIZE*.5;g.set_meta("economy_ready_p0",0)
   capture.execute_action(g,"p0",{"type":"purchase","id":item,"seq":7,"input_seq":2});check(capture.controls[-1].packet.accepted and g.inventory.p0.size()==1,"Central market accepts authoritative purchase")
   g.set_meta("economy_ready_p0",0);capture.execute_action(g,"p0",{"type":"bg_upgrade","key":"order:capital","seq":8,"input_seq":2,"buyer":"p1"})
   check(capture.controls[-1].packet.accepted and b.bases[b.owners.p0].order=="capital" and b.bases[b.owners.p1].order=="open","wire order affects authenticated commander only")
   g.set_meta("economy_ready_p0",0);capture.execute_action(g,"p0",{"type":"bg_upgrade","key":"order:recall","seq":9,"input_seq":2})
   check(capture.controls[-1].packet.accepted and g.positions.p0.distance_to(b.bases[b.owners.p0].pos)<200,"authoritative recall relocates hero to own barracks")
   g.set_meta("economy_ready_p0",0);capture.execute_action(g,"p0",{"type":"bg_upgrade","key":"order:recall","seq":10,"input_seq":2})
   check(not capture.controls[-1].packet.accepted,"wire recall cannot bypass cooldown")
   sync();check(c.battlegrounds.command.recall_ready.p0>0,"guest receives authoritative recall cooldown")
   # Army population and victory conditions.

   b.units.clear()
   for base in b.bases.values():
    base.counts=[6,3,3,3,3,3,3,3,3,3,3]
    for repeat in 32:b.spawn_unit(base,0,repeat)
   check(b.units.size()==seats*32,"Army cap holds for complete roster")
   var phases=[0,0,0,0,0,0]
   for soldier in b.units.values():phases[int(soldier.phase)]+=1
   check(int(phases.max())<=43,"Strategy work stays bounded to at most 43 troops per frame")
   b.rebuild_unit_grid()
   var rng=RandomNumberGenerator.new();rng.seed=12
   for trial in 100:
    var center=Vector2(rng.randf_range(0,6800),rng.randf_range(0,4400));var radius=rng.randf_range(25,750)
    var candidates=b.hostile_near("p0",center,radius)
    for target in b.hostile("p0"):
     var actor=b.actor(target)
     if actor.pos.distance_to(center)<=radius:check(candidates.has(target),"Spatial broadphase keeps every nearby hostile target")
   var movable=str(b.units.keys()[0]);var old:Vector2=b.units[movable].pos;b.knock(movable,Vector2.RIGHT,150)
   check(b.nearby_units(old,30).size()>=0 and b.unit_grid_dirty,"Knockback invalidates army spatial index")
   b.hostile_near("p1",b.units[movable].pos,30);check(not b.unit_grid_dirty,"Next spatial query rebuilds after knockback")

   var converted=""
   for candidate in b.units:
    if int(b.units[candidate].team)==1:converted=str(candidate);break
   var lost_owner=str(b.units[converted].owner);g.positions.p0=b.units[converted].pos;b.convert("p0",converted)
   b.spawn_unit(b.bases[b.owners[lost_owner]],0,0)
   check(b.units.size()<=seats*32,"Converted soldiers cannot open an extra global army slot")
   var heart=float(b.heart_hp[1]);b.damage("bgheart:1",10,"p0");check(b.heart_hp[1]==heart-10 and g.started,"Capital takes damage while opposing barracks still stand")
   if map_id=="warzone":
    b.air_timer=0;b.tick_bombs(.1);check(b.bombs.size()>=3,"Iron Rain warns before bombing")
    var bomb:Dictionary=b.bombs[0];g.positions.p0=bomb.pos;g.positions.p1=bomb.pos;g.health.p0=1000;g.health.p1=1000;g.invincible_until.p0=0;g.invincible_until.p1=0;bomb.time=0;b.tick_bombs(.1)
    check(g.health.p0<1000 and g.health.p1<1000,"Airstrike damages both factions")
   for base_key in b.bases:
    if int(b.bases[base_key].team)==1:b.damage("bgbase:"+str(base_key),100000,"p0")
   check(not b.shielded(1),"Destroyed barracks stop reinforcements; capital stays vulnerable")
   b.damage("bgheart:1",100000,"p0");sync()
   check(not g.started and not c.started and c.battlegrounds.winner==0 and c.adventure_won(c.results_reason),"Winner and results replicate to winning faction")
   c.my_id="p1";check(not c.adventure_won(c.results_reason),"Opposing faction sees a loss")
   check(capture.captured.battlegrounds.units.size()<=seats*32,"Complete army snapshot is bounded")
   await clean()
 # Distinct 10 Hz samples interpolate over the entire interval, despite repeated 20 Hz packets.
 var view=load("res://network/world_view.gd").new()
 for tick in [3,6,9,12,15,18]:
  var stamp=floori(tick/6.0)*.1
  view.receive({"server_tick":tick,"battlegrounds":{"army_time":stamp,"units":{"u":{"pos":[stamp*1000,0]}},"shots":[{"uid":1,"pos":[stamp*1000,10]}],"bombs":[{"uid":2,"pos":[0,0],"time":2.0}],"clock":tick/60.0}},tick/60.0)
 for time in [.125,.15,.175]:
  view.render_time=time;var result=view.battlegrounds();check(absf(result.units.u.pos.x-time*1000)<.01,"Smooth full-interval strategy interpolation at "+str(time));check(absf(result.shots[0].pos.x-time*1000)<.01,"Siege projectiles use same timeline")
 check(view.snapshots[0].data.battlegrounds.units.u.pos is Array,"Rendering never mutates buffered state")
 var staggered=load("res://network/world_view.gd").new()
 for tick in [3,6,9,12,15,18]:
  var time=tick/60.0;var sample=floorf((time-.025)/.1)*.1+.025
  staggered.receive({"server_tick":tick,"battlegrounds":{"army_time":time,"units":{"u":{"sample_time":sample,"pos":[sample*1000,0]}},"shots":[],"bombs":[]}},time)
 for time in [.15,.175,.2]:
  staggered.render_time=time;check(absf(staggered.battlegrounds().units.u.pos.x-time*1000)<.01,"Per-unit scheduling retains smooth movement")
 staggered.receive({"server_tick":21,"battlegrounds":{"army_time":.35,"units":{},"shots":[],"bombs":[]}},.35)
 staggered.render_time=.36;check(staggered.battlegrounds().units.is_empty(),"Destroyed units disappear on shared timeline")
 staggered.clear();check(staggered.army_tracks.is_empty(),"Returning to lobby discards old army history")

 DirAccess.make_dir_recursive_absolute("res://validation/v195");var f=FileAccess.open("res://validation/v195/battleground-wire195.json",FileAccess.WRITE);f.store_string(JSON.stringify({"passed":failures==0,"checks":checks,"failures":failures},"  "));f.close()
 print("V187 BATTLEGROUNDS ",checks," checks, ",failures," failures");quit(1 if failures else 0)
